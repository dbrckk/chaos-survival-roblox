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
function OriginalMeshScenery.placements(base)
    if not base or not base:IsA("BasePart") then
        return {}
    end
    local halfX, halfZ = base.Size.X * 0.5, base.Size.Z * 0.5
    local surfaceY = base.Position.Y + base.Size.Y * 0.5
    return {
        {
            name = "OriginalGateNorth",
            asset = "perimeter_gate",
            assetId = ASSETS.perimeter_gate,
            position = base.Position + Vector3.new(0, surfaceY - base.Position.Y, -halfZ - 11),
            yaw = 0,
        },
        {
            name = "OriginalGateSouth",
            asset = "perimeter_gate",
            assetId = ASSETS.perimeter_gate,
            position = base.Position + Vector3.new(0, surfaceY - base.Position.Y, halfZ + 11),
            yaw = math.pi,
        },
        {
            name = "OriginalReactorSpireEast",
            asset = "reactor_spire",
            assetId = ASSETS.reactor_spire,
            position = base.Position + Vector3.new(halfX + 24, surfaceY - base.Position.Y, 12),
            yaw = -math.pi * 0.5,
        },
        {
            name = "OriginalServiceCraneWest",
            asset = "service_crane",
            assetId = ASSETS.service_crane,
            position = base.Position + Vector3.new(-halfX - 26, surfaceY - base.Position.Y, -12),
            yaw = math.pi * 0.5,
        },
    }
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
    for _, placement in ipairs(OriginalMeshScenery.placements(base)) do
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
            local added = OriginalMeshScenery.mount(arena, templates)
            if added > 0 then
                arena:SetAttribute("Original3DSceneryReady", true)
            end
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
