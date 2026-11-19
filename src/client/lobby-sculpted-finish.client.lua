local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local profiles = {
    LobbySculptedCasting = {
        holder = "ApprovedPerimeterArmorTemplates",
        model = "Cap",
        marker = "OriginalPerimeterArmor3D",
        region = "WayfinderBase",
        id = 88962643359267,
    },
    LobbySculptedSwept = {
        holder = "ApprovedTowersSignatureBridgeTemplates",
        model = "ForgedBridge",
        marker = "OriginalTowersSignatureBridge3D",
        region = "SweptCrossbeam",
        id = 126298311664881,
    },
    LobbySculptedShaft = {
        holder = "ApprovedLargeStructureTemplates",
        model = "Towers",
        marker = "OriginalLargeStructure3D",
        region = "BeaconShaft",
        id = 107521411452905,
    },
}

local folder = Instance.new("Folder")
folder.Name = "LobbySculptedFinishLocal"
folder.Parent = workspace

local mounted = {}
local fetches = {}
local refreshPending = false
local scheduleRefresh

local function findSource(profile)
    local holder = ReplicatedStorage:FindFirstChild(profile.holder)
    if not holder or not holder:IsA("Folder") or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local model = holder:FindFirstChild(profile.model)
    if not model or not model:IsA("Model")
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute(profile.marker) ~= true
        or model:GetAttribute("Original3DAssetId") ~= profile.id then
        return nil
    end
    local source = model:FindFirstChild(profile.region)
    return source and source:IsA("MeshPart") and source.Archivable
        and source.MeshId ~= "" and source or nil
end

local function cleanClone(source)
    local mesh = source:Clone()
    if mesh then
        mesh:ClearAllChildren()
        mesh.TextureID = ""
    end
    return mesh
end

local function ready(source)
    local meshId = source.MeshId
    local state = fetches[meshId]
    if state ~= nil then
        return state == "ready"
    end
    fetches[meshId] = "loading"
    task.spawn(function()
        local probe = cleanClone(source)
        if not probe then
            fetches[meshId] = nil
            return
        end
        for attempt = 1, 2 do
            local loaded = false
            local ok = pcall(function()
                ContentProvider:PreloadAsync({probe}, function(_, status)
                    loaded = status == Enum.AssetFetchStatus.Success
                end)
            end)
            if ok and loaded then
                probe:Destroy()
                fetches[meshId] = "ready"
                scheduleRefresh()
                return
            end
            if attempt == 1 then task.wait(12) end
        end
        probe:Destroy()
        -- Asset delivery may fail transiently on mobile connections. Keep
        -- the native Part visible and retry once after a cooldown instead
        -- of permanently disabling all finishes using this mesh ID.
        fetches[meshId] = "cooldown"
        task.delay(60, function()
            if fetches[meshId] == "cooldown" then
                fetches[meshId] = nil
                scheduleRefresh()
            end
        end)
    end)
    return false
end

local function unmount(part)
    local entry = mounted[part]
    if not entry then return end
    mounted[part] = nil
    entry.appearance:Disconnect()
    entry.removal:Disconnect()
    entry.ancestry:Disconnect()
    if part.LocalTransparencyModifier == 1 then
        part.LocalTransparencyModifier = entry.originalMask
    end
    entry.mesh:Destroy()
end

local function mount(part, source)
    local mesh = cleanClone(source)
    if not mesh then return end
    local axisOffset = CFrame.new()
    local function applyGeometry()
        local rotate = (source.Size.X > source.Size.Z) ~= (part.Size.X > part.Size.Z)
        -- A small inset keeps flush SurfaceGuis, light strips and seams clear.
        local size = part.Size * 0.99
        mesh.Size = rotate and Vector3.new(size.Z, size.Y, size.X) or size
        axisOffset = rotate and CFrame.Angles(0, math.pi * 0.5, 0) or CFrame.new()
        mesh.CFrame = part.CFrame * axisOffset
    end
    applyGeometry()
    mesh.Name = part.Name .. "Sculpted"
    mesh.Anchored = true
    mesh.CanCollide = false
    mesh.CanTouch = false
    mesh.CanQuery = false
    mesh.CastShadow = false
    -- The source is hidden only after the replacement is parented. Do not
    -- inherit an old local mask from a recycled/generated source Part.
    mesh.LocalTransparencyModifier = 0

    mesh.Color = part.Color
    mesh.Transparency = part.Transparency
    mesh.Material = part.Material
    mesh.MaterialVariant = part.MaterialVariant
    mesh.Parent = folder
    mounted[part] = {
        source = source,
        mesh = mesh,
        originalMask = part.LocalTransparencyModifier,
        appearance = part.Changed:Connect(function(property)
            if property == "Color" or property == "Transparency"
                or property == "Material" or property == "MaterialVariant" then
                mesh[property] = part[property]
            elseif property == "CFrame" then
                mesh.CFrame = part.CFrame * axisOffset
            elseif property == "Size" then
                applyGeometry()
            end
        end),
        removal = mesh:GetPropertyChangedSignal("Parent"):Connect(function()
            if mesh.Parent ~= folder then unmount(part) end
        end),
        -- GeneratedMap and Activities can be replaced during map resets.
        -- Release the local mesh immediately rather than leaving a ghost
        -- visible until a later tag or player-state refresh.
        ancestry = part.AncestryChanged:Connect(function()
            if not part:IsDescendantOf(workspace) then
                unmount(part)
            else
                scheduleRefresh()
            end
        end),
    }
    part.LocalTransparencyModifier = 1
end

local function refresh()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    local decor = lobby and lobby:FindFirstChild("Decor")
    local architecture = decor and decor:FindFirstChild("OriginalLobbyArchitecture")
    local stage = architecture and architecture:FindFirstChild("MachinedLobbyCenterStage")
    local gate = architecture and architecture:FindFirstChild("MachinedArenaEntrance")
    if (tonumber(player:GetAttribute("LocalOriginalLobbyGateMeshCount")) or 0) > 0 then
        gate = nil
    end
    local activities = lobby and lobby:FindFirstChild("Activities")
    local presentation = workspace:FindFirstChild("LobbyPresentationLocal")
    local surfaceDetail = workspace:FindFirstChild("LobbySurfaceDetailLocal")
    local candidates = {}
    if decor
        and player:GetAttribute("RoundParticipant") ~= true
        and (tonumber(player:GetAttribute("OptionalVfxPressure")) or 0) < 1 then
        for tag, profile in pairs(profiles) do
            local source = findSource(profile)
            if source and ready(source) then
                for _, part in ipairs(CollectionService:GetTagged(tag)) do
                    -- The sculpted lobby signs carry text on their own
                    -- SignTextSurface. Do not mask panels that still
                    -- host a SurfaceGui directly on the backing.
                    local gatePiece = gate and part.Parent == gate
                    local gateCue = presentation and part.Parent == presentation
                        and part:GetAttribute("ChaosLobbyGateCue") == true
                    local socialMarker = presentation and part.Parent == presentation
                        and tag == "LobbySculptedCasting" and part:GetAttribute("LobbySocialMarker") == true
                    local sculptedSurfaceDetail = surfaceDetail and part.Parent == surfaceDetail
                        and tag == "LobbySculptedSwept"
                    if not part:IsA("Part") and not ((gatePiece or gateCue) and part:IsA("WedgePart")) then
                        continue
                    end
                    local cosmeticCladding = (gatePiece or gateCue or socialMarker or sculptedSurfaceDetail
                            or (stage and part.Parent == stage))
                        and not part.CanCollide and not part.CanTouch and not part.CanQuery
                    if part.Anchored
                        and not part:FindFirstChildWhichIsA("SurfaceGui")
                        and (part.Parent == decor or cosmeticCladding
                            or (activities and part.Parent == activities
                                and not part.CanCollide and not part.CanQuery
                                and (not part.CanTouch
                                    or (tag == "LobbySculptedCasting"
                                        and part:GetAttribute("LobbyPracticePad") == true)))) then
                        candidates[part] = source
                    end
                end
            end
        end
    end

    for part, entry in pairs(mounted) do
        if candidates[part] ~= entry.source then unmount(part) end
    end
    for part, source in pairs(candidates) do
        if not mounted[part] then mount(part, source) end
    end
end

scheduleRefresh = function()
    if refreshPending then return end
    refreshPending = true
    task.defer(function()
        refreshPending = false
        refresh()
    end)
end

local function sourceChanged(item)
    for _, profile in pairs(profiles) do
        if item.Name == profile.holder or item.Name == profile.model
            or item.Name == profile.region then
            scheduleRefresh()
            return
        end
    end
end

for tag in pairs(profiles) do
    CollectionService:GetInstanceAddedSignal(tag):Connect(scheduleRefresh)
    CollectionService:GetInstanceRemovedSignal(tag):Connect(scheduleRefresh)
end
ReplicatedStorage.DescendantAdded:Connect(sourceChanged)
ReplicatedStorage.DescendantRemoving:Connect(sourceChanged)
player:GetAttributeChangedSignal("OptionalVfxPressure"):Connect(scheduleRefresh)
player:GetAttributeChangedSignal("RoundParticipant"):Connect(scheduleRefresh)
player:GetAttributeChangedSignal("LocalOriginalLobbyGateMeshCount"):Connect(scheduleRefresh)
scheduleRefresh()
