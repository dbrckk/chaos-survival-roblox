local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)
local PremiumLobbyGroundMeshKit = require(script.Parent.PremiumLobbyGroundMeshKit)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer

local FALLBACK_PAIRS = {Low = 2, Medium = 3, High = 4}
-- Fractions of the inset's half extents. Leave its four straight access
-- routes, the notice panels and the raised center clear.
local SEAM_LAYOUT = {
    {x = .56, z = -.82, alongX = true, length = .53},
    {x = .56, z = .88, alongX = true, length = .53},
    {x = .89, z = -.51, alongX = false, length = .48},
    {x = .89, z = .51, alongX = false, length = .48},
}
local MAINTENANCE_LAYOUT = {
    {x = .54, z = -.61, alongX = true, length = 6.4},
    {x = .54, z = .61, alongX = true, length = 4.8},
    {x = .80, z = .29, alongX = false, length = 6.4},
    {x = .80, z = -.57, alongX = false, length = 4.8},
}

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

local function buildVestibuleFallback(inset, tier, vestibuleTiles)
    local top = inset.CFrame * CFrame.new(0, inset.Size.Y * .5, 0)
    local halfX, halfZ = inset.Size.X * .5, inset.Size.Z * .5
    local hatchColor = VisualTheme.World.SurfaceRaised:Lerp(VisualTheme.World.Metal, .38)
    local showHatchLights = tier == "High" and vestibuleTiles == 0

    for i = 1, FALLBACK_PAIRS[tier] do
        local seam = SEAM_LAYOUT[i]
        local hatch = MAINTENANCE_LAYOUT[i]
        local seamSize = seam.alongX and Vector3.new(halfX * seam.length, .026, .12)
            or Vector3.new(.12, .026, halfZ * seam.length)
        local hatchRotation = CFrame.Angles(0, hatch.alongX and 0 or math.pi * .5, 0)
        for side = -1, 1, 2 do
            local index = (i - 1) * 2 + (side < 0 and 1 or 2)
            if not PremiumLobbyGroundMeshKit.coversVestibuleSector(vestibuleTiles, side, seam.z) then
                makePart("LobbyPanelSeam" .. index, seamSize,
                    top * CFrame.new(side * seam.x * halfX, .017, seam.z * halfZ),
                    VisualTheme.World.MetalLight, Enum.Material.Metal, tier == "Low" and .48 or .56)
            end
            if not PremiumLobbyGroundMeshKit.coversVestibuleSector(vestibuleTiles, side, hatch.z) then
                local panel = makePart("LobbyMaintenancePanel" .. index,
                    Vector3.new(hatch.length, .034, 2),
                    top * CFrame.new(side * hatch.x * halfX, .022, hatch.z * halfZ) * hatchRotation,
                    hatchColor, Enum.Material.Metal, tier == "Low" and .30 or .16)
                if showHatchLights then
                    makePart("LobbyMaintenanceInset" .. index,
                        Vector3.new(panel.Size.X * .62, .022, .08),
                        panel.CFrame * CFrame.new(0, panel.Size.Y * .5 + .012, 0),
                        side < 0 and VisualTheme.Accents.Cyan or VisualTheme.Accents.Violet,
                        Enum.Material.Neon, .72)
                end
            end
        end
    end
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
    local centerPlatform = decor and decor:FindFirstChild("CenterPlatform")
    -- A mounted approved tile takes over the fallback seams and hatches.
    -- All gameplay panels, the 74-stud collision Floor, and spawn remain.
    local meshParts, meshTiles, vestibuleTiles = PremiumLobbyGroundMeshKit.install(
        folder, floor, tier.Name, player:GetAttribute("OptionalVfxPressure"), centerPlatform
    )
    if player:GetAttribute("LocalOriginalLobbyGroundMeshPartCount")
        ~= meshParts then
        player:SetAttribute("LocalOriginalLobbyGroundMeshPartCount", meshParts)
    end
    if player:GetAttribute("LocalOriginalLobbyGroundTileCount")
        ~= meshTiles then
        player:SetAttribute("LocalOriginalLobbyGroundTileCount", meshTiles)
    end
    local inset = decor and decor:FindFirstChild("LobbyFloorInset")
    if inset and inset:IsA("BasePart") then
        buildVestibuleFallback(inset, tier.Name, vestibuleTiles)
    end

    local runway = decor and decor:FindFirstChild("ArenaRunway")
    if runway and runway:IsA("BasePart") then
        local sectionCount = tier.Name == "Low" and 4 or 7
        -- Seat the relief just clear of the deck and under the moving cue.
        local detailPlane = runway.CFrame * CFrame.new(0, runway.Size.Y * 0.5 + 0.016, 0)
        for i = 1, sectionCount do
            local t = (i / (sectionCount + 1)) * 2 - 1
            local sectionFrame = detailPlane * CFrame.new(0, 0, t * runway.Size.Z * 0.44)
            local seam = makePart(
                "RunwaySection" .. i,
                Vector3.new(runway.Size.X * 0.78, 0.022, 0.16),
                sectionFrame,
                VisualTheme.World.MetalLight,
                Enum.Material.Metal,
                tier.Name == "Low" and 0.63 or 0.56
            )
            CollectionService:AddTag(seam, "LobbySculptedSwept")

            if tier.Name ~= "Low" and i % 2 == 1 then
                local guide = makePart(
                    "RunwayGuide" .. i,
                    Vector3.new(1.7, 0.022, 0.20),
                    sectionFrame * CFrame.new(0, 0, -1.15),
                    i % 4 == 1 and VisualTheme.Accents.Cyan or VisualTheme.Accents.Violet,
                    Enum.Material.Neon,
                    0.52
                )
                CollectionService:AddTag(guide, "LobbySculptedSwept")
            end
        end
    end

    if centerPlatform and centerPlatform:IsA("BasePart") and tier.Name ~= "Low" then
        local topCenter = centerPlatform.CFrame
            * CFrame.new(0, centerPlatform.Size.Y * 0.5 + 0.056, 0)
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
        local disconnectFloor = MapVisualReadiness.watch(
            generated, "Lobby", "Floor", scheduleRefresh)
        local function onDetailAnchorChange(item)
            if item.Name ~= "CenterPlatform" and item.Name ~= "ArenaRunway"
                and item.Name ~= "LobbyFloorInset" then return end
            local lobby = generated:FindFirstChild("Lobby")
            local decor = lobby and lobby:FindFirstChild("Decor")
            if decor and item.Parent == decor then scheduleRefresh() end
        end
        local added = generated.DescendantAdded:Connect(onDetailAnchorChange)
        -- On removal, refresh from the canonical hierarchy after the
        -- anchor (or a streamed ancestor) actually leaves the lobby.
        local removing = generated.DescendantRemoving:Connect(onDetailAnchorChange)
        disconnectFloorWatch = function()
            disconnectFloor()
            added:Disconnect()
            removing:Disconnect()
        end
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
