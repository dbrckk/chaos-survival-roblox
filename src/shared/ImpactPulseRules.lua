-- Prevent simultaneous meteor/bomb impact feedback from filling the playfield.
-- Rendering may be reduced, but the server's damage and hazard timing never are.
local ImpactPulseRules = {}
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

function ImpactPulseRules.pulse(tier, reducedMotion, distance, concurrent, kind)
    local cfg = ImpactPulseRules.profile(tier, reducedMotion)
    if type(distance) ~= "number" or distance < 0
        or distance > cfg.Near or (tonumber(concurrent) or 0) > cfg.Concurrent then
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

return ImpactPulseRules
