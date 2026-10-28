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

-- Count only active rendered frames in the adaptive-quality sampler.
-- Resuming a suspended Android app can deliver a multi-second RenderStepped
-- dt; interpreting that as sustained low FPS can incorrectly degrade the
-- entire arena immediately after returning. Genuine 2-5 FPS frames remain
-- measurable, so persistently weak hardware still downgrades.
function VfxQuality.activeFrameSeconds(dt)
    if type(dt) ~= "number" or dt ~= dt or dt == math.huge
        or dt == -math.huge or dt <= 0 or dt > 0.60 then
        return 0
    end
    return dt
end

function VfxQuality.initialTier(isTouchDevice)
    return isTouchDevice == true and "Medium" or "High"
end

-- Pacing inputs are optional for compatibility with existing callers.
-- Touch-only hysteresis responds to repeated long frames that average FPS
-- alone conceals. Never let a single spike, paused app or malformed sample
-- trigger a quality drop. This changes cosmetics, never gameplay warnings.
function VfxQuality.nextTier(currentTier, averageFps, isTouchDevice,
    p95FrameMs, slowFramePercent)
    local fps = tonumber(averageFps) or 60
    local current = VfxQuality.Tiers[currentTier] and currentTier or "High"
    local touch = isTouchDevice == true
    local validPacing = touch
        and type(p95FrameMs) == "number"
        and p95FrameMs == p95FrameMs
        and p95FrameMs > 0 and p95FrameMs <= 600
        and type(slowFramePercent) == "number"
        and slowFramePercent == slowFramePercent
        and slowFramePercent >= 0 and slowFramePercent <= 100

    -- P95 requires >=5% affected frames; the slow-frame share requires
    -- >=12% affected frames, so neither isolated spikes nor a one-off
    -- transition can force Low graphics on an otherwise smooth device.
    local repeatedStutter = validPacing
        and p95FrameMs >= 45 and slowFramePercent >= 12
    local severeStutter = validPacing
        and p95FrameMs >= 65 and slowFramePercent >= 25
    local promotionSafe = not validPacing
        or (p95FrameMs <= 32 and slowFramePercent <= 8)

    if current == "High" then
        -- Keep desktop thresholds unchanged. Android lowers optional
        -- materials and effects when frame pacing degrades repeatedly.
        if fps < (touch and 48 or 42) or repeatedStutter then
            return "Medium"
        end
        return "High"
    end

    if current == "Medium" then
        if fps < 32 or severeStutter then
            return "Low"
        elseif fps > (touch and 58 or 54) and promotionSafe then
            return "High"
        end
        return "Medium"
    end

    if fps > (touch and 46 or 44) and promotionSafe then
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

-- Before adaptive FPS sampling publishes a tier, touch devices start
-- cosmetics at Medium rather than briefly allocating desktop High.
function VfxQuality.deviceTier(tierName, isTouchDevice)
    if type(tierName) == "string" and VfxQuality.Tiers[tierName] then
        return VfxQuality.Tiers[tierName]
    end
    return VfxQuality.Tiers[VfxQuality.initialTier(isTouchDevice)]
end

-- Hazard-only scenery pulses and decoration need less frequent refreshes
-- than gameplay warnings or hit detection. Reduced motion conserves even
-- more mobile update work without suppressing static hazard cues.
function VfxQuality.decorativeInterval(tier, reducedMotion)
    local interval = VfxQuality.get(tier).DecorUpdateInterval
    return math.max(interval, reducedMotion == true and (1 / 12) or 0)
end

-- The persistent tornado controller is loaded for EVERY player, even
-- outside tornado rounds. It needs no 30-60Hz idle work; when active,
-- reuse the existing decorative budget rather than the high-FPS
-- gameplay cadence. Reduced-motion uses at most 12 visual refreshes/s.
function VfxQuality.tornadoInterval(tier, reducedMotion, active)
    if active ~= true then
        return 0.40
    end
    return VfxQuality.decorativeInterval(tier, reducedMotion)
end

-- Nonessential mobility/pickup flashes must never wash the entire
-- Android screen during a hazard. This does NOT affect the actual
-- disaster warning UI, camera shake or any server-authoritative mechanics.
function VfxQuality.optionalFullScreenFlashAllowed(isTouchDevice, reducedMotion)
    return isTouchDevice ~= true and reducedMotion ~= true
end

function VfxQuality.particleCount(tier, baseCount, minimum)
    local profile = VfxQuality.get(tier)
    local base = math.max(0, tonumber(baseCount) or 0)
    local floorCount = math.max(0, tonumber(minimum) or 0)
    return math.max(floorCount, math.floor((base * profile.ParticleScale) + 0.5))
end

return VfxQuality
