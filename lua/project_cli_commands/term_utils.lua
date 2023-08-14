local terminal = require("toggleterm.terminal")

local M = {}

M.next_id = function ()
  local all = terminal.get_all(true)
  local max_id = -1
  for _, term in pairs(all) do
    if term.id > max_id then
      max_id = term.id
    end
  end
  if max_id < 10 then
    return 10
  else
    return max_id + 1
  end
end

M.toggle_term = function (bfnr, direction)
   direction = direction or "horizontal"
   local bufnr = tonumber(bfnr)
   local all_terminals = require("toggleterm.terminal").get_all(true)
   local id = nil
   for _, term in pairs(all_terminals) do
      if term.bufnr == bufnr then
         id = term.id
      end
   end

   if id then
      require("toggleterm").toggle(id, nil, nil, direction)
   else
      id = M.next_id()
      ---@diagnostic disable-next-line: param-type-mismatch
      if vim.api.nvim_buf_is_valid(bufnr) == false then
         error("bufnr is not valid")
      end

      local cmdTerm = require("toggleterm.terminal").Terminal:new({
         id            = id,
         bufnr         = bufnr,
         hidden        = true,
         close_on_exit = false,
         direction     = direction,
      })
      cmdTerm:toggle()
   end
end



return M
