-- Original creator-owned, moderator-approved environment models.
-- Source registry: assets/source/roblox-asset-registry.json.
-- These are Roblox MODEL package IDs (not MeshPart.MeshId values).
-- All native, gameplay-authoritative floor/route/hazard parts remain intact.
local AssetService = game:GetService("AssetService")

local OriginalMeshScenery = {}

local ASSETS = {
    reactor_spire = 102992487644269,
    service_crane = 119468460691888,
    perimeter_gate = 137284215564363,
    plasma_foundry = 95926792159328,
    sky_transit_exchange = 95878714550124,
    orbital_halo_array = 135985134195364,
}

local ORDER = {
    "reactor_spire", "service_crane", "perimeter_gate",
    "plasma_foundry", "sky_transit_exchange", "orbital_halo_array",
}
local MAX_PARTS = 24
local MAX_DIMENSION = 65

-- Eight authored locations, using six approved, creator-owned Roblox
-- Model packages. Four primary skyline anchors plus four staggered
-- secondary landmarks create real 3D depth on 224-stud mega-arenas.
-- Cosmetic only: the native fallback architecture, physics and hazards
-- remain playable if an external model fails to load.
local VARIANT_ART = {
    Classic = {"perimeter_gate", "plasma_foundry", "reactor_spire", "service_crane",
        "sky_transit_exchange", "orbital_halo_array", "plasma_foundry", "perimeter_gate"},
    Towers = {"service_crane", "sky_transit_exchange", "service_crane", "reactor_spire",
        "perimeter_gate", "plasma_foundry", "orbital_halo_array", "sky_transit_exchange"},
    Crossroads = {"perimeter_gate", "sky_transit_exchange", "plasma_foundry", "service_crane",
        "orbital_halo_array", "reactor_spire", "sky_transit_exchange", "perimeter_gate"},
    Orbital = {"orbital_halo_array", "perimeter_gate", "reactor_spire", "orbital_halo_array",
        "sky_transit_exchange", "plasma_foundry", "service_crane", "perimeter_gate"},
}

-- Each side has two DISTINCT stations, with lateral offsets to avoid
-- hiding both imported assets behind the same exterior architecture.
function OriginalMeshScenery.placements(base, variantId)
    if not base or not base:IsA("BasePart") then
        return {}
    end
    local chosen = VARIANT_ART[variantId] or VARIANT_ART.Classic
    local names = {
        perimeter_gate = "Gate",
        reactor_spire = "ReactorSpire",
        service_crane = "ServiceCrane",
        plasma_foundry = "PlasmaFoundry",
        sky_transit_exchange = "SkyTransitExchange",
        orbital_halo_array = "OrbitalHaloArray",
    }
    local halfX, halfZ = base.Size.X * 0.5, base.Size.Z * 0.5
    local surfaceY = base.Position.Y + base.Size.Y * 0.5
    local slots = {
        {direction = "North", axis = "Z", sign = -1, yaw = 0, lateral = -14},
        {direction = "South", axis = "Z", sign = 1, yaw = math.pi, lateral = 14},
        {direction = "East", axis = "X", sign = 1, yaw = -math.pi * 0.5, lateral = -14},
        {direction = "West", axis = "X", sign = -1, yaw = math.pi * 0.5, lateral = 14},
        {direction = "NorthRelay", axis = "Z", sign = -1, yaw = 0, lateral = 58},
        {direction = "SouthRelay", axis = "Z", sign = 1, yaw = math.pi, lateral = -58},
        {direction = "EastRelay", axis = "X", sign = 1, yaw = -math.pi * 0.5, lateral = 58},
        {direction = "WestRelay", axis = "X", sign = -1, yaw = math.pi * 0.5, lateral = -58},
    }
    local placements = {}
    for index, slot in ipairs(slots) do
        local assetName = chosen[index]
        local setback = assetName == "service_crane" and 26
            or (assetName == "reactor_spire" and 23 or 24)
        -- safeExteriorPosition additionally accounts for actual imported
        -- bounds and rotation, so all six approved packages stay off-floor.
        local x = slot.axis == "X" and slot.sign * (halfX + setback)
            or slot.lateral
        local z = slot.axis == "Z" and slot.sign * (halfZ + setback)
            or slot.lateral
        placements[index] = {
            name = "Original" .. names[assetName] .. slot.direction,
            asset = assetName,
            assetId = ASSETS[assetName],
            position = Vector3.new(base.Position.X + x, surfaceY, base.Position.Z + z),
            yaw = slot.yaw,
            axis = slot.axis,
            sign = slot.sign,
        }
    end
    return placements
end

-- A static prefab's bounding volume can be wider than its authored
-- standoff (for example a rotated 65-stud crane). Push its CENTER farther
-- from the playable floor rather than allowing decorative geometry to
-- project inside the map and obscure real platforms or hazard warnings.
-- `GetBoundingBox` returns the model's oriented bounding dimensions;
-- target yaw rotates that box into the intended exterior composition.
function OriginalMeshScenery.safeExteriorPosition(base, placement, size, gap)
    if not base or not base:IsA("BasePart")
        or type(placement) ~= "table"
        or typeof(placement.position) ~= "Vector3"
        or typeof(size) ~= "Vector3"
        or (placement.axis ~= "X" and placement.axis ~= "Z")
        or (placement.sign ~= 1 and placement.sign ~= -1)
    then
        return nil
    end
    local yaw = tonumber(placement.yaw)
    if not yaw or yaw ~= yaw or math.abs(yaw) == math.huge then
        return nil
    end
    if size.X <= 0 or size.Y <= 0 or size.Z <= 0
        or size.X > MAX_DIMENSION or size.Y > MAX_DIMENSION
        or size.Z > MAX_DIMENSION
    then
        return nil
    end

    local cosine, sine = math.abs(math.cos(yaw)), math.abs(math.sin(yaw))
    local radiusX = (size.X * cosine + size.Z * sine) * 0.5
    local radiusZ = (size.Z * cosine + size.X * sine) * 0.5
    local clearance = math.max(12.5, tonumber(gap) or 12.5)
    local position = placement.position

    if placement.axis == "X" then
        local minimum = base.Size.X * 0.5 + radiusX + clearance
        local offset = (position.X - base.Position.X) * placement.sign
        local outward = math.max(minimum, offset)
        return Vector3.new(base.Position.X + placement.sign * outward,
            position.Y, position.Z)
    end
    local minimum = base.Size.Z * 0.5 + radiusZ + clearance
    local offset = (position.Z - base.Position.Z) * placement.sign
    local outward = math.max(minimum, offset)
    return Vector3.new(position.X, position.Y,
        base.Position.Z + placement.sign * outward)
end

-- Imported skyline packages should not visibly intersect the many authored
-- native buildings already present outside the map. Compare oriented boxes
-- conservatively in X/Z, then search nearby lateral skyline slots before
-- pushing an import much farther from the player's camera. Zero physics.
local function planarRadii(cf, size)
    return (
        math.abs(cf.RightVector.X) * size.X
        + math.abs(cf.UpVector.X) * size.Y
        + math.abs(cf.LookVector.X) * size.Z
    ) * 0.5, (
        math.abs(cf.RightVector.Z) * size.X
        + math.abs(cf.UpVector.Z) * size.Y
        + math.abs(cf.LookVector.Z) * size.Z
    ) * 0.5
end

function OriginalMeshScenery.unobstructedExteriorPosition(base, placement,
        size, decor)
    local starting = OriginalMeshScenery.safeExteriorPosition(
        base, placement, size
    )
    if not starting or typeof(decor) ~= "Instance" then
        return starting
    end
    local obstructions = {}
    local function collectBounds(model)
        local ok, cf, bounds = pcall(function()
            return model:GetBoundingBox()
        end)
        if ok and cf and bounds then
            local rx, rz = planarRadii(cf, bounds)
            obstructions[#obstructions + 1] = {
                x = cf.Position.X, z = cf.Position.Z,
                rx = rx, rz = rz,
            }
        end
    end
    for _, child in ipairs(decor:GetChildren()) do
        -- Gameplay platforms and hazard telegraphs are not decorative
        -- blockers; keep native exterior art intact.
        if child:IsA("Model")
            and child:GetAttribute("ChaosDistantScenery") == true then
            collectBounds(child)
        end
    end
    -- Imported packages live in a nested Folder, not as direct children
    -- of Decor. Their dimensions MUST also count. Otherwise the second
    -- through fourth packages (and asynchronous late-loading packages)
    -- can occupy an already-mounted MeshPart's space.
    local imported = decor:FindFirstChild("Original3DScenery")
    if imported and imported:IsA("Folder") then
        for _, child in ipairs(imported:GetChildren()) do
            if child:IsA("Model")
                and child:GetAttribute("CosmeticOnly") == true
                and type(child:GetAttribute("Original3DAssetId")) == "number"
            then
                collectBounds(child)
            end
        end
    end
    if #obstructions == 0 then return starting end

    local yaw = tonumber(placement.yaw) or 0
    local radiusX = (math.abs(math.cos(yaw)) * size.X
        + math.abs(math.sin(yaw)) * size.Z) * 0.5
    local radiusZ = (math.abs(math.cos(yaw)) * size.Z
        + math.abs(math.sin(yaw)) * size.X) * 0.5
    local isEastWest = placement.axis == "X"
    -- Lateral alternatives first: maintain strong apparent scale and
    -- prevent obscured details behind native skyline architecture.
    for _, farther in ipairs({0, 12, 24, 42, 64, 96, 132}) do
        for _, lateral in ipairs({0, -24, 24, -42, 42, -58, 58,
                -76, 76, -98, 98}) do
            local candidate = if isEastWest then Vector3.new(
                starting.X + placement.sign * farther,
                starting.Y, starting.Z + lateral
            ) else Vector3.new(
                starting.X + lateral, starting.Y,
                starting.Z + placement.sign * farther
            )
            local clear = true
            for _, bound in ipairs(obstructions) do
                if math.abs(candidate.X - bound.x)
                    < radiusX + bound.rx + 4
                    and math.abs(candidate.Z - bound.z)
                    < radiusZ + bound.rz + 4 then
                    clear = false
                    break
                end
            end
            if clear then
                return candidate
            end
        end
    end
    -- Never introduce a visually interpenetrating import merely to reach
    -- a target count. Existing collision-free native skyline is retained.
    return nil
end

-- No instances from a remote model become live until fully sanitized.
-- Keep only the geometry and its inert surface appearance. Never retain a
-- loaded Script, ModuleScript, LocalScript, constraints, sounds or effects.
function OriginalMeshScenery.sanitize(source)
    if not source or not source:IsA("Model") then
        return nil
    end

    local pieces = {}
    for _, descendant in ipairs(source:GetDescendants()) do
        if descendant:IsA("BasePart") then
            table.insert(pieces, descendant)
            if #pieces > MAX_PARTS then
                return nil
            end
        end
    end
    if #pieces == 0 then
        return nil
    end

    local clean = Instance.new("Model")
    clean.Name = "SanitizedOriginal3D"
    for _, original in ipairs(pieces) do
        local ok, copy = pcall(function()
            return original:Clone()
        end)
        if not ok or not copy or not copy:IsA("BasePart") then
            clean:Destroy()
            return nil
        end
        for _, nested in ipairs(copy:GetDescendants()) do
            if not nested:IsA("SurfaceAppearance")
                and not nested:IsA("Decal")
                and not nested:IsA("Texture")
            then
                nested:Destroy()
            end
        end
        copy.Anchored = true
        copy.CanCollide = false
        copy.CanTouch = false
        copy.CanQuery = false
        copy.CastShadow = false
        copy.Massless = true
        copy.Parent = clean
    end

    local _, size = clean:GetBoundingBox()
    if size.X <= 0 or size.Y <= 0 or size.Z <= 0
        or size.X > MAX_DIMENSION
        or size.Y > MAX_DIMENSION
        or size.Z > MAX_DIMENSION
    then
        clean:Destroy()
        return nil
    end
    return clean
end

-- The imported meshes stand beyond the arena's physical floor. Give them
-- grounded structural mass instead of leaving their bottom silhouette
-- apparently floating in space. All original art remains immutable; these
-- four simple, low-cost Roblox Parts are authored AFTER sanitization,
-- inside the cosmetic model and inside the imported model's X/Z footprint.
-- They are automatically hidden together with the MeshPart on Android Low.
local FOUNDATION_COLORS = {
    reactor_spire = Color3.fromRGB(69, 89, 112),
    service_crane = Color3.fromRGB(124, 102, 79),
    perimeter_gate = Color3.fromRGB(77, 104, 114),
    plasma_foundry = Color3.fromRGB(115, 91, 84),
    sky_transit_exchange = Color3.fromRGB(83, 114, 126),
    orbital_halo_array = Color3.fromRGB(85, 100, 139),
}

function OriginalMeshScenery.addFoundation(model, assetName, target, size)
    if not model or not model:IsA("Model")
        or typeof(target) ~= "CFrame" or typeof(size) ~= "Vector3"
        or size.X <= 0 or size.Y <= 0 or size.Z <= 0
    then return 0 end
    if model:GetAttribute("OriginalFoundationBuilt") == true then return 0 end
    local accent = FOUNDATION_COLORS[assetName]
    if not accent then return 0 end
    -- All elevations are relative to the imported *bounding-box center*.
    -- Every support's top begins at or beneath the mesh bottom; nothing
    -- artificial rises into the character/hazard plane.
    local halfY = size.Y * 0.5
    local specs = {
        {"FoundationShoulder", Vector3.new(size.X * 0.92, 0.62, size.Z * 0.92),
            Vector3.new(0, -halfY - 0.31, 0), Enum.Material.Metal,
            Color3.fromRGB(32, 41, 54)},
        {"FoundationInset", Vector3.new(size.X * 0.80, 0.78, size.Z * 0.80),
            Vector3.new(0, -halfY - 1.01, 0), Enum.Material.Metal, accent},
        {"FoundationBallast", Vector3.new(size.X * 0.88, 3.8, size.Z * 0.88),
            Vector3.new(0, -halfY - 3.24, 0), Enum.Material.Concrete,
            Color3.fromRGB(29, 35, 45)},
        {"FoundationGroundPad", Vector3.new(size.X * 0.96, 0.75, size.Z * 0.96),
            Vector3.new(0, -halfY - 5.45, 0), Enum.Material.Metal,
            Color3.fromRGB(47, 54, 64)},
    }
    for _, spec in ipairs(specs) do
        local p = Instance.new("Part")
        p.Name = spec[1]
        p.Size = spec[2]
        p.CFrame = target * CFrame.new(spec[3])
        p.Material = spec[4]
        p.Color = spec[5]
        p.Anchored = true
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.CastShadow = false
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        -- Explicit provenance: imported package geometry can have arbitrary
        -- names, but only these four locally authored parts may get PBR.
        p:SetAttribute("OriginalFoundationVisual", true)
        p.Parent = model
    end
    model:SetAttribute("OriginalFoundationBuilt", true)
    return #specs
end

-- Idempotent on the same live arena. The original native horizon and
-- perimeter decor is never destroyed: if an asset cannot load, the game
-- remains visually complete with all tested collision surfaces intact.
function OriginalMeshScenery.mount(arena, templates)
    if not arena or not arena.Parent or not templates then
        return 0
    end
    local decor = arena:FindFirstChild("Decor")
    local base = arena:FindFirstChild("Base")
    if not decor or not base then
        return 0
    end

    local folder = decor:FindFirstChild("Original3DScenery")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "Original3DScenery"
        folder:SetAttribute("ChaosDistantScenery", true)
        folder.Parent = decor
    end

    local mounted = 0
    for _, placement in ipairs(OriginalMeshScenery.placements(
        base, arena:GetAttribute("VariantId")
    )) do
        if not folder:FindFirstChild(placement.name) then
            local template = templates[placement.asset]
            if template then
                local clone = template:Clone()
                if clone then
                    clone.Name = placement.name
                    clone:SetAttribute("ChaosDistantScenery", true)
                    clone:SetAttribute("Original3DAssetId", placement.assetId)
                    clone:SetAttribute("CosmeticOnly", true)
                    local bbox, size = clone:GetBoundingBox()
                    local safePosition = OriginalMeshScenery.unobstructedExteriorPosition(
                        base, placement, size, decor
                    )
                    if not safePosition then
                        clone:Destroy()
                        continue
                    end
                    local target = CFrame.new(
                        safePosition + Vector3.new(0, size.Y * 0.5, 0)
                    ) * CFrame.Angles(0, placement.yaw, 0)
                    -- Recenter to bounding volume, not an untrusted
                    -- imported pivot, so every model stands on its base.
                    for _, item in ipairs(clone:GetChildren()) do
                        if item:IsA("BasePart") then
                            item.CFrame = target * bbox:ToObjectSpace(item.CFrame)
                        end
                    end
                    OriginalMeshScenery.addFoundation(
                        clone, placement.asset, target, size
                    )
                    -- A sanitized Model has no PrimaryPart, and moving the
                    -- individual BasePart CFrames does NOT necessarily update
                    -- a previously initialized WorldPivot (e.g. cloned from
                    -- an imported package). Keep the pivot at the *actual*
                    -- placed mesh center so the Android per-model LOD uses
                    -- the correct camera distance after each map swap.
                    -- Setting WorldPivot changes NO geometry or collision.
                    clone.WorldPivot = target
                    -- Roblox StreamingEnabled: keep the imported MeshPart
                    -- and its four structural supports visually coherent
                    -- as one atomic unit. Unlike Persistent, this can still
                    -- stream out normally when the camera moves away.
                    clone.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
                    clone.Parent = folder
                    mounted += 1
                end
            end
        end
    end
    -- Counters are replicated for inspection without any Studio-only
    -- debugging tools. "Complete" means eight decorative placements, not
    -- proof of texture visibility or Android performance.
    local total = #folder:GetChildren()
    arena:SetAttribute("Original3DSceneryCount", total)
    arena:SetAttribute("Original3DSceneryComplete", total == 8)
    return mounted
end

-- Observe world-map lifecycle without holding on to a destroyed
-- GeneratedMap. A retrying server, a regenerated map or late Arena/Decor
-- streaming must still receive its already-loaded decorative MeshParts.
-- No polling or new per-frame work: connections are explicitly replaced.
function OriginalMeshScenery.observeWorld(world, onReady)
    assert(typeof(world) == "Instance" and type(onReady) == "function",
        "OriginalMeshScenery.observeWorld requires a world and callback")
    local alive = true
    local generated, arena = nil, nil
    local sentArena = nil
    local mapAdded, mapRemoved, arenaAdded = nil, nil, nil

    local function disconnect(connection)
        if connection then connection:Disconnect() end
    end
    local function emit()
        if not alive or not generated or not arena
            or generated.Parent ~= world
            or world:FindFirstChild("GeneratedMap") ~= generated
            or generated:FindFirstChild("Arena") ~= arena
            or not arena:FindFirstChild("Base")
            or not arena:FindFirstChild("Decor")
            or sentArena == arena
        then
            return
        end
        sentArena = arena
        onReady(arena)
    end
    local function bindArena(nextArena)
        if nextArena == arena then return end
        disconnect(arenaAdded)
        arenaAdded = nil
        arena = nextArena
        sentArena = nil
        if arena then
            arenaAdded = arena.ChildAdded:Connect(function(child)
                if child.Name == "Base" or child.Name == "Decor" then
                    task.defer(emit)
                end
            end)
            -- Arena is parented before the builder's synchronous Base and
            -- Decor creation, so never assume they already exist here.
            task.defer(emit)
        end
    end
    local function bindGenerated(nextMap)
        if nextMap == generated then return end
        disconnect(mapAdded)
        disconnect(mapRemoved)
        mapAdded, mapRemoved = nil, nil
        bindArena(nil)
        generated = nextMap
        if generated then
            local observed = generated
            mapAdded = observed.ChildAdded:Connect(function(child)
                if child.Name == "Arena" and generated == observed then
                    bindArena(observed:FindFirstChild("Arena"))
                end
            end)
            mapRemoved = observed.ChildRemoved:Connect(function(child)
                if child == arena and generated == observed then
                    bindArena(observed:FindFirstChild("Arena"))
                end
            end)
            bindArena(observed:FindFirstChild("Arena"))
        end
    end
    local worldAdded = world.ChildAdded:Connect(function(child)
        if child.Name == "GeneratedMap" then
            bindGenerated(world:FindFirstChild("GeneratedMap"))
        end
    end)
    local worldRemoved = world.ChildRemoved:Connect(function(child)
        if child == generated then
            bindGenerated(world:FindFirstChild("GeneratedMap"))
        end
    end)
    bindGenerated(world:FindFirstChild("GeneratedMap"))

    return function()
        if not alive then return end
        alive = false
        disconnect(worldAdded)
        disconnect(worldRemoved)
        disconnect(mapAdded)
        disconnect(mapRemoved)
        disconnect(arenaAdded)
        worldAdded, worldRemoved = nil, nil
        mapAdded, mapRemoved, arenaAdded = nil, nil, nil
        generated, arena, sentArena = nil, nil, nil
    end
end

-- Bound concurrent AssetService.LoadAssetAsync operations. Issuing all six
-- package requests on the same frame can spike join-time streaming and
-- trigger owner-wide throttling; two independent lanes continue if one
-- individual package fails. Fresh arrays prevent callers mutating ORDER.
function OriginalMeshScenery.loadLanes()
    local lanes = {{}, {}}
    for index, name in ipairs(ORDER) do
        lanes[(index - 1) % 2 + 1][#lanes[(index - 1) % 2 + 1] + 1] = name
    end
    return lanes
end

local started = false
local templates = {}

function OriginalMeshScenery.start()
    if started then
        return
    end
    started = true

    -- Remain subscribed if GeneratedMap is created late/rebuilt entirely.
    -- The callback is used only for a complete, canonical arena, while
    -- asynchronous template arrivals refresh the current arena directly.
    OriginalMeshScenery.observeWorld(workspace, function(arena)
        OriginalMeshScenery.mount(arena, templates)
    end)

    local function refreshArena()
        local generated = workspace:FindFirstChild("GeneratedMap")
        local arena = generated and generated:FindFirstChild("Arena")
        if arena and arena:FindFirstChild("Base")
            and arena:FindFirstChild("Decor") then
            OriginalMeshScenery.mount(arena, templates)
        end
    end

    -- Cache each moderator-approved package once per server. A temporary
    -- Roblox CDN failure may still occur: retry twice with backoff.
    -- One package's permanent failure cannot prevent its lane from
    -- reaching the other approved packages.
    local function loadOne(assetName)
        local assetId = ASSETS[assetName]
        for attempt = 1, 3 do
            local ok, imported = pcall(
                AssetService.LoadAssetAsync, AssetService, assetId
            )
            if ok and imported and imported:IsA("Model") then
                local clean = OriginalMeshScenery.sanitize(imported)
                imported:Destroy()
                if not clean then
                    warn("Original 3D scenery rejected: invalid geometry", assetName)
                    return
                end
                templates[assetName] = clean
                refreshArena()
                return
            end

            if ok and typeof(imported) == "Instance" then
                imported:Destroy()
            end
            if attempt == 3 then
                warn("Original 3D scenery failed after 3 attempts:",
                    assetName, imported)
                return
            end
            task.wait(attempt * 3)
        end
    end

    -- Cosmetic loading must never delay joining or the round lifecycle.
    -- Exactly two worker coroutines means no more than two concurrent
    -- original-asset network operations per running server.
    for _, lane in ipairs(OriginalMeshScenery.loadLanes()) do
        task.spawn(function()
            for _, assetName in ipairs(lane) do
                loadOne(assetName)
            end
        end)
    end
end

return OriginalMeshScenery
