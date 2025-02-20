function deepcopy(orig, copies)
    copies = copies or {}  -- Table pour éviter les références circulaires
    if type(orig) ~= "table" then
        return orig  -- Retourne la valeur si ce n'est pas une table
    elseif copies[orig] then
        return copies[orig]  -- Retourne la copie déjà faite si elle existe
    end
    
    local copy = {}  -- Nouvelle table copiée
    copies[orig] = copy  -- Stocker la référence pour éviter les boucles infinies
    
    for k, v in pairs(orig) do
        copy[deepcopy(k, copies)] = deepcopy(v, copies)  -- Copie récursive
    end
    
    return setmetatable(copy, getmetatable(orig))  -- Copie aussi la métatable
end
