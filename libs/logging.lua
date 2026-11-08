--[[ Logging Library ]]--

-- Logging levels
local LOG_LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

-- Current log level
local currentLogLevel = LOG_LEVELS.INFO

-- Log file handle
local logFile = nil

-- Initialize logging
function initLogging(logFilePath, level)
    currentLogLevel = level or LOG_LEVELS.INFO
    
    if logFilePath then
        logFile = fs.open(logFilePath, "a")
        if not logFile then
            computer.log(LOG_LEVELS.ERROR, "Failed to open log file: " .. logFilePath)
        end
    end
end

-- Close log file
function closeLogging()
    if logFile then
        logFile:close()
        logFile = nil
    end
end

-- Format log message
local function formatLog(level, message, ...)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local levelName = "INFO"
    
    for name, val in pairs(LOG_LEVELS) do
        if val == level then
            levelName = name
            break
        end
    end
    
    local formatted = string.format("[%s] [%s] %s", timestamp, levelName, message)
    if ... then
        formatted = formatted .. " " .. string.format(...)
    end
    
    return formatted .. "\n"
end

-- Log message
function log(level, message, ...)
    if level >= currentLogLevel then
        local formatted = formatLog(level, message, ...)
        
        -- Console output
        print(formatted)
        
        -- File output
        if logFile then
            logFile:write(formatted)
            logFile:flush()
        end
        
        -- System log
        computer.log(level, message)
    end
end

-- Convenience functions
function debug(message, ...)
    log(LOG_LEVELS.DEBUG, message, ...)
end

function info(message, ...)
    log(LOG_LEVELS.INFO, message, ...)
end

function warn(message, ...)
    log(LOG_LEVELS.WARN, message, ...)
end

function error(message, ...)
    log(LOG_LEVELS.ERROR, message, ...)
end

-- Set log level
function setLogLevel(level)
    currentLogLevel = level
end

return {
    LOG_LEVELS = LOG_LEVELS,
    init = initLogging,
    close = closeLogging,
    log = log,
    debug = debug,
    info = info,
    warn = warn,
    error = error,
    setLevel = setLogLevel
}
