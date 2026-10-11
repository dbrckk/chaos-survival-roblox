-- Cosmetic human momentum trail budget; never affects movement or damage.
-- Distances are in studs; tier caps prevent unnecessary GPU trail rendering.
local Rules = {}

function Rules.visible(phase, finalRush, airborne, ratio, tier, reduceMotion, distance, wasVisible)
    if phase ~= "round" or finalRush == true or airborne == true
        or reduceMotion == true or (tier ~= "Medium" and tier ~= "High")
    then
        return false
    end
    -- Hysteresis avoids rapidly recreating translucent segments when
    -- velocity jitters near sprint speed or the camera crosses a cull edge.
    -- A previously visible ribbon may persist for 3 more studs, but never
    -- bypasses phase, airborne, Low, or ReduceMotion restrictions.
    local retained = wasVisible == true
    local limit = (tier == "High" and 90 or 60) + (retained and 3 or 0)
    local threshold = retained and 0.76 or 0.82
    return (tonumber(ratio) or 0) > threshold
        and (tonumber(distance) or math.huge) <= limit
end

-- Pure human trail rules are loadable by Lest via source path without script.Parent.

-- Spectators and eliminated players must not show active-contestant momentum.
function Rules.humanEligible(participant, eliminated)
    return participant == true and eliminated ~= true
end

function Rules.style(tier)
    if tier == "High" then
        return 0.14, 0.34
    elseif tier == "Medium" then
        return 0.1092, 0.2244
    end
    return 0, 0
end

-- Three original motion signatures on one existing Trail, without geometry.
-- Separate entry/exit thresholds suppress sprint-speed jitter on Android.
function Rules.momentumBand(ratio, previous)
    if type(ratio) ~= "number" or ratio ~= ratio
        or math.abs(ratio) == math.huge or ratio < 0 then
        return "Flow"
    end
    if (previous == "Surge" and ratio >= 1.04) or ratio >= 1.12 then
        return "Surge"
    end
    if (previous == "Drive" and ratio >= 0.91) or ratio >= 0.97 then
        return "Drive"
    end
    return "Flow"
end

function Rules.momentumStyle(tier, band)
    local lifetime, width = Rules.style(tier)
    if lifetime <= 0 then
        return {Lifetime = 0, Width = 0, Peak = 0.28,
            Emission = 0, Opacity = 1}
    end
    local life, breadth, peak, emission, opacity
    if band == "Surge" then
        life, breadth, peak, emission, opacity = 1.07, 1.08, 0.38, 0.82, 0.48
    elseif band == "Drive" then
        life, breadth, peak, emission, opacity = 1, 1, 0.28, 0.74, 0.56
    else
        life, breadth, peak, emission, opacity = 0.90, 0.85, 0.19, 0.65, 0.64
    end
    return {Lifetime = lifetime * life, Width = width * breadth,
        Peak = peak, Emission = emission, Opacity = opacity}
end

-- A hard limit on simultaneously rendered remote human trails prevents
-- crowded rounds from multiplying translucent GPU overdraw.
function Rules.remoteBudget(tier)
    if tier == "High" then return 8 end
    if tier == "Medium" then return 4 end
    return 0
end

-- Reuse the caller's arrays/maps to avoid per-frame allocations.
-- Existing trails receive a small distance bias to prevent flicker
-- when two players trade places at the visibility cutoff.
function Rules.selectRemote(candidates, tier, selected)
    table.clear(selected)
    local budget = Rules.remoteBudget(tier)
    if budget == 0 then return selected end
    table.sort(candidates, function(a, b)
        local da = a.distance - ((a.trail and a.trail.Enabled) and 3 or 0)
        local db = b.distance - ((b.trail and b.trail.Enabled) and 3 or 0)
        if da == db then return a.order < b.order end
        return da < db
    end)
    for i = 1, math.min(budget, #candidates) do
        selected[candidates[i]] = true
    end
    return selected
end

return Rules
