local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)
local PremiumLobbyGroundMeshKit = require(script.Parent.PremiumLobbyGroundMeshKit)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "LobbySurfaceDetailLocal"
folder.Parent = workspace

local clearingOwn = false
local function clear()
    clearingOwn = true
    folder:ClearAllChildren()
    clearingOwn = false
    if player:GetAttribute("LocalOriginalLobbyGroundMeshPartCount") ~= 0 then
        player:SetAttribute("LocalOriginalLobbyGroundMeshPartCount", 0)
    end
    if player:GetAttribute("LocalOriginalLobbyGroundTileCount") ~= 0 then
        player:SetAttribute("LocalOriginalLobbyGroundTileCount", 0)
    end
end

local function makePart(name, size, cframe, color, material, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Color = color
    part.Material = material or Enum.Material.Metal
    part.Transparency = transparency or 0
    part.Parent = folder
    return part
end

local function rebuild()
    clear()

    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    local floor = lobby and lobby:FindFirstChild("Floor")
    local decor = lobby and lobby:FindFirstChild("Decor")
    if not lobby or not floor or not floor:IsA("BasePart") then
        return
    end

    local tier = VfxQuality.deviceTier(
        player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled)
    -- Only verified real imported UV meshes replace the native line grid.
    -- All gameplay panels, the 74-stud collision Floor, and spawn remain.
    local meshParts, meshTiles = PremiumLobbyGroundMeshKit.install(
        folder, floor, tier.Name, player:GetAttribute("OptionalVfxPressure")
    )
    if player:GetAttribute("LocalOriginalLobbyGroundMeshPartCount")
        ~= meshParts then
        player:SetAttribute("LocalOriginalLobbyGroundMeshPartCount", meshParts)
    end
    if player:GetAttribute("LocalOriginalLobbyGroundTileCount")
        ~= meshTiles then
        player:SetAttribute("LocalOriginalLobbyGroundTileCount", meshTiles)
    end
    local top = floor.CFrame * CFrame.new(0, floor.Size.Y * 0.5 + 0.04, 0)
    local halfX = floor.Size.X * 0.5
    local halfZ = floor.Size.Z * 0.5

    local seamCount = meshTiles > 0 and 0
        or (tier.Name == "Low" and 4 or (tier.Name == "Medium" and 6 or 8))
    for i = 1, seamCount do
        local t = (i / (seamCount + 1)) * 2 - 1
        local horizontal = i % 2 == 0
        makePart(
            "LobbyPanelSeam" .. i,
            horizontal
                and Vector3.new(floor.Size.X * 0.80, 0.026, 0.075)
                or Vector3.new(0.075, 0.026, floor.Size.Z * 0.80),
            top * CFrame.new(
                horizontal and 0 or t * halfX * 0.78,
                0,
                horizontal and t * halfZ * 0.78 or 0
            ),
            VisualTheme.World.Deep,
            Enum.Material.Metal,
            tier.Name == "Low" and 0.78 or 0.62
        )
    end

    local panelCount = tier.Name == "Low" and 4 or (tier.Name == "Medium" and 6 or 8)
    for i = 1, panelCount do
        local angle = ((i - 1) / panelCount) * math.pi * 2 + math.rad(22.5)
        local radius = 25 + ((i * 3) % 6)
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        local panel = makePart(
            "LobbyMaintenancePanel" .. i,
            Vector3.new(4.8 + (i % 2) * 1.6, 0.034, 2.0),
            top
                * CFrame.new(x, 0.012, z)
                * CFrame.Angles(0, -angle + math.pi * 0.5, 0),
            VisualTheme.World.SurfaceRaised:Lerp(VisualTheme.World.Metal, 0.38),
            i % 3 == 0 and Enum.Material.DiamondPlate or Enum.Material.Metal,
            tier.Name == "Low" and 0.30 or 0.16
        )

        if tier.Name == "High" then
            makePart(
                "LobbyMaintenanceInset" .. i,
                Vector3.new(panel.Size.X * 0.62, 0.022, 0.08),
                panel.CFrame * CFrame.new(0, panel.Size.Y * 0.5 + 0.02, 0),
                i % 2 == 0 and VisualTheme.Accents.Cyan or VisualTheme.Accents.Violet,
                Enum.Material.Neon,
                0.72
            )
        end
    end

    local runway = decor and decor:FindFirstChild("ArenaRunway")
    if runway and runway:IsA("BasePart") then
        local sectionCount = tier.Name == "Low" and 4 or 7
        for i = 1, sectionCount do
            local t = (i / (sectionCount + 1)) * 2 - 1
            local seam = makePart(
                "RunwaySection" .. i,
                Vector3.new(runway.Size.X * 0.78, 0.026, 0.08),
                runway.CFrame * CFrame.new(
                    0,
                    runway.Size.Y * 0.5 + 0.024,
                    t * runway.Size.Z * 0.44
                ),
                VisualTheme.World.MetalLight,
                Enum.Material.Metal,
                tier.Name == "Low" and 0.74 or 0.58
            )

            if tier.Name ~= "Low" and i % 2 == 1 then
                makePart(
                    "RunwayGuide" .. i,
                    Vector3.new(1.7, 0.030, 0.18),
                    seam.CFrame * CFrame.new(0, 0.012, -1.15),
                    i % 4 == 1 and VisualTheme.Accents.Cyan or VisualTheme.Accents.Violet,
                    Enum.Material.Neon,
                    0.52
                )
            end
        end
    end

    local centerPlatform = decor and decor:FindFirstChild("CenterPlatform")
    if centerPlatform and centerPlatform:IsA("BasePart") and tier.Name ~= "Low" then
        local topCenter = centerPlatform.CFrame
            * CFrame.new(0, centerPlatform.Size.Y * 0.5 + 0.04, 0)
        for i = 1, 4 do
            local angle = math.rad(45 + (i - 1) * 90)
            makePart(
                "CenterPlatformTrim" .. i,
                Vector3.new(6.2, 0.03, 0.11),
                topCenter
                    * CFrame.new(
                        math.cos(angle) * 7.0,
                        0,
                        math.sin(angle) * 7.0
                    )
                    * CFrame.Angles(0, -angle + math.pi * 0.5, 0),
                i % 2 == 0 and VisualTheme.Accents.Violet or VisualTheme.Accents.Cyan,
                Enum.Material.Neon,
                0.58
            )
        end
    end
end

-- Existing server asset lane can publish PremiumGroundTile after the
-- lobby is first shown. One deferred reconstruction replaces native lines
-- only once actual original MeshParts are ready, not on a fixed timer.
local refreshPending = false
local disconnectFloorWatch = nil
local watchedMap = nil
local watchedTemplates = nil
local templateConnections = {}

local function scheduleRefresh()
    if refreshPending then return end
    refreshPending = true
    task.defer(function()
        refreshPending = false
        rebuild()
    end)
end

local function bindMap(generated)
    if disconnectFloorWatch then disconnectFloorWatch() end
    disconnectFloorWatch = nil
    watchedMap = generated
    if generated then
        disconnectFloorWatch = MapVisualReadiness.watch(
            generated, "Lobby", "Floor", scheduleRefresh)
    else
        clear()
    end
    scheduleRefresh()
end

local function bindTemplates(holder)
    if watchedTemplates == holder then return end
    for _, connection in ipairs(templateConnections) do
        connection:Disconnect()
    end
    table.clear(templateConnections)
    watchedTemplates = holder
    if holder and holder:IsA("Folder") then
        local function changed(child)
            if child.Name == "PremiumGroundTile" then scheduleRefresh() end
        end
        templateConnections[#templateConnections + 1] =
            holder.ChildAdded:Connect(changed)
        templateConnections[#templateConnections + 1] =
            holder.ChildRemoved:Connect(changed)
        templateConnections[#templateConnections + 1] =
            holder:GetAttributeChangedSignal("OwnerVerified")
                :Connect(scheduleRefresh)
    end
    scheduleRefresh()
end

-- Approved client meshes do not normally stream out, but any unexpected
-- removal must restore their native backdrop without a manual reload.
-- Suppress our own ClearAllChildren teardown to avoid rebuild recursion.
folder.DescendantRemoving:Connect(function(item)
    if not clearingOwn and item:IsA("MeshPart")
        and item:GetAttribute("OriginalLobbyGround3D") == true then
        scheduleRefresh()
    end
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap"
        and child == workspace:FindFirstChild("GeneratedMap") then
        bindMap(child)
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child == watchedMap then
        bindMap(workspace:FindFirstChild("GeneratedMap"))
    end
end)

ReplicatedStorage.ChildAdded:Connect(function(child)
    if child.Name == "PremiumRouteMeshTemplates" then
        bindTemplates(child)
    end
end)
ReplicatedStorage.ChildRemoved:Connect(function(child)
    if child == watchedTemplates then
        bindTemplates(ReplicatedStorage:FindFirstChild(
            "PremiumRouteMeshTemplates"))
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(scheduleRefresh)
player:GetAttributeChangedSignal("OptionalVfxPressure"):Connect(scheduleRefresh)

bindMap(workspace:FindFirstChild("GeneratedMap"))
bindTemplates(ReplicatedStorage:FindFirstChild("PremiumRouteMeshTemplates"))
scheduleRefresh()
