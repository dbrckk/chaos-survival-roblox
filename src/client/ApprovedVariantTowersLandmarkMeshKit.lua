-- Towers corner machinery: one genuine seven-material creator-approved
-- sculpt shared by four independently generated nonphysical landmarks.
-- Source workflow 42861370182: Roblox Model 72143366927826 Approved.
-- This is cosmetic-only and runs on the EXISTING scenery-lod client sampler.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local ID = 72143366927826
local BOUNDS = Vector3.new(7.36,24.9,7.36)
local CAP = {Low=0,Medium=2,High=4}
local RANGE = {Low=0,Medium=290,High=410}
local RETENTION = 24
local bucket = Instance.new("Folder")
bucket.Name = "ApprovedTowersMachineryLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent = workspace

local activeArena = nil
local mounted = {}

local function restore(body)
    local entry = mounted[body]
    if not entry then return end
    mounted[body] = nil
    for _,connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    for native,alpha in pairs(entry.natives) do
        if native.Parent == entry.decor and native.Transparency == 1
            and native.Anchored and not native.CanCollide
            and not native.CanTouch and not native.CanQuery then
            native.Transparency = alpha
        end
    end
    -- TowerMachineryCap is animated by arena-identity-motion: restore
    -- only its local visibility and previous LOD owner, never its
    -- live Transparency or CFrame, which belong to the animator.
    if entry.cap.Parent==entry.decor then
        entry.cap.LocalTransparencyModifier=entry.capOriginalModifier
        entry.cap:SetAttribute("SceneryLodHidden",entry.capOriginalHidden)
    end
    entry.model:Destroy()
end

local function clear()
    local owners = {}
    for body in pairs(mounted) do owners[#owners+1]=body end
    for _,body in ipairs(owners) do restore(body) end
end

local function sourceFor()
    local holder=ReplicatedStorage:FindFirstChild("ApprovedVariantTowersLandmarkTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local source=holder:FindFirstChild("Machinery")
    if not source or not source:IsA("Model")
        or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalTowersMachinery3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= ID then
        return nil
    end
    local count = 0
    for _,piece in ipairs(source:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") or piece.CanCollide
                or piece.CanTouch or piece.CanQuery then
                return nil
            end
            count += 1
        elseif piece:IsA("LuaSourceContainer") then return nil end
    end
    if count ~= 7 then return nil end
    local _,bounds=source:GetBoundingBox()
    if (bounds-BOUNDS).Magnitude > .55 then return nil end
    return source,holder
end

local function genuine(arena,index)
    local generated=workspace:FindFirstChild("GeneratedMap")
    local base=arena and arena:FindFirstChild("Base")
    local decor=arena and arena:FindFirstChild("Decor")
    if not arena or not arena:IsA("Folder") or arena.Name ~= "Arena"
        or not generated or not generated:IsA("Folder")
        or arena.Parent ~= generated or arena:GetAttribute("VariantId") ~= "Towers"
        or not base or not base:IsA("BasePart") or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide
        or typeof(base:GetAttribute("OriginalSizeX"))~="number"
        or typeof(base:GetAttribute("OriginalSizeZ"))~="number"
        or base:GetAttribute("OriginalSizeX")<318
        or base:GetAttribute("OriginalSizeZ")<318
        or not decor or not decor:IsA("Folder") or decor.Parent ~= arena
        or index < 1 or index > 4 then
        return nil
    end
    local x=(index==1 or index==3) and -1 or 1
    local z=index <= 2 and -1 or 1
    local originalX=base:GetAttribute("OriginalSizeX")
    local originalZ=base:GetAttribute("OriginalSizeZ")
    local center=base.Position+Vector3.new(
        x*(originalX*.5+6),12,z*(originalZ*.5+6))
    local body=decor:FindFirstChild("TowerMachinery"..index)
    local cap=decor:FindFirstChild("TowerMachineryCap"..index)
    local antenna=decor:FindFirstChild("TowerAntenna"..index)
    if not body or not cap or not antenna
        or not body:IsA("Part") or not cap:IsA("Part")
        or not antenna:IsA("Part")
        or body.Parent ~= decor or cap.Parent ~= decor
        or antenna.Parent ~= decor then return nil end
    for _,part in ipairs({body,cap,antenna}) do
        if not part.Anchored or part.CanCollide
            or part.CanTouch or part.CanQuery
            or part.Shape ~= Enum.PartType.Block then
            return nil
        end
    end
    if (body.Size-Vector3.new(5.2,24,5.2)).Magnitude > .10
        or (cap.Size-Vector3.new(7.4,1,7.4)).Magnitude > .10
        or (antenna.Size-Vector3.new(.55,9,.55)).Magnitude > .10
        or (body.Position-center).Magnitude > .16
        or (cap.Position-(center+Vector3.new(0,12.4,0))).Magnitude > .28
        or (antenna.Position-(center+Vector3.new(0,17.2,0))).Magnitude > .16
        or body.CFrame.LookVector:Dot(Vector3.new(0,0,-1)) < .999
        or cap.CFrame.LookVector:Dot(Vector3.new(0,0,-1)) < .999
        or math.abs(body.Transparency-.04) > .035
            and body.Transparency ~= 1
        or not ((cap.Transparency>=.05 and cap.Transparency<=.68)
            or cap.Transparency==1)
        -- Antenna also pulses and tilts; preserve it as a live native.
        or not (antenna.Transparency>=.05
            and antenna.Transparency<=.68) then
        return nil
    end
    -- Current prefab is already outside the playable Base: new mesh width
    -- 7.36 < 12-stud total setback, leaving >2.3 studs of separation.
    return body,cap,decor,base,center
end

local function valid(entry)
    if entry.arena ~= activeArena or entry.model.Parent ~= bucket
        or entry.source.Parent ~= entry.holder
        or entry.holder.Parent ~= ReplicatedStorage
        or entry.decor.Parent ~= entry.arena
        or entry.base.Parent ~= entry.arena or #entry.pieces ~= 7 then
        return false
    end
    local body,cap,decor,base=genuine(entry.arena,entry.index)
    if body ~= entry.body or cap ~= entry.cap
        or decor ~= entry.decor or base ~= entry.base then
        return false
    end
    for _,piece in ipairs(entry.pieces) do
        if not piece:IsDescendantOf(entry.model) then return false end
    end
    return true
end

local function mount(arena,index,body,cap,decor,base,source,holder)
    if mounted[body] then return end
    local originalBody,originalCap=genuine(arena,index)
    if originalBody ~= body or originalCap ~= cap then return end
    if cap:GetAttribute("SceneryLodHidden")==true then return end
    local clone=source:Clone()
    local frame,bounds=clone:GetBoundingBox()
    if (bounds-BOUNDS).Magnitude > .55 then
        clone:Destroy()
        return
    end
    -- The original union has bottom 0/top 24.9 while TowerMachinery is
    -- centered at 12.0 with height 24; shift only +0.45 stud vertically.
    local target=CFrame.new(body.Position+Vector3.new(0,.45,0))
    local pieces={}
    for _,piece in ipairs(clone:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then
                clone:Destroy()
                return
            end
            piece.CFrame=target*frame:ToObjectSpace(piece.CFrame)
            piece.Anchored=true
            piece.Massless=true
            piece.CanCollide=false
            piece.CanTouch=false
            piece.CanQuery=false
            piece.CastShadow=false
            piece:SetAttribute("CosmeticOnly",true)
            piece:SetAttribute("Original3DAssetId",ID)
            pieces[#pieces+1]=piece
        end
    end
    if #pieces ~= 7 then clone:Destroy();return end
    local entry={
        arena=arena,index=index,body=body,cap=cap,
        decor=decor,base=base,source=source,holder=holder,
        model=clone,pieces=pieces,natives={
            [body]=body.Transparency,
        },connections={},
        capOriginalModifier=cap.LocalTransparencyModifier,
        capOriginalHidden=cap:GetAttribute("SceneryLodHidden"),
    }
    clone.Name="TowersCornerSculpted3D_"..index
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",ID)
    clone.Parent=bucket
    mounted[body]=entry
    if not valid(entry) then restore(body);return end
    body.Transparency=1
    cap:SetAttribute("SceneryLodHidden",true)
    cap.LocalTransparencyModifier=1
    local function check()
        if mounted[body]==entry and not valid(entry) then restore(body) end
    end
    for _,object in ipairs({body,cap,base,decor,source}) do
        entry.connections[#entry.connections+1]=
            object.AncestryChanged:Connect(check)
    end
    for _,native in ipairs({body,cap}) do
        entry.connections[#entry.connections+1]=
            native:GetPropertyChangedSignal("Size"):Connect(check)
        entry.connections[#entry.connections+1]=
            native:GetPropertyChangedSignal("CFrame"):Connect(check)
    end
    entry.connections[#entry.connections+1]=
        base:GetPropertyChangedSignal("Size"):Connect(check)
    entry.connections[#entry.connections+1]=
        base:GetPropertyChangedSignal("CFrame"):Connect(check)
    entry.connections[#entry.connections+1]=
        source.DescendantRemoving:Connect(function(p)
            if p:IsA("MeshPart") then restore(body) end
        end)
    entry.connections[#entry.connections+1]=
        clone.DescendantRemoving:Connect(function(p)
            if p:IsA("MeshPart") then restore(body) end
        end)
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,touch,pressure)
    if arena ~= activeArena then clear();activeArena=arena end
    local cap=CAP[tier] or 0
    if touch then
        cap=tier=="High" and math.min(cap,2)
            or tier=="Medium" and math.min(cap,1) or 0
    end
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if stress==1 then cap=math.floor(cap*.5) end
    if stress>=2 then cap=0 end
    if cap==0 or not cameraReady
        or typeof(cameraPoint)~="Vector3" then clear();return end
    local ranked={}
    local source,holder=sourceFor()
    if not source then clear();return end
    for index=1,4 do
        local body,capPart,decor,base=genuine(arena,index)
        if body then
            local held=mounted[body]~=nil
            local distance=(body.Position-cameraPoint).Magnitude
            if distance <= (RANGE[tier] or 0)+(held and RETENTION or 0) then
                ranked[#ranked+1]={
                    body=body,capPart=capPart,decor=decor,base=base,
                    source=source,holder=holder,index=index,
                    score=distance-(held and RETENTION*.55 or 0),
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
    local obsolete={}
    for body,entry in pairs(mounted) do
        if not wanted[body] or not valid(entry)
            or entry.source ~= source then
            obsolete[#obsolete+1]=body
        else
            for part in pairs(entry.natives) do part.Transparency=1 end
            entry.cap:SetAttribute("SceneryLodHidden",true)
            entry.cap.LocalTransparencyModifier=1
        end
    end
    for _,body in ipairs(obsolete) do restore(body) end
    for body,candidate in pairs(wanted) do
        if not mounted[body] then
            mount(arena,candidate.index,body,candidate.capPart,
                candidate.decor,candidate.base,
                candidate.source,candidate.holder)
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
            for native in pairs(entry.natives) do
                if native.Parent==entry.decor and native.Transparency==1 then
                    n+=1
                end
            end
            if entry.cap.Parent==entry.decor
                and entry.cap.LocalTransparencyModifier>=.99
                and entry.cap:GetAttribute("SceneryLodHidden")==true then
                n+=1
            end
        end
    end
    return n
end

return Kit
