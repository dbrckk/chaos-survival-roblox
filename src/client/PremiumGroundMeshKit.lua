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
-- native geometry. Medium covers 12 of 36; Low remains at 2.
-- An existing local frame/instance-pressure signal can rapidly reclaim
-- the expensive optional copies without a new polling loop or profiler.
-- Imported mesh ceilings (2,976 tris per tile): Low 5,952, Medium
-- 35,712, High 107,136. The server-authoritative Base never changes.
local BUDGET = {
    Low = {count = 2, distance = 125, retention = 18},
    Medium = {count = 12, distance = 195, retention = 24},
    High = {count = 36, distance = 260, retention = 28},
}
local PRESSURE_COUNTS = {
    Low = {2, 2, 1},
    Medium = {12, 8, 4},
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
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    PremiumGroundPbrKit.detach(entry)
    markResident(entry, nil)
    restoreOverlays(entry)
    if entry.model then entry.model:Destroy() end
end

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

local function originalSurface(ground, decor, base)
    -- Only source-authored 49-stud modular floors may take imported art.
    -- Do not decorate the real Base, platform collider, hazard or arbitrary
    -- player-supplied instance with a falsely safe-looking floor surface.
    if not ground or not decor or not base or not base.Parent
        or ground.Parent ~= decor or not ground:IsA("Part")
        or not ground.Name:match("^PremiumGroundModule%d+$")
        or ground:GetAttribute("OriginalGroundFinish") ~= true
        or ground:GetAttribute("PremiumArchitecturalSurface") ~= true
        or ground.CanCollide or ground.CanTouch or ground.CanQuery
        or ground.Transparency >= 0.5
        or ground.Size.X < 35 or ground.Size.Z < 35
        or base.Size.X < 318 or base.Size.Z < 318 then
        return false
    end
    return true
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
    if not entry.model or not entry.model.Parent
        or not entry.pieces or #entry.pieces < 1
        or #entry.pieces > 24 then
        return false
    end
    for _, piece in ipairs(entry.pieces) do
        if not piece:IsA("MeshPart")
            or not piece:IsDescendantOf(entry.model) then
            return false
        end
    end
    if not originalSurface(ground, entry.decor, base)
        or (ground.Size - entry.initialSize).Magnitude >= 0.07
        or (ground.CFrame.Position - entry.initialCFrame.Position).Magnitude >= 0.07
        -- A rotation or streamed reanchor must not leave ghost 3D paint.
        or ground.CFrame.LookVector:Dot(entry.initialCFrame.LookVector) < 0.999
        or ground.CFrame.RightVector:Dot(entry.initialCFrame.RightVector) < 0.999
    then
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
    if scale < 0.60 then return nil end
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
            part.Anchored = true
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
        initialSize = ground.Size, initialCFrame = ground.CFrame,
        pieces = pieces, connections = {}, index = number, overlays = {},
        originalColors = {},
    }
    for _, piece in ipairs(pieces) do
        entry.originalColors[piece] = piece.Color
    end
    recolorMounted(entry)
    local function onGroundChanged()
        -- Hide untrusted/changed 3D immediately, and restore the native
        -- finish. Reversible if a harmless transparency change is undone.
        if not safeAfterMount(entry, base) then
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
            if base.Size.X < 318 or base.Size.Z < 318 then
                clearMounted()
            end
        end)
    end
    if base.Size.X < 318 or base.Size.Z < 318 then
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
                if hasFacing and horizontal.Magnitude > 54
                    and horizontal.Unit:Dot(look) < -0.15 then
                    priority += 72
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
    for _, candidate in ipairs(candidates) do
        local entry = mounted[candidate.part]
        if entry then
            if remaining > 0 and safeAfterMount(entry, base) then
                local count = PremiumGroundPbrKit.attach(entry, variant)
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
