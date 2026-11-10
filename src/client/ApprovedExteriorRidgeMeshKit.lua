-- Four creator-owned sculpted ExteriorRidge originals, 3 wedges each.
-- A single existing scenery sample decides ranked camera LOD; no frame loop.
-- All wedge originals are hidden only after a fully validated mesh mounts.
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Kit={}
local CORNERS={"NW","NE","SW","SE"}
local PROFILES={
    NW={sx=-1,sz=-1,id=123836720232695,heights={17,13,9},
        bounds=Vector3.new(37.45768,15.9,33.90254),
        offset=Vector3.new(-1.55967,6.53,-1.6353)},
    NE={sx=1,sz=-1,id=83853948389204,heights={12,19,15},
        bounds=Vector3.new(37.90254,17.78,33.45768),
        offset=Vector3.new(1.6353,7.47,-1.55967)},
    SW={sx=-1,sz=1,id=108491064314671,heights={16,12,19},
        bounds=Vector3.new(37.90254,17.78,33.45768),
        offset=Vector3.new(-1.6353,7.47,1.55967)},
    SE={sx=1,sz=1,id=83023096720529,heights={11,18,14},
        bounds=Vector3.new(37.45768,16.84,33.90254),
        offset=Vector3.new(1.55967,7.0,1.6353)},
}
local VARIANTS={Classic=true,Towers=true,Crossroads=true,
    Orbital=true,Harbor=true}
local QUALITIES={Low=0,Medium=2,High=4}
local DISTANCE={Low=0,Medium=410,High=530}
local RETENTION=26
local bucket=Instance.new("Folder")
bucket.Name="ApprovedExteriorRidgesLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent=workspace

local activeArena=nil
local mounted={}
local baseConnections={}
local watchedBase=nil

local function dispose(owner)
    local entry=mounted[owner]
    if not entry then return end
    mounted[owner]=nil
    for _,c in ipairs(entry.connections) do c:Disconnect() end
    for part,alpha in pairs(entry.natives) do
        if part.Parent==owner and part:IsA("WedgePart")
            and part.Anchored and not part.CanCollide
            and not part.CanTouch and not part.CanQuery
            and part.Transparency==1 then
            part.Transparency=alpha
        end
    end
    entry.model:Destroy()
end

local function removeAll()
    local owners={}
    for owner in pairs(mounted) do owners[#owners+1]=owner end
    for _,owner in ipairs(owners) do dispose(owner) end
end

local function clear()
    removeAll()
    for _,c in ipairs(baseConnections) do c:Disconnect() end
    table.clear(baseConnections)
    watchedBase=nil
    activeArena=nil
    bucket:ClearAllChildren()
end

local function sourceFor(corner)
    local spec=PROFILES[corner]
    if not spec then return nil end
    local holder=ReplicatedStorage:FindFirstChild("ApprovedExteriorRidgeTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent~=ReplicatedStorage
        or holder:GetAttribute("OwnerVerified")~=true then
        return nil
    end
    local source=holder:FindFirstChild("Ridges"..corner)
    if not source or not source:IsA("Model")
        or source.Parent~=holder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalExteriorRidges3D")~=true
        or source:GetAttribute("Original3DAssetId")~=spec.id
        or source:GetAttribute("ExteriorCornerId")~=corner then
        return nil
    end
    local parts=0
    for _,p in ipairs(source:GetDescendants()) do
        if p:IsA("BasePart") then
            if not p:IsA("MeshPart") or p.CanCollide
                or p.CanTouch or p.CanQuery then return nil end
            parts+=1
        elseif p:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if parts~=7 then return nil end
    local _,size=source:GetBoundingBox()
    if (size-spec.bounds).Magnitude>.62 then return nil end
    return source
end

local function realRidges(arena,owner,corner)
    local spec=PROFILES[corner]
    if not spec or not arena or not arena:IsA("Folder")
        or not VARIANTS[arena:GetAttribute("VariantId")] then
        return nil
    end
    local generated=workspace:FindFirstChild("GeneratedMap")
    if not generated or not generated:IsA("Folder")
        or arena.Name~="Arena" or arena.Parent~=generated then
        return nil
    end
    local base=arena:FindFirstChild("Base")
    local decor=arena:FindFirstChild("Decor")
    if not base or not base:IsA("BasePart")
        or base.Parent~=arena or not base.Anchored
        or not base.CanCollide or base.Size.X<318
        or base.Size.Z<318 or not decor
        or not decor:IsA("Folder") or decor.Parent~=arena
        or not owner or not owner:IsA("Model")
        or owner.Parent~=decor
        or owner.Name~="ExteriorRidge"..corner
        or owner:GetAttribute("ChaosDistantScenery")~=true then
        return nil
    end
    local anchor=base.Position+Vector3.new(
        spec.sx*(base.Size.X*.5+28),base.Size.Y*.5,
        spec.sz*(base.Size.Z*.5+28))
    local yaw=math.atan2(spec.sx,spec.sz)
    local natives={}
    for index=1,3 do
        local height=9+((index*7+spec.sx*3+spec.sz*5+20)%11)
        if height~=spec.heights[index] then return nil end
        local ridge=owner:FindFirstChild("Ridge"..index)
        local expected=CFrame.new(anchor+Vector3.new(
            (index-2)*spec.sx*8,height*.5-1.5,
            (index-2)*spec.sz*6))
            *CFrame.Angles(0,yaw+(index-2)*.32,0)
        if not ridge or not ridge:IsA("WedgePart")
            or ridge.Parent~=owner or not ridge.Anchored
            or ridge.CanCollide or ridge.CanTouch or ridge.CanQuery
            or (ridge.Size-Vector3.new(11+index*3,
                height,13+index*2)).Magnitude>.12
            or (ridge.Position-expected.Position).Magnitude>.16
            or ridge.CFrame.LookVector:Dot(expected.LookVector)<.999
            or ridge.CFrame.UpVector:Dot(expected.UpVector)<.999
            or math.abs(ridge.Transparency-
                (.07+index*.04))>.03
                and ridge.Transparency~=1 then
            return nil
        end
        natives[#natives+1]=ridge
    end
    return base,natives,anchor
end

local function fit(source,corner,anchor)
    local spec=PROFILES[corner]
    local model=source:Clone()
    local frame,bounds=model:GetBoundingBox()
    if (bounds-spec.bounds).Magnitude>.62 then
        model:Destroy()
        return nil
    end
    -- Sculptor centered its source OBJ on its bounding box and emitted
    -- the exact source-world anchor offset, different for all four corners.
    -- Do not infer yaw from the arbitrary Model pivot: source vertices
    -- already have each of their THREE native wedge yaw transforms baked in.
    local target=CFrame.new(anchor+spec.offset)
    local pieces={}
    for _,p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            if not p:IsA("MeshPart") then
                model:Destroy()
                return nil
            end
            p.CFrame=target*frame:ToObjectSpace(p.CFrame)
            p.Anchored=true
            p.Massless=true
            p.CanCollide=false
            p.CanTouch=false
            p.CanQuery=false
            p.CastShadow=false
            p:SetAttribute("CosmeticOnly",true)
            p:SetAttribute("Original3DAssetId",spec.id)
            pieces[#pieces+1]=p
        end
    end
    if #pieces~=7 then model:Destroy();return nil end
    model.Name="OriginalExteriorRidges3D_"..corner
    model:SetAttribute("CosmeticOnly",true)
    model:SetAttribute("Original3DAssetId",spec.id)
    return model,pieces
end

local function mount(arena,owner,corner,source)
    if mounted[owner] then return end
    local base,natives,anchor=realRidges(arena,owner,corner)
    if not base then return end
    local model,pieces=fit(source,corner,anchor)
    if not model then return end
    local checkBase,checkNatives=realRidges(arena,owner,corner)
    if checkBase~=base or not checkNatives or #checkNatives~=3
        or not source.Parent then
        model:Destroy()
        return
    end
    local entry={
        model=model,pieces=pieces,source=source,
        base=base,corner=corner,frames={},natives={},connections={},
    }
    for _,native in ipairs(natives) do
        entry.natives[native]=native.Transparency
        entry.frames[native]=native.CFrame
    end
    model.Parent=bucket
    mounted[owner]=entry
    for _,native in ipairs(natives) do native.Transparency=1 end
    entry.connections[#entry.connections+1]=
        owner.AncestryChanged:Connect(function()
            if owner.Parent~=arena:FindFirstChild("Decor") then
                dispose(owner)
            end
        end)
    entry.connections[#entry.connections+1]=
        source.AncestryChanged:Connect(function()
            if not source.Parent then dispose(owner) end
        end)
    entry.connections[#entry.connections+1]=
        source.DescendantRemoving:Connect(function(p)
            if p:IsA("MeshPart") then dispose(owner) end
        end)
    entry.connections[#entry.connections+1]=
        model.DescendantRemoving:Connect(function(p)
            if p:IsA("MeshPart") then dispose(owner) end
        end)
    for _,native in ipairs(natives) do
        entry.connections[#entry.connections+1]=
            native.AncestryChanged:Connect(function()
                if native.Parent~=owner then dispose(owner) end
            end)
    end
end

bucket.ChildRemoved:Connect(function(child)
    for owner,entry in pairs(mounted) do
        if entry.model==child then dispose(owner);break end
    end
end)

function Kit.sync(arena,cameraPoint,tier,cameraReady,touch,pressure)
    if arena~=activeArena then clear();activeArena=arena end
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    local cap=QUALITIES[tier] or 0
    if tier=="High" and touch then cap=3 end
    if stress==1 then cap=math.floor(cap*.5) end
    if stress>=2 then cap=0 end
    if cap==0 or not cameraReady
        or typeof(cameraPoint)~="Vector3" then
        removeAll()
        return
    end
    local base=arena and arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") or not base.Anchored
        or not base.CanCollide or base.Size.X<318
        or base.Size.Z<318 then
        removeAll()
        return
    end
    if watchedBase~=base then
        for _,c in ipairs(baseConnections) do c:Disconnect() end
        table.clear(baseConnections)
        watchedBase=base
        local function checkBase()
            if base.Parent~=arena or not base.Anchored
                or not base.CanCollide or base.Size.X<318
                or base.Size.Z<318 then
                removeAll()
            end
        end
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("Size"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("CanCollide"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base.AncestryChanged:Connect(checkBase)
    end
    local decor=arena:FindFirstChild("Decor")
    local ranked={}
    if decor and decor:IsA("Folder") then
        for index,corner in ipairs(CORNERS) do
            local owner=decor:FindFirstChild("ExteriorRidge"..corner)
            local nativeBase,natives,anchor=realRidges(arena,owner,corner)
            local source=sourceFor(corner)
            if nativeBase and natives and source then
                local held=mounted[owner]~=nil
                local distance=(anchor-cameraPoint).Magnitude
                if distance<=(DISTANCE[tier] or 0)
                    +(held and RETENTION or 0) then
                    ranked[#ranked+1]={
                        owner=owner,base=base,corner=corner,
                        index=index,source=source,anchor=anchor,
                        score=distance-(held and RETENTION*.5 or 0),
                    }
                end
            end
        end
    end
    table.sort(ranked,function(a,b)
        if a.score~=b.score then return a.score<b.score end
        return a.index<b.index
    end)
    local wanted={}
    for i=1,math.min(cap,#ranked) do
        wanted[ranked[i].owner]=ranked[i]
    end
    for owner,entry in pairs(mounted) do
        local nextEntry=wanted[owner]
        local invalid=not nextEntry or nextEntry.corner~=entry.corner
            or nextEntry.source~=entry.source
            or nextEntry.base~=entry.base
            or entry.model.Parent~=bucket or #entry.pieces~=7
        if not invalid then
            for native,frame in pairs(entry.frames) do
                if native.Parent~=owner
                    or (native.Position-frame.Position).Magnitude>.08
                    or native.CFrame.LookVector:Dot(frame.LookVector)<.999
                    or native.CFrame.UpVector:Dot(frame.UpVector)<.999 then
                    invalid=true
                    break
                end
            end
            for _,p in ipairs(entry.pieces) do
                if not p:IsDescendantOf(entry.model) then
                    invalid=true
                    break
                end
            end
        end
        if invalid then
            dispose(owner)
        else
            for native in pairs(entry.natives) do native.Transparency=1 end
        end
    end
    for owner,candidate in pairs(wanted) do
        if not mounted[owner] then
            mount(arena,owner,candidate.corner,candidate.source)
        end
    end
end

function Kit.count()
    local count=0
    for _,entry in pairs(mounted) do
        if entry.model.Parent==bucket and #entry.pieces==7 then
            count+=1
        end
    end
    return count
end

function Kit.replacedNativeCount()
    local count=0
    for owner,entry in pairs(mounted) do
        if entry.model.Parent==bucket and #entry.pieces==7 then
            for part in pairs(entry.natives) do
                if part.Parent==owner and part.Transparency==1 then
                    count+=1
                end
            end
        end
    end
    return count
end

return Kit
