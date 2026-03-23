local M = {}

local notifyError = function(message)
  vim.notify(message, vim.log.levels.ERROR)
end

local createDirIfNotExists = function(filePath)
  -- Check if directory exists
  if vim.fn.isdirectory(filePath) == 0 then -- Create the directory
    -- Create the directory
    local success = vim.fn.mkdir(filePath, "p")
    if success == -1 then
      error("Error creating directory: " .. filePath)
    end
    print(".nvim directory created.")
  else
    print(".nvim directory already exists.")
  end

  return true
end

local readFile = function(filePath)
  local file = io.open(filePath, "rb")
  if file == nil then
    return nil
  end

  local fileContent = file:read "*a"
  file:close()

  return fileContent
end

local decodeJson = function(jsonString, filePath, configName)
  local ok, decoded = pcall(vim.fn.json_decode, jsonString)
  if not ok then
    return nil, string.format("Invalid %s config JSON at %s: %s", configName, filePath, decoded)
  end

  if type(decoded) ~= "table" then
    return nil, string.format("Invalid %s config JSON at %s: root value must be an object", configName, filePath)
  end

  return decoded, nil
end

local mergeConfig = function(globalConfig, projectConfig, globalDirPath, projectDirPath)
  local mergedConfig = {}
  local commandBaseDirs = {}
  local envBaseDir

  local function applyConfig(config, baseDirPath)
    if type(config) ~= "table" then
      return
    end

    for key, value in pairs(config) do
      if key == "commands" and type(value) == "table" then
        if type(mergedConfig.commands) ~= "table" then
          mergedConfig.commands = {}
        end

        for commandName, commandConfig in pairs(value) do
          mergedConfig.commands[commandName] = commandConfig
          commandBaseDirs[commandName] = baseDirPath
        end
      else
        mergedConfig[key] = value
        if key == "env" then
          envBaseDir = baseDirPath
        end
      end
    end
  end

  applyConfig(globalConfig, globalDirPath)
  applyConfig(projectConfig, projectDirPath)

  return {
    config = mergedConfig,
    envBaseDir = envBaseDir,
    commandBaseDirs = commandBaseDirs,
  }
end


M.openConfigFile = function()
  local projectDirPath = vim.fn.getcwd() .. '/.nvim'
  local projectConfigPath = projectDirPath .. '/config.json'
  local globalDirPath = vim.fn.expand('~/.config/nvim')
  local globalConfigPath = globalDirPath .. '/config.json'

  local globalConfigString = readFile(globalConfigPath)
  local globalConfig
  if globalConfigString ~= nil then
    local decodeError
    globalConfig, decodeError = decodeJson(globalConfigString, globalConfigPath, "global")
    if decodeError ~= nil then
      notifyError(decodeError)
      return nil, decodeError
    end
  end

  local projectConfigString = readFile(projectConfigPath)
  local projectConfig
  if projectConfigString == nil and globalConfig == nil then
    local choice
    repeat
      choice = vim.fn.input("No config found (neither ~/.config/nvim/config.json nor .nvim/config.json). Create .nvim/config.json? (y/n): ")
    until choice == 'y' or choice == 'n'

    if choice == 'y' then
      if createDirIfNotExists(projectDirPath) == false then
        error("Can't create .nvim directory.")
      end
      -- Create a new file and write an empty table
      local new_file = io.open(projectConfigPath, "w")
      if new_file == nil then
        error(".nvim/config.json could not be created.")
      end

      new_file:write("{\n  \"commands\": {\n    \"ls:la\": \"ls -la\"\n   }\n}\n")
      new_file:close()

      print(".nvim/config.json created with an empty table.")
      vim.api.nvim_command('edit ' .. projectConfigPath)
    end
    return nil, ".nvim/config.json isn't found."
  end

  if projectConfigString ~= nil then
    local decodeError
    projectConfig, decodeError = decodeJson(projectConfigString, projectConfigPath, "project")
    if decodeError ~= nil then
      notifyError(decodeError)
      return nil, decodeError
    end
  end

  local mergedConfig = mergeConfig(globalConfig, projectConfig, globalDirPath, projectDirPath)
  return mergedConfig, nil
end

M.readEnvFromFile = function(filepath)
  local env_table = {}
  for line in io.lines(filepath) do
    local key, value = string.match(line, "([^=]+)=(.+)")
    if key and value then
      env_table[key] = value
    end
  end
  return env_table
end

M.getEnvTable = function(filepath, baseDirPath)
  local envTable
  if filepath then
    local envFilePath
    if filepath:sub(1, 1) == '/' then
      envFilePath = filepath
    else
      local envBaseDir = baseDirPath or (vim.fn.getcwd() .. '/.nvim')
      envFilePath = envBaseDir .. '/' .. filepath
    end
    envTable = M.readEnvFromFile(envFilePath)
  end
  return envTable
end

return M
