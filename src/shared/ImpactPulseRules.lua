-- Prevent simultaneous meteor/bomb impact feedback from filling the playfield.
-- Rendering may be reduced, but the server's damage and hazard timing never are.
local ImpactPulseRules = {}
local DisasterCosmeticRules = require(script.Parent.DisasterCosmeticRules)
local BUDGETS = {
    Low = {Near = 70, Concurrent = 2, Expansion = 1.04},
    Medium = {Near = 105, Concurrent = 3, Expansion = 1.16},
    High = {Near = 140, Concurrent = 4, Expansion = 1.22},
}

function ImpactPulseRules.profile(tier, reducedMotion)
    local base = BUDGETS[tostring(tier or "")] or BUDGETS.Low
    if reducedMotion == true then
        return {Near = 45, Concurrent = 1, Expansion = 0.76}
    end
    return base
end

-- Concurrent is the number of bursts including this one. A pulse is
-- permitted exactly up to the tier budget, never one beyond it.
function ImpactPulseRules.pulse(tier, reducedMotion, distance, concurrent, kind)
    local cfg = ImpactPulseRules.profile(tier, reducedMotion)
    if type(distance) ~= "number" or distance ~= distance
        or distance < 0 or distance == math.huge
        or distance > cfg.Near or type(concurrent) ~= "number"
        or concurrent ~= concurrent or concurrent % 1 ~= 0
        or concurrent < 1 or concurrent > cfg.Concurrent then
        return nil
    end
    local meteor = kind == "Meteor"
    local bomb = kind == "Bomb"
    if not meteor and not bomb then return nil end
    return {
        Scale = cfg.Expansion * (meteor and 0.92 or 1.10),
        Duration = reducedMotion and 0.12 or (meteor and 0.30 or 0.34),
        Alpha = reducedMotion and 0.76 or (meteor and 0.38 or 0.48),
        Name = meteor and "MeteorCraterWave" or "BombPressureWave",
    }
end

-- Preserve every nearby explosion's compact signature while limiting
-- expensive secondary lights, smoke and spark emitters in overlapping
-- Bomb + Meteor rounds on touch devices. Desktop keeps its prior budgets.
-- This governs cosmetics ONLY; blast radius and damage stay server-owned.
function ImpactPulseRules.richDetailAllowed(tier, reduced, distance,
        concurrent, touchDevice)
    if reduced == true or (tier ~= "High" and tier ~= "Medium")
        or type(distance) ~= "number" or distance ~= distance
        or distance < 0 or distance == math.huge
        or type(concurrent) ~= "number" or concurrent ~= concurrent
        or concurrent % 1 ~= 0 or concurrent < 1 then
        return false
    end
    local high = tier == "High"
    local limit = if touchDevice == true
        then (high and 3 or 2) else (high and 10 or 8)
    local range = high and 100 or 72
    return concurrent <= limit and distance <= range
end


-- Distant cosmetic bursts must not consume the entire simultaneous-impact
-- queue before a blast near the player's camera arrives. This is a SECOND,
-- smaller pool for peripheral effects on Android only. Nearby explosions
-- still use the existing total queue; no server warning or damage is gated.
-- nil means the impact is near enough (or desktop) to bypass this sub-cap.
function ImpactPulseRules.peripheralBurstCap(tier, reducedMotion, touchDevice, distance)
    if touchDevice ~= true or type(distance) ~= "number"
        or distance ~= distance or distance < 0
        or math.abs(distance) == math.huge then
        return nil
    end
    local near = tier == "Low" and 48
        or (tier == "Medium" and 72 or 88)
    if distance <= near then return nil end
    return reducedMotion == true and 1
        or (tier == "Low" and 1 or 2)
end

-- A short flash lasts ~0.3–0.4s, but airborne material chips and
-- local impact sculptures remain alive for up to ~1.01s. Protect an
-- independent, long-lived pool for OPTIONAL geometry on touch clients.
-- The flash, warning HUD and server damage are outside this cap.
-- Zero explicitly disables sculpture in ReduceMotion; those clients
-- retain the existing compact central flash and critical danger cues.
function ImpactPulseRules.decorativeBundleCap(tier, reduced, simultaneous)
    if reduced == true then return 0 end
    local base = tier == "Low" and 2
        or (tier == "Medium" and 3 or (tier == "High" and 4 or 0))
    if base == 0 then return 0 end
    local pressure = DisasterCosmeticRules.pressureMultiplier(simultaneous)
    return math.max(1, math.min(base, math.floor(base * pressure + 0.5)))
end

-- Retention covers ImpactSetpiece's 0.85s + 0.12s cleanup and material
-- chip's 0.87s + 0.14s cleanup. Do not free the cosmetic slot at the
-- shorter flash lifetime while its parts still occupy the GPU budget.
function ImpactPulseRules.decorativeBundleHoldSeconds()
    return 1.10
end

-- Peripheral impacts remain perceptible through the existing compact
-- pressure wave, warning glyph and audio. On touch GPUs, reserve the
-- expensive smoke, PointLight and extra fragment sculpture for explosions
-- actually near the camera or visibly inside its viewport. A near blast
-- keeps full impact feedback even if the player briefly looks away.
function ImpactPulseRules.richDetailVisible(touchDevice, distance, inViewport)
    if touchDevice ~= true or inViewport ~= false then
        return true
    end
    return type(distance) == "number" and distance == distance
        and distance >= 0 and distance <= 28
end

return ImpactPulseRules
