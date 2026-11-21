-- Forged district bases on the same camera pass as the facade and shell.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:FindFirstChild("Shared")
local horizonModule = shared and shared:FindFirstChild("HorizonMonumentGeometry")
local HorizonMonumentGeometry = if horizonModule then require(horizonModule)
    else require("../shared/HorizonMonumentGeometry")

local Kit = {}
local ASSET_ID = 101457508594609
Kit.AssetId = ASSET_ID
local SOURCE_FOLDER = "ApprovedHarborDockCaissonTemplates"
local SOURCE_TAG = "OriginalHarborDockCaisson3D"
local FACADE = "LocalApprovedDistrictFacadeMounted"
local SIDEWALL = "LocalApprovedDistrictSidewallMounted"
local BUDGET = {
    Low = {count = 1, touch = 1, range = 130},
    Medium = {count = 2, touch = 1, range = 170},
    High = {count = 4, touch = 2, range = 205},
}
local RETENTION = 14
local MATERIAL_COUNT = 7
local FOOT = {name = "BasaltFoundation", size = Vector3.new(.7, 15.5, 15.5), y = .35}
local RIM = {name = "FoundationRim", size = Vector3.new(.22, 13.8, 13.8), y = .77}
local CYLINDER = CFrame.Angles(0, 0, math.pi * .5)
local MESH_PROPERTIES = {"MeshId", "CFrame", "Size", "Anchored", "Massless",
    "CanCollide", "CanTouch", "CanQuery", "Transparency"}
local NATIVE_PROPERTIES = {"Name", "CFrame", "Size", "Anchored",
    "CanCollide", "CanTouch", "CanQuery", "LocalTransparencyModifier"}
local OWNER_ATTRIBUTES = {"ArenaDistrictArchitecture", "SourceIsOriginal",
    "CosmeticOnly", "DistrictIndex", "FacadeVariantId", FACADE, SIDEWALL}

local bucket = Instance.new("Folder")
bucket.Name = "ApprovedDistrictFoundationsLocal"
bucket:SetAttribute("CosmeticOnly", true)
bucket.Parent = workspace

local arenaInUse
local sourceInUse
local sourceConnections = {}
local mounted = {}

local function watch(connections, signal, handler)
    table.insert(connections, signal:Connect(handler))
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
        if part.Parent == building and part.Transparency == 1 then
            part.Transparency = alpha
        end
    end
    entry.clone:Destroy()
end

local function revokeSource()
    disconnect(sourceConnections)
    sourceInUse = nil
    for building in pairs(mounted) do release(building) end
end

local function approved()
    local holder = ReplicatedStorage:FindFirstChild(SOURCE_FOLDER)
    local source = holder and holder:FindFirstChild("DockCaisson")
    if not holder or not holder:IsA("Folder") or not source or not source:IsA("Model")
        or holder:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute(SOURCE_TAG) ~= true
        or source:GetAttribute("Original3DAssetId") ~= ASSET_ID then return nil end
    local parts = source:GetChildren()
    if #parts ~= MATERIAL_COUNT then return nil end
    for _, part in ipairs(parts) do
        if not part:IsA("MeshPart") or not part.Anchored or not part.Massless
            or part.CanCollide or part.CanTouch or part.CanQuery
            or part.Transparency >= 1 then return nil end
        for _, detail in ipairs(part:GetDescendants()) do
            if not detail:IsA("SurfaceAppearance") and not detail:IsA("Decal")
                and not detail:IsA("Texture") then return nil end
        end
    end
    local _, bounds = source:GetBoundingBox()
    if (bounds - Vector3.new(14.07, 3.30755, 14.07)).Magnitude > .47 then return nil end
    return source
end

function Kit.plinthProfile()
    local source = approved()
    if not source then return nil end
    -- The ARMOR region contains the sealed upper cassette and its inset
    -- lower bulkhead. Its square footprint survives horizontal axis swaps.
    local expected = Vector3.new(12.82, 2.69, 12.82)
    local plinth
    for _, part in ipairs(source:GetChildren()) do
        if (part.Size - expected).Magnitude < .12 then
            if plinth or not part.Archivable or part.MeshId == "" then return nil end
            plinth = part
        end
    end
    return plinth
end

local function bindSource(source)
    sourceInUse = source
    local holder = source.Parent
    watch(sourceConnections, holder:GetAttributeChangedSignal("OwnerVerified"), revokeSource)
    watch(sourceConnections, holder:GetPropertyChangedSignal("Name"), revokeSource)
    watch(sourceConnections, source.AncestryChanged, revokeSource)
    watch(sourceConnections, source:GetPropertyChangedSignal("Name"), revokeSource)
    watch(sourceConnections, source.DescendantAdded, revokeSource)
    watch(sourceConnections, source.DescendantRemoving, revokeSource)
    for _, attribute in ipairs({"OwnerVerified", "CosmeticOnly", SOURCE_TAG, "Original3DAssetId"}) do
        watch(sourceConnections, source:GetAttributeChangedSignal(attribute), revokeSource)
    end
    for _, part in ipairs(source:GetChildren()) do
        for _, property in ipairs(MESH_PROPERTIES) do
            watch(sourceConnections, part:GetPropertyChangedSignal(property), revokeSource)
        end
    end
end

local function sameFrame(actual, expected)
    return (actual.Position - expected.Position).Magnitude < .08
        and actual.RightVector:Dot(expected.RightVector) > .999
        and actual.UpVector:Dot(expected.UpVector) > .999
end

local function cosmeticPart(part, owner)
    return part and part:IsA("BasePart") and part.Parent == owner and part.Anchored
        and not part.CanCollide and not part.CanTouch and not part.CanQuery
        and part.LocalTransparencyModifier < .95
        and part:GetAttribute("SceneryLodHidden") ~= true
end

local function nativeFor(building, origin, spec)
    local part = building:FindFirstChild(spec.name)
    if not cosmeticPart(part, building) then return nil end
    local size, frame = part.Size, part.CFrame
    if part:IsA("MeshPart") then
        local expectedAsset = if spec == FOOT
            then HorizonMonumentGeometry.assetId("shaft", building:GetAttribute("FacadeVariantId"))
            else 104654294187035
        if not expectedAsset or part.MeshId == ""
            or part:GetAttribute("Original3DAssetId") ~= expectedAsset then return nil end
        size = Vector3.new(size.Y, size.X, size.Z)
        frame *= CYLINDER
    elseif not part:IsA("Part") or part.Shape ~= Enum.PartType.Cylinder then
        return nil
    end
    if (size - spec.size).Magnitude < .08
        and sameFrame(frame, origin * CFrame.new(0, spec.y, 0) * CYLINDER)
        and (part.Transparency < 1 or (mounted[building] and mounted[building].originals[part])) then
        return part
    end
    return nil
end

local function eligible(building, district)
    if not building:IsA("Model") or building.Parent ~= district
        or building:GetAttribute("ArenaDistrictArchitecture") ~= true
        or building:GetAttribute("SourceIsOriginal") ~= true
        or building:GetAttribute("CosmeticOnly") ~= true
        or building:GetAttribute(FACADE) ~= true or building:GetAttribute(SIDEWALL) ~= true then
        return nil
    end
    local index = building:GetAttribute("DistrictIndex")
    if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > 16 then return nil end
    local door = building:FindFirstChild("ServiceEntryDoor")
    if not cosmeticPart(door, building) or not door:IsA("Part") or door.Transparency >= .7 then return nil end
    local origin = door.CFrame * CFrame.new(.35, -4, 4.36)
    local foot, rim = nativeFor(building, origin, FOOT), nativeFor(building, origin, RIM)
    if not foot or not rim then return nil end
    return door, origin, foot, rim
end

local function mask(entry)
    for part in pairs(entry.originals) do
        if part.Transparency < 1 then
            entry.originals[part] = part.Transparency
            part.Transparency = 1
        end
    end
end

local function axisScale(axis, scale)
    if math.abs(axis.Y) > .9999 then return scale.Y end
    if math.abs(axis.Y) < .0001 then return scale.X end
    return nil
end

local function mount(building, district, door, origin, foot, rim, source)
    local clone = source:Clone()
    if not clone then return end
    local frame, bounds = clone:GetBoundingBox()
    -- Keep the new corners within the native disc's 15.5 x 15.5 bounds.
    -- The broad upper plate reaches the facade pilasters; its top meets
    -- the original rim height at floor +.88.
    local widthFactor = 15.35 / math.max(bounds.X, bounds.Z)
    local scale = Vector3.new(widthFactor, .88 / bounds.Y, widthFactor)
    local target = origin * CFrame.new(0, .44, 0)
    local pieces = clone:GetChildren()
    if #pieces ~= MATERIAL_COUNT then clone:Destroy(); return end
    for _, part in ipairs(pieces) do
        local pose = frame:ToObjectSpace(part.CFrame)
        local x, y, z = axisScale(pose.RightVector, scale),
            axisScale(pose.UpVector, scale), axisScale(pose.LookVector, scale)
        if not x or not y or not z then clone:Destroy(); return end
        part.Size *= Vector3.new(x, y, z)
        part.CFrame = target * CFrame.new(pose.Position * scale) * pose.Rotation
        part.Color = part.Color:Lerp(rim.Color, .24)
        part.CastShadow = false
        part.LocalTransparencyModifier = 0
    end
    clone.Name = "ApprovedOriginalDistrictFoundation3D"
    clone:SetAttribute("DistrictIndex", building:GetAttribute("DistrictIndex"))
    clone.Parent = bucket
    local entry = {
        clone = clone, door = door, origin = origin, foot = foot, rim = rim,
        originals = {[foot] = foot.Transparency, [rim] = rim.Transparency},
        connections = {},
    }
    mounted[building] = entry
    local function drop()
        if mounted[building] == entry then release(building) end
    end
    local function reconcile()
        local currentDoor, currentOrigin, currentFoot, currentRim = eligible(building, district)
        if arenaInUse.Parent ~= workspace:FindFirstChild("GeneratedMap")
            or district.Parent ~= arenaInUse:FindFirstChild("Decor")
            or currentDoor ~= door or currentFoot ~= foot or currentRim ~= rim
            or not sameFrame(currentOrigin, origin) then drop() end
    end
    watch(entry.connections, clone.AncestryChanged, function()
        if clone.Parent ~= bucket then drop() end
    end)
    watch(entry.connections, clone.ChildAdded, drop)
    watch(entry.connections, clone.ChildRemoved, drop)
    for _, part in ipairs(pieces) do
        for _, property in ipairs(MESH_PROPERTIES) do
            watch(entry.connections, part:GetPropertyChangedSignal(property), drop)
        end
        watch(entry.connections, part:GetPropertyChangedSignal("LocalTransparencyModifier"), drop)
    end
    for _, owner in ipairs({building, door, foot, rim}) do
        watch(entry.connections, owner.AncestryChanged, reconcile)
    end
    for _, attribute in ipairs(OWNER_ATTRIBUTES) do
        watch(entry.connections, building:GetAttributeChangedSignal(attribute), reconcile)
    end
    for _, part in ipairs({foot, rim}) do
        watch(entry.connections, part:GetAttributeChangedSignal("SceneryLodHidden"), reconcile)
        if part:IsA("MeshPart") then
            watch(entry.connections, part:GetPropertyChangedSignal("MeshId"), reconcile)
            watch(entry.connections, part:GetAttributeChangedSignal("Original3DAssetId"), reconcile)
        else
            watch(entry.connections, part:GetPropertyChangedSignal("Shape"), reconcile)
        end
        for _, property in ipairs(NATIVE_PROPERTIES) do
            watch(entry.connections, part:GetPropertyChangedSignal(property), reconcile)
        end
    end
    watch(entry.connections, door:GetPropertyChangedSignal("CFrame"), reconcile)
    watch(entry.connections, door:GetPropertyChangedSignal("Transparency"), reconcile)
    watch(entry.connections, door:GetAttributeChangedSignal("SceneryLodHidden"), reconcile)
    mask(entry)
end

function Kit.sync(arena, camera, tier, ready, touch, pressure, look)
    if arena ~= arenaInUse then
        revokeSource()
        arenaInUse = arena
    end
    local generated = workspace:FindFirstChild("GeneratedMap")
    local decor = arena and arena:FindFirstChild("Decor")
    local district = decor and decor:FindFirstChild("ArenaDistrictArchitecture3D")
    if not ready or typeof(camera) ~= "Vector3" or (tonumber(pressure) or 0) >= 1
        or not generated or not arena or arena.Parent ~= generated or arena.Name ~= "Arena"
        or not district or not district:IsA("Folder") then
        revokeSource()
        return
    end
    local source = approved()
    if source ~= sourceInUse then
        revokeSource()
        if source then bindSource(source) end
    end
    if not source then return end
    local budget = BUDGET[tier] or BUDGET.Low
    local cap = if touch then budget.touch else budget.count
    local horizontal = if typeof(look) == "Vector3" then Vector3.new(look.X, 0, look.Z) else Vector3.zero
    local facing = horizontal.Magnitude > .2
    if facing then horizontal = horizontal.Unit end
    local candidates = {}
    for _, building in ipairs(district:GetChildren()) do
        local door, origin, foot, rim = eligible(building, district)
        if door then
            local offset = origin.Position - camera
            local distance = offset.Magnitude
            local retention = if mounted[building] then RETENTION else 0
            if distance <= budget.range + retention then
                local planar = Vector3.new(offset.X, 0, offset.Z)
                local behind = facing and planar.Magnitude > 35 and planar.Unit:Dot(horizontal) < -.15
                local score = distance - retention * .5 + (behind and 65 or 0)
                table.insert(candidates, {building = building, door = door, origin = origin,
                    foot = foot, rim = rim, score = score})
            end
        end
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
        if not item or entry.clone.Parent ~= bucket or entry.door ~= item.door
            or entry.foot ~= item.foot or entry.rim ~= item.rim
            or not sameFrame(entry.origin, item.origin) then release(building) end
    end
    for building, item in pairs(wanted) do
        local entry = mounted[building]
        if entry then
            mask(entry)
        else
            mount(building, district, item.door, item.origin, item.foot, item.rim, source)
        end
    end
end

function Kit.replacedNativeCount()
    local count = 0
    for _, entry in pairs(mounted) do
        for part in pairs(entry.originals) do
            if part.Transparency == 1 then count += 1 end
        end
    end
    return count
end

return Kit
