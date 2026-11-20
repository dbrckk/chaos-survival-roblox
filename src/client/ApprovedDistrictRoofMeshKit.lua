-- Variant-specific rooftop equipment on the existing district scenery pass.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:FindFirstChild("Shared")
local horizonModule = shared and shared:FindFirstChild("HorizonMonumentGeometry")
local HorizonMonumentGeometry = if horizonModule then require(horizonModule)
    else require("../shared/HorizonMonumentGeometry")

local Kit = {}
local V = Vector3.new
local FACADE = "LocalApprovedDistrictFacadeMounted"
local PROFILES = {
    Classic = {
        holder = "ApprovedClassicSignatureObservatoryTemplates",
        template = "DualDishObservatory", tag = "OriginalClassicDualDishObservatory3D",
        id = 112493873850364, bounds = V(9.105, 15.0875, 1.03), dishes = true,
        size = V(10.6, 15.7, 2.3), center = V(0, 22.35, -3.25),
        natives = {"ObservatoryColumn", "StormSensor", "LightningTip",
            "WeatherRadarShell", "RadarFeedHousing"},
    },
    Towers = {
        holder = "ApprovedSouthTowersSkytransferTemplates",
        template = "ForgedSkytransfer", tag = "OriginalSouthTowersForgedSkytransfer3D",
        id = 120959181274080, bounds = V(19.65, 4.42948, 2.94874),
        size = V(13.2, 5.6, 4.7), center = V(0, 17.7, -2.2),
        natives = {"GantryArch", "TransitCab", "TransitGlazing", "TransferRailHousing",
            "HoistDriveHousing-1", "HoistDriveHousing1"},
    },
    Crossroads = {
        holder = "ApprovedCrossroadsSignatureInterchangeTemplates",
        template = "ForgedInterchange", tag = "OriginalCrossroadsSignatureInterchange3D",
        id = 96622579843060, bounds = V(47.68, 11.73404, 6.76),
        size = V(14.2, 8.1, 5.2), center = V(0, 19.4, -2.55),
        natives = {"SwitchArm", "SwitchPod-1", "SwitchPod1",
            "RouteRelayHousing-1", "RouteRelayHousing1", "SwitchboardPanel"},
    },
    Orbital = {
        holder = "ApprovedOrbitalReactorLandmarkTemplates",
        template = "Node", tag = "OriginalOrbitalReactorLandmark3D",
        id = 104654294187035, bounds = V(4.36, 4.36, 4.36),
        size = V(10.4, 10.4, 10.4), center = V(0, 20.55, -2.5),
        natives = {"HaloReceiver", "ReactorSphere", "ReactorCap",
            "ContainmentShield-1", "ContainmentShield1", "ReactorCollectorHousing"},
    },
    Harbor = {
        holder = "ApprovedHarborKineticGantryTemplates",
        template = "ContainerGantry", tag = "OriginalHarborKineticGantry3D",
        id = 75684193304551, bounds = V(44, 36.08949, 21.86), crane = true,
        size = V(13.6, 12.5, 6.8), center = V(0, 20.85, -2.6),
        natives = {"HarborHoistTower", "HarborLoadCrossarm", "HarborHoistCabin",
            "HarborCargoCable", "HarborCargoHousing"},
    },
}
local BUDGET = {
    Low = {count = 1, touch = 1, range = 142},
    Medium = {count = 3, touch = 2, range = 196},
    High = {count = 6, touch = 3, range = 250},
}
local RETENTION = 15
local PIECES = 7
local MESH_PROPERTIES = {"MeshId", "CFrame", "Size", "Anchored",
    "Massless", "CanCollide", "CanTouch", "CanQuery", "Transparency"}
local NATIVE_PROPERTIES = {"Name", "CFrame", "Size", "Anchored",
    "CanCollide", "CanTouch", "CanQuery", "LocalTransparencyModifier"}
local OWNER_ATTRIBUTES = {"ArenaDistrictArchitecture", "SourceIsOriginal", "CosmeticOnly",
    "DistrictIndex", "FacadeVisualVersion", "FacadeVariantId", FACADE}

local bucket = Instance.new("Folder")
bucket.Name = "ApprovedDistrictRoofsLocal"
bucket:SetAttribute("CosmeticOnly", true)
bucket.Parent = workspace

local activeArena
local activeVariant
local activeSource
local sourceConnections = {}
local mounted = {}

local function watch(connections, signal, callback)
    table.insert(connections, signal:Connect(callback))
end

local function disconnect(connections)
    for _, connection in ipairs(connections) do connection:Disconnect() end
    table.clear(connections)
end

local function release(building)
    local entry = mounted[building]
    if not entry then return end
    mounted[building] = nil
    disconnect(entry.connections)
    for part, alpha in pairs(entry.originals) do
        if part.Transparency == 1 then part.Transparency = alpha end
    end
    entry.model:Destroy()
end

local function clear()
    disconnect(sourceConnections)
    activeSource = nil
    for building in pairs(mounted) do release(building) end
end

local function approved(profile)
    local holder = ReplicatedStorage:FindFirstChild(profile.holder)
    local model = holder and holder:FindFirstChild(profile.template)
    if not holder or not holder:IsA("Folder") or holder:GetAttribute("OwnerVerified") ~= true
        or not model or not model:IsA("Model") or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true or model:GetAttribute(profile.tag) ~= true
        or model:GetAttribute("Original3DAssetId") ~= profile.id then return nil end
    local parts = model:GetChildren()
    if #parts ~= PIECES then return nil end
    for _, part in ipairs(parts) do
        if not part:IsA("MeshPart") or not part.Anchored or not part.Massless
            or part.CanCollide or part.CanTouch or part.CanQuery
            or part.Transparency >= 1 then return nil end
        for _, detail in ipairs(part:GetDescendants()) do
            if not detail:IsA("SurfaceAppearance") and not detail:IsA("Decal")
                and not detail:IsA("Texture") then return nil end
        end
    end
    local _, bounds = model:GetBoundingBox()
    local size = profile.bounds
    if math.abs(math.max(bounds.X, bounds.Z) - size.X) > .55
        or math.abs(bounds.Y - size.Y) > .52
        or math.abs(math.min(bounds.X, bounds.Z) - size.Z) > .28 then return nil end
    return model
end

local function bindSource(model, profile)
    activeSource = model
    local holder = model.Parent
    watch(sourceConnections, holder:GetAttributeChangedSignal("OwnerVerified"), clear)
    watch(sourceConnections, holder:GetPropertyChangedSignal("Name"), clear)
    watch(sourceConnections, model:GetPropertyChangedSignal("Name"), clear)
    watch(sourceConnections, model.AncestryChanged, clear)
    watch(sourceConnections, model.DescendantAdded, clear)
    watch(sourceConnections, model.DescendantRemoving, clear)
    for _, name in ipairs({"OwnerVerified", "CosmeticOnly", "Original3DAssetId", profile.tag}) do
        watch(sourceConnections, model:GetAttributeChangedSignal(name), clear)
    end
    for _, part in ipairs(model:GetChildren()) do
        for _, property in ipairs(MESH_PROPERTIES) do
            watch(sourceConnections, part:GetPropertyChangedSignal(property), clear)
        end
    end
end

local SHAFTS = {
    ObservatoryColumn = true, LightningTip = true, HarborHoistTower = true, HarborCargoCable = true,
}
local ROOF_ASSETS = {
    StormSensor = 104654294187035, WeatherRadarShell = 104654294187035,
    HaloReceiver = 104654294187035, ReactorSphere = 104654294187035,
    GantryArch = 106401955318567, TransferRailHousing = 106401955318567,
    SwitchArm = 106401955318567, ReactorCollectorHousing = 106401955318567,
    HarborLoadCrossarm = 106401955318567,
    RadarFeedHousing = 88962643359267, TransitCab = 88962643359267, TransitGlazing = 88962643359267,
    ["HoistDriveHousing-1"] = 88962643359267, HoistDriveHousing1 = 88962643359267,
    ["SwitchPod-1"] = 88962643359267, SwitchPod1 = 88962643359267,
    ["RouteRelayHousing-1"] = 88962643359267, RouteRelayHousing1 = 88962643359267,
    SwitchboardPanel = 88962643359267, ReactorCap = 88962643359267,
    ["ContainmentShield-1"] = 88962643359267, ContainmentShield1 = 88962643359267,
    HarborHoistCabin = 88962643359267, HarborCargoHousing = 88962643359267,
}

local function visibleCosmetic(part, variant)
    if not part then return false end
    local native = part:IsA("Part") or part:IsA("WedgePart")
    local assetId = if SHAFTS[part.Name] then HorizonMonumentGeometry.assetId("shaft", variant)
        else ROOF_ASSETS[part.Name]
    local fitted = part:IsA("MeshPart") and assetId ~= nil and part.MeshId ~= ""
        and part:GetAttribute("Original3DAssetId") == assetId
        and (part.Name ~= "TransitGlazing" or (part.Size - V(3.5, 1.1, .18)).Magnitude < .06)
    return (native or fitted) and part.Anchored
        and not part.CanCollide and not part.CanTouch and not part.CanQuery
        and part:GetAttribute("SceneryLodHidden") ~= true
        and part.LocalTransparencyModifier < .95
end

local function ownerEligible(building, district, variant)
    local index = building:GetAttribute("DistrictIndex")
    return building:IsA("Model") and building.Parent == district
        and building:GetAttribute("ArenaDistrictArchitecture") == true
        and building:GetAttribute("SourceIsOriginal") == true
        and building:GetAttribute("CosmeticOnly") == true
        and building:GetAttribute("FacadeVisualVersion") == 1
        and building:GetAttribute("FacadeVariantId") == variant
        and building:GetAttribute(FACADE) == true
        and type(index) == "number" and index % 1 == 0 and index >= 1 and index <= 16
end

local function matchesNative(part, origin, variant)
    if not visibleCosmetic(part, variant) then return false end
    local center = origin:PointToObjectSpace(part.Position)
    return math.abs(center.X) <= 7 and center.Y >= 16 and center.Y <= 29
        and math.abs(center.Z) <= 4.25 and math.max(part.Size.X, part.Size.Y, part.Size.Z) <= 13
end

local function getDoor(building)
    local door = building:FindFirstChild("ServiceEntryDoor")
    if visibleCosmetic(door) and door:IsA("Part") and door.Transparency < .7
        and (door.Size - V(4.65, 4.68, .18)).Magnitude < .08 then return door end
    return nil
end

local function axisScale(axis, scale)
    if math.abs(axis.X) > .9999 then return scale.X end
    if math.abs(axis.Y) > .9999 then return scale.Y end
    if math.abs(axis.Z) > .9999 then return scale.Z end
    if scale.X == scale.Y and scale.Y == scale.Z then return scale.X end
    return nil
end

local function fit(source, profile, origin, tint)
    local clone = source:Clone()
    if not clone then return nil end
    local frame, bounds = clone:GetBoundingBox()
    local swapped = bounds.Z > bounds.X + .25
    local yaw = if swapped then -math.pi * .5 else 0
    local parts = clone:GetChildren()
    -- Import may interchange X and Z. Resolve both directional assets
    -- from their own geometry so neither faces away from the district.
    for _, part in ipairs(parts) do
        local position = frame:PointToObjectSpace(part.Position)
        if profile.dishes and math.abs(part.Size.Y - 13.8531) < .08
            and math.abs(math.max(part.Size.X, part.Size.Z) - 6.6175) < .08 then
            if (if swapped then position.X else position.Z) > 0 then yaw += math.pi end
            break
        elseif profile.crane and part:GetAttribute("OriginalHarborGantryKineticRole") == "Load" then
            if (if swapped then -position.Z else position.X) > 0 then yaw += math.pi end
            break
        end
    end
    local target = origin * CFrame.new(profile.center) * CFrame.Angles(0, yaw, 0)
    local size = profile.size
    if swapped then size = V(size.Z, size.Y, size.X) end
    local scale = size / bounds
    for _, part in ipairs(parts) do
        local pose = frame:ToObjectSpace(part.CFrame)
        local x, y, z = axisScale(pose.RightVector, scale),
            axisScale(pose.UpVector, scale), axisScale(pose.LookVector, scale)
        if not x or not y or not z then clone:Destroy(); return nil end
        part.Size *= V(x, y, z)
        part.CFrame = target * CFrame.new(pose.Position * scale) * pose.Rotation
        part.Color = part.Color:Lerp(tint, .20)
        part.CastShadow = false
        part.LocalTransparencyModifier = 0
    end
    clone.Name = "ApprovedOriginalDistrictRoof3D"
    return clone, parts
end

local function mask(entry)
    for part in pairs(entry.originals) do
        if part.Transparency < 1 then
            entry.originals[part] = part.Transparency
            part.Transparency = 1
        end
    end
end

local function mount(item, district, variant, profile, source)
    local building, door = item.building, item.door
    local model, pieces = fit(source, profile, item.origin, item.natives[1].Color)
    if not model then return end
    model:SetAttribute("DistrictIndex", building:GetAttribute("DistrictIndex"))
    local entry = {model = model, door = door, natives = item.natives, originals = {}, connections = {}}
    for _, native in ipairs(item.natives) do entry.originals[native] = native.Transparency end
    mounted[building] = entry
    model.Parent = bucket
    local function drop()
        if mounted[building] == entry then release(building) end
    end
    local function ownerChanged()
        if not ownerEligible(building, district, variant) or getDoor(building) ~= door
            or not activeArena or activeArena.Parent ~= workspace:FindFirstChild("GeneratedMap")
            or district.Parent ~= activeArena:FindFirstChild("Decor") then drop() end
    end
    watch(entry.connections, building.AncestryChanged, ownerChanged)
    for _, name in ipairs(OWNER_ATTRIBUTES) do
        watch(entry.connections, building:GetAttributeChangedSignal(name), drop)
    end
    watch(entry.connections, door.AncestryChanged, ownerChanged)
    for _, property in ipairs(NATIVE_PROPERTIES) do
        watch(entry.connections, door:GetPropertyChangedSignal(property), drop)
    end
    watch(entry.connections, door:GetPropertyChangedSignal("Transparency"), ownerChanged)
    watch(entry.connections, door:GetAttributeChangedSignal("SceneryLodHidden"), ownerChanged)
    for _, native in ipairs(item.natives) do
        watch(entry.connections, native.AncestryChanged, drop)
        watch(entry.connections, native:GetAttributeChangedSignal("SceneryLodHidden"), drop)
        if native:IsA("MeshPart") then
            watch(entry.connections, native:GetPropertyChangedSignal("MeshId"), drop)
            watch(entry.connections, native:GetAttributeChangedSignal("Original3DAssetId"), drop)
        end
        for _, property in ipairs(NATIVE_PROPERTIES) do
            watch(entry.connections, native:GetPropertyChangedSignal(property), drop)
        end
    end
    watch(entry.connections, model.AncestryChanged, function()
        if model.Parent ~= bucket then drop() end
    end)
    watch(entry.connections, model.ChildAdded, drop)
    watch(entry.connections, model.ChildRemoved, drop)
    for _, part in ipairs(pieces) do
        watch(entry.connections, part:GetPropertyChangedSignal("LocalTransparencyModifier"), drop)
        for _, property in ipairs(MESH_PROPERTIES) do
            watch(entry.connections, part:GetPropertyChangedSignal(property), drop)
        end
    end
    mask(entry)
end

local function candidate(building, district, variant, profile, camera, look, range)
    if not ownerEligible(building, district, variant) then return nil end
    local door = getDoor(building)
    if not door then return nil end
    local origin = door.CFrame * CFrame.new(.35, -4, 4.36)
    local offset = origin:PointToWorldSpace(profile.center) - camera
    local distance = offset.Magnitude
    local entry = mounted[building]
    local margin = if entry then RETENTION else 0
    if distance > range + margin then return nil end
    local natives = {}
    for _, name in ipairs(profile.natives) do
        local native = building:FindFirstChild(name)
        if not matchesNative(native, origin, variant)
            or (native.Transparency >= 1 and (not entry or entry.originals[native] == nil)) then return nil end
        table.insert(natives, native)
    end
    local planar = V(offset.X, 0, offset.Z)
    local behind = planar.Magnitude > 35 and planar.Unit:Dot(look) < -.15
    return {building = building, door = door, origin = origin, natives = natives,
        score = distance - margin * .5 + (behind and 75 or 0)}
end

local function sameNatives(old, new)
    for index, part in ipairs(new) do
        if old[index] ~= part then return false end
    end
    return true
end

function Kit.sync(arena, camera, tier, ready, touch, pressure, cameraLook)
    local variant = arena and arena:GetAttribute("VariantId")
    if arena ~= activeArena or variant ~= activeVariant then
        clear()
        activeArena, activeVariant = arena, variant
    end
    local profile = PROFILES[variant]
    local generated = workspace:FindFirstChild("GeneratedMap")
    local decor = arena and arena:FindFirstChild("Decor")
    local district = decor and decor:FindFirstChild("ArenaDistrictArchitecture3D")
    if not profile or not ready or typeof(camera) ~= "Vector3" or (tonumber(pressure) or 0) >= 1
        or not generated or not arena or arena.Parent ~= generated or arena.Name ~= "Arena"
        or not district or not district:IsA("Folder") then clear(); return end
    local source = approved(profile)
    if source ~= activeSource then
        clear()
        if source then bindSource(source, profile) end
    end
    if not source then return end

    local budget = BUDGET[tier] or BUDGET.Low
    local cap = if touch then budget.touch else budget.count
    local look = if typeof(cameraLook) == "Vector3" then V(cameraLook.X, 0, cameraLook.Z) else Vector3.zero
    look = if look.Magnitude > .2 then look.Unit else Vector3.zero
    local candidates = {}
    for _, building in ipairs(district:GetChildren()) do
        local item = candidate(building, district, variant, profile, camera, look, budget.range)
        if item then table.insert(candidates, item) end
    end
    table.sort(candidates, function(a, b)
        if a.score == b.score then return a.building.Name < b.building.Name end
        return a.score < b.score
    end)
    local wanted = {}
    for i = 1, math.min(#candidates, cap) do
        local item = candidates[i]
        wanted[item.building] = item
    end
    for building, entry in pairs(mounted) do
        local item = wanted[building]
        if not item or item.door ~= entry.door or entry.model.Parent ~= bucket
            or not sameNatives(entry.natives, item.natives) then
            release(building)
        end
    end
    for building, item in pairs(wanted) do
        local entry = mounted[building]
        if entry then mask(entry) else mount(item, district, variant, profile, source) end
    end
end

function Kit.replacedNativeCount()
    local count = 0
    for building, entry in pairs(mounted) do
        for native in pairs(entry.originals) do
            if native.Parent == building and native.Transparency == 1 then count += 1 end
        end
    end
    return count
end

return Kit
