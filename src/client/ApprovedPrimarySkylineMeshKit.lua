-- Authenticated replacements for the four REAL SkylineStructure silhouettes.
-- Reuses creator-approved seven-MeshPart exterior tower art; no new asset IDs.
-- Only nonphysical StructuralCore, TopCap, OuterRibL/R are hidden. Keep the
-- foundation, inset navigation accents and each variant's antenna native.
-- Low keeps exactly one nearby original skyline silhouette on
-- Android/PC at normal pressure; pressure restores native geometry.
-- One existing scenery LOD sampler owns all mount/rollback decisions.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SceneryLodRules = require(ReplicatedStorage.Shared.SceneryLodRules)

local Kit = {}
local NAMES = {"North","East","South","West"}
local IDS = {
    [21] = 137744886537150,
    [24] = 74958476744494,
    [27] = 97864559770371,
    [30] = 112172520488996,
}
local PRIMARY = {
    Classic=17, Harbor=17, Crossroads=20, Orbital=22, Towers=25,
}
local SOURCE_FOR_HEIGHT = {
    [17]=21, [20]=21, [22]=24, [23]=24, [25]=27, [28]=30,
}
local DIRECTIONS = {
    {x=-22,z=-1,yaw=0},
    {x=1,z=-22,yaw=math.pi*.5},
    {x=22,z=1,yaw=math.pi},
    {x=-1,z=22,yaw=-math.pi*.5},
}
local BUDGET = {
    Low={count=1,distance=315},
    Medium={count=2,distance=390},
    High={count=4,distance=510},
}
local RETENTION = 24
local REPLACE = {"StructuralCore","TopCap","OuterRibL","OuterRibR"}
local bucket = Instance.new("Folder")
bucket.Name = "ApprovedPrimarySkylineLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent = workspace

local activeArena = nil
local mounted = {}

local function release(owner)
    local entry = mounted[owner]
    if not entry then return end
    mounted[owner] = nil
    for _,connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    for native,alpha in pairs(entry.natives) do
        if native.Parent == owner and native.Transparency == 1 then
            native.Transparency = alpha
        end
    end
    entry.model:Destroy()
end

local function releaseAll()
    local owners = {}
    for owner in pairs(mounted) do owners[#owners+1] = owner end
    for _,owner in ipairs(owners) do release(owner) end
end

local function template(height)
    local id = IDS[height]
    if not id then return nil end
    local holder = ReplicatedStorage:FindFirstChild("ApprovedExteriorTowerTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local source = holder:FindFirstChild("Tower"..height)
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalExteriorTower3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= id then
        return nil
    end
    local n = 0
    for _,item in ipairs(source:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or item.CanCollide
                or item.CanTouch or item.CanQuery then return nil end
            n += 1
        elseif item:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if n ~= 7 then return nil end
    local _,dims = source:GetBoundingBox()
    local width = math.max(dims.X,dims.Z)
    local depth = math.min(dims.X,dims.Z)
    if math.abs(dims.Y-(height+1.2)) > .45
        or math.abs(width-11.84) > .42
        or math.abs(depth-9.84) > .42 then
        return nil
    end
    return source,holder,id
end

local function checkPart(owner,name,kind,size,frame,alpha,shape)
    local part = owner:FindFirstChild(name)
    if not part or not part:IsA(kind) or part.Parent ~= owner
        or not part.Anchored or part.CanCollide or part.CanTouch
        or part.CanQuery or (part.Size-size).Magnitude > .12
        or (part.Position-frame.Position).Magnitude > .16
        or part.CFrame.LookVector:Dot(frame.LookVector) < .999
        or part.CFrame.UpVector:Dot(frame.UpVector) < .999
        or (math.abs(part.Transparency-alpha) > .035
            and part.Transparency ~= 1) then
        return nil
    end
    if shape and part:IsA("Part") and part.Shape ~= shape then
        return nil
    end
    return part
end

local function genuine(arena,owner,index)
    local variant = arena and arena:GetAttribute("VariantId")
    local baseHeight = PRIMARY[variant]
    local generated = workspace:FindFirstChild("GeneratedMap")
    local decor = arena and arena:FindFirstChild("Decor")
    local base = arena and arena:FindFirstChild("Base")
    if not arena or not arena:IsA("Folder") or not generated
        or not generated:IsA("Folder") or arena.Name ~= "Arena"
        or arena.Parent ~= generated
        or not decor or not decor:IsA("Folder") or decor.Parent ~= arena
        or not base or not base:IsA("BasePart") or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide
        or base.Size.X < 318 or base.Size.Z < 318
        or not owner or not owner:IsA("Model") or owner.Parent ~= decor
        or owner.Name ~= "SkylineStructure"..NAMES[index]
        or owner:GetAttribute("ChaosDistantScenery") ~= true
        or not baseHeight then
        return nil
    end
    local h = baseHeight+(index%2)*3
    local direction = DIRECTIONS[index]
    local x,z = direction.x,direction.z
    if index == 1 or index == 3 then
        z *= base.Size.Z*.5+23
    else
        x *= base.Size.X*.5+23
    end
    local origin = CFrame.new(base.Position+Vector3.new(
        x,base.Size.Y*.5,z))*CFrame.Angles(0,direction.yaw,0)
    local hull = checkPart(owner,"Foundation","Part",
        Vector3.new(14,2.3,10),origin*CFrame.new(0,-1.1,0),.04)
    local core = checkPart(owner,"StructuralCore","Part",
        Vector3.new(8.5,h,7.4),origin*CFrame.new(0,h*.5,0),.03,
        Enum.PartType.Block)
    local cap = checkPart(owner,"TopCap","WedgePart",
        Vector3.new(11.4,3,8.8),origin*CFrame.new(0,h+1.3,0),.06)
    local l = checkPart(owner,"OuterRibL","WedgePart",
        Vector3.new(2.2,5.4,8),
        origin*CFrame.new(-4.6,2.8,0)*CFrame.Angles(0,math.pi,0),.06)
    local r = checkPart(owner,"OuterRibR","WedgePart",
        Vector3.new(2.2,5.4,8),origin*CFrame.new(4.6,2.8,0),.06)
    local inL = checkPart(owner,"InsetL","Part",
        Vector3.new(.24,h*.54,.85),
        origin*CFrame.new(-4.30,h*.52,-3.6),.28)
    local inR = checkPart(owner,"InsetR","Part",
        Vector3.new(.24,h*.54,.85),
        origin*CFrame.new(4.30,h*.52,-3.6),.28)
    if not hull or not core or not cap or not l or not r
        or not inL or not inR then return nil end
    -- The variant-specific mast is a visual waypoint, never replaced.
    local signal
    if variant == "Orbital" then
        signal = checkPart(owner,"ReceiverHead","Part",
            Vector3.new(5.5,.75,5.5),
            origin*CFrame.new(0,h+3.4,0),.06,Enum.PartType.Cylinder)
    elseif variant == "Crossroads" then
        signal = checkPart(owner,"ExchangeMast","Part",
            Vector3.new(.7,5.5,.7),
            origin*CFrame.new(0,h+4,0),.04)
        signal = signal and checkPart(owner,"CrossAntenna","Part",
            Vector3.new(7.5,.4,.4),
            origin*CFrame.new(0,h+6.1,0),.05)
    elseif variant == "Towers" then
        signal = checkPart(owner,"ServiceMast","Part",
            Vector3.new(.85,7,.85),
            origin*CFrame.new(0,h+4.6,0),.06)
    else
        signal = checkPart(owner,"RelayAerial","WedgePart",
            Vector3.new(3.4,3.2,2),
            origin*CFrame.new(0,h+3.2,0),.06)
    end
    if not signal then return nil end
    -- Check all four parts belong to this exact generated skyline,
    -- well beyond the playable base, not a similarly named arena prop.
    if math.max(math.abs(core.Position.X-base.Position.X),
        math.abs(core.Position.Z-base.Position.Z))
        < math.min(base.Size.X,base.Size.Z)*.5 then
        return nil
    end
    return {core,cap,l,r},origin,h,base,decor
end

local function valid(entry)
    if entry.arena ~= activeArena
        or entry.model.Parent ~= bucket
        or entry.owner.Parent ~= entry.decor
        or entry.source.Parent ~= entry.holder
        or entry.holder.Parent ~= ReplicatedStorage
        or entry.base.Parent ~= entry.arena
        or #entry.parts ~= 7 then return false end
    local native = genuine(entry.arena,entry.owner,entry.index)
    if not native or #native ~= #REPLACE then return false end
    for i,n in ipairs(native) do
        if entry.originals[i] ~= n or entry.natives[n] == nil then
            return false
        end
    end
    for _,part in ipairs(entry.parts) do
        if not part:IsDescendantOf(entry.model) then return false end
    end
    return true
end

local function mount(arena,owner,index,source,holder,id)
    local native,origin,height,base,decor = genuine(arena,owner,index)
    if not native then return end
    local clone = source:Clone()
    local _,bounds = clone:GetBoundingBox()
    local width,depth = math.max(bounds.X,bounds.Z),
        math.min(bounds.X,bounds.Z)
    local scale = math.min((height+2.8)/bounds.Y,
        11.4*1.06/width,8.8*1.13/depth)
    if scale < .80 or scale > 1.10
        or not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return
    end
    local frame,size = clone:GetBoundingBox()
    local w,d = math.max(size.X,size.Z),math.min(size.X,size.Z)
    if size.Y < (height+2.8)*.965 or size.Y > height+2.9
        or w > 11.4*1.07 or d > 8.8*1.14 then
        clone:Destroy()
        return
    end
    local yaw = size.X >= size.Z and 0 or math.pi*.5
    local target = origin*CFrame.new(0,size.Y*.5,0)
        *CFrame.Angles(0,yaw,0)
    local parts = {}
    for _,piece in ipairs(clone:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then
                clone:Destroy()
                return
            end
            piece.CFrame = target*frame:ToObjectSpace(piece.CFrame)
            piece.Anchored = true
            piece.Massless = true
            piece.CanCollide = false
            piece.CanTouch = false
            piece.CanQuery = false
            piece.CastShadow = false
            piece:SetAttribute("CosmeticOnly",true)
            piece:SetAttribute("Original3DAssetId",id)
            parts[#parts+1] = piece
        end
    end
    if #parts ~= 7 or not genuine(arena,owner,index)
        or source.Parent ~= holder then
        clone:Destroy()
        return
    end
    clone.Name = "SculptedSkylineStructure"..NAMES[index]
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",id)
    clone.Parent = bucket
    local entry = {
        arena=arena,owner=owner,index=index,base=base,decor=decor,
        source=source,holder=holder,model=clone,parts=parts,
        natives={},originals=native,connections={},
    }
    for _,part in ipairs(native) do entry.natives[part] = part.Transparency end
    mounted[owner] = entry
    if not valid(entry) then release(owner);return end
    for _,part in ipairs(native) do part.Transparency = 1 end
    local function check()
        if mounted[owner] == entry and not valid(entry) then
            release(owner)
        end
    end
    for _,object in ipairs({owner,base,source}) do
        entry.connections[#entry.connections+1] =
            object.AncestryChanged:Connect(check)
    end
    for _,signal in ipairs({
        base:GetPropertyChangedSignal("Size"),
        base:GetPropertyChangedSignal("CFrame"),
        base:GetPropertyChangedSignal("CanCollide"),
    }) do
        entry.connections[#entry.connections+1] = signal:Connect(check)
    end
    entry.connections[#entry.connections+1] =
        source.DescendantRemoving:Connect(function(p)
            if p:IsA("MeshPart") then release(owner) end
        end)
    entry.connections[#entry.connections+1] =
        clone.DescendantRemoving:Connect(function(p)
            if p:IsA("MeshPart") then release(owner) end
        end)
    for _,part in ipairs(native) do
        entry.connections[#entry.connections+1] =
            part.AncestryChanged:Connect(check)
        entry.connections[#entry.connections+1] =
            part:GetPropertyChangedSignal("CFrame"):Connect(check)
        entry.connections[#entry.connections+1] =
            part:GetPropertyChangedSignal("Size"):Connect(check)
    end
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,touch,pressure,cameraLook)
    if arena ~= activeArena then
        releaseAll()
        activeArena = arena
    end
    local spec = BUDGET[tier] or BUDGET.Low
    local stress = math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    local cap = spec.count
    if touch then
        cap = tier == "High" and math.min(cap,2)
            or tier == "Medium" and math.min(cap,1)
            or tier == "Low" and math.min(cap,1) or 0
    end
    if stress == 1 then cap = math.floor(cap*.5) end
    if stress >= 2 then cap = 0 end
    if cap == 0 or not cameraReady
        or typeof(cameraPoint) ~= "Vector3" then
        releaseAll()
        return
    end
    local ranked = {}
    local decor = arena and arena:FindFirstChild("Decor")
    if not decor or not decor:IsA("Folder") then
        releaseAll()
        return
    end
    for index,name in ipairs(NAMES) do
        local owner = decor:FindFirstChild("SkylineStructure"..name)
        local native,_,height = genuine(arena,owner,index)
        local srcHeight = height and SOURCE_FOR_HEIGHT[height]
        local source,holder,id = template(srcHeight)
        if native and source then
            local held = mounted[owner] ~= nil
            local distance = (cameraPoint-native[1].Position).Magnitude
            if distance <= spec.distance+(held and RETENTION or 0) then
                ranked[#ranked+1] = {
                    owner=owner,index=index,source=source,holder=holder,
                    id=id,score=SceneryLodRules.skylineViewScore(
                        distance-(held and RETENTION*.5 or 0),
                        native[1].Position-cameraPoint,cameraLook),
                }
            end
        end
    end
    table.sort(ranked,function(a,b)
        if a.score ~= b.score then return a.score < b.score end
        return a.index < b.index
    end)
    local wanted = {}
    for i=1,math.min(cap,#ranked) do
        wanted[ranked[i].owner] = ranked[i]
    end
    local obsolete = {}
    for owner,entry in pairs(mounted) do
        local target = wanted[owner]
        if not target or target.source ~= entry.source or not valid(entry) then
            obsolete[#obsolete+1] = owner
        else
            for native in pairs(entry.natives) do
                native.Transparency = 1
            end
        end
    end
    for _,owner in ipairs(obsolete) do release(owner) end
    for owner,item in pairs(wanted) do
        if not mounted[owner] then
            mount(arena,owner,item.index,item.source,item.holder,item.id)
        end
    end
end

function Kit.count()
    local n = 0
    for _,entry in pairs(mounted) do
        if valid(entry) then n += 1 end
    end
    return n
end

function Kit.replacedNativeCount()
    local n = 0
    for _,entry in pairs(mounted) do
        if valid(entry) then
            for part in pairs(entry.natives) do
                if part.Parent == entry.owner and part.Transparency == 1 then
                    n += 1
                end
            end
        end
    end
    return n
end

return Kit
