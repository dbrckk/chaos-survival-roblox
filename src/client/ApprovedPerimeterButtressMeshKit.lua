-- P4: replace the TWO blocky contact-height buttresses on each of the
-- four genuine perimeter stations with authenticated creator-owned 3D.
-- Never replace Base, hazards, collisions, station instructions or lights.
-- Driven only by scenery-lod.client.lua's existing camera/quality sampler.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local APPROVED = {
    Classic = 91626128452597,
    Towers = 107521411452905,
    Crossroads = 93993697329658,
    Orbital = 119010829781313,
    Harbor = 76194593490199,
}
local STATIONS = {"North", "East", "South", "West"}
-- One nearest authentic two-pillar pair at Android Low. The original
-- two native cuboids are hidden only after both owner-verified Models
-- mount. The first pressure tier floors the cap to zero and restores them.
local LIMITS = {Low = 1, Medium = 1, High = 4}
local RANGE = {Low = 150, Medium = 185, High = 275}
local RETENTION = 18

local bucket = Instance.new("Folder")
bucket.Name = "ApprovedPerimeterButtressesLocal"
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
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    for native, alpha in pairs(entry.native) do
        if native.Parent == station and native.Transparency == 1
            and native.Anchored and not native.CanCollide
            and not native.CanTouch and not native.CanQuery then
            native.Transparency = alpha
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
    for _, station in ipairs(keys) do dispose(station) end
end

local function clear()
    removeAll()
    for _, connection in ipairs(baseConnections) do
        connection:Disconnect()
    end
    table.clear(baseConnections)
    watchedBase = nil
    activeArena = nil
    bucket:ClearAllChildren()
end

-- All five variant-specific assets are already moderated/approved and
-- sanitized by PremiumLargeStructureAssets on the authoritative server.
local function sourceFor(variant)
    local approvedId = APPROVED[variant]
    if not approvedId then return nil end
    local holder = ReplicatedStorage:FindFirstChild("ApprovedLargeStructureTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = holder:FindFirstChild(variant)
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalLargeStructure3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= approvedId then
        return nil
    end
    local count = 0
    for _, piece in ipairs(source:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") or piece.CanCollide
                or piece.CanTouch or piece.CanQuery then return nil end
            count += 1
        elseif piece:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 12 then return nil end
    local _, size = source:GetBoundingBox()
    if size.Y < 13.4 or size.Y > 15.1
        or math.min(size.X, size.Z) < 1.5
        or math.min(size.X, size.Z) > 2.7
        or math.max(size.X, size.Z) < 1.6
        or math.max(size.X, size.Z) > 2.8 then return nil end
    return source
end

local function genuineStation(arena, base, decor, station, index)
    if not arena or not base or not decor or not station
        or decor.Parent ~= arena or station.Parent ~= decor
        or not station:IsA("Model")
        or station.Name ~= "PerimeterStation" .. STATIONS[index]
        or station:GetAttribute("ChaosPerimeterStation") ~= true
        or station:GetAttribute("StationIndex") ~= index
        or not base:IsA("BasePart") or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide
        or base.Size.X < 318 or base.Size.Z < 318
        or arena.Parent == nil or arena.Parent.Name ~= "GeneratedMap"
        or arena.Parent.Parent ~= workspace then
        return nil
    end
    local left = station:FindFirstChild("LeftButtress")
    local right = station:FindFirstChild("RightButtress")
    -- An unfinished/late-streamed station must never qualify with only
    -- its left pillar: ipairs would otherwise skip a nil right entry.
    if not left or not right then return nil end
    for _, native in ipairs({left, right}) do
        if not native or not native:IsA("Part")
            or native.Parent ~= station or not native.Anchored
            or native.CanCollide or native.CanTouch or native.CanQuery
            or math.abs(native.Size.X - 1.5) > 0.1
            or math.abs(native.Size.Y - 9) > 0.1
            or math.abs(native.Size.Z - 2) > 0.1 then
            return nil
        end
    end
    return left, right
end

local function fittedClone(source, native, approvedId)
    local clone = source:Clone()
    local _, original = clone:GetBoundingBox()
    -- The approved model is a tall 14-15-stud structural sculpture.
    -- Rotate its shorter source horizontal axis onto the 1.5-stud
    -- native pillar width, then scale uniformly without fake geometry.
    local yaw = original.X <= original.Z and 0 or math.pi * 0.5
    local sourceX = yaw == 0 and original.X or original.Z
    local sourceZ = yaw == 0 and original.Z or original.X
    local scale = math.min(1,
        native.Size.X * 1.08 / sourceX,
        native.Size.Z * 1.06 / sourceZ,
        native.Size.Y * 0.99 / original.Y)
    if scale < 0.52 or not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return nil
    end
    local frame, bounds = clone:GetBoundingBox()
    local width = yaw == 0 and bounds.X or bounds.Z
    local depth = yaw == 0 and bounds.Z or bounds.X
    if width < native.Size.X * 0.72
        or width > native.Size.X * 1.09
        or depth < native.Size.Z * 0.48
        or depth > native.Size.Z * 1.07
        or bounds.Y < native.Size.Y * 0.84
        or bounds.Y > native.Size.Y then
        clone:Destroy()
        return nil
    end
    local target = native.CFrame
        * CFrame.new(0, -native.Size.Y * .5 + bounds.Y * .5, 0)
        * CFrame.Angles(0, yaw, 0)
    local parts = {}
    for _, item in ipairs(clone:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            item.CFrame = target * frame:ToObjectSpace(item.CFrame)
            item.Anchored = true
            item.Massless = true
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = false
            item.CastShadow = false
            item:SetAttribute("CosmeticOnly", true)
            parts[#parts + 1] = item
        end
    end
    if #parts < 1 or #parts > 12 then
        clone:Destroy()
        return nil
    end
    clone.Name = "ApprovedButtress3D_" .. native.Name
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("Original3DAssetId", approvedId)
    return clone, parts
end

local function mount(arena, base, decor, station, index, source, variant)
    local left, right = genuineStation(arena, base, decor, station, index)
    if not left or not right or mounted[station] then return end
    -- Both pillars must succeed before hiding ANY primitive. A partially
    -- available/streamed source never makes a one-sided station.
    local first, firstParts = fittedClone(source, left, APPROVED[variant])
    if not first then return end
    local second, secondParts = fittedClone(source, right, APPROVED[variant])
    if not second then first:Destroy(); return end
    if not genuineStation(arena, base, decor, station, index)
        or not source.Parent then
        first:Destroy()
        second:Destroy()
        return
    end
    local native = {[left] = left.Transparency, [right] = right.Transparency}
    local entry = {
        source = source, models = {first, second},
        parts = {firstParts, secondParts}, native = native,
        connections = {}, index = index, variant = variant,
        frames = {[left] = left.CFrame, [right] = right.CFrame},
    }
    first.Parent = bucket
    second.Parent = bucket
    mounted[station] = entry
    left.Transparency = 1
    right.Transparency = 1
    entry.connections[#entry.connections + 1] =
        station.AncestryChanged:Connect(function()
            if station.Parent ~= decor then dispose(station) end
        end)
    entry.connections[#entry.connections + 1] =
        source.AncestryChanged:Connect(function()
            if not source.Parent then dispose(station) end
        end)
    entry.connections[#entry.connections + 1] =
        source.DescendantRemoving:Connect(function(item)
            if item:IsA("MeshPart") then dispose(station) end
        end)
    for _, model in ipairs(entry.models) do
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
        clear()
        activeArena = arena
    end
    local stress = math.clamp(math.floor(tonumber(pressure) or 0), 0, 2)
    local cap = LIMITS[tier] or 0
    if tier == "High" and touch then cap = 2 end
    if stress == 1 then cap = math.floor(cap * .5) end
    if stress >= 2 then cap = 0 end
    if not cameraReady or typeof(cameraPoint) ~= "Vector3"
        or cap == 0 or not arena or not arena:IsA("Folder") then
        removeAll()
        return
    end
    local base = arena:FindFirstChild("Base")
    local decor = arena:FindFirstChild("Decor")
    local variant = arena:GetAttribute("VariantId")
    if not decor or not decor:IsA("Folder") or not APPROVED[variant]
        or not base or not base:IsA("BasePart")
        or base.Size.X < 318 or base.Size.Z < 318 then
        removeAll()
        return
    end
    if watchedBase ~= base then
        for _, c in ipairs(baseConnections) do c:Disconnect() end
        table.clear(baseConnections)
        watchedBase = base
        local function invalidBase()
            if not base.Parent or not base.CanCollide
                or base.Size.X < 318 or base.Size.Z < 318 then
                removeAll()
            end
        end
        baseConnections[#baseConnections + 1] =
            base:GetPropertyChangedSignal("Size"):Connect(invalidBase)
        baseConnections[#baseConnections + 1] =
            base:GetPropertyChangedSignal("CanCollide"):Connect(invalidBase)
        baseConnections[#baseConnections + 1] =
            base.AncestryChanged:Connect(invalidBase)
    end
    local source = sourceFor(variant)
    if not source then
        removeAll()
        return
    end
    local ranked = {}
    for index, name in ipairs(STATIONS) do
        local station = decor:FindFirstChild("PerimeterStation" .. name)
        local left, right = genuineStation(arena, base, decor, station, index)
        if left and right then
            local distance = (left.Position + right.Position) * .5 - cameraPoint
            local retained = mounted[station] ~= nil
            local score = distance.Magnitude
            if score <= RANGE[tier] + (retained and RETENTION or 0) then
                ranked[#ranked + 1] = {
                    station = station, index = index,
                    score = score - (retained and RETENTION * .6 or 0),
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
            or entry.source ~= source or entry.variant ~= variant
            or not genuineStation(arena, base, decor, station, entry.index)
        if not invalid then
            for native in pairs(entry.native) do
                if native.Parent ~= station
                    or (native.CFrame.Position - entry.frames[native].Position).Magnitude > .08
                    or native.CFrame.LookVector:Dot(entry.frames[native].LookVector) < .999 then
                    invalid = true
                    break
                end
            end
            for i, model in ipairs(entry.models) do
                if model.Parent ~= bucket then invalid = true end
                for _, piece in ipairs(entry.parts[i]) do
                    if not piece:IsDescendantOf(model) then invalid = true end
                end
            end
        end
        if invalid then
            dispose(station)
        else
            -- Other cosmetic owners may have restored the primitive after
            -- a local change. The authentic replacement wins only while safe.
            for native in pairs(entry.native) do
                native.Transparency = 1
            end
        end
    end
    for station, index in pairs(wanted) do
        if not mounted[station] then
            mount(arena, base, decor, station, index, source, variant)
        end
    end
end

function Kit.count()
    local n = 0
    for _, entry in pairs(mounted) do
        if entry.models[1].Parent == bucket
            and entry.models[2].Parent == bucket then
            n += 1
        end
    end
    return n
end

function Kit.replacedNativeCount()
    return Kit.count() * 2
end

return Kit
