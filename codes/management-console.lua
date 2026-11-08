--[[ Management Console - Centralized Management Program ]]--

-- Configuration
local MANAGEMENT_PORT = 4200
local NET_BOOT_PORT = 1

-- Setup Network
local net = computer.getPCIDevices(classes.NetworkCard)[1]
if not net then
    error("Management Console: Failed to Start: No Network Card available!")
end

net:open(MANAGEMENT_PORT)
event.listen(net)

-- Load required libraries
local logging = getLibrary("logging")
local errorHandling = getLibrary("error-handling")
local dependencyMgmt = getLibrary("dependency-mgmt")
local updateMgmt = getLibrary("update-mgmt")

-- Initialize logging
logging.init("/logs/management-console.log", logging.LOG_LEVELS.INFO)
logging.info("Management Console started on port %d", MANAGEMENT_PORT)

-- Known net-boot servers
local netBootServers = {}

-- Register a net-boot server
function registerNetBootServer(address, port)
    netBootServers[address] = port or NET_BOOT_PORT
    logging.info("Registered net-boot server at %s:%d", address, port or NET_BOOT_PORT)
end

-- Send command to net-boot server
function sendToNetBootServer(serverAddress, command, ...)
    local port = netBootServers[serverAddress] or NET_BOOT_PORT
    
    local success, err = errorHandling.withRetry(
        function()
            net:send(serverAddress, port, command, ...)
            return true
        end,
        nil,
        function(err, attempt, maxAttempts)
            logging.warn("Failed to send command to %s (attempt %d/%d): %s", 
                serverAddress, attempt, maxAttempts, err)
        end
    )
    
    return success
end

-- Get program list from net-boot server
function getProgramList(serverAddress)
    local success, result = errorHandling.withRetry(
        function()
            sendToNetBootServer(serverAddress, "getProgramList")
            -- In a real implementation, we would wait for response
            return {"init", "boot-client", "remote-test", "dban", "depot-mgmt", "train-mgmt"}
        end
    )
    
    return success and result or {}
end

-- Get library list from net-boot server
function getLibraryList(serverAddress)
    local success, result = errorHandling.withRetry(
        function()
            sendToNetBootServer(serverAddress, "getLibraryList")
            -- In a real implementation, we would wait for response
            return {"debug-print", "mountLib", "deepcopy", "tablelength", "getPercentage", "stationState", "logging", "error-handling", "dependency-mgmt", "cache", "update-mgmt"}
        end
    )
    
    return success and result or {}
end

-- Check for updates on a server
function checkServerUpdates(serverAddress)
    local success, result = errorHandling.withRetry(
        function()
            sendToNetBootServer(serverAddress, "checkUpdates")
            -- In a real implementation, we would wait for response
            return { programs = {}, libraries = {} }
        end
    )
    
    return success and result or { programs = {}, libraries = {} }
end

-- Apply updates on a server
function applyServerUpdates(serverAddress, updates)
    local success = errorHandling.withRetry(
        function()
            sendToNetBootServer(serverAddress, "applyUpdates", updates)
            return true
        end
    )
    
    return success
end

-- Get client list from net-boot server
function getClientList(serverAddress)
    local success, result = errorHandling.withRetry(
        function()
            sendToNetBootServer(serverAddress, "getClientList")
            -- In a real implementation, we would wait for response
            return {
                {
                    address = "192.168.1.10",
                    programs = {"init", "boot-client", "remote-test"},
                    status = "running"
                },
                {
                    address = "192.168.1.11",
                    programs = {"init", "boot-client", "dban"},
                    status = "running"
                }
            }
        end
    )
    
    return success and result or {}
end

-- Reboot a client
function rebootClient(serverAddress, clientAddress)
    local success = errorHandling.withRetry(
        function()
            sendToNetBootServer(serverAddress, "rebootClient", clientAddress)
            return true
        end
    )
    
    return success
end

-- Update client configuration
function updateClientConfig(serverAddress, clientAddress, config)
    local success = errorHandling.withRetry(
        function()
            sendToNetBootServer(serverAddress, "updateConfig", clientAddress, config)
            return true
        end
    )
    
    return success
end

-- Main loop
while true do
    local e, _, sender, port, command, arg1, arg2 = event.pull()
    
    if e == "NetworkMessage" and port == MANAGEMENT_PORT then
        logging.debug("Received command '%s' from %s", command, sender)
        
        if command == "register" then
            -- Register a net-boot server
            registerNetBootServer(sender, arg1)
            net:send(sender, MANAGEMENT_PORT, "ack", "registered")
            
        elseif command == "getProgramList" then
            -- Get program list
            local programs = getProgramList(arg1 or sender)
            net:send(sender, MANAGEMENT_PORT, "programList", programs)
            
        elseif command == "getLibraryList" then
            -- Get library list
            local libraries = getLibraryList(arg1 or sender)
            net:send(sender, MANAGEMENT_PORT, "libraryList", libraries)
            
        elseif command == "checkUpdates" then
            -- Check for updates
            local updates = checkServerUpdates(arg1 or sender)
            net:send(sender, MANAGEMENT_PORT, "updates", updates)
            
        elseif command == "applyUpdates" then
            -- Apply updates
            local success = applyServerUpdates(arg1 or sender, arg2)
            net:send(sender, MANAGEMENT_PORT, "updateResult", success)
            
        elseif command == "getClientList" then
            -- Get client list
            local clients = getClientList(arg1 or sender)
            net:send(sender, MANAGEMENT_PORT, "clientList", clients)
            
        elseif command == "rebootClient" then
            -- Reboot a client
            local success = rebootClient(arg1 or sender, arg2)
            net:send(sender, MANAGEMENT_PORT, "rebootResult", success)
            
        elseif command == "updateConfig" then
            -- Update client configuration
            local success = updateClientConfig(arg1 or sender, arg2, arg3)
            net:send(sender, MANAGEMENT_PORT, "configResult", success)
            
        elseif command == "ping" then
            -- Respond to ping
            net:send(sender, MANAGEMENT_PORT, "pong", computer.getInstance().id, computer.getInstance().nick)
        end
    end
end

logging.info("Management Console shutting down")
logging.close()
