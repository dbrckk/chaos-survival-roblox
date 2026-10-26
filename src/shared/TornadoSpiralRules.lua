--!strict
-- Deterministic tornado spiral silhouettes. Pure client-side geometry recipes:
-- server wind impulses, damage, arena navigation and roster remain unchanged.
local TornadoSpiralRules = {}

-- Two intertwined arms give the funnel a distinct silhouette. Each arm
-- remains short and inexpensive: 3/6/9 segments per arm.
local COUNTS = {Low = 6, Medium = 12, High = 18}

local function finite(value)
    return type(value) == "number" and value == value
        and math.abs(value) < math.huge
end

function TornadoSpiralRules.count(tier, reducedMotion)
    local count = COUNTS[tostring(tier or "")] or 0
    if reducedMotion == true then
        return math.min(count, 6)
    end
    return count
end

-- Each ribbon extends between two heights on an expanding outer funnel.
-- Low graphics and ReduceMotion have stable, non-animated geometry.
function TornadoSpiralRules.segment(center, index, count, elapsed, reducedMotion)
    if typeof(center) ~= "Vector3"
        or not finite(center.X) or not finite(center.Y) or not finite(center.Z)
        or not finite(index) or index % 1 ~= 0
        or not finite(count) or count % 1 ~= 0 or count < 2 or count > 18
        or count % 2 ~= 0
        or index < 1 or index > count then
        return nil
    end

    local time = finite(elapsed) and math.clamp(elapsed, 0, 1e7) or 0
    if reducedMotion == true then
        time = 0
    end
    -- Indexes alternate between the near and far helical arms. A full
    -- vertical sweep is rendered by each half of the allocated segments.
    local perArm = count / 2
    local arm = (index - 1) % 2
    local step = math.floor((index - 1) / 2)
    local function point(fraction)
        local y = 1.6 + fraction * 14.6
        local radius = 3.5 + fraction * 6.3
        local phase = fraction * math.pi * 3.8 + 0.37
            + arm * math.pi + time * (arm == 0 and 1.55 or 1.35)
        return center + Vector3.new(
            math.cos(phase) * radius,
            y,
            math.sin(phase) * radius
        )
    end

    local t0 = step / perArm
    local t1 = (step + 1) / perArm
    local startPosition = point(t0)
    local endPosition = point(t1)
    local midpoint = (startPosition + endPosition) * 0.5
    local span = (endPosition - startPosition).Magnitude
    local width = count <= 6 and 0.37 or (count <= 12 and 0.32 or 0.28)

    return {
        CFrame = CFrame.lookAt(midpoint, endPosition),
        Size = Vector3.new(width, 0.13, span),
        Color = arm == 0 and Color3.fromRGB(153, 213, 222)
            or Color3.fromRGB(78, 145, 165),
        Transparency = math.clamp(0.43 + t0 * 0.15 + arm * 0.07, 0.40, 0.70),
    }
end

return TornadoSpiralRules
