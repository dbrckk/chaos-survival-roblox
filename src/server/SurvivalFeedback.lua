local SurvivalFeedback = {}

SurvivalFeedback.CriticalHealthRatio = 0.20

function SurvivalFeedback.isCriticalHealth(health, maxHealth)
    local current = math.max(0, tonumber(health) or 0)
    local maximum = math.max(0, tonumber(maxHealth) or 0)

    if maximum <= 0 or current <= 0 then
        return false
    end

    return (current / maximum) <= SurvivalFeedback.CriticalHealthRatio
end

-- Bots already restore full health when they enter their next match.
-- Human survivors must receive the same reset, but ONLY on successfully
-- spawning into the next READY phase. Never heal mid-disaster or resurrect
-- dead rigs here, and preserve custom MaxHealth set by non-pay-to-win modes.
function SurvivalFeedback.restoreForNextRound(humanoid)
    if typeof(humanoid) ~= "Instance" or not humanoid:IsA("Humanoid") then
        return false
    end
    local current = humanoid.Health
    local maximum = humanoid.MaxHealth
    if current <= 0 or maximum <= 0
        or current ~= current or maximum ~= maximum
        or current == math.huge or maximum == math.huge
    then
        return false
    end
    humanoid.Health = maximum
    return true
end

return SurvivalFeedback
