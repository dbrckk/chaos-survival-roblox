local MovementSafety = {}

function MovementSafety.clampVelocity(velocity, horizontalMax, verticalMin, verticalMax)
    local vector = typeof(velocity) == "Vector3" and velocity or Vector3.zero
    local maxHorizontal = math.max(1, tonumber(horizontalMax) or 60)
    local minVertical = tonumber(verticalMin) or -60
    local maxVertical = tonumber(verticalMax) or 60

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
    local current = typeof(currentVelocity) == "Vector3" and currentVelocity or Vector3.zero
    local delta = typeof(impulse) == "Vector3" and impulse or Vector3.zero
    return MovementSafety.clampVelocity(
        current + delta,
        horizontalMax,
        verticalMin,
        verticalMax
    )
end

return MovementSafety
