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
  - [Placeholder suggested values](#placeholder-suggested-values)
  - [Just integration](#just-integration)
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
      -- Optional: override the global config path
      -- Default: vim.fn.stdpath('config') .. '/project-cli-commands.config.json'
      -- global_config_path = vim.fn.stdpath('config') .. '/project-cli-commands.config.json',

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

Configuration can be stored in two places:

- Global config: `vim.fn.stdpath('config') .. '/project-cli-commands.config.json'` by default
- Project config: `.nvim/config.json`

Both files use the same JSON schema. When both files exist, the plugin merges them with this precedence:

- Project config overrides global config for top-level keys
- Commands with the same name are overridden by project config
- Keys that exist only in global config remain available

If neither file exists and you run `Telescope project_cli_commands open`, the plugin asks to create `.nvim/config.json` in the current project — unless the project has a [justfile](#just-integration), in which case its recipes are listed and you aren't asked for anything.

Example of `config.json`:

```json
{
  "env": ".env",
  "commands": {
    "ls:la": "ls -tls",
    "current:ls": "ls -la ${currentBuffer}",
    "print:env": "echo $EXPO_TOKEN",
    "print:env:local": {
      "name": "Print local token",
      "description": "Echo EXPO_TOKEN from .env.local",
      "cmd": "echo $EXPO_TOKEN",
      "env": ".env.local",
      "after": "Telescope find_files"
    }
  }
}
```

- `env` - (optional) path to the environment file. It will be loaded before running the command. Relative paths are resolved from the directory containing the config file that defines them — Neovim's config directory for global config and `.nvim/` for project config. Absolute paths are used as-is.
- `commands` - list of termainal commands.
  - `key` - command name.
  - `value` - (string) terminal command to run.
  - `value` - (table) command configuration.
    - `name` - (optional) display name shown in Telescope instead of the command key.
    - `description` - (optional) text shown in Telescope after `name` (or key if `name` is missing).
    - `cmd` - terminal command to run.
    - `env` - (optional) path to the environment file. It will be loaded before running the command.
    - `after` - (optional) neovim command to run after the terminal command.
    - `placeholders` - (optional) map of placeholder names to lists of allowed values: strings or `{ "label", "value" }` objects (see [Placeholder suggested values](#placeholder-suggested-values)).

Example merge behavior (global + project override):

Global `vim.fn.stdpath('config') .. '/project-cli-commands.config.json'`

```json
{
  "env": ".env.shared",
  "commands": {
    "test:all": "npm test",
    "lint": "npm run lint"
  }
}
```

Project `.nvim/config.json`

```json
{
  "commands": {
    "test:all": "pnpm test",
    "build": "pnpm build"
  }
}
```

Merged result used by the picker:

```json
{
  "env": ".env.shared",
  "commands": {
    "test:all": "pnpm test",
    "lint": "npm run lint",
    "build": "pnpm build"
  }
}
```

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

#### Placeholder suggested values

Use `${name}` tokens in your command and define a `placeholders` map to restrict each token to a predefined list of values. When the command is executed, a Telescope picker opens for each placeholder in order — the selected values are substituted before the terminal starts. Pressing `<Esc>` or `<C-c>` in any picker cancels the entire execution.

```json
{
  "commands": {
    "deploy": {
      "cmd": "deploy.sh --env ${environment} --region ${region}",
      "placeholders": {
        "environment": ["staging", "production"],
        "region": ["us-east-1", "eu-west-1", "ap-southeast-1"]
      }
    }
  }
}
```

Items may also be objects with a display `label` and a substituted `value`:

```json
{
  "placeholders": {
    "environment": [
      { "label": "Staging", "value": "staging" },
      { "label": "Production", "value": "production" }
    ],
    "region": [
      { "label": "US East (N. Virginia)", "value": "us-east-1" },
      { "label": "EU West (Ireland)", "value": "eu-west-1" },
      { "label": "Asia Pacific (Singapore)", "value": "ap-southeast-1" }
    ]
  }
}
```

- Multiple placeholders are resolved sequentially, left-to-right.
- The same resolved value is substituted for every occurrence of `${name}` in the command.
- List items are strings, or objects with a substituted `value` and optional display `label`. An empty string is a valid `value`.
- `${currentBuffer}` is always resolved automatically and cannot be used as a placeholder name.
- If a placeholder name in the map has no matching `${name}` token in `cmd`, or vice versa, a warning is shown and execution is aborted.
- If a placeholder list is empty, or an item is not a string or `{ label, value }` object, a warning is shown and execution is aborted.

#### Just integration

If the project has a [justfile](https://just.systems/), its recipes are listed in the
picker alongside the commands from `config.json` — no configuration needed. `just` does
the file lookup itself, so the same justfile it would pick from your current directory
(including ones in parent directories) is the one you see recipes from.

```
alpha       ||  echo alpha
lint        ||  npm run lint
build       ||  Build the project
deploy      ||  Deploy to an environment
```

Recipes are listed under their own name, after the commands from `config.json`. A
recipe and a command may share a name — both are listed, neither is hidden. Typing
`just` in the picker narrows the list to recipes.

The description column shows the recipe's doc comment, falling back to the first line
of its body when there isn't one.

- Private recipes (`[private]` or a leading underscore) are left out, as `just --list` leaves them out.
- Aliases are left out too, since the recipe an alias points at is already in the list.
- Recipes from imported modules are listed under their full path, e.g. `sub::inner`.
- A recipe with a parameter that has no default opens the input prompt so you can pass
  arguments, the same as pressing `<C-i>`.
- Recipes run without the environment from `env` — a justfile loads its own dotenv files
  via `set dotenv-load`, and layering both would give you two sets of rules for the same
  variables.

Nothing happens if `just` isn't installed or the project has no justfile. If a justfile
is there but can't be parsed, the error from `just` is reported.

To turn the integration off:

```lua
require('project_cli_commands').setup({
  just = {
    enabled = false,
  },
})
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
- [x] run recipes from a justfile
- [ ] current directory path variable ${currentDirectory}
- [ ] scroll preview content
- [ ] copy to clipboard with ${currentBuffer}

- [ ] add readme
  - [x] add installation instructions
  - [x] keymaps setup
  - [x] features description and examples
  - [ ] demo gif
  - [ ] full demo video (maybe on youtube)
