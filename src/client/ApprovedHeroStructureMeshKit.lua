-- Five creator-approved, real 3D hero structures replace the primitive
-- skyline architecture on the active arena. Only the source-owner server
-- publishes these sanitized MeshPart templates; clients never fetch assets.
-- Existing 0.65/0.90-second scenery sampler owns lifecycle and tier budgets.
-- The original static Roblox structures remain fully reversible fallbacks.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}

-- Model package IDs from assets/source/roblox-asset-registry.json.
-- These are NOT MeshPart.MeshId strings; verify the server's source identity.
local PROFILE = {
    Classic = {name = "reactor_spire", id = 102992487644269,
        majorMin = 10, majorMax = 18, minorMin = 10, minorMax = 18,
        heightMin = 22, heightMax = 34},
    Towers = {name = "sky_transit_exchange", id = 95878714550124,
        majorMin = 27, majorMax = 39, minorMin = 12, minorMax = 21,
        heightMin = 23, heightMax = 35},
    Crossroads = {name = "plasma_foundry", id = 95926792159328,
        majorMin = 25, majorMax = 37, minorMin = 11, minorMax = 20,
        heightMin = 23, heightMax = 35},
    Orbital = {name = "orbital_halo_array", id = 135985134195364,
        majorMin = 19, majorMax = 29, minorMin = 9, minorMax = 17,
        heightMin = 25, heightMax = 37},
    Harbor = {name = "service_crane", id = 119468460691888,
        majorMin = 18, majorMax = 29, minorMin = 7, minorMax = 16,
        heightMin = 14, heightMax = 24},
}

-- One actual original Model on screen: 1,220 / 620 / 992 / 1,616 /
-- 504 triangles respectively in creator-authored source OBJ files.
-- Low remains one small landmark, with no additional render/network loop.
local DISTANCE = {Low = 175, Medium = 275, High = 370}
local RETENTION = 24

local bucket = Instance.new("Folder")
bucket.Name = "ApprovedOriginalHeroStructuresLocal"
bucket.Parent = workspace

local activeArena = nil
local mounted = nil
local watchedBase = nil
local baseConnection = nil

local function restoreNative(entry)
    for part, originalAlpha in pairs(entry.replaced) do
        if part.Parent == entry.native and part.Transparency == 1
            and part.Anchored and not part.CanCollide and not part.CanTouch
            and not part.CanQuery then
            part.Transparency = originalAlpha
        end
        entry.replaced[part] = nil
    end
end

local function dispose()
    if not mounted then return end
    local entry = mounted
    mounted = nil
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
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
    if not holder or not holder:IsA("Folder")
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
            if not item:IsA("MeshPart") then return nil end
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

local function nativeOrigin(arena, base, variant)
    local decor = arena:FindFirstChild("Decor")
    local native = decor and decor:FindFirstChild("ArenaHeroArchitecture3D")
    if not native or not native:IsA("Model") or native.Parent ~= decor
        or native:GetAttribute("ChaosDistantScenery") ~= true
        or native:GetAttribute("SourceIsOriginal") ~= true
        or native:GetAttribute("SignatureVariant") ~= variant then
        return nil
    end
    local count = 0
    for _, item in ipairs(native:GetDescendants()) do
        if item:IsA("BasePart") then
            if not item.Anchored or item.CanCollide or item.CanTouch
                or item.CanQuery then
                return nil
            end
            count += 1
        elseif item:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 8 or count > 125 then return nil end
    local frame, size = native:GetBoundingBox()
    if size.X <= 0 or size.Y < 12 or size.Z <= 0
        or size.X > 65 or size.Y > 65 or size.Z > 65 then
        return nil
    end
    -- The entire hero must sit well OUTSIDE the playable 320-stud floor.
    -- Even a 42-stud imported package then cannot create a ghost safe route.
    if frame.Position.X - base.Position.X
        < base.Size.X * .5 + size.X * .5 + 15 then
        return nil
    end
    return native, frame, size
end

local function valid(entry, base, arena, variant)
    if not base or not base.Parent or not arena or not arena.Parent
        or base.Size.X < 318 or base.Size.Z < 318
        or entry.variant ~= variant or entry.native.Parent ~= entry.decor then
        return false
    end
    local native, frame, size = nativeOrigin(arena, base, variant)
    return native == entry.native and frame ~= nil
        and (frame.Position - entry.nativeFrame.Position).Magnitude < .12
        and (size - entry.nativeSize).Magnitude < .12
end

local function hidePrimitiveSkyline(entry)
    for _, part in ipairs(entry.native:GetDescendants()) do
        if part:IsA("BasePart") and part:IsDescendantOf(entry.native)
            and part.Anchored and not part.CanCollide and not part.CanTouch
            and not part.CanQuery and part.Transparency < 1 then
            if entry.replaced[part] == nil then
                entry.replaced[part] = part.Transparency
            end
            -- Transparency, not LocalTransparencyModifier: the latter is
            -- owned by scenery-lod and must be left unchanged.
            part.Transparency = 1
        end
    end
end

local function mount(arena, base, decor, native, frame, size, variant, source)
    local clone = source:Clone()
    local sourceFrame, sourceSize = clone:GetBoundingBox()
    if sourceSize.X <= 0 or sourceSize.Y <= 0 or sourceSize.Z <= 0 then
        clone:Destroy()
        return nil
    end
    -- Respect the original outboard architecture footprint. Different
    -- source assets are 18..30 studs tall and must not be stretched into
    -- a billboard or turned into an apparent walkable platform.
    local scale = math.min(1.40,
        size.X * 1.06 / sourceSize.X,
        size.Z * 1.06 / sourceSize.Z,
        size.Y * .96 / sourceSize.Y)
    if scale < .58 or not pcall(function() clone:ScaleTo(scale) end) then
        clone:Destroy()
        return nil
    end
    local cloneFrame, bounds = clone:GetBoundingBox()
    if bounds.X > 45 or bounds.Z > 45 or bounds.Y > 55 then
        clone:Destroy()
        return nil
    end
    local target = CFrame.new(frame.Position.X,
        frame.Position.Y - size.Y * .5 + bounds.Y * .5,
        frame.Position.Z)
    local pieces = {}
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            part.CFrame = target * cloneFrame:ToObjectSpace(part.CFrame)
            part.LocalTransparencyModifier = 0
            part.Anchored = true
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            pieces[#pieces + 1] = part
        end
    end
    if #pieces < 1 or #pieces > 24 then
        clone:Destroy()
        return nil
    end
    clone.Name = "ApprovedOriginalHero3D_" .. variant
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("ApprovedHero3D", true)
    clone:SetAttribute("Original3DAssetId", PROFILE[variant].id)
    clone:SetAttribute("SignatureVariant", variant)
    clone.WorldPivot = target
    clone.Parent = bucket

    local entry = {
        model = clone, native = native, decor = decor, variant = variant,
        nativeFrame = frame, nativeSize = size, replaced = {},
        connections = {}, pieces = pieces,
    }
    local function reconcile()
        if not valid(entry, base, arena, variant) then
            restoreNative(entry)
            for _, part in ipairs(entry.pieces) do
                if part.Parent then part.LocalTransparencyModifier = 1 end
            end
        else
            for _, part in ipairs(entry.pieces) do
                if part.Parent then part.LocalTransparencyModifier = 0 end
            end
            hidePrimitiveSkyline(entry)
        end
    end
    entry.reconcile = reconcile
    entry.connections[#entry.connections + 1] =
        native.AncestryChanged:Connect(reconcile)
    entry.connections[#entry.connections + 1] =
        base:GetPropertyChangedSignal("Size"):Connect(reconcile)
    reconcile()
    return entry
end

function Kit.sync(arena, cameraPoint, tier, cameraReady)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local maximum = DISTANCE[tier] or DISTANCE.Low
    if not arena or not cameraReady or typeof(cameraPoint) ~= "Vector3" then
        dispose()
        return
    end
    local base = arena:FindFirstChild("Base")
    local decor = arena:FindFirstChild("Decor")
    local variant = arena:GetAttribute("VariantId")
    if not base or not base:IsA("BasePart")
        or not decor or not decor:IsA("Folder")
        or not PROFILE[variant]
        or base.Size.X < 318 or base.Size.Z < 318 then
        dispose()
        return
    end
    if base ~= watchedBase then
        if baseConnection then baseConnection:Disconnect() end
        watchedBase = base
        baseConnection = base:GetPropertyChangedSignal("Size"):Connect(function()
            if base.Size.X < 318 or base.Size.Z < 318 then dispose() end
        end)
    end
    local native, frame, size = nativeOrigin(arena, base, variant)
    local distance = frame and (frame.Position - cameraPoint).Magnitude
        or math.huge
    if not native or distance > maximum + (mounted and RETENTION or 0) then
        dispose()
        return
    end
    if mounted and (not valid(mounted, base, arena, variant)
        or mounted.native ~= native) then
        dispose()
    end
    if mounted then
        mounted.reconcile()
        return
    end
    local source = verifiedTemplate(variant)
    if source then
        mounted = mount(arena, base, decor, native, frame, size,
            variant, source)
    end
end

function Kit.count()
    return mounted and mounted.model.Parent and 1 or 0
end

function Kit.replacedNativeCount()
    if not mounted or not mounted.model.Parent then return 0 end
    local count = 0
    for part in pairs(mounted.replaced) do
        if part.Parent == mounted.native and part.Transparency == 1 then
            count += 1
        end
    end
    return count
end

return Kit
