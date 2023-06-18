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


return M
