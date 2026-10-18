local MovementSafety = {}

-- Physics and client-owned assemblies can occasionally report invalid or
-- extreme velocity components. Never propagate NaN/Infinity to a rig during
-- server-authoritative hazard knockback.
local COMPONENT_LIMIT = 10000

local function finiteNumber(value, fallback)
    local n = tonumber(value)
    if not n or n ~= n or n == math.huge or n == -math.huge then
        return fallback
    end
    return n
end

local function safeVector(value)
    if typeof(value) ~= "Vector3" then
        return Vector3.zero
    end
    return Vector3.new(
        math.clamp(finiteNumber(value.X, 0), -COMPONENT_LIMIT, COMPONENT_LIMIT),
        math.clamp(finiteNumber(value.Y, 0), -COMPONENT_LIMIT, COMPONENT_LIMIT),
        math.clamp(finiteNumber(value.Z, 0), -COMPONENT_LIMIT, COMPONENT_LIMIT)
    )
end

function MovementSafety.clampVelocity(velocity, horizontalMax, verticalMin, verticalMax)
    local vector = safeVector(velocity)
    local maxHorizontal = math.clamp(finiteNumber(horizontalMax, 60), 1, COMPONENT_LIMIT)
    local minVertical = math.clamp(
        finiteNumber(verticalMin, -60), -COMPONENT_LIMIT, COMPONENT_LIMIT
    )
    local maxVertical = math.clamp(
        finiteNumber(verticalMax, 60), -COMPONENT_LIMIT, COMPONENT_LIMIT
    )

    if minVertical > maxVertical then
        minVertical, maxVertical = maxVertical, minVertical
    end

    local horizontal = Vector3.new(vector.X, 0, vector.Z)
    if horizontal.Magnitude > maxHorizontal then
        horizontal = horizontal.Unit * maxHorizontal
    end

    return Vector3.new(
        horizontal.X,
        math.clamp(vector.Y, minVertical, maxVertical),
        horizontal.Z
    )
end

function MovementSafety.addImpulse(currentVelocity, impulse, horizontalMax, verticalMin, verticalMax)
    -- Sanitize before addition as well as before clamping: +inf + -inf
    -- must not turn a recovered avatar into permanent NaN motion.
    local current = safeVector(currentVelocity)
    local delta = safeVector(impulse)
    return MovementSafety.clampVelocity(
        current + delta,
        horizontalMax,
        verticalMin,
        verticalMax
    )
end

return MovementSafety
