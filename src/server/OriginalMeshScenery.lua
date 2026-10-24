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
}

local ORDER = {"reactor_spire", "service_crane", "perimeter_gate"}
local MAX_PARTS = 24
local MAX_DIMENSION = 65

-- Four off-floor destinations are intentionally outside player-accessible
-- geometry, kill volumes and hazard telegraphs. Only purely visual meshes
-- are inserted; the existing procedural structures always remain as fallback.
local VARIANT_ART = {
    Classic = {"perimeter_gate", "perimeter_gate", "reactor_spire", "service_crane"},
    Towers = {"service_crane", "perimeter_gate", "service_crane", "reactor_spire"},
    Crossroads = {"perimeter_gate", "perimeter_gate", "service_crane", "service_crane"},
    Orbital = {"reactor_spire", "perimeter_gate", "reactor_spire", "perimeter_gate"},
}

-- Four authored skyline compositions rather than the same repeated props in
-- every arena. Standoffs are wider for a crane's 22-stud arm than a gate.
-- This keeps all geometry beyond playable platforms on every 150+ stud map.
function OriginalMeshScenery.placements(base, variantId)
    if not base or not base:IsA("BasePart") then
        return {}
    end
    local chosen = VARIANT_ART[variantId] or VARIANT_ART.Classic
    local names = {
        perimeter_gate = "Gate",
        reactor_spire = "ReactorSpire",
        service_crane = "ServiceCrane",
    }
    local halfX, halfZ = base.Size.X * 0.5, base.Size.Z * 0.5
    local surfaceY = base.Position.Y + base.Size.Y * 0.5
    local slots = {
        {direction = "North", axis = "Z", sign = -1, yaw = 0},
        {direction = "South", axis = "Z", sign = 1, yaw = math.pi},
        {direction = "East", axis = "X", sign = 1, yaw = -math.pi * 0.5},
        {direction = "West", axis = "X", sign = -1, yaw = math.pi * 0.5},
    }
    local placements = {}
    for index, slot in ipairs(slots) do
        local assetName = chosen[index]
        local setback = assetName == "service_crane" and 26
            or (assetName == "reactor_spire" and 23 or 13)
        local x = slot.axis == "X" and slot.sign * (halfX + setback)
            or (index % 2 == 0 and 12 or -12)
        local z = slot.axis == "Z" and slot.sign * (halfZ + setback)
            or (index % 2 == 0 and 12 or -12)
        placements[index] = {
            name = "Original" .. names[assetName] .. slot.direction,
            asset = assetName,
            assetId = ASSETS[assetName],
            position = Vector3.new(base.Position.X + x, surfaceY, base.Position.Z + z),
            yaw = slot.yaw,
        }
    end
    return placements
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
                    local target = CFrame.new(
                        placement.position + Vector3.new(0, size.Y * 0.5, 0)
                    ) * CFrame.Angles(0, placement.yaw, 0)
                    -- Recenter to bounding volume, not an untrusted
                    -- imported pivot, so every model stands on its base.
                    for _, item in ipairs(clone:GetChildren()) do
                        if item:IsA("BasePart") then
                            item.CFrame = target * bbox:ToObjectSpace(item.CFrame)
                        end
                    end
                    clone.Parent = folder
                    mounted += 1
                end
            end
        end
    end
    -- Counters are replicated for inspection without any Studio-only
    -- debugging tools. "Complete" means four decorative placements, not
    -- proof of texture visibility or Android performance.
    local total = #folder:GetChildren()
    arena:SetAttribute("Original3DSceneryCount", total)
    arena:SetAttribute("Original3DSceneryComplete", total == 4)
    return mounted
end

local started = false
local templates = {}

function OriginalMeshScenery.start()
    if started then
        return
    end
    started = true

    local generated = workspace:FindFirstChild("GeneratedMap")
    if not generated then
        warn("Original 3D scenery: GeneratedMap missing; native assets retained.")
        return
    end

    local function refreshArena()
        local arena = generated:FindFirstChild("Arena")
        if arena then
            OriginalMeshScenery.mount(arena, templates)
        end
    end

    generated.ChildAdded:Connect(function(child)
        if child.Name == "Arena" then
            -- MapBuilder builds its Decor after parenting the arena. Run
            -- only after that synchronous construction has completed.
            task.defer(function()
                if child.Parent == generated then
                    refreshArena()
                end
            end)
        end
    end)

    -- Load only three moderator-approved packages, once per server,
    -- asynchronously. No player, round, spawn or UI code waits for them.
    for _, assetName in ipairs(ORDER) do
        task.spawn(function()
            local assetId = ASSETS[assetName]
            local ok, imported = pcall(
                AssetService.LoadAssetAsync, AssetService, assetId
            )
            if not ok or not imported then
                warn("Original 3D scenery unavailable:", assetName, imported)
                return
            end
            local clean = OriginalMeshScenery.sanitize(imported)
            imported:Destroy()
            if not clean then
                warn("Original 3D scenery rejected: invalid geometry", assetName)
                return
            end
            templates[assetName] = clean
            refreshArena()
        end)
    end
end

return OriginalMeshScenery
