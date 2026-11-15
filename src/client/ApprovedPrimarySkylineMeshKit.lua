-- The four direction-specific skyline towers share the existing camera
-- budget. The tower, stepped foot and variant rooftop equipment can be
-- restored independently when an approved source is unavailable.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SceneryLodRules = if script then require(ReplicatedStorage.Shared.SceneryLodRules)
    else require("../shared/SceneryLodRules")

local Kit = {}
local NAMES = {"North","East","South","West"}
local IDS = {
    [21] = 137744886537150,
    [24] = 74958476744494,
    [27] = 97864559770371,
    [30] = 112172520488996,
}
local PRIMARY = {
    Classic=17, Harbor=17, Crossroads=20, Orbital=22, Towers=25,
}
local SOURCE_FOR_HEIGHT = {
    [17]=21, [20]=21, [22]=24, [23]=24, [25]=27, [28]=30,
}
local DIRECTIONS = {
    {x=-22,z=-1,yaw=0},
    {x=1,z=-22,yaw=math.pi*.5},
    {x=22,z=1,yaw=math.pi},
    {x=-1,z=22,yaw=-math.pi*.5},
}
local BUDGET = {
    Low={count=1,distance=315},
    Medium={count=2,distance=390},
    High={count=4,distance=510},
}
local RETENTION = 24
local REPLACE = {"StructuralCore","TopCap","OuterRibL","OuterRibR","InsetL","InsetR"}
local FOOT = {id=101457508594609, holder="ApprovedHarborDockCaissonTemplates",
    name="DockCaisson", tag="OriginalHarborDockCaisson3D",
    size=Vector3.new(14.07,3.30755,14.07),
    pieces={{12.82,2.69,12.82},{13.54,2.95755,13.54}}}
local RELAY = {id=88962643359267, holder="ApprovedPerimeterArmorTemplates",
    name="Cap", tag="OriginalPerimeterArmor3D", size=Vector3.new(2.7699,2.14,2.34),
    pieces={{2.7699,2.14,2.34},{2.4566,.4494,1.7784}}}
local DISH = {id=133526819668194, holder="ApprovedPerimeterRotorTemplates",
    name="Rotor", tag="OriginalPerimeterRotor3D", size=Vector3.new(2.56,.8155,2.56),
    pieces={{2.56,.72,2.56},{2.0018,.2528,2.0009},{.7,.68,.7}}}
local GRID_MAST = {id=105555650820011, holder="ApprovedVariantIdentitySpineTemplates",
    name="Classic", tag="OriginalVariantIdentitySpine3D", size=Vector3.new(2.16,11.92,2.16),
    pieces={{1.9388,11.52,1.8788},{2.16,11.92,2.16}}}
local SERVICE_MAST = {id=86423178125318, holder=GRID_MAST.holder, name="Towers",
    tag=GRID_MAST.tag, size=Vector3.new(2.52,19.97562,2.52),
    pieces={{2.29954,19.52,2.23955},{2.52,19.92,2.52}}}
local CROSSBAR = {id=138666009076890, holder="ApprovedOrbitalReactorLandmarkTemplates",
    name="Strut", tag="OriginalOrbitalReactorLandmark3D", size=Vector3.new(8.46,1.24,1.10),
    pieces={{8.46,1.24,1.10},{7.96,.86380,.872}}}
local ROOFTOP = {
    Classic=RELAY, Harbor=RELAY, Orbital=DISH, Towers=SERVICE_MAST, Crossroads=GRID_MAST,
}
local BASE_DETAIL = {{"Foundation","Part",Vector3.new(14,2.3,10),-1.1,.04}}
local TOP_DETAIL = {
    Classic={{"RelayAerial","WedgePart",Vector3.new(3.4,3.2,2),3.2,.06}},
    Towers={{"ServiceMast","Part",Vector3.new(.85,7,.85),4.6,.06}},
    Orbital={{"ReceiverHead","Part",Vector3.new(5.5,.75,5.5),3.4,.06,Enum.PartType.Cylinder}},
    Crossroads={{"ExchangeMast","Part",Vector3.new(.7,5.5,.7),4,.04},
        {"CrossAntenna","Part",Vector3.new(7.5,.4,.4),6.1,.05}},
}
TOP_DETAIL.Harbor = TOP_DETAIL.Classic
local bucket = Instance.new("Folder")
bucket.Name = "ApprovedPrimarySkylineLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent = workspace

local activeArena = nil
local mounted = {}

local function releaseDetail(entry,key)
    local detail = entry[key]
    if not detail then return end
    entry[key] = nil
    for _,connection in ipairs(detail.connections) do connection:Disconnect() end
    for native,alpha in pairs(detail.originals) do
        if native.Transparency == 1 then native.Transparency = alpha end
    end
    detail.model:Destroy()
end

-- The four SkylineStructure anchors were placed relative to the ORIGINAL
-- 320-stud playfield. Never recompute their location from a shrinking
-- floor or replace authentic source sculptures with native boxes mid-round.
local function authenticFootprint(base, arena)
    if not base or not base:IsA("BasePart")
        or not arena or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide then return nil end
    local sx = base:GetAttribute("OriginalSizeX")
    local sz = base:GetAttribute("OriginalSizeZ")
    if typeof(sx) ~= "number" or typeof(sz) ~= "number"
        or sx < 318 or sz < 318
        or base.Size.X <= 0 or base.Size.Z <= 0
        or base.Size.X > sx + 0.2 or base.Size.Z > sz + 0.2 then
        return nil
    end
    return sx, sz
end

local function release(owner)
    local entry = mounted[owner]
    if not entry then return end
    mounted[owner] = nil
    for _,connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    releaseDetail(entry,"foot")
    releaseDetail(entry,"roof")
    for native,alpha in pairs(entry.natives) do
        if native.Transparency == 1 then
            native.Transparency = alpha
        end
    end
    entry.model:Destroy()
end

local function releaseAll()
    local owners = {}
    for owner in pairs(mounted) do owners[#owners+1] = owner end
    for _,owner in ipairs(owners) do release(owner) end
end

local function template(height)
    local id = IDS[height]
    if not id then return nil end
    local holder = ReplicatedStorage:FindFirstChild("ApprovedExteriorTowerTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local source = holder:FindFirstChild("Tower"..height)
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalExteriorTower3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= id then
        return nil
    end
    local n = 0
    for _,item in ipairs(source:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or item.CanCollide
                or item.CanTouch or item.CanQuery then return nil end
            n += 1
        elseif item:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if n ~= 7 then return nil end
    local _,dims = source:GetBoundingBox()
    local width = math.max(dims.X,dims.Z)
    local depth = math.min(dims.X,dims.Z)
    if math.abs(dims.Y-(height+1.2)) > .45
        or math.abs(width-11.84) > .42
        or math.abs(depth-9.84) > .42 then
        return nil
    end
    return source,holder,id
end

local function checkPart(owner,name,kind,size,frame,alpha,shape)
    local part = owner:FindFirstChild(name)
    if not part or not part:IsA(kind) or part.Parent ~= owner
        or not part.Anchored or part.CanCollide or part.CanTouch
        or part.CanQuery or (part.Size-size).Magnitude > .12
        or (part.Position-frame.Position).Magnitude > .16
        or part.CFrame.LookVector:Dot(frame.LookVector) < .999
        or part.CFrame.UpVector:Dot(frame.UpVector) < .999
        or (math.abs(part.Transparency-alpha) > .035
            and part.Transparency ~= 1) then
        return nil
    end
    if shape and part:IsA("Part") and part.Shape ~= shape then
        return nil
    end
    return part
end

local function genuine(arena,owner,index)
    local variant = arena and arena:GetAttribute("VariantId")
    local baseHeight = PRIMARY[variant]
    local generated = workspace:FindFirstChild("GeneratedMap")
    local decor = arena and arena:FindFirstChild("Decor")
    local base = arena and arena:FindFirstChild("Base")
    local originalX, originalZ = authenticFootprint(base, arena)
    if not arena or not arena:IsA("Folder") or not generated
        or not generated:IsA("Folder") or arena.Name ~= "Arena"
        or arena.Parent ~= generated
        or not decor or not decor:IsA("Folder") or decor.Parent ~= arena
        or not originalX or not originalZ
        or not owner or not owner:IsA("Model") or owner.Parent ~= decor
        or owner.Name ~= "SkylineStructure"..NAMES[index]
        or owner:GetAttribute("ChaosDistantScenery") ~= true
        or not baseHeight then
        return nil
    end
    local h = baseHeight+(index%2)*3
    local direction = DIRECTIONS[index]
    local x,z = direction.x,direction.z
    if index == 1 or index == 3 then
        z *= originalZ*.5+23
    else
        x *= originalX*.5+23
    end
    local origin = CFrame.new(base.Position+Vector3.new(
        x,base.Size.Y*.5,z))*CFrame.Angles(0,direction.yaw,0)
    local core = checkPart(owner,"StructuralCore","Part",
        Vector3.new(8.5,h,7.4),origin*CFrame.new(0,h*.5,0),.03,
        Enum.PartType.Block)
    local cap = checkPart(owner,"TopCap","WedgePart",
        Vector3.new(11.4,3,8.8),origin*CFrame.new(0,h+1.3,0),.06)
    local l = checkPart(owner,"OuterRibL","WedgePart",
        Vector3.new(2.2,5.4,8),
        origin*CFrame.new(-4.6,2.8,0)*CFrame.Angles(0,math.pi,0),.06)
    local r = checkPart(owner,"OuterRibR","WedgePart",
        Vector3.new(2.2,5.4,8),origin*CFrame.new(4.6,2.8,0),.06)
    local inL = checkPart(owner,"InsetL","Part",
        Vector3.new(.24,h*.54,.85),
        origin*CFrame.new(-4.30,h*.52,-3.6),.28)
    local inR = checkPart(owner,"InsetR","Part",
        Vector3.new(.24,h*.54,.85),
        origin*CFrame.new(4.30,h*.52,-3.6),.28)
    if not core or not cap or not l or not r
        or not inL or not inR then return nil end
    -- Check all four parts belong to this exact generated skyline,
    -- well beyond the playable base, not a similarly named arena prop.
    if math.max(math.abs(core.Position.X-base.Position.X),
        math.abs(core.Position.Z-base.Position.Z))
        < math.min(originalX,originalZ)*.5 then
        return nil
    end
    return {core,cap,l,r,inL,inR},origin,h,base,decor
end

local function valid(entry)
    if entry.arena ~= activeArena
        or entry.variant ~= entry.arena:GetAttribute("VariantId")
        or entry.model.Parent ~= bucket
        or entry.owner.Parent ~= entry.decor
        or entry.source.Parent ~= entry.holder
        or entry.holder.Parent ~= ReplicatedStorage
        or entry.holder:GetAttribute("OwnerVerified") ~= true
        or entry.source:GetAttribute("OwnerVerified") ~= true
        or entry.source:GetAttribute("OriginalExteriorTower3D") ~= true
        or entry.source:GetAttribute("CosmeticOnly") ~= true
        or entry.source:GetAttribute("Original3DAssetId") ~= entry.id
        or entry.base.Parent ~= entry.arena
        or #entry.parts ~= 7 then return false end
    local native = genuine(entry.arena,entry.owner,entry.index)
    if not native or #native ~= #REPLACE then return false end
    for i,n in ipairs(native) do
        if entry.originals[i] ~= n or entry.natives[n] == nil then
            return false
        end
    end
    for _,part in ipairs(entry.parts) do
        if not part:IsDescendantOf(entry.model) then return false end
    end
    return true
end

local function trusted(source,holder,spec)
    return holder and holder:IsA("Folder") and holder.Parent == ReplicatedStorage
        and holder.Name == spec.holder and holder:GetAttribute("OwnerVerified") == true
        and source and source:IsA("Model") and source.Parent == holder
        and source.Name == spec.name and source:GetAttribute("OwnerVerified") == true
        and source:GetAttribute("CosmeticOnly") == true
        and source:GetAttribute(spec.tag) == true
        and source:GetAttribute("Original3DAssetId") == spec.id
end

local function horizontalSize(size)
    return Vector3.new(math.max(size.X,size.Z),size.Y,math.min(size.X,size.Z))
end

local function detailTemplate(spec)
    local holder = ReplicatedStorage:FindFirstChild(spec.holder)
    local source = holder and holder:FindFirstChild(spec.name)
    if not trusted(source,holder,spec) then return nil end
    local children = source:GetChildren()
    if #children ~= 7 then return nil end
    local frame,size = source:GetBoundingBox()
    local expected = horizontalSize(spec.size)
    if (horizontalSize(size)-expected).Magnitude > .28 then return nil end
    local selected = {}
    for _,piece in ipairs(children) do
        if not piece:IsA("MeshPart") or not piece.Anchored or piece.CanCollide
            or piece.CanTouch or piece.CanQuery or piece.Transparency >= 1 then return nil end
        for _,detail in ipairs(piece:GetDescendants()) do
            if not detail:IsA("SurfaceAppearance") and not detail:IsA("Decal")
                and not detail:IsA("Texture") then return nil end
        end
        local dimensions = horizontalSize(piece.Size)
        for index,signature in ipairs(spec.pieces) do
            local fit = horizontalSize(Vector3.new(signature[1],signature[2],signature[3]))
            if (dimensions-fit).Magnitude < .09 then
                if selected[index] then return nil end
                selected[index] = piece
            end
        end
    end
    for index = 1,#spec.pieces do if not selected[index] then return nil end end
    return {source=source,holder=holder,frame=frame,size=size,pieces=selected,spec=spec}
end

local function detailNatives(entry,key)
    local specs = key == "foot" and BASE_DETAIL or TOP_DETAIL[entry.variant]
    local result = {}
    for _,s in ipairs(specs) do
        local y = key == "foot" and s[4] or entry.height+s[4]
        local part = checkPart(entry.owner,s[1],s[2],s[3],
            entry.origin*CFrame.new(0,y,0),s[5],s[6] or Enum.PartType.Block)
        if not part or part:GetAttribute("SceneryLodHidden") == true
            or part.LocalTransparencyModifier >= .95 then return nil end
        result[#result+1] = part
    end
    return result
end

local function axisScale(axis,scale)
    if math.abs(axis.X) > .9999 then return scale.X end
    if math.abs(axis.Y) > .9999 then return scale.Y end
    if math.abs(axis.Z) > .9999 then return scale.Z end
    return nil
end

local function sculpt(clone,source,target,size,color)
    local bounds = source.size
    if (source.spec.size.X > source.spec.size.Z and bounds.Z > bounds.X)
        or (source.spec.size.X < source.spec.size.Z and bounds.X > bounds.Z) then
        target *= CFrame.Angles(0,math.pi*.5,0)
        size = Vector3.new(size.Z,size.Y,size.X)
    end
    local scale = size/bounds
    for _,original in ipairs(source.pieces) do
        local localPose = source.frame:ToObjectSpace(original.CFrame)
        local x = axisScale(localPose.RightVector,scale)
        local y = axisScale(localPose.UpVector,scale)
        local z = axisScale(localPose.LookVector,scale)
        if not x or not y or not z then return false end
        local part = original:Clone()
        if not part then return false end
        part.Size *= Vector3.new(x,y,z)
        part.CFrame = target*CFrame.new(localPose.Position*scale)*localPose.Rotation
        part.Massless = true
        part.CastShadow = false
        part.LocalTransparencyModifier = 0
        part.Color = part.Color:Lerp(color,.40)
        part:SetAttribute("Original3DAssetId",source.spec.id)
        part.Parent = clone
    end
    return true
end

local function syncDetail(entry,key,source,bar)
    local native = source and detailNatives(entry,key)
    local detail = entry[key]
    if detail then
        local intact = native and detail.source == source.source
            and detail.bar == (bar and bar.source)
            and detail.model.Parent == entry.model and #detail.model:GetChildren() == detail.count
        for _,part in ipairs(native or {}) do
            if detail.originals[part] == nil then intact = false;break end
        end
        if intact then
            for _,part in ipairs(native) do
                if part.Transparency < 1 then detail.originals[part] = part.Transparency end
                part.Transparency = 1
            end
            return
        end
        releaseDetail(entry,key)
    end
    if not native then return end
    for _,part in ipairs(native) do if part.Transparency >= 1 then return end end
    local clone = Instance.new("Model")
    clone.Name = key == "foot" and "ForgedSkylineFoundation" or "SculptedSkylineEquipment"
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",source.spec.id)
    local size = native[1].Size
    local center = native[1].CFrame
    if key == "roof" then
        local top = entry.roofHeight
        local bottom = top-.13
        size = Vector3.new(math.max(size.X,1),size.Y,math.max(size.Z,1))
        if source.spec == RELAY then
            center = entry.origin*CFrame.new(0,bottom+size.Y*.5,0)*CFrame.Angles(0,entry.inwardYaw,0)
        elseif source.spec == DISH then
            size = Vector3.new(5.5,.88,5.5)
            center = entry.origin*CFrame.new(0,bottom+size.Y*.5,0)
        else
            if bar then size = Vector3.new(1,math.max(2.8,native[2].Position.Y-entry.origin.Position.Y-bottom+.14),1) end
            center = entry.origin*CFrame.new(0,bottom+size.Y*.5,0)
        end
    end
    if not sculpt(clone,source,center,size,native[1].Color)
        or (bar and not sculpt(clone,bar,native[2].CFrame,Vector3.new(7.5,.66,.62),native[2].Color)) then
        clone:Destroy()
        return
    end
    clone.Parent = entry.model
    detail = {model=clone,source=source.source,bar=bar and bar.source,
        count=#clone:GetChildren(),originals={},connections={}}
    entry[key] = detail
    local function revoke()
        if entry[key] == detail then releaseDetail(entry,key) end
    end
    local function checkNative()
        local current = detailNatives(entry,key)
        if not current then revoke();return end
        for _,part in ipairs(current) do
            if detail.originals[part] == nil then revoke();return end
        end
    end
    local function watch(signal,callback)
        table.insert(detail.connections,signal:Connect(callback))
    end
    watch(clone.ChildRemoved,revoke)
    watch(clone.AncestryChanged,function()
        if clone.Parent ~= entry.model then revoke() end
    end)
    for _,asset in ipairs(bar and {source,bar} or {source}) do
        watch(asset.source.ChildAdded,revoke)
        watch(asset.source.ChildRemoved,revoke)
        watch(asset.source.AncestryChanged,revoke)
        watch(asset.source:GetPropertyChangedSignal("Name"),revoke)
        watch(asset.holder:GetPropertyChangedSignal("Name"),revoke)
        watch(asset.holder:GetAttributeChangedSignal("OwnerVerified"),revoke)
        for _,flag in ipairs({"OwnerVerified","CosmeticOnly","Original3DAssetId",asset.spec.tag}) do
            watch(asset.source:GetAttributeChangedSignal(flag),revoke)
        end
    end
    for _,part in ipairs(native) do
        detail.originals[part] = part.Transparency
        watch(part.AncestryChanged,checkNative)
        watch(part:GetAttributeChangedSignal("SceneryLodHidden"),checkNative)
        for _,property in ipairs({"CFrame","Size","Name","Anchored","CanCollide",
            "CanTouch","CanQuery","LocalTransparencyModifier"}) do
            watch(part:GetPropertyChangedSignal(property),checkNative)
        end
        if part:IsA("Part") then watch(part:GetPropertyChangedSignal("Shape"),checkNative) end
        part.Transparency = 1
    end
end

local function mount(arena,owner,index,source,holder,id)
    local native,origin,height,base,decor = genuine(arena,owner,index)
    if not native then return end
    local clone = source:Clone()
    if not clone then return end
    local _,bounds = clone:GetBoundingBox()
    local width,depth = math.max(bounds.X,bounds.Z),
        math.min(bounds.X,bounds.Z)
    local scale = math.min((height+2.8)/bounds.Y,
        11.4*1.06/width,8.8*1.13/depth)
    if scale < .80 or scale > 1.10
        or not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return
    end
    local frame,size = clone:GetBoundingBox()
    local w,d = math.max(size.X,size.Z),math.min(size.X,size.Z)
    if size.Y < (height+2.8)*.965 or size.Y > height+2.9
        or w > 11.4*1.07 or d > 8.8*1.14 then
        clone:Destroy()
        return
    end
    -- The original vents face local -Z. The builder's odd directions have
    -- local +Z toward the arena. The roof code resolves a swapped import.
    local inwardYaw = index % 2 == 1 and math.pi or 0
    local swapped = size.Z > size.X
    local yaw = inwardYaw + (swapped and -math.pi*.5 or 0)
    for _,part in ipairs(clone:GetChildren()) do
        if part:IsA("MeshPart") and part.Size.Y < .16 then
            local center = frame:PointToObjectSpace(part.Position)
            local depth = swapped and center.X or center.Z
            if math.abs(depth) > d*.30 then
                if depth > 0 then yaw += math.pi end
                break
            end
        end
    end
    local target = origin*CFrame.new(0,size.Y*.5,0)
        *CFrame.Angles(0,yaw,0)
    local parts = {}
    for _,piece in ipairs(clone:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then
                clone:Destroy()
                return
            end
            piece.CFrame = target*frame:ToObjectSpace(piece.CFrame)
            piece.Anchored = true
            piece.Massless = true
            piece.CanCollide = false
            piece.CanTouch = false
            piece.CanQuery = false
            piece.CastShadow = false
            piece.Color = piece.Color:Lerp(native[1].Color,.18)
            piece:SetAttribute("CosmeticOnly",true)
            piece:SetAttribute("Original3DAssetId",id)
            parts[#parts+1] = piece
        end
    end
    if #parts ~= 7 or not genuine(arena,owner,index)
        or source.Parent ~= holder then
        clone:Destroy()
        return
    end
    clone.Name = "SculptedSkylineStructure"..NAMES[index]
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",id)
    clone.Parent = bucket
    local entry = {
        arena=arena,owner=owner,index=index,base=base,decor=decor,
        source=source,holder=holder,model=clone,parts=parts,id=id,
        natives={},originals=native,connections={},origin=origin,height=height,
        roofHeight=size.Y,variant=arena:GetAttribute("VariantId"),inwardYaw=inwardYaw,
    }
    for _,part in ipairs(native) do entry.natives[part] = part.Transparency end
    mounted[owner] = entry
    if not valid(entry) then release(owner);return end
    for _,part in ipairs(native) do part.Transparency = 1 end
    local function check()
        if mounted[owner] == entry and not valid(entry) then
            release(owner)
        end
    end
    for _,object in ipairs({owner,base,source,clone}) do
        entry.connections[#entry.connections+1] =
            object.AncestryChanged:Connect(check)
    end
    for _,signal in ipairs({
        base:GetPropertyChangedSignal("Size"),
        base:GetPropertyChangedSignal("CFrame"),
        base:GetPropertyChangedSignal("CanCollide"),
        holder:GetAttributeChangedSignal("OwnerVerified"),
        source:GetAttributeChangedSignal("OwnerVerified"),
        source:GetAttributeChangedSignal("OriginalExteriorTower3D"),
        source:GetAttributeChangedSignal("Original3DAssetId"),
        source:GetAttributeChangedSignal("CosmeticOnly"),
    }) do
        entry.connections[#entry.connections+1] = signal:Connect(check)
    end
    entry.connections[#entry.connections+1] =
        source.DescendantRemoving:Connect(function(p)
            if p:IsA("MeshPart") then release(owner) end
        end)
    entry.connections[#entry.connections+1] =
        clone.DescendantRemoving:Connect(function(p)
            if table.find(parts,p) then release(owner) end
        end)
    for _,part in ipairs(native) do
        entry.connections[#entry.connections+1] =
            part.AncestryChanged:Connect(check)
        entry.connections[#entry.connections+1] =
            part:GetPropertyChangedSignal("CFrame"):Connect(check)
        entry.connections[#entry.connections+1] =
            part:GetPropertyChangedSignal("Size"):Connect(check)
    end
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,touch,pressure,cameraLook)
    if arena ~= activeArena then
        releaseAll()
        activeArena = arena
    end
    local spec = BUDGET[tier] or BUDGET.Low
    local pressureValue = tonumber(pressure) or 0
    local stress = pressureValue == pressureValue and math.clamp(math.floor(pressureValue),0,2) or 0
    local cap = spec.count
    if touch then
        cap = tier == "High" and math.min(cap,2)
            or tier == "Medium" and math.min(cap,1)
            or tier == "Low" and math.min(cap,1) or 0
    end
    if stress == 1 then cap = math.floor(cap*.5) end
    if stress >= 2 then cap = 0 end
    if cap == 0 or not cameraReady
        or typeof(cameraPoint) ~= "Vector3" then
        releaseAll()
        return
    end
    local ranked = {}
    local decor = arena and arena:FindFirstChild("Decor")
    if not decor or not decor:IsA("Folder") then
        releaseAll()
        return
    end
    for index,name in ipairs(NAMES) do
        local owner = decor:FindFirstChild("SkylineStructure"..name)
        local native,_,height = genuine(arena,owner,index)
        local srcHeight = height and SOURCE_FOR_HEIGHT[height]
        local source,holder,id = template(srcHeight)
        if native and source then
            local held = mounted[owner] ~= nil
            local distance = (cameraPoint-native[1].Position).Magnitude
            if distance <= spec.distance+(held and RETENTION or 0) then
                ranked[#ranked+1] = {
                    owner=owner,index=index,source=source,holder=holder,
                    id=id,score=SceneryLodRules.sceneryViewScore(
                        distance-(held and RETENTION*.5 or 0),
                        native[1].Position-cameraPoint,cameraLook),
                }
            end
        end
    end
    table.sort(ranked,function(a,b)
        if a.score ~= b.score then return a.score < b.score end
        return a.index < b.index
    end)
    local wanted = {}
    for i=1,math.min(cap,#ranked) do
        wanted[ranked[i].owner] = ranked[i]
    end
    local obsolete = {}
    for owner,entry in pairs(mounted) do
        local target = wanted[owner]
        if not target or target.source ~= entry.source or not valid(entry) then
            obsolete[#obsolete+1] = owner
        else
            for native in pairs(entry.natives) do
                native.Transparency = 1
            end
        end
    end
    for _,owner in ipairs(obsolete) do release(owner) end
    local variant = arena:GetAttribute("VariantId")
    local rooftop = ROOFTOP[variant]
    local foot = stress == 0 and #ranked > 0 and detailTemplate(FOOT) or nil
    local roof = stress == 0 and #ranked > 0 and rooftop and detailTemplate(rooftop) or nil
    local bar = roof and variant == "Crossroads" and detailTemplate(CROSSBAR) or nil
    if variant == "Crossroads" and not bar then roof = nil end
    for owner,item in pairs(wanted) do
        if not mounted[owner] then
            mount(arena,owner,item.index,item.source,item.holder,item.id)
        end
        local entry = mounted[owner]
        if entry then
            syncDetail(entry,"foot",foot)
            syncDetail(entry,"roof",roof,bar)
        end
    end
end

function Kit.count()
    local n = 0
    for _,entry in pairs(mounted) do
        if valid(entry) then n += 1 end
    end
    return n
end

function Kit.replacedNativeCount()
    local bodies,details = 0,0
    for _,entry in pairs(mounted) do
        if valid(entry) then
            for part in pairs(entry.natives) do
                if part.Parent == entry.owner and part.Transparency == 1 then
                    bodies += 1
                end
            end
            for _,key in ipairs({"foot","roof"}) do
                local detail = entry[key]
                if detail and detail.model.Parent == entry.model then
                    for part in pairs(detail.originals) do
                        if part.Parent == entry.owner and part.Transparency == 1 then details += 1 end
                    end
                end
            end
        end
    end
    return bodies,details
end

return Kit
