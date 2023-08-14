local actions_state
local actions
if pcall(require, "telescope") then
  actions_state = require "telescope.actions.state"
  actions = require "telescope.actions"
else
  error "Cannot find telescope!"
end

local toggle_term = require("project_cli_commands.term_utils").toggle_term

local M = {}

function M.exit_terminal(prompt_bufnr)
  local selection = actions_state.get_selected_entry()
  if selection == nil then
    return
  end
  local bufnr = selection.value.bufnr
  local current_picker = actions_state.get_current_picker(prompt_bufnr)
  current_picker:delete_selection(function(_) -- _ is selection
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
end

function M.open_float(prompt_bufnr)
  M.open(prompt_bufnr, "float")
end

function M.open(prompt_bufnr, direction)
  direction = direction or "horizontal"
  actions.close(prompt_bufnr)
  local selection = actions_state.get_selected_entry()
  if selection == nil then
    return
  end
  local bufnr = tostring(selection.value.bufnr)
  toggle_term(bufnr, direction)
end

return M
