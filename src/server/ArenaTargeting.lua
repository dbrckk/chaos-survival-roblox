local ArenaTargeting = {}

function ArenaTargeting.halfExtents(baseSize, padding, fallbackHalfExtent)
    local fallback = math.max(1, tonumber(fallbackHalfExtent) or 42)
    local margin = math.max(0, tonumber(padding) or 6)

    if typeof(baseSize) ~= "Vector3" then
        return fallback, fallback
    end

    local halfX = math.max(1, (baseSize.X * 0.5) - margin)
    local halfZ = math.max(1, (baseSize.Z * 0.5) - margin)
    return halfX, halfZ
end

function ArenaTargeting.activeHalfExtents(padding, fallbackHalfExtent)
    local generatedMap = workspace:FindFirstChild("GeneratedMap")
    local arena = generatedMap and generatedMap:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")

    return ArenaTargeting.halfExtents(
        base and base:IsA("BasePart") and base.Size or nil,
        padding,
        fallbackHalfExtent
    )
end

function ArenaTargeting.randomOffset(padding, fallbackHalfExtent)
    local halfX, halfZ = ArenaTargeting.activeHalfExtents(padding, fallbackHalfExtent)
    return Vector3.new(
        (math.random() * 2 - 1) * halfX,
        0,
        (math.random() * 2 - 1) * halfZ
    )
end

return ArenaTargeting
