-- Tracks terminals started by this plugin and stops them when Neovim exits.
--
-- toggleterm starts every terminal with `detach = 1`, and Neovim does not stop
-- detached jobs on exit, so long-running commands (dev servers, watchers) would
-- otherwise outlive the editor and keep their ports busy.

local M = {}

-- Terminal objects created by this plugin. Weak keys so terminals that
-- toggleterm has dropped can be garbage collected.
local tracked = setmetatable({}, { __mode = "k" })

M.track = function(term)
  tracked[term] = true
end

local function stop(job_id)
  -- The pty child is a session and process group leader, so signalling the
  -- negative pid also reaches grandchildren (e.g. pnpm -> node -> next-server).
  local ok, pid = pcall(vim.fn.jobpid, job_id)
  if ok and pid and pid > 0 then
    pcall(vim.uv.kill, -pid, "sigterm")
  end
  pcall(vim.fn.jobstop, job_id)
end

M.stop_all = function()
  for term in pairs(tracked) do
    if term.job_id then
      stop(term.job_id)
    end
  end
end

-- Registers (or, when disabled, removes) the VimLeavePre cleanup. Safe to call
-- again when setup() runs more than once.
M.setup = function(enabled)
  local group = vim.api.nvim_create_augroup("ProjectCliCommandsCleanup", { clear = true })
  if not enabled then
    return
  end
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = M.stop_all,
  })
end

return M
