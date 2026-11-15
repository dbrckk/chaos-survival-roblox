-- Four original, owner-approved, authentically triangulated monument
-- profiles replace the primitive skyline of the four arena corner towers.
-- Reuses the existing approved facade templates, single scenery LOD sampler,
-- true map provenance and noncolliding source-authored MeshParts.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}
local PROFILE = {
    [1] = {name = "Observatory", id = 132020956214241},
    [2] = {name = "Freight", id = 88725004643299},
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
local FOUNDATION_ID = 72507987666671
local FOUNDATION_PARTS = 7
local FOUNDATION_CAP = {Low = 1, Medium = 2, High = 4}
local TOUCH_FOUNDATION_CAP = {Low = 1, Medium = 1, High = 2}
local FOUNDATION_SIZE = Vector3.new(19.6, 1.76, 19.6)

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

-- The facade profiles cover the tower bodies. The lightning rod and the
-- cargo signal fin still distinguish their skylines.
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

local function releaseFoundation(entry)
    local foundation = entry.foundation
    if not foundation then return end
    entry.foundation = nil
    for _, connection in ipairs(foundation.connections) do
        connection:Disconnect()
    end
    for part, alpha in pairs(foundation.originals) do
        if part.Transparency == 1 then part.Transparency = alpha end
    end
    foundation.model:Destroy()
end

local function maskFoundation(foundation)
    for part in pairs(foundation.originals) do
        if part.Transparency < 1 then
            foundation.originals[part] = part.Transparency
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
    releaseFoundation(entry)
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

local function trustedFoundation(source, holder)
    return holder and holder:IsA("Folder")
        and holder.Parent == ReplicatedStorage
        and holder.Name == "PremiumRouteMeshTemplates"
        and holder:GetAttribute("OwnerVerified") == true
        and source and source:IsA("Model") and source.Parent == holder
        and source.Name == "PremiumGroundTile"
        and source:GetAttribute("OwnerVerified") == true
        and source:GetAttribute("PremiumGround3D") == true
        and source:GetAttribute("CosmeticOnly") == true
        and source:GetAttribute("Original3DAssetId") == FOUNDATION_ID
end

local function foundationTemplate()
    local holder = ReplicatedStorage:FindFirstChild("PremiumRouteMeshTemplates")
    local source = holder and holder:FindFirstChild("PremiumGroundTile")
    if not trustedFoundation(source, holder) then return nil end
    if #source:GetChildren() ~= FOUNDATION_PARTS then return nil end
    for _, part in ipairs(source:GetChildren()) do
        if not part:IsA("MeshPart") or not part.Anchored
            or part.CanCollide or part.CanTouch or part.CanQuery
            or part.Transparency >= 1 then return nil end
        for _, detail in ipairs(part:GetDescendants()) do
            if not detail:IsA("SurfaceAppearance") and not detail:IsA("Decal")
                and not detail:IsA("Texture") then return nil end
        end
    end
    local _, size = source:GetBoundingBox()
    if size.X < 40 or size.X > 55 or size.Z < 40 or size.Z > 55
        or math.abs(size.X - size.Z) > 1
        or size.Y < .16 or size.Y > .50 then return nil end
    return source
end

local function nativeFoundationPart(part, parent, size)
    return part and part:IsA("Part") and part.Parent == parent
        and part.Shape == Enum.PartType.Block and part.Anchored
        and not part.CanCollide and not part.CanTouch and not part.CanQuery
        and part:GetAttribute("SceneryLodHidden") ~= true
        and part.LocalTransparencyModifier < .95
        and (part.Size - size).Magnitude < .08
end

local function foundationRim(entry)
    local native, plinth = entry.native, entry.plinth
    local rim = native:FindFirstChild("PlinthRim")
    if nativeFoundationPart(plinth, native, Vector3.new(20, 1.4, 20))
        and nativeFoundationPart(rim, native, Vector3.new(17.8, .4, 17.8))
        and (plinth.CFrame:PointToObjectSpace(rim.Position)
            - Vector3.new(0, .9, 0)).Magnitude < .08
        and rim.CFrame.LookVector:Dot(plinth.CFrame.LookVector) > .999
        and rim.CFrame.UpVector:Dot(plinth.CFrame.UpVector) > .999 then
        return rim
    end
    return nil
end

local function mountFoundation(entry, rim, source)
    local plinth = entry.plinth
    if plinth.Transparency >= 1 or rim.Transparency >= 1 then return false end
    local clone = source:Clone()
    if not clone then return false end
    local origin, size = clone:GetBoundingBox()
    local horizontalScale = FOUNDATION_SIZE.X / math.max(size.X, size.Z)
    local verticalScale = FOUNDATION_SIZE.Y / size.Y
    local scale = Vector3.new(horizontalScale, verticalScale, horizontalScale)
    local target = plinth.CFrame * CFrame.new(0,
        (FOUNDATION_SIZE.Y - plinth.Size.Y) * .5, 0)
    local parts = clone:GetChildren()
    if #parts ~= FOUNDATION_PARTS then
        clone:Destroy()
        return false
    end
    for _, part in ipairs(parts) do
        local relative = origin:ToObjectSpace(part.CFrame)
        local verticalAxes = Vector3.new(math.abs(relative.RightVector.Y),
            math.abs(relative.UpVector.Y), math.abs(relative.LookVector.Y))
        -- The importer can permute local axes. Stretch along the actual
        -- bounds' vertical axis, rejecting a skewed transform.
        if math.max(verticalAxes.X, verticalAxes.Y, verticalAxes.Z) < .9999 then
            clone:Destroy()
            return false
        end
        local partScale = Vector3.new(
            verticalAxes.X > .9999 and verticalScale or horizontalScale,
            verticalAxes.Y > .9999 and verticalScale or horizontalScale,
            verticalAxes.Z > .9999 and verticalScale or horizontalScale)
        part.Size *= partScale
        part.CFrame = target * CFrame.new(relative.Position * scale)
            * relative.Rotation
        part.Massless = true
        part.CastShadow = false
        part.LocalTransparencyModifier = 0
        part.Color = part.Color:Lerp(rim.Color, .16)
    end
    clone.Name = "Original3DCornerMonumentFoundation"
    clone:SetAttribute("CornerLandmarkIndex", entry.slot)
    clone.Parent = entry.model
    local holder = source.Parent
    local foundation = {
        model = clone, source = source, rim = rim, connections = {},
        originals = {[plinth] = plinth.Transparency, [rim] = rim.Transparency},
    }
    entry.foundation = foundation
    local function revoke()
        if entry.foundation == foundation then releaseFoundation(entry) end
    end
    local function checkSource()
        if not trustedFoundation(source, holder) then revoke() end
    end
    local function checkNative()
        if foundationRim(entry) ~= rim then revoke() end
    end
    local function watch(signal, handler)
        table.insert(foundation.connections, signal:Connect(handler))
    end
    watch(source.AncestryChanged, checkSource)
    watch(source.ChildAdded, revoke)
    watch(source.ChildRemoved, revoke)
    watch(holder:GetAttributeChangedSignal("OwnerVerified"), checkSource)
    for _, name in ipairs({"OwnerVerified", "PremiumGround3D", "CosmeticOnly",
        "Original3DAssetId"}) do
        watch(source:GetAttributeChangedSignal(name), checkSource)
    end
    watch(clone.ChildRemoved, revoke)
    watch(clone.AncestryChanged, function()
        if clone.Parent ~= entry.model then revoke() end
    end)
    for _, part in ipairs({plinth, rim}) do
        watch(part.AncestryChanged, checkNative)
        watch(part:GetAttributeChangedSignal("SceneryLodHidden"), checkNative)
        for _, property in ipairs({"CFrame", "Size", "Shape", "Anchored",
            "CanCollide", "CanTouch", "CanQuery", "LocalTransparencyModifier"}) do
            watch(part:GetPropertyChangedSignal(property), checkNative)
        end
    end
    maskFoundation(foundation)
    return true
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
    if not plinth or not plinth:IsA("Part")
        or plinth.Parent ~= native or not plinth.Anchored
        or plinth.CanCollide or plinth.CanTouch or plinth.CanQuery
        or plinth:GetAttribute("SceneryLodHidden") == true
        or plinth.LocalTransparencyModifier >= 0.95
        or plinth.Size.X < 19 or plinth.Size.X > 21
        or plinth.Size.Z < 19 or plinth.Size.Z > 21 then
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
    local clone = source:Clone()
    local sourceFrame, size = clone:GetBoundingBox()
    -- GroundPlinth is at origin + (0, 0.7, 0), and is rotated by the
    -- server's authored per-corner yaw. Mesh bottom therefore meets the
    -- ORIGINAL terrain without adding a phantom walkable platform.
    local target = plinth.CFrame * CFrame.new(0, size.Y * .5 - .7, 0)
    local pieces = {}
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            part.CFrame = target * sourceFrame:ToObjectSpace(part.CFrame)
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
            releaseFoundation(entry)
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
    for _, property in ipairs({"Size", "CFrame"}) do
        entry.connections[#entry.connections + 1] =
            plinth:GetPropertyChangedSignal(property):Connect(reconcile)
    end
    entry.connections[#entry.connections + 1] =
        native.AncestryChanged:Connect(reconcile)
    entry.connections[#entry.connections + 1] =
        plinth.AncestryChanged:Connect(reconcile)
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
    local source = cap > 0 and foundationTemplate() or nil
    local active = 0
    for _, selected in ipairs(ranked) do
        local entry = mounted[selected.native]
        if not entry then continue end
        local rim = source and active < cap and foundationRim(entry)
        local foundation = entry.foundation
        if foundation and (not rim or foundation.rim ~= rim
            or foundation.source ~= source or foundation.model.Parent ~= entry.model
            or #foundation.model:GetChildren() ~= FOUNDATION_PARTS) then
            releaseFoundation(entry)
        end
        if rim and entry.foundation then
            maskFoundation(entry.foundation)
            active += 1
        elseif rim and mountFoundation(entry, rim, source) then
            active += 1
        end
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

function Kit.foundationCount()
    local models, replaced = 0, 0
    for _, entry in pairs(mounted) do
        local foundation = entry.foundation
        if foundation and foundation.model.Parent == entry.model then
            models += 1
            for part in pairs(foundation.originals) do
                if part.Parent == entry.native and part.Transparency == 1 then
                    replaced += 1
                end
            end
        end
    end
    return models, replaced
end

return Kit
