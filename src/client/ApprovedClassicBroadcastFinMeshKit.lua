-- Four original Classic broadcast fins: one creator-approved sculpted
-- seven-material 3D aerofoil, rotated per authentic native direction.
-- The independently positioned ClassicBroadcastGlow strips are NEVER hidden.
-- Runs on the existing scenery LOD camera sample, with reversible fallback.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local ASSET_ID = 123049626693705
local SIZE = Vector3.new(5.46,15.92,1.76)
-- One real 7-MeshPart original at camera range in healthy Low.
-- At the first GPU-pressure level, floor(1 * .5) restores its native.
local CAP = {Low=1,Medium=2,High=4}
local RANGE = {Low=195,Medium=285,High=415}
local RETENTION = 26
local bucket = Instance.new("Folder")
bucket.Name = "ApprovedClassicBroadcastFinLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent = workspace

local activeArena = nil
local mounted = {}

local function unmount(native)
    local entry=mounted[native]
    if not entry then return end
    mounted[native]=nil
    for _,connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    if native.Parent==entry.decor and native.Transparency==1
        and native.Anchored and not native.CanCollide
        and not native.CanTouch and not native.CanQuery then
        native.Transparency=entry.original
    end
    entry.model:Destroy()
end

-- The cooperative Android ledger may evict optional 3D between
-- LOD samples. Restore the exact 16-stud native fin immediately, rather
-- than leaving its original body transparent for another 0.65/0.90s.
bucket.ChildRemoved:Connect(function(child)
    if not child:IsA("Model") then return end
    for native,entry in pairs(mounted) do
        if entry.model==child then
            unmount(native)
            break
        end
    end
end)

local function clear()
    local all={}
    for native in pairs(mounted) do all[#all+1]=native end
    for _,native in ipairs(all) do unmount(native) end
end

local function sourceFor()
    local holder=ReplicatedStorage:FindFirstChild("ApprovedClassicBroadcastFinTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent~=ReplicatedStorage
        or holder:GetAttribute("OwnerVerified")~=true then return nil end
    local source=holder:FindFirstChild("BroadcastFin")
    if not source or not source:IsA("Model")
        or source.Parent~=holder
        or source:GetAttribute("OwnerVerified")~=true
        or source:GetAttribute("CosmeticOnly")~=true
        or source:GetAttribute("OriginalClassicBroadcastFin3D")~=true
        or source:GetAttribute("Original3DAssetId")~=ASSET_ID then return nil end
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
    local long=math.max(size.X,size.Z)
    local thin=math.min(size.X,size.Z)
    if math.abs(long-SIZE.X)>.32
        or math.abs(size.Y-SIZE.Y)>.32
        or math.abs(thin-SIZE.Z)>.32 then return nil end
    return source,holder
end

local function genuine(arena,index)
    local generated=workspace:FindFirstChild("GeneratedMap")
    local base=arena and arena:FindFirstChild("Base")
    local decor=arena and arena:FindFirstChild("Decor")
    if not arena or not arena:IsA("Folder") or arena.Name~="Arena"
        or not generated or not generated:IsA("Folder")
        or arena.Parent~=generated
        or arena:GetAttribute("VariantId")~="Classic"
        or not base or not base:IsA("BasePart")
        or base.Parent~=arena or not base.Anchored
        or not base.CanCollide
        or base.Size.X<318 or base.Size.Z<318
        or not decor or not decor:IsA("Folder")
        or decor.Parent~=arena or index<1 or index>4 then return nil end
    local halfX=base.Size.X*.5
    local halfZ=base.Size.Z*.5
    local offset
    if index==1 then
        offset=Vector3.new(-halfX-5,8,-18)
    elseif index==2 then
        offset=Vector3.new(halfX+5,8,18)
    elseif index==3 then
        offset=Vector3.new(-18,8,halfZ+5)
    else
        offset=Vector3.new(18,8,-halfZ-5)
    end
    local center=base.Position+offset
    local alongZ=index<=2
    local expectedSize=alongZ and Vector3.new(1.8,16,5.5)
        or Vector3.new(5.5,16,1.8)
    local expectedGlow=alongZ and Vector3.new(.22,10,5.58)
        or Vector3.new(5.58,10,.22)
    local fin=decor:FindFirstChild("ClassicBroadcastFin"..index)
    local glow=decor:FindFirstChild("ClassicBroadcastGlow"..index)
    if not fin or not fin:IsA("Part")
        or not glow or not glow:IsA("Part")
        or fin.Parent~=decor or glow.Parent~=decor then return nil end
    for _,part in ipairs({fin,glow}) do
        if not part.Anchored or part.CanCollide
            or part.CanTouch or part.CanQuery
            or part.Shape~=Enum.PartType.Block
            or part.CFrame.LookVector:Dot(Vector3.new(0,0,-1))<.999
            or part.CFrame.UpVector:Dot(Vector3.new(0,1,0))<.999 then
            return nil
        end
    end
    if (fin.Size-expectedSize).Magnitude>.10
        or (glow.Size-expectedGlow).Magnitude>.10
        or (fin.Position-center).Magnitude>.16
        or (glow.Position-(center+Vector3.new(0,.5,0))).Magnitude>.16
        or (math.abs(fin.Transparency-.05)>.035
            and fin.Transparency~=1)
        or math.abs(glow.Transparency-.24)>.035 then return nil end
    -- Cosmetic profile remains outside the collision-tested Base by
    -- 5 studs; the 1.76-stud slim dimension is within that setback.
    return fin,glow,base,decor
end

local function valid(entry)
    if entry.arena~=activeArena or entry.model.Parent~=bucket
        or entry.source.Parent~=entry.holder
        or entry.holder.Parent~=ReplicatedStorage
        or entry.decor.Parent~=entry.arena
        or entry.base.Parent~=entry.arena
        or #entry.parts~=7 then return false end
    local source=sourceFor()
    if source~=entry.source then return false end
    local fin,glow,base,decor=genuine(entry.arena,entry.index)
    if fin~=entry.fin or glow~=entry.glow
        or base~=entry.base or decor~=entry.decor then return false end
    for _,piece in ipairs(entry.parts) do
        if not piece:IsDescendantOf(entry.model) then return false end
    end
    return true
end

local function mount(arena,index,fin,glow,base,decor,source,holder)
    local inspected,inspectedGlow=genuine(arena,index)
    if inspected~=fin or inspectedGlow~=glow then return end
    local clone=source:Clone()
    local frame,bounds=clone:GetBoundingBox()
    local long=math.max(bounds.X,bounds.Z)
    local thin=math.min(bounds.X,bounds.Z)
    if math.abs(long-SIZE.X)>.32
        or math.abs(bounds.Y-SIZE.Y)>.32
        or math.abs(thin-SIZE.Z)>.32 then
        clone:Destroy()
        return
    end
    -- Source long axis = X. Fin1/2 are aligned along Z; Fin3/4 X.
    -- Imported geometries may be transposed, so compare actual source.
    local sourceX=bounds.X>=bounds.Z
    local nativeX=index>=3
    local yaw=sourceX==nativeX and 0 or math.pi*.5
    local target=fin.CFrame*CFrame.Angles(0,yaw,0)
    local pieces={}
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
            pieces[#pieces+1]=piece
        end
    end
    if #pieces~=7 or not genuine(arena,index) then
        clone:Destroy()
        return
    end
    clone.Name="ClassicBroadcastSculpted3D_"..index
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",ASSET_ID)
    clone.Parent=bucket
    local entry={
        arena=arena,index=index,fin=fin,glow=glow,
        base=base,decor=decor,source=source,holder=holder,
        model=clone,parts=pieces,original=fin.Transparency,
        connections={},
    }
    mounted[fin]=entry
    if not valid(entry) then unmount(fin);return end
    fin.Transparency=1
    local function changed()
        if mounted[fin]==entry and not valid(entry) then unmount(fin) end
    end
    for _,instance in ipairs({fin,glow,base,decor,source}) do
        entry.connections[#entry.connections+1]=
            instance.AncestryChanged:Connect(changed)
    end
    for _,native in ipairs({fin,glow}) do
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
            if piece:IsA("MeshPart") then unmount(fin) end
        end)
    entry.connections[#entry.connections+1]=
        clone.DescendantRemoving:Connect(function(piece)
            if piece:IsA("MeshPart") then unmount(fin) end
        end)
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,touch,pressure)
    if arena~=activeArena then clear();activeArena=arena end
    local cap=CAP[tier] or 0
    if touch then
        -- Touch formerly forced ALL Low models back to zero even if
        -- CAP.Low were enabled. Keep exactly one original on Android Low.
        cap=tier=="High" and math.min(cap,2)
            or tier=="Medium" and math.min(cap,1)
            or tier=="Low" and math.min(cap,1) or 0
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
        local fin,glow,base,decor=genuine(arena,index)
        if fin then
            local held=mounted[fin]~=nil
            local distance=(fin.Position-cameraPoint).Magnitude
            if distance<=(RANGE[tier] or 0)+(held and RETENTION or 0) then
                ranked[#ranked+1]={
                    index=index,fin=fin,glow=glow,base=base,
                    decor=decor,source=source,holder=holder,
                    score=distance-(held and RETENTION*.5 or 0),
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
        wanted[ranked[i].fin]=ranked[i]
    end
    local stale={}
    for fin,entry in pairs(mounted) do
        if not wanted[fin] or not valid(entry)
            or entry.source~=source then stale[#stale+1]=fin
        else
            fin.Transparency=1
        end
    end
    for _,fin in ipairs(stale) do unmount(fin) end
    for fin,item in pairs(wanted) do
        if not mounted[fin] then
            mount(arena,item.index,fin,item.glow,item.base,item.decor,
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
        if valid(entry) and entry.fin.Transparency==1 then n+=1 end
    end
    return n
end

return Kit
