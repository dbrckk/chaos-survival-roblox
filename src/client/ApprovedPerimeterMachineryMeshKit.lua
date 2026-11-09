-- P4: source-authenticated mechanical housings on the four REAL perimeter
-- stations of every arena. Only the three server-authored cosmetic cuboids
-- are hidden, and only after all three approved 3D sculptures are mounted.
-- The lens, intake rotors, signage, data rails, warnings and floor remain.
-- Called by the existing scenery-lod camera/pressure sampler; no new loop.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local STATIONS = {"North", "East", "South", "West"}
local IDS = {Core = 127295681925871, Pod = 106083832432833}
local NAMES = {Core = "Orbital", Pod = "Towers"}
local VARIANTS = {
    Classic = true, Towers = true, Crossroads = true,
    Orbital = true, Harbor = true,
}
local CAPS = {Low = 0, Medium = 1, High = 3}
local DISTANCE = {Low = 0, Medium = 170, High = 245}
local RETAIN = 16
local EXPECTED = {
    CoreHousing = Vector3.new(3.2, 3.7, 2.8),
    CompressorPodL = Vector3.new(3.7, 3.1, 4.6),
    CompressorPodR = Vector3.new(3.7, 3.1, 4.6),
}
local PARTS = {"CoreHousing", "CompressorPodL", "CompressorPodR"}

local bucket = Instance.new("Folder")
bucket.Name = "ApprovedPerimeterMachineryLocal"
bucket:SetAttribute("CosmeticOnly", true)
bucket.Parent = workspace

local mounted = {}
local activeArena = nil

local function dispose(station)
    local entry = mounted[station]
    if not entry then return end
    mounted[station] = nil
    for _, signal in ipairs(entry.connections) do
        signal:Disconnect()
    end
    -- Restore only the exact genuine native pieces still present; never
    -- override a different native owner after a model/arena replacement.
    for native, originalAlpha in pairs(entry.native) do
        if native.Parent == station and native.Transparency == 1
            and native:IsA("Part") and native.Anchored
            and not native.CanCollide and not native.CanTouch
            and not native.CanQuery then
            native.Transparency = originalAlpha
        end
    end
    for _, model in ipairs(entry.models) do
        model:Destroy()
    end
end

local function removeAll()
    local keys = {}
    for station in pairs(mounted) do
        keys[#keys + 1] = station
    end
    for _, station in ipairs(keys) do
        dispose(station)
    end
end

local function sourceFor(kind)
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedServiceEquipmentTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = holder:FindFirstChild(NAMES[kind])
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalService3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= IDS[kind] then
        return nil
    end
    local count = 0
    for _, item in ipairs(source:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or item.CanCollide
                or item.CanTouch or item.CanQuery then return nil end
            count += 1
        elseif item:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 12 then return nil end
    local _, bounds = source:GetBoundingBox()
    if math.min(bounds.X, bounds.Y, bounds.Z) < 0.65
        or math.max(bounds.X, bounds.Y, bounds.Z) > 6 then return nil end
    return source
end

local function nativePieces(arena, station, index)
    if not arena or not arena:IsA("Folder")
        or not VARIANTS[arena:GetAttribute("VariantId")]
        or not arena.Parent or arena.Parent.Name ~= "GeneratedMap"
        or arena.Parent.Parent ~= workspace
        or not station or not station:IsA("Model")
        or station.Name ~= "PerimeterStation" .. STATIONS[index]
        or station:GetAttribute("ChaosPerimeterStation") ~= true
        or station:GetAttribute("StationIndex") ~= index then return nil end
    local decor = arena:FindFirstChild("Decor")
    local base = arena:FindFirstChild("Base")
    if not decor or not decor:IsA("Folder") or decor.Parent ~= arena
        or station.Parent ~= decor
        or not base or not base:IsA("BasePart")
        or base.Parent ~= arena or not base.Anchored
        or not base.CanCollide or base.Size.X < 318
        or base.Size.Z < 318 then return nil end
    local natives = {}
    -- Explicit indexed loop: ipairs({core, left, right}) could silently
    -- accept a partially streamed station with a nil third member.
    for _, name in ipairs(PARTS) do
        local part = station:FindFirstChild(name)
        local size = EXPECTED[name]
        if not part or not part:IsA("Part") or part.Parent ~= station
            or not part.Anchored or part.CanCollide or part.CanTouch
            or part.CanQuery
            or (part.Size - size).Magnitude > 0.12 then return nil end
        natives[#natives + 1] = part
    end
    return natives
end

local function fit(source, native, kind)
    local model = source:Clone()
    local _, size = model:GetBoundingBox()
    -- A matching sculpture is scaled uniformly inside the ORIGINAL
    -- cosmetic machinery envelope, not stretched into a fake box.
    local factor = math.min(1.20,
        native.Size.X * 0.96 / size.X,
        native.Size.Y * 0.96 / size.Y,
        native.Size.Z * 0.96 / size.Z)
    if factor < 0.70 or not pcall(function() model:ScaleTo(factor) end) then
        model:Destroy()
        return nil
    end
    local originalFrame, bounds = model:GetBoundingBox()
    if bounds.X > native.Size.X * 0.99
        or bounds.Y > native.Size.Y * 0.99
        or bounds.Z > native.Size.Z * 0.99
        or bounds.Y < native.Size.Y * 0.52
        or bounds.X < native.Size.X * 0.44
        or bounds.Z < native.Size.Z * (kind == "Core" and 0.45 or 0.50) then
        model:Destroy()
        return nil
    end
    local target = native.CFrame
        * CFrame.new(0, -native.Size.Y * 0.5 + bounds.Y * 0.5, 0)
    local pieces = {}
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then
                model:Destroy()
                return nil
            end
            item.CFrame = target * originalFrame:ToObjectSpace(item.CFrame)
            item.Anchored = true
            item.Massless = true
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = false
            item.CastShadow = false
            item:SetAttribute("CosmeticOnly", true)
            item:SetAttribute("Original3DAssetId", IDS[kind])
            pieces[#pieces + 1] = item
        end
    end
    if #pieces < 1 or #pieces > 12 then
        model:Destroy()
        return nil
    end
    model.Name = "ApprovedMachinery3D_" .. native.Name
    model:SetAttribute("CosmeticOnly", true)
    model:SetAttribute("Original3DAssetId", IDS[kind])
    return model, pieces
end

local function mount(arena, station, index, sources)
    if mounted[station] then return end
    local natives = nativePieces(arena, station, index)
    if not natives then return end
    local models, pieceSets = {}, {}
    -- No native Part may disappear until all THREE 3D replacements pass.
    for i, native in ipairs(natives) do
        local kind = i == 1 and "Core" or "Pod"
        local model, pieces = fit(sources[kind], native, kind)
        if not model then
            for _, prior in ipairs(models) do prior:Destroy() end
            return
        end
        models[#models + 1] = model
        pieceSets[#pieceSets + 1] = pieces
    end
    if not nativePieces(arena, station, index)
        or not sources.Core.Parent or not sources.Pod.Parent then
        for _, model in ipairs(models) do model:Destroy() end
        return
    end
    local entry = {
        index = index, native = {}, frames = {},
        models = models, pieces = pieceSets, sources = sources,
        connections = {},
    }
    for _, native in ipairs(natives) do
        entry.native[native] = native.Transparency
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
    for _, source in pairs(sources) do
        entry.connections[#entry.connections + 1] =
            source.AncestryChanged:Connect(function()
                if not source.Parent then dispose(station) end
            end)
        entry.connections[#entry.connections + 1] =
            source.DescendantRemoving:Connect(function(item)
                if item:IsA("MeshPart") then dispose(station) end
            end)
    end
    for _, model in ipairs(models) do
        entry.connections[#entry.connections + 1] =
            model.DescendantRemoving:Connect(function(item)
                if item:IsA("MeshPart") then dispose(station) end
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
        removeAll()
        activeArena = arena
    end
    local stress = math.clamp(math.floor(tonumber(pressure) or 0), 0, 2)
    local cap = CAPS[tier] or 0
    if tier == "High" and touch then cap = 2 end
    if stress == 1 then cap = math.floor(cap * 0.5) end
    if stress == 2 then cap = 0 end
    if cap == 0 or not cameraReady or typeof(cameraPoint) ~= "Vector3"
        or not arena or not arena:IsA("Folder") then
        removeAll()
        return
    end
    local core, pod = sourceFor("Core"), sourceFor("Pod")
    if not core or not pod then
        removeAll()
        return
    end
    local sources = {Core = core, Pod = pod}
    local decor = arena:FindFirstChild("Decor")
    if not decor or not decor:IsA("Folder") then
        removeAll()
        return
    end
    local ranked = {}
    for index, name in ipairs(STATIONS) do
        local station = decor:FindFirstChild("PerimeterStation" .. name)
        local natives = nativePieces(arena, station, index)
        if natives then
            local distance = (natives[1].Position - cameraPoint).Magnitude
            local retained = mounted[station] ~= nil
            if distance <= (DISTANCE[tier] or 0)
                + (retained and RETAIN or 0) then
                ranked[#ranked + 1] = {
                    station = station, index = index,
                    score = distance - (retained and RETAIN * 0.6 or 0),
                }
            end
        end
    end
    table.sort(ranked, function(a, b)
        if a.score ~= b.score then return a.score < b.score end
        return a.index < b.index
    end)
    local wanted = {}
    for i = 1, math.min(#ranked, cap) do
        wanted[ranked[i].station] = ranked[i].index
    end
    for station, entry in pairs(mounted) do
        local bad = wanted[station] ~= entry.index
            or entry.sources.Core ~= core or entry.sources.Pod ~= pod
            or not nativePieces(arena, station, entry.index)
        if not bad then
            for native in pairs(entry.native) do
                local old = entry.frames[native]
                if native.Parent ~= station
                    or (native.CFrame.Position - old.Position).Magnitude > 0.08
                    or native.CFrame.LookVector:Dot(old.LookVector) < 0.999
                    or native.CFrame.UpVector:Dot(old.UpVector) < 0.999 then
                    bad = true
                    break
                end
            end
            for i, model in ipairs(entry.models) do
                if model.Parent ~= bucket then bad = true end
                for _, part in ipairs(entry.pieces[i]) do
                    if not part:IsDescendantOf(model) then bad = true end
                end
            end
        end
        if bad then
            dispose(station)
        else
            for native in pairs(entry.native) do
                native.Transparency = 1
            end
        end
    end
    for station, index in pairs(wanted) do
        if not mounted[station] then
            mount(arena, station, index, sources)
        end
    end
end

function Kit.count()
    local n = 0
    for _, entry in pairs(mounted) do
        if entry.models[1].Parent == bucket
            and entry.models[2].Parent == bucket
            and entry.models[3].Parent == bucket then
            n += 1
        end
    end
    return n
end

function Kit.replacedNativeCount()
    return Kit.count() * 3
end

return Kit
