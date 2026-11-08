--[[ Dependency Management Library ]]--

-- Dependency graph
local dependencyGraph = {}

-- Program states
local programStates = {}

-- Initialize dependency management
function initDependencyManagement()
    dependencyGraph = {}
    programStates = {}
end

-- Register a program with its dependencies
function registerProgram(name, dependencies)
    dependencyGraph[name] = dependencies or {}
    programStates[name] = { status = "uninitialized", version = nil }
end

-- Get dependencies for a program
function getDependencies(name)
    return dependencyGraph[name] or {}
end

-- Get all dependencies (recursive)
function getAllDependencies(name, visited)
    visited = visited or {}
    local deps = {}
    
    for dep, _ in pairs(getDependencies(name)) do
        if not visited[dep] then
            visited[dep] = true
            deps[dep] = true
            
            -- Recursively get dependencies of dependencies
            for subdep, _ in pairs(getAllDependencies(dep, visited)) do
                deps[subdep] = true
            end
        end
    end
    
    return deps
end

-- Check if all dependencies are satisfied
function checkDependencies(name)
    local allDeps = getAllDependencies(name)
    local satisfied = true
    local missing = {}
    
    for dep, _ in pairs(allDeps) do
        if not programStates[dep] or programStates[dep].status ~= "running" then
            satisfied = false
            table.insert(missing, dep)
        end
    end
    
    return satisfied, missing
end

-- Get execution order based on dependencies
function getExecutionOrder(programs)
    local order = {}
    local visited = {}
    local tempVisited = {}
    
    local function visit(name)
        if tempVisited[name] then
            error("Circular dependency detected: " .. name)
        end
        
        if not visited[name] then
            tempVisited[name] = true
            
            for dep, _ in pairs(getDependencies(name)) do
                if programs[dep] then
                    visit(dep)
                end
            end
            
            tempVisited[name] = nil
            visited[name] = true
            table.insert(order, name)
        end
    end
    
    for name, _ in pairs(programs) do
        visit(name)
    end
    
    return order
end

-- Update program state
function updateProgramState(name, state, version)
    if programStates[name] then
        programStates[name].status = state
        if version then
            programStates[name].version = version
        end
    else
        registerProgram(name, {})
        programStates[name].status = state
        programStates[name].version = version
    end
end

-- Get program state
function getProgramState(name)
    return programStates[name] or { status = "unknown", version = nil }
end

-- Check if a program needs update
function needsUpdate(name, currentVersion, latestVersion)
    return currentVersion ~= latestVersion
end

return {
    init = initDependencyManagement,
    register = registerProgram,
    getDependencies = getDependencies,
    getAllDependencies = getAllDependencies,
    checkDependencies = checkDependencies,
    getExecutionOrder = getExecutionOrder,
    updateState = updateProgramState,
    getState = getProgramState,
    needsUpdate = needsUpdate
}
