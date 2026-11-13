-- Seven authentically sculpted Classic observatory MeshParts mask only the
-- seven original nonphysical tower/dish primitives, all at once.
-- True client-only cosmetic LOD, no new frame loop or physics mutations.
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Kit={}
-- These outboard landmarks are fixed to the BUILDER's initial perimeter.
-- Shrinking Arena contracts the playable Base, not the original sculpture.
local function originalFootprint(base, arena)
    if not base or not base:IsA("BasePart") or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide then return nil end
    local sx = base:GetAttribute("OriginalSizeX")
    local sz = base:GetAttribute("OriginalSizeZ")
    if typeof(sx) ~= "number" or typeof(sz) ~= "number"
        or sx ~= sx or sz ~= sz or sx < 318 or sz < 318
        or sx == math.huge or sz == math.huge
        or base.Size.X <= 0 or base.Size.Z <= 0
        or base.Size.X > sx + .2 or base.Size.Z > sz + .2 then
        return nil
    end
    return sx, sz
end

local OWNER_ID=112493873850364
-- Android Low: one authenticated seven-MeshPart landmark instead of
-- 7 distant primitive silhouette Parts, only at VFX pressure zero.
-- These three variants are mutually exclusive on the same active arena.
local QUALITY={Low=1,Medium=1,High=1}
local RANGE={Low=290,Medium=440,High=615}
local RETAIN=26
local NAMES={
    "PrimaryRelayMast","RelayHead","DishBridge",
    "ReceiverDishWest","ReceiverDishEast",
    "ReceiverHubWest","ReceiverHubEast",
}
local SIZES={
    Vector3.new(3,55,3),
    Vector3.new(7,4.7,4.2),
    Vector3.new(30,1.2,2),
    Vector3.new(.8,10.5,10.5),
    Vector3.new(.8,10.5,10.5),
    Vector3.new(2.1,2.1,2.1),
    Vector3.new(2.1,2.1,2.1),
}
local RELATIVE={
    CFrame.new(0,30.5,0),
    CFrame.new(0,9.5,0),
    CFrame.new(-13,13.5,0)*CFrame.Angles(0,math.pi*.5,0),
    CFrame.new(13,19.5,0)*CFrame.Angles(0,math.pi*.5,0),
    CFrame.new(-13,13.5,-.8),
    CFrame.new(13,19.5,-.8),
}
local folder=Instance.new("Folder")
folder.Name="ApprovedClassicSignatureObservatoryLocal"
folder:SetAttribute("CosmeticOnly",true)
folder.Parent=workspace

local activeArena=nil
local mounted=nil
local watchedBase=nil
local baseConnections={}

local function restore()
    local state=mounted
    if not state then return end
    mounted=nil
    for _,connection in ipairs(state.connections) do
        connection:Disconnect()
    end
    for native,alpha in pairs(state.originals) do
        if native.Parent==state.owner and native:IsA("BasePart")
            and native.Anchored and not native.CanCollide
            and not native.CanTouch and not native.CanQuery
            and native.Transparency==1 then
            native.Transparency=alpha
        end
    end
    state.model:Destroy()
end

local function clear()
    restore()
    for _,connection in ipairs(baseConnections) do
        connection:Disconnect()
    end
    table.clear(baseConnections)
    watchedBase=nil
    activeArena=nil
    folder:ClearAllChildren()
end

local function approvedSource()
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedClassicSignatureObservatoryTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent~=ReplicatedStorage
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=holder:FindFirstChild("DualDishObservatory")
    if not source or not source:IsA("Model")
        or source.Parent~=holder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalClassicDualDishObservatory3D")~=true
        or source:GetAttribute("Original3DAssetId")~=OWNER_ID then
        return nil
    end
    local meshes=0
    for _,part in ipairs(source:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide
                or part.CanTouch or part.CanQuery then return nil end
            meshes+=1
        elseif part:IsA("LuaSourceContainer") then return nil end
    end
    if meshes~=7 then return nil end
    local _,size=source:GetBoundingBox()
    local short,long=math.min(size.X,size.Z),math.max(size.X,size.Z)
    if math.abs(size.Y-15.0875)>.43
        or math.abs(short-1.03)>.20
        or math.abs(long-9.105)>.40 then
        return nil
    end
    return source
end

local function context(arena)
    if not arena or not arena:IsA("Folder") or arena.Name~="Arena"
        or arena:GetAttribute("VariantId")~="Classic" then return nil end
    local generated=workspace:FindFirstChild("GeneratedMap")
    if not generated or not generated:IsA("Folder")
        or arena.Parent~=generated then return nil end
    local base=arena:FindFirstChild("Base")
    local decor=arena:FindFirstChild("Decor")
    local originalX, originalZ = originalFootprint(base, arena)
    if not base or not base:IsA("BasePart")
        or base.Parent~=arena or not base.Anchored
        or not base.CanCollide or not originalFootprint(base,arena)
        or not decor or not decor:IsA("Folder")
        or decor.Parent~=arena then return nil end
    local owner=decor:FindFirstChild("ArenaSignatureMegastructure")
    if not owner or not owner:IsA("Model") or owner.Parent~=decor
        or owner:GetAttribute("ChaosDistantScenery")~=true
        or owner:GetAttribute("SignatureVariant")~="Classic" then
        return nil
    end

    local originals={}
    for i,name in ipairs(NAMES) do
        local part=owner:FindFirstChild(name)
        local wedge=i==2
        if not part or part.Parent~=owner
            or (wedge and not part:IsA("WedgePart"))
            or (not wedge and (not part:IsA("Part")))
            or not part.Anchored or part.CanCollide
            or part.CanTouch or part.CanQuery
            or (part.Size-SIZES[i]).Magnitude>.11 then return nil end
        if not wedge then
            local shape=(i==4 or i==5)
                and Enum.PartType.Cylinder or Enum.PartType.Block
            if part.Shape~=shape then return nil end
        end
        originals[i]=part
    end

    local mast=originals[1]
    local expected=base.Position+Vector3.new(
        originalX*.24,
        base.Size.Y*.5+27.5,
        -(originalZ*.5+66))
    if (mast.Position-expected).Magnitude>.20 then return nil end
    for i=2,7 do
        local actual=mast.CFrame:ToObjectSpace(originals[i].CFrame)
        local target=RELATIVE[i-1]
        if (actual.Position-target.Position).Magnitude>.12
            or actual.LookVector:Dot(target.LookVector)<.999
            or actual.UpVector:Dot(target.UpVector)<.999 then
            return nil
        end
    end

    -- All native load-bearing cosmetic silhouettes and readable service
    -- signage must remain, otherwise partial map streaming is in progress.
    local companionNames={
        {"RelayButtressWest",Vector3.new(3.5,33,4.5)},
        {"RelayButtressEast",Vector3.new(3.5,33,4.5)},
        {"RelaySparWest",Vector3.new(1.1,31,1.4)},
        {"RelaySparEast",Vector3.new(1.1,31,1.4)},
        {"ServicePanel",Vector3.new(5,3.2,.55)},
    }
    for _,spec in ipairs(companionNames) do
        local native=owner:FindFirstChild(spec[1])
        if not native or not native:IsA("Part") or native.Parent~=owner
            or not native.Anchored or native.CanCollide
            or native.CanTouch or native.CanQuery
            or (native.Size-spec[2]).Magnitude>.12 then
            return nil
        end
    end
    return base,owner,originals
end

local function fit(source,mast)
    local model=source:Clone()
    -- Full native seven-Part union (not whole landmark foundation):
    -- X=±18.25, Y=0..60.35, Z=±2.10. Source normalized 1:4.
    local desired=Vector3.new(36.5,60.35,4.2)
    local _,original=model:GetBoundingBox()
    local direct=math.abs(original.X-desired.X*.25)
        +math.abs(original.Z-desired.Z*.25)
    local swapped=math.abs(original.Z-desired.X*.25)
        +math.abs(original.X-desired.Z*.25)
    local yaw=direct<=swapped and 0 or math.pi*.5
    local width=yaw==0 and original.X or original.Z
    local depth=yaw==0 and original.Z or original.X
    local factor=math.min(4.06,
        desired.X*.985/width,
        desired.Y*.985/original.Y,
        desired.Z*.985/depth)
    if factor<3.60 or factor>4.07
        or not pcall(function() model:ScaleTo(factor) end) then
        model:Destroy()
        return nil
    end
    local frame,scaled=model:GetBoundingBox()
    width=yaw==0 and scaled.X or scaled.Z
    depth=yaw==0 and scaled.Z or scaled.X
    if width>desired.X*.997 or depth>desired.Z*.997
        or scaled.Y>desired.Y*.997
        or width<desired.X*.92 or depth<desired.Z*.88
        or scaled.Y<desired.Y*.94 then
        model:Destroy()
        return nil
    end
    local target=mast.CFrame*CFrame.new(0,2.675,0)
        *CFrame.Angles(0,yaw,0)
    local parts={}
    for _,item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") then
                model:Destroy()
                return nil
            end
            item.CFrame=target*frame:ToObjectSpace(item.CFrame)
            item.Anchored=true
            item.Massless=true
            item.CanCollide=false
            item.CanTouch=false
            item.CanQuery=false
            item.CastShadow=false
            item:SetAttribute("CosmeticOnly",true)
            item:SetAttribute("Original3DAssetId",OWNER_ID)
            parts[#parts+1]=item
        end
    end
    if #parts~=7 then model:Destroy();return nil end
    model.Name="ApprovedClassicDualDishObservatory3D"
    model:SetAttribute("CosmeticOnly",true)
    model:SetAttribute("Original3DAssetId",OWNER_ID)
    return model,parts
end

local function mount(arena,source)
    if mounted then return end
    local base,owner,originals=context(arena)
    if not base then return end
    local model,parts=fit(source,originals[1])
    if not model then return end
    local againBase,againOwner,again=context(arena)
    if againBase~=base or againOwner~=owner
        or not again or not source.Parent then
        model:Destroy()
        return
    end
    for i=1,7 do
        if again[i]~=originals[i] then
            model:Destroy()
            return
        end
    end
    local state={
        arena=arena,base=base,owner=owner,source=source,
        model=model,parts=parts,originals={},frames={},connections={},
    }
    for _,part in ipairs(originals) do
        state.originals[part]=part.Transparency
        state.frames[part]=part.CFrame
    end
    model.Parent=folder
    mounted=state
    for _,part in ipairs(originals) do part.Transparency=1 end
    state.connections[#state.connections+1]=
        owner.AncestryChanged:Connect(function()
            if owner.Parent~=arena:FindFirstChild("Decor") then restore() end
        end)
    state.connections[#state.connections+1]=
        source.AncestryChanged:Connect(function()
            if not source.Parent then restore() end
        end)
    state.connections[#state.connections+1]=
        source.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then restore() end
        end)
    state.connections[#state.connections+1]=
        model.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then restore() end
        end)
    for _,native in ipairs(originals) do
        state.connections[#state.connections+1]=
            native.AncestryChanged:Connect(function()
                if native.Parent~=owner then restore() end
            end)
    end
end

folder.ChildRemoved:Connect(function(child)
    if mounted and mounted.model==child then restore() end
end)

function Kit.sync(arena,cameraPoint,tier,cameraReady,pressure)
    if arena~=activeArena then clear();activeArena=arena end
    local cap=QUALITY[tier] or 0
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if stress>=2 or (stress==1 and tier~="High") then cap=0 end
    if cap==0 or not cameraReady or typeof(cameraPoint)~="Vector3" then
        restore()
        return
    end
    local base,owner,natives=context(arena)
    if not base then restore();return end
    local distance=(natives[1].Position-cameraPoint).Magnitude
    if distance>(RANGE[tier] or 0)+(mounted and RETAIN or 0) then
        restore()
        return
    end
    if watchedBase~=base then
        for _,c in ipairs(baseConnections) do c:Disconnect() end
        table.clear(baseConnections)
        watchedBase=base
        local function verifyBase()
            if base.Parent~=arena or not base.Anchored
                or not base.CanCollide or not originalFootprint(base,arena) then restore() end
        end
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("Size"):Connect(verifyBase)
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("CanCollide"):Connect(verifyBase)
        baseConnections[#baseConnections+1]=
            base.AncestryChanged:Connect(verifyBase)
        baseConnections[#baseConnections+1]=
            base:GetAttributeChangedSignal("OriginalSizeX"):Connect(verifyBase)
        baseConnections[#baseConnections+1]=
            base:GetAttributeChangedSignal("OriginalSizeZ"):Connect(verifyBase)
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("Anchored"):Connect(verifyBase)
    end
    local source=approvedSource()
    if not source then restore();return end
    if mounted then
        local invalid=mounted.arena~=arena or mounted.owner~=owner
            or mounted.base~=base or mounted.source~=source
            or mounted.model.Parent~=folder or #mounted.parts~=7
        if not invalid then
            for native,oldFrame in pairs(mounted.frames) do
                if native.Parent~=owner
                    or (native.CFrame.Position-oldFrame.Position).Magnitude>.08
                    or native.CFrame.LookVector:Dot(oldFrame.LookVector)<.999
                    or native.CFrame.UpVector:Dot(oldFrame.UpVector)<.999 then
                    invalid=true
                    break
                end
            end
            for _,part in ipairs(mounted.parts) do
                if not part:IsDescendantOf(mounted.model) then
                    invalid=true
                end
            end
        end
        if invalid then restore() end
    end
    if not mounted then mount(arena,source) end
    if mounted then
        for native in pairs(mounted.originals) do
            native.Transparency=1
        end
    end
end

function Kit.count()
    return mounted and mounted.model.Parent==folder
        and #mounted.parts==7 and 1 or 0
end

function Kit.replacedNativeCount()
    if Kit.count()==0 then return 0 end
    local count=0
    for native in pairs(mounted.originals) do
        if native.Parent==mounted.owner and native.Transparency==1 then
            count+=1
        end
    end
    return count
end

return Kit
