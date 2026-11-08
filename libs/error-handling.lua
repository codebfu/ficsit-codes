--[[ Error Handling and Retry Library ]]--

-- Configuration
local MAX_RETRIES = 3
local RETRY_DELAY = 5 -- seconds
local EXPONENTIAL_BACKOFF = true

-- Initialize configuration
function initErrorHandling(config)
    if config then
        MAX_RETRIES = config.maxRetries or MAX_RETRIES
        RETRY_DELAY = config.retryDelay or RETRY_DELAY
        EXPONENTIAL_BACKOFF = config.exponentialBackoff ~= false
    end
end

-- Execute function with retry logic
function withRetry(func, successCallback, errorCallback, context)
    local lastError = nil
    local attempt = 0
    
    while attempt < MAX_RETRIES do
        attempt = attempt + 1
        local success, result = pcall(func)
        
        if success then
            if successCallback then
                successCallback(result, context)
            end
            return true, result
        else
            lastError = result
            
            if errorCallback then
                errorCallback(result, attempt, MAX_RETRIES, context)
            end
            
            if attempt < MAX_RETRIES then
                local delay = RETRY_DELAY
                if EXPONENTIAL_BACKOFF then
                    delay = RETRY_DELAY * math.pow(2, attempt - 1)
                end
                
                computer.log(3, string.format("Retry %d/%d in %d seconds: %s", 
                    attempt, MAX_RETRIES, delay, tostring(result)))
                
                event.pull(delay)
            end
        end
    end
    
    return false, lastError
end

-- Execute function with timeout
function withTimeout(func, timeoutSeconds)
    local co = coroutine.create(func)
    local timeout = os.time() + timeoutSeconds
    
    while coroutine.status(co) ~= "dead" do
        local ok, result = coroutine.resume(co)
        if not ok then
            return false, result
        end
        
        if os.time() >= timeout then
            return false, "Timeout exceeded"
        end
        
        event.pull(0.1)
    end
    
    return true
end

-- Validate Lua code syntax
function validateLuaCode(code)
    local func, err = load(code)
    if not func then
        return false, "Invalid Lua syntax: " .. err
    end
    return true
end

-- Validate checksum
function validateChecksum(code, expectedChecksum)
    local actualChecksum = computeChecksum(code)
    return actualChecksum == expectedChecksum, actualChecksum
end

-- Compute simple checksum
function computeChecksum(str)
    local hash = 5381
    for i = 1, #str do
        hash = ((hash << 5) + hash) + string.byte(str, i)
    end
    return tostring(hash)
end

return {
    init = initErrorHandling,
    withRetry = withRetry,
    withTimeout = withTimeout,
    validateLuaCode = validateLuaCode,
    validateChecksum = validateChecksum,
    computeChecksum = computeChecksum
}
