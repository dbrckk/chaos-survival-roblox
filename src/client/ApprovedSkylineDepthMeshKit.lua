-- Camera-selected distant roofs and their forged aerials share the existing
-- scenery sampler and Android residency limits. Both have a native fallback.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SceneryLodRules = if script then require(ReplicatedStorage.Shared.SceneryLodRules)
    else require("../shared/SceneryLodRules")

local ExteriorDetailGeometry = require("./ExteriorDetailGeometry")

local Kit = {}
local SOURCE_ID = 80692067525256
local SOURCE_SIZE = Vector3.new(11.4,33.95,7.19)
local AERIAL_ID = 105555650820011
local AERIAL_HOLDER = "ApprovedVariantIdentitySpineTemplates"
local AERIAL_TAG = "OriginalVariantIdentitySpine3D"
local AERIAL_SIZE = Vector3.new(2.16,11.92,2.16)
-- Exact bounds from the approved OBJ's ARMOR hull and BRUSHED end sockets.
-- Their combined 384 source triangles carry the entire distant silhouette.
local AERIAL_HULL = Vector3.new(1.9388,11.52,1.8788)
local DIRECTIONS = {
    {id="North",x=-22,z=-1,yaw=0},
    {id="East",x=1,z=-22,yaw=math.pi*.5},
    {id="South",x=22,z=1,yaw=math.pi},
    {id="West",x=-1,z=22,yaw=-math.pi*.5},
}
local VARIANTS = {Classic=true,Towers=true,Crossroads=true,
    Orbital=true,Harbor=true}
local BUDGET = {
    Low={cap=1,distance=315},
    Medium={cap=2,distance=425},
    High={cap=4,distance=570},
}
local RETENTION = 28
local bucket = Instance.new("Folder")
bucket.Name = "ApprovedSkylineDepthLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent = workspace
local activeArena = nil
local mounted = {}

local function releaseAerial(entry)
    local aerial = entry.aerial
    if not aerial then return end
    entry.aerial = nil
    for _,connection in ipairs(aerial.connections) do
        connection:Disconnect()
    end
    if aerial.native.Transparency == 1 then
        aerial.native.Transparency = aerial.alpha
    end
    aerial.model:Destroy()
end

-- The eight SkylineDepth source roof masses are stationary OUTBOARD
-- sculptures authored at the unshrunk 320-stud playfield perimeter.
-- Size changes of the playable Base must not retarget those originals.
local function authenticFootprint(base, arena)
    if not base or not base:IsA("BasePart")
        or not arena or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide then return nil end
    local sx = base:GetAttribute("OriginalSizeX")
    local sz = base:GetAttribute("OriginalSizeZ")
    if typeof(sx) ~= "number" or typeof(sz) ~= "number"
        or sx < 318 or sz < 318
        or base.Size.X <= 0 or base.Size.Z <= 0
        or base.Size.X > sx + 0.2 or base.Size.Z > sz + 0.2 then
        return nil
    end
    return sx, sz
end

local function restore(owner)
    local entry = mounted[owner]
    if not entry then return end
    mounted[owner] = nil
    for _,connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    releaseAerial(entry)
    local body = entry.body
    if body.Transparency == 1 then
        body.Transparency = entry.original
    end
    entry.model:Destroy()
end

local function clear()
    local owners = {}
    for owner in pairs(mounted) do owners[#owners+1] = owner end
    for _,owner in ipairs(owners) do restore(owner) end
end

local function approved()
    -- No trust in a guessed ID, a local model with the same name, or
    -- replicated partial geometry: this must be the exact server-sanitized
    -- 11-Nov owner-approved original sculpture (workflow #42994003806).
    local holder = ReplicatedStorage:FindFirstChild(
        "ApprovedSkylineDepthSculptTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local template = holder:FindFirstChild("Roof")
    if not template or not template:IsA("Model")
        or template.Parent ~= holder
        or template:GetAttribute("OwnerVerified") ~= true
        or template:GetAttribute("CosmeticOnly") ~= true
        or template:GetAttribute("OriginalSkylineDepthSculpt3D") ~= true
        or template:GetAttribute("Original3DAssetId") ~= SOURCE_ID then
        return nil
    end
    local count = 0
    for _,part in ipairs(template:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart")
                or part.CanCollide or part.CanTouch or part.CanQuery then
                return nil
            end
            count += 1
        elseif part:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count ~= 7 then return nil end
    local _,bounds = template:GetBoundingBox()
    if math.abs(bounds.Y - SOURCE_SIZE.Y) > .45 then return nil end
    local direct = math.abs(bounds.X-SOURCE_SIZE.X)
        + math.abs(bounds.Z-SOURCE_SIZE.Z)
    local swapped = math.abs(bounds.Z-SOURCE_SIZE.X)
        + math.abs(bounds.X-SOURCE_SIZE.Z)
    local yaw = direct <= swapped and 0 or math.pi*.5
    if math.min(direct,swapped) > .86 then return nil end
    return template,holder,SOURCE_ID,yaw
end

local function trustedAerial(source, holder)
    return holder and holder:IsA("Folder") and holder.Parent == ReplicatedStorage
        and holder.Name == AERIAL_HOLDER and holder:GetAttribute("OwnerVerified") == true
        and source and source:IsA("Model") and source.Parent == holder
        and source.Name == "Classic" and source:GetAttribute("OwnerVerified") == true
        and source:GetAttribute("CosmeticOnly") == true
        and source:GetAttribute(AERIAL_TAG) == true
        and source:GetAttribute("Original3DAssetId") == AERIAL_ID
end

local function approvedAerial()
    local holder = ReplicatedStorage:FindFirstChild(AERIAL_HOLDER)
    local source = holder and holder:FindFirstChild("Classic")
    if not trustedAerial(source, holder) then return nil end
    local children = source:GetChildren()
    if #children ~= 7 then return nil end
    local frame, size = source:GetBoundingBox()
    if (size-AERIAL_SIZE).Magnitude > .30 then return nil end
    local hull, sockets
    for _,part in ipairs(children) do
        if not part:IsA("MeshPart") or not part.Anchored or part.CanCollide
            or part.CanTouch or part.CanQuery or part.Transparency >= 1 then
            return nil
        end
        for _,detail in ipairs(part:GetDescendants()) do
            if not detail:IsA("SurfaceAppearance") and not detail:IsA("Decal")
                and not detail:IsA("Texture") then return nil end
        end
        local dims = Vector3.new(math.max(part.Size.X,part.Size.Z),part.Size.Y,
            math.min(part.Size.X,part.Size.Z))
        if (frame.Position-part.Position).Magnitude < .16
            and math.abs(part.CFrame.UpVector:Dot(frame.UpVector)) > .999 then
            if (dims-AERIAL_HULL).Magnitude < .13 then
                if hull then return nil end
                hull = part
            elseif (dims-AERIAL_SIZE).Magnitude < .16 then
                if sockets then return nil end
                sockets = part
            end
        end
    end
    if not hull or not sockets then return nil end
    return {source=source,holder=holder,frame=frame,hull=hull,sockets=sockets}
end

local function genuineAerial(owner, body, layer)
    local aerial = owner:FindFirstChild("DistantAerial")
    local size = Vector3.new(.38,4+layer*2,.38)
    local position = body.Position+Vector3.new(0,(body.Size.Y+size.Y)*.5,0)
    local fittedSize, pose = ExteriorDetailGeometry.monumentFootprint(aerial, owner, "Part")
    if not fittedSize or (fittedSize-size).Magnitude > .08 or (pose.Position-position).Magnitude > .20
        or pose.UpVector:Dot(Vector3.yAxis) < .999
        or aerial.LocalTransparencyModifier >= .95
        or aerial:GetAttribute("SceneryLodHidden") == true then return nil end
    return aerial
end

local function realOwner(arena,decor,base,direction,index,layer)
    local originalX, originalZ = authenticFootprint(base, arena)
    if not originalX or not originalZ then return nil end
    local owner = decor:FindFirstChild("SkylineDepth"..direction.id..layer)
    if not owner or not owner:IsA("Model") or owner.Parent ~= decor
        or owner:GetAttribute("ChaosDistantScenery") ~= true then
        return nil
    end
    local body = owner:FindFirstChild("DistantRoofMass")
    local variant = arena:GetAttribute("VariantId")
    local height = (variant == "Towers" and 31 or 22)
        + layer*5 + ((index+layer)%3)*3
    local x = direction.x
    local z = direction.z
    if direction.id == "North" or direction.id == "South" then
        z = z*(originalZ*.5+23)
    else
        x = x*(originalX*.5+23)
    end
    local side = Vector3.new(math.cos(direction.yaw),0,
        -math.sin(direction.yaw))
    local outward = Vector3.new(math.sin(direction.yaw),0,
        -math.cos(direction.yaw))
    local origin = base.Position
        + Vector3.new(x,base.Size.Y*.5,z)
        + outward*(16+layer*10)
        + side*(layer == 1 and -17 or 19)
    local expected = CFrame.new(origin+Vector3.new(0,height*.5,0))
        * CFrame.Angles(0,direction.yaw,0)
    local sourceSize = Vector3.new(10+layer*3,height,8)
    local original = .14+layer*.12
    local size, pose = ExteriorDetailGeometry.monumentFootprint(body, owner, "WedgePart")
    if not size or (size-sourceSize).Magnitude > .12
        or (pose.Position-expected.Position).Magnitude > .20
        or pose.LookVector:Dot(expected.LookVector) < .999
        or pose.UpVector:Dot(expected.UpVector) < .999
        or (math.abs(body.Transparency-original) > .035
            and body.Transparency ~= 1) then
        return nil
    end
    return owner,body,original
end

local function valid(entry)
    local size, pose = ExteriorDetailGeometry.monumentFootprint(entry.body, entry.owner, "WedgePart")
    if not size or entry.arena ~= activeArena
        or entry.model.Parent ~= bucket
        or entry.owner.Parent ~= entry.decor
        or entry.decor.Parent ~= entry.arena
        or entry.arena.Parent ~= workspace:FindFirstChild("GeneratedMap")
        or not authenticFootprint(entry.base, entry.arena)
        or entry.source.Parent ~= entry.holder
        or entry.holder.Parent ~= ReplicatedStorage
        or size ~= entry.size
        or (pose.Position-entry.pose.Position).Magnitude > .08
        or pose.LookVector:Dot(entry.pose.LookVector) < .999
        or pose.UpVector:Dot(entry.pose.UpVector) < .999
        or #entry.pieces ~= 7 then return false end
    for _,part in ipairs(entry.pieces) do
        if not part:IsDescendantOf(entry.model) then return false end
    end
    return true
end

local function mountAerial(entry, native, layer, approved)
    if native.Transparency >= 1 then return end
    local clone = Instance.new("Model")
    clone.Name = "ForgedDistantAerial"
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",AERIAL_ID)
    local height = native.Size.Y
    local width = layer == 1 and .94 or 1.08
    local frame = entry.pose * CFrame.new(0,
        entry.roofHeight-entry.size.Y*.5+height*.5-.16,0)
    local scale = Vector3.new(width/AERIAL_SIZE.X,height/AERIAL_SIZE.Y,width/AERIAL_SIZE.Z)
    for _,part in ipairs({approved.hull,approved.sockets}) do
        local mesh = part:Clone()
        if not mesh then clone:Destroy();return end
        local offset = approved.frame:ToObjectSpace(part.CFrame)
        mesh.Size *= scale
        mesh.CFrame = frame*CFrame.new(offset.Position*scale)*offset.Rotation
        mesh.Massless = true
        mesh.CastShadow = false
        mesh.LocalTransparencyModifier = 0
        mesh.Color = mesh.Color:Lerp(native.Color,.60)
        mesh.Transparency = native.Transparency*.8
        mesh.Parent = clone
    end
    clone.Parent = entry.model
    local aerial = {model=clone,native=native,source=approved.source,
        hull=approved.hull,sockets=approved.sockets,alpha=native.Transparency,connections={}}
    entry.aerial = aerial
    local function revoke()
        if entry.aerial == aerial then releaseAerial(entry) end
    end
    local function checkSource()
        if not trustedAerial(approved.source,approved.holder) then revoke() end
    end
    local function checkNative()
        if genuineAerial(entry.owner,entry.body,layer) ~= native then revoke() end
    end
    local function watch(signal,callback)
        table.insert(aerial.connections,signal:Connect(callback))
    end
    watch(clone.ChildRemoved,revoke)
    watch(clone.AncestryChanged,function()
        if clone.Parent ~= entry.model then revoke() end
    end)
    watch(approved.source.ChildAdded,revoke)
    watch(approved.source.ChildRemoved,revoke)
    watch(approved.source.AncestryChanged,checkSource)
    watch(approved.source:GetPropertyChangedSignal("Name"),checkSource)
    watch(approved.holder:GetPropertyChangedSignal("Name"),checkSource)
    watch(approved.holder:GetAttributeChangedSignal("OwnerVerified"),checkSource)
    for _,attribute in ipairs({"OwnerVerified","CosmeticOnly",AERIAL_TAG,"Original3DAssetId"}) do
        watch(approved.source:GetAttributeChangedSignal(attribute),checkSource)
    end
    watch(native.AncestryChanged,checkNative)
    watch(native:GetAttributeChangedSignal("SceneryLodHidden"),checkNative)
    for _,property in ipairs({"Name","CFrame","Size","Anchored","CanCollide",
        "CanTouch","CanQuery","LocalTransparencyModifier"}) do
        watch(native:GetPropertyChangedSignal(property),checkNative)
    end
    if native:IsA("Part") then
        watch(native:GetPropertyChangedSignal("Shape"),checkNative)
    elseif native:IsA("MeshPart") then
        watch(native:GetPropertyChangedSignal("MeshId"),checkNative)
        for _,attribute in ipairs({"OriginalExteriorDetail3D","Original3DAssetId","ExteriorDetailAxisSwap"}) do
            watch(native:GetAttributeChangedSignal(attribute),checkNative)
        end
    end
    native.Transparency = 1
end

local function syncAerial(entry, layer, approved)
    local native = approved and genuineAerial(entry.owner,entry.body,layer)
    local aerial = entry.aerial
    if aerial and (not native or aerial.native ~= native
        or aerial.source ~= approved.source or aerial.hull ~= approved.hull
        or aerial.sockets ~= approved.sockets or aerial.model.Parent ~= entry.model
        or #aerial.model:GetChildren() ~= 2) then
        releaseAerial(entry)
        aerial = nil
    end
    if aerial then
        if native.Transparency < 1 then
            aerial.alpha = native.Transparency
            native.Transparency = 1
        end
    elseif native then
        mountAerial(entry,native,layer,approved)
    end
end

local function mount(arena,decor,base,owner,body,original,source,
        holder,id,yaw)
    local size, pose = ExteriorDetailGeometry.monumentFootprint(body, owner, "WedgePart")
    if not size then return end
    local clone = source:Clone()
    if not clone then return end
    local _,bounds = clone:GetBoundingBox()
    -- Preserve a single sculpt's proportions across all 27..47 stud
    -- native heights; bounded uniform scaling prevents a cheap stretched
    -- tower. No procedural Parts, renderer loops or physical effects.
    local rawWidth = yaw == 0 and bounds.X or bounds.Z
    local rawDepth = yaw == 0 and bounds.Z or bounds.X
    local scale = math.min(size.Y/bounds.Y,
        size.X*1.15/rawWidth,size.Z*1.28/rawDepth)
    if scale < .72 or scale > 1.55
        or not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return
    end
    local frame,scaled = clone:GetBoundingBox()
    local width = yaw == 0 and scaled.X or scaled.Z
    local depth = yaw == 0 and scaled.Z or scaled.X
    if scaled.Y < size.Y*.79
        or scaled.Y > size.Y*1.07
        or width > size.X*1.15
        or depth > size.Z*1.28 then
        clone:Destroy()
        return
    end
    local target = pose
        * CFrame.new(0,(scaled.Y-size.Y)*.5,0)
        * CFrame.Angles(0,yaw,0)
    local pieces = {}
    for _,part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return
            end
            part.CFrame = target*frame:ToObjectSpace(part.CFrame)
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            pieces[#pieces+1] = part
        end
    end
    if #pieces ~= 7 then clone:Destroy();return end
    clone.Name = "Sculpted"..owner.Name
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("Original3DAssetId",id)
    clone.Parent = bucket
    local entry = {
        arena=arena,decor=decor,base=base,owner=owner,body=body,
        original=original,source=source,holder=holder,model=clone,
        pieces=pieces,connections={},size=size,pose=pose,roofHeight=scaled.Y,
    }
    mounted[owner] = entry
    if not valid(entry) then restore(owner);return end
    body.Transparency = 1
    local function changed()
        if mounted[owner] == entry and not valid(entry) then
            restore(owner)
        end
    end
    for _,signal in ipairs({
        body.AncestryChanged,owner.AncestryChanged,
        source.AncestryChanged,base.AncestryChanged,
        body:GetPropertyChangedSignal("CFrame"),
        body:GetPropertyChangedSignal("Size"),
        body:GetPropertyChangedSignal("Anchored"),
        body:GetPropertyChangedSignal("CanCollide"),
        body:GetPropertyChangedSignal("CanTouch"),
        body:GetPropertyChangedSignal("CanQuery"),
        clone.AncestryChanged,
    }) do
        entry.connections[#entry.connections+1] = signal:Connect(changed)
    end
    if body:IsA("MeshPart") then
        entry.connections[#entry.connections+1] = body:GetPropertyChangedSignal("MeshId"):Connect(changed)
        for _,attribute in ipairs({"OriginalExteriorDetail3D","Original3DAssetId","ExteriorDetailAxisSwap"}) do
            entry.connections[#entry.connections+1] = body:GetAttributeChangedSignal(attribute):Connect(changed)
        end
    end
    entry.connections[#entry.connections+1] =
        source.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then restore(owner) end
        end)
    entry.connections[#entry.connections+1] =
        clone.DescendantRemoving:Connect(function(part)
            if table.find(pieces,part) then restore(owner) end
        end)
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,pressure,touch,cameraLook)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local spec = BUDGET[tier] or BUDGET.Low
    local pressureValue = tonumber(pressure) or 0
    local stress = pressureValue == pressureValue and math.clamp(math.floor(pressureValue),0,2) or 0
    local cap = spec.cap
    if tier == "High" and touch then cap = 3 end
    if stress == 1 then cap = math.floor(cap*.5) end
    if stress >= 2 then cap = 0 end
    if not cameraReady or typeof(cameraPoint) ~= "Vector3"
        or cap == 0 then
        clear()
        return
    end
    local generated = workspace:FindFirstChild("GeneratedMap")
    local base = arena and arena:FindFirstChild("Base")
    local decor = arena and arena:FindFirstChild("Decor")
    if not arena or not arena:IsA("Folder") or not generated
        or arena.Parent ~= generated
        or not authenticFootprint(base, arena) or not decor
        or not decor:IsA("Folder") or decor.Parent ~= arena
        or not VARIANTS[arena:GetAttribute("VariantId")] then
        clear()
        return
    end
    local ranked = {}
    local source,holder,id,yaw = approved()
    for index,direction in ipairs(DIRECTIONS) do
        for layer=1,2 do
            local owner,body,original =
                realOwner(arena,decor,base,direction,index,layer)
            if owner then
                -- Exactly one approved model across all eight heights.
                -- The original native roof remains as visual fallback.
                local held = mounted[owner] ~= nil
                local distance = (cameraPoint-body.Position).Magnitude
                if source and distance <= spec.distance
                    +(held and RETENTION or 0) then
                    ranked[#ranked+1] = {
                        owner=owner,body=body,original=original,
                        source=source,holder=holder,id=id,yaw=yaw,
                        score=SceneryLodRules.sceneryViewScore(
                            distance-(held and RETENTION*.55 or 0),
                            body.Position-cameraPoint,cameraLook),
                        index=(index-1)*2+layer,layer=layer,
                    }
                end
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
    local old = {}
    for owner,entry in pairs(mounted) do
        local next = wanted[owner]
        if not next or not valid(entry)
            or entry.source ~= next.source then
            old[#old+1] = owner
        else
            entry.body.Transparency = 1
        end
    end
    for _,owner in ipairs(old) do restore(owner) end
    local aerialSource = stress == 0 and source and approvedAerial() or nil
    for owner,candidate in pairs(wanted) do
        if not mounted[owner] then
            mount(arena,decor,base,owner,candidate.body,
                candidate.original,candidate.source,candidate.holder,
                candidate.id,candidate.yaw)
        end
        local entry = mounted[owner]
        if entry then syncAerial(entry,candidate.layer,aerialSource) end
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
    local roofs, aerials = 0, 0
    for _,entry in pairs(mounted) do
        if valid(entry) then
            if entry.body.Transparency == 1 then roofs += 1 end
            local aerial = entry.aerial
            if aerial and aerial.model.Parent == entry.model
                and aerial.native.Parent == entry.owner
                and aerial.native.Transparency == 1 then aerials += 1 end
        end
    end
    return roofs,aerials
end

return Kit
