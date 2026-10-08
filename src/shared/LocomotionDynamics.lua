--!strict
-- Small, deterministic pose envelopes for the existing R15 body-feel owner.
-- This module NEVER writes Motor6Ds, Humanoids or camera transforms.
local LocomotionDynamics = {}

function LocomotionDynamics.profile(tier, reduced)
    if reduced == true then
        return 0.10
    end
    if tier == "Low" then
        return 0.35
    elseif tier == "Medium" then
        return 0.70
    end
    return 1
end

-- Physically sampled speed change, including deceleration after input release.
-- This fixes the old brakeWeight gate that required MoveDirection > 0.
function LocomotionDynamics.acceleration(speed, previousSpeed, dt, grounded)
    if not grounded or type(dt) ~= "number" or dt <= 0 then
        return 0, 0
    end
    local current = math.max(0, tonumber(speed) or 0)
    local previous = math.max(0, tonumber(previousSpeed) or current)
    local acceleration = (current - previous) / math.max(dt, 1 / 120)
    local launch = math.clamp((acceleration - 24) / 125, 0, 1)
    local stop = math.max(current, previous) > 1.0
        and math.clamp((-acceleration - 18) / 115, 0, 1) or 0
    return launch, stop
end

-- A 180-degree reversal has almost no cross product. Preserve a readable
-- sign for that pivot without imparting movement or turning the root.
function LocomotionDynamics.cut(previousDirection, currentDirection, speed, grounded)
    if not grounded or typeof(previousDirection) ~= "Vector3"
        or typeof(currentDirection) ~= "Vector3"
    then
        return 0, 0
    end
    local before = Vector3.new(previousDirection.X, 0, previousDirection.Z)
    local after = Vector3.new(currentDirection.X, 0, currentDirection.Z)
    if before.Magnitude < 0.1 or after.Magnitude < 0.1 then
        return 0, 0
    end

    local first = before.Unit
    local second = after.Unit
    local dot = math.clamp(first:Dot(second), -1, 1)
    local severity = math.clamp((1 - dot) * 0.5, 0, 1)
    local speedWeight = math.clamp((tonumber(speed) or 0) / 17, 0, 1)
    local amount = severity * speedWeight
    if amount < 0.025 then
        return 0, 0
    end

    local direction = first:Cross(second).Y
    if math.abs(direction) < 0.04 and severity > 0.88 then
        direction = first.X + first.Z >= 0 and 1 or -1
    end
    return (direction < 0 and -1 or 1) * amount, amount
end

function LocomotionDynamics.footPlant(strideClock, strideWeight, grounded)
    if not grounded then
        return 0
    end
    local weight = math.clamp(tonumber(strideWeight) or 0, 0, 1)
    local phase = tonumber(strideClock) or 0
    -- Two foot contacts per stride cycle, softened to avoid camera-like bob.
    return math.clamp((0.5 + 0.5 * math.cos(phase * 2)) * weight, 0, 1)
end

function LocomotionDynamics.flight(verticalVelocity, grounded, lowGravity)
    if grounded then
        return 0, 0
    end
    local velocity = tonumber(verticalVelocity) or 0
    local scale = lowGravity == true and 0.55 or 1
    return math.clamp((velocity - 5) / 40, 0, 1) * scale,
        math.clamp((-velocity - 7) / 35, 0, 1) * scale
end

return LocomotionDynamics
