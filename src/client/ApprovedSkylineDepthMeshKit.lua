-- Replaces camera-selected nonphysical SkylineDepth roof wedges with genuine
-- owner-approved exterior tower sculptures. Never alters DistantAerial cues,
-- gameplay collision, server map generation, or the Roblox asset registry.
-- Shared scenery LOD sampler owns this module: NO new frame loop / asset load.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local SOURCE = {
    [27] = 97864559770371,
    [30] = 112172520488996,
}
local DIRECTIONS = {
    {id="North",x=-22,z=-1,yaw=0},
    {id="East",x=1,z=-22,yaw=math.pi*.5},
    {id="South",x=22,z=1,yaw=math.pi},
    {id="West",x=-1,z=22,yaw=-math.pi*.5},
}
local VARIANTS = {Classic=true,Towers=true,Crossroads=true,
    Orbital=true,Harbor=true}
local BUDGET = {
    Low={cap=0,distance=0},
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

local function restore(owner)
    local entry = mounted[owner]
    if not entry then return end
    mounted[owner] = nil
    for _,connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    local body = entry.body
    if body.Parent == owner and body.Transparency == 1 then
        body.Transparency = entry.original
    end
    entry.model:Destroy()
end

local function clear()
    local owners = {}
    for owner in pairs(mounted) do owners[#owners+1] = owner end
    for _,owner in ipairs(owners) do restore(owner) end
end

local function approved(height)
    local id = SOURCE[height]
    if not id then return nil end
    local holder = ReplicatedStorage:FindFirstChild("ApprovedExteriorTowerTemplates")
    if not holder or not holder:IsA("Folder")
        or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local template = holder:FindFirstChild("Tower"..height)
    if not template or not template:IsA("Model")
        or template.Parent ~= holder
        or template:GetAttribute("OwnerVerified") ~= true
        or template:GetAttribute("CosmeticOnly") ~= true
        or template:GetAttribute("OriginalExteriorTower3D") ~= true
        or template:GetAttribute("Original3DAssetId") ~= id then
        return nil
    end
    local count = 0
    for _,part in ipairs(template:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide
                or part.CanTouch or part.CanQuery then return nil end
            count += 1
        elseif part:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count ~= 7 then return nil end
    local _,bounds = template:GetBoundingBox()
    if math.abs(bounds.X-11.84) > .40
        or math.abs(bounds.Y-(height+1.2)) > .45
        or math.abs(bounds.Z-9.84) > .40 then
        return nil
    end
    return template,holder,id
end

local function realOwner(arena,decor,base,direction,index,layer)
    local owner = decor:FindFirstChild("SkylineDepth"..direction.id..layer)
    if not owner or not owner:IsA("Model") or owner.Parent ~= decor
        or owner:GetAttribute("ChaosDistantScenery") ~= true then
        return nil
    end
    local body = owner:FindFirstChild("DistantRoofMass")
    local aerial = owner:FindFirstChild("DistantAerial")
    local variant = arena:GetAttribute("VariantId")
    local height = (variant == "Towers" and 31 or 22)
        + layer*5 + ((index+layer)%3)*3
    local x = direction.x
    local z = direction.z
    if direction.id == "North" or direction.id == "South" then
        z = z*(base.Size.Z*.5+23)
    else
        x = x*(base.Size.X*.5+23)
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
    if not body or not body:IsA("WedgePart")
        or body.Parent ~= owner
        or not body.Anchored or body.CanCollide or body.CanTouch
        or body.CanQuery or (body.Size-sourceSize).Magnitude > .12
        or (body.Position-expected.Position).Magnitude > .20
        or body.CFrame.LookVector:Dot(expected.LookVector) < .999
        or body.CFrame.UpVector:Dot(expected.UpVector) < .999
        or (math.abs(body.Transparency-original) > .035
            and body.Transparency ~= 1)
        or not aerial or not aerial:IsA("Part")
        or aerial.Parent ~= owner or not aerial.Anchored
        or aerial.CanCollide or aerial.CanTouch or aerial.CanQuery
        or (aerial.Size-Vector3.new(.38,4+layer*2,.38)).Magnitude > .08
        or (aerial.Position-
            (origin+Vector3.new(0,height+2+layer,0))).Magnitude > .20 then
        return nil
    end
    return owner,body,height,original
end

local function valid(entry)
    if entry.arena ~= activeArena
        or entry.model.Parent ~= bucket
        or entry.owner.Parent ~= entry.decor
        or entry.decor.Parent ~= entry.arena
        or entry.arena.Parent ~= workspace:FindFirstChild("GeneratedMap")
        or entry.base.Parent ~= entry.arena
        or entry.source.Parent ~= entry.holder
        or entry.holder.Parent ~= ReplicatedStorage
        or entry.body.Parent ~= entry.owner
        or entry.body.Size ~= entry.size
        or (entry.body.Position-entry.position).Magnitude > .08
        or entry.body.CFrame.LookVector:Dot(entry.look) < .999
        or not entry.body.Anchored or entry.body.CanCollide
        or entry.body.CanTouch or entry.body.CanQuery
        or #entry.pieces ~= 7 then return false end
    for _,part in ipairs(entry.pieces) do
        if not part:IsDescendantOf(entry.model) then return false end
    end
    return true
end

local function mount(arena,decor,base,owner,body,original,source,
        holder,id)
    local clone = source:Clone()
    local _,bounds = clone:GetBoundingBox()
    -- Fit height without stretching native geometry. Distant buildings
    -- may overhang their old box by up to 35% but remain outside play.
    local scale = math.min(body.Size.Y/bounds.Y,
        body.Size.X*1.35/bounds.X,body.Size.Z*2/bounds.Z)
    if scale < .80 or scale > 1.60
        or not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return
    end
    local frame,scaled = clone:GetBoundingBox()
    if scaled.Y < body.Size.Y*.80
        or scaled.Y > body.Size.Y*1.07
        or scaled.X > body.Size.X*1.37
        or scaled.Z > body.Size.Z*2.03 then
        clone:Destroy()
        return
    end
    local target = body.CFrame
        * CFrame.new(0,(scaled.Y-body.Size.Y)*.5,0)
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
        pieces=pieces,connections={},size=body.Size,
        position=body.Position,look=body.CFrame.LookVector,
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
    }) do
        entry.connections[#entry.connections+1] = signal:Connect(changed)
    end
    entry.connections[#entry.connections+1] =
        source.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then restore(owner) end
        end)
    entry.connections[#entry.connections+1] =
        clone.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then restore(owner) end
        end)
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,pressure,touch)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local spec = BUDGET[tier] or BUDGET.Low
    local stress = math.clamp(math.floor(tonumber(pressure) or 0),0,2)
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
        or arena.Parent ~= generated or not base
        or not base:IsA("BasePart") or not base.Anchored
        or not base.CanCollide or base.Size.X < 318
        or base.Size.Z < 318 or not decor
        or not decor:IsA("Folder") or decor.Parent ~= arena
        or not VARIANTS[arena:GetAttribute("VariantId")] then
        clear()
        return
    end
    local ranked = {}
    for index,direction in ipairs(DIRECTIONS) do
        for layer=1,2 do
            local owner,body,height,original =
                realOwner(arena,decor,base,direction,index,layer)
            if owner then
                local sourceHeight = height <= 30 and 27 or 30
                local source,holder,id = approved(sourceHeight)
                local held = mounted[owner] ~= nil
                local distance = (cameraPoint-body.Position).Magnitude
                if source and distance <= spec.distance
                    +(held and RETENTION or 0) then
                    ranked[#ranked+1] = {
                        owner=owner,body=body,original=original,
                        source=source,holder=holder,id=id,
                        score=distance-(held and RETENTION*.55 or 0),
                        index=(index-1)*2+layer,
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
    for owner,candidate in pairs(wanted) do
        if not mounted[owner] then
            mount(arena,decor,base,owner,candidate.body,
                candidate.original,candidate.source,candidate.holder,
                candidate.id)
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
        if valid(entry) and entry.body.Transparency == 1 then
            n += 1
        end
    end
    return n
end

return Kit
