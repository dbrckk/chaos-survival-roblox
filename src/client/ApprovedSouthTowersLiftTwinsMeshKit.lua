-- True creator-owned 3D South Towers Observation Torus.
-- Atomically replaces 14 nonphysical SouthHorizonMonument SkyTransfers.
-- Distinct from NORTH Towers reactor; no physics/network or extra loop.
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Kit={}
local MODEL_ID=114886409893890
local QUALITIES={Low=0,Medium=1,High=1}
local DISTANCE={Low=0,Medium=420,High=580}
local RETENTION=26
local bucket=Instance.new("Folder")
bucket.Name="ApprovedSouthTowersLiftTwinsLocal"
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
        "ApprovedSouthTowersLiftTwinsTemplates")
    if not folder or not folder:IsA("Folder")
        or folder.Parent~=ReplicatedStorage
        or folder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=folder:FindFirstChild("ForgedLiftTwins")
    if not source or not source:IsA("Model") or source.Parent~=folder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalSouthTowersForgedLiftTwins3D")~=true
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
    if lengths[1]<2.65 or lengths[1]>3.20
        or lengths[2]<17.40 or lengths[2]>18.10
        or lengths[3]<19.50 or lengths[3]>20.75 then
        return nil
    end
    return source
end

local function context(arena)
    if not arena or not arena:IsA("Folder")
        or arena:GetAttribute("VariantId")~="Towers" then return nil end
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
    local owner=decor:FindFirstChild("SouthHorizonMonument")
    if not owner or not owner:IsA("Model") or owner.Parent~=decor
        or owner:GetAttribute("ChaosDistantScenery")~=true
        or owner:GetAttribute("SignatureVariant")~="Towers" then return nil end
    local origin=base.Position+Vector3.new(-base.Size.X*.20,
        base.Size.Y*.5,base.Size.Z*.5+54)
    local names={"WestLift","EastLift","WestCrown","EastCrown"}
    local sizes={
        Vector3.new(6.5,37,7),Vector3.new(6.5,46,7),
        Vector3.new(9.5,4.5,8.5),Vector3.new(9.5,4.5,8.5),
    }
    local offsets={
        Vector3.new(-17.5,18.5,0),Vector3.new(17.5,23,0),
        Vector3.new(-17.5,39,0),Vector3.new(17.5,48,0),
    }
    local natives={}
    for i,name in ipairs(names) do
        local part=owner:FindFirstChild(name)
        if not part or not part:IsA("BasePart") or part.Parent~=owner
            or (i<=2 and not part:IsA("Part"))
            or (i>2 and not part:IsA("WedgePart"))
            or not part.Anchored or part.CanCollide
            or part.CanTouch or part.CanQuery
            or (part.Size-sizes[i]).Magnitude>.10
            or (part.Position-(origin+offsets[i])).Magnitude>.16
            or part.CFrame.LookVector:Dot(
                i==3 and Vector3.new(0,0,1) or Vector3.new(0,0,-1))<.999
            or part.CFrame.UpVector:Dot(Vector3.new(0,1,0))<.999 then
            return nil
        end
        natives[i]=part
    end
    -- Keep the existing approved skytransfer and all native signals,
    -- support rails and suspension links independent of this kit.
    for _,name in ipairs({"SkyTransfer","UnderslungLift",
        "WestLiftRail","EastLiftRail","WestSuspension",
        "EastSuspension","TransferSignal"}) do
        local p=owner:FindFirstChild(name)
        if not p or not p:IsA("BasePart") or p.Parent~=owner
            or not p.Anchored or p.CanCollide or p.CanTouch
            or p.CanQuery then return nil end
    end
    return base,owner,natives,origin+Vector3.new(0,25,0)
end

local function fit(source,center)
    local model=source:Clone()
    local _,dimensions=model:GetBoundingBox()
    local major=math.max(dimensions.X,dimensions.Y,dimensions.Z)
    local scale=50.115/major
    if scale<2.40 or scale>2.60
        or not pcall(function() model:ScaleTo(scale) end) then
        model:Destroy()
        return nil
    end
    local frame,scaled=model:GetBoundingBox()
    local sorted={scaled.X,scaled.Y,scaled.Z}
    table.sort(sorted)
    if sorted[1]<6.5 or sorted[1]>8.25
        or sorted[2]<43.1 or sorted[2]>45.5
        or sorted[3]<49.0 or sorted[3]>51.5 then
        model:Destroy()
        return nil
    end
    local target=CFrame.new(center)
    local pieces={}
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
            pieces[#pieces+1]=part
        end
    end
    if #pieces~=7 then model:Destroy();return nil end
    model.Name="OriginalSouthTowersForgedLiftTwins3D"
    model:SetAttribute("CosmeticOnly",true)
    model:SetAttribute("Original3DAssetId",MODEL_ID)
    return model,pieces
end

local function mount(arena,source)
    if entry then return end
    local base,owner,natives,center=context(arena)
    if not base then return end
    local model,pieces=fit(source,center)
    if not model then return end
    local currentBase,currentOwner,currentNatives=context(arena)
    if currentBase~=base or currentOwner~=owner
        or not source.Parent or not currentNatives or #currentNatives~=4 then
        model:Destroy()
        return
    end
    local item={
        model=model,pieces=pieces,natives={},frames={},
        owner=owner,arena=arena,source=source,
        base=base,connections={},
    }
    for _,native in ipairs(natives) do
        item.natives[native]=native.Transparency
        item.frames[native]=native.CFrame
    end
    model.Parent=bucket
    entry=item
    for _,native in ipairs(natives) do native.Transparency=1 end
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
    for _,native in ipairs(natives) do
        item.connections[#item.connections+1]=
            native.AncestryChanged:Connect(function()
                if native.Parent~=owner then restore() end
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
    local base,owner,natives,center=context(arena)
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
