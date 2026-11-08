--[[ Update Management Library ]]--

-- Update configuration
local UPDATE_CONFIG = {
    checkInterval = 3600, -- 1 hour
    autoUpdate = true,
    updateServer = "https://raw.githubusercontent.com/codebfu/ficsit-codes/master",
    lastCheck = 0
}

-- Program versions
local programVersions = {}

-- Library versions
local libraryVersions = {}

-- Initialize update management
function initUpdateManagement(config)
    if config then
        UPDATE_CONFIG.checkInterval = config.checkInterval or UPDATE_CONFIG.checkInterval
        UPDATE_CONFIG.autoUpdate = config.autoUpdate ~= false
        UPDATE_CONFIG.updateServer = config.updateServer or UPDATE_CONFIG.updateServer
    end
    
    UPDATE_CONFIG.lastCheck = os.time()
end

-- Set program version
function setProgramVersion(name, version)
    programVersions[name] = version
end

-- Set library version
function setLibraryVersion(name, version)
    libraryVersions[name] = version
end

-- Get current version of a program
function getProgramVersion(name)
    return programVersions[name]
end

-- Get current version of a library
function getLibraryVersion(name)
    return libraryVersions[name]
end

-- Check for updates (simplified - would use HTTP in real implementation)
function checkForUpdates()
    if os.time() - UPDATE_CONFIG.lastCheck < UPDATE_CONFIG.checkInterval then
        return false -- No need to check yet
    end
    
    UPDATE_CONFIG.lastCheck = os.time()
    
    -- In a real implementation, this would fetch update information from the server
    -- For now, we'll simulate finding updates
    
    local updates = {}
    
    -- Simulate checking program versions
    for name, _ in pairs(programVersions) do
        local latestVersion = getLatestVersion(name, "program")
        if latestVersion and latestVersion ~= programVersions[name] then
            updates.programs = updates.programs or {}
            updates.programs[name] = latestVersion
        end
    end
    
    -- Simulate checking library versions
    for name, _ in pairs(libraryVersions) do
        local latestVersion = getLatestVersion(name, "library")
        if latestVersion and latestVersion ~= libraryVersions[name] then
            updates.libraries = updates.libraries or {}
            updates.libraries[name] = latestVersion
        end
    end
    
    return next(updates) ~= nil, updates
end

-- Simulate getting latest version from server
function getLatestVersion(name, type)
    -- In a real implementation, this would fetch version info from the server
    -- For simulation, we'll return a mock version
    
    if type == "program" then
        -- Simulate version format: "1.0.0"
        return "1.1.0"
    elseif type == "library" then
        return "1.0.1"
    end
    
    return nil
end

-- Apply updates
function applyUpdates(updates, callback)
    local applied = { programs = {}, libraries = {} }
    
    -- Apply program updates
    if updates.programs then
        for name, version in pairs(updates.programs) do
            -- In a real implementation, this would download and install the update
            computer.log(2, "Updating program: " .. name .. " to version " .. version)
            
            -- Simulate update
            programVersions[name] = version
            applied.programs[name] = version
            
            -- Invalidate cache for this program
            local cache = getLibrary("cache")
            if cache then
                cache.invalidate("program", name)
            end
        end
    end
    
    -- Apply library updates
    if updates.libraries then
        for name, version in pairs(updates.libraries) do
            -- In a real implementation, this would download and install the update
            computer.log(2, "Updating library: " .. name .. " to version " .. version)
            
            -- Simulate update
            libraryVersions[name] = version
            applied.libraries[name] = version
            
            -- Invalidate cache for this library
            local cache = getLibrary("cache")
            if cache then
                cache.invalidate("library", name)
            end
        end
    end
    
    if callback then
        callback(applied)
    end
    
    return applied
end

-- Check if a program needs update
function needsProgramUpdate(name)
    local currentVersion = programVersions[name]
    local latestVersion = getLatestVersion(name, "program")
    
    return currentVersion ~= latestVersion
end

-- Check if a library needs update
function needsLibraryUpdate(name)
    local currentVersion = libraryVersions[name]
    local latestVersion = getLatestVersion(name, "library")
    
    return currentVersion ~= latestVersion
end

-- Get all available updates
function getAvailableUpdates()
    local updates = { programs = {}, libraries = {} }
    
    for name, version in pairs(programVersions) do
        local latestVersion = getLatestVersion(name, "program")
        if latestVersion and latestVersion ~= version then
            updates.programs[name] = { current = version, latest = latestVersion }
        end
    end
    
    for name, version in pairs(libraryVersions) do
        local latestVersion = getLatestVersion(name, "library")
        if latestVersion and latestVersion ~= version then
            updates.libraries[name] = { current = version, latest = latestVersion }
        end
    end
    
    return updates
end

return {
    init = initUpdateManagement,
    setProgramVersion = setProgramVersion,
    setLibraryVersion = setLibraryVersion,
    getProgramVersion = getProgramVersion,
    getLibraryVersion = getLibraryVersion,
    checkForUpdates = checkForUpdates,
    applyUpdates = applyUpdates,
    needsProgramUpdate = needsProgramUpdate,
    needsLibraryUpdate = needsLibraryUpdate,
    getAvailableUpdates = getAvailableUpdates
}
