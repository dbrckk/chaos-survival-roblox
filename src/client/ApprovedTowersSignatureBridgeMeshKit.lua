-- Genuine original forged bridge, 7 physical MeshParts (cosmetic only).
-- Replaces exactly two big nonphysical native slab Parts on the true Towers
-- ArenaSignatureMegastructure. Nothing here changes playable Skyrail bridges.
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Kit={}
local MODEL_ID=126298311664881
-- Android Low: one authenticated seven-MeshPart landmark instead of
-- 2 distant primitive silhouette Parts, only at VFX pressure zero.
-- These three variants are mutually exclusive on the same active arena.
local QUALITY={Low=1,Medium=1,High=1}
local RANGE={Low=290,Medium=390,High=575}
local RETENTION=24
local bucket=Instance.new("Folder")
bucket.Name="ApprovedTowersSignatureBridgeLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent=workspace

local currentArena=nil
local mounted=nil
local watchedBase=nil
local baseConnections={}

local function restore()
    local state=mounted
    if not state then return end
    mounted=nil
    for _,c in ipairs(state.connections) do c:Disconnect() end
    for native,original in pairs(state.originals) do
        if native.Parent==state.owner and native:IsA("Part")
            and native.Anchored and not native.CanCollide
            and not native.CanTouch and not native.CanQuery
            and native.Transparency==1 then
            native.Transparency=original
        end
    end
    state.model:Destroy()
end

local function clear()
    restore()
    for _,c in ipairs(baseConnections) do c:Disconnect() end
    table.clear(baseConnections)
    watchedBase=nil
    currentArena=nil
    bucket:ClearAllChildren()
end

local function approvedSource()
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedTowersSignatureBridgeTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent~=ReplicatedStorage
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=holder:FindFirstChild("ForgedBridge")
    if not source or not source:IsA("Model") or source.Parent~=holder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalTowersSignatureBridge3D")~=true
        or source:GetAttribute("Original3DAssetId")~=MODEL_ID then
        return nil
    end
    local count=0
    for _,p in ipairs(source:GetDescendants()) do
        if p:IsA("BasePart") then
            if not p:IsA("MeshPart") or p.CanCollide
                or p.CanTouch or p.CanQuery then return nil end
            count+=1
        elseif p:IsA("LuaSourceContainer") then return nil end
    end
    if count~=7 then return nil end
    local _,dims=source:GetBoundingBox()
    local minHorizontal=math.min(dims.X,dims.Z)
    local maxHorizontal=math.max(dims.X,dims.Z)
    if math.abs(dims.Y-4.87784)>.30
        or math.abs(minHorizontal-6.77)>.35
        or math.abs(maxHorizontal-40.64)>.50 then return nil end
    return source
end

-- Establish identity from real MapBuilder dimensions and authored position.
-- Require the real anchor, preserved signal and the two lift towers so
-- incomplete StreamingEnabled models NEVER hide only half a bridge.
local function nativeContext(arena)
    if not arena or not arena:IsA("Folder")
        or arena.Name~="Arena"
        or arena:GetAttribute("VariantId")~="Towers" then return nil end
    local root=workspace:FindFirstChild("GeneratedMap")
    if not root or not root:IsA("Folder") or arena.Parent~=root then
        return nil
    end
    local base=arena:FindFirstChild("Base")
    local decor=arena:FindFirstChild("Decor")
    if not base or not base:IsA("BasePart") or base.Parent~=arena
        or not base.Anchored or not base.CanCollide
        or base.Size.X<318 or base.Size.Z<318
        or not decor or not decor:IsA("Folder")
        or decor.Parent~=arena then return nil end
    local owner=decor:FindFirstChild("ArenaSignatureMegastructure")
    if not owner or not owner:IsA("Model") or owner.Parent~=decor
        or owner:GetAttribute("ChaosDistantScenery")~=true
        or owner:GetAttribute("SignatureVariant")~="Towers" then
        return nil
    end
    local bridge=owner:FindFirstChild("OverheadServiceBridge")
    local truss=owner:FindFirstChild("LowerTruss")
    local signal=owner:FindFirstChild("HangingSignal")
    if not bridge or not bridge:IsA("Part") or bridge.Parent~=owner
        or bridge.Shape~=Enum.PartType.Block or not bridge.Anchored
        or bridge.CanCollide or bridge.CanTouch or bridge.CanQuery
        or (bridge.Size-Vector3.new(41,2.4,6.5)).Magnitude>.10
        or not truss or not truss:IsA("Part") or truss.Parent~=owner
        or truss.Shape~=Enum.PartType.Block or not truss.Anchored
        or truss.CanCollide or truss.CanTouch or truss.CanQuery
        or (truss.Size-Vector3.new(35,.8,1.2)).Magnitude>.10
        or not signal or not signal:IsA("WedgePart")
        or signal.Parent~=owner or not signal.Anchored
        or signal.CanCollide or signal.CanTouch or signal.CanQuery
        or (signal.Size-Vector3.new(4.8,3,2)).Magnitude>.10 then
        return nil
    end
    for _,name in ipairs({"LiftTowerWest","LiftTowerEast"}) do
        local lift=owner:FindFirstChild(name)
        if not lift or not lift:IsA("Part") or lift.Parent~=owner
            or not lift.Anchored or lift.CanCollide or lift.CanTouch
            or lift.CanQuery or
            (lift.Size-Vector3.new(7,41,8)).Magnitude>.10 then
            return nil
        end
    end
    -- The true distant landmark sits outside the negative Z arena edge.
    local expected=base.Position+Vector3.new(
        base.Size.X*.24,base.Size.Y*.5+39,-(base.Size.Z*.5+66))
    if (bridge.Position-expected).Magnitude>.20 then return nil end
    local relative=bridge.CFrame:PointToObjectSpace(truss.Position)
    if (relative-Vector3.new(0,-3.4,-3.2)).Magnitude>.12
        or bridge.CFrame.LookVector:Dot(truss.CFrame.LookVector)<.999
        or bridge.CFrame.UpVector:Dot(truss.CFrame.UpVector)<.999 then
        return nil
    end
    local signalRelative=bridge.CFrame:PointToObjectSpace(signal.Position)
    if (signalRelative-Vector3.new(0,-5.3,-3)).Magnitude>.12 then
        return nil
    end
    return base,owner,bridge,truss
end

local function fittedModel(source,bridge)
    local clone=source:Clone()
    local _,dims=clone:GetBoundingBox()
    local localUnion=Vector3.new(41,5,7.05)
    local direct=math.abs(dims.X-localUnion.X)
        +math.abs(dims.Z-localUnion.Z)
    local swapped=math.abs(dims.Z-localUnion.X)
        +math.abs(dims.X-localUnion.Z)
    local yaw=direct<=swapped and 0 or math.pi*.5
    local width=yaw==0 and dims.X or dims.Z
    local depth=yaw==0 and dims.Z or dims.X
    local scale=math.min(1.045,
        localUnion.X*.985/width,
        localUnion.Y*.985/dims.Y,
        localUnion.Z*.985/depth)
    if scale<.80 or not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return nil
    end
    local frame,bounds=clone:GetBoundingBox()
    width=yaw==0 and bounds.X or bounds.Z
    depth=yaw==0 and bounds.Z or bounds.X
    if width>localUnion.X*.996 or depth>localUnion.Z*.996
        or bounds.Y>localUnion.Y*.996
        or width<localUnion.X*.90 or depth<localUnion.Z*.87
        or bounds.Y<localUnion.Y*.88 then
        clone:Destroy()
        return nil
    end
    -- Union midpoint relative to the real 41-stud bridge:
    -- native Y spans 35.2..40.2, center 37.7; Z spans -3.8..3.25.
    local target=bridge.CFrame*CFrame.new(0,-1.3,-.275)
        *CFrame.Angles(0,yaw,0)
    local pieces={}
    for _,part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            part.CFrame=target*frame:ToObjectSpace(part.CFrame)
            part.Anchored=true
            part.Massless=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.CastShadow=false
            part:SetAttribute("CosmeticOnly",true)
            part:SetAttribute("Original3DAssetId",MODEL_ID)
            pieces[#pieces+1]=part
        end
    end
    if #pieces~=7 then clone:Destroy();return nil end
    clone.Name="ApprovedTowersSignatureBridge3D"
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",MODEL_ID)
    return clone,pieces
end

local function mount(arena,source)
    if mounted then return end
    local base,owner,bridge,truss=nativeContext(arena)
    if not base then return end
    local clone,pieces=fittedModel(source,bridge)
    if not clone then return end
    local stillBase,stillOwner,stillBridge,stillTruss=nativeContext(arena)
    if stillBase~=base or stillOwner~=owner
        or stillBridge~=bridge or stillTruss~=truss
        or not source.Parent then
        clone:Destroy()
        return
    end
    local state={
        model=clone,pieces=pieces,source=source,arena=arena,
        owner=owner,base=base,originals={},frames={},
        connections={},
    }
    state.originals[bridge]=bridge.Transparency
    state.originals[truss]=truss.Transparency
    state.frames[bridge]=bridge.CFrame
    state.frames[truss]=truss.CFrame
    clone.Parent=bucket
    mounted=state
    bridge.Transparency=1
    truss.Transparency=1
    state.connections[#state.connections+1]=
        owner.AncestryChanged:Connect(function()
            if owner.Parent~=arena:FindFirstChild("Decor") then
                restore()
            end
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
        clone.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then restore() end
        end)
    for _,native in ipairs({bridge,truss}) do
        state.connections[#state.connections+1]=
            native.AncestryChanged:Connect(function()
                if native.Parent~=owner then restore() end
            end)
    end
end

bucket.ChildRemoved:Connect(function(child)
    if mounted and mounted.model==child then restore() end
end)

function Kit.sync(arena,cameraPoint,tier,cameraReady,pressure)
    if arena~=currentArena then clear();currentArena=arena end
    local cap=QUALITY[tier] or 0
    local load=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if load>=2 or (load==1 and tier~="High") then cap=0 end
    if cap==0 or not cameraReady or typeof(cameraPoint)~="Vector3" then
        restore()
        return
    end
    local base,owner,bridge,truss=nativeContext(arena)
    if not base then restore();return end
    local distance=(bridge.Position-cameraPoint).Magnitude
    if distance>(RANGE[tier] or 0)+(mounted and RETENTION or 0) then
        restore()
        return
    end
    if watchedBase~=base then
        for _,c in ipairs(baseConnections) do c:Disconnect() end
        table.clear(baseConnections)
        watchedBase=base
        local function checkBase()
            if base.Parent~=arena or not base.Anchored or not base.CanCollide
                or base.Size.X<318 or base.Size.Z<318 then
                restore()
            end
        end
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("Size"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("CanCollide"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base.AncestryChanged:Connect(checkBase)
    end
    local source=approvedSource()
    if not source then restore();return end
    if mounted then
        local bad=mounted.arena~=arena or mounted.owner~=owner
            or mounted.base~=base or mounted.source~=source
            or mounted.model.Parent~=bucket or #mounted.pieces~=7
        if not bad then
            for native,frame in pairs(mounted.frames) do
                if native.Parent~=owner
                    or (native.CFrame.Position-frame.Position).Magnitude>.08
                    or native.CFrame.LookVector:Dot(frame.LookVector)<.999
                    or native.CFrame.UpVector:Dot(frame.UpVector)<.999 then
                    bad=true
                    break
                end
            end
            for _,p in ipairs(mounted.pieces) do
                if not p:IsDescendantOf(mounted.model) then bad=true end
            end
        end
        if bad then restore() end
    end
    if not mounted then mount(arena,source) end
    if mounted then
        for part in pairs(mounted.originals) do
            part.Transparency=1
        end
    end
end

function Kit.count()
    return mounted and mounted.model.Parent==bucket
        and #mounted.pieces==7 and 1 or 0
end

function Kit.replacedNativeCount()
    if Kit.count()==0 then return 0 end
    local hidden=0
    for part in pairs(mounted.originals) do
        if part.Parent==mounted.owner and part.Transparency==1 then
            hidden+=1
        end
    end
    return hidden
end

return Kit
