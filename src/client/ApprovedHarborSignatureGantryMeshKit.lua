-- Harbor nonphysical industrial mega-gantry: genuine original 3D, 7 MeshParts.
-- Three exact real primitive Parts are hidden only after full model mount.
-- The crane legs, hoists, winches, spreader and cargo keep their native art.
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Kit={}
local MODEL_ID=124368710235343
-- Android Low: one authenticated seven-MeshPart landmark instead of
-- 3 distant primitive silhouette Parts, only at VFX pressure zero.
-- These three variants are mutually exclusive on the same active arena.
local QUALITY={Low=1,Medium=1,High=1}
local RANGE={Low=290,Medium=440,High=610}
local RETENTION=26
local NAMES={
    "QuayCraneSpanningBeam","QuayCraneCounterweight","QuayControlCab",
}
local SIZES={
    Vector3.new(41,2.1,4.4),
    Vector3.new(7,5.8,7),
    Vector3.new(7.2,5.4,5.2),
}
local bucket=Instance.new("Folder")
bucket.Name="ApprovedHarborSignatureGantryLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent=workspace

local activeArena=nil
local mounted=nil
local watchedBase=nil
local baseConnections={}

local function restore()
    local state=mounted
    if not state then return end
    mounted=nil
    for _,c in ipairs(state.connections) do c:Disconnect() end
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
    for _,c in ipairs(baseConnections) do c:Disconnect() end
    table.clear(baseConnections)
    watchedBase=nil
    activeArena=nil
    bucket:ClearAllChildren()
end

local function approvedSource()
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedHarborSignatureGantryTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent~=ReplicatedStorage
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=holder:FindFirstChild("SculptedGantry")
    if not source or not source:IsA("Model") or source.Parent~=holder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalHarborSignatureGantry3D")~=true
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
    local _,size=source:GetBoundingBox()
    local small,large=math.min(size.X,size.Z),math.max(size.X,size.Z)
    if math.abs(size.Y-14.0425)>.44
        or math.abs(small-9.141)>.40
        or math.abs(large-40.8)>.52 then return nil end
    return source
end

-- Exterior gantry stays at the originally authored northern berth.
-- Only the survival floor contracts during Shrinking Arena.
local function authenticBase(base,arena)
    if not base or not base:IsA("BasePart") or base.Parent~=arena
        or not base.Anchored or not base.CanCollide then return false end
    local sx=base:GetAttribute("OriginalSizeX")
    local sz=base:GetAttribute("OriginalSizeZ")
    return typeof(sx)=="number" and typeof(sz)=="number"
        and sx>=318 and sz>=318
        and base.Size.X>0 and base.Size.Z>0
        and base.Size.X<=sx+.2 and base.Size.Z<=sz+.2
end

local function realContext(arena)
    if not arena or not arena:IsA("Folder") or arena.Name~="Arena"
        or arena:GetAttribute("VariantId")~="Harbor" then return nil end
    local generated=workspace:FindFirstChild("GeneratedMap")
    if not generated or not generated:IsA("Folder")
        or arena.Parent~=generated then return nil end
    local base=arena:FindFirstChild("Base")
    local decor=arena:FindFirstChild("Decor")
    if not authenticBase(base,arena)
        or not decor or not decor:IsA("Folder")
        or decor.Parent~=arena then return nil end
    local owner=decor:FindFirstChild("ArenaSignatureMegastructure")
    if not owner or not owner:IsA("Model") or owner.Parent~=decor
        or owner:GetAttribute("ChaosDistantScenery")~=true
        or owner:GetAttribute("SignatureVariant")~="Harbor" then
        return nil
    end
    local natives={}
    for i,name in ipairs(NAMES) do
        local part=owner:FindFirstChild(name)
        if not part or not part:IsA("Part") or part.Parent~=owner
            or part.Shape~=Enum.PartType.Block
            or not part.Anchored or part.CanCollide or part.CanTouch
            or part.CanQuery or (part.Size-SIZES[i]).Magnitude>.12 then
            return nil
        end
        natives[i]=part
    end
    local beam=natives[1]
    local originalX=base:GetAttribute("OriginalSizeX")
    local originalZ=base:GetAttribute("OriginalSizeZ")
    local expected=base.Position+Vector3.new(
        originalX*.24,base.Size.Y*.5+43.5,-(originalZ*.5+66))
    if (beam.Position-expected).Magnitude>.20 then return nil end
    -- Authored MapBuilder frame relationships are exact and unchanged.
    local expectedRelative={
        CFrame.new(-10,4.5,3),
        CFrame.new(4.8,-4,0),
    }
    for i=2,3 do
        local observed=beam.CFrame:ToObjectSpace(natives[i].CFrame)
        local target=expectedRelative[i-1]
        if (observed.Position-target.Position).Magnitude>.12
            or observed.LookVector:Dot(target.LookVector)<.999
            or observed.UpVector:Dot(target.UpVector)<.999 then
            return nil
        end
    end

    -- Require existing safety silhouettes; a partially streamed model
    -- must never hide the huge crane before its other structure loads.
    local companions={
        {"QuayPortLeg",Vector3.new(3.3,40,3.8)},
        {"QuayStarboardLeg",Vector3.new(3.3,40,3.8)},
        {"QuayWinchPort",Vector3.new(5.4,4.2,5.5)},
        {"QuayWinchStarboard",Vector3.new(5.4,4.2,5.5)},
        {"QuayHoistPort",Vector3.new(.3,17,.3)},
        {"QuayHoistStarboard",Vector3.new(.3,17,.3)},
        {"QuayStormMast",Vector3.new(1.1,11.5,1.1)},
        {"QuayCargoStack",Vector3.new(21,4.2,9)},
        {"QuaySpreader",Vector3.new(25,.8,1.8)},
    }
    for _,pair in ipairs(companions) do
        local part=owner:FindFirstChild(pair[1])
        if not part or not part:IsA("Part") or part.Parent~=owner
            or not part.Anchored or part.CanCollide or part.CanTouch
            or part.CanQuery or (part.Size-pair[2]).Magnitude>.12 then
            return nil
        end
    end
    return base,owner,natives
end

local function fittedModel(source,beam)
    local model=source:Clone()
    local nativeBox=Vector3.new(41,14.1,9.1)
    local _,orig=model:GetBoundingBox()
    local direct=math.abs(orig.X-nativeBox.X)
        +math.abs(orig.Z-nativeBox.Z)
    local swapped=math.abs(orig.Z-nativeBox.X)
        +math.abs(orig.X-nativeBox.Z)
    local yaw=direct<=swapped and 0 or math.pi*.5
    local width=yaw==0 and orig.X or orig.Z
    local depth=yaw==0 and orig.Z or orig.X
    -- Uniform ScaleTo only; genuine roof/cab/weight proportions retained.
    local factor=math.min(1.045,nativeBox.X*.985/width,
        nativeBox.Y*.985/orig.Y,nativeBox.Z*.985/depth)
    if factor<.79 or not pcall(function() model:ScaleTo(factor) end) then
        model:Destroy()
        return nil
    end
    local frame,scaled=model:GetBoundingBox()
    width=yaw==0 and scaled.X or scaled.Z
    depth=yaw==0 and scaled.Z or scaled.X
    if width>nativeBox.X*.996 or depth>nativeBox.Z*.996
        or scaled.Y>nativeBox.Y*.996
        or width<nativeBox.X*.87 or depth<nativeBox.Z*.85
        or scaled.Y<nativeBox.Y*.87 then
        model:Destroy()
        return nil
    end
    -- Union center of the three authentic native forms: x=0,
    -- y=43.85,z=1.95. Original QuayCraneSpanningBeam center:
    -- x=0,y=43.5,z=0. Distinct cabin and counterweight keep position.
    local target=beam.CFrame*CFrame.new(0,.35,1.95)
        *CFrame.Angles(0,yaw,0)
    local meshes={}
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then model:Destroy();return nil end
            part.CFrame=target*frame:ToObjectSpace(part.CFrame)
            part.Anchored=true
            part.Massless=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.CastShadow=false
            part:SetAttribute("CosmeticOnly",true)
            part:SetAttribute("Original3DAssetId",MODEL_ID)
            meshes[#meshes+1]=part
        end
    end
    if #meshes~=7 then model:Destroy();return nil end
    model.Name="ApprovedHarborSculptedMegaGantry3D"
    model:SetAttribute("CosmeticOnly",true)
    model:SetAttribute("Original3DAssetId",MODEL_ID)
    return model,meshes
end

local function mount(arena,source)
    if mounted then return end
    local base,owner,natives=realContext(arena)
    if not base then return end
    local model,meshes=fittedModel(source,natives[1])
    if not model then return end
    local stillBase,stillOwner,again=realContext(arena)
    if stillBase~=base or stillOwner~=owner
        or not again or not source.Parent then
        model:Destroy()
        return
    end
    for i=1,3 do
        if again[i]~=natives[i] then model:Destroy();return end
    end
    local state={
        arena=arena,base=base,owner=owner,source=source,
        model=model,meshes=meshes,originals={},frames={},connections={},
    }
    for _,native in ipairs(natives) do
        state.originals[native]=native.Transparency
        state.frames[native]=native.CFrame
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
        source.DescendantRemoving:Connect(function(p)
            if p:IsA("MeshPart") then restore() end
        end)
    state.connections[#state.connections+1]=
        model.DescendantRemoving:Connect(function(p)
            if p:IsA("MeshPart") then restore() end
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
    local count=QUALITY[tier] or 0
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if stress>=2 or (stress==1 and tier~="High") then count=0 end
    if count==0 or not cameraReady or typeof(cameraPoint)~="Vector3" then
        restore()
        return
    end
    local base,owner,natives=realContext(arena)
    if not base then restore();return end
    local distance=(natives[1].Position-cameraPoint).Magnitude
    if distance>(RANGE[tier] or 0)+(mounted and RETENTION or 0) then
        restore()
        return
    end
    if watchedBase~=base then
        for _,c in ipairs(baseConnections) do c:Disconnect() end
        table.clear(baseConnections)
        watchedBase=base
        local function checkBase()
            if not authenticBase(base,arena) then restore() end
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
        local invalid=mounted.arena~=arena or mounted.owner~=owner
            or mounted.base~=base or mounted.source~=source
            or mounted.model.Parent~=bucket or #mounted.meshes~=7
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
            for _,mesh in ipairs(mounted.meshes) do
                if not mesh:IsDescendantOf(mounted.model) then
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
        and #mounted.meshes==7 and 1 or 0
end

function Kit.replacedNativeCount()
    if Kit.count()==0 then return 0 end
    local n=0
    for native in pairs(mounted.originals) do
        if native.Parent==mounted.owner and native.Transparency==1 then
            n+=1
        end
    end
    return n
end

return Kit
