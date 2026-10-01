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

return SurvivalFeedback
