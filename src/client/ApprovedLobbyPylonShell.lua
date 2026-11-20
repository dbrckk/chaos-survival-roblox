local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
Kit.AssetId = 75945454705246 -- Approved source #41825253849

function Kit.approved()
    local holder = ReplicatedStorage:FindFirstChild("ApprovedLobbyPylonShellTemplates")
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local model = holder:FindFirstChild("LobbyPylonShell")
    if not model or not model:IsA("Model") or model.Parent ~= holder
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("OriginalLobbyPylonShell3D") ~= true
        or model:GetAttribute("EnclosesCollider") ~= true
        or model:GetAttribute("Original3DAssetId") ~= Kit.AssetId then
        return nil
    end
    local count = 0
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or item.MeshId == "" then return nil end
            count += 1
        elseif item:IsA("LuaSourceContainer") then return nil end
    end
    if count < 1 or count > 12 then return nil end
    local _, size = model:GetBoundingBox()
    if size.Y < 10.25 or size.Y > 10.75
        or math.min(size.X, size.Z) < 3.40
        or math.max(size.X, size.Z) > 4.05 then return nil end
    return model, count, size
end

function Kit.bodyProfile()
    local model = Kit.approved()
    if not model then return nil end
    -- The ARMOR region is the closed octagonal core. Its square footprint
    -- remains identifiable if the importer swaps X and Z.
    local expected = Vector3.new(2.84, 10.36, 2.84)
    local profile
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("MeshPart") and (part.Size - expected).Magnitude < 0.075 then
            if profile or not part.Archivable then return nil end
            profile = part
        end
    end
    return profile
end

return Kit
