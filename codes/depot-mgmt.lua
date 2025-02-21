getLibrary("debug-print")
getLibrary("getPercentage")
getLibrary("stationState")

function netBootReset()
    print("Net-Boot Restart Cleanup!")
end

while true do
	print("Waiting 10s before next loop")
	event.pull(10)
	local stations = component.proxy(component.findComponent(""))
	for _, station in ipairs(stations) do
		if station.internalName:find("TrainStation") then
			local state = getState(station)
 			dprint("Processing : " .. station.name .. " (" .. station.id .. ") state: " .. state)
			local count = 0
			local max = 0
			local slots = 0
			local item = ""
 			local assigned = false
 			if station.name:find(":") then
 				assigned = true
 				item = station.name:sub(2,station.name:find(":")-2)
 				dprint("--- This depot is assigned to : " .. item)
 			else
 				dprint("--- This depot was previously unassigned")
 			end
 			local platforms = station:getAllConnectedPlatforms()
 			for _, platform in ipairs(platforms) do
 				if platform.internalName:find("TrainDockingStation") then
 					platform.isInLoadMode = false
 					local inventories = platform:getInventories()
 					for _, inventory in ipairs(inventories) do
 						inventory:sort()
 						for i=0,inventory.size-1 do
 							local stack = inventory:getStack(i)
 							if stack.count > 0 then
		 						count = count + stack.count
		 						item = stack.item.type.name
								max = stack.item.type.max
 							end
 						end 
 					end
 				end
 			end
			max = max * slots
			local filled = getPercentage(count, max)
			if filled < 80 then
				if state ~= "filling" then
					dprint("--- This depot is in need")
					setState(station, "inNeed")
				end
			else
				dprint("--- This depot is full")
				setState(station, "full")
			end
 			if count == 0 and assigned == false then
				dprint("--- This depot is still unassigned")
				station.name = "Unassigned Depot"
			else
				dprint("--- This depot is assigned to " .. item .. " (" .. count .. ")")
				station.name = item .. " : " .. count
			end 			
		end
	end
	if debug then
		print("debug is true, not looping")
		break
	end
end
print("done")