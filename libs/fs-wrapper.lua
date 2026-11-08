--[[ Filesystem Access Wrapper with Retry Logic ]]--

-- Configuration
local FS_RETRY_CONFIG = {
    maxRetries = 5,
    initialDelay = 1,
    maxDelay = 30,
    exponentialBackoff = true
}

-- Initialize with custom configuration
function initFSWrapper(config)
    if config then
        FS_RETRY_CONFIG.maxRetries = config.maxRetries or FS_RETRY_CONFIG.maxRetries
        FS_RETRY_CONFIG.initialDelay = config.initialDelay or FS_RETRY_CONFIG.initialDelay
        FS_RETRY_CONFIG.maxDelay = config.maxDelay or FS_RETRY_CONFIG.maxDelay
        FS_RETRY_CONFIG.exponentialBackoff = config.exponentialBackoff ~= false
    end
end

-- Check if filesystem is ready
local function isFSReady()
    -- Try a simple filesystem operation to check if it's ready
    local success = pcall(function()
        return filesystem.isDir("/")
    end)
    return success
end

-- Wait for filesystem to be ready
local function waitForFS(timeout)
    local startTime = os.time()
    local delay = FS_RETRY_CONFIG.initialDelay
    
    while not isFSReady() do
        if timeout and os.time() - startTime >= timeout then
            return false, "Timeout waiting for filesystem"
        end
        
        event.pull(delay)
        
        -- Exponential backoff
        if FS_RETRY_CONFIG.exponentialBackoff then
            delay = math.min(delay * 2, FS_RETRY_CONFIG.maxDelay)
        end
    end
    
    return true
end

-- Wrapped filesystem operations with retry logic
local function fsOperationWithRetry(operation, ...)
    local attempt = 0
    local lastError = nil
    
    while attempt < FS_RETRY_CONFIG.maxRetries do
        attempt = attempt + 1
        
        -- Check if filesystem is ready
        if not isFSReady() then
            local success, err = waitForFS(FS_RETRY_CONFIG.maxDelay * 2)
            if not success then
                return false, err
            end
        end
        
        -- Try the operation
        local success, result = pcall(operation, ...)
        
        if success then
            return true, result
        else
            lastError = result
            
            -- If it's a filesystem-specific error, wait and retry
            if string.find(result, "filesystem") or string.find(result, "FS") then
                local delay = FS_RETRY_CONFIG.initialDelay * math.pow(2, attempt - 1)
                delay = math.min(delay, FS_RETRY_CONFIG.maxDelay)
                event.pull(delay)
            else
                -- Non-retryable error
                return false, result
            end
        end
    end
    
    return false, lastError
end

-- Wrapped filesystem functions
function fsCreateDir(path, recursive)
    local success, result = fsOperationWithRetry(function()
        return filesystem.createDir(path, recursive)
    end)
    return success and result or false
end

function fsIsDir(path)
    local success, result = fsOperationWithRetry(function()
        return filesystem.isDir(path)
    end)
    return success and result or false
end

function fsIsFile(path)
    local success, result = fsOperationWithRetry(function()
        return filesystem.isFile(path)
    end)
    return success and result or false
end

function fsOpen(path, mode)
    local success, result = fsOperationWithRetry(function()
        return filesystem.open(path, mode)
    end)
    return success and result or nil
end

function fsMount(source, target)
    local success, result = fsOperationWithRetry(function()
        return filesystem.mount(source, target)
    end)
    return success and result or false
end

function fsUnmount(target)
    local success, result = fsOperationWithRetry(function()
        return filesystem.unmount(target)
    end)
    return success and result or false
end

function fsList(path)
    local success, result = fsOperationWithRetry(function()
        return filesystem.list(path)
    end)
    return success and result or {}
end

function fsRemove(path)
    local success, result = fsOperationWithRetry(function()
        return filesystem.remove(path)
    end)
    return success and result or false
end

-- Filesystem state monitoring
function monitorFSState(callback, interval)
    interval = interval or 5
    
    while true do
        local ready = isFSReady()
        if callback then
            callback(ready)
        end
        
        event.pull(interval)
    end
end

return {
    init = initFSWrapper,
    isReady = isFSReady,
    waitForReady = waitForFS,
    createDir = fsCreateDir,
    isDir = fsIsDir,
    isFile = fsIsFile,
    open = fsOpen,
    mount = fsMount,
    unmount = fsUnmount,
    list = fsList,
    remove = fsRemove,
    monitor = monitorFSState
}
