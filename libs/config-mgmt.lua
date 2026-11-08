--[[ Configuration Management Library ]]--

-- Configuration storage location
local CONFIG_STORAGE = "/floppy/config"

-- Default configuration template
local DEFAULT_CONFIG = {
    programName = "",
    version = "1.0.0",
    lastUpdated = 0,
    settings = {}
}

-- Initialize configuration management
function initConfigManagement(storagePath)
    if storagePath then
        CONFIG_STORAGE = storagePath
    end
    
    -- Ensure config directory exists
    if not fs.isDir(CONFIG_STORAGE) then
        fs.createDir(CONFIG_STORAGE)
    end
end

-- Get configuration path for a program
local function getConfigPath(programName)
    return CONFIG_STORAGE .. "/" .. programName .. ".cfg"
end

-- Load configuration for a program
function loadConfig(programName)
    local configPath = getConfigPath(programName)
    
    if not fs.isFile(configPath) then
        -- Create default configuration
        return createDefaultConfig(programName)
    end
    
    local file = fs.open(configPath, "r")
    if not file then
        return createDefaultConfig(programName)
    end
    
    local configData = file:read(65535)
    file:close()
    
    local config = textutils.unserialize(configData)
    if not config then
        return createDefaultConfig(programName)
    end
    
    return config
end

-- Create default configuration
function createDefaultConfig(programName)
    local config = table.copy(DEFAULT_CONFIG)
    config.programName = programName
    config.lastUpdated = os.time()
    
    saveConfig(programName, config)
    return config
end

-- Save configuration for a program
function saveConfig(programName, config)
    if not config then
        return false
    end
    
    -- Update metadata
    config.programName = programName
    config.lastUpdated = os.time()
    
    local configPath = getConfigPath(programName)
    local file = fs.open(configPath, "w")
    if not file then
        return false
    end
    
    local success = file:write(textutils.serialize(config))
    file:close()
    
    return success
end

-- Update program settings
function updateSettings(programName, settings)
    local config = loadConfig(programName)
    
    if not config then
        return false
    end
    
    -- Merge settings
    if type(settings) == "table" then
        for key, value in pairs(settings) do
            config.settings[key] = value
        end
    end
    
    return saveConfig(programName, config)
end

-- Get program settings
function getSettings(programName)
    local config = loadConfig(programName)
    return config and config.settings or {}
end

-- Get configuration metadata
function getConfigMetadata(programName)
    local config = loadConfig(programName)
    if not config then
        return nil
    end
    
    return {
        programName = config.programName,
        version = config.version,
        lastUpdated = config.lastUpdated
    }
end

-- Check if configuration exists
function configExists(programName)
    local configPath = getConfigPath(programName)
    return fs.isFile(configPath)
end

-- Delete configuration
function deleteConfig(programName)
    local configPath = getConfigPath(programName)
    if fs.isFile(configPath) then
        return fs.remove(configPath)
    end
    return false
end

-- List all configured programs
function listConfiguredPrograms()
    local programs = {}
    
    if not fs.isDir(CONFIG_STORAGE) then
        return programs
    end
    
    for _, file in ipairs(fs.list(CONFIG_STORAGE)) do
        if string.match(file, "%.cfg$`) then
            local programName = string.sub(file, 1, -5) -- Remove .cfg extension
            table.insert(programs, programName)
        end
    end
    
    return programs
end

-- Validate configuration
function validateConfig(config, schema)
    if not config then
        return false, "Configuration is nil"
    end
    
    if schema and type(schema) == "table" then
        -- Basic schema validation
        for field, fieldType in pairs(schema) do
            if config[field] ~= nil and type(config[field]) ~= fieldType then
                return false, string.format("Field '%s' should be of type %s", field, fieldType)
            end
        end
    end
    
    return true
end

-- Migrate configuration format
function migrateConfig(programName, oldFormat)
    local config = loadConfig(programName)
    
    if oldFormat == "v1" then
        -- Handle migration from v1 format
        if config.settings and type(config.settings) == "string" then
            -- Old format stored settings as string, convert to table
            local settings = textutils.unserialize(config.settings)
            if settings and type(settings) == "table" then
                config.settings = settings
                saveConfig(programName, config)
                return true
            end
        end
    end
    
    return false
end

-- Get configuration backup
function backupConfig(programName)
    local config = loadConfig(programName)
    if not config then
        return nil
    end
    
    local backupPath = CONFIG_STORAGE .. "/" .. programName .. ".bak"
    local file = fs.open(backupPath, "w")
    if not file then
        return nil
    end
    
    local success = file:write(textutils.serialize(config))
    file:close()
    
    return success
end

-- Restore configuration from backup
function restoreConfig(programName)
    local backupPath = CONFIG_STORAGE .. "/" .. programName .. ".bak"
    if not fs.isFile(backupPath) then
        return false
    end
    
    local file = fs.open(backupPath, "r")
    if not file then
        return false
    end
    
    local configData = file:read(65535)
    file:close()
    
    local config = textutils.unserialize(configData)
    if not config then
        return false
    end
    
    return saveConfig(programName, config)
end

return {
    init = initConfigManagement,
    load = loadConfig,
    save = saveConfig,
    update = updateSettings,
    get = getSettings,
    getMetadata = getConfigMetadata,
    exists = configExists,
    delete = deleteConfig,
    list = listConfiguredPrograms,
    validate = validateConfig,
    migrate = migrateConfig,
    backup = backupConfig,
    restore = restoreConfig
}
