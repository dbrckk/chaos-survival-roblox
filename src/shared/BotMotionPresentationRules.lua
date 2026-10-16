-- Deterministic cosmetic reaction thresholds for nearby bot movement.
-- No physics, AI pathing, Humanoid, Motor6D or Animator changes.
local BotMotionPresentationRules = {}

local function finite(value)
    return type(value) == "number" and value == value
        and math.abs(value) ~= math.huge
end

local function finiteVector(value)
    return typeof(value) == "Vector3"
        and finite(value.X) and finite(value.Y) and finite(value.Z)
end

local PROFILES = {
    Low = {Range = 0, Cooldown = math.huge, MaxPerScan = 0},
    Medium = {Range = 54, Cooldown = 1.65, MaxPerScan = 1},
    High = {Range = 78, Cooldown = 1.35, MaxPerScan = 1},
}

function BotMotionPresentationRules.profile(tier, reducedMotion)
    if reducedMotion == true then
        return PROFILES.Low
    end
    return PROFILES[tostring(tier or "")] or PROFILES.Low
end

-- A short color cue ties an existing AI trail to its nearby footwork.
-- This is returned as a presentation color only; no extra Trail is created.
local ACCENTS = {
    Launch = Color3.fromRGB(83, 222, 255),
    Skid = Color3.fromRGB(255, 156, 83),
    Pivot = Color3.fromRGB(187, 105, 255),
}
function BotMotionPresentationRules.trailAccent(cueKind)
    return ACCENTS[cueKind]
end

-- Three distinct brief, sculpted Trail silhouettes on the existing bot
-- Trail. These are static cached recipes: zero tables allocated per scan.
-- A Launch draws out a slim jet, Skid spreads as a short friction fan,
-- and Pivot banks into a tighter side-curved ribbon.
local GESTURES = {
    High = {
        Launch = {Width = 0.21, Peak = 0.22, Emission = 0.75,
            DurationScale = 1.08},
        Skid = {Width = 0.32, Peak = 0.48, Emission = 0.62,
            DurationScale = 0.74},
        Pivot = {Width = 0.26, Peak = 0.36, Emission = 0.70,
            DurationScale = 0.88},
    },
    Medium = {
        Launch = {Width = 0.145, Peak = 0.22, Emission = 0.52,
            DurationScale = 1.02},
        Skid = {Width = 0.22, Peak = 0.48, Emission = 0.42,
            DurationScale = 0.74},
        Pivot = {Width = 0.18, Peak = 0.36, Emission = 0.48,
            DurationScale = 0.88},
    },
}
function BotMotionPresentationRules.trailGesture(tier, kind)
    local byTier = GESTURES[tier]
    return byTier and byTier[kind] or nil
end

-- Keep an existing AI Trail only when it can materially improve the
-- viewer's scene. Enter/exit hysteresis avoids flickering at the boundary.
-- No newly-instantiated trails, and no need to know the total bot count.
function BotMotionPresentationRules.trailVisible(
        tier, reducedMotion, phase, grounded, runRatio, viewerDistance, wasVisible)
    if phase ~= "round" or reducedMotion == true or grounded ~= true
        or (tier ~= "High" and tier ~= "Medium")
        or not finite(viewerDistance) or viewerDistance < 0
        or not finite(runRatio) or runRatio <= 0.68 then
        return false
    end
    local entering = tier == "High" and 95 or 66
    local leaving = entering + 12
    return viewerDistance <= (wasVisible == true and leaving or entering)
end

function BotMotionPresentationRules.cue(velocity, previousVelocity, dt,
        grounded, tier, reducedMotion, phase, viewerDistance, dynamicsOverride)
    local profile = BotMotionPresentationRules.profile(tier, reducedMotion)
    if profile.MaxPerScan == 0 or tostring(phase or "") ~= "round"
        or not finiteVector(velocity) or not finiteVector(previousVelocity)
        or grounded ~= true or not finite(dt) or dt <= 0
        or not finite(viewerDistance) or viewerDistance < 0
        or viewerDistance > profile.Range then
        return nil, 0
    end
    local dynamics = dynamicsOverride or require(game:GetService("ReplicatedStorage").Shared.LocomotionDynamics)
    local now = Vector3.new(velocity.X, 0, velocity.Z)
    local before = Vector3.new(previousVelocity.X, 0, previousVelocity.Z)
    local speed = now.Magnitude
    local previousSpeed = before.Magnitude
    local launch, skid = dynamics.acceleration(
        speed, previousSpeed, dt, true
    )
    local cut = dynamics.cut(
        before, now, speed, true
    )
    local kind, strength = dynamics.groundCue(
        launch, skid, cut, tier, reducedMotion, phase
    )
    -- Bot pathfinding often makes tiny velocity corrections; only expose
    -- deliberate, legible movement silhouettes, not jitter.
    if kind == "Launch" and speed < 7 then
        return nil, 0
    elseif kind == "Skid" and previousSpeed < 8 then
        return nil, 0
    elseif kind == "Pivot" and speed < 9 then
        return nil, 0
    end
    if strength < 0.78 then
        return nil, 0
    end
    return kind, strength
end

return BotMotionPresentationRules
