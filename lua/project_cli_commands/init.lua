local actions = require('telescope.actions')
local state = require('telescope.actions.state')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")


local Terminal = require("toggleterm.terminal").Terminal

local next_id = require("project_cli_commands.term_utils").next_id
local openConfigFile = require("project_cli_commands.file").openConfigFile
local getSubstringAfterSecondSlash = require("project_cli_commands.str_utils").getSubstringAfterSecondSlash
local open_action = require('project_cli_commands.actions').open


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

        local id = next_id()

        local cmdTerm = Terminal:new({
          id            = id,
          cmd           = selection.value .. params,
          hidden        = true,
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

M.running = function(opts)
  local default_opts = {
    layout_config = {
      preview_width = 0.6,
    },
  }

  opts = opts or {}

  -- iterate over key-value pairs in opts
  for k, v in pairs(opts) do
    default_opts[k] = v
  end

  local bufnrs = vim.tbl_filter(function(b)
    return vim.api.nvim_buf_get_option(b, "filetype") == "toggleterm"
  end, vim.api.nvim_list_bufs())

  table.sort(bufnrs, function(a, b)
    return vim.fn.getbufinfo(a)[1].lastused > vim.fn.getbufinfo(b)[1].lastused
  end)
  local buffers = {}
  for _, bufnr in ipairs(bufnrs) do
    local info = vim.fn.getbufinfo(bufnr)[1]
    local element = {
      bufnr = info.bufnr,
      changed = info.changed,
      changedtick = info.changedtick,
      hidden = info.hidden,
      lastused = info.lastused,
      linecount = info.linecount,
      listed = info.listed,
      lnum = info.lnum,
      loaded = info.loaded,
      name = info.name,
      title = getSubstringAfterSecondSlash(info.name),
      windows = info.windows,
      terminal_job_id = info.variables.terminal_job_id,
      terminal_job_pid = info.variables.terminal_job_pid,
      toggle_number = info.variables.toggle_number,
    }
    table.insert(buffers, element)
  end

  pickers.new(default_opts, {
    prompt_title = "Terminal Buffers",
    finder = finders.new_table {
      -- results = results,
      results = buffers,
      entry_maker = function(entry)
        return {
          value = entry,
          text = tostring(entry.bufnr),
          display = tostring(entry.title),
          ordinal = tostring(entry.title),
        }
      end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(open_action)

      -- setup mappings
      local mappings = M.config.telescope_mappings
      for keybind, action in pairs(mappings) do
        map("i", keybind, function()
          action(prompt_bufnr)
        end)
      end
      return true
    end,
    previewer = previewers.new_buffer_previewer {
      define_preview = function(self, entry, _) -- 3d param is status
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, true,
          vim.api.nvim_buf_get_lines(entry.value.bufnr, 0, -1, false))
      end
    }
  }):find()
end

M.setup = function(config)
  M.config = config
end

return M
