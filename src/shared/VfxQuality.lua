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

function VfxQuality.nextTier(currentTier, averageFps, isTouchDevice)
    local fps = tonumber(averageFps) or 60
    local current = VfxQuality.Tiers[currentTier] and currentTier or "High"
    local touch = isTouchDevice == true

    if current == "High" then
        local degradeThreshold = touch and 48 or 42
        if fps < degradeThreshold then
            return "Medium"
        end
        return "High"
    end

    if current == "Medium" then
        if fps < 32 then
            return "Low"
        end

        local upgradeThreshold = touch and 58 or 54
        if fps > upgradeThreshold then
            return "High"
        end
        return "Medium"
    end

    local recoveryThreshold = touch and 46 or 44
    if fps > recoveryThreshold then
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
