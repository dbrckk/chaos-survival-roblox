local RoundIntensity = {}

function RoundIntensity.progress(elapsedSeconds, roundSeconds)
    local total = math.max(1, tonumber(roundSeconds) or 1)
    local elapsed = math.max(0, tonumber(elapsedSeconds) or 0)
    return math.clamp(elapsed / total, 0, 1)
end

function RoundIntensity.factor(elapsedSeconds, roundSeconds, solo, doubleChaos)
    local progress = RoundIntensity.progress(elapsedSeconds, roundSeconds)

    local startFactor = 0.92
    local endFactor = 1.22

    if solo then
        endFactor = 1.14
    end

    if doubleChaos then
        startFactor = math.min(startFactor, 0.88)
        endFactor = math.min(endFactor, solo and 1.06 or 1.10)
    end

    -- Three deliberate acts: readable opening, sustained middle pressure,
    -- then a short climactic finale. Smooth interpolation at the joins
    -- avoids an abrupt unfair spike during a player's committed jump.
    local eased
    if progress <= 0.22 then
        local t = progress / 0.22
        eased = 0.18 * t * t * (3 - 2 * t)
    elseif progress <= 0.76 then
        local t = (progress - 0.22) / 0.54
        eased = 0.18 + 0.57 * t * t * (3 - 2 * t)
    else
        local t = (progress - 0.76) / 0.24
        eased = 0.75 + 0.25 * t * t * (3 - 2 * t)
    end
    return startFactor + ((endFactor - startFactor) * eased)
end

function RoundIntensity.spawnDelay(baseSeconds, factor, minimumSeconds)
    local base = math.max(0.05, tonumber(baseSeconds) or 1)
    local intensity = math.max(0.1, tonumber(factor) or 1)
    local minimum = math.max(0.05, tonumber(minimumSeconds) or 0.2)
    return math.max(minimum, base / intensity)
end

return RoundIntensity
