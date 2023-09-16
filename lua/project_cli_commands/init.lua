local actions = require('telescope.actions')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local sorters = require('telescope.sorters')
local conf = require("telescope.config").values
local previewers = require("telescope.previewers")

local openConfigFile = require("project_cli_commands.file").openConfigFile
local getSubstringAfterSecondSlash = require("project_cli_commands.str_utils").getSubstringAfterSecondSlash
local open_action = require('project_cli_commands.actions').open_vertical

local execute_script = require('project_cli_commands.open_actions').execute_script
local execute_script_with_input = require('project_cli_commands.open_actions').execute_script_with_input
local copy_command_clipboard = require('project_cli_commands.open_actions').copy_command_clipboard
local execute_script_vertical = require('project_cli_commands.open_actions').execute_script_vertical
local execute_script_float = require('project_cli_commands.open_actions').execute_script_float



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
      -- setup mappings
      local mappings = M.config.open_telescope_mapping
      for _, mapping in pairs(mappings) do
        map(mapping.mode, mapping.key, mapping.action)
        map(mapping.mode, mapping.key, function()
          mapping.action(prompt_bufnr)
        end)
      end

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
      local mappings = M.config.running_telescope_mapping
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
  local defaults = {
    -- Key mappings bound inside the telescope window
    running_telescope_mapping = {
      ['<C-c>'] = require('project_cli_commands.actions').exit_terminal,
      ['<C-f>'] = require('project_cli_commands.actions').open_float,
      ['<C-v>'] = require('project_cli_commands.actions').open_vertical,
      ['<C-h>'] = require('project_cli_commands.actions').open_horizontal,
    },
    open_telescope_mapping = {
      { mode = 'i', key = '<CR>',  action = execute_script_vertical },
      { mode = 'n', key = '<CR>',  action = execute_script_vertical },
      { mode = 'i', key = '<C-h>', action = execute_script },
      { mode = 'n', key = '<C-h>', action = execute_script },
      { mode = 'i', key = '<C-i>', action = execute_script_with_input },
      { mode = 'n', key = '<C-i>', action = execute_script_with_input },
      { mode = 'i', key = '<C-c>', action = copy_command_clipboard },
      { mode = 'n', key = '<C-c>', action = copy_command_clipboard },
      { mode = 'i', key = '<C-f>', action = execute_script_float },
      { mode = 'n', key = '<C-f>', action = execute_script_float },
      { mode = 'i', key = '<C-v>', action = execute_script_vertical },
      { mode = 'n', key = '<C-v>', action = execute_script_vertical },
    }
  }

  config = config or {}
  config = vim.tbl_deep_extend("force", defaults, config)

  M.config = config
end

return M
