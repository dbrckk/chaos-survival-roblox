-- Pure, bounded rules for the local descent reticle. The reticle is an
-- estimate, never an authoritative prediction of hazards or collision.
local JumpLandingPreviewRules = {}

local function finite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

JumpLandingPreviewRules.SampleSeconds = 0.10
JumpLandingPreviewRules.MaxPredictionSeconds = 0.42
JumpLandingPreviewRules.MaxDrop = 13

function JumpLandingPreviewRules.eligible(
    phase, participant, eliminated, health, humanoidState, grounded, verticalSpeed
)
    return phase == "round" and participant == true
        and eliminated ~= true
        and finite(health) and health > 0
        and humanoidState == Enum.HumanoidStateType.Freefall
        and grounded == false
        and finite(verticalSpeed) and verticalSpeed < -3
end

function JumpLandingPreviewRules.timeToSurface(verticalSpeed, gravity, drop)
    if not finite(verticalSpeed) or not finite(gravity)
        or not finite(drop) or gravity <= 0 or drop < 0
        or drop > JumpLandingPreviewRules.MaxDrop
        or verticalSpeed >= -3
    then
        return nil
    end
    -- Positive root of drop = -verticalSpeed * t + gravity * t^2 / 2.
    -- Horizontal velocity is sampled locally; a distant airborne player
    -- does not get an unreliable or misleading long-horizon path.
    local discriminant = verticalSpeed * verticalSpeed + 2 * gravity * drop
    local t = (verticalSpeed + math.sqrt(discriminant)) / gravity
    if t < 0 or t > JumpLandingPreviewRules.MaxPredictionSeconds then
        return nil
    end
    return t
end

function JumpLandingPreviewRules.edgeMargin(platform, hitPosition)
    if typeof(platform) ~= "Instance" or not platform:IsA("BasePart")
        or typeof(hitPosition) ~= "Vector3" then
        return nil
    end
    local localPoint = platform.CFrame:PointToObjectSpace(hitPosition)
    local x = platform.Size.X * 0.5 - math.abs(localPoint.X)
    local z = platform.Size.Z * 0.5 - math.abs(localPoint.Z)
    return math.min(x, z)
end

return JumpLandingPreviewRules
