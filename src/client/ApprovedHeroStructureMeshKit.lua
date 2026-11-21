-- Arena-specific hero bodies, foundations and fittings use the same scenery
-- sampler. Replicated owner-approved templates are the only mesh sources.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:FindFirstChild("Shared")
local horizonModule = shared and shared:FindFirstChild("HorizonMonumentGeometry")
local HorizonMonumentGeometry = if horizonModule then require(horizonModule)
    else require("../shared/HorizonMonumentGeometry")

local FALLBACK_ASSETS = {
    [HorizonMonumentGeometry.assetId("bevel")] = true,
    [HorizonMonumentGeometry.assetId("beam")] = true,
    [HorizonMonumentGeometry.assetId("lens")] = true,
}
local Kit = {}

-- Model package IDs from assets/source/roblox-asset-registry.json.
-- These are NOT MeshPart.MeshId strings; verify the server's source identity.
local PROFILE = {
    Towers = {name = "sky_transit_exchange", id = 95878714550124,
        majorMin = 27, majorMax = 39, minorMin = 12, minorMax = 21,
        heightMin = 23, heightMax = 35},
    Crossroads = {name = "plasma_foundry", id = 95926792159328,
        majorMin = 25, majorMax = 37, minorMin = 11, minorMax = 20,
        heightMin = 23, heightMax = 35},
    Orbital = {name = "orbital_halo_array", id = 135985134195364,
        majorMin = 19, majorMax = 29, minorMin = 9, minorMax = 17,
        heightMin = 25, heightMax = 37},
}

local CLASSIC = {holder="ApprovedClassicSignatureObservatoryTemplates",
    name="DualDishObservatory", id=112493873850364, tag="OriginalClassicDualDishObservatory3D",
    bounds=Vector3.new(9.105,15.0875,1.03), pieces={
        Vector3.new(1.71,15.0875,1.03),Vector3.new(9.105,12.085,.6975),
        Vector3.new(9.07,5.1625,.7338),Vector3.new(6.6175,13.8531,.4594),
        Vector3.new(8.9772,14.1883,.7155)}}
local HARBOR = {holder="ApprovedSouthHarborDrydockTemplates",name="SculptedDrydock",
    id=125428569657840,tag="OriginalSouthHarborSculptedDrydock3D",
    bounds=Vector3.new(16.53571,18.36429,4.60071),pieces={
        Vector3.new(16.5357,18.3643,4.4107),Vector3.new(15.215,17.9729,4.6007),
        Vector3.new(14.6429,17.1089,3.2214)}}
local CROSSROADS = {holder="ApprovedCrossroadsSignatureInterchangeTemplates",
    name="ForgedInterchange",id=96622579843060,tag="OriginalCrossroadsSignatureInterchange3D",
    bounds=Vector3.new(47.68,11.73404,6.76),pieces={
        Vector3.new(45.04,11.12,5.9),Vector3.new(47.68,2.3458,5.3),
        Vector3.new(46.409,9.4952,5.244)}}
local MAST = {holder="ApprovedVariantIdentitySpineTemplates",name="Towers",
    id=86423178125318,tag="OriginalVariantIdentitySpine3D",
    bounds=Vector3.new(2.52,19.97562,2.52),pieces={
        Vector3.new(2.52,19.92,2.52),Vector3.new(2.29954,19.52,2.23955)}}
local VANE = {holder="ApprovedOrbitalReactorLandmarkTemplates",name="Strut",
    id=138666009076890,tag="OriginalOrbitalReactorLandmark3D",
    bounds=Vector3.new(8.46,1.24,1.10),pieces={
        Vector3.new(8.46,1.24,1.10),Vector3.new(7.96,.8638,.872)}}
local LENS = {holder=VANE.holder,name="Node",id=104654294187035,
    tag=VANE.tag,bounds=Vector3.new(4.36,4.36,4.36),pieces={
        Vector3.new(2.96,2.9503,2.96),Vector3.new(4.11,4.11,.39)}}
local FOOT = {holder="ApprovedHarborDockCaissonTemplates",name="DockCaisson",
    id=101457508594609,tag="OriginalHarborDockCaisson3D",
    bounds=Vector3.new(14.07,3.30755,14.07),pieces={
        Vector3.new(12.82,2.69,12.82),Vector3.new(13.54,2.95755,13.54)}}

local MAIN_PROFILE = {
    Classic = {premium=CLASSIC,size=Vector3.new(21.8,38,4.3)},
    Towers = {size=Vector3.new(31,26.25,14.7)},
    Crossroads = {size=Vector3.new(24.3,23.2,13.5)},
    Orbital = {size=Vector3.new(26,35.4,14)},
    Harbor = {premium=HARBOR,size=Vector3.new(31.6,32,13.2)},
}
-- Mounts fit the authored outboard safety line after the room-facing yaw.
local FOOT_NAME = {Classic="ObservatoryFoundation",Towers="TransitFoundation",
    Crossroads="SwitchyardFoundation",Orbital="MagneticPlatform",Harbor="HarborDrydockFoundation"}
local FITTING_NAMES = {
    Towers={"SkyTransitSignalCrown","SkyTransitWeatherVane"},
    Crossroads={"NorthConduit","EastConduit","ExchangeCoupler1","ExchangeCoupler2",
        "ExchangeCoupler3","ExchangeCoupler4","DataTower","RoutingHeadHousing",
        "SwitchAntenna-1","SwitchAntenna1","RoutingSwitchFin-1","RoutingSwitchFin1"},
    Orbital={"HaloLens"},
}

-- Only one landmark is mounted. The base and fittings are pressure-limited.
local DISTANCE = {Low = 242, Medium = 275, High = 370}
local RETENTION = 24

local bucket = Instance.new("Folder")
bucket.Name = "ApprovedOriginalHeroStructuresLocal"
bucket.Parent = workspace

local activeArena = nil
local mounted = nil
local watchedBase = nil
local baseConnection = nil

local function restore(parts)
    for part, alpha in pairs(parts) do
        if part.Transparency == 1 then part.Transparency = alpha end
    end
    table.clear(parts)
end

local function releaseDetail(entry,key)
    local detail = entry[key]
    if not detail then return end
    entry[key] = nil
    for _,connection in ipairs(detail.connections) do connection:Disconnect() end
    restore(detail.replaced)
    detail.model:Destroy()
end

-- The hero lives OUTSIDE the unchanged original arena. The playable
-- Base shrinks during survival; authenticate its immutable footprint
-- rather than dropping verified skyline art mid-round.
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

local function restoreNative(entry)
    restore(entry.replaced)
end

local function dispose()
    if not mounted then return end
    local entry = mounted
    mounted = nil
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    releaseDetail(entry,"foundation")
    releaseDetail(entry,"fittings")
    restoreNative(entry)
    entry.model:Destroy()
end

local function clear()
    dispose()
    if baseConnection then baseConnection:Disconnect() end
    baseConnection = nil
    watchedBase = nil
    activeArena = nil
    bucket:ClearAllChildren()
end

local function verifiedTemplate(variant)
    local profile = PROFILE[variant]
    if not profile then return nil end
    local holder = ReplicatedStorage:FindFirstChild("ApprovedHeroStructureTemplates")
    if not holder or not holder:IsA("Folder") or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local model = holder:FindFirstChild(profile.name)
    if not model or not model:IsA("Model") or model.Parent ~= holder
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("ApprovedHero3D") ~= true
        or model:GetAttribute("Original3DAssetId") ~= profile.id then
        return nil
    end
    local count = 0
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item:IsA("MeshPart") or not item.Anchored or item.CanCollide
                or item.CanTouch or item.CanQuery then return nil end
            count += 1
        elseif item:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 24 then return nil end
    local _, size = model:GetBoundingBox()
    local major = math.max(size.X, size.Z)
    local minor = math.min(size.X, size.Z)
    if major < profile.majorMin or major > profile.majorMax
        or minor < profile.minorMin or minor > profile.minorMax
        or size.Y < profile.heightMin or size.Y > profile.heightMax then
        return nil
    end
    return model
end

local function authenticGeometry(part, shaftAsset, variant)
    if not part:IsA("MeshPart") then return part:IsA("Part") end
    local assetId = part:GetAttribute("Original3DAssetId")
    if part.MeshId == "" or assetId == nil then return false end
    if FALLBACK_ASSETS[assetId] == true or assetId == shaftAsset then return true end
    if variant ~= "Harbor" then return false end
    local name = part.Name
    if assetId == FOOT.id then return name == FOOT_NAME.Harbor or name == "CargoHull" end
    local shaft = name == "SignalTower" or name == "HangingCable"
        or name:match("^GantryPylon%-?1$") or name:match("^DiagonalDockBrace%-?1$")
    return HorizonMonumentGeometry.matchesHarborStructuralFallback(assetId, shaft and "shaft" or "bevel")
        or assetId == HorizonMonumentGeometry.assetId("cast")
end

local function nativeOrigin(arena, base, variant)
    local originalX,originalZ = authenticFootprint(base, arena)
    if not originalX then return nil end
    if arena.Name ~= "Arena" or arena.Parent ~= workspace:FindFirstChild("GeneratedMap") then
        return nil
    end
    local decor = arena:FindFirstChild("Decor")
    local native = decor and decor:FindFirstChild("ArenaHeroArchitecture3D")
    if not native or not native:IsA("Model") or native.Parent ~= decor
        or native:GetAttribute("ChaosDistantScenery") ~= true
        or native:GetAttribute("SourceIsOriginal") ~= true
        or native:GetAttribute("SignatureVariant") ~= variant then
        return nil
    end
    local shaftAsset = HorizonMonumentGeometry.assetId("shaft", variant)
    local count = 0
    for _, item in ipairs(native:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item.Anchored or item.CanCollide or item.CanTouch
                or item.CanQuery or not authenticGeometry(item, shaftAsset, variant) then
                return nil
            end
            count += 1
        elseif item:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 8 or count > 125 then return nil end
    if native:GetAttribute("HeroArchitectureParts") ~= count then return nil end
    local frame, size = native:GetBoundingBox()
    if size.X <= 0 or size.Y < 12 or size.Z <= 0
        or size.X > 65 or size.Y > 65 or size.Z > 65 then
        return nil
    end
    -- The entire hero must sit well OUTSIDE the playable 320-stud floor.
    -- Even a 42-stud imported package then cannot create a ghost safe route.
    if frame.Position.X - base.Position.X
        < originalX * .5 + size.X * .5 + 15 then
        return nil
    end
    local origin = CFrame.new(base.Position+Vector3.new(
        originalX*.5+68,base.Size.Y*.5,originalZ*.22))
    local signed = native:GetAttribute("HeroOrigin")
    if typeof(signed) ~= "CFrame" or (signed.Position-origin.Position).Magnitude > .08
        or signed.LookVector:Dot(origin.LookVector) < .999
        or signed.UpVector:Dot(origin.UpVector) < .999 then return nil end
    return native, frame, size, origin
end

local function sortedSize(size)
    return Vector3.new(math.max(size.X,size.Z),size.Y,math.min(size.X,size.Z))
end

local function checkedAsset(spec)
    local holder = ReplicatedStorage:FindFirstChild(spec.holder)
    local source = holder and holder:FindFirstChild(spec.name)
    if not holder or not holder:IsA("Folder") or holder.Parent ~= ReplicatedStorage
        or holder:GetAttribute("OwnerVerified") ~= true or not source or not source:IsA("Model")
        or source:GetAttribute("OwnerVerified") ~= true or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute(spec.tag) ~= true or source:GetAttribute("Original3DAssetId") ~= spec.id then
        return nil
    end
    local children = source:GetChildren()
    if #children ~= 7 then return nil end
    local frame,bounds = source:GetBoundingBox()
    if (sortedSize(bounds)-spec.bounds).Magnitude > .47 then return nil end
    local pieces = {}
    for _,piece in ipairs(children) do
        if not piece:IsA("MeshPart") or not piece.Anchored or piece.CanCollide
            or piece.CanTouch or piece.CanQuery or piece.Transparency >= 1 then return nil end
        for _,detail in ipairs(piece:GetDescendants()) do
            if not detail:IsA("SurfaceAppearance") and not detail:IsA("Decal")
                and not detail:IsA("Texture") then return nil end
        end
        for index,size in ipairs(spec.pieces) do
            if (sortedSize(piece.Size)-sortedSize(size)).Magnitude < .08 then
                if pieces[index] then return nil end
                pieces[index] = piece
            end
        end
    end
    for index=1,#spec.pieces do if not pieces[index] then return nil end end
    return {model=source,holder=holder,pieces=pieces,frame=frame,bounds=bounds,spec=spec}
end

local function legacyAsset(variant)
    local model = verifiedTemplate(variant)
    if not model then return nil end
    local frame,bounds = model:GetBoundingBox()
    local pieces = {}
    for _,piece in ipairs(model:GetDescendants()) do
        if piece:IsA("MeshPart") then pieces[#pieces+1] = piece end
    end
    return {model=model,holder=model.Parent,pieces=pieces,frame=frame,bounds=bounds,
        spec={id=PROFILE[variant].id,tag="ApprovedHero3D"}}
end

local function axisScale(axis,scale)
    if math.abs(axis.X) > .9999 then return scale.X end
    if math.abs(axis.Y) > .9999 then return scale.Y end
    if math.abs(axis.Z) > .9999 then return scale.Z end
    return nil
end

local function inwardYaw(asset)
    local swapped = asset.bounds.Z > asset.bounds.X + .12
    local yaw = swapped and -math.pi*.5 or 0
    -- The Classic receiver faces the SIGNAL material's signed depth.
    -- Recover its direction even when Roblox swaps the horizontal axes.
    if asset.spec == CLASSIC then
        local signal = asset.frame:PointToObjectSpace(asset.pieces[4].Position)
        if (swapped and signal.X or signal.Z) > 0 then yaw += math.pi end
    end
    return yaw
end

local function sculpt(parent,asset,frame,size,color)
    local swapped = asset.bounds.Z > asset.bounds.X + .12
    frame *= CFrame.Angles(0,inwardYaw(asset),0)
    if swapped then size = Vector3.new(size.Z,size.Y,size.X) end
    local scale = size/asset.bounds
    for _,original in ipairs(asset.pieces) do
        local relative = asset.frame:ToObjectSpace(original.CFrame)
        local x,y,z = axisScale(relative.RightVector,scale),axisScale(relative.UpVector,scale),
            axisScale(relative.LookVector,scale)
        if not x or not y or not z then return false end
        local mesh = original:Clone()
        if not mesh then return false end
        mesh.Size *= Vector3.new(x,y,z)
        mesh.CFrame = frame*CFrame.new(relative.Position*scale)*relative.Rotation
        mesh.Anchored = true
        mesh.Massless = true
        mesh.CanCollide = false
        mesh.CanTouch = false
        mesh.CanQuery = false
        mesh.CastShadow = false
        mesh.LocalTransparencyModifier = 0
        mesh.Color = mesh.Color:Lerp(color,.24)
        mesh:SetAttribute("Original3DAssetId",asset.spec.id)
        mesh.Parent = parent
    end
    return true
end

local function maskPart(replaced,part)
    if part.Transparency < 1 then
        replaced[part] = part.Transparency
        part.Transparency = 1
    end
end

local function watchAsset(connections,asset,revoke)
    local function watch(signal) connections[#connections+1] = signal:Connect(revoke) end
    watch(asset.model.AncestryChanged)
    watch(asset.model.ChildAdded)
    watch(asset.model.ChildRemoved)
    watch(asset.model:GetPropertyChangedSignal("Name"))
    watch(asset.holder:GetPropertyChangedSignal("Name"))
    watch(asset.holder:GetAttributeChangedSignal("OwnerVerified"))
    for _,name in ipairs({"OwnerVerified","CosmeticOnly","Original3DAssetId",asset.spec.tag}) do
        watch(asset.model:GetAttributeChangedSignal(name))
    end
    for _,part in ipairs(asset.pieces) do
        for _,property in ipairs({"MeshId","Size","CFrame","Anchored","CanCollide","CanTouch","CanQuery"}) do
            watch(part:GetPropertyChangedSignal(property))
        end
    end
end

local function ownedParts(native,names)
    local parts = {}
    for _,name in ipairs(names) do
        local part = native:FindFirstChild(name)
        if not part or not part:IsA("BasePart") or not part.Anchored
            or part.CanCollide or part.CanTouch or part.CanQuery then return nil end
        parts[#parts+1] = part
    end
    return parts
end

local function watchNativeMesh(part, watch)
    if part:IsA("MeshPart") then
        watch(part:GetPropertyChangedSignal("MeshId"))
        watch(part:GetAttributeChangedSignal("Original3DAssetId"))
    end
end

local function maskMain(entry)
    for _,part in ipairs(entry.natives) do maskPart(entry.replaced,part) end
end

local function valid(entry,base,arena,variant)
    if not authenticFootprint(base, arena) or entry.variant ~= variant
        or entry.model.Parent ~= bucket or entry.native.Parent ~= entry.decor
        or entry.source.model.Parent ~= entry.source.holder
        or entry.source.holder.Parent ~= ReplicatedStorage then return false end
    local native,frame,size,origin = nativeOrigin(arena,base,variant)
    return native == entry.native and frame ~= nil
        and (frame.Position-entry.nativeFrame.Position).Magnitude < .12
        and (size-entry.nativeSize).Magnitude < .12
        and (origin.Position-entry.origin.Position).Magnitude < .08
end

local function mount(arena,base,decor,native,frame,size,origin,variant,asset)
    local profile = MAIN_PROFILE[variant]
    local names = FITTING_NAMES[variant]
    local excluded = {[FOOT_NAME[variant]]=true}
    for _,name in ipairs(names or {}) do excluded[name] = true end
    local foundation = native:FindFirstChild(FOOT_NAME[variant])
    if not foundation or not foundation:IsA("BasePart") then return nil end
    local bodyParts = {}
    for _,part in ipairs(native:GetChildren()) do
        if part:IsA("BasePart") and not excluded[part.Name] then bodyParts[#bodyParts+1] = part end
    end
    local clone = Instance.new("Model")
    clone.Name = "ApprovedOriginalHero3D_"..variant
    clone:SetAttribute("CosmeticOnly",true)
    clone:SetAttribute("ApprovedHero3D",true)
    clone:SetAttribute("Original3DAssetId",asset.spec.id)
    clone:SetAttribute("SignatureVariant",variant)
    -- These monuments sit east of the arena. Face the dish, halo and
    -- fitted towers toward the players. Crossroads keeps its two conduits.
    local yaw = variant == "Crossroads" and 0 or math.pi*.5
    local target = origin*CFrame.new(0,foundation.Size.Y-.08+profile.size.Y*.5,0)
        *CFrame.Angles(0,yaw,0)
    local eastWidth = yaw == 0 and profile.size.X or profile.size.Z
    if target.Position.X-eastWidth*.5 < base.Position.X+base:GetAttribute("OriginalSizeX")*.5+15 then
        clone:Destroy()
        return nil
    end
    if not sculpt(clone,asset,target,profile.size,foundation.Color) then
        clone:Destroy()
        return nil
    end
    local pieces = {}
    for _,piece in ipairs(clone:GetChildren()) do pieces[piece] = true end
    clone.Parent = bucket
    local entry = {model=clone,native=native,decor=decor,variant=variant,source=asset,
        nativeFrame=frame,nativeSize=size,origin=origin,natives=bodyParts,replaced={},connections={},
        bodyTop=target.Position.Y+profile.size.Y*.5,bodyYaw=yaw}
    mounted = entry
    local function revoke()
        if mounted == entry then dispose() end
    end
    watchAsset(entry.connections,asset,revoke)
    local function watch(signal,handler)
        table.insert(entry.connections,signal:Connect(handler or revoke))
    end
    watch(clone.AncestryChanged,function() if clone.Parent ~= bucket then revoke() end end)
    watch(clone.DescendantRemoving,function(mesh) if pieces[mesh] then revoke() end end)
    watch(native.AncestryChanged)
    watch(native.ChildAdded)
    watch(native.ChildRemoved)
    watch(native:GetAttributeChangedSignal("HeroOrigin"))
    watch(native:GetAttributeChangedSignal("SignatureVariant"))
    watch(base.AncestryChanged)
    watch(base:GetPropertyChangedSignal("CFrame"))
    watch(base:GetPropertyChangedSignal("CanCollide"))
    watch(base:GetPropertyChangedSignal("Anchored"))
    for _,part in ipairs(bodyParts) do
        watchNativeMesh(part, watch)
        for _,property in ipairs({"Name","CFrame","Size","CanCollide","CanTouch","CanQuery","Anchored"}) do
            watch(part:GetPropertyChangedSignal(property))
        end
    end
    watchNativeMesh(foundation, watch)
    for _,name in ipairs({"CFrame","Size","Anchored","CanCollide","CanTouch","CanQuery"}) do
        watch(foundation:GetPropertyChangedSignal(name))
    end
    maskMain(entry)
    return entry
end

local function fittingAssets(variant)
    if variant == "Towers" then
        local mast,vane = checkedAsset(MAST),checkedAsset(VANE)
        if mast and vane then return {mast,vane} end
    elseif variant == "Crossroads" then
        local bridge,mast = checkedAsset(CROSSROADS),checkedAsset(MAST)
        if bridge and mast then return {bridge,mast} end
    elseif variant == "Orbital" then
        local lens = checkedAsset(LENS)
        if lens then return {lens} end
    end
    return nil
end

local function sculptDetails(entry,key,model,assets,parts)
    local origin = entry.origin
    local color = parts[1].Color
    if key == "foundation" then
        local size = parts[1].Size * 1.043
        local target = parts[1].CFrame*CFrame.new(0,.16,0)
        if entry.variant == "Harbor" then
            size = Vector3.new(32.1,size.Y,17.7)
            target *= CFrame.Angles(0,entry.bodyYaw,0)
        end
        return sculpt(model,assets[1],target,size,color)
    elseif entry.variant == "Towers" then
        local top = entry.bodyTop-origin.Position.Y
        local bottom = top-.18
        local center = origin*CFrame.new(0,bottom+3.52,0)
        return sculpt(model,assets[1],center,Vector3.new(1.20,7.2,1.20),color)
            and sculpt(model,assets[2],origin*CFrame.new(0,bottom+7.16,0)
                *CFrame.Angles(0,math.pi*.5,0),Vector3.new(6.05,.65,.72),parts[2].Color)
    elseif entry.variant == "Crossroads" then
        local bottom = 17.9
        return sculpt(model,assets[1],origin*CFrame.new(0,bottom+2.32,0),
            Vector3.new(29.4,4.64,5.84),color)
            and sculpt(model,assets[1],origin*CFrame.new(0,bottom+2.32,0)*CFrame.Angles(0,math.pi*.5,0),
                Vector3.new(24.7,4.64,5.84),color)
            and sculpt(model,assets[2],origin*CFrame.new(0,bottom+4.64-.20+12.75*.5,0),
                Vector3.new(3.65,12.75,3.65),parts[7].Color)
    else
        local center = origin*CFrame.new(-.72,entry.bodyTop-origin.Position.Y-13.25,0)
            *CFrame.Angles(0,math.pi*.5,0)
        return sculpt(model,assets[1],center,Vector3.one*5.05,color)
    end
end

local function syncDetail(entry,key,assets,names)
    local old = entry[key]
    local parts = assets and names and ownedParts(entry.native,names)
    if old then
        local intact = parts and old.model.Parent == entry.model and #old.sources == #assets
        if intact then
            for i,asset in ipairs(assets) do
                if asset.model ~= old.sources[i] then intact = false;break end
            end
        end
        if intact then
            for _,part in ipairs(parts) do
                if old.replaced[part] == nil then intact = false;break end
            end
        end
        if intact then
            for _,part in ipairs(parts) do maskPart(old.replaced,part) end
            return
        end
        releaseDetail(entry,key)
    end
    if not parts then return end
    for _,part in ipairs(parts) do if part.Transparency >= 1 then return end end
    local model = Instance.new("Model")
    model.Name = key == "foundation" and "ForgedHeroFoundation" or "ForgedHeroFittings"
    model:SetAttribute("CosmeticOnly",true)
    if not sculptDetails(entry,key,model,assets,parts) then model:Destroy();return end
    model.Parent = entry.model
    local detail = {model=model,replaced={},connections={},sources={}}
    entry[key] = detail
    local function revoke()
        if entry[key] == detail then releaseDetail(entry,key) end
    end
    for _,asset in ipairs(assets) do
        detail.sources[#detail.sources+1] = asset.model
        watchAsset(detail.connections,asset,revoke)
    end
    detail.connections[#detail.connections+1] = model.ChildRemoved:Connect(revoke)
    detail.connections[#detail.connections+1] = model.AncestryChanged:Connect(function()
        if model.Parent ~= entry.model then revoke() end
    end)
    local function watch(signal)
        detail.connections[#detail.connections+1] = signal:Connect(revoke)
    end
    for _,part in ipairs(parts) do
        watch(part.AncestryChanged)
        watchNativeMesh(part, watch)
        for _,property in ipairs({"Name","CFrame","Size","Anchored","CanCollide","CanTouch","CanQuery"}) do
            watch(part:GetPropertyChangedSignal(property))
        end
        maskPart(detail.replaced,part)
    end
end

function Kit.sync(arena,cameraPoint,tier,cameraReady,pressure)
    if arena ~= activeArena then clear();activeArena = arena end
    local maximum = DISTANCE[tier] or DISTANCE.Low
    local stress = tonumber(pressure) or 0
    if stress ~= stress then stress = 0 end
    if stress >= 2 or not arena or not cameraReady or typeof(cameraPoint) ~= "Vector3" then
        dispose()
        return
    end
    local base = arena:FindFirstChild("Base")
    local decor = arena:FindFirstChild("Decor")
    local variant = arena:GetAttribute("VariantId")
    local profile = MAIN_PROFILE[variant]
    if not authenticFootprint(base, arena) or not decor or not decor:IsA("Folder") or not profile then
        dispose()
        return
    end
    if base ~= watchedBase then
        if baseConnection then baseConnection:Disconnect() end
        watchedBase = base
        baseConnection = base:GetPropertyChangedSignal("Size"):Connect(function()
            if not authenticFootprint(base,activeArena) then dispose() end
        end)
    end
    local native,frame,size,origin = nativeOrigin(arena,base,variant)
    if not native or (frame.Position-cameraPoint).Magnitude > maximum+(mounted and RETENTION or 0) then
        dispose()
        return
    end
    local desired = profile.premium and checkedAsset(profile.premium) or legacyAsset(variant)
    if mounted and (not desired or mounted.source.model ~= desired.model
        or not valid(mounted,base,arena,variant)) then dispose() end
    if not desired then return end
    if not mounted then mount(arena,base,decor,native,frame,size,origin,variant,desired) end
    local entry = mounted
    if not entry then return end
    maskMain(entry)
    local foot = stress < 1 and checkedAsset(FOOT) or nil
    syncDetail(entry,"foundation",foot and {foot}, {FOOT_NAME[variant]})
    syncDetail(entry,"fittings",stress < 1 and fittingAssets(variant),FITTING_NAMES[variant])
end

function Kit.count()
    return mounted and mounted.model.Parent and 1 or 0
end

function Kit.replacedNativeCount()
    if not mounted or not mounted.model.Parent then return 0 end
    local count = 0
    local function masked(replaced)
        for part in pairs(replaced) do
            if part.Parent == mounted.native and part.Transparency == 1 then count += 1 end
        end
    end
    masked(mounted.replaced)
    for _, key in ipairs({"foundation","fittings"}) do
        local detail = mounted[key]
        if detail and detail.model.Parent == mounted.model then masked(detail.replaced) end
    end
    return count
end

return Kit
