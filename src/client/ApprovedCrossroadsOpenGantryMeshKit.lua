-- Four real Crossroads boundary portiques: 1 approved seven-material
-- original 3D truss, four independently camera-ranked reversible instances.
-- Native CrossroadSignal strips remain visible, with no new collider, light,
-- AssetService call or render-step loop. Existing LOD sampler drives sync.
local ReplicatedStorage=game:GetService("ReplicatedStorage")

local Kit={}
local ASSET_ID=90844491148907
-- Low allows one approved seven-MeshPart gantry; stress 1 restores
-- its original primitive. The warning signal remains server-authored.
local QUALITIES={Low=1,Medium=2,High=4}
local DISTANCE={Low=180,Medium=290,High=410}
local RETAIN=26
local SIZE=Vector3.new(27.92,3.6,2.74)
local folder=Instance.new("Folder")
folder.Name="ApprovedCrossroadsOpenGantryLocal"
folder:SetAttribute("CosmeticOnly",true)
folder.Parent=workspace

local activeArena=nil
local mounted={}

local function unmount(body)
    local entry=mounted[body]
    if not entry then return end
    mounted[body]=nil
    for _,connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    if body.Parent==entry.decor and body.Transparency==1 then
        body.Transparency=entry.original
    end
    entry.model:Destroy()
end

local function clear()
    local owners={}
    for body in pairs(mounted) do owners[#owners+1]=body end
    for _,body in ipairs(owners) do unmount(body) end
end

local function sourceFor()
    local holder=ReplicatedStorage:FindFirstChild("ApprovedCrossroadsGantryTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent~=ReplicatedStorage
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=holder:FindFirstChild("Gantry")
    if not source or not source:IsA("Model")
        or source.Parent~=holder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalCrossroadsGantry3D")~=true
        or source:GetAttribute("Original3DAssetId")~=ASSET_ID then
        return nil
    end
    local n=0
    for _,desc in ipairs(source:GetDescendants()) do
        if desc:IsA("BasePart") then
            if not desc:IsA("MeshPart") or desc.CanCollide
                or desc.CanTouch or desc.CanQuery then return nil end
            n+=1
        elseif desc:IsA("LuaSourceContainer") then return nil end
    end
    if n~=7 then return nil end
    local _,dims=source:GetBoundingBox()
    local major=math.max(dims.X,dims.Z)
    local minor=math.min(dims.X,dims.Z)
    if math.abs(dims.Y-SIZE.Y)>.4
        or math.abs(major-SIZE.X)>.4
        or math.abs(minor-SIZE.Z)>.38 then return nil end
    return source,holder
end

local function genuine(arena,index)
    local generated=workspace:FindFirstChild("GeneratedMap")
    local base=arena and arena:FindFirstChild("Base")
    local decor=arena and arena:FindFirstChild("Decor")
    if not arena or not arena:IsA("Folder") or arena.Name~="Arena"
        or not generated or arena.Parent~=generated
        or arena:GetAttribute("VariantId")~="Crossroads"
        or not base or not base:IsA("BasePart")
        or base.Parent~=arena or not base.Anchored
        or not base.CanCollide or base.Size.X<318 or base.Size.Z<318
        or not decor or not decor:IsA("Folder")
        or decor.Parent~=arena or index<1 or index>4 then return nil end
    local x,z=0,0
    local expectedBody
    local expectedSignal
    if index<=2 then
        z=(index==1 and -1 or 1)*(base.Size.Z*.5+4)
        expectedBody=Vector3.new(28,2,2)
        expectedSignal=Vector3.new(18,.34,2.12)
    else
        x=(index==3 and -1 or 1)*(base.Size.X*.5+4)
        expectedBody=Vector3.new(2,2,28)
        expectedSignal=Vector3.new(2.12,.34,18)
    end
    local center=base.Position+Vector3.new(x,8,z)
    local body=decor:FindFirstChild("CrossroadGantry"..index)
    local signal=decor:FindFirstChild("CrossroadSignal"..index)
    if not body or not body:IsA("Part")
        or not signal or not signal:IsA("Part")
        or body.Parent~=decor or signal.Parent~=decor then return nil end
    for _,part in ipairs({body,signal}) do
        if not part.Anchored or part.CanCollide
            or part.CanTouch or part.CanQuery
            or part.Shape~=Enum.PartType.Block
            or (part.Position-center).Magnitude>.16
            or part.CFrame.LookVector:Dot(Vector3.new(0,0,-1))<.999
            or part.CFrame.UpVector:Dot(Vector3.new(0,1,0))<.999 then
            return nil
        end
    end
    if (body.Size-expectedBody).Magnitude>.10
        or (signal.Size-expectedSignal).Magnitude>.10
        or (math.abs(body.Transparency-.04)>.035
            and body.Transparency~=1)
        or math.abs(signal.Transparency-.16)>.035 then return nil end
    -- Nonphysical source overhang never reaches the playable base.
    -- Native setback = 4 studs; new source half depth = 1.37 studs.
    return body,signal,base,decor
end

local function valid(entry)
    if entry.arena~=activeArena or entry.model.Parent~=folder
        or entry.source.Parent~=entry.holder
        or entry.holder.Parent~=ReplicatedStorage
        or entry.decor.Parent~=entry.arena
        or entry.base.Parent~=entry.arena
        or #entry.parts~=7 then return false end
    local body,signal,base,decor=genuine(entry.arena,entry.index)
    if body~=entry.body or signal~=entry.signal
        or base~=entry.base or decor~=entry.decor then return false end
    for _,piece in ipairs(entry.parts) do
        if not piece:IsDescendantOf(entry.model) then return false end
    end
    return true
end

local function mount(arena,index,body,signal,base,decor,source,holder)
    local checkBody,checkSignal=genuine(arena,index)
    if checkBody~=body or checkSignal~=signal then return end
    local clone=source:Clone()
    local frame,size=clone:GetBoundingBox()
    local originalX=size.X>=size.Z
    local desiredX=index<=2
    local yaw=originalX==desiredX and 0 or math.pi*.5
    local major=math.max(size.X,size.Z)
    local minor=math.min(size.X,size.Z)
    if math.abs(major-SIZE.X)>.4
        or math.abs(minor-SIZE.Z)>.38
        or math.abs(size.Y-SIZE.Y)>.4 then
        clone:Destroy()
        return
    end
    local target=body.CFrame*CFrame.Angles(0,yaw,0)
    local parts={}
    for _,piece in ipairs(clone:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then clone:Destroy();return end
            piece.CFrame=target*frame:ToObjectSpace(piece.CFrame)
            piece.Anchored=true
            piece.Massless=true
            piece.CanCollide=false
            piece.CanTouch=false
            piece.CanQuery=false
            piece.CastShadow=false
            piece:SetAttribute("CosmeticOnly",true)
            piece:SetAttribute("Original3DAssetId",ASSET_ID)
            parts[#parts+1]=piece
        end
    end
    if #parts~=7 then clone:Destroy();return end
    clone.Name="ForgedCrossroadsGantry3D_"..index
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",ASSET_ID)
    clone.Parent=folder
    local entry={
        arena=arena,index=index,body=body,signal=signal,
        base=base,decor=decor,source=source,holder=holder,
        model=clone,parts=parts,original=body.Transparency,
        connections={},
    }
    mounted[body]=entry
    if not valid(entry) then unmount(body);return end
    body.Transparency=1
    local function changed()
        if mounted[body]==entry and not valid(entry) then unmount(body) end
    end
    for _,instance in ipairs({body,signal,base,decor,source}) do
        entry.connections[#entry.connections+1]=
            instance.AncestryChanged:Connect(changed)
    end
    for _,native in ipairs({body,signal}) do
        entry.connections[#entry.connections+1]=
            native:GetPropertyChangedSignal("Size"):Connect(changed)
        entry.connections[#entry.connections+1]=
            native:GetPropertyChangedSignal("CFrame"):Connect(changed)
    end
    entry.connections[#entry.connections+1]=
        base:GetPropertyChangedSignal("Size"):Connect(changed)
    entry.connections[#entry.connections+1]=
        base:GetPropertyChangedSignal("CFrame"):Connect(changed)
    entry.connections[#entry.connections+1]=
        source.DescendantRemoving:Connect(function(piece)
            if piece:IsA("MeshPart") then unmount(body) end
        end)
    entry.connections[#entry.connections+1]=
        clone.DescendantRemoving:Connect(function(piece)
            if piece:IsA("MeshPart") then unmount(body) end
        end)
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,touch,pressure)
    if arena~=activeArena then clear();activeArena=arena end
    local cap=QUALITIES[tier] or 0
    -- Preserve the single Low sculpture on real Android touchscreens.
    -- Medium/High keep their previous touch demotion.
    if touch and tier~="Low" then
        cap=tier=="High" and math.min(cap,2)
            or tier=="Medium" and math.min(cap,1) or 0
    end
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if stress==1 then cap=math.floor(cap*.5) end
    if stress>=2 then cap=0 end
    if cap==0 or not cameraReady
        or typeof(cameraPoint)~="Vector3" then clear();return end
    local source,holder=sourceFor()
    if not source then clear();return end
    local ranked={}
    for index=1,4 do
        local body,signal,base,decor=genuine(arena,index)
        if body then
            local held=mounted[body]~=nil
            local distance=(body.Position-cameraPoint).Magnitude
            if distance<=(DISTANCE[tier] or 0)+(held and RETAIN or 0) then
                ranked[#ranked+1]={
                    index=index,body=body,signal=signal,base=base,
                    decor=decor,source=source,holder=holder,
                    score=distance-(held and RETAIN*.5 or 0),
                }
            end
        end
    end
    table.sort(ranked,function(a,b)
        if a.score~=b.score then return a.score<b.score end
        return a.index<b.index
    end)
    local wanted={}
    for i=1,math.min(cap,#ranked) do
        wanted[ranked[i].body]=ranked[i]
    end
    local stale={}
    for body,entry in pairs(mounted) do
        if not wanted[body] or not valid(entry)
            or entry.source~=source then
            stale[#stale+1]=body
        else
            body.Transparency=1
        end
    end
    for _,body in ipairs(stale) do unmount(body) end
    for body,item in pairs(wanted) do
        if not mounted[body] then
            mount(arena,item.index,body,item.signal,item.base,item.decor,
                item.source,item.holder)
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
        if valid(entry) and entry.body.Transparency==1 then n+=1 end
    end
    return n
end

return Kit
