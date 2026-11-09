-- P4: mount ONLY real creator-approved fan geometry over real nonphysical
-- perimeter turbines. Three complete MeshPart Models, or three native
-- cylinders; no partial station, collision, new loop, hazard or fake ID.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local APPROVED = 133526819668194
local STATIONS = {"North", "East", "South", "West"}
local ARENAS = {
    Classic = true, Towers = true, Crossroads = true,
    Orbital = true, Harbor = true,
}
local NAMES = {"IntakeTurbineL", "IntakeTurbineR", "GeneratorRotor"}
local SIZE = {
    IntakeTurbineL = Vector3.new(2.6, 0.8, 2.6),
    IntakeTurbineR = Vector3.new(2.6, 0.8, 2.6),
    GeneratorRotor = Vector3.new(2.7, 0.9, 2.7),
}
local CAPS = {Low = 0, Medium = 1, High = 3}
local RANGE = {Low = 0, Medium = 170, High = 245}
local HYSTERESIS = 16

local bucket = Instance.new("Folder")
bucket.Name = "ApprovedPerimeterRotorsLocal"
bucket:SetAttribute("CosmeticOnly", true)
bucket.Parent = workspace

local mounted = {}
local activeArena = nil
local watchedBase = nil
local baseConnections = {}

local function dispose(station)
    local entry = mounted[station]
    if not entry then return end
    mounted[station] = nil
    for _, c in ipairs(entry.connections) do c:Disconnect() end
    for native, alpha in pairs(entry.natives) do
        if native.Parent == station and native:IsA("Part")
            and native.Transparency == 1 and native.Anchored
            and not native.CanCollide and not native.CanTouch
            and not native.CanQuery then
            native.Transparency = alpha
        end
    end
    for _, model in ipairs(entry.models) do model:Destroy() end
end

local function removeAll()
    local keys = {}
    for station in pairs(mounted) do
        keys[#keys + 1] = station
    end
    for _, station in ipairs(keys) do dispose(station) end
end

local function clear()
    removeAll()
    for _, c in ipairs(baseConnections) do c:Disconnect() end
    table.clear(baseConnections)
    watchedBase = nil
    activeArena = nil
    bucket:ClearAllChildren()
end

local function sourceFor()
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedPerimeterRotorTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local source = holder:FindFirstChild("Rotor")
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalPerimeterRotor3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= APPROVED then
        return nil
    end
    local count = 0
    for _, item in ipairs(source:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or item.CanCollide
                or item.CanTouch or item.CanQuery then return nil end
            count += 1
        elseif item:IsA("LuaSourceContainer") then return nil end
    end
    if count ~= 7 then return nil end
    local _, size = source:GetBoundingBox()
    local lengths = {size.X, size.Y, size.Z}
    table.sort(lengths)
    if lengths[1] < 0.65 or lengths[1] > 1.15
        or lengths[2] < 2.35 or lengths[2] > 2.95
        or lengths[3] < 2.35 or lengths[3] > 2.95 then
        return nil
    end
    return source
end

local function genuineStation(arena, station, index)
    if not arena or not arena:IsA("Folder")
        or not ARENAS[arena:GetAttribute("VariantId")]
        or not arena.Parent or arena.Parent.Name ~= "GeneratedMap"
        or arena.Parent.Parent ~= workspace
        or not station or not station:IsA("Model")
        or station.Name ~= "PerimeterStation" .. STATIONS[index]
        or station:GetAttribute("ChaosPerimeterStation") ~= true
        or station:GetAttribute("StationIndex") ~= index then
        return nil
    end
    local decor = arena:FindFirstChild("Decor")
    local base = arena:FindFirstChild("Base")
    if not decor or not decor:IsA("Folder") or station.Parent ~= decor
        or not base or not base:IsA("BasePart")
        or base.Parent ~= arena or not base.Anchored
        or not base.CanCollide or base.Size.X < 318
        or base.Size.Z < 318 then return nil end
    -- Besides the three rotors, demand the physical station's authored
    -- machinery core. Streaming an incomplete station must not qualify.
    local core = station:FindFirstChild("CoreHousing")
    if not core or not core:IsA("Part") or not core.Anchored
        or core.CanCollide or core.CanTouch or core.CanQuery
        or (core.Size - Vector3.new(3.2, 3.7, 2.8)).Magnitude > 0.12
        then return nil end
    local natives = {}
    for _, name in ipairs(NAMES) do
        local native = station:FindFirstChild(name)
        if not native or not native:IsA("Part")
            or native.Parent ~= station or not native.Anchored
            or native.CanCollide or native.CanTouch or native.CanQuery
            or native.Shape ~= Enum.PartType.Cylinder
            or (native.Size - SIZE[name]).Magnitude > 0.12 then
            return nil
        end
        natives[#natives + 1] = native
    end
    return natives, base
end

local function fit(source, native)
    local copy = source:Clone()
    local _, original = copy:GetBoundingBox()
    -- A glTF importer may swap the original thin axial dimension to X/Z.
    -- Rotate it onto native local Y before measuring its fitted footprint.
    local rotation = CFrame.identity
    local w, h, d = original.X, original.Y, original.Z
    if original.X < original.Y and original.X < original.Z then
        rotation = CFrame.Angles(0, 0, math.pi * 0.5)
        w, h = original.Y, original.X
    elseif original.Z < original.Y and original.Z < original.X then
        rotation = CFrame.Angles(math.pi * 0.5, 0, 0)
        h, d = original.Z, original.Y
    end
    local scale = math.min(1.08,
        native.Size.X * 0.98 / w,
        native.Size.Y * 0.98 / h,
        native.Size.Z * 0.98 / d)
    if scale < 0.70 or not pcall(function() copy:ScaleTo(scale) end) then
        copy:Destroy()
        return nil
    end
    local frame, scaled = copy:GetBoundingBox()
    local width, height, depth = scaled.X, scaled.Y, scaled.Z
    if rotation ~= CFrame.identity then
        if original.X < original.Y and original.X < original.Z then
            width, height = scaled.Y, scaled.X
        else
            height, depth = scaled.Z, scaled.Y
        end
    end
    if width > native.Size.X * 0.995
        or height > native.Size.Y * 0.995
        or depth > native.Size.Z * 0.995
        or width < native.Size.X * 0.82
        or depth < native.Size.Z * 0.82
        or height < native.Size.Y * 0.67 then
        copy:Destroy()
        return nil
    end
    local target = native.CFrame * rotation
    local parts = {}
    for _, part in ipairs(copy:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                copy:Destroy()
                return nil
            end
            part.CFrame = target * frame:ToObjectSpace(part.CFrame)
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part:SetAttribute("CosmeticOnly", true)
            part:SetAttribute("Original3DAssetId", APPROVED)
            parts[#parts + 1] = part
        end
    end
    if #parts ~= 7 then
        copy:Destroy()
        return nil
    end
    copy.Name = "OriginalRotor3D_" .. native.Name
    copy:SetAttribute("CosmeticOnly", true)
    copy:SetAttribute("Original3DAssetId", APPROVED)
    return copy, parts
end

local function mount(arena, station, index, source)
    if mounted[station] then return end
    local natives = genuineStation(arena, station, index)
    if not natives then return end
    local models, parts = {}, {}
    -- All three original 3D assemblies must pass before ANY cylinder hides.
    for _, native in ipairs(natives) do
        local model, pieces = fit(source, native)
        if not model then
            for _, old in ipairs(models) do old:Destroy() end
            return
        end
        models[#models + 1] = model
        parts[#parts + 1] = pieces
    end
    if not genuineStation(arena, station, index) or not source.Parent then
        for _, model in ipairs(models) do model:Destroy() end
        return
    end
    local entry = {
        index = index, source = source, models = models,
        pieces = parts, frames = {}, natives = {}, connections = {},
    }
    for _, native in ipairs(natives) do
        entry.natives[native] = native.Transparency
        entry.frames[native] = native.CFrame
    end
    for _, model in ipairs(models) do model.Parent = bucket end
    mounted[station] = entry
    for _, native in ipairs(natives) do native.Transparency = 1 end
    entry.connections[#entry.connections + 1] =
        station.AncestryChanged:Connect(function()
            if station.Parent ~= arena:FindFirstChild("Decor") then
                dispose(station)
            end
        end)
    entry.connections[#entry.connections + 1] =
        source.AncestryChanged:Connect(function()
            if not source.Parent then dispose(station) end
        end)
    entry.connections[#entry.connections + 1] =
        source.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then dispose(station) end
        end)
    for _, native in ipairs(natives) do
        entry.connections[#entry.connections + 1] =
            native.AncestryChanged:Connect(function()
                if native.Parent ~= station then dispose(station) end
            end)
    end
    for _, model in ipairs(models) do
        entry.connections[#entry.connections + 1] =
            model.DescendantRemoving:Connect(function(part)
                if part:IsA("MeshPart") then dispose(station) end
            end)
    end
end

bucket.ChildRemoved:Connect(function(child)
    for station, entry in pairs(mounted) do
        if table.find(entry.models, child) then
            dispose(station)
            break
        end
    end
end)

function Kit.sync(arena, cameraPoint, tier, cameraReady, touch, pressure)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local stress = math.clamp(math.floor(tonumber(pressure) or 0), 0, 2)
    local cap = CAPS[tier] or 0
    if tier == "High" and touch then cap = 2 end
    if stress == 1 then cap = math.floor(cap * .5) end
    if stress >= 2 then cap = 0 end
    if cap == 0 or not cameraReady or typeof(cameraPoint) ~= "Vector3"
        or not arena or not arena:IsA("Folder") then
        removeAll()
        return
    end
    local base = arena:FindFirstChild("Base")
    local decor = arena:FindFirstChild("Decor")
    if not base or not base:IsA("BasePart")
        or not decor or not decor:IsA("Folder")
        or base.Size.X < 318 or base.Size.Z < 318
        or not base.Anchored or not base.CanCollide then
        removeAll()
        return
    end
    if watchedBase ~= base then
        for _, c in ipairs(baseConnections) do c:Disconnect() end
        table.clear(baseConnections)
        watchedBase = base
        local function validateBase()
            if base.Parent ~= arena or not base.Anchored
                or not base.CanCollide or base.Size.X < 318
                or base.Size.Z < 318 then
                removeAll()
            end
        end
        baseConnections[#baseConnections + 1] =
            base:GetPropertyChangedSignal("Size"):Connect(validateBase)
        baseConnections[#baseConnections + 1] =
            base:GetPropertyChangedSignal("CanCollide"):Connect(validateBase)
        baseConnections[#baseConnections + 1] =
            base.AncestryChanged:Connect(validateBase)
    end
    local source = sourceFor()
    if not source then removeAll(); return end
    local ranked = {}
    for index, name in ipairs(STATIONS) do
        local station = decor:FindFirstChild("PerimeterStation" .. name)
        local natives = genuineStation(arena, station, index)
        if natives then
            local retained = mounted[station] ~= nil
            local distance = (natives[3].Position - cameraPoint).Magnitude
            if distance <= (RANGE[tier] or 0)
                + (retained and HYSTERESIS or 0) then
                ranked[#ranked + 1] = {
                    station = station,
                    index = index,
                    score = distance - (retained and HYSTERESIS * .6 or 0),
                }
            end
        end
    end
    table.sort(ranked, function(a, b)
        if a.score ~= b.score then return a.score < b.score end
        return a.index < b.index
    end)
    local wanted = {}
    for i = 1, math.min(cap, #ranked) do
        wanted[ranked[i].station] = ranked[i].index
    end
    for station, entry in pairs(mounted) do
        local invalid = wanted[station] ~= entry.index
            or source ~= entry.source
            or not genuineStation(arena, station, entry.index)
        if not invalid then
            for native, frame in pairs(entry.frames) do
                if native.Parent ~= station or
                    (native.CFrame.Position - frame.Position).Magnitude > .08
                    or native.CFrame.LookVector:Dot(frame.LookVector) < .999
                    or native.CFrame.UpVector:Dot(frame.UpVector) < .999 then
                    invalid = true
                    break
                end
            end
            for i, model in ipairs(entry.models) do
                if model.Parent ~= bucket then invalid = true end
                for _, part in ipairs(entry.pieces[i]) do
                    if not part:IsDescendantOf(model) then invalid = true end
                end
            end
        end
        if invalid then
            dispose(station)
        else
            for native in pairs(entry.natives) do native.Transparency = 1 end
        end
    end
    for station, index in pairs(wanted) do
        if not mounted[station] then mount(arena, station, index, source) end
    end
end

function Kit.count()
    local stations = 0
    for _, entry in pairs(mounted) do
        if entry.models[1].Parent == bucket
            and entry.models[2].Parent == bucket
            and entry.models[3].Parent == bucket then
            stations += 1
        end
    end
    return stations
end

function Kit.replacedNativeCount()
    return Kit.count() * 3
end

return Kit
