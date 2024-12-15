-- Configuration
local realProgramName = "boot-client"
local netBootPort = 1

-- Setup Network
local net = computer.getPCIDevices(classes.NetworkCard)[1]
if not net then
    error("Net-Boot: Failed to Start: No Network Card available!")
end
net:open(netBootPort)
event.listen(net)

local realProgram = nil
while realProgram == nil do
    print("Net-Boot: Request Net-Boot-Program \"" .. realProgramName .. "\" from Port " .. netBootPort)
    net:broadcast(netBootPort, "getEEPROM", realProgramName)
    while realProgram == nil do
        local e, _, s, p, cmd, programName, code = event.pull(30)
        if e == "NetworkMessage" and p == netBootPort and cmd == "setEEPROM" and programName == realProgramName then
            print("Net-Boot: Got Code for Program \"" .. realProgramName .. "\" from Server \"" .. s .. "\"")
            realProgram = load(code)
        elseif e == nil then
            computer.log(3, "Net-Boot: Request Timeout reached! Retry...")
            break
        end
    end
end
computer.setEEPROM(realProgram)
print("Update netBootProgramName and restart computer")
