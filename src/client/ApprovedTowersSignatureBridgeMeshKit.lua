-- Genuine original forged bridge, 7 physical MeshParts (cosmetic only).
-- Replaces exactly two big nonphysical native slab Parts on the true Towers
-- ArenaSignatureMegastructure and supplies the sculpted timed shutter profile.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ExteriorDetailGeometry = require("./ExteriorDetailGeometry")

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

local MODEL_ID=126298311664881
Kit.AssetId = MODEL_ID
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
        if native.Parent==state.owner and native:IsA("BasePart")
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

function Kit.sweptProfile()
    local model = approvedSource()
    local profile = model and model:FindFirstChild("SweptCrossbeam")
    if profile and profile:IsA("MeshPart") and profile.Archivable and profile.MeshId ~= "" then
        return profile
    end
    return nil
end

function Kit.bindShutterSkin(gate, profile)
    if not gate:IsA("Part") or not gate.Parent or not gate.Anchored
        or gate:GetAttribute("BridgeShutter") ~= true then return nil end
    local skin = profile:Clone()
    if not skin then return nil end
    local acrossX = gate.Size.X > gate.Size.Z
    local sourceAlongX = skin.Size.X > skin.Size.Z
    skin:ClearAllChildren()
    skin.TextureID = ""
    skin.MaterialVariant = ""
    skin.Name = "SculptedShutterFace"
    skin.Size = sourceAlongX == acrossX and gate.Size
        or Vector3.new(gate.Size.Z, gate.Size.Y, gate.Size.X)
    skin.CFrame = gate.CFrame * CFrame.Angles(0, sourceAlongX ~= acrossX and math.pi * .5 or 0, 0)
    skin.Color = gate.Color
    skin.Material = gate.Material
    skin.Transparency = gate.Transparency
    skin.LocalTransparencyModifier = 0
    skin.CanCollide = false
    skin.CanTouch = false
    skin.CanQuery = false
    skin.CastShadow = false
    skin.Massless = true

    local joint = Instance.new("WeldConstraint")
    joint.Name = "ShutterSkinWeld"
    joint.Part0 = gate
    joint.Part1 = skin
    joint.Parent = skin
    skin.Anchored = false
    skin.Parent = gate

    local nativeAlpha = gate.LocalTransparencyModifier
    local connections = {}
    local released = false
    local function release()
        if released then return end
        released = true
        for _, connection in ipairs(connections) do connection:Disconnect() end
        if gate.LocalTransparencyModifier == 1 then
            gate.LocalTransparencyModifier = nativeAlpha
        end
        skin:Destroy()
    end
    connections = {
        gate:GetPropertyChangedSignal("Color"):Connect(function()
            skin.Color = gate.Color
        end),
        gate:GetPropertyChangedSignal("Transparency"):Connect(function()
            skin.Transparency = gate.Transparency
        end),
        skin.AncestryChanged:Connect(function()
            if skin.Parent ~= gate or not gate.Parent then release() end
        end),
        joint.AncestryChanged:Connect(function()
            if joint.Parent ~= skin then release() end
        end),
    }
    gate.LocalTransparencyModifier = 1
    return skin, release
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
    local originalX, originalZ = originalFootprint(base, arena)
    if not base or not base:IsA("BasePart") or base.Parent~=arena
        or not base.Anchored or not base.CanCollide
        or not originalFootprint(base,arena)
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
    local bridgeSize,bridgePose=ExteriorDetailGeometry.monumentFootprint(bridge,owner,"Part")
    local trussSize,trussPose=ExteriorDetailGeometry.monumentFootprint(truss,owner,"Part")
    local signalSize,signalPose=ExteriorDetailGeometry.monumentFootprint(signal,owner,"WedgePart")
    if not bridgeSize or (bridgeSize-Vector3.new(41,2.4,6.5)).Magnitude>.10
        or not trussSize or (trussSize-Vector3.new(35,.8,1.2)).Magnitude>.10
        or not signalSize or (signalSize-Vector3.new(4.8,3,2)).Magnitude>.10 then
        return nil
    end
    for _,name in ipairs({"LiftTowerWest","LiftTowerEast"}) do
        local lift=owner:FindFirstChild(name)
        local size=ExteriorDetailGeometry.monumentFootprint(lift,owner,"Part")
        if not size or (size-Vector3.new(7,41,8)).Magnitude>.10 then
            return nil
        end
    end
    -- The true distant landmark sits outside the negative Z arena edge.
    local expected=base.Position+Vector3.new(
        originalX*.24,base.Size.Y*.5+39,-(originalZ*.5+66))
    if (bridgePose.Position-expected).Magnitude>.20 then return nil end
    local relative=bridgePose:PointToObjectSpace(trussPose.Position)
    if (relative-Vector3.new(0,-3.4,-3.2)).Magnitude>.12
        or bridgePose.LookVector:Dot(trussPose.LookVector)<.999
        or bridgePose.UpVector:Dot(trussPose.UpVector)<.999 then
        return nil
    end
    local signalRelative=bridgePose:PointToObjectSpace(signalPose.Position)
    if (signalRelative-Vector3.new(0,-5.3,-3)).Magnitude>.12 then
        return nil
    end
    return base,owner,bridge,truss,bridgePose
end

local function fittedModel(source,bridgePose)
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
    local target=bridgePose*CFrame.new(0,-1.3,-.275)
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
    local base,owner,bridge,truss,bridgePose=nativeContext(arena)
    if not base then return end
    local clone,pieces=fittedModel(source,bridgePose)
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
                or not originalFootprint(base,arena) then
                restore()
            end
        end
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("Size"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("CanCollide"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base.AncestryChanged:Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base:GetAttributeChangedSignal("OriginalSizeX"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base:GetAttributeChangedSignal("OriginalSizeZ"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("Anchored"):Connect(checkBase)
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
