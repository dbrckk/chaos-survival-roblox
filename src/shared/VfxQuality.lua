local VfxQuality = {}

VfxQuality.Tiers = {
    High = {
        Name = "High",
        Scale = 1,
        ParticleScale = 1,
        RaysEnabled = true,
    },
    Medium = {
        Name = "Medium",
        Scale = 0.78,
        ParticleScale = 0.72,
        RaysEnabled = true,
    },
    Low = {
        Name = "Low",
        Scale = 0.58,
        ParticleScale = 0.45,
        RaysEnabled = false,
    },
}

function VfxQuality.nextTier(currentTier, averageFps)
    local fps = tonumber(averageFps) or 60
    local current = VfxQuality.Tiers[currentTier] and currentTier or "High"

    if current == "High" then
        if fps < 42 then
            return "Medium"
        end
        return "High"
    end

    if current == "Medium" then
        if fps < 32 then
            return "Low"
        elseif fps > 54 then
            return "High"
        end
        return "Medium"
    end

    if fps > 44 then
        return "Medium"
    end
    return "Low"
end

function VfxQuality.get(tier)
    return VfxQuality.Tiers[tier] or VfxQuality.Tiers.High
end

return VfxQuality
