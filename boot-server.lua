--[[ Net-Boot Server ]]--

-- Configuration
local OS = "AC5D93D559A44DFD9A4414809FFF4085"
local netBootPort = 1
local netBootPrograms = {}
local netLibPrograms = {}
local hasNas = false
local hasCode = false

netBootPrograms["local-test"] = [[
    function netBootReset()
        print("Net-Boot Restart Cleanup!")
    end
    
    local counter = 0
    while true do
        event.pull(1)
        counter = counter + 1
        print("Counter:", counter)
        if counter > 10 then
            error("meep")
        end
    end
]]

local netBootFallbackProgram = [[
    print("Invalid Net-Boot-Program: Program not found!")
    event.pull(5)
    computer.reset()
]]

--[[
--]]

-- Mount filesystem
fs = filesystem

function mountOS(uuid, label)
	local fs = filesystem

	if fs.initFileSystem("/dev") == false then
    	computer.panic("Cannot initialize /dev")
	end

	print("Mounting OS")
	if fs.mount("/dev" .. uuid, "/") == false then
		error("Couldn't mount root fs")
	end
	local file = fs.open("/_type_", "w")
	file:write("OS")
	file:close()
	local file = fs.open("/_label_", "w")
	file:write(label)
	file:close()

	fs.createDir("/mnt")
end

function formatAndMount(type, label, mountpoint)
	local fs = filesystem
	local identified = ""
	local duplicate = false
	print("Searching for drive '" .. type .. " : " .. label .. "'")
	for _, drive in ipairs(fs.children("/dev")) do
    	print("--- Checking drive : " .. drive)
   		local dtype = ""
   		local dlabel = ""
   		fs.createDir("/mnt/" .. drive)
		fs.mount("/dev/" .. drive, "/mnt/" .. drive)
		if fs.isFile("/mnt/" .. drive .. "/_type_") then
			local file = fs.open("/mnt/" .. drive .. "/_type_", "r")
			dtype = file:read(65535)
			file:close()
		end
		if fs.isFile("/mnt/" .. drive .. "/_label_") then
			local file = fs.open("/mnt/" .. drive .. "/_label_", "r")
			dlabel = file:read(65535)
			file:close()
		end
		fs.unmount("/mnt/" .. drive)
		fs.remove("/mnt/" .. drive)
		if dtype == type and dlabel == label then
			if identified == "" then
				identified = drive
			else
				print("Error: Too many drives of type '" .. type .. "' and label '" .. label .. "' found")
				duplicate = true
			end
		end
	end
	if duplicate then
		error("See error(s) above")
	end
	if identified == "" then
		print("Drive not found, searching for spare")
		for _, drive in ipairs(fs.children("/dev")) do
   			print("--- Checking drive : " .. drive)
   			fs.createDir("/mnt/" .. drive)
			fs.mount("/dev/" .. drive, "/mnt/" .. drive)
			if fs.isFile("/mnt/" .. drive .. "/_type_") == false and fs.isFile("/mnt/" .. drive .. "/_label_") == false then
				identified = drive
			end
			fs.unmount("/mnt/" .. drive)
			fs.remove("/mnt/" .. drive)
			if identified ~= "" then
				break
			end
		end
	end
	if identified == "" then
		error("Failed to identify a suitable drive")
	else
		print("Compatible drive identified: " .. identified)
	end
	fs.createDir(mountpoint, true)
	if fs.mount("/dev/" .. identified, mountpoint) == false then
		error("Couldn't mount drive")
	end
	local file = fs.open(mountpoint .. "/_type_", "w")
	file:write(type)
	file:close()
	local file = fs.open(mountpoint .. "/_label_", "w")
	file:write(label)
	file:close()
end

mountOS(OS, "net-boot OS")
formatAndMount("codes", "net-boot codes", "/codes")
formatAndMount("libs", "net-boot libs", "/libs")

-- Retrieve Remote Code
local internet = computer.getPCIDevices(classes.FINInternetCard)[1]
if not internet then
    error("Failed to start Net-Boot-Server: No internet card found!")
end

local req = internet:request("https://raw.githubusercontent.com/codebfu/ficsit-codes/master/code.lst", "GET", "")
local _, codelist = req:await()

for codename in codelist:gmatch("[^\n]+") do
	if codename ~= "" then
        print("Retrieving program : " .. codename)
        local req = internet:request("https://raw.githubusercontent.com/codebfu/ficsit-codes/master/codes/" .. codename .. ".lua", "GET", "")
        local _, code = req:await()
        local file = fs.open("/codes/" .. codename, "w")
        file:write(code)
        file:close()
        netBootPrograms[codename] = "remote"
    end
end

local req = internet:request("https://raw.githubusercontent.com/codebfu/ficsit-codes/master/lib.lst", "GET", "")
local _, codelist = req:await()

for codename in codelist:gmatch("[^\n]+") do
	if codename ~= "" then
        print("Retrieving library : " .. codename)
        local req = internet:request("https://raw.githubusercontent.com/codebfu/ficsit-codes/master/libs/" .. codename .. ".lua", "GET", "")
        local _, code = req:await()
        local file = fs.open("/libs/" .. codename, "w")
        file:write(code)
        file:close()
        netLibPrograms[codename] = "remote"
    end
end

-- Setup Network
local net = computer.getPCIDevices(classes.NetworkCard)[1]
if not net then
    error("Failed to start Net-Boot-Server: No network card found!")
end
net:open(netBootPort)
event.listen(net)

-- Reset all related Programs
for programName in pairs(netBootPrograms) do
    net:broadcast(netBootPort, "reset", programName)
    print("Broadcasted reset for Program \"" .. programName .. "\"")
end

-- Serve Net-Boot
while true do
    local e, _, s, p, cmd, arg1 = event.pull()
    if e == "NetworkMessage" and p == netBootPort then
        if cmd == "getEEPROM" then
            print("Program Request for \"" .. arg1 .. "\" from \"" .. s .. "\"")
            local code = netBootPrograms[arg1] or netBootFallbackProgram
            if code == "remote" then
            	print("This is remote code")
            	local file = fs.open("/codes/" .. arg1, "r") 
            	code = file:read(65535)
            	file:close()
            end
            net:send(s, netBootPort, "setEEPROM", arg1, code)
        end
        if cmd == "getLibrary" then
            print("Library Request for \"" .. arg1 .. "\" from \"" .. s .. "\"")
            local code = netLibPrograms[arg1]
            if code == "remote" then
            	print("This is remote library")
            	local file = fs.open("/libs/" .. arg1, "r") 
            	code = file:read(65535)
            	file:close()
            end
            net:send(s, netBootPort, "setLibrary", arg1, code)
        end
        if cmd == "ping" then
            computer.log(2, "Net-Boot: Received ping Server \"" .. s .. "\"")
            net:send(s, netBootPort, "pong", computer.getInstance().id, computer.getInstance().nick)
        end
    end
end
