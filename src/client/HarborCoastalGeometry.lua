-- Fitted local art shared by the Harbor barges and quay fascia.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Armor = require(script.Parent.ApprovedPerimeterArmorMeshKit)
local Dock = require(script.Parent.ApprovedDistrictFoundationMeshKit)
local Bridge = require(script.Parent.ApprovedTowersSignatureBridgeMeshKit)
local PlatformFinishKit = require(script.Parent.PlatformFinishKit)

local Geometry = {}
local SOURCE_MODELS = {
    ApprovedHarborDockCaissonTemplates = "DockCaisson",
    ApprovedPerimeterArmorTemplates = "Cap",
    ApprovedTowersSignatureBridgeTemplates = "ForgedBridge",
}
function Geometry.sources()
    local relief = PlatformFinishKit.artProfiles("Harbor", false)
    local closed = {source = relief.hatch, id = relief.hatchAssetId or relief.assetId}
    local plinth = Dock.plinthProfile()
    local swept = Bridge.sweptProfile()
    local casting, rotation, swapXZ, castingId = Armor.slopedCapProfile()
    return {
        -- These bodies keep their original frame so the complete barge can
        -- take over from the same hull anchor even with a relief casting.
        plate = if plinth then {source = plinth, id = Dock.AssetId} else closed,
        beam = if swept then {source = swept, id = Bridge.AssetId} else closed,
        bow = if casting then {source = casting, id = castingId,
            rotation = rotation, swapXZ = swapXZ} else closed,
        roller = if relief.detail then {source = relief.detail, id = relief.assetId} else closed,
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

-- Both callers coalesce matching streamed template events into one rebuild.
function Geometry.watch(onChanged, additionalModels)
    local function changed(item)
        local model = if item:IsA("MeshPart") then item.Parent else item
        local holder = model and model.Parent
        if not holder or holder.Parent ~= ReplicatedStorage or not model:IsA("Model") then return end
        if SOURCE_MODELS[holder.Name] == model.Name
            or (additionalModels and additionalModels[holder.Name] == model.Name)
            or (holder.Name == "ApprovedFloorReliefTemplates"
                and (model.Name == "Harbor" or model.Name == "Classic")) then
            onChanged()
        end
    end
    ReplicatedStorage.DescendantAdded:Connect(changed)
    ReplicatedStorage.DescendantRemoving:Connect(changed)
end

return Geometry
