--!strict
-- Deterministic non-physical landmark reactions to live disasters.
-- No additional objects, camera displacement or flashes. Designed to layer
-- onto arena-hero-motion's existing anchored cosmetic scene ownership.

local LandmarkDisasterReactionRules = {}

local EVENTS = {
    RisingLava = {Heat = 1, Pulse = 0.55, Shake = 0.15},
    Meteors = {Shake = 0.92, Pulse = 0.80},
    LowGravity = {Lift = 1, Drift = 0.80},
    DisappearingPlatforms = {Shake = 0.65, Pulse = 0.60},
    Tornado = {Wind = 1, Drift = 0.70},
    Freeze = {Frost = 1, Drift = 0.15},
    Bombs = {Shake = 1, Pulse = 0.76},
    SpeedSurge = {Wind = 0.70, Pulse = 0.88},
    Darkness = {Darkness = 1, Pulse = 0.32},
    ShrinkingArena = {Pulse = 0.95, Shake = 0.28},
    JumpShock = {Pulse = 1, Shake = 0.33},
}

local QUALITY = {Low = 0.18, Medium = 0.58, High = 1}

function LandmarkDisasterReactionRules.compose(ids, phase, tier, reduceMotion, finalRush, visualsOverride)
    local profile = {
        Active = false,
        Accent = Color3.fromRGB(140, 200, 255),
        Heat = 0, Shake = 0, Lift = 0, Wind = 0, Pulse = 0,
        Drift = 0, Frost = 0, Darkness = 0,
        Motion = reduceMotion == true and 0 or (QUALITY[tier] or QUALITY.Low),
        Tint = tier == "Low" and 0.16 or 0.25,
    }
    if phase ~= "round" or type(ids) ~= "table" then
        return profile
    end
    local visuals = visualsOverride or require(game:GetService("ReplicatedStorage").Shared.DisasterVisuals)
    local count = 0
    local accum = Vector3.zero
    for _, id in ipairs(ids) do
        local event = EVENTS[tostring(id)]
        local visual = visuals.get(tostring(id))
        if event and visual and count < 2 then
            count += 1
            profile.Active = true
            local c = visual.Accent
            accum += Vector3.new(c.R, c.G, c.B)
            for _, property in ipairs({
                "Heat", "Shake", "Lift", "Wind", "Pulse",
                "Drift", "Frost", "Darkness",
            }) do
                profile[property] = math.max(profile[property], event[property] or 0)
            end
        end
    end
    if count == 0 then return profile end
    profile.Accent = Color3.new(
        accum.X / count, accum.Y / count, accum.Z / count
    )
    -- Dangerous rounds intensify without exceeding animation limits.
    if finalRush == true then
        profile.Pulse = math.min(1, profile.Pulse * 1.14)
        profile.Shake = math.min(1, profile.Shake * 1.10)
    end
    if profile.Frost > 0.5 then
        profile.Motion *= 0.58
    end
    if reduceMotion == true then
        profile.Tint = 0.13
    end
    return profile
end

function LandmarkDisasterReactionRules.offset(role, index, time, context)
    if type(context) ~= "table" or context.Active ~= true then
        return Vector3.zero, 0, 0, 0
    end
    local t = tonumber(time) or 0
    local i = tonumber(index) or 1
    local motion = math.clamp(tonumber(context.Motion) or 0, 0, 1)
    local wave = math.sin(t * (2.3 + i * 0.13))
    local fast = math.sin(t * (7.5 + i * 0.18))
    local sway = (context.Wind or 0) * wave * 0.045
        + (context.Shake or 0) * fast * 0.018
    local lift = ((context.Lift or 0) * (0.5 + 0.5 * wave) * 0.33
        + (context.Heat or 0) * math.sin(t * 1.8 + i) * 0.07)
    local yaw = ((context.Drift or 0) * math.sin(t * 1.1 + i) * 0.02)
    local tint = math.clamp(
        (tonumber(context.Tint) or 0) * (
            0.52 + (context.Pulse or 0) * (0.28 + 0.18 * (0.5 + wave * 0.5))
                + (context.Darkness or 0) * 0.12
        ), 0, 0.27
    )
    local roleFactor = role == "reactorCore" and 1.1
        or (role == "cable" and 1.15
        or (role == "lift" and 0.8 or 0.65))
    return Vector3.new(sway * 2.0, lift, 0) * motion * roleFactor,
        sway * motion * roleFactor,
        yaw * motion * roleFactor,
        tint
end

return LandmarkDisasterReactionRules
