-- The six Orbital Ring spheres can be replaced by two GENUINE,
-- previously owner-approved seven-MeshPart original sculptures.
-- Only existing server-replicated templates are used. No new asset,
-- collider, light, RemoteEvent, physics simulation or update loop.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:FindFirstChild("Shared")
local spatial = shared and shared:FindFirstChild("SpatialMidgroundSelectionRules")
local SpatialMidgroundSelectionRules = if spatial then require(spatial)
    else require("../shared/SpatialMidgroundSelectionRules")
local Kit = {}

local PROFILES = {
    Satellite = {
        folder = "ApprovedAmbientMotionTemplates",
        flag = "ApprovedAmbientMotion3D",
        id = 127850230318627, min = .5, max = 8.0,
    },
    Containment = {
        folder = "ApprovedServiceEquipmentTemplates",
        flag = "OriginalService3D",
        id = 127295681925871, min = .65, max = 6.0,
    },
}
local BUDGET = {
    Low = {count=1, distance=290, hysteresis=25},
    Medium = {count=3, distance=345, hysteresis=34},
    High = {count=6, distance=430, hysteresis=46},
}

local holder = Instance.new("Folder")
holder.Name = "OriginalOrbitalStationsLocal"
holder:SetAttribute("CosmeticOnly", true)
holder.Parent = workspace

local activeArena = nil
local mounted = {}

local function profileAt(index)
    return index%2 == 1 and "Satellite" or "Containment"
end

local function template(kind)
    local spec = PROFILES[kind]
    if not spec then return nil end
    local parent = ReplicatedStorage:FindFirstChild(spec.folder)
    if not parent or not parent:IsA("Folder")
        or parent.Parent ~= ReplicatedStorage
        or parent:GetAttribute("OwnerVerified") ~= true then return nil end
    local source = parent:FindFirstChild("Orbital")
    if not source or not source:IsA("Model") or source.Parent ~= parent
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute(spec.flag) ~= true
        or source:GetAttribute("Original3DAssetId") ~= spec.id then
        return nil
    end
    local count = 0
    for _, part in ipairs(source:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") or part.CanCollide or part.CanTouch
                or part.CanQuery then return nil end
            count += 1
        elseif part:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count ~= 7 then return nil end
    local _, bounds = source:GetBoundingBox()
    if math.min(bounds.X,bounds.Y,bounds.Z) < spec.min
        or math.max(bounds.X,bounds.Y,bounds.Z) > spec.max then
        return nil
    end
    return source
end

local function arenaParts(arena)
    if not arena or not arena:IsA("Folder")
        or arena:GetAttribute("VariantId") ~= "Orbital" then return nil end
    local map = workspace:FindFirstChild("GeneratedMap")
    if not map or arena.Parent ~= map then return nil end
    local base = arena:FindFirstChild("Base")
    local mid = workspace:FindFirstChild("ArenaMidgroundMassLocal")
    if not base or not base:IsA("BasePart") or not base.Anchored
        or base.Size.X < 160 or base.Size.Z < 160
        or not mid or not mid:IsA("Folder") or mid.Parent ~= workspace then
        return nil
    end
    return base, mid
end

local function station(body, base, mid, index)
    if not body or not body:IsA("Part") or body.Parent ~= mid
        or body.Name ~= "OrbitalStationMass"..index
        or body.Shape ~= Enum.PartType.Ball
        or body:GetAttribute("OriginalOrbitalStationIndex") ~= index
        or not body.Anchored or body.CanCollide or body.CanTouch
        or body.CanQuery then return false end
    local expected = 8 + (index%3)*2
    if math.abs(body.Size.X-expected) > .15
        or math.abs(body.Size.Y-expected) > .15
        or math.abs(body.Size.Z-expected) > .15 then return false end
    local localPos = base.CFrame:PointToObjectSpace(body.Position)
    local marginX = math.abs(localPos.X)-base.Size.X*.5
    local marginZ = math.abs(localPos.Z)-base.Size.Z*.5
    return math.max(marginX,marginZ) >= expected*1.15+4
end

local function isValid(e)
    if not e or e.model.Parent ~= holder or e.arena ~= activeArena
        or e.arena.Parent ~= workspace:FindFirstChild("GeneratedMap")
        or e.base.Parent ~= e.arena or e.mid.Parent ~= workspace
        or e.source.Parent ~= e.sourceFolder
        or e.sourceFolder.Parent ~= ReplicatedStorage
        or not station(e.body,e.base,e.mid,e.index)
        or (e.body.Position-e.position).Magnitude > .15
        or e.body.CFrame.LookVector:Dot(e.look) < .999
        or #e.pieces ~= 7 then return false end
    for _, part in ipairs(e.pieces) do
        if not part or not part:IsDescendantOf(e.model) then return false end
    end
    return true
end

local function visibility(e)
    local show = isValid(e)
    for _, part in ipairs(e.pieces) do
        if part.Parent then part.LocalTransparencyModifier = show and 0 or 1 end
    end
    for part, alpha in pairs(e.original) do
        if part.Parent == e.mid
            and part:GetAttribute("OriginalOrbitalStationIndex") == e.index then
            if show then
                part.Transparency = 1
            elseif part.Transparency == 1 then
                part.Transparency = alpha
            end
        end
    end
    return show
end

local function remove(e)
    for _, signal in ipairs(e.connections) do signal:Disconnect() end
    -- Restore ORIGINAL art before destroying the approved 3D clone.
    for part, alpha in pairs(e.original) do
        if part.Parent == e.mid and part.Transparency == 1
            and part:GetAttribute("OriginalOrbitalStationIndex") == e.index then
            part.Transparency = alpha
        end
    end
    e.model:Destroy()
end

local function clear()
    for body, e in pairs(mounted) do
        remove(e)
        mounted[body] = nil
    end
end

local function mount(arena,base,mid,body,index,approved,kind)
    if not station(body,base,mid,index) then return nil end
    local clone = approved:Clone()
    local _, natural = clone:GetBoundingBox()
    local maxSpan = kind == "Satellite"
        and body.Size.X*1.24 or body.Size.X*1.08
    local scale = math.min(3.2,
        maxSpan/math.max(natural.X,natural.Z),
        body.Size.Y*1.22/natural.Y)
    if scale < .75 or not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return nil
    end
    local frame, bounds = clone:GetBoundingBox()
    if bounds.X > body.Size.X*1.27
        or bounds.Z > body.Size.X*1.27
        or bounds.Y > body.Size.Y*1.24
        or math.min(bounds.X,bounds.Z) < 1.5
        or bounds.Y < 2.5 then
        clone:Destroy()
        return nil
    end
    local localPos = base.CFrame:PointToObjectSpace(body.Position)
    -- Conservative rotated AABB: the COMPLETE sculpture stays outside
    -- the collision-authoritative square, not just its center.
    local reach = math.max(bounds.X,bounds.Z)*.7072
    if math.max(
        math.abs(localPos.X)-base.Size.X*.5,
        math.abs(localPos.Z)-base.Size.Z*.5
    ) < reach+3 then
        clone:Destroy()
        return nil
    end
    local target = body.CFrame*CFrame.Angles(0,math.rad((index-1)*43),0)
    local pieces = {}
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then clone:Destroy();return nil end
            part.CFrame = target*frame:ToObjectSpace(part.CFrame)
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part:SetAttribute("Original3DAssetId",PROFILES[kind].id)
            part:SetAttribute("OriginalOrbitalStation3D",true)
            pieces[#pieces+1] = part
        end
    end
    if #pieces ~= 7 then clone:Destroy();return nil end
    local native, count = {}, 0
    for _, part in ipairs(mid:GetChildren()) do
        if part:IsA("BasePart")
            and part:GetAttribute("OriginalOrbitalStationIndex") == index then
            if not part.Anchored or part.CanCollide or part.CanTouch
                or part.CanQuery then clone:Destroy();return nil end
            native[part] = part.Transparency
            count += 1
        end
    end
    -- Low constructs body + one real native motif.
    if count < 2 or native[body] == nil then
        clone:Destroy();return nil
    end
    clone.Name = "ApprovedOriginalOrbital_"..kind.."_"..index
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("OriginalOrbitalStation3D",true)
    clone:SetAttribute("Original3DAssetId",PROFILES[kind].id)
    clone:SetAttribute("OriginalOrbitalStationIndex",index)
    clone.Parent = holder
    local e={
        arena=arena,base=base,mid=mid,body=body,index=index,
        model=clone,source=approved,sourceFolder=approved.Parent,
        position=body.Position,look=body.CFrame.LookVector,
        pieces=pieces,original=native,connections={},
    }
    local function changed()
        if not isValid(e) then visibility(e) end
    end
    e.connections[#e.connections+1]=body.AncestryChanged:Connect(changed)
    e.connections[#e.connections+1]=body:GetPropertyChangedSignal("Size"):Connect(changed)
    e.connections[#e.connections+1]=body:GetPropertyChangedSignal("CFrame"):Connect(changed)
    e.connections[#e.connections+1]=base:GetPropertyChangedSignal("Size"):Connect(changed)
    e.connections[#e.connections+1]=base:GetPropertyChangedSignal("CFrame"):Connect(changed)
    e.connections[#e.connections+1]=mid.AncestryChanged:Connect(changed)
    e.connections[#e.connections+1]=approved.AncestryChanged:Connect(changed)
    e.connections[#e.connections+1]=clone.DescendantRemoving:Connect(function(p)
        if p:IsA("MeshPart") then task.defer(visibility,e) end
    end)
    if not visibility(e) then remove(e);return nil end
    return e
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,cameraLook,pressure)
    if arena ~= activeArena then clear();activeArena=arena end
    local budget = BUDGET[tier] or BUDGET.Low
    local stress = math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    local cap = budget.count
    if tier == "Low" then
        cap = stress==0 and 1 or 0
    elseif tier == "Medium" then
        cap = stress==0 and 3 or (stress==1 and 1 or 0)
    elseif tier == "High" then
        cap = stress==0 and 6 or (stress==1 and 3 or 0)
    end
    local base, mid = arenaParts(arena)
    if not base or not cameraReady or cap == 0
        or typeof(cameraPoint) ~= "Vector3" then clear();return end
    local candidates = {}
    for index=1,6 do
        local body = mid:FindFirstChild("OrbitalStationMass"..index)
        local kind = profileAt(index)
        local approved = template(kind)
        if approved and station(body,base,mid,index) then
            local distance=(body.Position-cameraPoint).Magnitude
            local resident=mounted[body]~=nil
            if distance<=budget.distance+
                (resident and budget.hysteresis or 0) then
                local score=distance-
                    (resident and budget.hysteresis*.6 or 0)
                if typeof(cameraLook)=="Vector3"
                    and cameraLook.Magnitude>.5 and distance>45 then
                    local direction=(body.Position-cameraPoint).Unit
                    score-=math.min(42,distance*.16)*direction:Dot(cameraLook.Unit)
                end
                candidates[#candidates+1]={
                    body=body,index=index,source=approved,kind=kind,score=score}
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.score==b.score then return a.index<b.index end
        return a.score<b.score
    end)
    -- Closest authentic orbital sculpture remains foreground;
    -- extra SAME-budget slots spread around the real station ring.
    -- Never fabricate a new walkable structure or increase 1/3/6 caps.
    local wanted=SpatialMidgroundSelectionRules.choose(candidates,cap)
    for body,e in pairs(mounted) do
        local want=wanted[body]
        if not want or want.source~=e.source or not isValid(e) then
            remove(e)
            mounted[body]=nil
        else
            visibility(e)
        end
    end
    for body,want in pairs(wanted) do
        if not mounted[body] then
            mounted[body]=mount(arena,base,mid,body,want.index,
                want.source,want.kind)
        end
    end
end

function Kit.count()
    local n=0
    for _,e in pairs(mounted) do
        if isValid(e) then n+=1 end
    end
    return n
end

function Kit.replacedNativeCount()
    local n=0
    for _,e in pairs(mounted) do
        if isValid(e) then
            for p in pairs(e.original) do
                if p.Parent==e.mid and p.Transparency==1 then n+=1 end
            end
        end
    end
    return n
end

return Kit
