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

function DisasterAtmosphereLayout.beamFrame(baseFrame, baseSize, angle, radius, height)
    local position = DisasterAtmosphereLayout.point(
        baseFrame, baseSize, angle, radius, height * 0.5 + 4
    )
    if not position then return nil end
    return CFrame.fromMatrix(position,
        baseFrame.RightVector, baseFrame.UpVector, -baseFrame.LookVector)
end

function DisasterAtmosphereLayout.beaconCount(tier, active)
    if active ~= true then return 0 end
    if tier == "Low" then return 4 end
    if tier == "Medium" then return 6 end
    if tier == "High" then return 8 end
    return 0
end

return DisasterAtmosphereLayout
