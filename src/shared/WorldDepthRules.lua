local WorldDepthRules = {}

function WorldDepthRules.budgets(tierName)
    local tier = tostring(tierName or "Medium")
    if tier == "Low" then
        return {
            TransitRibs = 3,
            HorizonStructures = 6,
            HorizonAccents = 2,
            UnderworldStruts = 2,
        }
    elseif tier == "High" then
        return {
            TransitRibs = 6,
            HorizonStructures = 12,
            HorizonAccents = 7,
            UnderworldStruts = 5,
        }
    end

    return {
        TransitRibs = 4,
        HorizonStructures = 8,
        HorizonAccents = 4,
        UnderworldStruts = 3,
    }
end

function WorldDepthRules.worldCenter(lobbyCenter, arenaCenter)
    return lobbyCenter:Lerp(arenaCenter, 0.5)
end

function WorldDepthRules.transitionSample(lobbyCenter, arenaCenter, index, count)
    local safeCount = math.max(1, math.floor(tonumber(count) or 1))
    local safeIndex = math.clamp(
        math.floor(tonumber(index) or 1),
        1,
        safeCount
    )

    local startAlpha = 0.24
    local endAlpha = 0.66
    local alpha = safeCount == 1
        and ((startAlpha + endAlpha) * 0.5)
        or startAlpha
            + (endAlpha - startAlpha)
            * ((safeIndex - 1) / (safeCount - 1))

    return lobbyCenter:Lerp(arenaCenter, alpha), alpha
end

function WorldDepthRules.horizonRadius(tierName)
    local tier = tostring(tierName or "Medium")
    if tier == "Low" then
        return 215
    elseif tier == "High" then
        return 245
    end
    return 230
end

function WorldDepthRules.horizonHeight(index)
    local i = math.max(1, math.floor(tonumber(index) or 1))
    return 34 + ((i * 17) % 52)
end

return WorldDepthRules
