local CharacterPolishRules = {}

function CharacterPolishRules.outlineTransparency(tierName, phase, localCharacter, aiCharacter, finalRush)
    local tier = tostring(tierName or "Medium")
    local state = tostring(phase or "waiting")

    if finalRush == true then
        return localCharacter == true and 0.50 or 0.82
    end

    if state == "round" or state == "ready" then
        if localCharacter == true then
            return tier == "Low" and 0.68 or (tier == "Medium" and 0.54 or 0.44)
        elseif aiCharacter == true then
            return tier == "Low" and 0.86 or (tier == "Medium" and 0.76 or 0.68)
        end
        return tier == "Low" and 0.90 or (tier == "Medium" and 0.82 or 0.75)
    end

    return localCharacter == true and 0.78 or 0.92
end

function CharacterPolishRules.fillTransparency(tierName, phase, localCharacter, finalRush)
    local tier = tostring(tierName or "Medium")
    local state = tostring(phase or "waiting")

    if finalRush == true or tier == "Low" then
        return 1
    end

    if localCharacter == true and (state == "round" or state == "ready") then
        return tier == "High" and 0.94 or 0.97
    end

    return 1
end

function CharacterPolishRules.lightBrightness(tierName, phase, localCharacter, finalRush)
    if finalRush == true or tostring(tierName) == "Low" then
        return 0
    end

    local state = tostring(phase or "waiting")
    if state ~= "round" and state ~= "ready" then
        return 0
    end

    if localCharacter == true then
        return tostring(tierName) == "High" and 0.42 or 0.22
    end
    return tostring(tierName) == "High" and 0.18 or 0
end

function CharacterPolishRules.trailLifetime(tierName, reduceMotion, finalRush)
    local tier = tostring(tierName or "Medium")
    local lifetime = tier == "Low" and 0.18 or (tier == "Medium" and 0.28 or 0.36)

    if reduceMotion == true then
        lifetime *= 0.58
    end
    if finalRush == true then
        lifetime = math.min(lifetime, 0.13)
    end

    return lifetime
end

return CharacterPolishRules
