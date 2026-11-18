local RouteSignalGeometry = {}

-- Fit the longest source axis to the signal. A vertical inlay turns the
-- raised face toward the path, mirroring the profile on the other pylon.
function RouteSignalGeometry.fit(template, frame, size, inlaySide)
    if not template then return nil end
    local mesh = template:Clone()
    if not mesh then return nil end
    local longAxisX = mesh.Size.X > mesh.Size.Z
    if inlaySide then
        frame *= CFrame.Angles(0, 0, inlaySide * math.pi * 0.5)
        size = Vector3.new(size.Y, size.X, size.Z)
    end
    local rotate = longAxisX ~= (size.X > size.Z)
    mesh:ClearAllChildren()
    mesh.TextureID = ""
    mesh.MaterialVariant = ""
    mesh.Size = rotate and Vector3.new(size.Z, size.Y, size.X) or size
    mesh.CFrame = rotate and frame * CFrame.Angles(0, math.pi * 0.5, 0) or frame
    mesh.Anchored = true
    mesh.CanCollide = false
    mesh.CanTouch = false
    mesh.CanQuery = false
    mesh.CastShadow = false
    mesh:SetAttribute("RouteSignalHeightAxis", inlaySide and (longAxisX and "X" or "Z") or nil)
    return mesh
end

return RouteSignalGeometry
