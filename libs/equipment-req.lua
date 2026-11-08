--[[ Equipment Requirements Library ]]--

-- Equipment types and specifications
local EQUIPMENT_TYPES = {
    CPU = {
        T1 = { power = 1, performance = 1 },
        T2 = { power = 2, performance = 2 },
        T3 = { power = 4, performance = 4 }
    },
    RAM = {
        T1 = { size = 1, speed = 1 },
        T2 = { size = 2, speed = 2 },
        T3 = { size = 4, speed = 4 }
    },
    HDD = {
        T1 = { size = 10, speed = 1 },
        T2 = { size = 50, speed = 2 },
        T3 = { size = 200, speed = 4 }
    },
    GPU = {
        T1 = { power = 1, vram = 1 },
        T2 = { power = 2, vram = 2 },
        T3 = { power = 4, vram = 4 }
    },
    NETWORK_CARD = {
        T1 = { speed = 10, ports = 1 },
        T2 = { speed = 100, ports = 2 },
        T3 = { speed = 1000, ports = 4 }
    },
    INTERNET_CARD = {
        T1 = { speed = 1, bandwidth = 1 },
        T2 = { speed = 10, bandwidth = 10 },
        T3 = { speed = 100, bandwidth = 100 }
    },
    SCREEN = {
        T1 = { resolution = "720p", size = 1 },
        T2 = { resolution = "1080p", size = 2 },
        T3 = { resolution = "4K", size = 3 }
    }
}

-- Program requirements registry
local programRequirements = {}

-- Register program requirements
function registerProgramRequirements(programName, requirements)
    programRequirements[programName] = requirements or {}
end

-- Get requirements for a program
function getProgramRequirements(programName)
    return programRequirements[programName] or {}
end

-- Check if current equipment meets requirements
function checkEquipmentRequirements(requirements)
    local missing = {}
    local insufficient = {}
    
    -- Check CPU
    if requirements.cpu then
        local requiredType = requirements.cpu.type
        local requiredSpec = requirements.cpu.spec or "T1"
        
        local availableCPU = computer.getPCIDevices(classes.CPU)[1]
        if not availableCPU then
            table.insert(missing, "CPU")
        else
            -- In a real implementation, we would check the actual CPU type
            -- For now, we'll assume it meets requirements
            local cpuSpec = availableCPU.spec or "T1"
            if cpuSpec < requiredSpec then
                table.insert(insufficient, "CPU (" .. cpuSpec .. " < " .. requiredSpec .. ")")
            end
        end
    end
    
    -- Check RAM
    if requirements.ram then
        local requiredType = requirements.ram.type
        local requiredSpec = requirements.ram.spec or "T1"
        
        local availableRAM = computer.getPCIDevices(classes.RAM)[1]
        if not availableRAM then
            table.insert(missing, "RAM")
        else
            -- In a real implementation, we would check the actual RAM type
            -- For now, we'll assume it meets requirements
            local ramSpec = availableRAM.spec or "T1"
            if ramSpec < requiredSpec then
                table.insert(insufficient, "RAM (" .. ramSpec .. " < " .. requiredSpec .. ")")
            end
        end
    end
    
    -- Check HDD
    if requirements.hdd then
        local requiredType = requirements.hdd.type
        local requiredSpec = requirements.hdd.spec or "T1"
        
        local availableHDD = computer.getPCIDevices(classes.HDD)[1]
        if not availableHDD then
            table.insert(missing, "HDD")
        else
            -- In a real implementation, we would check the actual HDD type
            -- For now, we'll assume it meets requirements
            local hddSpec = availableHDD.spec or "T1"
            if hddSpec < requiredSpec then
                table.insert(insufficient, "HDD (" .. hddSpec .. " < " .. requiredSpec .. ")")
            end
        end
    end
    
    -- Check GPU
    if requirements.gpu then
        local requiredType = requirements.gpu.type
        local requiredSpec = requirements.gpu.spec or "T1"
        
        local availableGPU = computer.getPCIDevices(classes.GPU)[1]
        if not availableGPU then
            table.insert(missing, "GPU")
        else
            -- In a real implementation, we would check the actual GPU type
            -- For now, we'll assume it meets requirements
            local gpuSpec = availableGPU.spec or "T1"
            if gpuSpec < requiredSpec then
                table.insert(insufficient, "GPU (" .. gpuSpec .. " < " .. requiredSpec .. ")")
            end
        end
    end
    
    -- Check Network Card
    if requirements.networkCard then
        local requiredType = requirements.networkCard.type
        local requiredSpec = requirements.networkCard.spec or "T1"
        
        local availableNetCard = computer.getPCIDevices(classes.NetworkCard)[1]
        if not availableNetCard then
            table.insert(missing, "Network Card")
        else
            -- In a real implementation, we would check the actual network card type
            -- For now, we'll assume it meets requirements
            local netSpec = availableNetCard.spec or "T1"
            if netSpec < requiredSpec then
                table.insert(insufficient, "Network Card (" .. netSpec .. " < " .. requiredSpec .. ")")
            end
        end
    end
    
    -- Check Internet Card
    if requirements.internetCard then
        local requiredType = requirements.internetCard.type
        local requiredSpec = requirements.internetCard.spec or "T1"
        
        local availableInternetCard = computer.getPCIDevices(classes.FINInternetCard)[1]
        if not availableInternetCard then
            table.insert(missing, "Internet Card")
        else
            -- In a real implementation, we would check the actual internet card type
            -- For now, we'll assume it meets requirements
            local internetSpec = availableInternetCard.spec or "T1"
            if internetSpec < requiredSpec then
                table.insert(insufficient, "Internet Card (" .. internetSpec .. " < " .. requiredSpec .. ")")
            end
        end
    end
    
    -- Check Screen
    if requirements.screen then
        local requiredType = requirements.screen.type
        local requiredSpec = requirements.screen.spec or "T1"
        
        local availableScreen = computer.getPCIDevices(classes.Screen)[1]
        if not availableScreen then
            table.insert(missing, "Screen")
        else
            -- In a real implementation, we would check the actual screen type
            -- For now, we'll assume it meets requirements
            local screenSpec = availableScreen.spec or "T1"
            if screenSpec < requiredSpec then
                table.insert(insufficient, "Screen (" .. screenSpec .. " < " .. requiredSpec .. ")")
            end
        end
    end
    
    return #missing == 0 and #insufficient == 0, missing, insufficient
end

-- Check if program can run on current machine
function canRunProgram(programName)
    local requirements = getProgramRequirements(programName)
    if not requirements or next(requirements) == nil then
        return true -- No requirements means it can run anywhere
    end
    
    return checkEquipmentRequirements(requirements)
end

-- Get equipment specifications
function getEquipmentSpecs()
    return EQUIPMENT_TYPES
end

-- Calculate required resources
function calculateRequiredResources(requirements)
    local total = {
        cpuPower = 0,
        ramSize = 0,
        hddSize = 0,
        gpuPower = 0,
        networkSpeed = 0,
        internetSpeed = 0
    }
    
    if requirements.cpu then
        local spec = requirements.cpu.spec or "T1"
        total.cpuPower = EQUIPMENT_TYPES.CPU[spec].power
    end
    
    if requirements.ram then
        local spec = requirements.ram.spec or "T1"
        total.ramSize = EQUIPMENT_TYPES.RAM[spec].size
    end
    
    if requirements.hdd then
        local spec = requirements.hdd.spec or "T1"
        total.hddSize = EQUIPMENT_TYPES.HDD[spec].size
    end
    
    if requirements.gpu then
        local spec = requirements.gpu.spec or "T1"
        total.gpuPower = EQUIPMENT_TYPES.GPU[spec].power
    end
    
    if requirements.networkCard then
        local spec = requirements.networkCard.spec or "T1"
        total.networkSpeed = EQUIPMENT_TYPES.NETWORK_CARD[spec].speed
    end
    
    if requirements.internetCard then
        local spec = requirements.internetCard.spec or "T1"
        total.internetSpeed = EQUIPMENT_TYPES.INTERNET_CARD[spec].speed
    end
    
    return total
end

return {
    EQUIPMENT_TYPES = EQUIPMENT_TYPES,
    register = registerProgramRequirements,
    getRequirements = getProgramRequirements,
    checkRequirements = checkEquipmentRequirements,
    canRun = canRunProgram,
    getSpecs = getEquipmentSpecs,
    calculateResources = calculateRequiredResources
}
