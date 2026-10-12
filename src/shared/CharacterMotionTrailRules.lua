-- Cosmetic human momentum trail budget; never affects movement or damage.
-- Distances are in studs; tier caps prevent unnecessary GPU trail rendering.
local Rules = {}

local function finiteNonnegative(value)
    return type(value) == "number" and value == value
        and value >= 0 and value < math.huge
end

function Rules.visible(phase, finalRush, airborne, ratio, tier, reduceMotion, distance, wasVisible)
    if phase ~= "round" or finalRush == true or airborne == true
        or reduceMotion == true or (tier ~= "Medium" and tier ~= "High")
    then
        return false
    end
    -- Bad numeric telemetry must never enable a ribbon, even when retained.
    if not finiteNonnegative(ratio) or not finiteNonnegative(distance) then
        return false
    end
    -- Hysteresis avoids rapidly recreating translucent segments when
    -- velocity jitters near sprint speed or the camera crosses a cull edge.
    -- A previously visible ribbon may persist for 3 more studs, but never
    -- bypasses phase, airborne, Low, or ReduceMotion restrictions.
    local retained = wasVisible == true
    local limit = (tier == "High" and 90 or 60) + (retained and 3 or 0)
    local threshold = retained and 0.76 or 0.82
    return ratio > threshold and distance <= limit
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

-- Motion ribbons are absent outside active rounds, in final rush,
-- and in Low/ReduceMotion. Poll their already-registered rigs less often
-- while disabled; keep original Medium/High active animation cadence.
-- Use exact positive intervals; never introduce a per-frame connection.
function Rules.updateInterval(tier, phase, reduceMotion, finalRush)
    if phase ~= "round" or reduceMotion == true or finalRush == true
        or tier == "Low" then
        return 0.12
    end
    if tier == "High" then return 1 / 30 end
    if tier == "Medium" then return 1 / 24 end
    return 0.12
end

-- A hard limit on simultaneously rendered remote human trails prevents
-- crowded rounds from multiplying translucent GPU overdraw.
function Rules.remoteBudget(tier)
    if tier == "High" then return 8 end
    if tier == "Medium" then return 4 end
    return 0
end

-- Reuse the caller's arrays/maps to avoid per-frame allocations.
-- Only four Medium or eight High remote human ribbons may be visible:
-- select that small nearest set without sorting the full candidate list.
-- Retain a 3-stud bias for already-enabled trails to prevent flicker.
local function distanceScore(entry)
    if type(entry) ~= "table" or not finiteNonnegative(entry.distance) then
        return math.huge
    end
    return entry.distance - ((entry.trail and entry.trail.Enabled) and 3 or 0)
end

function Rules.selectRemote(candidates, tier, selected)
    table.clear(selected)
    local budget = Rules.remoteBudget(tier)
    if budget == 0 then return selected end

    -- In-place partial selection: at most 4/8 passes, no temporary tables
    -- and no need to order candidates that cannot receive a ribbon.
    for i = 1, math.min(budget, #candidates) do
        local bestIndex = i
        local bestScore = distanceScore(candidates[i])
        for j = i + 1, #candidates do
            local score = distanceScore(candidates[j])
            if score < bestScore
                or (score == bestScore and score ~= math.huge
                    and candidates[j].order < candidates[bestIndex].order) then
                bestIndex = j
                bestScore = score
            end
        end
        if bestScore == math.huge then break end
        candidates[i], candidates[bestIndex] = candidates[bestIndex], candidates[i]
        selected[candidates[i]] = true
    end
    return selected
end

return Rules
