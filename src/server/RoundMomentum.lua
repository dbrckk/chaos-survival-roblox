local RoundMomentum = {}

RoundMomentum.WindowSeconds = 6

function RoundMomentum.next(currentCombo, lastActionAt, now)
    local current = math.max(0, math.floor(tonumber(currentCombo) or 0))
    local lastAt = tonumber(lastActionAt)
    local currentAt = tonumber(now)

    if not currentAt then
        return 1
    end

    if lastAt and lastAt > 0 and currentAt >= lastAt and (currentAt - lastAt) <= RoundMomentum.WindowSeconds then
        return current + 1
    end

    return 1
end

return RoundMomentum
