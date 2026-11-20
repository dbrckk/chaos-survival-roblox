local RouteSignalGeometry = {}

-- Fit the longest source axis to the signal. A vertical inlay turns the
-- raised face toward the path, mirroring the profile on the other pylon.
function RouteSignalGeometry.fit(template, frame, size, inlaySide, alongX)
    if not template then return nil end
    local mesh = template:Clone()
    if not mesh then return nil end
    local longAxisX = mesh.Size.X > mesh.Size.Z
    if inlaySide then
        frame *= CFrame.Angles(0, 0, inlaySide * math.pi * 0.5)
        size = Vector3.new(size.Y, size.X, size.Z)
    end
    -- A nearly square deck can have a wider lip than its intended span.
    local targetAlongX = if alongX ~= nil then alongX else size.X > size.Z
    local rotate = longAxisX ~= targetAlongX
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

function RouteSignalGeometry.fitStructural(frame, size, keepAxes, ...)
    for index = 1, select("#", ...) do
        local source = select(index, ...)
        local template = source and source.part
        if template and template.MeshId ~= "" then
            local alongX
            if keepAxes then alongX = template.Size.X > template.Size.Z end
            local mesh = RouteSignalGeometry.fit(template, frame, size, nil, alongX)
            if mesh then
                mesh:SetAttribute("Original3DAssetId", source.assetId)
                return mesh
            end
        end
    end
    return nil
end

-- Imported models are split by material and can swap horizontal axes.
-- Match the unique region by its long, vertical and short dimensions.
function RouteSignalGeometry.regionByBounds(model, regionSize)
    local region
    for _, piece in ipairs(model:GetChildren()) do
        if not piece:IsA("MeshPart") then continue end
        local size = piece.Size
        local bounds = Vector3.new(math.max(size.X, size.Z), size.Y, math.min(size.X, size.Z))
        if (bounds - regionSize).Magnitude < 0.075 then
            if region or not piece.Archivable or piece.MeshId == "" then return nil end
            region = piece
        end
    end
    return region
end

function RouteSignalGeometry.approvedModel(holder, name, tag, assetId)
    if not holder or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local model = holder:FindFirstChild(name)
    if not model or not model:IsA("Model")
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute(tag) ~= true
        or model:GetAttribute("Original3DAssetId") ~= assetId then return nil end
    return model
end

return RouteSignalGeometry
