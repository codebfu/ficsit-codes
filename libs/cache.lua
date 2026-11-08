--[[ Cache Management Library ]]--

-- Cache storage
local cache = {
    programs = {},
    libraries = {},
    metadata = {}
}

-- Cache configuration
local CACHE_CONFIG = {
    enabled = true,
    maxSize = 100, -- MB
    maxAge = 86400, -- seconds (24 hours)
    cacheDir = "/cache"
}

-- Initialize cache
function initCache(config)
    if config then
        CACHE_CONFIG.enabled = config.enabled ~= false
        CACHE_CONFIG.maxSize = config.maxSize or CACHE_CONFIG.maxSize
        CACHE_CONFIG.maxAge = config.maxAge or CACHE_CONFIG.maxAge
        CACHE_CONFIG.cacheDir = config.cacheDir or CACHE_CONFIG.cacheDir
    end
    
    if CACHE_CONFIG.enabled then
        if not fs.isDir(CACHE_CONFIG.cacheDir) then
            fs.createDir(CACHE_CONFIG.cacheDir)
        end
    end
end

-- Get cache entry
function getCacheEntry(type, name)
    if not CACHE_CONFIG.enabled then return nil end
    
    local cacheKey = type .. ":" .. name
    if cache[cacheKey] then
        -- Check if cache is still valid
        if os.time() - cache[cacheKey].timestamp < CACHE_CONFIG.maxAge then
            return cache[cacheKey].data
        else
            -- Cache expired, remove it
            cache[cacheKey] = nil
        end
    end
    
    -- Try to load from disk
    local filePath = CACHE_CONFIG.cacheDir .. "/" .. cacheKey
    if fs.isFile(filePath) then
        local file = fs.open(filePath, "r")
        local data = file:read(65535)
        file:close()
        
        -- Check metadata
        local metaPath = filePath .. ".meta"
        local meta = {}
        if fs.isFile(metaPath) then
            local metaFile = fs.open(metaPath, "r")
            local metaData = metaFile:read(65535)
            metaFile:close()
            meta = textutils.unserialize(metaData) or {}
        end
        
        -- Update cache
        cache[cacheKey] = {
            data = data,
            timestamp = os.time(),
            metadata = meta
        }
        
        return data
    end
    
    return nil
end

-- Set cache entry
function setCacheEntry(type, name, data, metadata)
    if not CACHE_CONFIG.enabled then return end
    
    local cacheKey = type .. ":" .. name
    cache[cacheKey] = {
        data = data,
        timestamp = os.time(),
        metadata = metadata or {}
    }
    
    -- Save to disk
    local filePath = CACHE_CONFIG.cacheDir .. "/" .. cacheKey
    local file = fs.open(filePath, "w")
    file:write(data)
    file:close()
    
    -- Save metadata
    local metaPath = filePath .. ".meta"
    local metaFile = fs.open(metaPath, "w")
    metaFile:write(textutils.serialize(metadata or {}))
    metaFile:close()
end

-- Invalidate cache entry
function invalidateCacheEntry(type, name)
    local cacheKey = type .. ":" .. name
    cache[cacheKey] = nil
    
    local filePath = CACHE_CONFIG.cacheDir .. "/" .. cacheKey
    if fs.isFile(filePath) then
        fs.remove(filePath)
    end
    
    local metaPath = filePath .. ".meta"
    if fs.isFile(metaPath) then
        fs.remove(metaPath)
    end
end

-- Clear cache
function clearCache()
    cache = { programs = {}, libraries = {}, metadata = {}}
    
    if CACHE_CONFIG.enabled and fs.isDir(CACHE_CONFIG.cacheDir) then
        for _, file in ipairs(fs.list(CACHE_CONFIG.cacheDir)) do
            fs.remove(CACHE_CONFIG.cacheDir .. "/" .. file)
        end
    end
end

-- Get cache size
function getCacheSize()
    local size = 0
    for _, entry in pairs(cache) do
        size = size + #entry.data
    end
    return size
end

-- Check if cache entry exists
function hasCacheEntry(type, name)
    if not CACHE_CONFIG.enabled then return false end
    
    local cacheKey = type .. ":" .. name
    if cache[cacheKey] then
        return true
    end
    
    local filePath = CACHE_CONFIG.cacheDir .. "/" .. cacheKey
    return fs.isFile(filePath)
end

return {
    init = initCache,
    get = getCacheEntry,
    set = setCacheEntry,
    invalidate = invalidateCacheEntry,
    clear = clearCache,
    size = getCacheSize,
    has = hasCacheEntry
}
