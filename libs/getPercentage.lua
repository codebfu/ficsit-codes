function getPercentage(count, max)
    local percent = 0
    if count > 0 then
        percent = math.ceil(100 * count / max)
    end
    return percent
end
