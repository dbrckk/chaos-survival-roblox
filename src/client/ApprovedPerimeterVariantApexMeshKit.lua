-- Real creator-approved 3D topology per arena: four distinct 7-mesh
-- sources mask ONLY the two native variant-specific apex shapes together.
-- Works on four genuine map stations; no server collider or new frame loop.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = {}

local SPECS = {
    Towers = {
        kind = "Towers", id = 131413152501235,
        size = Vector3.new(2.14,8.043,1.72),
        union = Vector3.new(2.2,8.1,1.8),
        first = "ServiceMast", firstSize = Vector3.new(.75,6.8,.75),
        firstShape = Enum.PartType.Block, second = "SignalCrown",
        secondSize = Vector3.new(2.2,1.4,1.8), secondWedge = true,
        separation = 4.0, centerShift = .65,
    },
    Orbital = {
        kind = "Orbital", id = 131188899020391,
        size = Vector3.new(3.356,3.92,3.356),
        union = Vector3.new(3.4,3.975,3.4),
        first = "ReceiverDish", firstSize = Vector3.new(3.4,.65,3.4),
        firstShape = Enum.PartType.Cylinder, second = "ReceiverAntenna",
        secondSize = Vector3.new(.38,3.4,.38), secondWedge = false,
        separation = 1.95, centerShift = 1.6625,
    },
    Crossroads = {
        kind = "Crossroads", id = 134533469777794,
        size = Vector3.new(2.41,3.11,8.36),
        union = Vector3.new(2.5,3.175,8.5),
        first = "ExchangeBeam", firstSize = Vector3.new(2.5,.75,8.5),
        firstShape = Enum.PartType.Block, second = "SwitchyardMarker",
        secondSize = Vector3.new(1.5,2,2), secondWedge = true,
        separation = 1.8, centerShift = 1.2125,
    },
    Relay = {
        kind = "Relay", id = 110237986522853,
        size = Vector3.new(2.26,6.0595,1.89),
        union = Vector3.new(2.4,6.1,2),
        first = "RelaySpire", firstSize = Vector3.new(.7,4.4,.7),
        firstShape = Enum.PartType.Block, second = "RelayCrown",
        secondSize = Vector3.new(2.4,1.6,2), secondWedge = true,
        separation = 3.1, centerShift = .85,
    },
}
local VARIANTS = {
    Classic = SPECS.Relay, Harbor = SPECS.Relay,
    Towers = SPECS.Towers, Orbital = SPECS.Orbital,
    Crossroads = SPECS.Crossroads,
}
local STATIONS = {"North","East","South","West"}
local CAPS = {Low=0,Medium=1,High=3}
local RANGE = {Low=0,Medium=170,High=245}
local RETENTION = 16

local bucket = Instance.new("Folder")
bucket.Name = "ApprovedPerimeterVariantApexLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent = workspace

local mounted = {}
local activeArena = nil
local watchedBase = nil
local watchers = {}

local function dispose(station)
    local entry = mounted[station]
    if not entry then return end
    mounted[station] = nil
    for _, c in ipairs(entry.connections) do c:Disconnect() end
    for native, alpha in pairs(entry.original) do
        if native.Parent == station and native.Anchored
            and not native.CanCollide and not native.CanTouch
            and not native.CanQuery and native.Transparency == 1 then
            native.Transparency = alpha
        end
    end
    entry.model:Destroy()
end

local function removeAll()
    local keys = {}
    for station in pairs(mounted) do keys[#keys+1] = station end
    for _, station in ipairs(keys) do dispose(station) end
end

local function clear()
    removeAll()
    for _, c in ipairs(watchers) do c:Disconnect() end
    table.clear(watchers)
    watchedBase = nil
    activeArena = nil
    bucket:ClearAllChildren()
end

local function sourceFor(spec)
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedPerimeterVariantApexTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = holder:FindFirstChild(spec.kind)
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalPerimeterVariantApex3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= spec.id then
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
    local x,z = math.min(size.X,size.Z),math.max(size.X,size.Z)
    local a,b = math.min(spec.size.X,spec.size.Z),
        math.max(spec.size.X,spec.size.Z)
    if math.abs(size.Y-spec.size.Y)>.30
        or math.abs(x-a)>.28 or math.abs(z-b)>.30 then return nil end
    return source
end

local function nativePair(arena, station, index, spec)
    if not arena or not arena:IsA("Folder")
        or VARIANTS[arena:GetAttribute("VariantId")] ~= spec
        or not arena.Parent or arena.Parent.Name ~= "GeneratedMap"
        or arena.Parent.Parent ~= workspace
        or not station or not station:IsA("Model")
        or station.Name ~= "PerimeterStation"..STATIONS[index]
        or station:GetAttribute("ChaosPerimeterStation") ~= true
        or station:GetAttribute("StationIndex") ~= index then return nil end
    local decor = arena:FindFirstChild("Decor")
    local base = arena:FindFirstChild("Base")
    if not decor or not decor:IsA("Folder")
        or decor.Parent ~= arena or station.Parent ~= decor
        or not base or not base:IsA("BasePart")
        or base.Parent ~= arena or not base.Anchored
        or not base.CanCollide or base.Size.X < 318
        or base.Size.Z < 318 then return nil end
    local core = station:FindFirstChild("CoreHousing")
    if not core or not core:IsA("Part") or core.Parent ~= station
        or not core.Anchored or core.CanCollide or core.CanTouch
        or core.CanQuery
        or (core.Size-Vector3.new(3.2,3.7,2.8)).Magnitude>.12 then
        return nil
    end
    local first = station:FindFirstChild(spec.first)
    local second = station:FindFirstChild(spec.second)
    if not first or not first:IsA("Part") or first.Parent ~= station
        or not first.Anchored or first.CanCollide or first.CanTouch
        or first.CanQuery or first.Shape ~= spec.firstShape
        or (first.Size-spec.firstSize).Magnitude > .12 then return nil end
    if not second or not second:IsA("BasePart")
        or second.Parent ~= station or not second.Anchored or second.CanCollide or second.CanTouch
        or second.CanQuery or
        (second.Size-spec.secondSize).Magnitude>.12 then return nil end
    if spec.secondWedge then
        if not second:IsA("WedgePart") then return nil end
    elseif not second:IsA("Part")
        or second.Shape ~= Enum.PartType.Block then
        return nil
    end
    -- Exact two-item authored station geometry, not merely same-named
    -- random scenery or partially streamed components.
    local localDelta = first.CFrame:PointToObjectSpace(second.Position)
    if (localDelta-Vector3.new(0,spec.separation,0)).Magnitude>.15
        or first.CFrame.LookVector:Dot(second.CFrame.LookVector)<.999
        or first.CFrame.UpVector:Dot(second.CFrame.UpVector)<.999 then
        return nil
    end
    return first,second
end

local function fit(source, spec, first)
    local model = source:Clone()
    local _, bounds = model:GetBoundingBox()
    local u=spec.union
    local direct=math.abs(bounds.X-u.X)+math.abs(bounds.Z-u.Z)
    local swapped=math.abs(bounds.Z-u.X)+math.abs(bounds.X-u.Z)
    local yaw=direct<=swapped and 0 or math.pi*.5
    local width=yaw==0 and bounds.X or bounds.Z
    local depth=yaw==0 and bounds.Z or bounds.X
    local factor=math.min(1.045,u.X*.985/width,
        u.Y*.985/bounds.Y,u.Z*.985/depth)
    if factor < .70 or not pcall(function() model:ScaleTo(factor) end) then
        model:Destroy()
        return nil
    end
    local frame,scaled=model:GetBoundingBox()
    width=yaw==0 and scaled.X or scaled.Z
    depth=yaw==0 and scaled.Z or scaled.X
    if width > u.X*.996 or depth > u.Z*.996 or scaled.Y>u.Y*.996
        or width < u.X*.78 or depth < u.Z*.78
        or scaled.Y < u.Y*.81 then
        model:Destroy()
        return nil
    end
    local target=first.CFrame*CFrame.new(0,spec.centerShift,0)
        *CFrame.Angles(0,yaw,0)
    local pieces={}
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then model:Destroy();return nil end
            part.CFrame = target * frame:ToObjectSpace(part.CFrame)
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part:SetAttribute("CosmeticOnly",true)
            part:SetAttribute("Original3DAssetId",spec.id)
            pieces[#pieces+1] = part
        end
    end
    if #pieces ~= 7 then model:Destroy();return nil end
    model.Name = "ApprovedVariantApex3D_"..spec.kind
    model:SetAttribute("CosmeticOnly",true)
    model:SetAttribute("Original3DAssetId",spec.id)
    return model,pieces
end

local function mount(arena,station,index,spec,source)
    if mounted[station] then return end
    local first,second=nativePair(arena,station,index,spec)
    if not first or not second then return end
    local model,pieces=fit(source,spec,first)
    if not model then return end
    if not nativePair(arena,station,index,spec)
        or not source.Parent then model:Destroy();return end
    local entry={
        model=model,pieces=pieces,index=index,spec=spec,source=source,
        originals={first,second},original={},frames={},connections={},
    }
    for _,native in ipairs(entry.originals) do
        entry.original[native]=native.Transparency
        entry.frames[native]=native.CFrame
    end
    model.Parent=bucket
    mounted[station]=entry
    for _,native in ipairs(entry.originals) do native.Transparency=1 end
    entry.connections[#entry.connections+1]=
        station.AncestryChanged:Connect(function()
            if station.Parent~=arena:FindFirstChild("Decor") then
                dispose(station)
            end
        end)
    entry.connections[#entry.connections+1]=
        source.AncestryChanged:Connect(function()
            if not source.Parent then dispose(station) end
        end)
    entry.connections[#entry.connections+1]=
        source.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then dispose(station) end
        end)
    entry.connections[#entry.connections+1]=
        model.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then dispose(station) end
        end)
    for _,native in ipairs(entry.originals) do
        entry.connections[#entry.connections+1]=
            native.AncestryChanged:Connect(function()
                if native.Parent~=station then dispose(station) end
            end)
    end
end

bucket.ChildRemoved:Connect(function(child)
    for station,entry in pairs(mounted) do
        if entry.model==child then dispose(station);break end
    end
end)

function Kit.sync(arena,cameraPoint,tier,cameraReady,touch,pressure)
    if arena~=activeArena then clear();activeArena=arena end
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    local limit=CAPS[tier] or 0
    if tier=="High" and touch then limit=2 end
    if stress==1 then limit=math.floor(limit*.5) end
    if stress>=2 then limit=0 end
    if limit==0 or not cameraReady or typeof(cameraPoint)~="Vector3"
        or not arena or not arena:IsA("Folder") then
        removeAll()
        return
    end
    local spec=VARIANTS[arena:GetAttribute("VariantId")]
    if not spec then removeAll();return end
    local source=sourceFor(spec)
    if not source then removeAll();return end
    local decor=arena:FindFirstChild("Decor")
    local base=arena:FindFirstChild("Base")
    if not decor or not decor:IsA("Folder")
        or not base or not base:IsA("BasePart")
        or not base.Anchored or not base.CanCollide
        or base.Size.X<318 or base.Size.Z<318 then
        removeAll()
        return
    end
    if watchedBase~=base then
        for _,c in ipairs(watchers) do c:Disconnect() end
        table.clear(watchers)
        watchedBase=base
        local function validateBase()
            if base.Parent~=arena or not base.Anchored
                or not base.CanCollide or base.Size.X<318
                or base.Size.Z<318 then removeAll() end
        end
        watchers[#watchers+1]=base:GetPropertyChangedSignal("Size"):Connect(validateBase)
        watchers[#watchers+1]=base:GetPropertyChangedSignal("CanCollide"):Connect(validateBase)
        watchers[#watchers+1]=base.AncestryChanged:Connect(validateBase)
    end
    local ranked={}
    for index,name in ipairs(STATIONS) do
        local station=decor:FindFirstChild("PerimeterStation"..name)
        local first=nativePair(arena,station,index,spec)
        if first then
            local existing=mounted[station]~=nil
            local distance=(first.Position-cameraPoint).Magnitude
            if distance<=(RANGE[tier] or 0)
                +(existing and RETENTION or 0) then
                ranked[#ranked+1]={
                    station=station,index=index,
                    score=distance-(existing and RETENTION*.6 or 0),
                }
            end
        end
    end
    table.sort(ranked,function(a,b)
        if a.score~=b.score then return a.score<b.score end
        return a.index<b.index
    end)
    local wanted={}
    for i=1,math.min(limit,#ranked) do
        wanted[ranked[i].station]=ranked[i].index
    end
    for station,entry in pairs(mounted) do
        local bad=wanted[station]~=entry.index or entry.spec~=spec
            or entry.source~=source
            or not nativePair(arena,station,entry.index,spec)
            or entry.model.Parent~=bucket
        if not bad then
            for native,restFrame in pairs(entry.frames) do
                if native.Parent~=station or
                    (native.CFrame.Position-restFrame.Position).Magnitude>.08
                    or native.CFrame.LookVector:Dot(restFrame.LookVector)<.999
                    or native.CFrame.UpVector:Dot(restFrame.UpVector)<.999 then
                    bad=true
                    break
                end
            end
            for _,part in ipairs(entry.pieces) do
                if not part:IsDescendantOf(entry.model) then bad=true end
            end
        end
        if bad then
            dispose(station)
        else
            for native in pairs(entry.original) do native.Transparency=1 end
        end
    end
    for station,index in pairs(wanted) do
        if not mounted[station] then mount(arena,station,index,spec,source) end
    end
end

function Kit.count()
    local n=0
    for _,entry in pairs(mounted) do
        if entry.model.Parent==bucket and #entry.pieces==7 then n+=1 end
    end
    return n
end

function Kit.replacedNativeCount()
    return Kit.count()*2
end

return Kit
