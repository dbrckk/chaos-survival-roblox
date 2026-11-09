-- One source-authenticated REAL 3D toroidal megareactor replaces all 16
-- rectangular native ReactorArcs of the actual Orbital signature landmark.
-- Atomic cosmetics only: no new loop, physics, damages or remote fetches.
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Kit={}
local MODEL_ID=125070862497818
local RADIUS=20
local SEGMENTS=16
local CHORD=2*RADIUS*math.sin(math.pi/SEGMENTS)+.10
local LEVEL=29
local QUALITIES={Low=0,Medium=1,High=1}
local DISTANCE={Low=0,Medium=410,High=575}
local RETENTION=28

local bucket=Instance.new("Folder")
bucket.Name="ApprovedOrbitalSignatureTorusLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent=workspace

local activeArena=nil
local entry=nil
local watchedBase=nil
local baseConnections={}

local function restore()
    local current=entry
    if not current then return end
    entry=nil
    for _,c in ipairs(current.connections) do c:Disconnect() end
    for part,alpha in pairs(current.natives) do
        if part.Parent==current.owner and part:IsA("Part")
            and part.Anchored and not part.CanCollide
            and not part.CanTouch and not part.CanQuery
            and part.Transparency==1 then
            part.Transparency=alpha
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

local function sourceFor()
    local folder=ReplicatedStorage:FindFirstChild(
        "ApprovedOrbitalSignatureRingTemplates")
    if not folder or not folder:IsA("Folder")
        or folder.Parent~=ReplicatedStorage
        or folder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=folder:FindFirstChild("ReactorRing")
    if not source or not source:IsA("Model") or source.Parent~=folder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalOrbitalSignatureTorus3D")~=true
        or source:GetAttribute("Original3DAssetId")~=MODEL_ID then
        return nil
    end
    local n=0
    for _,p in ipairs(source:GetDescendants()) do
        if p:IsA("BasePart") then
            if not p:IsA("MeshPart") or p.CanCollide
                or p.CanTouch or p.CanQuery then return nil end
            n+=1
        elseif p:IsA("LuaSourceContainer") then return nil end
    end
    if n~=7 then return nil end
    local _,dims=source:GetBoundingBox()
    local lengths={dims.X,dims.Y,dims.Z}
    table.sort(lengths)
    if lengths[1]<1.05 or lengths[1]>1.60
        or lengths[2]<16.45 or lengths[2]>17.50
        or lengths[3]<16.45 or lengths[3]>17.50 then
        return nil
    end
    return source
end

local function context(arena)
    if not arena or not arena:IsA("Folder")
        or arena:GetAttribute("VariantId")~="Orbital" then return nil end
    local generated=workspace:FindFirstChild("GeneratedMap")
    if not generated or not generated:IsA("Folder")
        or arena.Parent~=generated or arena.Name~="Arena" then return nil end
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
        or owner:GetAttribute("SignatureVariant")~="Orbital" then return nil end

    local origin=base.Position+Vector3.new(base.Size.X*.24,
        base.Size.Y*.5,-(base.Size.Z*.5+66))
    local center=origin+Vector3.new(0,LEVEL,0)
    local arcs={}
    for k=0,SEGMENTS-1 do
        local arc=owner:FindFirstChild("ReactorArc"..(k+1))
        if not arc or not arc:IsA("Part") or arc.Parent~=owner
            or arc.Shape~=Enum.PartType.Block
            or not arc.Anchored or arc.CanCollide
            or arc.CanTouch or arc.CanQuery
            or (arc.Size-Vector3.new(CHORD,1.35,2.1)).Magnitude>.10 then
            return nil
        end
        local angle=k*math.tau/SEGMENTS
        local intended=CFrame.new(center+Vector3.new(
            RADIUS*math.sin(angle),RADIUS*math.cos(angle),0))
            *CFrame.Angles(0,0,-angle)
        if (arc.Position-intended.Position).Magnitude>.16
            or arc.CFrame.LookVector:Dot(intended.LookVector)<.999
            or arc.CFrame.UpVector:Dot(intended.UpVector)<.999 then
            return nil
        end
        arcs[#arcs+1]=arc
    end
    -- Do not remove the suspended glowing reactor ball or its real
    -- support system; also reject partially streamed core structures.
    local core=owner:FindFirstChild("SuspendedReactorCore")
    local retainer=owner:FindFirstChild("CoreRetainer")
    if not core or not core:IsA("Part") or core.Parent~=owner
        or core.Shape~=Enum.PartType.Ball or not core.Anchored
        or core.CanCollide or core.CanTouch or core.CanQuery
        or (core.Size-Vector3.new(10,10,10)).Magnitude>.1
        or not retainer or not retainer:IsA("Part")
        or retainer.Parent~=owner or not retainer.Anchored
        or retainer.CanCollide or retainer.CanTouch or retainer.CanQuery then
        return nil
    end
    return base,owner,arcs,center
end

local function fit(source,center)
    local model=source:Clone()
    local _,sourceBounds=model:GetBoundingBox()
    local thinAxis
    if sourceBounds.Z<sourceBounds.X and sourceBounds.Z<sourceBounds.Y then
        thinAxis="Z"
    elseif sourceBounds.Y<sourceBounds.X and sourceBounds.Y<sourceBounds.Z then
        thinAxis="Y"
    elseif sourceBounds.X<sourceBounds.Y and sourceBounds.X<sourceBounds.Z then
        thinAxis="X"
    else
        model:Destroy()
        return nil
    end
    local major=math.max(sourceBounds.X,sourceBounds.Y,sourceBounds.Z)
    local scale=40.8/major
    if scale<2.1 or scale>2.65
        or not pcall(function() model:ScaleTo(scale) end) then
        model:Destroy()
        return nil
    end
    local sourceFrame,dimensions=model:GetBoundingBox()
    local dims={dimensions.X,dimensions.Y,dimensions.Z}
    table.sort(dims)
    if dims[1]<2.4 or dims[1]>4.6
        or dims[2]<39.0 or dims[2]>42.3
        or dims[3]<39.0 or dims[3]>42.3 then
        model:Destroy()
        return nil
    end
    local rotation=CFrame.identity
    if thinAxis=="Y" then
        rotation=CFrame.Angles(math.pi*.5,0,0)
    elseif thinAxis=="X" then
        rotation=CFrame.Angles(0,math.pi*.5,0)
    end
    local target=CFrame.new(center)*rotation
    local pieces={}
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then model:Destroy();return nil end
            part.CFrame=target*sourceFrame:ToObjectSpace(part.CFrame)
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
    if #pieces~=7 then model:Destroy();return nil end
    model.Name="OriginalOrbitalSignatureTorus3D"
    model:SetAttribute("CosmeticOnly",true)
    model:SetAttribute("Original3DAssetId",MODEL_ID)
    return model,pieces
end

local function mount(arena,source)
    if entry then return end
    local base,owner,arcs,center=context(arena)
    if not base then return end
    local model,pieces=fit(source,center)
    if not model then return end
    local currentBase,currentOwner,currentArcs=context(arena)
    if currentBase~=base or currentOwner~=owner
        or not source.Parent or not currentArcs or #currentArcs~=SEGMENTS then
        model:Destroy()
        return
    end
    local item={
        model=model,pieces=pieces,natives={},frames={},
        owner=owner,arena=arena,source=source,
        base=base,connections={},
    }
    for _,arc in ipairs(arcs) do
        item.natives[arc]=arc.Transparency
        item.frames[arc]=arc.CFrame
    end
    model.Parent=bucket
    entry=item
    for _,arc in ipairs(arcs) do arc.Transparency=1 end
    item.connections[#item.connections+1]=
        owner.AncestryChanged:Connect(function()
            if owner.Parent~=arena:FindFirstChild("Decor") then restore() end
        end)
    item.connections[#item.connections+1]=
        source.AncestryChanged:Connect(function()
            if not source.Parent then restore() end
        end)
    item.connections[#item.connections+1]=
        source.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then restore() end
        end)
    item.connections[#item.connections+1]=
        model.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then restore() end
        end)
    for _,arc in ipairs(arcs) do
        item.connections[#item.connections+1]=
            arc.AncestryChanged:Connect(function()
                if arc.Parent~=owner then restore() end
            end)
    end
end

bucket.ChildRemoved:Connect(function(child)
    if entry and entry.model==child then restore() end
end)

function Kit.sync(arena,cameraPoint,tier,cameraReady,pressure)
    if arena~=activeArena then clear();activeArena=arena end
    local cap=QUALITIES[tier] or 0
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if stress==1 and tier~="High" then cap=0 end
    if stress>=2 then cap=0 end
    if cap==0 or not cameraReady or typeof(cameraPoint)~="Vector3" then
        restore()
        return
    end
    local base,owner,arcs,center=context(arena)
    if not base then restore();return end
    local distance=(center-cameraPoint).Magnitude
    local maxDistance=(DISTANCE[tier] or 0)+(entry and RETENTION or 0)
    if distance>maxDistance then restore();return end
    if watchedBase~=base then
        for _,c in ipairs(baseConnections) do c:Disconnect() end
        table.clear(baseConnections)
        watchedBase=base
        local function checkBase()
            if base.Parent~=arena or not base.Anchored or not base.CanCollide
                or base.Size.X<318 or base.Size.Z<318 then restore() end
        end
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("Size"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("CanCollide"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base.AncestryChanged:Connect(checkBase)
    end
    local source=sourceFor()
    if not source then restore();return end
    if entry then
        local bad=entry.arena~=arena or entry.owner~=owner
            or entry.base~=base or entry.source~=source
            or entry.model.Parent~=bucket or #entry.pieces~=7
        if not bad then
            for native,frame in pairs(entry.frames) do
                if native.Parent~=owner
                    or (native.CFrame.Position-frame.Position).Magnitude>.08
                    or native.CFrame.LookVector:Dot(frame.LookVector)<.999
                    or native.CFrame.UpVector:Dot(frame.UpVector)<.999 then
                    bad=true
                    break
                end
            end
            for _,p in ipairs(entry.pieces) do
                if not p:IsDescendantOf(entry.model) then bad=true end
            end
        end
        if bad then restore() end
    end
    if not entry then mount(arena,source) end
    if entry then
        for native in pairs(entry.natives) do native.Transparency=1 end
    end
end

function Kit.count()
    return entry and entry.model.Parent==bucket
        and #entry.pieces==7 and 1 or 0
end

function Kit.replacedNativeCount()
    if Kit.count()==0 then return 0 end
    local hidden=0
    for native in pairs(entry.natives) do
        if native.Parent==entry.owner and native.Transparency==1 then
            hidden+=1
        end
    end
    return hidden
end

return Kit
