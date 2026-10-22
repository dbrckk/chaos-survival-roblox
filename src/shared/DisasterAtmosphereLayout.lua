-- Pure transform/layout rules for client-only event atmosphere.
-- Every position is authored in the arena's local deck coordinates.
local DisasterAtmosphereLayout = {}

function DisasterAtmosphereLayout.point(baseFrame, baseSize, angle, radius, height)
    if typeof(baseFrame) ~= "CFrame" or typeof(baseSize) ~= "Vector3"
        or type(angle) ~= "number" or type(radius) ~= "number"
        or type(height) ~= "number" then
        return nil
    end
    local localHeight = baseSize.Y * 0.5 + height
    return baseFrame:PointToWorldSpace(Vector3.new(
        math.cos(angle) * radius, localHeight, math.sin(angle) * radius
    ))
end

-- These authored perimeter accents must follow the *current* collision
-- footprint. ShrinkingArena changes Base.Size continuously during a round.
-- A static radius causes visible beacons and shafts to float outside the
-- playable floor once Double Chaos contracts the arena.
function DisasterAtmosphereLayout.perimeterRadius(baseSize, multiple)
    if typeof(baseSize) ~= "Vector3" then return nil end
    local factor = multiple == nil and 0.52 or multiple
    if type(factor) ~= "number" or factor <= 0
        or factor ~= factor or factor == math.huge then
        return nil
    end
    return math.max(baseSize.X, baseSize.Z) * factor
end

function DisasterAtmosphereLayout.beaconFrame(baseFrame, baseSize, angle)
    local radius = DisasterAtmosphereLayout.perimeterRadius(baseSize)
    if not radius then return nil end
    local position = DisasterAtmosphereLayout.point(
        baseFrame, baseSize, angle, radius, 0.8
    )
    if not position then return nil end
    return CFrame.fromMatrix(
        position, baseFrame.RightVector, baseFrame.UpVector,
        -baseFrame.LookVector
    )
end

function DisasterAtmosphereLayout.orbitalCoreFrame(baseFrame)
    if typeof(baseFrame) ~= "CFrame" then return nil end
    -- Keep the reactor aura aligned to the deck normal when tilted.
    return baseFrame * CFrame.new(0, 13, 0)
end

function DisasterAtmosphereLayout.beamFrame(baseFrame, baseSize, angle, radius, height)
    local position = DisasterAtmosphereLayout.point(
        baseFrame, baseSize, angle, radius, height * 0.5 + 4
    )
    if not position then return nil end
    return CFrame.fromMatrix(position,
        baseFrame.RightVector, baseFrame.UpVector, -baseFrame.LookVector)
end

-- No GPU objects exist in the lobby or between catastrophe phases.
-- Dormant polling is deliberately slower, while active High/Medium/Low
-- retains the original exact per-tier animation cadence.
function DisasterAtmosphereLayout.updateCadence(active, interval)
    if active ~= true then return 0.50 end
    if type(interval) == "number" and interval > 0
        and interval == interval and interval < math.huge then
        return interval
    end
    return 1 / 30
end

-- Scenery LOD owns visibility on weaker devices. Its hidden attributes
-- are authoritative for the local cosmetic scene; physics and server
-- telegraphs never call this function.
function DisasterAtmosphereLayout.shouldAnimate(part)
    return typeof(part) == "Instance" and part:IsA("BasePart")
        and part.Parent ~= nil
        and part:GetAttribute("SceneryLodHidden") ~= true
end

function DisasterAtmosphereLayout.beaconCount(tier, active)
    if active ~= true then return 0 end
    if tier == "Low" then return 4 end
    if tier == "Medium" then return 6 end
    if tier == "High" then return 8 end
    return 0
end

return DisasterAtmosphereLayout
