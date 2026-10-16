local VfxQuality = {}

VfxQuality.Tiers = {
    High = {
        Name = "High",
        Scale = 1,
        ParticleScale = 1,
        RaysEnabled = true,
        UpdateInterval = 1 / 60,
        DecorUpdateInterval = 1 / 30,
    },
    Medium = {
        Name = "Medium",
        Scale = 0.78,
        ParticleScale = 0.72,
        RaysEnabled = true,
        UpdateInterval = 1 / 45,
        DecorUpdateInterval = 1 / 24,
    },
    Low = {
        Name = "Low",
        Scale = 0.58,
        ParticleScale = 0.45,
        RaysEnabled = false,
        UpdateInterval = 1 / 30,
        DecorUpdateInterval = 1 / 15,
    },
}

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

local TIER_RANK = {
    Low = 1,
    Medium = 2,
    High = 3,
}

function VfxQuality.requiredStableSamples(currentTier, nextTier, isTouchDevice)
    local current = VfxQuality.Tiers[currentTier] and currentTier or "High"
    local nextValue = VfxQuality.Tiers[nextTier] and nextTier or current

    if nextValue == current then
        return 0
    end

    local currentRank = TIER_RANK[current] or 3
    local nextRank = TIER_RANK[nextValue] or currentRank
    if nextRank < currentRank then
        -- Performance drops should react immediately.
        return 1
    end

    -- Promotions are intentionally slower so short FPS spikes do not push a
    -- device back into a heavier visual tier before thermal/performance state
    -- has actually stabilized.
    return isTouchDevice == true and 3 or 2
end

function VfxQuality.get(tier)
    return VfxQuality.Tiers[tier] or VfxQuality.Tiers.High
end

-- Hazard-only scenery pulses and decoration need less frequent refreshes
-- than gameplay warnings or hit detection. Reduced motion conserves even
-- more mobile update work without suppressing static hazard cues.
function VfxQuality.decorativeInterval(tier, reducedMotion)
    local interval = VfxQuality.get(tier).DecorUpdateInterval
    return math.max(interval, reducedMotion == true and (1 / 12) or 0)
end

function VfxQuality.particleCount(tier, baseCount, minimum)
    local profile = VfxQuality.get(tier)
    local base = math.max(0, tonumber(baseCount) or 0)
    local floorCount = math.max(0, tonumber(minimum) or 0)
    return math.max(floorCount, math.floor((base * profile.ParticleScale) + 0.5))
end

return VfxQuality
