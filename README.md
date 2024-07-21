# project-cli-commands.nvim

<div align="left">
  <a align="left" href="https://github.com/dimaportenko?tab=followers">
    <img src="https://img.shields.io/github/followers/dimaportenko?label=Follow%20%40dimaportenko&style=social" />
  </a>
  <br/>
  <a align="left" href="https://twitter.com/dimaportenko">
    <img src="https://img.shields.io/twitter/follow/dimaportenko?label=Follow%20%40dimaportenko&style=social" />
  </a>
  <br/>
  <a align="left" href="https://www.youtube.com/channel/UCReKeeIMZywvQoaZPZKzQbQ">
    <img src="https://img.shields.io/youtube/channel/subscribers/UCReKeeIMZywvQoaZPZKzQbQ" />
  </a>
  <br/>
  <a align="left" href="https://www.youtube.com/channel/UCReKeeIMZywvQoaZPZKzQbQ">
    <img src="https://img.shields.io/youtube/channel/views/UCReKeeIMZywvQoaZPZKzQbQ" />
  </a>
</div>
<br/>

Quickly run your project cli commands with [Telescope](https://github.com/nvim-telescope/telescope.nvim) and [ToggleTerm](https://github.com/akinsho/toggleterm.nvim).

![demo](https://raw.githubusercontent.com/dimaportenko/project-cli-commands.nvim/main/docs/demo.gif)

- [Installation](#installation)
- [Usage](#usage)
  - [Commands Configuration](#commands-configuration)
  - [Telescope commands](#telescope-commands)
  - [Keymap](#keymap)
- [Features](#features)
  - [Open terminal with command](#open-terminal-with-command)
  - [Run command with input](#run-command-with-input)
  - [Copy command to clipboard](#copy-command-to-clipboard)
  - [Run command after](#run-command-after)
  - [Environment variables](#environment-variables)
  - [Inject current buffer path to command](#inject-current-buffer-path-to-command)
  - [List of running commands](#list-of-running-commands)
- [Possible improvments](#todo)

## Installation

Lazy config

```lua
{
  "dimaportenko/project-cli-commands.nvim",

  dependencies = {
    "akinsho/toggleterm.nvim",
    "nvim-telescope/telescope.nvim",
  },

  -- optional keymap config
  config = function()
    local OpenActions = require('project_cli_commands.open_actions')
    local RunActions = require('project_cli_commands.actions')

    local config = {
      -- Key mappings bound inside the telescope window
      running_telescope_mapping = {
        ['<C-c>'] = RunActions.exit_terminal,
        ['<C-f>'] = RunActions.open_float,
        ['<C-v>'] = RunActions.open_vertical,
        ['<C-h>'] = RunActions.open_horizontal,
      },
      open_telescope_mapping = {
        { mode = 'i', key = '<CR>',  action = OpenActions.execute_script_vertical },
        { mode = 'n', key = '<CR>',  action = OpenActions.execute_script_vertical },
        { mode = 'i', key = '<C-h>', action = OpenActions.execute_script },
        { mode = 'n', key = '<C-h>', action = OpenActions.execute_script },
        { mode = 'i', key = '<C-i>', action = OpenActions.execute_script_with_input },
        { mode = 'n', key = '<C-i>', action = OpenActions.execute_script_with_input },
        { mode = 'i', key = '<C-c>', action = OpenActions.copy_command_clipboard },
        { mode = 'n', key = '<C-c>', action = OpenActions.copy_command_clipboard },
        { mode = 'i', key = '<C-f>', action = OpenActions.execute_script_float },
        { mode = 'n', key = '<C-f>', action = OpenActions.execute_script_float },
        { mode = 'i', key = '<C-v>', action = OpenActions.execute_script_vertical },
        { mode = 'n', key = '<C-v>', action = OpenActions.execute_script_vertical },
      }
    }

    require('project_cli_commands').setup(config)
  end
}
```

## Usage

### Commands Configuration

Configuration is stored in `.nvim/config.json`. If you don't have `config.json` and run `Telescope project_cli_commands open` it will ask you to create new config for you.

Example of `config.json`:

```json
{
  "env": ".env",
  "commands": {
    "ls:la": "ls -tls",
    "current:ls": "ls -la ${currentBuffer}",
    "print:env": "echo $EXPO_TOKEN",
    "print:env:local": {
      "cmd": "echo $EXPO_TOKEN",
      "env": ".env.local",
      "after": "Telescope find_files"
    }
  }
}
```

- `env` - (optional) path to the environment file. It will be loaded before running the command.
- `commands` - list of termainal commands.
  - `key` - command name.
  - `value` - (string) terminal command to run.
  - `value` - (table) command configuration.
    - `cmd` - terminal command to run.
    - `env` - (optional) path to the environment file. It will be loaded before running the command.
    - `after` - (optional) neovim command to run after the terminal command.

### Telescope commands

- `Telescope project_cli_commands open` - open telescope with list of commands from `config.json`. Where you can pick one to run.
- `Telescope project_cli_commands running` - open telescope with list of running commands. Where you can toggle terminal for it or stop them.

### Keymap

```lua
--
vim.api.nvim_set_keymap("n", "<leader>p", ":Telescope project_cli_commands open<cr>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>;", ":Telescope project_cli_commands running<cr>", { noremap = true, silent = true })
```

## Features

#### Open terminal with command

You can open terminal for command in float, vertical and horizontal mode.

#### Run command with input

You can run command with input. Basic use case is when you want to add extra arguments to your terminal command.

#### Copy command to clipboard

By pressing `Ctrl+c` (default keymap) you can copy command to clipboard.

#### Run command after

You can run neovim command after terminal command is finished.

#### Environment variables

You can load environment variables from file before running the command.

#### Inject current buffer path to command

For example you would like to run test for current buffer you can configure it like this

```json
{
  "commands": {
    "test:current": "jest ${currentBuffer}"
  }
}
```

#### List of running commands

You can open list of running commands with `Telescope project_cli_commands running`. There you can show/hide terminal for each command. Or you can stop running command.

## TODO

- [x] keymap open toggleterm with different positions (e.g. float like rnstart cmd)
- [x] merge telescope-toggleterm plugin with this one
- [x] add vertical open option
- [x] add keymaps config
- [x] add new config templates setup
- [x] add environment variables to run commands
- [x] table config for commands
- [x] after command (e.g. run 'LspRestart' after terminal command)
- [ ] current directory path variable ${currentDirectory}
- [ ] scroll preview content
- [ ] copy to clipboard with ${currentBuffer}

- [ ] add readme
  - [x] add installation instructions
  - [x] keymaps setup
  - [x] features description and examples
  - [ ] demo gif
  - [ ] full demo video (maybe on youtube)
