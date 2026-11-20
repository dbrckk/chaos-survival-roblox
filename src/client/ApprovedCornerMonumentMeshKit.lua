-- Four original, owner-approved, authentically triangulated monument
-- profiles replace the primitive skyline of the four arena corner towers.
-- Reuses the existing approved facade templates, single scenery LOD sampler,
-- true map provenance and noncolliding source-authored MeshParts.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:FindFirstChild("Shared")
local horizonModule = shared and shared:FindFirstChild("HorizonMonumentGeometry")
local HorizonMonumentGeometry = if horizonModule then require(horizonModule)
    else require("../shared/HorizonMonumentGeometry")

local Kit = {}
-- Grounded facade heights put the forged antenna and split fin in contact
-- with the imported observatory needle and freight hoist forks.
local PROFILE = {
    [1] = {name = "Observatory", id = 132020956214241, height = 35.2},
    [2] = {name = "Freight", id = 88725004643299, height = 33.65},
    [3] = {name = "Turbine", id = 84217436280282},
    [4] = {name = "Aerial", id = 135791763112202},
}
-- A full four-corner manufactured skyline must not revert to
-- primitive Parts on ordinary desktop/Android Medium quality. All FOUR
-- creator-approved profile MeshParts can now be resident on Medium, still
-- camera ranked and distance limited. Low remains one for slow phones.
-- This changes only existing local cosmetic clones, not server geometry,
-- replication, source loading, colliders or the LOD update cadence.
local BUDGET = {
    Low = {count = 1, distance = 145, retention = 16},
    Medium = {count = 4, distance = 280, retention = 22},
    High = {count = 4, distance = 330, retention = 26},
}
local FOUNDATION = {id = 72507987666671, holder = "PremiumRouteMeshTemplates",
    name = "PremiumGroundTile", tag = "PremiumGround3D"}
local OPTIONAL_PARTS = 7
local FOUNDATION_CAP = {Low = 1, Medium = 2, High = 4}
local TOUCH_FOUNDATION_CAP = {Low = 1, Medium = 1, High = 2}
local FOUNDATION_SIZE = Vector3.new(19.6, 1.76, 19.6)
local PLINTH_ASSET = HorizonMonumentGeometry.assetId("bevel")
local PLINTH_SIZE = Vector3.new(20, 1.4, 20)
local RIM_SIZE = Vector3.new(17.8, .4, 17.8)
local CROWN = {
    [1] = {id = 105555650820011, holder = "ApprovedVariantIdentitySpineTemplates",
        name = "Classic", tag = "OriginalVariantIdentitySpine3D",
        bounds = Vector3.new(2.16, 11.92, 2.16), native = "LightningRod",
        class = "Part", size = Vector3.new(.55, 7, .55), y = 38,
        fit = Vector3.new(.93, 7.05, .93), offset = Vector3.new(0, -.025, -.25)},
    [2] = {id = 123049626693705, holder = "ApprovedClassicBroadcastFinTemplates",
        name = "BroadcastFin", tag = "OriginalClassicBroadcastFin3D",
        bounds = Vector3.new(5.46, 15.92, 1.76), native = "SignalFin",
        class = "WedgePart", size = Vector3.new(6, 5.5, 3), y = 36,
        baseAsset = HorizonMonumentGeometry.assetId("cast"),
        fit = Vector3.new(5.8, 5.45, 2.75), offset = Vector3.new(0, -.025, .34)},
}

local bucket = Instance.new("Folder")
bucket.Name = "ApprovedOriginalCornerMonumentsLocal"
bucket.Parent = workspace
local activeArena = nil
local mounted = {}
local baseConnection = nil
local watchedBase = nil

-- The active arena floor shrinks during disasters. These four inert
-- corner monuments do not travel with it; validate the immutable
-- builder-origin footprint and still require the authoritative
-- anchored, collidable Base to belong to this exact arena.
local function authenticBase(base, arena)
    if not base or not base:IsA("BasePart")
        or not arena or base.Parent ~= arena
        or not base.Anchored or not base.CanCollide then return false end
    local sx = base:GetAttribute("OriginalSizeX")
    local sz = base:GetAttribute("OriginalSizeZ")
    return typeof(sx) == "number" and typeof(sz) == "number"
        and sx >= 318 and sz >= 318
        and base.Size.X > 0 and base.Size.Z > 0
        and base.Size.X <= sx + 0.2 and base.Size.Z <= sz + 0.2
end

-- The facade owns the tower body. Each crown masks its own native separately.
local function redundant(slot, name)
    if slot == 1 then
        return name == "WeatherMast" or name == "ScannerLens"
            or name:match("^StormTripod%-?1$") ~= nil
            or name:match("^ObservatoryDish%d+$") ~= nil
    elseif slot == 2 then
        return name == "SkyGantry" or name == "ControlCabin"
            or name:match("^SuspensionPylon%-?1$") ~= nil
            or name:match("^DiagonalBrace%-?1$") ~= nil
            or name:match("^TransitPod%-?1$") ~= nil
            or name:match("^PodGlazing%-?1$") ~= nil
    elseif slot == 3 then
        return name == "ArmouredReactor" or name == "CrownCollar"
            or name == "ContainmentHeart"
            or name:match("^MagneticRing%d+$") ~= nil
            or name:match("^CoreFin%-?1$") ~= nil
    elseif slot == 4 then
        return name == "LighthouseShaft" or name == "ObservationCab"
            or name == "GlassBelt" or name == "Antenna"
            or name == "NavigationLens"
            or name:match("^SignalBlade[123]$") ~= nil
    end
    return false
end

local function restoreNative(entry)
    for part, alpha in pairs(entry.replaced) do
        if part.Parent == entry.native and part.Transparency == 1
            and not part.CanCollide and not part.CanTouch
            and not part.CanQuery then
            part.Transparency = alpha
        end
        entry.replaced[part] = nil
    end
end

local function suppressNative(entry)
    for _, part in ipairs(entry.native:GetChildren()) do
        if part:IsA("BasePart") and part.Parent == entry.native
            and redundant(entry.slot, part.Name)
            and part.Anchored and not part.CanCollide
            and not part.CanTouch and not part.CanQuery
            and part.Transparency < 1 then
            if entry.replaced[part] == nil then
                entry.replaced[part] = part.Transparency
            end
            part.Transparency = 1
        end
    end
end

local function releaseDetail(entry, key)
    local detail = entry[key]
    if not detail then return end
    entry[key] = nil
    for _, connection in ipairs(detail.connections) do
        connection:Disconnect()
    end
    for part, alpha in pairs(detail.originals) do
        if part.Transparency == 1 then part.Transparency = alpha end
    end
    detail.model:Destroy()
end

local function maskDetail(detail)
    for part in pairs(detail.originals) do
        if part.Transparency < 1 then
            detail.originals[part] = part.Transparency
            part.Transparency = 1
        end
    end
end

local function dispose(entry)
    if entry.disposed then return end
    entry.disposed = true
    -- Source or imported-child removal may call this synchronously.
    -- Abandon the entry before destroying its own descendants.
    if mounted[entry.native] == entry then
        mounted[entry.native] = nil
    end
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    releaseDetail(entry, "foundation")
    releaseDetail(entry, "crown")
    restoreNative(entry)
    entry.model:Destroy()
end

local function clearMounted()
    for native, entry in pairs(mounted) do
        dispose(entry)
        mounted[native] = nil
    end
end

local function clear()
    clearMounted()
    if baseConnection then baseConnection:Disconnect() end
    baseConnection = nil
    watchedBase = nil
    activeArena = nil
    bucket:ClearAllChildren()
end

local function template(slot)
    local id = PROFILE[slot]
    local holder = ReplicatedStorage:FindFirstChild("ApprovedDistrictFacadeTemplates")
    if not id or not holder or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local source = holder:FindFirstChild(id.name)
    if not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("DistrictFacade3D") ~= true
        or source:GetAttribute("Original3DAssetId") ~= id.id then
        return nil
    end
    local count = 0
    for _, part in ipairs(source:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then return nil end
            count += 1
        elseif part:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 24 then return nil end
    local _, size = source:GetBoundingBox()
    if size.X < 8 or size.X > 31 or size.Y < 12 or size.Y > 48
        or size.Z < 3 or size.Z > 28 then
        return nil
    end
    return source
end

local function trustedDetail(source, holder, spec)
    return holder and holder:IsA("Folder")
        and holder.Parent == ReplicatedStorage and holder.Name == spec.holder
        and holder:GetAttribute("OwnerVerified") == true
        and source and source:IsA("Model") and source.Parent == holder
        and source.Name == spec.name
        and source:GetAttribute("OwnerVerified") == true
        and source:GetAttribute("CosmeticOnly") == true
        and source:GetAttribute(spec.tag) == true
        and source:GetAttribute("Original3DAssetId") == spec.id
end

local function detailTemplate(spec)
    local holder = ReplicatedStorage:FindFirstChild(spec.holder)
    local source = holder and holder:FindFirstChild(spec.name)
    if not trustedDetail(source, holder, spec) then return nil end
    local parts = source:GetChildren()
    if #parts ~= OPTIONAL_PARTS then return nil end
    for _, part in ipairs(parts) do
        if not part:IsA("MeshPart") or not part.Anchored
            or part.CanCollide or part.CanTouch or part.CanQuery
            or part.Transparency >= 1 then return nil end
        for _, detail in ipairs(part:GetDescendants()) do
            if not detail:IsA("SurfaceAppearance") and not detail:IsA("Decal")
                and not detail:IsA("Texture") then return nil end
        end
    end
    local _, size = source:GetBoundingBox()
    if spec == FOUNDATION then
        if size.X < 40 or size.X > 55 or size.Z < 40 or size.Z > 55
            or math.abs(size.X - size.Z) > 1
            or size.Y < .16 or size.Y > .50 then return nil end
    else
        local canonical = Vector3.new(math.max(size.X, size.Z), size.Y,
            math.min(size.X, size.Z))
        if (canonical - spec.bounds).Magnitude > .48 then return nil end
    end
    return source
end

local function nativeDetailPart(part, parent, class, size, assetId)
    if not part or part.Parent ~= parent or not part:IsA("BasePart")
        or not part.Anchored or part.CanCollide or part.CanTouch or part.CanQuery
        or part:GetAttribute("SceneryLodHidden") == true
        or part.LocalTransparencyModifier >= .95
        or (part.Size - size).Magnitude >= .08 then return false end
    if part:IsA("MeshPart") then
        return assetId ~= nil and part.MeshId ~= ""
            and part:GetAttribute("Original3DAssetId") == assetId
    end
    return part:IsA(class) and (class ~= "Part" or part.Shape == Enum.PartType.Block)
end

local function matchesFrame(part, host, offset)
    return (host.CFrame:PointToObjectSpace(part.Position) - offset).Magnitude < .075
        and part.CFrame.LookVector:Dot(host.CFrame.LookVector) > .999
        and part.CFrame.UpVector:Dot(host.CFrame.UpVector) > .999
end

local function foundationRim(entry)
    local native, plinth = entry.native, entry.plinth
    local rim = native:FindFirstChild("PlinthRim")
    if nativeDetailPart(plinth, native, "Part", PLINTH_SIZE, PLINTH_ASSET)
        and nativeDetailPart(rim, native, "Part", RIM_SIZE, PLINTH_ASSET)
        and matchesFrame(rim, plinth, Vector3.new(0, .9, 0)) then return rim end
    return nil
end

local function nativeCrown(entry)
    local spec = CROWN[entry.slot]
    if not spec then return nil end
    local part = entry.native:FindFirstChild(spec.native)
    if not part or not part:IsA("BasePart") then return nil end
    local plinth = entry.plinth
    local offset = Vector3.new(0, spec.y - .7, 0)
    local size = spec.size
    if spec.baseAsset and part:IsA("MeshPart") then
        -- The imported fin may carry a quarter-turn to align its slope.
        local front = part.CFrame.LookVector
        if math.abs(front:Dot(plinth.CFrame.RightVector)) > .999 then
            size = Vector3.new(size.Z, size.Y, size.X)
        elseif math.abs(front:Dot(plinth.CFrame.LookVector)) <= .999 then
            return nil
        end
        if (plinth.CFrame:PointToObjectSpace(part.Position) - offset).Magnitude >= .075
            or part.CFrame.UpVector:Dot(plinth.CFrame.UpVector) <= .999 then return nil end
    elseif not matchesFrame(part, plinth, offset) then
        return nil
    end
    local assetId = spec.baseAsset
        or HorizonMonumentGeometry.assetId("shaft", entry.native:GetAttribute("SignatureVariant"))
    if nativeDetailPart(part, entry.native, spec.class, size, assetId) then return part end
    return nil
end

local function scaleAxis(axis, scale)
    -- Valid scaling must preserve each axis of the imported MeshPart.
    -- Equal horizontal factors allow arbitrary yaw on the square base.
    local direction = Vector3.new(math.abs(axis.X), math.abs(axis.Y), math.abs(axis.Z))
    if direction.X > .9999 then return scale.X end
    if direction.Y > .9999 then return scale.Y end
    if direction.Z > .9999 then return scale.Z end
    if scale.X == scale.Z and direction.Y < .0001 then return scale.X end
    return nil
end

local function fitPiece(part, origin, target, scale)
    local relative = origin:ToObjectSpace(part.CFrame)
    local x = scaleAxis(relative.RightVector, scale)
    local y = scaleAxis(relative.UpVector, scale)
    local z = scaleAxis(relative.LookVector, scale)
    if not x or not y or not z then return false end
    if scale ~= Vector3.one then
        -- Very thin cross sections may reach Roblox's size floor. Keep
        -- their original center so the aggregate silhouette stays fitted.
        part.Size *= Vector3.new(x, y, z)
    end
    part.CFrame = target * CFrame.new(relative.Position * scale) * relative.Rotation
    return true
end

local function mountDetail(entry, key, native, source, spec)
    local originals = {[native] = native.Transparency}
    if key == "foundation" then originals[entry.plinth] = entry.plinth.Transparency end
    for _, alpha in pairs(originals) do
        if alpha >= 1 then return end
    end
    local clone = source:Clone()
    if not clone then return end
    local origin, size = clone:GetBoundingBox()
    local fit = spec.fit or FOUNDATION_SIZE
    local target, scale
    if spec == FOUNDATION then
        local plinth = entry.plinth
        target = plinth.CFrame * CFrame.new(0, (fit.Y - plinth.Size.Y) * .5, 0)
        local horizontal = fit.X / math.max(size.X, size.Z)
        scale = Vector3.new(horizontal, fit.Y / size.Y, horizontal)
    else
        -- Crown placement uses the authored monument axes even when the
        -- fitted fin mesh was imported sideways.
        target = entry.plinth.CFrame * CFrame.new(spec.offset + Vector3.new(0, spec.y - .7, 0))
        if entry.slot == 2 and size.Z > size.X then
            target *= CFrame.Angles(0, math.pi * .5, 0)
            fit = Vector3.new(fit.Z, fit.Y, fit.X)
        end
        scale = fit / size
    end
    local parts = clone:GetChildren()
    if #parts ~= OPTIONAL_PARTS then
        clone:Destroy()
        return
    end
    for _, part in ipairs(parts) do
        if not fitPiece(part, origin, target, scale) then
            clone:Destroy()
            return
        end
        part.Massless = true
        part.CastShadow = false
        part.LocalTransparencyModifier = 0
        part.Color = part.Color:Lerp(native.Color, key == "crown" and .30 or .16)
    end
    clone.Name = key == "crown" and "Original3DCornerMonumentCrown"
        or "Original3DCornerMonumentFoundation"
    clone:SetAttribute("CornerLandmarkIndex", entry.slot)
    clone.Parent = entry.model
    local holder = source.Parent
    local detail = {model = clone, source = source, native = native,
        connections = {}, originals = originals}
    entry[key] = detail
    local function revoke()
        if entry[key] == detail then releaseDetail(entry, key) end
    end
    local function checkSource()
        if not trustedDetail(source, holder, spec) then revoke() end
    end
    local identify = key == "crown" and nativeCrown or foundationRim
    local function checkNative()
        if identify(entry) ~= native then revoke() end
    end
    local function watch(signal, handler)
        table.insert(detail.connections, signal:Connect(handler))
    end
    watch(source.AncestryChanged, checkSource)
    watch(source:GetPropertyChangedSignal("Name"), checkSource)
    watch(holder:GetPropertyChangedSignal("Name"), checkSource)
    watch(source.ChildAdded, revoke)
    watch(source.ChildRemoved, revoke)
    watch(holder:GetAttributeChangedSignal("OwnerVerified"), checkSource)
    for _, name in ipairs({"OwnerVerified", spec.tag, "CosmeticOnly", "Original3DAssetId"}) do
        watch(source:GetAttributeChangedSignal(name), checkSource)
    end
    watch(clone.ChildRemoved, revoke)
    watch(clone.AncestryChanged, function()
        if clone.Parent ~= entry.model then revoke() end
    end)
    for part in pairs(originals) do
        watch(part.AncestryChanged, checkNative)
        watch(part:GetAttributeChangedSignal("SceneryLodHidden"), checkNative)
        for _, property in ipairs({"Name", "CFrame", "Size", "Anchored",
            "CanCollide", "CanTouch", "CanQuery", "LocalTransparencyModifier"}) do
            watch(part:GetPropertyChangedSignal(property), checkNative)
        end
        if part:IsA("MeshPart") then
            watch(part:GetPropertyChangedSignal("MeshId"), checkNative)
            watch(part:GetAttributeChangedSignal("Original3DAssetId"), checkNative)
        elseif part:IsA("Part") then
            watch(part:GetPropertyChangedSignal("Shape"), checkNative)
        end
    end
    maskDetail(detail)
    return detail
end

local function syncDetail(entry, key, native, source, spec)
    local detail = entry[key]
    if detail and (not native or detail.native ~= native
        or detail.source ~= source or detail.model.Parent ~= entry.model
        or #detail.model:GetChildren() ~= OPTIONAL_PARTS) then
        releaseDetail(entry, key)
        detail = nil
    end
    if detail then
        maskDetail(detail)
        return detail
    elseif native and source then
        return mountDetail(entry, key, native, source, spec)
    end
    return nil
end

local function eligible(native, corners, variant)
    if not native:IsA("Model") or native.Parent ~= corners
        or native:GetAttribute("ArenaDistrictArchitecture") ~= true
        or native:GetAttribute("SourceIsOriginal") ~= true
        or native:GetAttribute("CosmeticOnly") ~= true
        or native:GetAttribute("SignatureVariant") ~= variant then
        return nil
    end
    local slot = native:GetAttribute("CornerLandmarkIndex")
    if type(slot) ~= "number" or slot % 1 ~= 0
        or not PROFILE[slot] then
        return nil
    end
    local plinth = native:FindFirstChild("GroundPlinth")
    if not nativeDetailPart(plinth, native, "Part", PLINTH_SIZE, PLINTH_ASSET) then
        return nil
    end
    return slot, plinth
end

local function valid(entry, corners, base, variant)
    if entry.disposed or entry.model.Parent ~= bucket
        or entry.source.Parent ~= entry.sourceFolder
        or entry.sourceFolder.Parent ~= ReplicatedStorage
        or entry.sourceFolder.Name ~= "ApprovedDistrictFacadeTemplates"
        or entry.source:GetAttribute("Original3DAssetId") ~= PROFILE[entry.slot].id
        or #entry.pieces < 1 or #entry.pieces > 24 then
        return false
    end
    for _, part in ipairs(entry.pieces) do
        if not part:IsDescendantOf(entry.model) then return false end
    end
    local slot, plinth = eligible(entry.native, corners, variant)
    return authenticBase(base, activeArena)
        and slot == entry.slot and plinth == entry.plinth
        and (plinth.CFrame.Position - entry.plinthFrame.Position).Magnitude < .08
        and plinth.CFrame.LookVector:Dot(entry.plinthFrame.LookVector) > .999
        and plinth.CFrame.UpVector:Dot(entry.plinthFrame.UpVector) > .999
        and (plinth.Size - entry.plinthSize).Magnitude < .08
end

local function mount(native, corners, base, variant, slot, plinth, source)
    if not source then return nil end
    local clone = source:Clone()
    if not clone then return nil end
    local sourceFrame, size = clone:GetBoundingBox()
    local height = PROFILE[slot].height or size.Y
    local scale = Vector3.new(1, height / size.Y, 1)
    -- GroundPlinth is at origin + (0, 0.7, 0), and is rotated by the
    -- server's authored per-corner yaw. Mesh bottom therefore meets the
    -- ORIGINAL terrain without adding a phantom walkable platform.
    local target = plinth.CFrame * CFrame.new(0, height * .5 - .7, 0)
    local pieces = {}
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            if scale == Vector3.one then
                part.CFrame = target * sourceFrame:ToObjectSpace(part.CFrame)
            elseif not fitPiece(part, sourceFrame, target, scale) then
                clone:Destroy()
                return nil
            end
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part.LocalTransparencyModifier = 0
            pieces[#pieces + 1] = part
        end
    end
    if #pieces < 1 or #pieces > 24 then
        clone:Destroy()
        return nil
    end
    clone.Name = "ApprovedOriginalCornerMonument3D_" .. tostring(slot)
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("Original3DAssetId", PROFILE[slot].id)
    clone:SetAttribute("CornerLandmarkIndex", slot)
    clone.Parent = bucket
    local entry = {
        native = native, slot = slot, plinth = plinth,
        plinthFrame = plinth.CFrame, plinthSize = plinth.Size,
        model = clone, pieces = pieces, source = source,
        sourceFolder = source.Parent, replaced = {}, connections = {},
    }
    local function reconcile()
        if entry.disposed then return end
        if not valid(entry, corners, base, variant) then
            releaseDetail(entry, "foundation")
            releaseDetail(entry, "crown")
            restoreNative(entry)
            for _, part in ipairs(pieces) do
                if part.Parent then part.LocalTransparencyModifier = 1 end
            end
        else
            for _, part in ipairs(pieces) do
                if part.Parent then part.LocalTransparencyModifier = 0 end
            end
            suppressNative(entry)
        end
    end
    entry.reconcile = reconcile
    for _, property in ipairs({"Size", "CFrame", "Anchored", "CanCollide",
        "CanTouch", "CanQuery", "LocalTransparencyModifier"}) do
        entry.connections[#entry.connections + 1] =
            plinth:GetPropertyChangedSignal(property):Connect(reconcile)
    end
    entry.connections[#entry.connections + 1] =
        plinth:GetAttributeChangedSignal("SceneryLodHidden"):Connect(reconcile)
    entry.connections[#entry.connections + 1] =
        native.AncestryChanged:Connect(reconcile)
    entry.connections[#entry.connections + 1] =
        plinth.AncestryChanged:Connect(reconcile)
    if plinth:IsA("MeshPart") then
        entry.connections[#entry.connections + 1] =
            plinth:GetPropertyChangedSignal("MeshId"):Connect(reconcile)
        entry.connections[#entry.connections + 1] =
            plinth:GetAttributeChangedSignal("Original3DAssetId"):Connect(reconcile)
    end
    -- Revive the original 3D skyline immediately if the optional
    -- approved clone or its creator-owned source loses any MeshPart.
    -- No polling, render loop, new source asset or external request.
    local function revokeIfMounted()
        if mounted[native] == entry then dispose(entry) end
    end
    entry.connections[#entry.connections + 1] =
        clone.AncestryChanged:Connect(function()
            if clone.Parent ~= bucket then revokeIfMounted() end
        end)
    entry.connections[#entry.connections + 1] =
        clone.DescendantRemoving:Connect(function(part)
            if table.find(pieces, part) then revokeIfMounted() end
        end)
    entry.connections[#entry.connections + 1] =
        source.AncestryChanged:Connect(function()
            if source.Parent ~= entry.sourceFolder
                or entry.sourceFolder.Parent ~= ReplicatedStorage then
                revokeIfMounted()
            end
        end)
    entry.connections[#entry.connections + 1] =
        source.DescendantRemoving:Connect(function(part)
            if part:IsA("MeshPart") then revokeIfMounted() end
        end)
    reconcile()
    return entry
end

function Kit.sync(arena, cameraPoint, tier, cameraReady, cameraLook, pressure, touch)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    if not arena or not cameraReady or typeof(cameraPoint) ~= "Vector3" then
        clearMounted()
        return
    end
    local base = arena:FindFirstChild("Base")
    local decor = arena:FindFirstChild("Decor")
    local corners = decor and decor:FindFirstChild("ArenaCornerLandmarks3D")
    local variant = arena:GetAttribute("VariantId")
    if not authenticBase(base, arena)
        or not corners or not corners:IsA("Folder")
        or type(variant) ~= "string" then
        clearMounted()
        return
    end
    if base ~= watchedBase then
        if baseConnection then baseConnection:Disconnect() end
        watchedBase = base
        baseConnection = base:GetPropertyChangedSignal("Size"):Connect(function()
            -- Never fall back to rectangular skyline simply because
            -- the shrinking playfield is narrower than its original Base.
            if not authenticBase(base, activeArena) then clearMounted() end
        end)
    end
    local budget = BUDGET[tier] or BUDGET.Low
    local look = typeof(cameraLook) == "Vector3"
        and Vector3.new(cameraLook.X, 0, cameraLook.Z) or Vector3.zero
    local facing = look.Magnitude > .2
    if facing then look = look.Unit end

    local ranked = {}
    for _, native in ipairs(corners:GetChildren()) do
        local slot, plinth = eligible(native, corners, variant)
        if slot and template(slot) then
            local delta = plinth.Position - cameraPoint
            local distance = delta.Magnitude
            local resident = mounted[native] ~= nil
            if distance <= budget.distance
                + (resident and budget.retention or 0) then
                local priority = distance
                    - (resident and budget.retention * .6 or 0)
                local horizontal = Vector3.new(delta.X, 0, delta.Z)
                if facing and horizontal.Magnitude > 42
                    and horizontal.Unit:Dot(look) < -.15 then
                    priority += 72
                end
                ranked[#ranked + 1] = {
                    native = native, slot = slot, plinth = plinth,
                    distance = distance, priority = priority,
                }
            end
        end
    end
    table.sort(ranked, function(a, b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        if a.distance ~= b.distance then return a.distance < b.distance end
        return a.native.Name < b.native.Name
    end)
    local wanted = {}
    for i = 1, math.min(#ranked, budget.count) do
        wanted[ranked[i].native] = ranked[i]
    end
    for native, entry in pairs(mounted) do
        local requested = wanted[native]
        if not requested or requested.slot ~= entry.slot
            or not valid(entry, corners, base, variant) then
            dispose(entry)
            mounted[native] = nil
        end
    end
    for native, selected in pairs(wanted) do
        if not mounted[native] then
            mounted[native] = mount(native, corners, base, variant,
                selected.slot, selected.plinth, template(selected.slot))
        elseif mounted[native].reconcile then
            mounted[native].reconcile()
        end
    end
    local caps = touch and TOUCH_FOUNDATION_CAP or FOUNDATION_CAP
    local cap = (tonumber(pressure) or 0) >= 1 and 0 or (caps[tier] or caps.Low)
    local foundationSource = cap > 0 and detailTemplate(FOUNDATION) or nil
    local crownCap = cap > 0 and (touch and tier ~= "High" and 1 or 2) or 0
    local activeFoundations, activeCrowns = 0, 0
    for _, selected in ipairs(ranked) do
        local entry = mounted[selected.native]
        if not entry then continue end
        local rim = foundationSource and activeFoundations < cap and foundationRim(entry)
        if syncDetail(entry, "foundation", rim, foundationSource, FOUNDATION) then
            activeFoundations += 1
        end
        local crown = activeCrowns < crownCap and nativeCrown(entry)
        local spec = CROWN[entry.slot]
        local crownSource = crown and detailTemplate(spec) or nil
        if syncDetail(entry, "crown", crown, crownSource, spec) then activeCrowns += 1 end
    end
end

function Kit.count()
    local n = 0
    for _, entry in pairs(mounted) do
        if entry.model.Parent then n += 1 end
    end
    return n
end

function Kit.replacedNativeCount()
    local n = 0
    for _, entry in pairs(mounted) do
        if entry.model.Parent then
            for part in pairs(entry.replaced) do
                if part.Parent == entry.native and part.Transparency == 1 then
                    n += 1
                end
            end
        end
    end
    return n
end

local function detailCount(key)
    local models, replaced = 0, 0
    for _, entry in pairs(mounted) do
        local detail = entry[key]
        if detail and detail.model.Parent == entry.model then
            models += 1
            for part in pairs(detail.originals) do
                if part.Parent == entry.native and part.Transparency == 1 then
                    replaced += 1
                end
            end
        end
    end
    return models, replaced
end

function Kit.foundationCount()
    return detailCount("foundation")
end

function Kit.crownCount()
    return detailCount("crown")
end

return Kit
