-- Fitted local art shared by the Harbor barges and quay fascia.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Armor = require(script.Parent.ApprovedPerimeterArmorMeshKit)
local Dock = require(script.Parent.ApprovedDistrictFoundationMeshKit)
local Bridge = require(script.Parent.ApprovedTowersSignatureBridgeMeshKit)

local Geometry = {}
local SOURCE_MODELS = {
    ApprovedHarborDockCaissonTemplates = "DockCaisson",
    ApprovedPerimeterArmorTemplates = "Cap",
    ApprovedTowersSignatureBridgeTemplates = "ForgedBridge",
    ApprovedFloorReliefTemplates = "Harbor",
}
local ROLLER_ID = 94830155055482

local function rollerProfile()
    local holder = ReplicatedStorage:FindFirstChild("ApprovedFloorReliefTemplates")
    if not holder or not holder:IsA("Folder") or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local model = holder:FindFirstChild("Harbor")
    if not model or not model:IsA("Model")
        or model:GetAttribute("OwnerVerified") ~= true or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("OriginalFloorRelief3D") ~= true
        or model:GetAttribute("Original3DAssetId") ~= ROLLER_ID then return nil end
    local region
    local expected = Vector3.new(2.50, .16, .16)
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("MeshPart") then
            local size = part.Size
            local bounds = Vector3.new(math.max(size.X, size.Z), size.Y, math.min(size.X, size.Z))
            if (bounds - expected).Magnitude < .075 then
                if region or not part.Archivable or part.MeshId == "" then return nil end
                region = part
            end
        end
    end
    return region
end

function Geometry.sources()
    local casting, rotation, swapXZ, castingId = Armor.slopedCapProfile()
    return {
        plate = {source = Dock.plinthProfile(), id = Dock.AssetId},
        beam = {source = Bridge.sweptProfile(), id = Bridge.AssetId},
        bow = {source = casting, id = castingId, rotation = rotation, swapXZ = swapXZ},
        roller = {source = rollerProfile(), id = ROLLER_ID},
    }
end

function Geometry.fit(profile, size, frame, alongX)
    local source = profile and profile.source
    if not source or not source.Archivable or source.MeshId == "" then return nil end
    local mesh = source:Clone()
    if not mesh then return nil end
    local turn = alongX ~= nil and (source.Size.X > source.Size.Z) ~= alongX
    if turn then frame *= CFrame.Angles(0, math.pi * .5, 0) end
    if profile.rotation then frame *= profile.rotation end
    if turn ~= (profile.swapXZ == true) then size = Vector3.new(size.Z, size.Y, size.X) end
    mesh:ClearAllChildren()
    mesh.TextureID = ""
    mesh.MaterialVariant = ""
    mesh.Size = size
    mesh.CFrame = frame
    mesh:SetAttribute("Original3DAssetId", profile.id)
    return mesh
end

-- Rebuild once when one of the four relevant templates is published or
-- removed. A different arena ignores these art-only events.
function Geometry.watch(onChanged)
    local function changed(item)
        local parent = item.Parent
        if parent and parent.Parent == ReplicatedStorage and item:IsA("Model")
            and SOURCE_MODELS[parent.Name] == item.Name then onChanged() end
    end
    ReplicatedStorage.DescendantAdded:Connect(changed)
    ReplicatedStorage.DescendantRemoving:Connect(changed)
end

return Geometry
