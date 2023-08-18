local defaults = {
  -- Key mappings bound inside the telescope window
  telescope_mappings = {
    ['<C-c>'] = require('project_cli_commands.actions').exit_terminal,
    ['<C-f>'] = require('project_cli_commands.actions').open_float,
    ['<C-v>'] = require('project_cli_commands.actions').open_vertical,
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
