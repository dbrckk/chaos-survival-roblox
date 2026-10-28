-- Authored industrial decals for the SIXTEEN canonical in-arena
-- district models. These are client-only SurfaceGuis on existing native
-- building geometry (never extra Parts or counterfeit texture asset IDs).
-- Close-range finish follows the established per-model scenery LOD's
-- LocalTransparencyModifier and disconnects on StreamingEnabled removal.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local DistrictMaterialFinishKit = require(script.Parent.DistrictMaterialFinishKit)

local player = Players.LocalPlayer
local details = {}
local folderAddedConnection = nil
local folderRemovedConnection = nil
local watchedFolder = nil
local rebuildPending = false

local function clear()
    if folderAddedConnection then
        folderAddedConnection:Disconnect()
        folderAddedConnection = nil
    end
    if folderRemovedConnection then
        folderRemovedConnection:Disconnect()
        folderRemovedConnection = nil
    end
    for part, entry in pairs(details) do
        entry.connection:Disconnect()
        if entry.gui.Parent then
            entry.gui:Destroy()
        end
        details[part] = nil
    end
    watchedFolder = nil
end

local function retire(model)
    for part, entry in pairs(details) do
        if part:IsDescendantOf(model) then
            entry.connection:Disconnect()
            if entry.gui.Parent then
                entry.gui:Destroy()
            end
            details[part] = nil
        end
    end
end

local function attach(model, variant, tier)
    if not model:IsA("Model")
        or model:GetAttribute("ArenaDistrictArchitecture") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model.Parent ~= watchedFolder
    then
        return
    end
    local index = tonumber(model:GetAttribute("DistrictIndex"))
    if not index or index < 1 or index > 16
        or index ~= math.floor(index) then
        return
    end
    -- A medium Android phone needs silhouettes, NOT 16 rich material
    -- canvases at once. Show half of the facades there, all 16 on High;
    -- each is additionally culled at 115/145 studs by SurfaceGui.
    if tier == "Medium" and index % 2 ~= 0 then return end
    local plate = model:FindFirstChild("SideCassette1")
    if not plate or not plate:IsA("BasePart") or details[plate] then
        return
    end

    local theme = VisualTheme.arena(variant)
    local accent = index % 2 == 0 and theme.Secondary or theme.Accent
    local profile = tonumber(model:GetAttribute("DistrictProfile")) or 1
    local style = (profile == 2 or profile == 3)
        and "hazard" or "telemetry"

    local gui = DistrictMaterialFinishKit.stencil(
        plate,
        "CS-" .. string.format("%02d", index) .. " / " .. string.upper(variant),
        accent, tier, style, Enum.NormalId.Right
    )
    if not gui then return end

    local function matchExistingSceneryLod()
        if gui.Parent then
            gui.Enabled = plate.LocalTransparencyModifier < 0.95
        end
    end
    local connection = plate:GetPropertyChangedSignal(
        "LocalTransparencyModifier"):Connect(matchExistingSceneryLod)
    details[plate] = {gui = gui, connection = connection}
    matchExistingSceneryLod()
end

local function rebuild()
    clear()
    local tier = VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled).Name
    if tier == "Low" then return end
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local decor = arena and arena:FindFirstChild("Decor")
    local folder = decor and decor:FindFirstChild("ArenaDistrictArchitecture3D")
    if not folder or not folder:IsA("Folder") then return end
    watchedFolder = folder
    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local function register(model)
        -- Atomic streamed models can parent before the last surface Parts.
        -- Defer once to allow immediate descendants to replicate first.
        task.defer(function()
            if watchedFolder == folder and model.Parent == folder then
                attach(model, variant, tier)
            end
        end)
    end
    for _, model in ipairs(folder:GetChildren()) do register(model) end
    folderAddedConnection = folder.ChildAdded:Connect(register)
    folderRemovedConnection = folder.ChildRemoved:Connect(retire)
end

local function schedule()
    if rebuildPending then return end
    rebuildPending = true
    task.defer(function()
        rebuildPending = false
        rebuild()
    end)
end

workspace.DescendantAdded:Connect(function(instance)
    if instance.Name == "ArenaDistrictArchitecture3D"
        and instance:IsA("Folder") then
        schedule()
    end
end)
workspace.DescendantRemoving:Connect(function(instance)
    if instance == watchedFolder then
        clear()
    end
end)
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(schedule)
schedule()
