--!strict
-- Client-only backpressure for purely decorative visual layers. This module
-- never controls authoritative warnings, physics, particles from hazards,
-- camera safety indicators or damage. Budget metrics are diagnostic counts,
-- not proof of GPU work; combine them with measured local frame pacing.
-- Published Roblox assets use sibling ModuleScripts; Lest's source
-- module imports run without a script Instance.
local VisualBudgetRules = if script and script.Parent
    then require(script.Parent.VisualBudgetRules)
    else require("./VisualBudgetRules")
local Rules = {}

local function finite(value)
    return type(value) == "number" and value == value
        and math.abs(value) < math.huge
end

function Rules.desired(tier, metrics, fps, p95)
    local budget = VisualBudgetRules.forTier(tier)
    local values = type(metrics) == "table" and metrics or {}
    local ratio = 0
    for _, name in ipairs({"Parts", "Lights", "Effects"}) do
        local n = tonumber(values[name]) or 0
        if finite(n) then
            ratio = math.max(ratio, math.max(0, n) / budget[name])
        end
    end

    local validFps = finite(fps) and fps > 0 and fps <= 240
    local validP95 = finite(p95) and p95 > 0 and p95 <= 600
    -- Healthy frame pacing must allow cosmetic recovery even if a large
    -- number of invisible or disabled Instances remain in the ledger.
    if validFps and fps >= 55 and (not validP95 or p95 <= 35) then
        return ratio >= 1.35 and 1 or 0
    end
    if ratio >= 1.20
        or (validFps and fps < 27)
        or (validP95 and p95 >= 75) then
        return 2
    end
    if ratio >= 1.05
        or (validFps and fps < 43)
        or (validP95 and p95 >= 50) then
        return 1
    end
    return 0
end

-- Pressure changes ONE stage at a time and only after repeated samples.
-- Two bad samples to degrade, three healthy ones to restore. Missing or
-- malformed metrics cannot cause a sudden uncontrolled quality promotion.
function Rules.advance(level, streak, desired)
    local current = math.clamp(math.floor(tonumber(level) or 0), 0, 2)
    local target = math.clamp(math.floor(tonumber(desired) or 0), 0, 2)
    if target == current then return current, 0 end
    local direction = target > current and 1 or -1
    local signed = tonumber(streak) or 0
    if not finite(signed) or signed * direction < 0 then signed = 0 end
    signed += direction
    if math.abs(signed) >= (direction > 0 and 2 or 3) then
        return current + direction, 0
    end
    return current, signed
end

function Rules.emissionScale(level)
    if level == 2 then return 0.30 end
    if level == 1 then return 0.65 end
    return 1
end

function Rules.optionalLightAllowed(level)
    return level ~= 1 and level ~= 2
end

return Rules
