-- Source-approved 7-MeshPart industrial cap/wing art on REAL perimeter
-- stations. Four native WedgeParts are hidden only after all four genuine
-- Models are assembled. Driven by existing scenery-lod; no extra timer.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = {}

local IDS = {Cap = 88962643359267, Wing = 138096293972093}
local MODEL_NAMES = {"Cap", "Cap", "Wing", "Wing"}
local NATIVE_NAMES = {
    "LeftAngledCap", "RightAngledCap",
    "AngledServiceWingL", "AngledServiceWingR",
}
local EXPECTED = {
    Cap = Vector3.new(2.9, 2.2, 2.4),
    Wing = Vector3.new(3.4, 1.7, 5.7),
}
local SOURCE_BOUNDS = {
    Cap = Vector3.new(2.7699, 2.14, 2.34),
    Wing = Vector3.new(3.277, 1.64, 5.62),
}
local STATIONS = {"North", "East", "South", "West"}
local VARIANTS = {Classic=true,Towers=true,Crossroads=true,
    Orbital=true,Harbor=true}
-- Low purchases only TWO large service wings (2 x 7 approved MeshParts),
-- never the two small top caps: full four-piece station art costs 28
-- MeshParts and remains a Medium/High privilege. Both wing models must
-- mount completely before either original WedgePart is masked.
local CAPS = {Low=1,Medium=1,High=3}
local RANGE = {Low=105,Medium=170,High=245}
local RETENTION = 16

local bucket = Instance.new("Folder")
bucket.Name = "ApprovedPerimeterArmorLocal"
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
        if native.Parent == station and native:IsA("WedgePart")
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
    local holder = ReplicatedStorage:FindFirstChild("ApprovedPerimeterArmorTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = holder:FindFirstChild(kind)
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalPerimeterArmor3D") ~= true
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
    if math.abs(box.Y - SOURCE_BOUNDS[kind].Y) > .32 then return nil end
    local x,z=math.min(box.X,box.Z),math.max(box.X,box.Z)
    local expect=SOURCE_BOUNDS[kind]
    local sx,sz=math.min(expect.X,expect.Z),math.max(expect.X,expect.Z)
    if math.abs(x-sx)>.30 or math.abs(z-sz)>.32 then return nil end
    return source
end

-- The four perimeter stations remain fixed outside the contracting playable
-- floor. Verify the builder-signed ORIGINAL arena footprint, not the live
-- Shrinking Arena size; still reject fake expansion, missing map authority
-- and any unanchored/noncollidable gameplay base.
local function authenticBase(base, arena)
    if not base or not base:IsA("BasePart")
        or not arena or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide then return false end
    local sx = base:GetAttribute("OriginalSizeX")
    local sz = base:GetAttribute("OriginalSizeZ")
    return typeof(sx) == "number" and typeof(sz) == "number"
        and sx >= 318 and sz >= 318
        and base.Size.X > 0 and base.Size.Z > 0
        and base.Size.X <= sx + .2 and base.Size.Z <= sz + .2
end

local function genuineStation(arena, station, index, tier)
    if not arena or not arena:IsA("Folder")
        or not VARIANTS[arena:GetAttribute("VariantId")]
        or not arena.Parent or arena.Parent.Name ~= "GeneratedMap"
        or arena.Parent.Parent ~= workspace
        or not station or not station:IsA("Model")
        or station.Name ~= "PerimeterStation"..STATIONS[index]
        or station:GetAttribute("ChaosPerimeterStation") ~= true
        or station:GetAttribute("StationIndex") ~= index then return nil end
    local base,decor=arena:FindFirstChild("Base"),arena:FindFirstChild("Decor")
    if not authenticBase(base, arena)
        or not decor or not decor:IsA("Folder")
        or decor.Parent ~= arena or station.Parent ~= decor then return nil end
    local natives={}
    -- Explicit iteration over names, not ipairs over an array containing
    -- streamed nils: a partial station must never hide its first cap.
    -- Low only replaces the two large wings; do not require or mask
    -- top-cap natives that may stream in later on an Android phone.
    local first=tier=="Low" and 3 or 1
    for i=first,#NATIVE_NAMES do
        local name=NATIVE_NAMES[i]
        local native=station:FindFirstChild(name)
        local size=EXPECTED[MODEL_NAMES[i]]
        if not native or not native:IsA("WedgePart")
            or native.Parent ~= station or not native.Anchored
            or native.CanCollide or native.CanTouch or native.CanQuery
            or (native.Size-size).Magnitude > .12 then return nil end
        natives[#natives+1]=native
    end
    return natives
end

local function fit(source, native, kind)
    local clone=source:Clone()
    local _,original=clone:GetBoundingBox()
    -- The importer is allowed to swap horizontal axes. Fix via yaw only;
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
    clone.Name="OriginalPerimeterArmor3D_"..native.Name
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",IDS[kind])
    return clone,parts
end

local function mount(arena, station, index, sources, tier)
    if mounted[station] then return end
    local natives=genuineStation(arena,station,index,tier)
    if not natives then return end
    local models,pieceSets={},{}
    local first=tier=="Low" and 3 or 1
    for i,native in ipairs(natives) do
        local kind=MODEL_NAMES[first+i-1]
        local model,pieces=fit(sources[kind],native,kind)
        if not model then
            for _,old in ipairs(models) do old:Destroy() end
            return
        end
        models[#models+1]=model
        pieceSets[#pieceSets+1]=pieces
    end
    if not genuineStation(arena,station,index,tier)
        or not sources.Wing or not sources.Wing.Parent
        or (tier~="Low" and (not sources.Cap or not sources.Cap.Parent)) then
        for _,model in ipairs(models) do model:Destroy() end
        return
    end
    local entry={
        index=index,models=models,pieces=pieceSets,original={},
        frames={},sources=sources,connections={},tier=tier,
        expected=tier=="Low" and 2 or 4,
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
    if not authenticBase(base,arena)
        or not decor or not decor:IsA("Folder") then
        removeAll()
        return
    end
    if watchedBase~=base then
        for _,c in ipairs(baseWatchers) do c:Disconnect() end
        table.clear(baseWatchers)
        watchedBase=base
        local function invalidBase()
            if not authenticBase(base,arena) then removeAll() end
        end
        baseWatchers[#baseWatchers+1]=
            base:GetPropertyChangedSignal("Size"):Connect(invalidBase)
        baseWatchers[#baseWatchers+1]=
            base:GetPropertyChangedSignal("CanCollide"):Connect(invalidBase)
        baseWatchers[#baseWatchers+1]=
            base:GetPropertyChangedSignal("Anchored"):Connect(invalidBase)
        for _,attribute in ipairs({"OriginalSizeX","OriginalSizeZ"}) do
            baseWatchers[#baseWatchers+1]=
                base:GetAttributeChangedSignal(attribute):Connect(invalidBase)
        end
        baseWatchers[#baseWatchers+1]=
            base.AncestryChanged:Connect(invalidBase)
    end

    local wing=sourceFor("Wing")
    local capSource=tier~="Low" and sourceFor("Cap") or nil
    if not wing or (tier~="Low" and not capSource) then
        removeAll()
        return
    end
    local sources={Wing=wing,Cap=capSource}
    local ranked={}
    for index,name in ipairs(STATIONS) do
        local station=decor:FindFirstChild("PerimeterStation"..name)
        local natives=genuineStation(arena,station,index,tier)
        if natives then
            local retained=mounted[station]~=nil
            -- On Low the first validated native IS the left service wing;
            -- Medium/High keep their historic third native (same wing).
            local wingNative=tier=="Low" and natives[1] or natives[3]
            local distance=(wingNative.Position-cameraPoint).Magnitude
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
            or entry.tier~=tier
            or entry.sources.Cap~=capSource or entry.sources.Wing~=wing
            or not genuineStation(arena,station,entry.index,tier)
            or #entry.models~=entry.expected
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
            mount(arena,station,index,sources,tier)
        end
    end
end

-- Count only COMPLETE source-backed groups. Low = two real 7-mesh
-- wings; Medium/High = four real 7-mesh caps/wings. The statistic for
-- replaced primitives must reflect what is actually hidden on each
-- tier, never infer four wedges from one Low two-wing group.
local function complete(entry)
    if #entry.models~=entry.expected then return false end
    for i,model in ipairs(entry.models) do
        if model.Parent~=bucket then return false end
        for _,piece in ipairs(entry.pieces[i]) do
            if not piece:IsDescendantOf(model) then return false end
        end
    end
    return true
end

function Kit.count()
    local n=0
    for _,entry in pairs(mounted) do
        if complete(entry) then n+=1 end
    end
    return n
end

function Kit.replacedNativeCount()
    local n=0
    for _,entry in pairs(mounted) do
        if complete(entry) then
            for native in pairs(entry.original) do
                if native.Transparency==1 then n+=1 end
            end
        end
    end
    return n
end

return Kit
