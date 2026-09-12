local actions = require('telescope.actions')
local state = require('telescope.actions.state')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local sorters = require('telescope.sorters')

local M = {}

local function extract_placeholder_names(cmd)
  local seen = {}
  local names = {}
  for name in cmd:gmatch("%${([^}]+)}") do
    if name ~= "currentBuffer" and not seen[name] then
      seen[name] = true
      table.insert(names, name)
    end
  end
  return names
end

local function validate(cmd, placeholders)
  local cmd_names = extract_placeholder_names(cmd)

  for _, name in ipairs(cmd_names) do
    if not placeholders[name] then
      return "placeholder '${" .. name .. "}' in cmd has no entry in placeholders"
    end
  end

  local cmd_names_set = {}
  for _, name in ipairs(cmd_names) do
    cmd_names_set[name] = true
  end

  for name, _ in pairs(placeholders) do
    if name == "currentBuffer" then
      return "'currentBuffer' is reserved and cannot be used as a placeholder name"
    end
    if not cmd_names_set[name] then
      return "placeholders key '" .. name .. "' has no matching '${" .. name .. "}' in cmd"
    end
  end

  for _, name in ipairs(cmd_names) do
    local values = placeholders[name]
    if type(values) ~= "table" then
      return "placeholders '" .. name .. "' must be a non-empty list"
    end
    local count = 0
    for i, item in ipairs(values) do
      count = i
      if type(item) == "table" then
        if type(item.value) ~= "string" then
          return "placeholders '" .. name .. "' item " .. i .. " must have a string value"
        end
        if item.label ~= nil and type(item.label) ~= "string" then
          return "placeholders '" .. name .. "' item " .. i .. " label must be a string"
        end
      elseif type(item) ~= "string" then
        return "placeholders '" .. name .. "' item " .. i .. " must be a string or { label, value }"
      end
    end
    if count == 0 then
      return "placeholders '" .. name .. "' must be a non-empty list"
    end
  end

  return nil
end

local function placeholder_entry(item)
  if type(item) == 'table' then
    local display = item.label or item.value
    return {
      value = item.value,
      display = display,
      ordinal = display .. ' ' .. item.value,
    }
  end
  return {
    value = item,
    display = item,
    ordinal = item,
  }
end

local function resolve_sequential(cmd, placeholders, resolved, names, index, callback, cancel_state, main_prompt_bufnr)
  if index > #names then
    local result = cmd
    for name, value in pairs(resolved) do
      result = result:gsub("%${" .. vim.pesc(name) .. "}", value)
    end
    callback(result)
    return
  end

  if cancel_state.cancelled then
    if main_prompt_bufnr then
      pcall(actions.close, main_prompt_bufnr)
    end
    return
  end

  local name = names[index]
  local values = placeholders[name]

  pickers.new({}, {
    prompt_title = "Select " .. name .. ":",
    finder = finders.new_table {
      results = values,
      entry_maker = placeholder_entry,
    },
    sorter = sorters.get_generic_fuzzy_sorter(),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection and type(selection.value) == 'string' then
          resolved[name] = selection.value
          resolve_sequential(cmd, placeholders, resolved, names, index + 1, callback, cancel_state, main_prompt_bufnr)
        else
          cancel_state.cancelled = true
          if main_prompt_bufnr then
            pcall(actions.close, main_prompt_bufnr)
          end
          vim.notify("project-cli-commands: no value selected for '" .. name .. "'", vim.log.levels.WARN)
        end
      end)
      map('i', '<Esc>', function()
        cancel_state.cancelled = true
        actions.close(prompt_bufnr)
        if main_prompt_bufnr then
          pcall(actions.close, main_prompt_bufnr)
        end
        vim.notify("project-cli-commands: placeholder selection cancelled", vim.log.levels.WARN)
      end)
      return true
    end,
  }):find()
end

M.resolve = function(cmd, placeholders, callback, main_prompt_bufnr)
  if type(placeholders) ~= "table" then
    vim.notify("project-cli-commands: placeholders must be a table", vim.log.levels.WARN)
    return
  end

  local err = validate(cmd, placeholders)
  if err then
    vim.notify("project-cli-commands: " .. err, vim.log.levels.WARN)
    return
  end

  local names = extract_placeholder_names(cmd)

  if #names == 0 then
    callback(cmd)
    return
  end

  resolve_sequential(cmd, placeholders, {}, names, 1, callback, { cancelled = false }, main_prompt_bufnr)
end

return M
