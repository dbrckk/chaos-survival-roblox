--!strict
-- Client-only arena crisis geometry policy. No server authority, collision,
-- extra graphics loops or external assets. Pure recipe for engine coverage.
local DisasterMotionSceneRules = {}

local function finite(value)
    return type(value) == "number" and value == value
        and math.abs(value) ~= math.huge
end

function DisasterMotionSceneRules.pose(base, kind, index)
    if not base or not base:IsA("BasePart") or not base.Parent
        or (kind ~= "shrink" and kind ~= "blackout")
        or type(index) ~= "number" or index % 1 ~= 0
        or index < 1 or index > 4 then
        return nil
    end
    local size = base.Size
    if not finite(size.X) or not finite(size.Y) or not finite(size.Z)
        or size.X <= 0 or size.Y <= 0 or size.Z <= 0 then
        return nil
    end
    local halfX, halfZ = size.X * 0.5, size.Z * 0.5
    local point
    local extent
    if kind == "shrink" then
        local y = size.Y * 0.5 + 0.18
        if index == 1 then
            point = Vector3.new(0, y, -halfZ)
            extent = Vector3.new(size.X, 0.24, 0.5)
        elseif index == 2 then
            point = Vector3.new(0, y, halfZ)
            extent = Vector3.new(size.X, 0.24, 0.5)
        elseif index == 3 then
            point = Vector3.new(-halfX, y, 0)
            extent = Vector3.new(0.5, 0.24, size.Z)
        else
            point = Vector3.new(halfX, y, 0)
            extent = Vector3.new(0.5, 0.24, size.Z)
        end
    else
        local x = (index == 1 or index == 3) and -halfX + 4 or halfX - 4
        local z = index <= 2 and -halfZ + 4 or halfZ - 4
        point = Vector3.new(x, 2.2, z)
        extent = Vector3.new(0.55, 3.2, 0.55)
    end
    return base.CFrame * CFrame.new(point), extent
end

-- A current scene needs exactly four live owned parts on the same Base.
function DisasterMotionSceneRules.needsRebuild(previousBase, base, parts)
    if previousBase ~= base or not base or not base.Parent
        or type(parts) ~= "table" or #parts ~= 4 then
        return true
    end
    for i = 1, 4 do
        if not parts[i] or not parts[i].Parent then return true end
    end
    return false
end

-- Geometry changes rarely; pulsing brightness may change each tick.
function DisasterMotionSceneRules.geometryChanged(lastFrame, lastSize, base)
    return not base or not base.Parent
        or lastFrame ~= base.CFrame or lastSize ~= base.Size
end

-- Four separated guidance phases instead of all four beacons flashing
-- in synchrony. Low and ReduceMotion retain a static visible signal.
function DisasterMotionSceneRules.beaconPulse(now, index, tier, reduced)
    if type(index) ~= "number" or index % 1 ~= 0
        or index < 1 or index > 4
        or not finite(now) or now < 0 or now > 1e7 then
        return 0.5
    end
    if tier == "Low" or reduced == true then return 0.5 end
    return (1 + math.sin(now * 2.6 + (index - 1) * math.pi / 2)) * 0.5
end

return DisasterMotionSceneRules
