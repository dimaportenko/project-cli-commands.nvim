
local M = {}

M.getSubstringAfterSecondSlash = function(input)
    local first = string.find(input, "//")
    if first then
        local second = string.find(input, "//", first + 1)
        if second then
            return string.sub(input, second + 2)
        end
    end
    return nil
end

return M
