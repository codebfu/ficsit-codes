--[[ Net-Boot Client ]]--

-- Configuration
debug = false
local netBootProgramName = "remote-test"
local netBootPort = 1

-- Setup Network
local net = computer.getPCIDevices(classes.NetworkCard)[1]
if not net then
    error("Net-Boot: Failed to Start: No Network Card available!")
end
net:open(netBootPort)
event.listen(net)

-- Wrap event.pull() and filter Net-Boot messages
local og_event_pull = event.pull
function event.pull(timeout)
    local args = {og_event_pull(timeout)}
    local e, _, s, p, cmd, programName = table.unpack(args)
    if e == "NetworkMessage" and p == netBootPort then
        if cmd == "reset" and programName == netBootProgramName then
            computer.log(2, "Net-Boot: Received reset command from Server \"" .. s .. "\"")
            if netBootReset then
                pcall(netBootReset)
            end
            computer.reset()
        end
        if cmd == "ping" then
            computer.log(2, "Net-Boot: Received ping Server \"" .. s .. "\"")
            net:send(s, netBootPort, "pong", computer.getInstance().id, computer.getInstance().nick)
        end
    end
    return table.unpack(args)
end

-- Request Library from Net-Boot Server
function getLibrary(name)
	local library = nil
	while library == nil do
    	print("Net-Boot: Request Net-Boot-Library \"" .. name .. "\" from Port " .. netBootPort)
    	net:broadcast(netBootPort, "getLibrary", name)
    	while library == nil do
        	local e, _, s, p, cmd, libraryName, code = event.pull(30)
        	if e == "NetworkMessage" and p == netBootPort and cmd == "setLibrary" and libraryName == name then
            	print("Net-Boot: Got Code for Library \"" .. name .. "\" from Server \"" .. s .. "\"")
            	library = load(code)
        	elseif e == nil then
            	computer.log(3, "Net-Boot: Request Timeout reached! Retry...")
            	break
        	end
    	end
	end
    local success, error = pcall(library)
end

-- Request Code from Net-Boot Server
local program = nil
while program == nil do
    print("Net-Boot: Request Net-Boot-Program \"" .. netBootProgramName .. "\" from Port " .. netBootPort)
    net:broadcast(netBootPort, "getEEPROM", netBootProgramName)
    while program == nil do
        local e, _, s, p, cmd, programName, code = event.pull(30)
        if e == "NetworkMessage" and p == netBootPort and cmd == "setEEPROM" and programName == netBootProgramName then
            print("Net-Boot: Got Code for Program \"" .. netBootProgramName .. "\" from Server \"" .. s .. "\"")
            program = load(code)
        elseif e == nil then
            computer.log(3, "Net-Boot: Request Timeout reached! Retry...")
            break
        end
    end
end

-- Execute Code got from Net-Boot Server
print("Now starting program: " .. netBootProgramName)
netBootReset = nil
local success, error = pcall(program)
if not success then
    computer.log(4, error)
    
    computer.reset()
end