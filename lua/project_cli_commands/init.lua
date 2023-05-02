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

local M = {}

M.open = function(opts)
  opts = opts or {}

  local filePath = vim.fn.getcwd() .. '/.nvim/commands.lua'

  local chunk, err = loadfile(filePath)
  if err then -- Prompt user to create new file
    local choice
    repeat
      choice = vim.fn.input("commands.lua isn't found do you want to create it? (y/n): ")
    until choice == 'y' or choice == 'n'

    if choice == 'y' then
      if createDirIfNotExists(vim.fn.getcwd() .. '/.nvim') == false then
        error("Can't create .nvim directory.")
      end
      -- Create a new file and write an empty table
      local file = io.open(filePath, "w")
      if file == nil then
        error("commands.lua could not be created.")
      end

      file:write("return {\n  ['ls'] = 'ls -tls'\n}\n")
      file:close()

      print("commands.lua created with an empty table.")
      vim.api.nvim_command('edit ' .. filePath)
    end
    return
  end

  -- Execute the loaded chunk to get the table
  if chunk == nil then
    error("commands.lua is empty.")
  end

  local commands = chunk()

  local scriptsNames    = {}
  for name, code in pairs(commands) do
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
