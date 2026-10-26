-- The server's 84-stud wind footprint is authoritative. Keep the
-- client-only amber escape contour locked to it even when veteran tornado
-- drift changes the center. No forces, damage or replication here.
local TornadoBoundaryRules = {}

local COUNTS = {Low = 8, Medium = 12, High = 16}

local function finite(n)
    return type(n) == "number" and n == n and math.abs(n) < math.huge
end

function TornadoBoundaryRules.profile(size, tier)
    if typeof(size) ~= "Vector3"
        or not finite(size.Y) or not finite(size.Z)
        or size.Y <= 0 or size.Z <= 0 then
        return nil
    end
    local count = COUNTS[tostring(tier or "")]
    if not count then return nil end
    -- The warning remains just INSIDE the force boundary, but no more than
    -- 0.6 studs away, including while the actual cyclone is drifting.
    local radius = math.max(0.5, math.min(size.Y, size.Z) * 0.5 - 0.6)
    return {
        Count = count,
        Radius = radius,
        Length = 2 * math.pi * radius / count * 0.66,
        Width = tier == "Low" and 0.22 or 0.18,
        Transparency = tier == "Low" and 0.30 or 0.43,
    }
end

function TornadoBoundaryRules.frame(center, index, profile)
    if typeof(center) ~= "Vector3" or type(profile) ~= "table"
        or not finite(center.X) or not finite(center.Y) or not finite(center.Z)
        or not finite(index) or index % 1 ~= 0
        or not finite(profile.Count) or profile.Count < 1
        or not finite(profile.Radius) or profile.Radius < 0.5
        or index < 1 or index > profile.Count then
        return nil
    end
    local angle = ((index - 0.5) / profile.Count) * math.pi * 2
    local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
    local tangent = Vector3.new(-radial.Z, 0, radial.X)
    return CFrame.fromMatrix(center + radial * profile.Radius, tangent, Vector3.yAxis)
end

return TornadoBoundaryRules
