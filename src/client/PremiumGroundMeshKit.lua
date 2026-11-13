-- Original, creator-owned, approved UV/tangent 3D floor plating.
-- The 320-stud arena's true server Base, six-by-six material floor, warning
-- glyphs and collision remain authoritative; these are camera-near cosmetics.
-- Reuse the existing scenery LOD sampler: no new RenderStepped/polling loop.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Roblox's published Rojo siblings and Lest's source-only require both
-- use the same audited template clone helper. No extra render owner.
local PremiumGroundPbrKit = if script and script.Parent
    and script.Parent:FindFirstChild("PremiumGroundPbrKit")
    then require(script.Parent.PremiumGroundPbrKit)
    else require("./PremiumGroundPbrKit")

local groundRulesModule = ReplicatedStorage:FindFirstChild("Shared")
    and ReplicatedStorage.Shared:FindFirstChild("LavaGroundContrastRules")
local LavaGroundContrastRules = if groundRulesModule
    then require(groundRulesModule)
    else require("../shared/LavaGroundContrastRules")
local PremiumGroundMeshKit = {}

-- Approved original Roblox MODEL package, not an invented MeshPart.MeshId.
-- Roblox import/moderation proof: GitHub Actions #41622860616.
local APPROVED_GROUND_ID = 72507987666671
local TEMPLATE_NAME = "PremiumGroundTile"
-- One approved tile is 2,976 source triangles / at most seven MeshParts.
-- The arena has 36 legitimate, author-marked 49-stud floor modules.
-- On healthy High clients, cover ALL 36 with the owner's real Approved
-- UV/tangent 3D tile instead of leaving a 12-tile sea of flat Roblox
-- native geometry. Healthy Medium now covers 16 of 36 (instead of 12);
-- Low stays at 2, and High retains its 36 legitimate floor bays.
-- Medium pressure 1 reclaims 6 of the extra tiles, and pressure 2
-- returns to the existing conservative four. No new poll/render loop.
-- Imported mesh ceilings (2,976 tris/tile): Low 5,952, Medium
-- 47,616 (demoted to 29,760 / 11,904), High 107,136.
-- The server-authoritative collision Base never changes.
local BUDGET = {
    Low = {count = 2, distance = 125, retention = 18},
    Medium = {count = 16, distance = 195, retention = 24},
    High = {count = 36, distance = 260, retention = 28},
}
local PRESSURE_COUNTS = {
    Low = {2, 2, 1},
    Medium = {16, 10, 4},
    High = {36, 24, 16},
}

-- OptionalVfxPressure is 0/1/2 from the existing hysteresis-filtered
-- Android frame pacing + Parts budget owner. Missing data is neutral.
-- Never expand a resident budget beyond the explicit per-device cap.
function PremiumGroundMeshKit.residencyCount(tier, pressure)
    local counts = PRESSURE_COUNTS[tier] or PRESSURE_COUNTS.Low
    local p = tonumber(pressure)
    if p == nil or p ~= p then p = 0 end
    p = math.clamp(math.floor(p), 0, 2)
    return counts[p + 1]
end

local folder = Instance.new("Folder")
folder.Name = "OriginalPremiumGroundMeshesLocal"
folder.Parent = workspace

local mounted = {}
local lavaContrastActive = false
local activeArena = nil

local function recolorMounted(entry)
    if not entry or not entry.pieces then return end
    for _, piece in ipairs(entry.pieces) do
        local baseColor = entry.originalColors and entry.originalColors[piece]
        if piece and piece.Parent and typeof(baseColor) == "Color3" then
            local target = LavaGroundContrastRules.tint(
                baseColor, "mesh", lavaContrastActive)
            if piece.Color ~= target then piece.Color = target end
        end
    end
end

-- Event-driven only: the existing arena-surface controller owns round
-- state, while the existing scenery LOD owner mounts new approved tiles.
-- No extra render loop or new instance: all verified mounted meshes are
-- recolored using their original imported material color, never the
-- already tinted Color from a previous disaster.
function PremiumGroundMeshKit.setLavaContrast(enabled)
    local nextValue = enabled == true
    if nextValue == lavaContrastActive then return end
    lavaContrastActive = nextValue
    for _, entry in pairs(mounted) do
        recolorMounted(entry)
    end
end
local watchedBase = nil
local baseChanged = nil

-- Recessed native maintenance seams/gussets were still drawn OVER approved
-- sculpted MeshParts. Suppress only the exact nonphysical source overlays
-- belonging to an actively resident verified tile, never warning cues.
-- Capture native transparency for exact fallback recovery after LOD exit.
local OVERLAY_PREFIXES = {
    "PremiumGroundServiceInlay",
    "PremiumGroundGusset",
}

local function restoreOverlays(entry)
    for native, alpha in pairs(entry.overlays or {}) do
        if native.Parent == entry.decor
            and not native.CanCollide and not native.CanTouch
            and not native.CanQuery and native.LocalTransparencyModifier == 1 then
            native.LocalTransparencyModifier = alpha
        end
        entry.overlays[native] = nil
    end
end

local function suppressOverlays(entry)
    for _, prefix in ipairs(OVERLAY_PREFIXES) do
        local native = entry.decor:FindFirstChild(prefix .. tostring(entry.index))
        if native and native:IsA("BasePart")
            and native.Parent == entry.decor and native.Anchored
            and not native.CanCollide and not native.CanTouch
            and not native.CanQuery and not native.CastShadow
            and native.Size.Y <= 0.1 then
            if entry.overlays[native] == nil then
                entry.overlays[native] = native.LocalTransparencyModifier
            end
            native.LocalTransparencyModifier = 1
        end
    end
end

local function markResident(entry, present)
    local ground = entry.ground
    if ground and ground.Parent
        and ground:GetAttribute("LocalApproved3DGroundResident") ~= present then
        -- Local-only advisory for 2K MaterialVariant owner: when a real
        -- UV MeshPart overlaps this 0.035-stud native panel, don't waste
        -- another 2K material sampler on the hidden UNDERLAY.
        ground:SetAttribute("LocalApproved3DGroundResident", present)
    end
end

local function restore(entry)
    if not entry or entry.restoring then return end
    entry.restoring = true
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    PremiumGroundPbrKit.detach(entry)
    markResident(entry, nil)
    restoreOverlays(entry)
    if entry.model then entry.model:Destroy() end
end

-- An imported Model can disappear without removing its internal MeshParts
-- (StreamingEnabled, external cleanup or a local owner error). Restore
-- hidden native gussets and the residency advisory on the SAME event,
-- rather than waiting for the next camera LOD sample.
folder.ChildRemoved:Connect(function(child)
    if not child:IsA("Model") then return end
    for ground, entry in pairs(mounted) do
        if not entry.restoring and entry.model == child then
            restore(entry)
            mounted[ground] = nil
        end
    end
end)

local function clearMounted()
    for ground, entry in pairs(mounted) do
        restore(entry)
        mounted[ground] = nil
    end
end

local function clear()
    clearMounted()
    if baseChanged then baseChanged:Disconnect() end
    baseChanged = nil
    watchedBase = nil
    activeArena = nil
    folder:ClearAllChildren()
end

-- Validate the builder's ORIGINAL 6x6 floor layout against the
-- server's live signed footprint. A shrinking cosmetic bay must match
-- BOTH the real size and moving position; it is never a walkable floor.
-- An incomplete streaming update fails closed and exposes native paint.
local function signedFloorScale(base)
    local map = workspace:FindFirstChild("GeneratedMap")
    local arena = base and base.Parent
    if not map or not map:IsA("Folder") or not arena
        or not arena:IsA("Folder") or arena.Name ~= "Arena"
        or arena.Parent ~= map or not base:IsA("BasePart")
        or not base.Anchored or not base.CanCollide then return nil end
    local sx, sz = base:GetAttribute("OriginalSizeX"),
        base:GetAttribute("OriginalSizeZ")
    if typeof(sx) ~= "number" or typeof(sz) ~= "number"
        or sx ~= sx or sz ~= sz or sx < 318 or sz < 318
        or sx >= math.huge or sz >= math.huge then return nil end
    local x, z = base.Size.X / sx, base.Size.Z / sz
    if x < .445 or x > 1.005 or z < .445 or z > 1.005
        or math.abs(x - z) > .012 then return nil end
    return math.min(x, z), sx, sz
end

local function originalSurface(ground, decor, base)
    local scale, sx, sz = signedFloorScale(base)
    if not scale or not ground or not decor
        or ground.Parent ~= decor or decor.Parent ~= base.Parent
        or not ground:IsA("Part") or ground.Shape ~= Enum.PartType.Block
        or not ground.Anchored or ground.CastShadow
        or ground:GetAttribute("OriginalGroundFinish") ~= true
        or ground:GetAttribute("PremiumArchitecturalSurface") ~= true
        or ground.CanCollide or ground.CanTouch or ground.CanQuery
        or ground.Transparency >= 0.5
        or math.abs(ground.Size.Y - .035) > .012 then
        return false
    end
    local index = tonumber(ground.Name:match("^PremiumGroundModule(%d+)$"))
    if not index or index < 1 or index > 36 then return false end
    local cellX, cellZ = (sx - 18) / 6, (sz - 18) / 6
    local expectedSizeX, expectedSizeZ =
        (cellX - 1.2) * scale, (cellZ - 1.2) * scale
    if math.abs(ground.Size.X - expectedSizeX) > .24
        or math.abs(ground.Size.Z - expectedSizeZ) > .24 then
        return false
    end
    local ix, iz = math.floor((index - 1) / 6) + 1,
        (index - 1) % 6 + 1
    local expected = base.CFrame:PointToWorldSpace(Vector3.new(
        (ix - 3.5) * cellX * scale,
        base.Size.Y * .5 + .153,
        (iz - 3.5) * cellZ * scale))
    return (ground.Position - expected).Magnitude < .36
        and ground.CFrame.LookVector:Dot(base.CFrame.LookVector) > .999
        and ground.CFrame.RightVector:Dot(base.CFrame.RightVector) > .999
end

local function validTemplate()
    local holder = ReplicatedStorage:FindFirstChild("PremiumRouteMeshTemplates")
    if not holder or holder:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local template = holder:FindFirstChild(TEMPLATE_NAME)
    if not template or not template:IsA("Model")
        or template:GetAttribute("Original3DAssetId") ~= APPROVED_GROUND_ID
        or template:GetAttribute("OwnerVerified") ~= true
        or template:GetAttribute("CosmeticOnly") ~= true then
        return nil
    end
    local meshCount = 0
    for _, descendant in ipairs(template:GetDescendants()) do
        if descendant:IsA("BasePart") then
            if not descendant:IsA("MeshPart") then return nil end
            meshCount += 1
        elseif descendant:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if meshCount < 1 or meshCount > 24 then return nil end
    return template
end

local function hide(entry)
    -- Shrink, stream unload or a changed source surface: the real game
    -- returns to native art immediately, without a phantom 3D overlay.
    PremiumGroundPbrKit.detach(entry)
    markResident(entry, nil)
    restoreOverlays(entry)
    for _, piece in ipairs(entry.pieces) do
        if piece.Parent and piece.LocalTransparencyModifier ~= 1 then
            piece.LocalTransparencyModifier = 1
        end
    end
end

local function safeAfterMount(entry, base)
    local ground = entry.ground
    -- An imported approved Model can partially disappear during
    -- streaming or failed asset replication even when its native 49-stud
    -- source Part is unchanged. NEVER leave masked native seams or 2K
    -- PBR painted on a missing genuine MeshPart.
    if entry.restoring or not entry.model
        or entry.model.Parent ~= folder
        or not entry.pieces or #entry.pieces < 1
        or #entry.pieces > 24 then
        return false
    end
    for _, piece in ipairs(entry.pieces) do
        if not piece:IsA("MeshPart")
            or not piece:IsDescendantOf(entry.model)
            or piece.Anchored or not piece.Massless
            or piece.CanCollide or piece.CanTouch or piece.CanQuery then
            return false
        end
    end
    -- The server shrinks the ORIGINAL bay and moves it each disaster
    -- tick; the provenance/position checks above replace the obsolete
    -- initial-size/CFrame tests. Welded art follows the actual native bay.
    if not originalSurface(ground, entry.decor, base) then
        return false
    end
    return true
end

local function mount(ground, decor, base, template)
    local _, templateSize = template:GetBoundingBox()
    if templateSize.X < 30 or templateSize.Z < 30
        or templateSize.X > 65 or templateSize.Z > 65
        or templateSize.Y > 1.5 or templateSize.Y <= 0 then
        return nil
    end
    local scale = math.min(
        ground.Size.X * 0.97 / templateSize.X,
        ground.Size.Z * 0.97 / templateSize.Z, 1.05)
    if scale < 0.35 then return nil end
    local clone = template:Clone()
    local scaled = pcall(function() clone:ScaleTo(scale) end)
    if not scaled then
        clone:Destroy()
        return nil
    end
    local sourceFrame, dimensions = clone:GetBoundingBox()
    if dimensions.X > ground.Size.X * 0.98
        or dimensions.Z > ground.Size.Z * 0.98
        or dimensions.Y > 1.5 then
        clone:Destroy()
        return nil
    end

    -- The original warning/safe-route paint is at ~0.19-0.20 studs above
    -- the Base. This 3D art's top is capped at +0.033 over the existing
    -- PremiumGroundModule center (+0.153), i.e. below danger text/glyphs.
    -- Keep real PBR underlay visible through the manufactured 3D seams.
    local number = tonumber(ground.Name:match("(%d+)$")) or 1
    -- The original 4x4 sculpted machined plates have asymmetric details.
    -- Quarter-turn modules by row/column to break visible tiling repetition.
    local yaw = ((math.floor((number - 1) / 6) + (number - 1) % 6) % 4)
        * math.pi * 0.5
    local frame = ground.CFrame
        * CFrame.new(0, 0.032 - dimensions.Y * 0.5, 0)
        * CFrame.Angles(0, yaw, 0)
    local pieces = {}
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            part.CFrame = frame * sourceFrame:ToObjectSpace(part.CFrame)
            part.Anchored = false
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            pieces[#pieces + 1] = part
        end
    end
    if #pieces == 0 or #pieces > 24 then
        clone:Destroy()
        return nil
    end
    clone.Name = "OriginalPremiumArenaGround3D"
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("OriginalGroundMeshId", APPROVED_GROUND_ID)
    clone:SetAttribute("Original3DSourceGround", ground.Name)
    clone.Parent = folder

    local entry = {
        model = clone, ground = ground, decor = decor,
        initialSize = ground.Size,
        pieces = pieces, connections = {}, index = number, overlays = {},
        originalColors = {}, joints = {}, frames = {}, sizes = {},
        lastFootprint = nil,
    }
    for _, piece in ipairs(pieces) do
        entry.originalColors[piece] = piece.Color
        local joint = Instance.new("Weld")
        joint.Name = "PremiumGroundShrinkCosmeticWeld"
        joint.Part0 = ground
        joint.Part1 = piece
        joint.C0 = ground.CFrame:ToObjectSpace(piece.CFrame)
        joint.C1 = CFrame.identity
        joint.Parent = piece
        entry.joints[piece] = joint
        entry.frames[piece] = ground.CFrame:ToObjectSpace(piece.CFrame)
        entry.sizes[piece] = piece.Size
    end
    recolorMounted(entry)
    -- Preserve the source's X/Z details while keeping the original
    -- height flush below the authoritative warning/glyph overlay.
    -- The weld carries all CFrame movement for free; only Size updates
    -- the local mesh profile, using the ALREADY INSTALLED event signal.
    local function refit()
        if not safeAfterMount(entry, base) then return false end
        local ratioX = ground.Size.X / entry.initialSize.X
        local ratioZ = ground.Size.Z / entry.initialSize.Z
        if ratioX <= 0 or ratioZ <= 0
            or ratioX > 2.28 or ratioZ > 2.28
            or math.abs(ratioX - ratioZ) > .015 then return false end
        for _, piece in ipairs(entry.pieces) do
            local joint = entry.joints[piece]
            if not joint or joint.Parent ~= piece
                or joint.Part0 ~= ground or joint.Part1 ~= piece
                or not entry.frames[piece] or not entry.sizes[piece] then
                return false
            end
        end
        if entry.lastFootprint
            and (ground.Size - entry.lastFootprint).Magnitude < .024 then
            return true
        end
        for _, piece in ipairs(entry.pieces) do
            local frame = entry.frames[piece]
            local size = entry.sizes[piece]
            piece.Size = Vector3.new(size.X * ratioX, size.Y,
                size.Z * ratioZ)
            entry.joints[piece].C0 = CFrame.new(
                frame.Position.X * ratioX, frame.Position.Y,
                frame.Position.Z * ratioZ) * (frame - frame.Position)
        end
        entry.lastFootprint = ground.Size
        return true
    end
    local function onGroundChanged()
        -- Hide untrusted/changed 3D immediately, and restore the native
        -- finish. Reversible if a harmless transparency change is undone.
        if not refit() then
            hide(entry)
            return
        end
        for _, piece in ipairs(entry.pieces) do
            if piece.Parent then piece.LocalTransparencyModifier = 0 end
        end
        markResident(entry, true)
        suppressOverlays(entry)
    end
    for _, prop in ipairs({"Size", "CFrame", "Transparency"}) do
        entry.connections[#entry.connections + 1] =
            ground:GetPropertyChangedSignal(prop):Connect(onGroundChanged)
    end
    entry.connections[#entry.connections + 1] =
        ground.AncestryChanged:Connect(onGroundChanged)
    -- Immediate fallback if a source 3D MeshPart is removed unexpectedly.
    -- Ignore PBR template detaches: those are SurfaceAppearance objects,
    -- never critical original geometry. One event per bounded resident tile.
    entry.connections[#entry.connections + 1] =
        clone.DescendantRemoving:Connect(function(descendant)
            if descendant:IsA("MeshPart") then
                hide(entry)
            end
        end)
    onGroundChanged()
    return entry
end

-- Exclusively called by the EXISTING arena/scenery LOD sampling owner.
function PremiumGroundMeshKit.sync(arena, cameraPoint, tier, cameraReady,
    cameraLook, pressure, touch, pbrDisabled)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local budget = BUDGET[tier] or BUDGET.Low
    local residentLimit = PremiumGroundMeshKit.residencyCount(tier, pressure)
    if not arena or not cameraReady or typeof(cameraPoint) ~= "Vector3" then
        clearMounted()
        return
    end
    local base = arena:FindFirstChild("Base")
    local decor = arena:FindFirstChild("Decor")
    if not base or not base:IsA("BasePart")
        or not decor or not decor:IsA("Folder") then
        clearMounted()
        return
    end
    if base ~= watchedBase then
        if baseChanged then baseChanged:Disconnect() end
        watchedBase = base
        baseChanged = base:GetPropertyChangedSignal("Size"):Connect(function()
            if not signedFloorScale(base) then clearMounted() end
        end)
    end
    if not signedFloorScale(base) then
        clearMounted()
        return
    end

    -- Rank the same small number of imported 3D tiles for visible ground.
    -- A third-person camera can sit closer to tiles BEHIND the player than
    -- tiles on screen; raw nearest-first spends Android meshes off screen.
    -- Keep underfoot panels even during camera rotation or steep pitch.
    local look = typeof(cameraLook) == "Vector3"
        and Vector3.new(cameraLook.X, 0, cameraLook.Z)
        or Vector3.zero
    local hasFacing = look.Magnitude > 0.2
    if hasFacing then look = look.Unit end

    local candidates = {}
    for _, part in ipairs(decor:GetChildren()) do
        if originalSurface(part, decor, base) then
            local toTile = part.Position - cameraPoint
            local distance = toTile.Magnitude
            local resident = mounted[part] ~= nil
            -- Only current, unmodified cosmetics receive an EXIT margin.
            -- New tiles still enter at exactly the previous tier distance.
            if distance <= budget.distance
                + (resident and budget.retention or 0) then
                local priority = distance
                    - (resident and budget.retention * 0.55 or 0)
                local horizontal = Vector3.new(toTile.X, 0, toTile.Z)
                if hasFacing and horizontal.Magnitude > 24 then
                    local facing = horizontal.Unit:Dot(look)
                    if horizontal.Magnitude > 54 and facing < -0.15 then
                        -- Preserve the established far-behind penalty.
                        priority += 72
                    elseif facing > 0.18 then
                        -- Spend scarce approved meshes on ground actually
                        -- AHEAD of a third-person player. A small capped
                        -- discount cannot outweigh a much closer
                        -- underfoot tile, and needs no camera raycasts.
                        local ahead = math.clamp(
                            (horizontal.Magnitude - 24) / 80, 0, 1)
                        priority -= 18 * ahead * facing
                    end
                end
                candidates[#candidates + 1] = {
                    part = part,
                    distance = distance,
                    priority = priority,
                }
            end
        end
    end
    table.sort(candidates, function(a, b)
        if a.priority ~= b.priority then
            return a.priority < b.priority
        end
        if a.distance ~= b.distance then
            return a.distance < b.distance
        end
        return a.part.Name < b.part.Name
    end)
    local template = validTemplate()
    local wanted = {}
    if template then
        for i = 1, math.min(budget.count, residentLimit, #candidates) do
            wanted[candidates[i].part] = true
        end
    end

    for ground, entry in pairs(mounted) do
        if not entry or not wanted[ground]
            or not safeAfterMount(entry, base) then
            if entry then restore(entry) end
            mounted[ground] = nil
        end
    end
    for ground in pairs(wanted) do
        if not mounted[ground] then
            mounted[ground] = mount(ground, decor, base, template)
        end
    end
    -- One CAMERA-RANKED set of authentic 2K SurfaceAppearance templates
    -- on ACTUAL UV/tangent MeshParts, not on primitive native surfaces.
    -- Four approved family atlases already exist; new PBR texture files,
    -- dynamic plugin-secured property writes and extra loops are forbidden.
    -- Pressure 0/1/2 consumes at most 6/3/1 High Android floor tiles,
    -- 2/1/0 Medium, none on Low. No increase to mesh residency ceiling.
    local pbrBudget = PremiumGroundPbrKit.tileBudget(
        tier, pressure, touch, pbrDisabled)
    local remaining = pbrBudget
    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local visualMaterial = lavaContrastActive and "LavaSafeSteel" or variant
    for _, candidate in ipairs(candidates) do
        local entry = mounted[candidate.part]
        if entry then
            if remaining > 0 and safeAfterMount(entry, base) then
                local count = PremiumGroundPbrKit.attach(
                    entry, visualMaterial)
                if count > 0 then
                    remaining -= 1
                end
            else
                PremiumGroundPbrKit.detach(entry)
            end
        end
    end
    -- Decor may stream in after its 3D floor Module. Reconcile a maximum
    -- of two native seams per already-mounted tile using the existing
    -- 0.65/0.90-second scenery sampler, without another listener/loop.
    for _, entry in pairs(mounted) do
        if entry and safeAfterMount(entry, base) then
            suppressOverlays(entry)
        end
    end
end

function PremiumGroundMeshKit.pbrCount()
    local tiles, appearances = 0, 0
    for _, entry in pairs(mounted) do
        if entry and entry.model and entry.model.Parent
            and type(entry.originalPbr) == "table"
            and #entry.originalPbr > 0 then
            tiles += 1
            appearances += #entry.originalPbr
        end
    end
    return tiles, appearances
end

function PremiumGroundMeshKit.count()
    local n = 0
    for _, entry in pairs(mounted) do
        if entry.model.Parent then n += 1 end
    end
    return n
end

return PremiumGroundMeshKit
