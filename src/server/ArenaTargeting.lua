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


-- A new lethal circle must not silently pile onto another active warning.
-- Check only X/Z: warnings appear on the arena floor, and their projected
-- circular dodge corridors are what a player sees on a small screen.
-- Return the first adequately separated candidate, or the furthest one if
-- the shrinking arena has no room for the requested separation.
function ArenaTargeting.chooseSeparatedOffset(candidates, center, occupied, gap)
    local origin = typeof(center) == "Vector3" and center or Vector3.zero
    local minGap = math.max(0, tonumber(gap) or 0)
    local best = nil
    local bestDistance = -math.huge
    for _, offset in ipairs(candidates or {}) do
        if typeof(offset) == "Vector3" then
            local point = origin + offset
            local nearest = math.huge
            for _, position in ipairs(occupied or {}) do
                if typeof(position) == "Vector3" then
                    local dx = point.X - position.X
                    local dz = point.Z - position.Z
                    nearest = math.min(nearest, math.sqrt(dx * dx + dz * dz))
                end
            end
            if nearest >= minGap then
                return offset
            end
            if nearest > bestDistance then
                best = offset
                bestDistance = nearest
            end
        end
    end
    return best or Vector3.zero
end

-- The same per-round registry is shared by Bomb Rain and Meteor Shower,
-- including Double Chaos. Only pending warnings are counted, not impacts
-- that have already resolved. Stale destroyed markers are purged on access.
function ArenaTargeting.randomSeparatedOffset(padding, fallback, center, pending, gap)
    local occupied = {}
    for marker in pairs(pending or {}) do
        if typeof(marker) == "Instance" and marker:IsA("BasePart")
            and marker.Parent
        then
            occupied[#occupied + 1] = marker.Position
        else
            pending[marker] = nil
        end
    end
    if #occupied == 0 then
        return ArenaTargeting.randomOffset(padding, fallback)
    end
    -- Eight candidate samples is bounded work, independent of player count.
    local candidates = {}
    for _ = 1, 8 do
        candidates[#candidates + 1] = ArenaTargeting.randomOffset(padding, fallback)
    end
    return ArenaTargeting.chooseSeparatedOffset(
        candidates, center, occupied, gap
    )
end

return ArenaTargeting
