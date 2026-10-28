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

function PerformancePulseRules.sanitize(raw)
    local source = type(raw) == "table" and raw or {}
    local result = {}
    for key, config in pairs(LIMITS) do
        result[key] = bounded(source[key], config[1], config[2])
    end

    local tier = source.vfxTier
    result.vfxTier = (tier == "Low" or tier == "Medium" or tier == "High")
        and tier or "Unknown"

    -- Only these two classes are emitted by the real client; accepting
    -- arbitrary text explodes analytics dimensions and needlessly allocates.
    local device = source.deviceClass
    result.deviceClass = (device == "Touch" or device == "Desktop")
        and device or "Unknown"
    return result
end

return PerformancePulseRules
