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

-- Only remote players use camera projection. A padded viewport prevents
-- translucent ribbons from consuming GPU fill when their owner is off-screen.
-- Fail open while the camera is initializing; distance/tier caps still apply.
-- Retained ribbons get a slightly wider border to avoid camera-turn popping.
-- This is a frustum test, not an expensive wall-occlusion raycast.
function Rules.inViewport(x, y, depth, width, height, wasVisible)
    local w, h = tonumber(width), tonumber(height)
    if not w or not h or w <= 0 or h <= 0 then return true end
    local px, py, z = tonumber(x), tonumber(y), tonumber(depth)
    if not px or not py or not z or z <= 0 then return false end
    local margin = wasVisible == true and 0.18 or 0.10
    return px >= -w * margin and px <= w * (1 + margin)
        and py >= -h * margin and py <= h * (1 + margin)
end

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
