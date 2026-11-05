--!strict
-- Small defensive conversion layer for 45-second client FPS/memory pulses.
-- A suspended Android Stats sampler or malformed network payload must never
-- throw in the server event handler or poison Analytics with NaN/Infinity.
-- Pure, bounded transformations; does not trust a client to certify device FPS.
local PerformancePulseRules = {}

local LIMITS = {
    averageFps = {240, false},
    -- Percentile pacing survives one-off OS hitches; both numbers are
    -- client-reported and diagnostic only, never trusted for game logic.
    p95FrameMs = {600, true},
    slowFramePercent = {100, true},
    tierTransitions = {99, true},
    visualParts = {5000, true},
    visualLights = {1000, true},
    visualEffects = {2000, true},
    -- Current visible-client residency of approved PBR MaterialVariants.
    -- These are diagnostic counters, never a server-authoritative receipt.
    pbrActive = {144, true},
    pbrBudget = {144, true},
    pbrCandidates = {10000, true},
    -- Genuine mounted creator-owned MeshPart Models, read from the
    -- established scenery owner's local counters every 45 seconds.
    -- These counts are advisory and never grant gameplay/rewards.
    originalGround = {36, true},
    originalRoutes = {40, true},
    originalHorizon = {11, true},
    originalTraffic = {4, true},
    originalHalo = {5, true},
    originalHorizonMasked = {33, true},
    originalHaloMasked = {5, true},
    optionalPressure = {2, true},
    totalMemoryMb = {65536, false},
    instanceCount = {250000, true},
    frameTimeMs = {1000, false},
    renderCpuMs = {1000, false},
    renderGpuMs = {1000, false},
}

local function bounded(value, maxValue, integer)
    -- Do not coerce arbitrary Roblox Instances/tables into analytics tags.
    local number = tonumber(value)
    if not number or number ~= number or math.abs(number) == math.huge then
        return 0
    end
    local clamped = math.clamp(number, 0, maxValue)
    return integer and math.floor(clamped) or clamped
end

-- Modes are session-local, diagnostic only. Never use a client-reported
-- graphics mode to grant rewards or make gameplay decisions.
-- Sample the first actual Android session soon enough to observe
-- streaming and onboarding exits; then retain the 45-second, existing
-- server RateLimiter cadence. No second sampler or RenderStepped.
function PerformancePulseRules.pulseInterval(first)
    return first == true and 12 or 45
end

function PerformancePulseRules.currentPbrMode(isTouch, disabled)
    return isTouch == true and disabled == true and "OFF" or "AUTO"
end

function PerformancePulseRules.sanitize(raw)
    local source = type(raw) == "table" and raw or {}
    local result = {}
    for key, config in pairs(LIMITS) do
        result[key] = bounded(source[key], config[1], config[2])
    end

    local tier = source.vfxTier
    result.vfxTier = (tier == "Low" or tier == "Medium" or tier == "High")
        and tier or "Unknown"

    local mode = source.pbrMode
    result.pbrMode = (mode == "AUTO" or mode == "OFF" or mode == "MIXED")
        and mode or "Unknown"

    -- Only these two classes are emitted by the real client; accepting
    -- arbitrary text explodes analytics dimensions and needlessly allocates.
    local device = source.deviceClass
    result.deviceClass = (device == "Touch" or device == "Desktop")
        and device or "Unknown"
    local VALID_ARENA = {
        Classic = true, Towers = true, Crossroads = true,
        Orbital = true, Harbor = true,
    }
    result.arenaVariant = VALID_ARENA[source.arenaVariant]
        and source.arenaVariant or "Unknown"
    return result
end

-- Roblox AnalyticsService accepts only 3 custom dimensions and caps their
-- combined unique values. Presence flags (not raw counts) keep cardinality
-- small: <=6 arenas x 12 device/tier classes x 32 bit combinations.
-- A numeric total retains actual sampled residency in event aggregation.
-- A model is considered RESIDENT by the source owner; this does NOT prove
-- it was visible in a photographed frame on an Android device.
local function presence(count)
    return count > 0 and "1" or "0"
end

function PerformancePulseRules.original3DAnalytics(sample)
    local s = PerformancePulseRules.sanitize(sample)
    local total = s.originalGround + s.originalRoutes
        + s.originalHorizon + s.originalTraffic + s.originalHalo
    local fallbackMismatch = s.originalHorizon > 0
        and s.originalHorizonMasked == 0
        or s.originalHalo > 0 and s.originalHaloMasked == 0
    local flags = "P" .. presence(s.originalGround + s.originalRoutes)
        .. "C" .. presence(s.originalHorizon)
        .. "T" .. presence(s.originalTraffic)
        .. "H" .. presence(s.originalHalo)
        .. "F" .. (fallbackMismatch and "1" or "0")
    return total, "Arena:" .. s.arenaVariant,
        "Device:" .. s.deviceClass .. "|VFX:" .. s.vfxTier,
        flags
end

return PerformancePulseRules
