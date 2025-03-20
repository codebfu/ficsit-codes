getLibrary("debug-print")
getLibrary("deepcopy")
getLibrary("tablelength")
getLibrary("getPercentage")
getLibrary("stationState")

function netBootReset()
    print("Net-Boot Restart Cleanup!")
end

local components = component.findComponent("")

itemTable = { encased_beam = "Industrial Encased Beam"}

resetState = false

function updateItem(station, stype, item)
    local sitem = "not found"
    if stype == "provider" then
        sitem = station.name:sub(1,station.name:find("_")-1)
    elseif stype == "requester" then
        sitem = station.name:sub(2,station.name:find("_")-1)
    else
        return
    end

    station.name = station.name:gsub(sitem, item)
end

function fixItem(station, stype, item)
    if itemTable[item] ~= nil then
        updateItem(station, stype, itemTable[item])
    end
end

trains = {}
stations = {}
stationDetails = {}

print("Scanning network")
for _,v in ipairs(components) do
	object = component.proxy(v)
	if(object.isNetworkComponent) then
	
				
		if object.internalName:find("Station") then

			local trackGraph = object:getTrackGraph()
						
			stations = trackGraph:getStations()
			trains = trackGraph:getTrains()

			break			
		end

	end
	
end

print("Sorting stations")
idx = 1 -- pairs counts from 1 ...
for _,station in ipairs(stations) do
	local count = 0
	local max = 0
    local stype = "none"
	local item = ""
    local sload = true
	if station.name:find("_L_") then
		-- This station has stuff, maybe
		stype = "provider"
		item = station.name:sub(1,station.name:find("_")-1)
        sload = true
	end
	if station.name:find("_U_") then
		-- This station needs stuff, maybe
		stype = "requester"
        local state = getState(station)
		item = station.name:sub(2,station.name:find("_")-1)
        sload = false
        if resetState == true then
            setState(station, "unknown")
        end
	end
	if station.name:find(":") then
		-- This station needs stuff, maybe
		stype = "depot"
		item = station.name:sub(1,station.name:find(":")-2)
        sload = false
	end
	if station.name:find("Garage_") then
		stype = "garage"
	end
	if station.name:find("Parking_") then
		stype = "parking"
	end
	if station.name:find("Trash Disposal") then
		stype = "trash"
        sload = false
	end

    local slots = 0
 	local platforms = station:getAllConnectedPlatforms()
 	for _, platform in ipairs(platforms) do
 		if platform.internalName:find("TrainDockingStation") then
 			platform.isInLoadMode = sload
 			local inventories = platform:getInventories()
 			for _, inventory in ipairs(inventories) do
 				inventory:sort()
 				for i=0,inventory.size-1 do
                    slots = slots + 1
 					local stack = inventory:getStack(i)
 					if stack.count > 0 then
						count = count + stack.count
						max = stack.item.type.max
                        item = stack.item.type.name
 					end
 				end 
 			end
 		end
 	end
    max = max * slots

    updateItem(station, stype, item)
    fixItem(station, stype, item)

    stationDetails[idx] = {}
    stationDetails[idx].object = station
    stationDetails[idx].item = item
    stationDetails[idx].type = stype
    stationDetails[idx].max = max
    stationDetails[idx].count = count

	print(station.name .. " (" .. stype .. ")" .. " -> " .. item .. " " .. count .. "/" .. max)

    idx = idx + 1
end

for _,train in ipairs(trains) do
    local tt = train:getTimeTable()
    local ttstop = tt:getStop(0)
    local ruleset = ttstop:getRuleSet()
    ruleset.duration = 5
end

while true do
	print("Waiting 3s before next loop")
	event.pull(3)

    print("Processing docked trains")
    resourceProviders = {}
    transportProviders = {}
    for _,station in ipairs(stationDetails) do
        if station.type == "provider" then
            local docked = station.object:getDockedLocomotive()
            if docked ~= nil then
                local train = docked:getTrain()
                train:setName("P: " .. station.object.name)
                local count = 0
                local max = 0
                local slots = 0
                for _, wagon in ipairs(train:getVehicles()) do
                    if wagon.internalName:find("FreightWagon") then
                        local inventories = wagon:getInventories()
                        for _, inventory in ipairs(inventories) do
                            inventory:sort()
                            for i=0,inventory.size-1 do
                                slots = slots + 1
                                local stack = inventory:getStack(i)
                                if stack.count > 0 then
                                count = count + stack.count
                                max = stack.item.type.max
                                end
                            end 
                        end
                    end
                end
                max = max * slots
                local filled = getPercentage(count, max)
                local tt = train:getTimeTable()
                local ttstop = tt:getStop(0)
                local ruleset = ttstop:getRuleSet()
                ruleset.duration = 5
                ttstop:setRuleSet(ruelset)
                if filled >= 98 and tt.numStops == 1 then
                    if resourceProviders[station.item] == nil then
                        resourceProviders[station.item] = {}
                    end
                    local idx = tablelength(resourceProviders[station.item]) + 1
                    resourceProviders[station.item][idx] = {}
                    resourceProviders[station.item][idx].train = train
                    resourceProviders[station.item][idx].reserved = false
                    print("Adding " .. train:getName() .. " (" .. station.item .. ") to the provider list")
                end
            end
        end
        if station.type == "garage" then
            local docked = station.object:getDockedLocomotive()
            if docked ~= nil then
                local train = docked:getTrain()
                train:setName("T: " .. station.object.name)
                local tt = train:getTimeTable()
                local idx = tablelength(transportProviders) + 1
                local ttstop = tt:getStop(0)
                local ruleset = ttstop:getRuleSet()
                ruleset.duration = 5
                ttstop:setRuleSet(ruelset)
                if tt.numStops == 1 then
                    transportProviders[idx] = {}
                    transportProviders[idx].train = train
                    transportProviders[idx].reserved = false
                    print("Adding " .. train:getName() .. " (" .. station.item .. ") to the transport list")
                end
            end
        end
    end

    print("Identify busy delivery trains")
    allocatedResourceProviders = {}
    for _,train in ipairs(trains) do
        if train:getName():sub(1,3) == "P: " then
            local tt = train:getTimeTable()
            if tt.numStops > 1 then
                local ttstop = tt:getStop(1)
                print(train:getName() .. " is refilling " .. ttstop.station.name)
                allocatedResourceProviders[ttstop.station.name] = train:getName()
            end
        end
    end


    print("Update requester status")
    resourceRequesters = {}
    for _,station in ipairs(stationDetails) do
        if station.type == "requester" then
            if getState(station.object) == "filling" and allocatedResourceProviders[station.object.name] == nil then
                print(station.object.name .. " is in filling state with no train on route, resetting state")
                setState(station.object, "unknown")
            end
            local count = 0
            local max = 0
            local slots = 0
            local platforms = station.object:getAllConnectedPlatforms()
            for _, platform in ipairs(platforms) do
                if platform.internalName:find("TrainDockingStation") then
                    local inventories = platform:getInventories()
                    for _, inventory in ipairs(inventories) do
                        inventory:sort()
                        for i=0,inventory.size-1 do
                            slots = slots + 1
                            local stack = inventory:getStack(i)
                            if stack.count > 0 then
                            count = count + stack.count
                            max = stack.item.type.max
                            end
                        end 
                    end
                end
            end
            max = max * slots
            local filled = getPercentage(count, max)
            if filled < 50 or max == 0 then
                if getState(station.object) ~= "filling" then
                    setState(station.object, "inNeed")
                end
            else
                setState(station.object, "full")
            end
        end
    end

    print("Fulfilling new requests")
    resourceRequesters = {}
    for _,station in ipairs(stationDetails) do
        if station.type == "requester" and getState(station.object) == "inNeed" then
            if resourceProviders[station.item] ~= nil then
                for _, provider in ipairs(resourceProviders[station.item]) do
                    if provider.reserved == false then
                        provider.reserved = true
                        setState(station.object, "filling")
                        local tt = provider.train:getTimeTable()
                        local newRuleSet = {}
                        newRuleSet.definition = 0
                        newRuleSet.duration = 10.0
                        newRuleSet.isDurationAndRule = true
                        tt:addStop(tt.numStops, station.object, newRuleSet)
                        print("Assigned " .. provider.train:getName() .. " to station " .. station.object.name)
                        break
                    end
                end
            end
        end
    end

    print("Clean off-duty train time tables")
    for _,train in ipairs(trains) do
        if train:getName():sub(1,3) == "P: " then
            local tt = train:getTimeTable()
            if tt.numStops > 1 and train.isDocked == false then
                if tt:getCurrentStop() == 0 then
                    local ttstop = tt:getStop(1)
                    print(ttstop.station.name .. " refilled, reseting state")
                    setState(ttstop.station, "unknown")
                    print(train:getName() .. " returning to base")
                    tt:removeStop(1)
                else
                    print(train:GetName() .. " is still on duty")    
                end
            end
        end
    end

    print("done")

end