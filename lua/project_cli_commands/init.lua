local actions = require('telescope.actions')
local state = require('telescope.actions.state')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
-- local previewers = require("telescope.previewers")
local Terminal = require("toggleterm.terminal").Terminal

local createDirIfNotExists = function(filePath)
  -- Check if directory exists
  if vim.fn.isdirectory(filePath) == 0 then -- Create the directory
    -- Create the directory
    local success = vim.fn.mkdir(filePath, "p")
    if success == -1 then
      error("Error creating directory: " .. filePath)
    end
    print(".nvim directory created.")
  else
    print(".nvim directory already exists.")
  end

  return true
end


local openConfigFile = function()
  local filePath = vim.fn.getcwd() .. '/.nvim/config.json'

  local file = io.open(filePath, "rb")
  if file == nil then
    local choice
    repeat
      choice = vim.fn.input(".nvim/config.json isn't found do you want to create it? (y/n): ")
    until choice == 'y' or choice == 'n'

    if choice == 'y' then
      if createDirIfNotExists(vim.fn.getcwd() .. '/.nvim') == false then
        error("Can't create .nvim directory.")
      end
      -- Create a new file and write an empty table
      local new_file = io.open(filePath, "w")
      if new_file == nil then
        error(".nvim/config.json could not be created.")
      end

      new_file:write("{\n  \"commands\": {\n    \"ls:la\": \"ls -la\"\n   }\n}\n")
      new_file:close()

      print(".nvim/config.json created with an empty table.")
      vim.api.nvim_command('edit ' .. filePath)
    end
    return nil, ".nvim/config.json isn't found."
  end

  local jsonString = file:read "*a"
  file:close()

  return jsonString, nil
end

local M = {}

M.open = function(opts)
  opts = opts or {}

  local jsonString, error = openConfigFile()

  if error ~= nil then
    return
  end

  local scriptsFromJson = vim.fn.json_decode(jsonString)['commands']
  local scriptsNames    = {}
  for name, code in pairs(scriptsFromJson) do
    table.insert(scriptsNames, { name, code })
  end

  -- find the length of the longest script name
  local longestScriptName = 0
  for _, script in ipairs(scriptsNames) do
    if #script[1] > longestScriptName then
      longestScriptName = #script[1]
    end
  end

  pickers.new(opts, {
    prompt_title = 'Search',
    results_title = 'Commands',
    layout_strategy = "horizontal",
    layout_config = {
      width = 0.8,
      height = 0.4,
      preview_width = 0.6,
    },
    finder = finders.new_table {
      results = scriptsNames,
      entry_maker = function(entry)
        -- fill string with spaces to make it the same length as the longest script name
        local spaces = string.rep(" ", longestScriptName - #entry[1])
        local display = entry[1] .. spaces .. "  ||  " .. entry[2]
        return {
          value = entry[2],
          ordinal = entry[1],
          display = display,
          code = entry[2]
        }
      end,
    },
    sorter = sorters.get_generic_fuzzy_sorter(),
    attach_mappings = function(prompt_bufnr, map)
      local execute_script_with_params = function(with_params)
        local selection = state.get_selected_entry()
        actions.close(prompt_bufnr)

        local params = ''
        if with_params then
          params = ' ' .. vim.fn.input(selection.code .. ' ')
        end

        local cmdTerm = Terminal:new({
          cmd = selection.value .. params,
          hidden = true,
          close_on_exit = false,
        })

        cmdTerm:toggle()
        -- print(vim.inspect(scriptsFromJson[selection.value]))
        -- print(vim.inspect(selection.value))
      end

      local execute_script = function()
        execute_script_with_params(false)
      end

      local execute_script_with_input = function()
        execute_script_with_params(true)
      end

      local copy_command_clipboard = function()
        local selection = state.get_selected_entry()
        actions.close(prompt_bufnr)

        vim.fn.setreg('+', selection.code)
      end

      map('i', '<CR>', execute_script)
      map('n', '<CR>', execute_script)

      map('i', '<C-i>', execute_script_with_input)
      map('n', '<C-i>', execute_script_with_input)

      map('i', '<C-c>', copy_command_clipboard)
      map('n', '<C-c>', copy_command_clipboard)

      return true
    end
  }):find()
end

return M
