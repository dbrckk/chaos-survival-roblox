-- Deterministic cosmetic reaction thresholds for nearby bot movement.
-- No physics, AI pathing, Humanoid, Motor6D or Animator changes.
local LocomotionDynamics = require(script.Parent.LocomotionDynamics)
local BotMotionPresentationRules = {}

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

function BotMotionPresentationRules.cue(velocity, previousVelocity, dt,
        grounded, tier, reducedMotion, phase, viewerDistance)
    local profile = BotMotionPresentationRules.profile(tier, reducedMotion)
    if profile.MaxPerScan == 0 or tostring(phase or "") ~= "round"
        or typeof(velocity) ~= "Vector3"
        or typeof(previousVelocity) ~= "Vector3"
        or grounded ~= true or type(dt) ~= "number" or dt <= 0
        or type(viewerDistance) ~= "number"
        or viewerDistance > profile.Range then
        return nil, 0
    end
    local now = Vector3.new(velocity.X, 0, velocity.Z)
    local before = Vector3.new(previousVelocity.X, 0, previousVelocity.Z)
    local speed = now.Magnitude
    local previousSpeed = before.Magnitude
    local launch, skid = LocomotionDynamics.acceleration(
        speed, previousSpeed, dt, true
    )
    local cut = LocomotionDynamics.cut(
        before, now, speed, true
    )
    local kind, strength = LocomotionDynamics.groundCue(
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
