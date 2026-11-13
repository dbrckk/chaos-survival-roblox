-- Owner-approved true 3D dual-level interchange for Crossroads skyline.
-- A single seven-MeshPart Model replaces the EXACT four decorative
-- Lower/UpperExchange + CantileverWest/East primitives atomically.
-- Real switchyard paths, collisions, AI and warning signage are unchanged.
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

local MODEL_ID=96622579843060
local RANGE={Low=320,Medium=405,High=580}
local RETENTION=25
-- At Low one approved seven-MeshPart interchange replaces FOUR native
-- wedges/slabs; the existing pressure 1/2 fallback remains authoritative.
local QUALITY={Low=1,Medium=1,High=1}
local NAMES={"LowerExchange","UpperExchange","CantileverWest","CantileverEast"}
local SIZES={
    Vector3.new(42,2,6),Vector3.new(48,1.3,5.4),
    Vector3.new(11,4,7),Vector3.new(11,4,7),
}
local bucket=Instance.new("Folder")
bucket.Name="ApprovedCrossroadsSignatureInterchangeLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent=workspace

local activeArena=nil
local mounted=nil
local watchedBase=nil
local baseConnections={}

local function restore()
    local current=mounted
    if not current then return end
    mounted=nil
    for _,c in ipairs(current.connections) do c:Disconnect() end
    for native,alpha in pairs(current.originals) do
        if native.Parent==current.owner and native:IsA("BasePart")
            and native.Anchored and not native.CanCollide
            and not native.CanTouch and not native.CanQuery
            and native.Transparency==1 then
            native.Transparency=alpha
        end
    end
    current.model:Destroy()
end

local function clear()
    restore()
    for _,c in ipairs(baseConnections) do c:Disconnect() end
    table.clear(baseConnections)
    watchedBase=nil
    activeArena=nil
    bucket:ClearAllChildren()
end

local function approvedSource()
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedCrossroadsSignatureInterchangeTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent~=ReplicatedStorage
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=holder:FindFirstChild("ForgedInterchange")
    if not source or not source:IsA("Model") or source.Parent~=holder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalCrossroadsSignatureInterchange3D")~=true
        or source:GetAttribute("Original3DAssetId")~=MODEL_ID then
        return nil
    end
    local count=0
    for _,item in ipairs(source:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or item.CanCollide
                or item.CanTouch or item.CanQuery then return nil end
            count+=1
        elseif item:IsA("LuaSourceContainer") then return nil end
    end
    if count~=7 then return nil end
    local _,b=source:GetBoundingBox()
    local small,large=math.min(b.X,b.Z),math.max(b.X,b.Z)
    if math.abs(b.Y-11.73404)>.45 or math.abs(small-6.76)>.36
        or math.abs(large-47.68)>.52 then return nil end
    return source
end

local function nativeContext(arena)
    if not arena or not arena:IsA("Folder") or arena.Name~="Arena"
        or arena:GetAttribute("VariantId")~="Crossroads" then return nil end
    local generated=workspace:FindFirstChild("GeneratedMap")
    if not generated or not generated:IsA("Folder")
        or arena.Parent~=generated then return nil end
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
        or owner:GetAttribute("SignatureVariant")~="Crossroads" then
        return nil
    end
    local natives={}
    for i,name in ipairs(NAMES) do
        local part=owner:FindFirstChild(name)
        local wedge=i>=3
        if not part or part.Parent~=owner
            or (wedge and not part:IsA("WedgePart"))
            or (not wedge and (not part:IsA("Part")
                              or part.Shape~=Enum.PartType.Block))
            or not part.Anchored or part.CanCollide or part.CanTouch
            or part.CanQuery or (part.Size-SIZES[i]).Magnitude>.10 then
            return nil
        end
        natives[i]=part
    end
    -- Require the authentic original signal devices and towers so
    -- StreamingEnabled cannot make a half-delivered model qualify.
    local signal=owner:FindFirstChild("Switchboard")
    local pylon=owner:FindFirstChild("SignalPylon")
    local crown=owner:FindFirstChild("SignalCrown")
    if not signal or not signal:IsA("Part") or signal.Parent~=owner
        or (signal.Size-Vector3.new(7.5,4.4,.55)).Magnitude>.10
        or not pylon or not pylon:IsA("Part") or pylon.Parent~=owner
        or (pylon.Size-Vector3.new(1.4,16,1.5)).Magnitude>.10
        or not crown or not crown:IsA("WedgePart") or crown.Parent~=owner
        or (crown.Size-Vector3.new(5.6,3.4,2.8)).Magnitude>.10 then
        return nil
    end
    for _,name in ipairs({"ExchangeLegWest","ExchangeLegEast"}) do
        local leg=owner:FindFirstChild(name)
        if not leg or not leg:IsA("Part") or leg.Parent~=owner
            or not leg.Anchored or leg.CanCollide or leg.CanTouch
            or leg.CanQuery
            or (leg.Size-Vector3.new(5.2,34,6)).Magnitude>.10 then
            return nil
        end
    end
    local lower=natives[1]
    local expected=base.Position+Vector3.new(
        originalX*.24,base.Size.Y*.5+29,-(originalZ*.5+66))
    if (lower.Position-expected).Magnitude>.20 then return nil end
    local relative={
        CFrame.new(0,7.5,0),
        CFrame.new(-18.3,9,0)*CFrame.Angles(0,math.pi,0),
        CFrame.new(18.3,9,0),
    }
    for i=2,4 do
        local part=natives[i]
        local observed=lower.CFrame:ToObjectSpace(part.CFrame)
        local intended=relative[i-1]
        if (observed.Position-intended.Position).Magnitude>.12
            or observed.LookVector:Dot(intended.LookVector)<.999
            or observed.UpVector:Dot(intended.UpVector)<.999 then
            return nil
        end
    end
    return base,owner,natives
end

local function fittedModel(source,lower)
    local clone=source:Clone()
    local original=Vector3.new(48,12,7)
    local _,dims=clone:GetBoundingBox()
    local direct=math.abs(dims.X-original.X)+math.abs(dims.Z-original.Z)
    local swapped=math.abs(dims.Z-original.X)+math.abs(dims.X-original.Z)
    local yaw=direct<=swapped and 0 or math.pi*.5
    local width=yaw==0 and dims.X or dims.Z
    local depth=yaw==0 and dims.Z or dims.X
    local scale=math.min(1.045,
        original.X*.985/width,
        original.Y*.985/dims.Y,
        original.Z*.985/depth)
    if scale<.80 or not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return nil
    end
    local frame,box=clone:GetBoundingBox()
    width=yaw==0 and box.X or box.Z
    depth=yaw==0 and box.Z or box.X
    if width>original.X*.996 or depth>original.Z*.996
        or box.Y>original.Y*.996
        or width<original.X*.90 or depth<original.Z*.87
        or box.Y<original.Y*.86 then
        clone:Destroy()
        return nil
    end
    -- The union of four original parts spans y=28..40 relative to
    -- signature origin. LowerExchange center is y=29 => union center +5.
    local target=lower.CFrame*CFrame.new(0,5,0)
        *CFrame.Angles(0,yaw,0)
    local parts={}
    for _,part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then clone:Destroy();return nil end
            part.CFrame=target*frame:ToObjectSpace(part.CFrame)
            part.Anchored=true
            part.Massless=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.CastShadow=false
            part:SetAttribute("CosmeticOnly",true)
            part:SetAttribute("Original3DAssetId",MODEL_ID)
            parts[#parts+1]=part
        end
    end
    if #parts~=7 then clone:Destroy();return nil end
    clone.Name="ApprovedCrossroadsForgedInterchange3D"
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",MODEL_ID)
    return clone,parts
end

local function mount(arena,source)
    if mounted then return end
    local base,owner,natives=nativeContext(arena)
    if not base then return end
    local clone,parts=fittedModel(source,natives[1])
    if not clone then return end
    local stillBase,stillOwner,stillNatives=nativeContext(arena)
    if stillBase~=base or stillOwner~=owner
        or not stillNatives or not source.Parent then
        clone:Destroy()
        return
    end
    for i=1,4 do
        if natives[i]~=stillNatives[i] then
            clone:Destroy()
            return
        end
    end
    local state={
        model=clone,parts=parts,source=source,arena=arena,
        base=base,owner=owner,originals={},frames={},connections={},
    }
    for _,native in ipairs(natives) do
        state.originals[native]=native.Transparency
        state.frames[native]=native.CFrame
    end
    clone.Parent=bucket
    mounted=state
    for _,native in ipairs(natives) do native.Transparency=1 end
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
        clone.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then restore() end
        end)
    for _,native in ipairs(natives) do
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
    if arena~=activeArena then clear();activeArena=arena end
    local available=QUALITY[tier] or 0
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if stress>=2 or (stress==1 and tier~="High") then available=0 end
    if available==0 or not cameraReady
        or typeof(cameraPoint)~="Vector3" then
        restore()
        return
    end
    local base,owner,natives=nativeContext(arena)
    if not base then restore();return end
    local dist=(natives[1].Position-cameraPoint).Magnitude
    if dist>(RANGE[tier] or 0)+(mounted and RETENTION or 0) then
        restore()
        return
    end
    if watchedBase~=base then
        for _,c in ipairs(baseConnections) do c:Disconnect() end
        table.clear(baseConnections)
        watchedBase=base
        local function validateBase()
            if base.Parent~=arena or not base.Anchored or not base.CanCollide
                or not originalFootprint(base,arena) then
                restore()
            end
        end
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("Size"):Connect(validateBase)
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("CanCollide"):Connect(validateBase)
        baseConnections[#baseConnections+1]=
            base.AncestryChanged:Connect(validateBase)
        baseConnections[#baseConnections+1]=
            base:GetAttributeChangedSignal("OriginalSizeX"):Connect(validateBase)
        baseConnections[#baseConnections+1]=
            base:GetAttributeChangedSignal("OriginalSizeZ"):Connect(validateBase)
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("Anchored"):Connect(validateBase)
    end
    local source=approvedSource()
    if not source then restore();return end
    if mounted then
        local invalid=mounted.arena~=arena or mounted.owner~=owner
            or mounted.base~=base or mounted.source~=source
            or mounted.model.Parent~=bucket or #mounted.parts~=7
        if not invalid then
            for native,frame in pairs(mounted.frames) do
                if native.Parent~=owner
                    or (native.CFrame.Position-frame.Position).Magnitude>.08
                    or native.CFrame.LookVector:Dot(frame.LookVector)<.999
                    or native.CFrame.UpVector:Dot(frame.UpVector)<.999 then
                    invalid=true
                    break
                end
            end
            for _,part in ipairs(mounted.parts) do
                if not part:IsDescendantOf(mounted.model) then invalid=true end
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
    return mounted and mounted.model.Parent==bucket
        and #mounted.parts==7 and 1 or 0
end

function Kit.replacedNativeCount()
    if Kit.count()==0 then return 0 end
    local hidden=0
    for native in pairs(mounted.originals) do
        if native.Parent==mounted.owner and native.Transparency==1 then
            hidden+=1
        end
    end
    return hidden
end

return Kit
