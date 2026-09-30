local SessionStreak = {}

function SessionStreak.update(current, best, survived)
    local currentValue = math.max(0, tonumber(current) or 0)
    local bestValue = math.max(0, tonumber(best) or 0)

    if survived then
        currentValue += 1
        bestValue = math.max(bestValue, currentValue)
    else
        currentValue = 0
    end

    return currentValue, bestValue
end

return SessionStreak
