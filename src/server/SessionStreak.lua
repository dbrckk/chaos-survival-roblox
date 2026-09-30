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

function SessionStreak.bonusCoins(streak)
    local value = math.max(0, tonumber(streak) or 0)
    if value < 2 then
        return 0
    end

    return math.min(10, (value - 1) * 2)
end

return SessionStreak
