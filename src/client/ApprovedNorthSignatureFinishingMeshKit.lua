-- Finishes the static components of the five northern monuments. Each
-- assembly has its own native fallback and approved source. The existing
-- dish, bridge, interchange, torus and crane sculpture owners are disjoint.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExteriorDetailGeometry = require("./ExteriorDetailGeometry")

local Kit = {}
local bucket = Instance.new("Folder")
bucket.Name = "ApprovedNorthSignatureFinishingLocal"
bucket:SetAttribute("CosmeticOnly",true)
bucket.Parent = workspace

local LIMITS = {
    Low={parts=8,distance=295},
    Medium={parts=16,distance=395},
    High={parts=24,distance=520},
}
local RETENTION = 20
local V = Vector3.new
local T = CFrame.new
local VERTICAL = CFrame.Angles(0,0,math.pi*.5)

local function source(holder,name,tag,id,bounds,...)
    return {holder=holder,name=name,tag=tag,id=id,bounds=bounds,pieces={...}}
end

local FOOT = source("ApprovedHarborDockCaissonTemplates","DockCaisson",
    "OriginalHarborDockCaisson3D",101457508594609,V(14.07,3.30755,14.07),
    V(12.82,2.69,12.82),V(13.54,2.95755,13.54))
local TOWER = source("ApprovedExteriorTowerTemplates","Tower21",
    "OriginalExteriorTower3D",137744886537150,V(11.84,22.2,9.84),
    V(8.96,21,7.8),V(11.84,19.47912,9.84),V(10.86,1.2275,7.85))
local BEAM = source("ApprovedOrbitalReactorLandmarkTemplates","Strut",
    "OriginalOrbitalReactorLandmark3D",138666009076890,V(8.46,1.24,1.10),
    V(8.46,1.24,1.10),V(7.96,.8638,.872))
local HOIST = source(BEAM.holder,BEAM.name,BEAM.tag,BEAM.id,BEAM.bounds,BEAM.pieces[1])
local SIGNAL = source("ApprovedPerimeterArmorTemplates","Cap",
    "OriginalPerimeterArmor3D",88962643359267,V(2.7699,2.14,2.34),
    V(2.7699,2.14,2.34),V(2.4566,.4494,1.7784))
local MAST = source("ApprovedVariantIdentitySpineTemplates","Towers",
    "OriginalVariantIdentitySpine3D",86423178125318,V(2.52,19.97562,2.52),
    V(2.29954,19.52,2.23955),V(2.52,19.92,2.52))
local CORE = source("ApprovedOrbitalReactorLandmarkTemplates","Node",
    "OriginalOrbitalReactorLandmark3D",104654294187035,V(4.36,4.36,4.36),
    V(2.96,2.9503,2.96),V(4.11,4.11,.39))

local function native(name,size,frame,kind)
    return {name=name,size=size,frame=frame,kind=kind}
end

local function assembly(key,asset,natives,frame,size,accent)
    return {key=key,asset=asset,natives=natives,frame=frame,size=size,accent=accent}
end

local function fitting(asset,name,size,frame,kind,targetSize,vertical,accent)
    return assembly(name,asset,{native(name,size,frame,kind)},
        vertical and frame*VERTICAL or frame,targetSize or size,accent)
end

local function foundation(width)
    return assembly("ForgedFoundation",FOOT,{
        native("Foundation",V(35,1.8,18),T(0,-.9,0)),
        native("InsetBase",V(31,.25,13),T(0,.16,0)),
    },T(0,-.76,0),V(width,2.16,18))
end

local profiles = {
    Classic={foundation(35)},
    Towers={foundation(38)},
    Crossroads={foundation(37)},
    Orbital={foundation(40)},
    Harbor={foundation(37)},
}
local braces = {Towers={},Crossroads={},Harbor={}}
for _,side in ipairs({-1,1}) do
    local cardinal = side == -1 and "West" or "East"
    local quay = side == -1 and "Port" or "Starboard"
    local yaw = CFrame.Angles(0,side == -1 and math.pi or 0,0)

    table.insert(profiles.Towers,assembly("ForgedLift"..cardinal,TOWER,{
        native("LiftTower"..cardinal,V(7,41,8),T(side*16,20.5,0)),
        native("TowerCrown"..cardinal,V(10,6,10),T(side*16,44,0)*yaw,"WedgePart"),
        native("TowerInlay"..cardinal,V(.22,29,1),T(side*12.4,21,-3.4)),
    },T(side*16,23.5,0),V(9.2,47,9.4)))

    table.insert(profiles.Crossroads,fitting(TOWER,"ExchangeLeg"..cardinal,
        V(5.2,34,6),T(side*16,17,0),nil,V(6.8,34,7.5)))

    local ring = side == -1 and "Left" or "Right"
    table.insert(profiles.Orbital,assembly("ForgedRingSupport"..ring,TOWER,{
        native("RingSupport"..ring,V(3.3,24,3.5),T(side*17,12,0)),
        native("RingFoot"..ring,V(7,6,8),T(side*17,3,0)*yaw,"WedgePart"),
    },T(side*17,12,0),V(6.7,24,7.2)))

    table.insert(profiles.Harbor,fitting(TOWER,"Quay"..quay.."Leg",
        V(3.3,40,3.8),T(side*16,20,0),nil,V(5,40,5.3)))

    table.insert(braces.Towers,fitting(BEAM,"TowerDiagonal"..cardinal,V(1,32,1.5),
        T(side*8,27,0)*CFrame.Angles(0,0,side*math.rad(27)),nil,V(32,1.15,1.5),true))
    table.insert(braces.Crossroads,fitting(BEAM,"SwitchBrace"..cardinal,V(1.1,22,1.4),
        T(side*8,25,-2)*CFrame.Angles(0,0,side*math.rad(32)),nil,V(22,1.2,1.4),true))
    table.insert(braces.Harbor,fitting(BEAM,"QuayRaker"..quay,V(1.2,34,1.5),
        T(side*10.5,25,0)*CFrame.Angles(0,0,side*math.rad(23)),nil,V(34,1.32,1.5),true))
end

for variant, fittings in pairs(braces) do
    for _,spec in ipairs(fittings) do table.insert(profiles[variant],spec) end
end

table.insert(profiles.Towers,fitting(SIGNAL,"HangingSignal",V(4.8,3,2),
    T(0,33.7,-3),"WedgePart",nil,false,true))
table.insert(profiles.Crossroads,fitting(SIGNAL,"Switchboard",V(7.5,4.4,.55),
    T(0,33,-3.2),nil,nil,false,true))
table.insert(profiles.Crossroads,fitting(MAST,"SignalPylon",V(1.4,16,1.5),
    T(0,45,0)))
table.insert(profiles.Crossroads,fitting(SIGNAL,"SignalCrown",V(5.6,3.4,2.8),
    T(0,54,0),"WedgePart",nil,false,true))
table.insert(profiles.Orbital,fitting(CORE,"SuspendedReactorCore",V(10,10,10),
    T(0,29,0),"Ball",V(10.7,10.7,10.7),false,true))
table.insert(profiles.Orbital,fitting(BEAM,"CoreRetainer",V(13,1.4,3),
    T(0,29,0),nil,V(13,1.4,3)))

table.insert(profiles.Harbor,fitting(FOOT,"QuayCargoStack",V(21,4.2,9),T(0,4.1,0)))
table.insert(profiles.Harbor,fitting(BEAM,"QuaySpreader",V(25,.8,1.8),T(0,23,-2.5)))
for _,side in ipairs({-1,1}) do
    local quay = side == -1 and "Port" or "Starboard"
    table.insert(profiles.Harbor,fitting(SIGNAL,"QuayWinch"..quay,V(5.4,4.2,5.5),
        T(side*10.6,44,0)))
    table.insert(profiles.Harbor,fitting(HOIST,"QuayHoist"..quay,V(.3,17,.3),
        T(side*10.6,33,-2.5),nil,V(17,.39,.39),true))
end
table.insert(profiles.Harbor,fitting(MAST,"QuayStormMast",V(1.1,11.5,1.1),T(0,51.5,0)))

local active = nil

local function disconnect(connections)
    for _,connection in ipairs(connections) do connection:Disconnect() end
end

local function watch(connections,signal,callback)
    table.insert(connections,signal:Connect(callback))
end

local function watchProperties(connections,object,properties,callback)
    for _,property in ipairs(properties) do
        watch(connections,object:GetPropertyChangedSignal(property),callback)
    end
end

local function watchAttributes(connections,object,attributes,callback)
    for _,attribute in ipairs(attributes) do
        watch(connections,object:GetAttributeChangedSignal(attribute),callback)
    end
end

local function release(state,key)
    local group = state.groups[key]
    if not group then return end
    state.groups[key] = nil
    disconnect(group.connections)
    local subscription = group.subscription
    subscription.keys[key] = nil
    if next(subscription.keys) == nil then
        disconnect(subscription.connections)
        state.sources[subscription.model] = nil
    end
    for index,part in ipairs(group.natives) do
        if part.Transparency == 1 then part.Transparency = group.alphas[index] end
    end
    group.model:Destroy()
end

local function clear()
    local state = active
    if not state then return end
    active = nil
    disconnect(state.connections)
    for _,spec in ipairs(state.profile) do release(state,spec.key) end
end

local function context(arena)
    local generated = workspace:FindFirstChild("GeneratedMap")
    if not arena or not arena:IsA("Folder") or arena.Name ~= "Arena"
        or not generated or not generated:IsA("Folder") or arena.Parent ~= generated then return nil end
    local variant = arena:GetAttribute("VariantId")
    local profile = profiles[variant]
    local base = arena:FindFirstChild("Base")
    local decor = arena:FindFirstChild("Decor")
    if not profile or not base or not base:IsA("Part") or not base.Anchored
        or not base.CanCollide or not decor or not decor:IsA("Folder") then return nil end
    local owner = decor:FindFirstChild("ArenaSignatureMegastructure")
    if not owner or not owner:IsA("Model")
        or owner.ModelStreamingMode ~= Enum.ModelStreamingMode.Atomic
        or owner:GetAttribute("ChaosDistantScenery") ~= true
        or owner:GetAttribute("SignatureVariant") ~= variant then return nil end
    local x,z = base:GetAttribute("OriginalSizeX"),base:GetAttribute("OriginalSizeZ")
    if typeof(x) ~= "number" or typeof(z) ~= "number" or x ~= x or z ~= z
        or x < 318 or z < 318 or x == math.huge or z == math.huge
        or base.Size.X > x+.2 or base.Size.Z > z+.2 then return nil end
    local origin = T(base.Position+V(x*.24,base.Size.Y*.5,-(z*.5+66)))
    local recorded = owner:GetAttribute("NorthSignatureOrigin")
    if typeof(recorded) ~= "CFrame" or (recorded.Position-origin.Position).Magnitude > .12
        or recorded.LookVector:Dot(origin.LookVector) < .999
        or recorded.UpVector:Dot(origin.UpVector) < .999 then return nil end
    return {arena=arena,base=base,owner=owner,origin=origin,profile=profile}
end

local function matchingNative(owner,origin,spec)
    local part = owner:FindFirstChild(spec.name)
    local kind = spec.kind == "WedgePart" and "WedgePart" or "Part"
    local shape = spec.kind == "Ball" and Enum.PartType.Ball or Enum.PartType.Block
    local size, pose = ExteriorDetailGeometry.monumentFootprint(part, owner, kind, shape)
    if not size or (size-spec.size).Magnitude > .10 then return nil end
    local expected = origin*spec.frame
    if (pose.Position-expected.Position).Magnitude > .15
        or pose.LookVector:Dot(expected.LookVector) < .999
        or pose.UpVector:Dot(expected.UpVector) < .999 then return nil end
    return part
end

local function horizontalSize(size)
    return V(math.max(size.X,size.Z),size.Y,math.min(size.X,size.Z))
end

local function validMesh(part)
    return part:IsA("MeshPart") and part.Anchored and not part.CanCollide
        and not part.CanTouch and not part.CanQuery and part.Transparency < 1
end

local function approved(spec)
    local holder = ReplicatedStorage:FindFirstChild(spec.holder)
    local model = holder and holder:FindFirstChild(spec.name)
    if not holder or not holder:IsA("Folder") or holder:GetAttribute("OwnerVerified") ~= true
        or not model or not model:IsA("Model") or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute(spec.tag) ~= true or model:GetAttribute("Original3DAssetId") ~= spec.id then
        return nil
    end
    local parts = model:GetChildren()
    if #parts ~= 7 then return nil end
    local frame,bounds = model:GetBoundingBox()
    if (horizontalSize(bounds)-spec.bounds).Magnitude > .27 then return nil end
    local pieces = {}
    for _,part in ipairs(parts) do
        if not validMesh(part) then return nil end
        for _,detail in ipairs(part:GetDescendants()) do
            if not detail:IsA("SurfaceAppearance") and not detail:IsA("Decal")
                and not detail:IsA("Texture") then return nil end
        end
        for index,dimensions in ipairs(spec.pieces) do
            if (horizontalSize(part.Size)-horizontalSize(dimensions)).Magnitude < .075 then
                if pieces[index] then return nil end
                pieces[index] = part
            end
        end
    end
    for index=1,#spec.pieces do if not pieces[index] then return nil end end
    return {holder=holder,model=model,frame=frame,bounds=bounds,pieces=pieces}
end

local function axisScale(axis,scale)
    if math.abs(axis.X) > .9999 then return scale.X end
    if math.abs(axis.Y) > .9999 then return scale.Y end
    if math.abs(axis.Z) > .9999 then return scale.Z end
    return nil
end

local function sculpt(asset,spec,origin,color)
    local model = Instance.new("Model")
    model.Name = spec.key
    model:SetAttribute("CosmeticOnly",true)
    model:SetAttribute("Original3DAssetId",spec.asset.id)
    local target,size = origin*spec.frame,spec.size
    if spec.asset.bounds.X > spec.asset.bounds.Z+.1 and asset.bounds.Z > asset.bounds.X then
        target *= CFrame.Angles(0,-math.pi*.5,0)
        size = V(size.Z,size.Y,size.X)
    end
    local scale = size/asset.bounds
    for index,original in ipairs(asset.pieces) do
        local pose = asset.frame:ToObjectSpace(original.CFrame)
        local x,y,z = axisScale(pose.RightVector,scale),axisScale(pose.UpVector,scale),
            axisScale(pose.LookVector,scale)
        local part = x and y and z and original:Clone()
        if not part then
            model:Destroy()
            return nil
        end
        part.Size *= V(x,y,z)
        part.CFrame = target*T(pose.Position*scale)*pose.Rotation
        part.Massless = true
        part.CastShadow = false
        part.LocalTransparencyModifier = 0
        part.Color = part.Color:Lerp(color,spec.accent and .58 or .34)
        if spec.asset == CORE and index == 1 then
            part.Material = Enum.Material.Glass
            part.Transparency = .19
        end
        part:SetAttribute("CosmeticOnly",true)
        part:SetAttribute("Original3DAssetId",spec.asset.id)
        part.Parent = model
    end
    return model
end

local MESH_GEOMETRY = {"Name","Size","CFrame","Anchored","CanCollide","CanTouch","CanQuery"}
local function subscribe(state,spec,asset)
    local binding = state.sources[asset.model]
    if binding then
        binding.keys[spec.key] = true
        return binding
    end
    local links = {}
    binding = {model=asset.model,keys={[spec.key]=true},connections=links}
    state.sources[asset.model] = binding
    local function revoke()
        if state.sources[asset.model] == binding then
            for key in pairs(binding.keys) do release(state,key) end
        end
    end
    watch(links,asset.model.AncestryChanged,revoke)
    watch(links,asset.model.DescendantAdded,revoke)
    watch(links,asset.model.DescendantRemoving,revoke)
    watchProperties(links,asset.model,{"Name","WorldPivot"},revoke)
    watchProperties(links,asset.holder,{"Name"},revoke)
    watchAttributes(links,asset.model,{"OwnerVerified","CosmeticOnly","Original3DAssetId",spec.asset.tag},revoke)
    watchAttributes(links,asset.holder,{"OwnerVerified"},revoke)
    for _,part in ipairs(asset.model:GetChildren()) do
        watchProperties(links,part,MESH_GEOMETRY,revoke)
        watchProperties(links,part,{"Transparency","MeshId","PivotOffset"},revoke)
    end
    return binding
end

local function mount(state,spec,asset)
    local natives,alphas = {},{}
    for index,n in ipairs(spec.natives) do
        local part = matchingNative(state.owner,state.origin,n)
        if not part or part.Transparency >= 1 then return nil end
        natives[index],alphas[index] = part,part.Transparency
    end
    local model = sculpt(asset,spec,state.origin,natives[1].Color)
    if not model then return nil end
    local links = {}
    local group = {model=model,natives=natives,alphas=alphas,
        count=#asset.pieces,connections=links}
    local function revoke()
        if state.groups[spec.key] == group then release(state,spec.key) end
    end
    model.Parent = bucket
    state.groups[spec.key] = group
    for _,part in ipairs(natives) do
        part.Transparency = 1
        watch(links,part.AncestryChanged,revoke)
        watchProperties(links,part,MESH_GEOMETRY,revoke)
        watchProperties(links,part,{"Color","Transparency"},revoke)
        if part:IsA("Part") then
            watchProperties(links,part,{"Shape"},revoke)
        elseif part:IsA("MeshPart") then
            watchProperties(links,part,{"MeshId"},revoke)
            watchAttributes(links,part,
                {"OriginalExteriorDetail3D","Original3DAssetId","ExteriorDetailAxisSwap"},revoke)
        end
    end
    watch(links,model.AncestryChanged,revoke)
    watch(links,model.ChildRemoved,revoke)
    group.subscription = subscribe(state,spec,asset)
    for _,part in ipairs(model:GetChildren()) do
        watchProperties(links,part,{"MeshId","Transparency"},revoke)
    end
    return group
end

local function start(state)
    active = state
    state.groups,state.connections,state.sources = {},{},{}
    local function revoke()
        if active == state then clear() end
    end
    local function checkContext()
        local current = context(state.arena)
        if not current or current.origin ~= state.origin
            or current.owner ~= state.owner or current.base ~= state.base then revoke() end
    end
    watch(state.connections,state.owner.AncestryChanged,revoke)
    watch(state.connections,state.base.AncestryChanged,revoke)
    watchProperties(state.connections,state.owner,{"Name","ModelStreamingMode"},revoke)
    watchAttributes(state.connections,state.owner,{"NorthSignatureOrigin","ChaosDistantScenery","SignatureVariant"},revoke)
    watchAttributes(state.connections,state.arena,{"VariantId"},revoke)
    watchAttributes(state.connections,state.base,{"OriginalSizeX","OriginalSizeZ"},revoke)
    watchProperties(state.connections,state.base,{"Name","CFrame","Size","Anchored","CanCollide"},checkContext)
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,pressure)
    local limit = LIMITS[tier]
    if not limit or not cameraReady or typeof(cameraPoint) ~= "Vector3"
        or (tonumber(pressure) or 0) >= 1 then
        clear()
        return
    end
    local current = context(arena)
    if active and (not current or active.owner ~= current.owner
        or active.origin ~= current.origin or active.base ~= current.base) then clear() end
    if not current or (cameraPoint-current.origin.Position).Magnitude
        > limit.distance+(active and RETENTION or 0) then clear();return end
    if not active then start(current) end
    local spent,assets = 0,{}
    for _,spec in ipairs(active.profile) do
        local group = active.groups[spec.key]
        local count = #spec.asset.pieces
        if spent+count > limit.parts then
            release(active,spec.key)
        else
            if not group then
                local asset = assets[spec.asset]
                if asset == nil then
                    asset = approved(spec.asset) or false
                    assets[spec.asset] = asset
                end
                if asset then group = mount(active,spec,asset) end
            end
            if group then spent += group.count end
        end
    end
end

function Kit.replacedNativeCount()
    local count = 0
    for _,group in pairs(active and active.groups or {}) do count += #group.natives end
    return count
end

function Kit.count()
    local count = 0
    for _,group in pairs(active and active.groups or {}) do count += group.count end
    return count
end

return Kit
