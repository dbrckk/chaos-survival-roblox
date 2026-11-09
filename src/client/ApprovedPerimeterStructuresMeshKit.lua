-- 7-MeshPart source-approved original steel truss and generator shield.
-- Real stations only: hide both decorative blocks iff BOTH genuine models
-- fit. Same existing scenery camera sampler; no additional frame loop.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = {}

local IDS = {Brace = 108452611210970, Shield = 113687802206554}
local MODEL_NAMES = {"Brace", "Shield"}
local NATIVE_NAMES = {"CrossBrace", "GeneratorShield"}
local EXPECTED = {
    Brace = Vector3.new(9.1, .65, 1.25),
    Shield = Vector3.new(4.0, .55, 1.4),
}
local SOURCE_BOUNDS = {
    Brace = Vector3.new(8.94, .5675, 1.12),
    Shield = Vector3.new(3.93, .5405, 1.3),
}
local STATIONS = {"North", "East", "South", "West"}
local VARIANTS = {Classic=true,Towers=true,Crossroads=true,
    Orbital=true,Harbor=true}
local CAPS = {Low=0,Medium=1,High=3}
local RANGE = {Low=0,Medium=170,High=245}
local RETENTION = 16

local bucket = Instance.new("Folder")
bucket.Name = "ApprovedPerimeterStructuresLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent = workspace

local activeArena = nil
local mounted = {}
local watchedBase = nil
local baseWatchers = {}

local function dispose(station)
    local entry = mounted[station]
    if not entry then return end
    mounted[station] = nil
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    for native, alpha in pairs(entry.original) do
        if native.Parent == station and native:IsA("Part")
            and native.Anchored and not native.CanCollide
            and not native.CanTouch and not native.CanQuery
            and native.Transparency == 1 then
            native.Transparency = alpha
        end
    end
    for _, model in ipairs(entry.models) do model:Destroy() end
end

local function removeAll()
    local keys = {}
    for station in pairs(mounted) do keys[#keys+1]=station end
    for _, station in ipairs(keys) do dispose(station) end
end

local function clear()
    removeAll()
    for _, c in ipairs(baseWatchers) do c:Disconnect() end
    table.clear(baseWatchers)
    watchedBase = nil
    activeArena = nil
    bucket:ClearAllChildren()
end

local function sourceFor(kind)
    local holder = ReplicatedStorage:FindFirstChild("ApprovedPerimeterStructuresTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = holder:FindFirstChild(kind)
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalPerimeterStructure3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= IDS[kind] then
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
    local _, box = source:GetBoundingBox()
    if math.abs(box.Y - SOURCE_BOUNDS[kind].Y) > .16 then return nil end
    local x,z=math.min(box.X,box.Z),math.max(box.X,box.Z)
    local expect=SOURCE_BOUNDS[kind]
    local sx,sz=math.min(expect.X,expect.Z),math.max(expect.X,expect.Z)
    if math.abs(x-sx)>.22 or math.abs(z-sz)>.30 then return nil end
    return source
end

local function genuineStation(arena, station, index)
    if not arena or not arena:IsA("Folder")
        or not VARIANTS[arena:GetAttribute("VariantId")]
        or not arena.Parent or arena.Parent.Name ~= "GeneratedMap"
        or arena.Parent.Parent ~= workspace
        or not station or not station:IsA("Model")
        or station.Name ~= "PerimeterStation"..STATIONS[index]
        or station:GetAttribute("ChaosPerimeterStation") ~= true
        or station:GetAttribute("StationIndex") ~= index then return nil end
    local base,decor=arena:FindFirstChild("Base"),arena:FindFirstChild("Decor")
    if not base or not base:IsA("BasePart") or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide
        or base.Size.X < 318 or base.Size.Z < 318
        or not decor or not decor:IsA("Folder")
        or decor.Parent ~= arena or station.Parent ~= decor then return nil end
    local natives={}
    -- Explicit iteration over names, not ipairs over an array containing
    -- streamed nils: a partial station must never hide its first cap.
    for i, name in ipairs(NATIVE_NAMES) do
        local native=station:FindFirstChild(name)
        local size=EXPECTED[MODEL_NAMES[i]]
        if not native or not native:IsA("Part")
            or native.Parent ~= station or not native.Anchored
            or native.CanCollide or native.CanTouch or native.CanQuery
            or native.Shape ~= Enum.PartType.Block
            or (native.Size-size).Magnitude > .12 then return nil end
        natives[#natives+1]=native
    end
    return natives
end

local function fit(source, native, kind)
    local clone=source:Clone()
    local _,original=clone:GetBoundingBox()
    -- Genuine imported geometry can swap horizontal axes. Correct yaw only;
    -- NEVER stretch model vertices or deform the approved 3D geometry.
    local nativeSize=native.Size
    local direct=math.abs(original.X-nativeSize.X)
        +math.abs(original.Z-nativeSize.Z)
    local swapped=math.abs(original.Z-nativeSize.X)
        +math.abs(original.X-nativeSize.Z)
    local yaw=direct<=swapped and 0 or math.pi*.5
    local w=yaw==0 and original.X or original.Z
    local d=yaw==0 and original.Z or original.X
    local factor=math.min(1.07,nativeSize.X*.985/w,
        nativeSize.Y*.985/original.Y,nativeSize.Z*.985/d)
    if factor < .72 or not pcall(function() clone:ScaleTo(factor) end) then
        clone:Destroy()
        return nil
    end
    local frame,size=clone:GetBoundingBox()
    w=yaw==0 and size.X or size.Z
    d=yaw==0 and size.Z or size.X
    if w > nativeSize.X*.995 or d > nativeSize.Z*.995
        or size.Y > nativeSize.Y*.995
        or w < nativeSize.X*.82 or d < nativeSize.Z*.82
        or size.Y < nativeSize.Y*.70 then
        clone:Destroy()
        return nil
    end
    local target=native.CFrame*CFrame.Angles(0,yaw,0)
    local parts={}
    for _,piece in ipairs(clone:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            piece.CFrame=target*frame:ToObjectSpace(piece.CFrame)
            piece.Anchored=true
            piece.Massless=true
            piece.CanCollide=false
            piece.CanTouch=false
            piece.CanQuery=false
            piece.CastShadow=false
            piece:SetAttribute("CosmeticOnly",true)
            piece:SetAttribute("Original3DAssetId",IDS[kind])
            parts[#parts+1]=piece
        end
    end
    if #parts~=7 then clone:Destroy();return nil end
    clone.Name="OriginalPerimeterStructure3D_"..native.Name
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",IDS[kind])
    return clone,parts
end

local function mount(arena, station, index, sources)
    if mounted[station] then return end
    local natives=genuineStation(arena,station,index)
    if not natives then return end
    local models,pieceSets={},{}
    for i,native in ipairs(natives) do
        local kind=MODEL_NAMES[i]
        local model,pieces=fit(sources[kind],native,kind)
        if not model then
            for _,old in ipairs(models) do old:Destroy() end
            return
        end
        models[#models+1]=model
        pieceSets[#pieceSets+1]=pieces
    end
    if not genuineStation(arena,station,index)
        or not sources.Brace.Parent or not sources.Shield.Parent then
        for _,model in ipairs(models) do model:Destroy() end
        return
    end
    local entry={
        index=index,models=models,pieces=pieceSets,original={},
        frames={},sources=sources,connections={},
    }
    for _,native in ipairs(natives) do
        entry.original[native]=native.Transparency
        entry.frames[native]=native.CFrame
    end
    for _,model in ipairs(models) do model.Parent=bucket end
    mounted[station]=entry
    for _,native in ipairs(natives) do native.Transparency=1 end

    entry.connections[#entry.connections+1]=
        station.AncestryChanged:Connect(function()
            if station.Parent~=arena:FindFirstChild("Decor") then
                dispose(station)
            end
        end)
    for _,source in pairs(sources) do
        entry.connections[#entry.connections+1]=
            source.AncestryChanged:Connect(function()
                if not source.Parent then dispose(station) end
            end)
        entry.connections[#entry.connections+1]=
            source.DescendantRemoving:Connect(function(item)
                if item:IsA("MeshPart") then dispose(station) end
            end)
    end
    for _,native in ipairs(natives) do
        entry.connections[#entry.connections+1]=
            native.AncestryChanged:Connect(function()
                if native.Parent~=station then dispose(station) end
            end)
    end
    for _,model in ipairs(models) do
        entry.connections[#entry.connections+1]=
            model.DescendantRemoving:Connect(function(item)
                if item:IsA("MeshPart") then dispose(station) end
            end)
    end
end

bucket.ChildRemoved:Connect(function(child)
    for station,entry in pairs(mounted) do
        if table.find(entry.models,child) then
            dispose(station)
            break
        end
    end
end)

function Kit.sync(arena,cameraPoint,tier,cameraReady,touch,pressure)
    if arena~=activeArena then clear();activeArena=arena end
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    local cap=CAPS[tier] or 0
    if tier=="High" and touch then cap=2 end
    if stress==1 then cap=math.floor(cap*.5) end
    if stress>=2 then cap=0 end
    if cap==0 or not cameraReady or typeof(cameraPoint)~="Vector3"
        or not arena or not arena:IsA("Folder") then
        removeAll()
        return
    end
    local base=arena:FindFirstChild("Base")
    local decor=arena:FindFirstChild("Decor")
    if not base or not base:IsA("BasePart")
        or not decor or not decor:IsA("Folder")
        or base.Size.X<318 or base.Size.Z<318
        or not base.Anchored or not base.CanCollide then
        removeAll()
        return
    end
    if watchedBase~=base then
        for _,c in ipairs(baseWatchers) do c:Disconnect() end
        table.clear(baseWatchers)
        watchedBase=base
        local function invalidBase()
            if base.Parent~=arena or not base.Anchored
                or not base.CanCollide or base.Size.X<318
                or base.Size.Z<318 then removeAll() end
        end
        baseWatchers[#baseWatchers+1]=
            base:GetPropertyChangedSignal("Size"):Connect(invalidBase)
        baseWatchers[#baseWatchers+1]=
            base:GetPropertyChangedSignal("CanCollide"):Connect(invalidBase)
        baseWatchers[#baseWatchers+1]=
            base.AncestryChanged:Connect(invalidBase)
    end

    local brace,shield=sourceFor("Brace"),sourceFor("Shield")
    if not brace or not shield then removeAll();return end
    local sources={Brace=brace,Shield=shield}
    local ranked={}
    for index,name in ipairs(STATIONS) do
        local station=decor:FindFirstChild("PerimeterStation"..name)
        local natives=genuineStation(arena,station,index)
        if natives then
            local retained=mounted[station]~=nil
            local distance=(natives[1].Position-cameraPoint).Magnitude
            if distance<=(RANGE[tier] or 0)
                +(retained and RETENTION or 0) then
                ranked[#ranked+1]={
                    station=station,index=index,
                    score=distance-(retained and RETENTION*.6 or 0),
                }
            end
        end
    end
    table.sort(ranked,function(a,b)
        if a.score~=b.score then return a.score<b.score end
        return a.index<b.index
    end)
    local wanted={}
    for i=1,math.min(cap,#ranked) do
        wanted[ranked[i].station]=ranked[i].index
    end
    for station,entry in pairs(mounted) do
        local invalid=wanted[station]~=entry.index
            or entry.sources.Brace~=brace or entry.sources.Shield~=shield
            or not genuineStation(arena,station,entry.index)
        if not invalid then
            for native,frame in pairs(entry.frames) do
                if native.Parent~=station
                    or (native.CFrame.Position-frame.Position).Magnitude>.08
                    or native.CFrame.LookVector:Dot(frame.LookVector)<.999
                    or native.CFrame.UpVector:Dot(frame.UpVector)<.999 then
                    invalid=true
                    break
                end
            end
            for i,model in ipairs(entry.models) do
                if model.Parent~=bucket then invalid=true end
                for _,part in ipairs(entry.pieces[i]) do
                    if not part:IsDescendantOf(model) then invalid=true end
                end
            end
        end
        if invalid then
            dispose(station)
        else
            for native in pairs(entry.original) do native.Transparency=1 end
        end
    end
    for station,index in pairs(wanted) do
        if not mounted[station] then
            mount(arena,station,index,sources)
        end
    end
end

function Kit.count()
    local n=0
    for _,entry in pairs(mounted) do
        if #entry.models==2 and entry.models[1].Parent==bucket
            and entry.models[2].Parent==bucket then n+=1 end
    end
    return n
end

function Kit.replacedNativeCount()
    return Kit.count()*2
end

return Kit
