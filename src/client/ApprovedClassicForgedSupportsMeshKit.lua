-- Original approved Classic forge supports; restores 5 native Parts if
-- anything fails. The pre-existing seven-part main twin-dish kit remains
-- independently mounted/validated and is NEVER modified by this script.
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Kit={}
local MODEL_ID=91717127334369
-- At Low one approved seven-MeshPart sculpture replaces FIVE verified
-- nonphysical primitive supports; pressure 1 restores natives immediately.
local QUALITY={Low=1,Medium=1,High=1}
local RANGE={Low=320,Medium=440,High=610}
local RETENTION=26
local NAMES={
    "RelayButtressWest","RelayButtressEast",
    "RelaySparWest","RelaySparEast","ServicePanel",
}
local SIZES={
    Vector3.new(3.5,33,4.5),Vector3.new(3.5,33,4.5),
    Vector3.new(1.1,31,1.4),Vector3.new(1.1,31,1.4),
    Vector3.new(5,3.2,.55),
}
local FRAMES={
    CFrame.new(-11.8,16.5,0),
    CFrame.new(11.8,16.5,0),
    CFrame.new(-7.5,24,-.8)*CFrame.Angles(0,0,-math.rad(21)),
    CFrame.new(7.5,24,-.8)*CFrame.Angles(0,0,math.rad(21)),
    CFrame.new(0,35,-2.25),
}
local REQUIRED_PRIMARY={
    "PrimaryRelayMast","RelayHead","DishBridge",
    "ReceiverDishWest","ReceiverDishEast",
    "ReceiverHubWest","ReceiverHubEast",
}
local bucket=Instance.new("Folder")
bucket.Name="ApprovedClassicForgedSupportsLocal"
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
    for _,connection in ipairs(state.connections) do
        connection:Disconnect()
    end
    -- The server's authentic native is still authoritative and must
    -- always be restored before optional 3D art is removed.
    for native,alpha in pairs(state.originals) do
        if native.Parent==state.owner and native:IsA("Part")
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
    currentArena=nil
    bucket:ClearAllChildren()
end

local function approvedSource()
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedClassicForgedSupportTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent~=ReplicatedStorage
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=holder:FindFirstChild("ForgedSupports")
    if not source or not source:IsA("Model")
        or source.Parent~=holder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalClassicForgedSupports3D")~=true
        or source:GetAttribute("Original3DAssetId")~=MODEL_ID then
        return nil
    end
    local count=0
    for _,obj in ipairs(source:GetDescendants()) do
        if obj:IsA("BasePart") then
            if not obj:IsA("MeshPart") or obj.CanCollide
                or obj.CanTouch or obj.CanQuery then return nil end
            count+=1
        elseif obj:IsA("LuaSourceContainer") then return nil end
    end
    if count~=7 then return nil end
    local _,b=source:GetBoundingBox()
    local a,z=math.min(b.X,b.Z),math.max(b.X,b.Z)
    if math.abs(b.Y-19.26613)>.42
        or math.abs(a-2.47275)>.27
        or math.abs(z-13.47557)>.46 then
        return nil
    end
    return source
end

local function nativeContext(arena)
    if not arena or not arena:IsA("Folder") or arena.Name~="Arena"
        or arena:GetAttribute("VariantId")~="Classic" then return nil end
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
        or owner:GetAttribute("SignatureVariant")~="Classic" then
        return nil
    end
    local origin=CFrame.new(base.Position+Vector3.new(
        base.Size.X*.24,base.Size.Y*.5,-(base.Size.Z*.5+66)))
    local natives={}
    for index,name in ipairs(NAMES) do
        local native=owner:FindFirstChild(name)
        local expected=origin*FRAMES[index]
        if not native or not native:IsA("Part")
            or native.Parent~=owner or native.Shape~=Enum.PartType.Block
            or not native.Anchored or native.CanCollide or native.CanTouch
            or native.CanQuery
            or (native.Size-SIZES[index]).Magnitude>.10
            or (native.Position-expected.Position).Magnitude>.16
            or native.CFrame.LookVector:Dot(expected.LookVector)<.999
            or native.CFrame.UpVector:Dot(expected.UpVector)<.999 then
            return nil
        end
        natives[#natives+1]=native
    end
    -- The existing seven approved primary replacements are independent:
    -- require the original seven native pieces for full map streaming,
    -- but do NOT read or change their transparency or their local model.
    for _,name in ipairs(REQUIRED_PRIMARY) do
        local native=owner:FindFirstChild(name)
        if not native or not native:IsA("BasePart")
            or native.Parent~=owner or not native.Anchored
            or native.CanCollide or native.CanTouch
            or native.CanQuery then
            return nil
        end
    end
    return base,owner,natives,origin
end

local function sculpture(source,origin)
    local clone=source:Clone()
    local _,native=clone:GetBoundingBox()
    local direct=math.abs(native.X-13.47557)
        +math.abs(native.Z-2.47275)
    local swapped=math.abs(native.Z-13.47557)
        +math.abs(native.X-2.47275)
    local yaw=direct<=swapped and 0 or math.pi*.5
    local x=yaw==0 and native.X or native.Z
    local z=yaw==0 and native.Z or native.X
    -- The real sculpt has world size 26.95114 × 38.53226 × 4.9455;
    -- ScaleTo is uniform and cannot squash the diagonal load spars.
    local factor=math.min(2.0,27.5*.99/x,39.0*.99/native.Y,5.30*.99/z)
    if factor<1.90 or not pcall(function() clone:ScaleTo(factor) end) then
        clone:Destroy()
        return nil
    end
    local originalFrame,dims=clone:GetBoundingBox()
    x=yaw==0 and dims.X or dims.Z
    z=yaw==0 and dims.Z or dims.X
    if x<26.1 or x>27.5 or dims.Y<37.0 or dims.Y>39.0
        or z<4.40 or z>5.30 then
        clone:Destroy()
        return nil
    end
    -- Underlying authored MapBuilder originals span approximately
    -- X±13.5, Y 0..38.6 and Z -2.7..2.2. The visual center is
    -- outboard from gameplay, just north of the existing signature.
    local target=origin*CFrame.new(0,19.32,-.14)
        *CFrame.Angles(0,yaw,0)
    local parts={}
    for _,part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            part.CFrame=target*originalFrame:ToObjectSpace(part.CFrame)
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
    clone.Name="ApprovedClassicForgedSupports3D"
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",MODEL_ID)
    return clone,parts
end

local function mount(arena,source)
    if mounted then return end
    local base,owner,natives,origin=nativeContext(arena)
    if not base then return end
    local model,parts=sculpture(source,origin)
    if not model then return end
    local checkBase,checkOwner,checkNatives=nativeContext(arena)
    if checkBase~=base or checkOwner~=owner
        or not checkNatives or not source.Parent then
        model:Destroy()
        return
    end
    for i,native in ipairs(natives) do
        if checkNatives[i]~=native then model:Destroy();return end
    end
    local state={
        arena=arena,base=base,owner=owner,source=source,
        model=model,parts=parts,originals={},frames={},
        connections={},
    }
    for _,part in ipairs(natives) do
        state.originals[part]=part.Transparency
        state.frames[part]=part.CFrame
    end
    model.Parent=bucket
    mounted=state
    for _,native in ipairs(natives) do native.Transparency=1 end
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
        model.DescendantRemoving:Connect(function(part)
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
    if arena~=currentArena then clear();currentArena=arena end
    local n=QUALITY[tier] or 0
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if stress>=2 or (stress==1 and tier~="High") then n=0 end
    if n==0 or not cameraReady or typeof(cameraPoint)~="Vector3" then
        restore()
        return
    end
    local base,owner,natives,origin=nativeContext(arena)
    if not base then restore();return end
    local target=origin.Position+Vector3.new(0,19.32,-.14)
    if (cameraPoint-target).Magnitude>(RANGE[tier] or 0)
        +(mounted and RETENTION or 0) then
        restore()
        return
    end
    if watchedBase~=base then
        for _,c in ipairs(baseConnections) do c:Disconnect() end
        table.clear(baseConnections)
        watchedBase=base
        local function check()
            if base.Parent~=arena or not base.Anchored or not base.CanCollide
                or base.Size.X<318 or base.Size.Z<318 then
                restore()
            end
        end
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("Size"):Connect(check)
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("CanCollide"):Connect(check)
        baseConnections[#baseConnections+1]=
            base.AncestryChanged:Connect(check)
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
                    or (native.Position-frame.Position).Magnitude>.09
                    or native.CFrame.LookVector:Dot(frame.LookVector)<.999
                    or native.CFrame.UpVector:Dot(frame.UpVector)<.999 then
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
        for native in pairs(mounted.originals) do native.Transparency=1 end
    end
end

function Kit.count()
    return mounted and mounted.model.Parent==bucket
        and #mounted.parts==7 and 1 or 0
end

function Kit.replacedNativeCount()
    if Kit.count()==0 then return 0 end
    local n=0
    for native in pairs(mounted.originals) do
        if native.Parent==mounted.owner and native.Transparency==1 then n+=1 end
    end
    return n
end

return Kit
