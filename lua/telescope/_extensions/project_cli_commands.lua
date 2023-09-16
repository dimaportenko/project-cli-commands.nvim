
return require("telescope").register_extension {
  exports = {
    open = require("project_cli_commands").open,
    running = require("project_cli_commands").running
  },
}
