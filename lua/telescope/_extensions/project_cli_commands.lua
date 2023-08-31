local execute_script = require('project_cli_commands.open_actions').execute_script
local execute_script_with_input = require('project_cli_commands.open_actions').execute_script_with_input
local copy_command_clipboard = require('project_cli_commands.open_actions').copy_command_clipboard
local execute_script_vertical = require('project_cli_commands.open_actions').execute_script_vertical
local execute_script_float = require('project_cli_commands.open_actions').execute_script_float

local defaults = {
  -- Key mappings bound inside the telescope window
  running_telescope_mapping = {
    ['<C-c>'] = require('project_cli_commands.actions').exit_terminal,
    ['<C-f>'] = require('project_cli_commands.actions').open_float,
    ['<C-v>'] = require('project_cli_commands.actions').open_vertical,
  },
  open_telescope_mapping = {
    -- ['<C-f>'] = require('project_cli_commands.actions').open_float,
    -- ['<C-v>'] = require('project_cli_commands.actions').open_vertical,
    -- map('i', '<CR>', execute_script)
    -- map('n', '<CR>', execute_script)
    --
    -- map('i', '<C-i>', execute_script_with_input)
    -- map('n', '<C-i>', execute_script_with_input)
    --
    -- map('i', '<C-c>', copy_command_clipboard)
    -- map('n', '<C-c>', copy_command_clipboard)
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

return require("telescope").register_extension {
  setup = function(config)
    config = config or {}
    config = vim.tbl_deep_extend("force", defaults, config)

    require("project_cli_commands").setup(config)
  end,
  exports = {
    open = require("project_cli_commands").open,
    running = require("project_cli_commands").running
  },
}
