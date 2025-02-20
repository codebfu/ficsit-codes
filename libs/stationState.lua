
function getRequesterState()
    return { unknown = "?", full = "*", inNeed = "!", filling = "+"}
end

function setState(station, state)
    local name = station.name:sub(2)
    station.name = getRequesterState()[state] .. name
end

function getState(station)
    local state = station.name:sub(1,1)
    for s, v in pairs(getRequesterState()) do
        if state == v then
            return s
        end
    end
    station.name = getRequesterState()["unknown"] .. station.name
    return "unknown"
end
