-- PHASE DASH / shared server-authoritative movement contract.
-- The client sends only a request. Direction, health, state and cooldown
-- are derived/validated on the server, not trusted from client arguments.
local PhaseDashRules = {}

PhaseDashRules.Cooldown = 9
PhaseDashRules.HorizontalImpulse = 29
PhaseDashRules.MaxHorizontalSpeed = 44

function PhaseDashRules.canActivate(phase, participant, eliminated, health, grounded, now, readyAt)
    return phase == "round"
        and participant == true
        and eliminated ~= true
        and (tonumber(health) or 0) > 0
        and grounded == true
        and (tonumber(now) or 0) >= (tonumber(readyAt) or 0)
end

function PhaseDashRules.direction(moveDirection, facing)
    local input = typeof(moveDirection) == "Vector3" and moveDirection or Vector3.zero
    local flat = Vector3.new(input.X, 0, input.Z)
    if flat.Magnitude < 0.12 then
        local look = typeof(facing) == "Vector3" and facing or Vector3.new(0, 0, -1)
        flat = Vector3.new(look.X, 0, look.Z)
    end
    if flat.Magnitude <= 0.001 then
        return Vector3.new(0, 0, -1)
    end
    return flat.Unit
end

function PhaseDashRules.velocity(current, moveDirection, facing)
    local vector = typeof(current) == "Vector3" and current or Vector3.zero
    local aim = PhaseDashRules.direction(moveDirection, facing)
    local vx = Vector3.new(vector.X, 0, vector.Z) + aim * PhaseDashRules.HorizontalImpulse
    if vx.Magnitude > PhaseDashRules.MaxHorizontalSpeed then
        vx = vx.Unit * PhaseDashRules.MaxHorizontalSpeed
    end
    -- Slight lift is visual/kinetic feedback, not an aerial second jump.
    local y = math.clamp(math.max(vector.Y, 2.5), -52, 48)
    return Vector3.new(vx.X, y, vx.Z)
end

function PhaseDashRules.nextReadyAt(now)
    return math.max(0, tonumber(now) or 0) + PhaseDashRules.Cooldown
end

return PhaseDashRules
