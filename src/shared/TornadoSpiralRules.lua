--!strict
-- Deterministic tornado spiral silhouettes. Pure client-side geometry recipes:
-- server wind impulses, damage, arena navigation and roster remain unchanged.
local TornadoSpiralRules = {}

local COUNTS = {Low = 4, Medium = 8, High = 12}

local function finite(value)
    return type(value) == "number" and value == value
        and math.abs(value) < math.huge
end

function TornadoSpiralRules.count(tier, reducedMotion)
    local count = COUNTS[tostring(tier or "")] or 0
    if reducedMotion == true then
        return math.min(count, 4)
    end
    return count
end

-- Each ribbon extends between two heights on an expanding outer funnel.
-- Low graphics and ReduceMotion have stable, non-animated geometry.
function TornadoSpiralRules.segment(center, index, count, elapsed, reducedMotion)
    if typeof(center) ~= "Vector3"
        or not finite(center.X) or not finite(center.Y) or not finite(center.Z)
        or not finite(index) or index % 1 ~= 0
        or not finite(count) or count % 1 ~= 0 or count < 1 or count > 12
        or index < 1 or index > count then
        return nil
    end

    local time = finite(elapsed) and math.clamp(elapsed, 0, 1e7) or 0
    if reducedMotion == true then
        time = 0
    end
    local function point(fraction)
        local y = 1.6 + fraction * 14.6
        local radius = 3.5 + fraction * 6.3
        local phase = fraction * math.pi * 3.8 + 0.37
            + time * 1.55
        return center + Vector3.new(
            math.cos(phase) * radius,
            y,
            math.sin(phase) * radius
        )
    end

    local t0 = (index - 1) / count
    local t1 = index / count
    local startPosition = point(t0)
    local endPosition = point(t1)
    local midpoint = (startPosition + endPosition) * 0.5
    local span = (endPosition - startPosition).Magnitude
    local width = count <= 4 and 0.35 or (count <= 8 and 0.32 or 0.29)

    return {
        CFrame = CFrame.lookAt(midpoint, endPosition),
        Size = Vector3.new(width, 0.13, span),
        Color = index % 3 == 0 and Color3.fromRGB(156, 216, 222)
            or (index % 2 == 0 and Color3.fromRGB(91, 158, 177)
                or Color3.fromRGB(110, 176, 183)),
        Transparency = math.clamp(0.42 + t0 * 0.15, 0.40, 0.65),
    }
end

return TornadoSpiralRules
