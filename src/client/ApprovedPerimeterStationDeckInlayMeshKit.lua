-- Authenticated original station deck sculpture. This is the approved 7-MeshPart
-- industrial ground asset, NOT a new Roblox primitive or gameplay collider.
-- The six neon/glass safety/navigation parts remain server-authoritative.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = {}

-- Perimeter station geometry stays fixed outside the playable floor.
-- Shrinking Arena changes only the live Base footprint. Authenticate
-- its builder-owned ORIGINAL size and reject expansion or invalid physics.
local function authenticBase(base, arena)
    if not arena or not base or not base:IsA("BasePart")
        or base.Parent ~= arena or not base.Anchored
        or not base.CanCollide then return false end
    local sx = base:GetAttribute("OriginalSizeX")
    local sz = base:GetAttribute("OriginalSizeZ")
    return typeof(sx) == "number" and typeof(sz) == "number"
        and sx >= 318 and sz >= 318
        and base.Size.X > 0 and base.Size.Z > 0
        and base.Size.X <= sx + .2 and base.Size.Z <= sz + .2
end
local SOURCE_ID = 72507987666671
local STATIONS = {"North", "East", "South", "West"}
local VARIANTS = {Classic=true,Towers=true,Crossroads=true,Orbital=true,Harbor=true}
local CAPS = {Low=1,Medium=2,High=4}
local RANGE = {Low=95,Medium=165,High=225}
local RETAIN = 14

local bucket = Instance.new("Folder")
bucket.Name = "ApprovedPerimeterStationDeckInlaysLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent = workspace

local activeArena, trackedBase = nil, nil
local mounted, baseListeners = {}, {}

local function unmount(station)
    local state = mounted[station]
    if not state then return end
    mounted[station] = nil
    for _,c in ipairs(state.listeners) do c:Disconnect() end
    -- Restore even during a transient stream-out: never strand the native
    -- with Transparency=1 if it later streams back into the real station.
    if state.native and state.native:IsA("Part")
        and state.native.Transparency == 1 then
        state.native.Transparency = state.alpha
    end
    state.model:Destroy()
end

local function unmountAll()
    local old = {}
    for station in pairs(mounted) do old[#old+1] = station end
    for _,station in ipairs(old) do unmount(station) end
end

local function reset()
    unmountAll()
    for _,c in ipairs(baseListeners) do c:Disconnect() end
    table.clear(baseListeners)
    trackedBase, activeArena = nil, nil
    bucket:ClearAllChildren()
end

local function realArena(arena)
    local generated = workspace:FindFirstChild("GeneratedMap")
    if not generated or generated.Parent ~= workspace
        or not arena or not arena:IsA("Folder")
        or arena.Name ~= "Arena" or arena.Parent ~= generated
        or not VARIANTS[arena:GetAttribute("VariantId")] then return nil end
    local base = arena:FindFirstChild("Base")
    local decor = arena:FindFirstChild("Decor")
    if not base or not base:IsA("BasePart") or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide
        or not authenticBase(base, arena)
        or not decor or not decor:IsA("Folder") or decor.Parent ~= arena
    then return nil end
    return base,decor
end

local function stationNative(decor,index)
    local station = decor:FindFirstChild("PerimeterStation"..STATIONS[index])
    if not station or not station:IsA("Model") or station.Parent ~= decor
        or station:GetAttribute("ChaosPerimeterStation") ~= true
        or station:GetAttribute("StationIndex") ~= index then return nil end
    local base = station:FindFirstChild("InlaidStationBase")
    local marker = station:FindFirstChild("WayfindingInset")
    if not base or not base:IsA("Part") or base.Parent ~= station
        or not base.Anchored or base.CanCollide or base.CanTouch
        or base.CanQuery or (base.Size-Vector3.new(12,.07,11)).Magnitude>.08
        or not marker or not marker:IsA("Part") or marker.Parent~=station
        or not marker.Anchored or marker.CanCollide or marker.CanTouch
        or marker.CanQuery or marker.Material~=Enum.Material.Neon
        or (marker.Size-Vector3.new(3.1,.16,1.6)).Magnitude>.08 then
        return nil
    end
    return station,base
end

local function approved()
    local holder = ReplicatedStorage:FindFirstChild("PremiumRouteMeshTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then return nil end
    local model = holder:FindFirstChild("PremiumGroundTile")
    if not model or not model:IsA("Model") or model.Parent~=holder
        or model:GetAttribute("Original3DAssetId")~=SOURCE_ID
        or model:GetAttribute("OwnerVerified")~=true
        or model:GetAttribute("CosmeticOnly")~=true then return nil end
    local count = 0
    for _,obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            if not obj:IsA("MeshPart") or obj.CanCollide
                or obj.CanTouch or obj.CanQuery then return nil end
            count += 1
        elseif obj:IsA("LuaSourceContainer") then return nil end
    end
    if count~=7 then return nil end
    local _,size = model:GetBoundingBox()
    if size.X<40 or size.X>55 or size.Z<40 or size.Z>55
        or size.Y<=0 or size.Y>1.5 then return nil end
    return model,size
end

local function mount(station,native,source,size)
    if mounted[station] or native.Transparency>=.5 then return end
    local clone = source:Clone()
    local scale = math.min(8.2/size.X,8.2/size.Z)
    if scale<.14 or scale>.205
        or not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy(); return
    end
    local origin,actual = clone:GetBoundingBox()
    if actual.X>8.26 or actual.Z>8.26 or actual.Y>.30 then
        clone:Destroy(); return
    end
    -- Source model stays inside the 12x11 station base. Negative-Z side
    -- is reserved for the WayfindingInset at Z=-4.25; its neon is exposed.
    -- The 3D surface rises just above the optional imported ground relief.
    local frame = native.CFrame*CFrame.new(0,.162-actual.Y*.5,.90)
    local parts = {}
    for _,part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then clone:Destroy();return end
            part.CFrame=frame*origin:ToObjectSpace(part.CFrame)
            part.Anchored=true
            part.Massless=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.CastShadow=false
            part.Color=part.Color:Lerp(native.Color,.12)
            parts[#parts+1]=part
        end
    end
    if #parts~=7 then clone:Destroy(); return end
    clone.Name="Original3DPerimeterStationDeckInlay"
    clone:SetAttribute("Original3DAssetId",SOURCE_ID)
    clone:SetAttribute("CosmeticOnly",true)
    local state={native=native,alpha=native.Transparency,pose=native.CFrame,
        source=source,model=clone,parts=parts,listeners={}}
    clone.Parent=bucket
    mounted[station]=state
    native.Transparency=1
    state.listeners[#state.listeners+1]=native.AncestryChanged:Connect(function()
        if native.Parent~=station then unmount(station) end
    end)
    state.listeners[#state.listeners+1]=clone.DescendantRemoving:Connect(function(obj)
        if obj:IsA("MeshPart") then unmount(station) end
    end)
    state.listeners[#state.listeners+1]=clone.AncestryChanged:Connect(function()
        if clone.Parent~=bucket then unmount(station) end
    end)
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,touch,pressure)
    if arena~=activeArena then reset(); activeArena=arena end
    local p=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    local cap=CAPS[tier] or 0
    if tier=="High" and touch then cap=2 end
    if p==1 then cap=math.floor(cap*.5) end
    if p>=2 then cap=0 end
    local base,decor=realArena(arena)
    if cap==0 or cameraReady~=true
        or typeof(cameraPoint)~="Vector3" or not base then
        unmountAll(); return
    end
    if trackedBase~=base then
        for _,c in ipairs(baseListeners) do c:Disconnect() end
        table.clear(baseListeners)
        trackedBase=base
        local function invalid()
            if base.Parent~=arena or not base.Anchored or not base.CanCollide
                or not authenticBase(base, arena) then unmountAll() end
        end
        baseListeners[#baseListeners+1]=
            base:GetPropertyChangedSignal("Size"):Connect(invalid)
        baseListeners[#baseListeners+1]=
            base:GetPropertyChangedSignal("CanCollide"):Connect(invalid)
        baseListeners[#baseListeners+1]=base.AncestryChanged:Connect(invalid)
    end
    local source,size=approved()
    if not source then unmountAll(); return end
    local ranked={}
    for index=1,#STATIONS do
        local station,native=stationNative(decor,index)
        if station then
            local resident=mounted[station]~=nil
            local distance=(native.Position-cameraPoint).Magnitude
            if (resident or native.Transparency<.5)
                and distance <= (RANGE[tier] or 0)
                    +(resident and RETAIN or 0) then
                ranked[#ranked+1]={station=station,native=native,index=index,
                    score=distance-(resident and RETAIN*.6 or 0)}
            end
        end
    end
    table.sort(ranked,function(a,b)
        if a.score~=b.score then return a.score<b.score end
        return a.index<b.index
    end)
    local wanted={}
    for i=1,math.min(cap,#ranked) do
        wanted[ranked[i].station]=ranked[i]
    end
    for station,state in pairs(mounted) do
        local wantedItem=wanted[station]
        local invalid=not wantedItem or wantedItem.native~=state.native
            or state.source~=source or state.model.Parent~=bucket
            or (state.native.Position-state.pose.Position).Magnitude>.08
            or state.native.CFrame.LookVector:Dot(state.pose.LookVector)<.999
            or state.native.CFrame.UpVector:Dot(state.pose.UpVector)<.999
        if not invalid then
            for _,part in ipairs(state.parts) do
                if not part:IsDescendantOf(state.model) then
                    invalid=true;break
                end
            end
        end
        if invalid then unmount(station)
        elseif state.native.Transparency~=1 then state.native.Transparency=1 end
    end
    for station,item in pairs(wanted) do
        if not mounted[station] then
            mount(station,item.native,source,size)
        end
    end
end

function Kit.count()
    local n=0
    for _,state in pairs(mounted) do
        if state.model.Parent==bucket and #state.parts==7 then n+=1 end
    end
    return n
end

function Kit.replacedNativeCount()
    return Kit.count()
end

return Kit
