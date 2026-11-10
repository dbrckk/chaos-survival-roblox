-- Eight authentic Orbital reactor nodes plus their eight support struts.
-- Paired atomic swap to 14 original seven-material MeshParts from TWO
-- creator-owned Approved Models (104654294187035, 138666009076890).
-- One existing scenery LOD camera sampler; no collisions, lights or remotes.
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Kit={}
local NODE_ID=104654294187035
local STRUT_ID=138666009076890
local NODE_BOUNDS=Vector3.new(4.36,4.36,4.36)
local STRUT_BOUNDS=Vector3.new(8.46,1.24,1.10)
local LIMITS={Low=0,Medium=3,High=6}
local RANGE={Low=0,Medium=340,High=460}
local RETENTION=26
local bucket=Instance.new("Folder")
bucket.Name="ApprovedOrbitalReactorLandmarksLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent=workspace

local activeArena=nil
local mounted={}

local function release(index)
    local entry=mounted[index]
    if not entry then return end
    mounted[index]=nil
    for _,connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    for native,alpha in pairs(entry.natives) do
        if native.Parent==entry.decor and native.Transparency==1
            and native.Anchored and not native.CanCollide
            and not native.CanTouch and not native.CanQuery then
            native.Transparency=alpha
        end
    end
    entry.model:Destroy()
end

local function releaseAll()
    local keys={}
    for index in pairs(mounted) do keys[#keys+1]=index end
    for _,index in ipairs(keys) do release(index) end
end

local function approved(name,id,expected)
    local holder=ReplicatedStorage:FindFirstChild(
        "ApprovedOrbitalReactorLandmarkTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent~=ReplicatedStorage
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=holder:FindFirstChild(name)
    if not source or not source:IsA("Model")
        or source.Parent~=holder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalOrbitalReactorLandmark3D")~=true
        or source:GetAttribute("Original3DAssetId")~=id then return nil end
    local count=0
    for _,item in ipairs(source:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or item.CanCollide
                or item.CanTouch or item.CanQuery then return nil end
            count+=1
        elseif item:IsA("LuaSourceContainer") then return nil end
    end
    if count~=7 then return nil end
    local _,dims=source:GetBoundingBox()
    if name=="Node" then
        if (dims-expected).Magnitude>.62 then return nil end
    elseif math.abs(math.max(dims.X,dims.Z)-expected.X)>.38
        or math.abs(dims.Y-expected.Y)>.35
        or math.abs(math.min(dims.X,dims.Z)-expected.Z)>.35 then
        return nil
    end
    return source,holder
end

local function bothApproved()
    local node,holder=approved("Node",NODE_ID,NODE_BOUNDS)
    if not node then return nil end
    local strut,strutHolder=approved("Strut",STRUT_ID,STRUT_BOUNDS)
    if not strut or strutHolder~=holder then return nil end
    return node,strut,holder
end

local function authenticPart(native,name,size,where,kind,alpha)
    if not native or not native:IsA("Part") or native.Name~=name
        or not native.Anchored or native.CanCollide
        or native.CanTouch or native.CanQuery
        or native.Shape~=kind
        or (native.Size-size).Magnitude>.10
        or (native.Position-where.Position).Magnitude>.17
        or native.CFrame.LookVector:Dot(where.LookVector)<.999
        or native.CFrame.UpVector:Dot(where.UpVector)<.999
        or (math.abs(native.Transparency-alpha)>.035
            and native.Transparency~=1) then return false end
    return true
end

local function genuine(arena,index)
    local generated=workspace:FindFirstChild("GeneratedMap")
    local base=arena and arena:FindFirstChild("Base")
    local decor=arena and arena:FindFirstChild("Decor")
    if not arena or not arena:IsA("Folder") or arena.Name~="Arena"
        or not generated or not generated:IsA("Folder")
        or arena.Parent~=generated
        or arena:GetAttribute("VariantId")~="Orbital"
        or not base or not base:IsA("BasePart")
        or base.Parent~=arena or not base.Anchored or not base.CanCollide
        or base.Size.X<318 or base.Size.Z<318
        or not decor or not decor:IsA("Folder")
        or decor.Parent~=arena or index<1 or index>8 then return nil end
    local angle=(index-1)*math.pi/4
    local radius=math.max(base.Size.X*.5,base.Size.Z*.5)+7
    local cosine=math.cos(angle)
    local sine=math.sin(angle)
    local nodeAt=base.Position+Vector3.new(cosine*radius,
        9+(index%2)*3,sine*radius)
    local strutAt=base.Position+Vector3.new(cosine*(radius-4.4),
        7,sine*(radius-4.4))
    local node=decor:FindFirstChild("OrbitalReactorNode"..index)
    local strut=decor:FindFirstChild("OrbitalReactorStrut"..index)
    if not node or not strut
        or node.Parent~=decor or strut.Parent~=decor then return nil end
    if not authenticPart(node,"OrbitalReactorNode"..index,
        Vector3.new(4.4,4.4,4.4),CFrame.new(nodeAt),
        Enum.PartType.Ball,.20) then return nil end
    local frame=CFrame.new(strutAt)*CFrame.Angles(0,-angle,0)
    if not authenticPart(strut,"OrbitalReactorStrut"..index,
        Vector3.new(8.5,.55,.55),frame,
        Enum.PartType.Block,.10) then return nil end
    -- The source models are cosmetic and extend no further into the
    -- arena than the existing 8.5-stud native strut.
    return node,strut,base,decor,frame
end

local function valid(entry)
    if entry.arena~=activeArena or entry.model.Parent~=bucket
        or entry.nodeSource.Parent~=entry.holder
        or entry.strutSource.Parent~=entry.holder
        or entry.holder.Parent~=ReplicatedStorage
        or entry.decor.Parent~=entry.arena
        or entry.base.Parent~=entry.arena
        or #entry.nodePieces~=7 or #entry.strutPieces~=7 then return false end
    local nodeSource,strutSource=bothApproved()
    if nodeSource~=entry.nodeSource
        or strutSource~=entry.strutSource then return false end
    local node,strut,base,decor=genuine(entry.arena,entry.index)
    if node~=entry.node or strut~=entry.strut
        or base~=entry.base or decor~=entry.decor then return false end
    for _,part in ipairs(entry.nodePieces) do
        if not part:IsDescendantOf(entry.model) then return false end
    end
    for _,part in ipairs(entry.strutPieces) do
        if not part:IsDescendantOf(entry.model) then return false end
    end
    return true
end

local function positionClone(source,target,id,expected,isStrut)
    local clone=source:Clone()
    local frame,dims=clone:GetBoundingBox()
    local correct
    local yaw=0
    if isStrut then
        correct=math.abs(math.max(dims.X,dims.Z)-expected.X)<=.38
            and math.abs(dims.Y-expected.Y)<=.35
            and math.abs(math.min(dims.X,dims.Z)-expected.Z)<=.35
        if dims.X<dims.Z then yaw=math.pi*.5 end
    else
        correct=(dims-expected).Magnitude<=.62
    end
    if not correct then clone:Destroy();return nil end
    local pieces={}
    local rotated=target*CFrame.Angles(0,yaw,0)
    for _,part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            part.CFrame=rotated*frame:ToObjectSpace(part.CFrame)
            part.Anchored=true
            part.Massless=true
            part.CanCollide=false
            part.CanTouch=false
            part.CanQuery=false
            part.CastShadow=false
            part:SetAttribute("CosmeticOnly",true)
            part:SetAttribute("Original3DAssetId",id)
            pieces[#pieces+1]=part
        end
    end
    if #pieces~=7 then clone:Destroy();return nil end
    return clone,pieces
end

local function mount(arena,index,nodeSource,strutSource,holder)
    local node,strut,base,decor,strutFrame=genuine(arena,index)
    if not node then return end
    local nodeModel,nodePieces=positionClone(nodeSource,
        CFrame.new(node.Position),NODE_ID,NODE_BOUNDS,false)
    if not nodeModel then return end
    local strutModel,strutPieces=positionClone(strutSource,
        strutFrame,STRUT_ID,STRUT_BOUNDS,true)
    if not strutModel then nodeModel:Destroy();return end
    local wrapper=Instance.new("Model")
    wrapper.Name="SculptedOrbitalNodeAndStrut_"..index
    wrapper:SetAttribute("CosmeticOnly",true)
    nodeModel.Name="AuthenticReactorNode"
    strutModel.Name="AuthenticOpenSupport"
    nodeModel.Parent=wrapper
    strutModel.Parent=wrapper
    wrapper.Parent=bucket
    local entry={
        arena=arena,index=index,node=node,strut=strut,
        base=base,decor=decor,holder=holder,
        nodeSource=nodeSource,strutSource=strutSource,
        nodePieces=nodePieces,strutPieces=strutPieces,
        model=wrapper,connections={},
        natives={[node]=node.Transparency,[strut]=strut.Transparency},
    }
    mounted[index]=entry
    if not valid(entry) then release(index);return end
    -- Atomic cosmetic swap. Do not hide either native before BOTH clones
    -- are placed, verified and parented.
    node.Transparency=1
    strut.Transparency=1
    local function changed()
        if mounted[index]==entry and not valid(entry) then release(index) end
    end
    for _,source in ipairs({nodeSource,strutSource}) do
        entry.connections[#entry.connections+1]=
            source.AncestryChanged:Connect(changed)
        entry.connections[#entry.connections+1]=
            source.DescendantRemoving:Connect(function(part)
                if part:IsA("MeshPart") then release(index) end
            end)
    end
    for _,item in ipairs({node,strut,base,decor}) do
        entry.connections[#entry.connections+1]=
            item.AncestryChanged:Connect(changed)
    end
    for _,native in ipairs({node,strut}) do
        entry.connections[#entry.connections+1]=
            native:GetPropertyChangedSignal("Size"):Connect(changed)
        entry.connections[#entry.connections+1]=
            native:GetPropertyChangedSignal("CFrame"):Connect(changed)
        entry.connections[#entry.connections+1]=
            native:GetPropertyChangedSignal("CanCollide"):Connect(changed)
    end
    entry.connections[#entry.connections+1]=
        base:GetPropertyChangedSignal("Size"):Connect(changed)
    entry.connections[#entry.connections+1]=
        base:GetPropertyChangedSignal("CFrame"):Connect(changed)
    for _,model in ipairs({nodeModel,strutModel}) do
        entry.connections[#entry.connections+1]=
            model.DescendantRemoving:Connect(function(part)
                if part:IsA("MeshPart") then release(index) end
            end)
    end
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,touch,pressure)
    if arena~=activeArena then releaseAll();activeArena=arena end
    local cap=LIMITS[tier] or 0
    if touch then
        cap=tier=="High" and math.min(cap,3)
            or tier=="Medium" and math.min(cap,1) or 0
    end
    local pressureLevel=math.clamp(math.floor(
        tonumber(pressure) or 0),0,2)
    if pressureLevel==1 then cap=math.floor(cap*.5) end
    if pressureLevel>=2 then cap=0 end
    if cap==0 or not cameraReady
        or typeof(cameraPoint)~="Vector3" then releaseAll();return end
    local nodeSource,strutSource,holder=bothApproved()
    if not nodeSource or not strutSource then releaseAll();return end
    local candidates={}
    for index=1,8 do
        local node,strut=genuine(arena,index)
        if node then
            local held=mounted[index]~=nil
            local distance=(node.Position-cameraPoint).Magnitude
            if distance<=(RANGE[tier] or 0)+(held and RETENTION or 0) then
                candidates[#candidates+1]={
                    index=index,score=distance-(held and RETENTION*.55 or 0),
                    node=node,strut=strut,
                }
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.score~=b.score then return a.score<b.score end
        return a.index<b.index
    end)
    local wanted={}
    for i=1,math.min(cap,#candidates) do
        wanted[candidates[i].index]=candidates[i]
    end
    local obsolete={}
    for index,entry in pairs(mounted) do
        if not wanted[index] or not valid(entry)
            or entry.nodeSource~=nodeSource
            or entry.strutSource~=strutSource then
            obsolete[#obsolete+1]=index
        else
            entry.node.Transparency=1
            entry.strut.Transparency=1
        end
    end
    for _,index in ipairs(obsolete) do release(index) end
    for index in pairs(wanted) do
        if not mounted[index] then
            mount(arena,index,nodeSource,strutSource,holder)
        end
    end
end

function Kit.count()
    local n=0
    for _,entry in pairs(mounted) do
        if valid(entry) then n+=1 end
    end
    return n
end

function Kit.replacedNativeCount()
    local n=0
    for _,entry in pairs(mounted) do
        if valid(entry) then
            if entry.node.Transparency==1 then n+=1 end
            if entry.strut.Transparency==1 then n+=1 end
        end
    end
    return n
end

return Kit
