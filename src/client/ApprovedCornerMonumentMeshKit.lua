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

-- Only native sculptural silhouettes DUPLICATED by the approved imported
-- profiles are suppressed. GroundPlinth and PlinthRim always remain, as do
-- the observatory's tall lightning tip and cargo's signal fin to distinguish
-- the original arena silhouette from the underlying manufactured facade.
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
    for _, property in ipairs({"Size", "CFrame", "Transparency"}) do
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
            if part:IsA("MeshPart") then revokeIfMounted() end
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

function Kit.sync(arena, cameraPoint, tier, cameraReady, cameraLook)
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

return Kit
