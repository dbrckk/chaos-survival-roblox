-- Premium original skyline replacements for four REAL exterior towers.
-- Per tower, four rectangular native bodies disappear ONLY after one
-- source-approved seven-MeshPart sculpt is fully mounted; signal and antenna
-- stay. Existing scenery LOD timer only; zero physics or network calls.
-- On Low, show ONE nearest approved seven-piece forged tower at normal
-- pressure; restore native silhouettes immediately at pressure level 1/2.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local STATIONS = {"North","East","South","West"}
local HEIGHTS = {21,24,27,30}
local IDS = {
    [21] = 137744886537150,
    [24] = 74958476744494,
    [27] = 97864559770371,
    [30] = 112172520488996,
}
local NAMES = {"ReactorShell","RoofCanopy","LeftRib","RightRib"}
local QUALITIES = {Low=1,Medium=2,High=4}
local DISTANCE = {Low=275,Medium=330,High=450}
local RETAIN = 24
local VARIANTS = {
    Classic=true,Towers=true,Crossroads=true,Orbital=true,Harbor=true,
}

local bucket = Instance.new("Folder")
bucket.Name = "ApprovedExteriorTowerMeshesLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent = workspace
local activeArena = nil
local mounted = {}
local observedBase = nil
local baseConnections = {}

local function dispose(owner)
    local entry = mounted[owner]
    if not entry then return end
    mounted[owner]=nil
    for _, c in ipairs(entry.connections) do c:Disconnect() end
    for native,alpha in pairs(entry.originals) do
        if native.Parent == owner and native.Anchored
            and not native.CanCollide and not native.CanTouch
            and not native.CanQuery and native.Transparency == 1 then
            native.Transparency = alpha
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
    for _, c in ipairs(baseConnections) do c:Disconnect() end
    table.clear(baseConnections)
    observedBase=nil
    activeArena=nil
    bucket:ClearAllChildren()
end

local function sourceFor(height)
    local holder=ReplicatedStorage:FindFirstChild("ApprovedExteriorTowerTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent~=ReplicatedStorage
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=holder:FindFirstChild("Tower"..height)
    if not source or not source:IsA("Model") or source.Parent~=holder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalExteriorTower3D")~=true
        or source:GetAttribute("Original3DAssetId")~=IDS[height] then
        return nil
    end
    local count=0
    for _, item in ipairs(source:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or item.CanCollide
                or item.CanTouch or item.CanQuery then return nil end
            count+=1
        elseif item:IsA("LuaSourceContainer") then return nil end
    end
    if count~=7 then return nil end
    local _,bounds=source:GetBoundingBox()
    local a,b=math.min(bounds.X,bounds.Z),math.max(bounds.X,bounds.Z)
    if math.abs(bounds.Y-(height+1.2))>.42
        or math.abs(a-9.84)>.36 or math.abs(b-11.84)>.38 then
        return nil
    end
    return source
end

local function realTower(arena,owner,index)
    local height=HEIGHTS[index]
    if not arena or not arena:IsA("Folder")
        or not VARIANTS[arena:GetAttribute("VariantId")]
        or not arena.Parent or arena.Parent.Name~="GeneratedMap"
        or arena.Parent.Parent~=workspace
        or not owner or not owner:IsA("Model")
        or owner.Name~="ExteriorSilhouette"..STATIONS[index]
        or owner:GetAttribute("ChaosDistantScenery")~=true then
        return nil
    end
    local decor=arena:FindFirstChild("Decor")
    local base=arena:FindFirstChild("Base")
    if not decor or not decor:IsA("Folder") or decor.Parent~=arena
        or owner.Parent~=decor
        or not base or not base:IsA("BasePart") or base.Parent~=arena
        or not base.Anchored or not base.CanCollide
        or base.Size.X<318 or base.Size.Z<318 then return nil end
    local expected={
        Vector3.new(9,height,8),
        Vector3.new(12,1.2,10),
        Vector3.new(1.2,height*.75,1.4),
        Vector3.new(1.2,height*.75,1.4),
    }
    local natives={}
    for i,name in ipairs(NAMES) do
        local part=owner:FindFirstChild(name)
        if not part or not part:IsA("Part")
            or part.Parent~=owner or part.Shape~=Enum.PartType.Block
            or not part.Anchored or part.CanCollide or part.CanTouch
            or part.CanQuery or (part.Size-expected[i]).Magnitude>.10 then
            return nil
        end
        natives[#natives+1]=part
    end
    -- Keep original neon SignalBand and mast antenna, but also require
    -- their real authored presence so a partially streamed model is refused.
    local signal=owner:FindFirstChild("SignalBand")
    local antenna=owner:FindFirstChild("Antenna")
    if not signal or not signal:IsA("Part") or signal.Parent~=owner
        or not signal.Anchored or signal.CanCollide
        or (signal.Size-Vector3.new(6,.35,.18)).Magnitude>.1
        or not antenna or not antenna:IsA("Part")
        or antenna.Parent~=owner or not antenna.Anchored
        or antenna.CanCollide
        or (antenna.Size-Vector3.new(.55,6,.55)).Magnitude>.1 then
        return nil
    end
    local shell=natives[1]
    local expectedOffsets={
        Vector3.new(0,height*.5+.6,0),
        Vector3.new(-5,-height*.08,-2.8),
        Vector3.new(5,-height*.08,-2.8),
    }
    for i=2,4 do
        local observed=shell.CFrame:PointToObjectSpace(natives[i].Position)
        if (observed-expectedOffsets[i-1]).Magnitude>.12
            or shell.CFrame.LookVector:Dot(natives[i].CFrame.LookVector)<.999
            or shell.CFrame.UpVector:Dot(natives[i].CFrame.UpVector)<.999 then
            return nil
        end
    end
    -- Bound the owner to the true external horizon, not an unrelated
    -- same-named object near a playable platform or lobby.
    local offset=shell.Position-base.Position
    if offset.Y<height*.5-5 or offset.Y>height*.5+5
        or math.max(math.abs(offset.X),math.abs(offset.Z))
            <math.min(base.Size.X,base.Size.Z)*.48 then
        return nil
    end
    return natives
end

local function fit(source,shell,height)
    local model=source:Clone()
    local native=Vector3.new(12,height+1.2,10)
    local _,bounds=model:GetBoundingBox()
    local normal=math.abs(bounds.X-native.X)+math.abs(bounds.Z-native.Z)
    local swapped=math.abs(bounds.Z-native.X)+math.abs(bounds.X-native.Z)
    local yaw=normal<=swapped and 0 or math.pi*.5
    local width=yaw==0 and bounds.X or bounds.Z
    local depth=yaw==0 and bounds.Z or bounds.X
    local scale=math.min(1.045,native.X*.985/width,
        native.Y*.985/bounds.Y,native.Z*.985/depth)
    if scale<.75 or not pcall(function() model:ScaleTo(scale) end) then
        model:Destroy()
        return nil
    end
    local frame,size=model:GetBoundingBox()
    width=yaw==0 and size.X or size.Z
    depth=yaw==0 and size.Z or size.X
    if width>native.X*.995 or depth>native.Z*.995
        or size.Y>native.Y*.995
        or width<native.X*.84 or depth<native.Z*.84
        or size.Y<native.Y*.90 then
        model:Destroy()
        return nil
    end
    local target=shell.CFrame*CFrame.new(0,.6,0)*CFrame.Angles(0,yaw,0)
    local pieces={}
    for _,p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            if not p:IsA("MeshPart") then model:Destroy();return nil end
            p.CFrame=target*frame:ToObjectSpace(p.CFrame)
            p.Anchored=true
            p.Massless=true
            p.CanCollide=false
            p.CanTouch=false
            p.CanQuery=false
            p.CastShadow=false
            p:SetAttribute("CosmeticOnly",true)
            p:SetAttribute("Original3DAssetId",IDS[height])
            pieces[#pieces+1]=p
        end
    end
    if #pieces~=7 then model:Destroy();return nil end
    model.Name="ApprovedExteriorTower3D_"..height
    model:SetAttribute("CosmeticOnly",true)
    model:SetAttribute("Original3DAssetId",IDS[height])
    return model,pieces
end

local function mount(arena,owner,index,source)
    if mounted[owner] then return end
    local natives=realTower(arena,owner,index)
    if not natives then return end
    local height=HEIGHTS[index]
    local model,pieces=fit(source,natives[1],height)
    if not model then return end
    if not realTower(arena,owner,index) or not source.Parent then
        model:Destroy()
        return
    end
    local entry={
        model=model,pieces=pieces,source=source,index=index,
        originals={},frames={},connections={},
    }
    for _,native in ipairs(natives) do
        entry.originals[native]=native.Transparency
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
    if cap==0 or not cameraReady or typeof(cameraPoint)~="Vector3"
        or not arena or not arena:IsA("Folder") then
        removeAll()
        return
    end
    local decor=arena:FindFirstChild("Decor")
    local base=arena:FindFirstChild("Base")
    if not decor or not decor:IsA("Folder")
        or not base or not base:IsA("BasePart")
        or not base.Anchored or not base.CanCollide
        or base.Size.X<318 or base.Size.Z<318 then
        removeAll()
        return
    end
    if observedBase~=base then
        for _,c in ipairs(baseConnections) do c:Disconnect() end
        table.clear(baseConnections)
        observedBase=base
        local function checkBase()
            if base.Parent~=arena or not base.Anchored
                or not base.CanCollide or base.Size.X<318
                or base.Size.Z<318 then removeAll() end
        end
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("Size"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base:GetPropertyChangedSignal("CanCollide"):Connect(checkBase)
        baseConnections[#baseConnections+1]=
            base.AncestryChanged:Connect(checkBase)
    end
    local ranked={}
    for index,name in ipairs(STATIONS) do
        local owner=decor:FindFirstChild("ExteriorSilhouette"..name)
        local natives=realTower(arena,owner,index)
        local source=sourceFor(HEIGHTS[index])
        if natives and source then
            local held=mounted[owner]~=nil
            local distance=(natives[1].Position-cameraPoint).Magnitude
            if distance<=(DISTANCE[tier] or 0)+(held and RETAIN or 0) then
                ranked[#ranked+1]={
                    owner=owner,index=index,source=source,
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
        wanted[ranked[i].owner]=ranked[i]
    end
    for owner,entry in pairs(mounted) do
        local candidate=wanted[owner]
        local invalid=not candidate or candidate.index~=entry.index
            or candidate.source~=entry.source
            or not realTower(arena,owner,entry.index)
            or entry.model.Parent~=bucket
        if not invalid then
            for native,frame in pairs(entry.frames) do
                if native.Parent~=owner
                    or (native.CFrame.Position-frame.Position).Magnitude>.08
                    or native.CFrame.LookVector:Dot(frame.LookVector)<.999
                    or native.CFrame.UpVector:Dot(frame.UpVector)<.999 then
                    invalid=true
                    break
                end
            end
            for _,part in ipairs(entry.pieces) do
                if not part:IsDescendantOf(entry.model) then invalid=true end
            end
        end
        if invalid then
            dispose(owner)
        else
            for native in pairs(entry.originals) do native.Transparency=1 end
        end
    end
    for owner,candidate in pairs(wanted) do
        if not mounted[owner] then
            mount(arena,owner,candidate.index,candidate.source)
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
    return Kit.count()*4
end

return Kit
