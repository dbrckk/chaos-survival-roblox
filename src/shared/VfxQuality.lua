local VfxQuality = {}

VfxQuality.Tiers = {
    High = {
        Name = "High",
        Scale = 1,
        ParticleScale = 1,
        RaysEnabled = true,
        UpdateInterval = 1 / 60,
    },
    Medium = {
        Name = "Medium",
        Scale = 0.78,
        ParticleScale = 0.72,
        RaysEnabled = true,
        UpdateInterval = 1 / 45,
    },
    Low = {
        Name = "Low",
        Scale = 0.58,
        ParticleScale = 0.45,
        RaysEnabled = false,
        UpdateInterval = 1 / 30,
    },
}

function VfxQuality.initialTier(isTouchDevice)
    return isTouchDevice == true and "Medium" or "High"
end

function VfxQuality.initialTier(isTouchDevice)
    return isTouchDevice == true and "Medium" or "High"
end

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

function VfxQuality.particleCount(tier, baseCount, minimum)
    local profile = VfxQuality.get(tier)
    local base = math.max(0, tonumber(baseCount) or 0)
    local floorCount = math.max(0, tonumber(minimum) or 0)
    return math.max(floorCount, math.floor((base * profile.ParticleScale) + 0.5))
end

return VfxQuality
