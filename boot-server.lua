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

if fs.initFileSystem("/dev") == false then
    computer.panic("Cannot initialize /dev")
end

-- Mounting OS
print("Mounting OS")
fs.mount("/dev" .. OS, "/")
fs.createDir("/type")
local file = fs.open("/type/os", "w")
file:write("boot-server")
file:close()

fs.createDir("/nas")
fs.createDir("/code")
fs.createDir("/libs")
fs.createDir("/mnt")

-- Mounting HDDs
for _, drive in ipairs(fs.children("/dev")) do
    print("Mounting drive : " .. drive)
    fs.createDir("/mnt/" .. drive)
	fs.mount("/dev/" .. drive, "/mnt/" .. drive)
end

for _, drive in ipairs(fs.children("/dev")) do
    if fs.exists("/mnt/" .. drive .. "/type") == true then
        if fs.exists("/mnt/" .. drive .. "/type/nas") then
            if hasNas then
                error("Cannot have 2 NAS drives")
            else
                print("Mounting NAS HDD : " .. drive)
                fs.mount("/mnt/" .. drive .. "/data", "/nas")
                hasNas = true
            end
        end

        if filesystem.exists("/mnt/" .. drive .. "/type/code") then
            if hasCode then
                error("Cannot have 2 Code drives")
            else
                print("Mounting Code HDD : " .. drive)
                fs.mount("/mnt/" .. drive .. "/data", "/code")
                hasCode = true
            end
        end
    end
end

for _, drive in ipairs(fs.children("/dev")) do
    if fs.exists("/mnt/" .. drive .. "/type") == false then
        if hasNas == false then
            print("Formating and mounting " .. drive .. " as NAS")
            fs.createDir("/mnt/" .. drive .. "/type")
            fs.createDir("/mnt/" .. drive .. "/data")
            local file = fs.open("/mnt/" .. drive .. "/type/nas", "w")
            file:write("tartiflette")
            file:close()
            fs.mount("/mnt/" .. drive .. "/data", "/nas")
            hasNas = true
            break
        end
    end
end

for _, drive in ipairs(fs.children("/dev")) do
    if fs.exists("/mnt/" .. drive .. "/type") == false then
        if hasCode == false then
            print("Formating and mounting " .. drive .. " as Code")
            fs.createDir("/mnt/" .. drive .. "/type")
            fs.createDir("/mnt/" .. drive .. "/data")
            local file = fs.open("/mnt/" .. drive .. "/type/code", "w")
            file:write("tartiflette")
            file:close()
            fs.mount("/mnt/" .. drive .. "/data", "/code")
            hasCode = true
            break
        end
    end
end

if hasNas == false or hasCode == false then
	error("Missing proper HDDs")
end

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
        local file = fs.open("/code/" .. codename, "w")
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
            	local file = fs.open("/code/" .. arg1, "r") 
            	code = file:read(65535)
            	file:close()
            end
            net:send(s, netBootPort, "setEEPROM", arg1, code)
        end
        if cmd == "getLibrary" then
            print("Program Request for \"" .. arg1 .. "\" from \"" .. s .. "\"")
            local code = netLibPrograms[arg1]
            if code == "remote" then
            	print("This is remote library")
            	local file = fs.open("/libs/" .. arg1, "r") 
            	code = file:read(65535)
            	file:close()
            end
            net:send(s, netBootPort, "setLibrary", arg1, code)
        end
    end
end
