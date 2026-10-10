-- Deterministic aerial-survey patrol routes, separate from physical gameplay.
-- The small, tiered cosmetic fleet never grants collision or gameplay credit.
local AerialSurveyRules = {}

AerialSurveyRules.Profiles = {
    Low = {Drones = 1, PartsPerDrone = 6, MaxParts = 6, Interval = 0.60},
    Medium = {Drones = 2, PartsPerDrone = 11, MaxParts = 22, Interval = 0.22},
    High = {Drones = 3, PartsPerDrone = 17, MaxParts = 51, Interval = 0.10},
}

function AerialSurveyRules.profile(tier)
    return AerialSurveyRules.Profiles[tier] or AerialSurveyRules.Profiles.Medium
end

local SILHOUETTES = {
    Classic = {
        Body = Vector3.new(2.6, 1.05, 4.4),
        Wing = Vector3.new(3.9, 0.24, 2.35),
        WingYaw = 10, Cockpit = Vector3.new(1.85, 0.63, 2.2),
    },
    Towers = {
        Body = Vector3.new(3.25, 1.40, 3.55),
        Wing = Vector3.new(2.75, 0.39, 2.75),
        WingYaw = -15, Cockpit = Vector3.new(2.15, 0.70, 1.8),
    },
    Crossroads = {
        Body = Vector3.new(2.35, 0.93, 5.15),
        Wing = Vector3.new(4.75, 0.18, 2.05),
        WingYaw = 8, Cockpit = Vector3.new(1.66, 0.56, 2.55),
    },
    Orbital = {
        Body = Vector3.new(1.95, 0.86, 5.6),
        Wing = Vector3.new(5.2, 0.16, 1.95),
        WingYaw = 23, Cockpit = Vector3.new(1.44, 0.45, 2.9),
    },
}

function AerialSurveyRules.silhouette(variant)
    return SILHOUETTES[variant] or SILHOUETTES.Classic
end

-- Physical disasters have no effect on these non-colliding actors, but
-- their animation language is distinct: evade meteors, bank in storms,
-- rise above lava, float in low gravity, idle slowly during a freeze.
function AerialSurveyRules.behavior(ids)
    local state = {Speed = 1, Climb = 0, Bank = 1, Sway = 0}
    if type(ids) ~= "table" then return state end
    for _, id in ipairs(ids) do
        if id == "RisingLava" then
            state.Climb = math.max(state.Climb, 7)
        elseif id == "Tornado" then
            state.Bank = math.max(state.Bank, 2.6)
            state.Sway = math.max(state.Sway, 1.3)
        elseif id == "Meteors" or id == "Bombs" then
            state.Sway = math.max(state.Sway, 1.7)
            state.Speed = math.max(state.Speed, 1.22)
        elseif id == "LowGravity" then
            state.Climb = math.max(state.Climb, 4)
            state.Speed = math.min(state.Speed, 0.68)
        elseif id == "Freeze" then
            state.Speed = math.min(state.Speed, 0.45)
        elseif id == "SpeedSurge" then
            state.Speed = math.max(state.Speed, 1.4)
        end
    end
    return state
end

function AerialSurveyRules.animated(phase, tier, reduceMotion)
    return (phase == "ready" or phase == "round")
        and reduceMotion ~= true and tier ~= "Low"
end

-- Integrate the real wall-clock delta once, instead of multiplying absolute
-- uptime by a changing disaster speed (which teleported the fleet).
-- Reset the sample when motion is paused or a clock moves backwards; cap
-- long frame stalls to avoid a catch-up leap on slow Android devices.
function AerialSurveyRules.advanceClock(elapsed, lastNow, now, active, speed)
    local progress = tonumber(elapsed) or 0
    local tick = tonumber(now)
    if not active or not tick or tick ~= tick or tick == math.huge
        or tick == -math.huge
    then
        return progress, nil
    end
    local previous = tonumber(lastNow)
    if not previous or previous ~= previous or tick < previous then
        return progress, tick
    end
    local multiplier = math.clamp(tonumber(speed) or 1, 0.25, 1.5)
    return progress + math.min(tick - previous, 0.30) * multiplier, tick
end

function AerialSurveyRules.flightFrame(base, variant, index, count, t, behavior)
    if not base or not base:IsA("BasePart") then return nil end
    local drones = math.max(1, math.floor(tonumber(count) or 1))
    local slot = math.clamp(math.floor(tonumber(index) or 1), 1, drones)
    local reaction = type(behavior) == "table" and behavior or {}
    local time = (tonumber(t) or 0) * (tonumber(reaction.Speed) or 1)
    local phase = ((slot - 1) / drones) * math.pi * 2
    local speed = variant == "Orbital" and 0.23
        or (variant == "Towers" and 0.13 or 0.17)
    local angle = phase + time * speed
    local halfX = base.Size.X * 0.5
    local halfZ = base.Size.Z * 0.5
    local rx = halfX + 44
    local rz = halfZ + 44
    -- An unscaled ellipse can cut through the corners of wide arenas.
    -- Keep the entire patrol outside the deck plus a small sway allowance.
    local clearance = 12
    local coverage = math.sqrt(((halfX + clearance) / rx) ^ 2
        + ((halfZ + clearance) / rz) ^ 2)
    local orbitScale = math.max(1, coverage)
    rx *= orbitScale
    rz *= orbitScale
    local elevation = variant == "Towers" and 41
        or (variant == "Orbital" and 36
            or (variant == "Crossroads" and 30 or 32))
    local sway = (tonumber(reaction.Sway) or 0)
        * math.sin(time * 3.6 + slot * 1.7)
    local offset = Vector3.new(
        math.cos(angle) * rx + sway,
        elevation + (tonumber(reaction.Climb) or 0)
            + math.sin(time * 0.8 + slot) * math.min(2.5, time * 0.45),
        math.sin(angle) * rz + sway * 0.5
    )
    -- Fly outside the arena; there is never an apparent landing platform
    -- nor a moving collider over traversable decks.
    local direction = Vector3.new(
        -math.sin(angle) * rx, 0, math.cos(angle) * rz
    ).Unit
    local position = base.CFrame:PointToWorldSpace(offset)
    local bank = math.sin(angle * 1.4)
        * math.rad(7) * (tonumber(reaction.Bank) or 1)
    return CFrame.lookAt(position, position + direction)
        * CFrame.Angles(0, 0, bank)
end

function AerialSurveyRules.alert(phase, disasterIds, finalRush)
    if phase ~= "round" then return "standby" end
    if finalRush == true then return "critical" end
    if type(disasterIds) == "table" and #disasterIds > 0 then
        return "hazard"
    end
    return "patrol"
end

return AerialSurveyRules
