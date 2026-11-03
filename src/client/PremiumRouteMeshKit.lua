-- True creator-owned imported 3D MeshPart route art. Not Roblox Parts.
-- Authoritative collision, movement, danger notices and game mechanics remain
-- the original server platforms. This module owns ONLY local cosmetic clones.
-- Reuse scenery-lod.client.lua's existing 0.65/0.90s camera/quality sampler;
-- no additional render loop, remote, client asset fetch or studio dependency.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PremiumRouteMeshKit = {}

local ASSETS = {
    PremiumJumpDeck = 98478693994864,
    PremiumSkybridgeModule = 94023662427980,
    -- Official creator-owner Approved import #41644715829, 3,072 triangles.
    OriginalUnderdeckChassis = 84582262145054,
}
-- Hysteresis keeps the SAME approved imported route art resident as the
-- camera moves across a threshold. A new route must be within distance;
-- an already mounted safe route gets a small exit margin, never more slots.
-- Stable residency avoids repeated MeshPart clone/weld churn on Android.
-- More actual visible jump surfaces receive owner-approved sculpted deck
-- meshes instead of the flat original PlatformPanel. Retain Low Android
-- caps, bridge segment caps, and the existing 0/2/4 underdeck sculpture
-- cap: all changes are cosmetics, ranked by safe route/camera relevance.
local BUDGET = {
    Low = {decks = 2, bridges = 1, segments = 1, underdecks = 0,
        distance = 100, retention = 18},
    Medium = {decks = 7, bridges = 1, segments = 3, underdecks = 2,
        distance = 190, retention = 22},
    High = {decks = 14, bridges = 2, segments = 5, underdecks = 4,
        distance = 260, retention = 28},
}

local folder = Instance.new("Folder")
folder.Name = "PremiumRouteMeshLocal"
folder.Parent = workspace

local mounted = {}
local activeArena = nil
local watchedBase = nil
local baseChanged = nil

local function restore(entry)
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    for _, model in ipairs(entry.models) do
        model:Destroy()
    end
    local panel = entry.panel
    if panel and panel.Parent then
        panel.LocalTransparencyModifier = entry.originalPanelAlpha
    end
end

local function clearMounted()
    for platform, entry in pairs(mounted) do
        restore(entry)
        mounted[platform] = nil
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

local function safePlatform(platform, initialSize)
    if not platform or not platform.Parent or not platform:IsA("BasePart")
        or not platform.CanCollide or platform.Transparency >= 0.75 then
        return false
    end
    local phase = platform:GetAttribute("CollapsePhase")
    if phase ~= nil and phase ~= "Normal" and phase ~= "Safe" then
        -- Warning and Gone must reveal the ORIGINAL gameplay hazard paint.
        return false
    end
    -- Skybridge shutters have their own independent server hazard state.
    -- The collision bridge stays solid during Warning/Raising/Raised, so
    -- CanCollide/CollapsePhase alone would leave decorative MeshParts
    -- covering the authoritative orange warning strip and gate approach.
    -- Restore the genuine server route paint immediately, before LOD tick.
    local shutter = platform:GetAttribute("BridgeShutterPhase")
    if shutter ~= nil and shutter ~= "Idle" then
        return false
    end
    if initialSize and (math.abs(platform.Size.X - initialSize.X) >= 0.09
        or math.abs(platform.Size.Z - initialSize.Z) >= 0.09) then
        -- No false safe 3D bridge/deck during independent shrinking routes.
        return false
    end
    return true
end

local function getTemplate(name)
    local templates = ReplicatedStorage:FindFirstChild("PremiumRouteMeshTemplates")
    if not templates or templates:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local model = templates:FindFirstChild(name)
    if not model or not model:IsA("Model")
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("Original3DAssetId") ~= ASSETS[name] then
        return nil
    end
    return model
end

local function addModel(entry, platform, template, offset, scale, yaw)
    if not template or scale <= 0 then return false end
    local clone = template:Clone()
    local ok = pcall(function() clone:ScaleTo(scale) end)
    if not ok then clone:Destroy(); return false end
    local initialFrame, dimensions = clone:GetBoundingBox()
    if dimensions.X <= 0 or dimensions.Y <= 0 or dimensions.Z <= 0
        or dimensions.X > 30 or dimensions.Z > 30 then
        clone:Destroy()
        return false
    end
    -- The top of the original mesh sits 0.11 studs above the physical top,
    -- matching the existing non-colliding 0.10-stud native panel paint.
    -- This is NOT a substitute for any authoritative walkable surface.
    local localOffset = typeof(offset) == "Vector3"
        and offset or Vector3.new(offset, 0, 0)
    local target = platform.CFrame
        * CFrame.new(localOffset.X,
            platform.Size.Y * 0.5 + 0.11 - dimensions.Y * 0.5,
            localOffset.Z)
        * CFrame.Angles(0, yaw, 0)

    local parts = {}
    for _, descendant in ipairs(clone:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CFrame = target * initialFrame:ToObjectSpace(descendant.CFrame)
            descendant.Anchored = false
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
            descendant.CastShadow = false
            descendant.Massless = true
            parts[#parts + 1] = descendant
        end
    end
    if #parts == 0 or #parts > 24 then
        clone:Destroy()
        return false
    end
    clone.Name = "OriginalPremiumRouteMesh"
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("OriginalPremiumRouteAssetId",
        template:GetAttribute("Original3DAssetId"))
    clone.Parent = folder
    for _, piece in ipairs(parts) do
        local weld = Instance.new("WeldConstraint")
        weld.Name = "OriginalRouteMeshCosmeticWeld"
        weld.Part0 = platform
        weld.Part1 = piece
        weld.Parent = piece
    end
    entry.models[#entry.models + 1] = clone
    return true
end

-- Genuine originally authored 3,072-triangle multi-web machine chassis.
-- Place it STRICTLY below the true collidable Part's LOWER face: never a
-- false jumpable floor, ghost safe route, gameplay collider or Roblox Part.
-- Long X source is rotated with an equally real Z-oriented walkway.
-- The same mesh-owner entry, hazard event listeners, weld cleanup and
-- existing camera sampler control this entire extra underdeck model.
local function addUnderdeckModel(entry, platform, template)
    if not template then return false end
    local _, sourceSize = template:GetBoundingBox()
    if sourceSize.X < 20 or sourceSize.X > 26
        or sourceSize.Y < 3 or sourceSize.Y > 8
        or sourceSize.Z < 8 or sourceSize.Z > 13 then
        return false
    end
    local length = math.max(platform.Size.X, platform.Size.Z)
    local width = math.min(platform.Size.X, platform.Size.Z)
    -- Small square jump tiles need no invisible 3K-triangle machinery.
    if length < 17 or width < 9.5 then return false end
    local scale = math.min(
        length * 0.88 / sourceSize.X,
        width * 0.88 / sourceSize.Z,
        1.06)
    if scale < 0.56 then return false end
    local clone = template:Clone()
    local ok = pcall(function() clone:ScaleTo(scale) end)
    if not ok then clone:Destroy(); return false end

    local frame, size = clone:GetBoundingBox()
    if size.X <= 0 or size.Y <= 0 or size.Z <= 0
        or size.X > 32 or size.Z > 18 or size.Y > 9 then
        clone:Destroy()
        return false
    end
    -- Source model center must be at or below the true platform's lower
    -- face. A small air gap lets the edge cast a visible real 3D profile.
    local yaw = platform.Size.Z > platform.Size.X and math.pi * 0.5 or 0
    local target = platform.CFrame
        * CFrame.new(0, -platform.Size.Y * 0.5 - 0.06 - size.Y * 0.5, 0)
        * CFrame.Angles(0, yaw, 0)
    local pieces = {}
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Never accept unexpected Parts in an imported model when this
            -- authored source is specifically a multi-material MeshPart kit.
            if not part:IsA("MeshPart") then
                clone:Destroy()
                return false
            end
            part.CFrame = target * frame:ToObjectSpace(part.CFrame)
            part.Anchored = false
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part.Massless = true
            pieces[#pieces + 1] = part
        end
    end
    if #pieces == 0 or #pieces > 16 then
        clone:Destroy()
        return false
    end
    clone.Name = "OriginalEngineeredUnderdeck3D"
    clone:SetAttribute("OriginalUnderdeckArt", true)
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("OriginalPremiumRouteAssetId",
        template:GetAttribute("Original3DAssetId"))
    clone.Parent = folder
    for _, piece in ipairs(pieces) do
        local weld = Instance.new("WeldConstraint")
        weld.Name = "OriginalUnderdeckSafeCosmeticWeld"
        weld.Part0 = platform
        weld.Part1 = piece
        weld.Parent = piece
    end
    entry.models[#entry.models + 1] = clone
    return true
end

local function syncVisibility(entry, platform)
    local safe = safePlatform(platform, entry.initialSize)
    -- Never hide the live platform itself or move the gameplay part.
    -- A warning immediately reveals the server-owned native surface.
    for _, model in ipairs(entry.models) do
        for _, piece in ipairs(model:GetDescendants()) do
            if piece:IsA("BasePart") then
                local wanted = safe and 0 or 1
                if piece.LocalTransparencyModifier ~= wanted then
                    piece.LocalTransparencyModifier = wanted
                end
            end
        end
    end
    if entry.panel and entry.panel.Parent then
        local desired = safe and 1 or entry.originalPanelAlpha
        if entry.panel.LocalTransparencyModifier ~= desired then
            entry.panel.LocalTransparencyModifier = desired
        end
    end
end

local function mount(platform, template, count, bridgeCandidate, underdeckTemplate)
    local _, bounds = template:GetBoundingBox()
    if bounds.X < 3 or bounds.Y < 0.1 or bounds.Z < 3 then
        return nil
    end
    local isBridge = bridgeCandidate == true
    local width = math.min(platform.Size.X, platform.Size.Z)
    local length = math.max(platform.Size.X, platform.Size.Z)
    local countToMount = isBridge and count or 1
    local segment = length / countToMount
    local scale = if isBridge then math.min(
        width * 0.91 / bounds.Z, segment * 0.88 / bounds.X, 1.10)
        else math.min(
            platform.Size.X * 0.93 / bounds.X,
            platform.Size.Z * 0.93 / bounds.Z, 1.28)
    if scale < 0.46 then return nil end
    local entry = {
        models = {},
        connections = {},
        initialSize = platform.Size,
        count = countToMount,
        panel = nil,
        originalPanelAlpha = 0,
        underdeck = underdeckTemplate ~= nil,
    }
    local yaw = isBridge and (platform.Size.Z > platform.Size.X
        and math.pi * 0.5 or 0) or 0

    for i = 1, countToMount do
        local offset = isBridge
            and ((i - 0.5) * segment - length * 0.5)
            or 0
        -- The imported module's X axis is rotated into the actual long
        -- bridge axis; the tile translation follows that SAME axis.
        -- No fake physical Part is introduced for the orientation change.
        local modelOffset = isBridge and platform.Size.Z > platform.Size.X
            and Vector3.new(0, 0, offset) or offset
        local before = #entry.models
        if not addModel(entry, platform, template, modelOffset, scale, yaw)
            or #entry.models == before then
            for _, model in ipairs(entry.models) do model:Destroy() end
            return nil
        end
    end

    if underdeckTemplate then
        -- Source outside bounds or an unavailable owner Model is simply a
        -- safe optional fallback: never invalidate the real route art.
        addUnderdeckModel(entry, platform, underdeckTemplate)
    end

    local index = tonumber(platform.Name:match("^Platform(%d+)$")
        or platform.Name:match("^Skybridge(%d+)$"))
    local arena = platform.Parent and platform.Parent.Parent
    local decor = arena and arena:FindFirstChild("Decor")
    local panel = decor and index and decor:FindFirstChild("PlatformPanel" .. index)
    if panel and panel:IsA("BasePart") then
        entry.panel = panel
        entry.originalPanelAlpha = panel.LocalTransparencyModifier
    end
    local function refresh()
        if platform.Parent then
            syncVisibility(entry, platform)
        end
    end
    for _, prop in ipairs({"CanCollide", "Transparency", "Size"}) do
        entry.connections[#entry.connections + 1] =
            platform:GetPropertyChangedSignal(prop):Connect(refresh)
    end
    for _, attribute in ipairs({"CollapsePhase", "BridgeShutterPhase"}) do
        entry.connections[#entry.connections + 1] =
            platform:GetAttributeChangedSignal(attribute):Connect(refresh)
    end
    refresh()
    return entry
end

-- Physically walkable, permanent connector decks have always used native
-- cuboids, even though real owner-approved UV/tangent bridge MeshParts are
-- already in ReplicatedStorage. The five maps have two eight-deck sky
-- promenades and a ten-deck Sky Spine supported by true server collisions.
-- Only those named, server-authored, safe route structures can share the
-- very same authenticated skybridge kit as Towers' four gated bridges.
-- NEVER label an arbitrary fake bridge or local cosmetic Part as walkable.
local function isPermanentConnector(platform)
    if not platform.Name:match("^Platform%d+$")
        or platform:GetAttribute("ChaosPermanentRoute") ~= true then
        return false
    end
    local lane = platform:GetAttribute("PromenadeLane")
    local step = platform:GetAttribute("PromenadeStep")
    if type(lane) == "number" and lane % 1 == 0
        and lane >= 1 and lane <= 2
        and type(step) == "number" and step % 1 == 0
        and step >= 1 and step <= 8 then
        return true
    end
    local spine = platform:GetAttribute("SkySpineStep")
    return platform:GetAttribute("SkySpineInterchange") == true
        and type(spine) == "number"
        and spine % 1 == 0 and spine >= 1 and spine <= 10
end

local function eligible(platform, cameraPoint, maxDistance, retention, cameraLook)
    -- Read genuine safety before residency: NEVER keep cosmetic meshes on
    -- a collapsing, shrinking, transparent or shutter-warning platform.
    if not safePlatform(platform) then return nil end
    local gatedBridge = platform:GetAttribute("ChaosSkybridge") == true
        and platform.Name:match("^Skybridge%d+$") ~= nil
    local connector = isPermanentConnector(platform)
    local isBridge = gatedBridge or connector
    local isDeck = platform.Name:match("^Platform%d+$") ~= nil
    if not isBridge and not isDeck then return nil end
    local width, length = math.min(platform.Size.X, platform.Size.Z),
        math.max(platform.Size.X, platform.Size.Z)
    if width < (isBridge and 3.8 or 8) or width > 26 then return nil end
    if not isBridge and length / width > 1.85 then return nil end

    local resident = mounted[platform] ~= nil
    local dist = (cameraPoint - platform.Position).Magnitude
    if dist > maxDistance + (resident and retention or 0) then return nil end
    -- Between equally useful routes, keep already visible art instead of
    -- replacing MeshParts every LOD tick for tiny camera movements. The
    -- hard deck/bridge/segment caps remain exactly the same on every tier.
    local priority = dist - (resident and retention * 0.65 or 0)
    -- The old nearest-only sort frequently filled ALL 2/5/9 approved deck
    -- mesh slots with platforms BEHIND the third-person Android camera.
    -- Prefer the real next leap in front (without creating any assets or
    -- increasing limits). Under 48 studs keep an omnidirectional stable
    -- landing: rotating the camera must not suddenly evict the current deck.
    if typeof(cameraLook) == "Vector3" and cameraLook.Magnitude > 0.5
        and dist > 48 then
        local direction = (platform.Position - cameraPoint) / dist
        local facing = direction:Dot(cameraLook.Unit)
        if facing > 0 then
            priority -= math.min(58, dist * 0.22) * facing
        else
            priority += math.min(38, dist * 0.17) * -facing
        end
    end
    -- Landmark crossing routes are highly visible from the upper world,
    -- but never override an actual closer, solid, warning-free landing.
    if connector then priority -= 6 end
    return {
        platform = platform,
        bridge = isBridge,
        connector = connector,
        distance = dist,
        priority = priority,
    }
end

-- Called BY the existing LOD scheduler, not a new time-based loop.
function PremiumRouteMeshKit.sync(arena, cameraPoint, quality, cameraReady, cameraLook)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local budget = BUDGET[quality] or BUDGET.Low
    if not arena or not cameraReady or typeof(cameraPoint) ~= "Vector3" then
        clearMounted()
        return
    end
    local base = arena:FindFirstChild("Base")
    local platforms = arena:FindFirstChild("Platforms")
    if not base or not base:IsA("BasePart") or not platforms
        or not platforms:IsA("Folder") then
        clearMounted()
        return
    end
    if base ~= watchedBase then
        if baseChanged then baseChanged:Disconnect() end
        watchedBase = base
        -- Resize is an immediate hazard; don't wait for the next 0.65s LOD
        -- cycle to hide cosmetic meshes from nonexistent jumpable ground.
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

    local decks, bridges = {}, {}
    for _, platform in ipairs(platforms:GetChildren()) do
        if platform:IsA("BasePart") then
            local item = eligible(platform, cameraPoint, budget.distance,
                budget.retention, cameraLook)
            if item then
                local bucket = item.bridge and bridges or decks
                bucket[#bucket + 1] = item
            end
        end
    end
    local function byDistance(a, b)
        if a.priority == b.priority then
            if a.distance == b.distance then
                return a.platform.Name < b.platform.Name
            end
            return a.distance < b.distance
        end
        return a.priority < b.priority
    end
    table.sort(decks, byDistance)
    table.sort(bridges, byDistance)

    local wanted = {}
    local deckTemplate = getTemplate("PremiumJumpDeck")
    local bridgeTemplate = getTemplate("PremiumSkybridgeModule")
    if deckTemplate then
        for i = 1, math.min(#decks, budget.decks) do
            wanted[decks[i].platform] = {template = deckTemplate, count = 1,
                bridge = false}
        end
    end
    if bridgeTemplate then
        for i = 1, math.min(#bridges, budget.bridges) do
            local span = math.max(bridges[i].platform.Size.X,
                bridges[i].platform.Size.Z)
            local count = math.min(budget.segments,
                math.max(1, math.floor(span / 9.5)))
            wanted[bridges[i].platform] = {
                template = bridgeTemplate, count = count, bridge = true,
            }
        end
    end

    -- A 3K-triangle hollow chassis is genuinely useful on long visible
    -- sky route foundations; never attach it to every streamed platform.
    -- The existing 0/2/4 UNDERDECK MODEL quota is additional but stays
    -- inside the SAME PremiumRouteMeshLocal adaptive Android Parts ledger.
    -- Prefer eligible real 26-stud connector routes, then large safe decks.
    local underdeckTemplate = getTemplate("OriginalUnderdeckChassis")
    local underdeckSlots = budget.underdecks
    if underdeckTemplate and underdeckSlots > 0 then
        local ranked = {}
        for _, item in ipairs(bridges) do
            if wanted[item.platform] then ranked[#ranked + 1] = item end
        end
        for _, item in ipairs(decks) do
            if wanted[item.platform] then ranked[#ranked + 1] = item end
        end
        table.sort(ranked, byDistance)
        for _, item in ipairs(ranked) do
            if underdeckSlots <= 0 then break end
            local size = item.platform.Size
            if math.max(size.X, size.Z) >= 17
                and math.min(size.X, size.Z) >= 9.5 then
                wanted[item.platform].underdeck = underdeckTemplate
                underdeckSlots -= 1
            end
        end
    end

    for platform, entry in pairs(mounted) do
        local desired = wanted[platform]
        if not desired or desired.count ~= entry.count
            or (desired.underdeck ~= nil) ~= entry.underdeck then
            restore(entry)
            mounted[platform] = nil
        end
    end
    for platform, desired in pairs(wanted) do
        if not mounted[platform] then
            mounted[platform] = mount(platform, desired.template, desired.count,
                desired.bridge, desired.underdeck)
        end
    end
end

function PremiumRouteMeshKit.count()
    local n = 0
    for _, entry in pairs(mounted) do
        n += #entry.models
    end
    return n
end

-- Diagnostics count REAL imported additional Model instances (not a
-- pretended on-device screenshot or guessed complete texture residency).
function PremiumRouteMeshKit.underdeckCount()
    local n = 0
    for _, entry in pairs(mounted) do
        for _, model in ipairs(entry.models) do
            if model.Parent and model:GetAttribute("OriginalUnderdeckArt") == true then
                n += 1
            end
        end
    end
    return n
end

return PremiumRouteMeshKit
