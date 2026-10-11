-- PHASE DASH / shared server-authoritative movement contract.
-- The client sends only a request. Direction, health, state and cooldown
-- are derived/validated on the server, not trusted from client arguments.
local PhaseDashRules = {}

PhaseDashRules.Cooldown = 9
PhaseDashRules.HorizontalImpulse = 29
PhaseDashRules.MaxHorizontalSpeed = 44

local function finite(n)
    return type(n) == "number" and n == n and math.abs(n) < math.huge
end

local function safeVector(value)
    if typeof(value) ~= "Vector3" then return nil end
    -- Leave a wide safety margin above gameplay speeds and map dimensions,
    -- but never normalize or add nonfinite/excessive network/physics values.
    if not finite(value.X) or not finite(value.Y) or not finite(value.Z)
        or math.abs(value.X) > 1e7 or math.abs(value.Y) > 1e7
        or math.abs(value.Z) > 1e7 then
        return nil
    end
    return value
end

function PhaseDashRules.canActivate(phase, participant, eliminated, health, grounded, now, readyAt)
    local hp, clock, ready = tonumber(health), tonumber(now),
        tonumber(readyAt) or 0
    return phase == "round"
        and participant == true
        and eliminated ~= true
        and finite(hp) and hp > 0
        and grounded == true
        and finite(clock) and finite(ready) and clock >= ready
end

function PhaseDashRules.direction(moveDirection, facing)
    local input = safeVector(moveDirection) or Vector3.zero
    local flat = Vector3.new(input.X, 0, input.Z)
    if flat.Magnitude < 0.12 then
        local look = safeVector(facing) or Vector3.new(0, 0, -1)
        flat = Vector3.new(look.X, 0, look.Z)
    end
    if flat.Magnitude <= 0.001 then
        return Vector3.new(0, 0, -1)
    end
    return flat.Unit
end

function PhaseDashRules.velocity(current, moveDirection, facing)
    local vector = safeVector(current) or Vector3.zero
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
    local time = tonumber(now)
    if not finite(time) then time = 0 end
    return math.max(0, time) + PhaseDashRules.Cooldown
end

-- HUD-only helper. Never display NaN/Infinity as a cooldown, and do not
-- send an invalid value back to the authoritative server.
function PhaseDashRules.remaining(readyAt, now)
    local expires, current = tonumber(readyAt), tonumber(now)
    if not finite(expires) or not finite(current) then return 0 end
    return math.max(0, expires - current)
end

return PhaseDashRules
