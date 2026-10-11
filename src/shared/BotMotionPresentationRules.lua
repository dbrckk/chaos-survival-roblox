-- Deterministic cosmetic reaction thresholds for nearby bot movement.
-- No physics, AI pathing, Humanoid, Motor6D or Animator changes.
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

-- Keep an existing AI Trail only when it can materially improve the
-- viewer's scene. Enter/exit hysteresis avoids flickering at the boundary.
-- No newly-instantiated trails, and no need to know the total bot count.
function BotMotionPresentationRules.trailVisible(
        tier, reducedMotion, phase, grounded, runRatio, viewerDistance, wasVisible)
    if phase ~= "round" or reducedMotion == true or grounded ~= true
        or (tier ~= "High" and tier ~= "Medium")
        or type(viewerDistance) ~= "number"
        or viewerDistance < 0 or (tonumber(runRatio) or 0) <= 0.68 then
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
        or typeof(velocity) ~= "Vector3"
        or typeof(previousVelocity) ~= "Vector3"
        or grounded ~= true or type(dt) ~= "number" or dt <= 0
        or type(viewerDistance) ~= "number"
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
