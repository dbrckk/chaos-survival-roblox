local RouteSignalGeometry = {}

-- Fit a horizontal light mesh by its long axis, allowing either Roblox
-- import orientation while leaving the route owner's footprint intact.
function RouteSignalGeometry.fit(template, frame, size)
    if not template then return nil end
    local mesh = template:Clone()
    if not mesh then return nil end
    local rotate = (mesh.Size.X > mesh.Size.Z) ~= (size.X > size.Z)
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
    return mesh
end

return RouteSignalGeometry
