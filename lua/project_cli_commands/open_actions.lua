local actions = require('telescope.actions')
local state = require('telescope.actions.state')

local Terminal = require("toggleterm.terminal").Terminal

local next_id = require("project_cli_commands.term_utils").next_id
local getEnvTable = require("project_cli_commands.file").getEnvTable


local M = {}

M.execute_script_with_params = function(prompt_bufnr, with_params, direction, size)
  direction = direction or "horizontal"

  local selection = state.get_selected_entry()
  actions.close(prompt_bufnr)

  local params = ''
  if with_params then
    params = ' ' .. vim.fn.input(selection.code .. ' ')
  end

  local id = next_id()
  -- Get the current buffer's full path
  local current_buffer_path = vim.fn.expand('%:p')

  local cmdLine = selection.value .. params

  -- Replace `${currentBuffer}` with the current buffer's path
  cmdLine = cmdLine:gsub("%${currentBuffer}", current_buffer_path)

  local termParams = {
    id            = id,
    cmd           = cmdLine,
    hidden        = true,
    close_on_exit = false,
    -- direction     = direction,
    -- size          = size,
  }

  local env
  if selection.env then
    env = getEnvTable(selection.env)
  end

  if not env then
    env = require('project_cli_commands').envTable
  end

  if env then
    termParams.env = env
  end

  local cmdTerm = Terminal:new(termParams)

  if selection.after then
    cmdTerm.on_exit = function()
      -- print("on_exit", selection.after)
      vim.cmd(selection.after)
    end
  end

  cmdTerm:toggle(size, direction)
  -- print(vim.inspect(scriptsFromJson[selection.value]))
  -- print(vim.inspect(selection.value))
end

M.execute_script = function(prompt_bufnr, direction, size)
  M.execute_script_with_params(prompt_bufnr, false, direction, size)
end

M.execute_script_vertical = function(prompt_bufnr)
  M.execute_script_with_params(prompt_bufnr, false, "vertical", math.floor(vim.o.columns / 2.5))
end

M.execute_script_float = function(prompt_bufnr)
  M.execute_script_with_params(prompt_bufnr, false, "float")
end

M.execute_script_with_input = function(prompt_bufnr)
  M.execute_script_with_params(prompt_bufnr, true)
end

M.copy_command_clipboard = function(prompt_bufnr)
  local selection = state.get_selected_entry()
  actions.close(prompt_bufnr)

  vim.fn.setreg('+', selection.code)
end

return M
