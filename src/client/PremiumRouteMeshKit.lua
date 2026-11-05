-- True creator-owned imported 3D MeshPart route art. Not Roblox Parts.
-- Authoritative collision, movement, danger notices and game mechanics remain
-- the original server platforms. This module owns ONLY local cosmetic clones.
-- Reuse scenery-lod.client.lua's existing 0.65/0.90s camera/quality sampler;
-- no additional render loop, remote, client asset fetch or studio dependency.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PremiumRoutePbrKit = if script and script.Parent
    and script.Parent:FindFirstChild("PremiumRoutePbrKit")
    then require(script.Parent.PremiumRoutePbrKit)
    else require("./PremiumRoutePbrKit")

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
-- Extend genuine near-camera bridge coverage while preserving hard caps:
-- High at most twelve jump decks + five four-segment bridges and four
-- optional underdeck chassis; Android global Part ledger still owns all of
-- them and existing VFX pressure reduces or disables expensive meshes.
-- No additional source assets, work loops or new physical platforms.
local BUDGET = {
    Low = {decks = 2, bridges = 1, segments = 1, underdecks = 0,
        distance = 100, retention = 18},
    Medium = {decks = 8, bridges = 3, segments = 3, underdecks = 2,
        distance = 195, retention = 22},
    High = {decks = 12, bridges = 5, segments = 4, underdecks = 4,
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
    if entry.restoring then return end
    entry.restoring = true
    PremiumRoutePbrKit.detach(entry)
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    -- Decor is streamed separately from the physical Platforms folder.
    -- These two bounded subscriptions must also be removed on map/LOD exit.
    for _, connection in ipairs(entry.decorConnections or {}) do
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

-- Single local owner for unexpected approved-mesh deletion. The native
-- panel must never remain hidden after its genuine model has vanished.
folder.ChildRemoved:Connect(function(child)
    if not child:IsA("Model") then return end
    for platform, entry in pairs(mounted) do
        if not entry.restoring and table.find(entry.models, child) then
            restore(entry)
            mounted[platform] = nil
        end
    end
end)

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

-- Never mask a physical landing with an incomplete 3D shell.
-- Cache exact approved MeshParts to detect partial streaming/deletion.
local function modelsIntact(entry)
    if entry.restoring or #entry.models == 0
        or type(entry.modelParts) ~= "table" then return false end
    for _, model in ipairs(entry.models) do
        if model.Parent ~= folder then return false end
        local parts = entry.modelParts[model]
        if not parts or #parts == 0 then return false end
        for _, piece in ipairs(parts) do
            if not piece:IsA("MeshPart")
                or not piece:IsDescendantOf(model) then return false end
        end
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

-- Imported models can have their long axis along X *or* Z depending
-- on the approved asset's Roblox import. Rotate genuine mesh copies into
-- the matching REAL physical deck axis, not a guessed rectangular tile.
-- Returns conservative actual bounding-box coverage, never a visual claim
-- that the mesh surface itself is opaque (engine/device QA is still needed).
local function fitSourceToDeck(platform, bounds, segments, isBridge)
    if not platform or not platform:IsA("BasePart")
        or typeof(bounds) ~= "Vector3"
        or bounds.X <= 0 or bounds.Z <= 0
        or bounds.Y <= 0 or segments < 1 then return nil end
    local size = platform.Size
    local longZ = size.Z > size.X
    local longAxis = math.max(size.X, size.Z)
    local narrowAxis = math.min(size.X, size.Z)
    if longAxis <= 0 or narrowAxis <= 0 then return nil end
    if isBridge then
        local sourceLongZ = bounds.Z > bounds.X
        local sourceLength = math.max(bounds.X, bounds.Z)
        local sourceWidth = math.min(bounds.X, bounds.Z)
        local segmentLength = longAxis / segments
        local scale = math.min(
            narrowAxis * 0.94 / sourceWidth,
            segmentLength * 0.985 / sourceLength, 1.16)
        if scale < 0.46 then return nil end
        local longCoverage = sourceLength * scale / segmentLength
        local widthCoverage = sourceWidth * scale / narrowAxis
        return {
            scale = scale,
            yaw = longZ == sourceLongZ and 0 or math.pi * 0.5,
            longCoverage = longCoverage,
            widthCoverage = widthCoverage,
            panelCovered = longCoverage >= 0.95
                and widthCoverage >= 0.82,
        }
    end
    -- Square and unequal jump decks may meet an owner model whose
    -- imported X/Z axes are swapped. Choose whichever places more
    -- creator-original geometry on the physical landing.
    local best = nil
    for _, yaw in ipairs({0, math.pi * 0.5}) do
        local sourceX = yaw == 0 and bounds.X or bounds.Z
        local sourceZ = yaw == 0 and bounds.Z or bounds.X
        local scale = math.min(
            size.X * 0.93 / sourceX,
            size.Z * 0.93 / sourceZ, 1.28)
        if scale >= 0.46 then
            local xCoverage = sourceX * scale / size.X
            local zCoverage = sourceZ * scale / size.Z
            local fit = {
                scale = scale,
                yaw = yaw,
                panelCovered = xCoverage >= 0.85
                    and zCoverage >= 0.85,
                score = math.min(1, xCoverage) * math.min(1, zCoverage),
            }
            if not best or fit.score > best.score then best = fit end
        end
    end
    return best
end

-- Select the MINIMUM genuine module count that can cover an authentic
-- long 3D corridor instead of blindly subdividing by 9.5 studs. The
-- fallback chooses the best real source coverage within Android quota.
local function chooseBridgeSegments(platform, bounds, maxSegments)
    local limit = math.max(1, math.floor(maxSegments or 1))
    local bestCount = nil
    local bestScore = -math.huge
    for n = 1, limit do
        local fit = fitSourceToDeck(platform, bounds, n, true)
        if fit then
            if fit.panelCovered then return n end
            local score = math.min(1, fit.longCoverage) * 0.8
                + math.min(1, fit.widthCoverage) * 0.2 - n * 0.007
            if score > bestScore then
                bestScore = score
                bestCount = n
            end
        end
    end
    return bestCount
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
            -- Reject native primitives disguised as creator-owned route art.
            if not descendant:IsA("MeshPart") then
                clone:Destroy()
                return false
            end
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
        and modelsIntact(entry)
    -- An active collapse/shutter must release optional GPU-heavy 2K
    -- overlays on the SAME server-property event that restores the real
    -- native landing paint; never wait for another 0.65s camera pass.
    if not safe then PremiumRoutePbrKit.detach(entry) end
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
        local desired = (safe and entry.panelCovered)
            and 1 or entry.originalPanelAlpha
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
    local length = math.max(platform.Size.X, platform.Size.Z)
    local countToMount = isBridge and count or 1
    local segment = length / countToMount
    local fit = fitSourceToDeck(platform, bounds, countToMount, isBridge)
    if not fit then return nil end
    local scale = fit.scale
    local entry = {
        models = {},
        connections = {},
        decorConnections = {},
        initialSize = platform.Size,
        count = countToMount,
        bridge = isBridge,
        panel = nil,
        originalPanelAlpha = 0,
        underdeck = underdeckTemplate ~= nil,
        -- The native landing paint is masked ONLY when the owner-approved
        -- model's actual bounding box covers both walkable axes.
        panelCovered = fit.panelCovered,
    }
    local yaw = fit.yaw

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

    -- A Model can remain resident while an internal MeshPart streams
    -- away. Restore the native landing immediately on the first loss,
    -- without allocating an independent frame sampler.
    entry.modelParts = {}
    for _, model in ipairs(entry.models) do
        local parts = {}
        for _, child in ipairs(model:GetDescendants()) do
            if child:IsA("BasePart") then
                if not child:IsA("MeshPart") then
                    restore(entry)
                    return nil
                end
                parts[#parts + 1] = child
            end
        end
        if #parts == 0 then
            restore(entry)
            return nil
        end
        entry.modelParts[model] = parts
        entry.connections[#entry.connections + 1] =
            model.DescendantRemoving:Connect(function(child)
                if not entry.restoring and child:IsA("BasePart") then
                    restore(entry)
                    mounted[platform] = nil
                end
            end)
    end

    local index = tonumber(platform.Name:match("^Platform(%d+)$")
        or platform.Name:match("^Skybridge(%d+)$"))
    local arena = platform.Parent and platform.Parent.Parent
    local decor = nil
    local panelName = index and "PlatformPanel" .. index or nil

    -- The server may stream a live Platforms folder BEFORE Decor. Previously
    -- an approved route shell mounted in this window never acquired its
    -- PlatformPanel owner until the camera happened to evict/reload the mesh.
    -- That left a basic, flat native panel drawn OVER genuine approved art.
    -- Bind the ONE existing panel for this physical route as its folder and
    -- Part arrive, without another poll, model clone or update loop.
    local function ownedPanel(panel)
        if not panelName or not panel or not panel:IsA("BasePart")
            or panel.Name ~= panelName or panel.Parent ~= decor
            or panel.CanCollide or panel.CanTouch or panel.CanQuery then
            return false
        end
        local intended = platform.Position
            + Vector3.new(0, platform.Size.Y * 0.5 + 0.055, 0)
        return (panel.Position - intended).Magnitude <= 0.75
            and math.abs(panel.Size.X - (platform.Size.X - 0.8)) < 1.25
            and math.abs(panel.Size.Z - (platform.Size.Z - 0.8)) < 1.25
    end

    local function releaseNativePanel()
        if entry.panel and entry.panel.Parent then
            entry.panel.LocalTransparencyModifier = entry.originalPanelAlpha
        end
        entry.panel = nil
        entry.originalPanelAlpha = 0
    end

    local function attachNativePanel(panel)
        if not ownedPanel(panel) or entry.panel == panel then return end
        releaseNativePanel()
        entry.panel = panel
        entry.originalPanelAlpha = panel.LocalTransparencyModifier
        syncVisibility(entry, platform)
    end

    local function bindDecor(nextDecor)
        if decor == nextDecor then return end
        -- A streamed folder can be replaced. Disconnect its exact two
        -- subscriptions before acquiring a new folder; no stale masking.
        for _, connection in ipairs(entry.decorConnections) do
            connection:Disconnect()
        end
        table.clear(entry.decorConnections)
        releaseNativePanel()
        decor = nextDecor and nextDecor:IsA("Folder")
            and nextDecor or nil
        if not decor or not panelName then return end
        attachNativePanel(decor:FindFirstChild(panelName))
        entry.decorConnections[#entry.decorConnections + 1] =
            decor.ChildAdded:Connect(function(child)
                if child.Name == panelName then
                    attachNativePanel(child)
                end
            end)
        entry.decorConnections[#entry.decorConnections + 1] =
            decor.ChildRemoved:Connect(function(child)
                if child == entry.panel then
                    releaseNativePanel()
                end
            end)
    end

    -- A panel may stream before its server dimensions/CFrame settle.
    -- Retry its exact ownership check through the ALREADY EXISTING camera
    -- LOD sample instead of leaving native paint in front of 3D forever.
    -- This is also a bounded backstop for streaming folder replacement.
    entry.refreshNativePanel = function()
        if entry.restoring then return end
        local currentDecor = arena and arena:FindFirstChild("Decor")
        if currentDecor ~= decor then bindDecor(currentDecor) end
        if entry.panel and not ownedPanel(entry.panel) then
            releaseNativePanel()
        end
        if decor and not entry.panel then
            attachNativePanel(decor:FindFirstChild(panelName))
        end
        syncVisibility(entry, platform)
    end

    if arena and arena:IsA("Folder") and panelName then
        bindDecor(arena:FindFirstChild("Decor"))
        entry.connections[#entry.connections + 1] =
            arena.ChildAdded:Connect(function(child)
                if child.Name == "Decor" and child:IsA("Folder") then
                    bindDecor(child)
                end
            end)
        entry.connections[#entry.connections + 1] =
            arena.ChildRemoved:Connect(function(child)
                if child == decor then bindDecor(nil) end
            end)
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

-- Only two VERIFIED permanent sky corridors may form a cosmetic joint:
-- adjacent promenade steps in the same lane, adjacent Sky Spine steps,
-- or the H-shaped junction where a physical Sky Spine endpoint actually
-- overlaps the real promenade. NO visual Part ever extends a jump gap.
-- In particular, matching names/indices ALONE cannot manufacture an
-- apparent safe bridge when streaming or a catastrophe removes a deck.
local function routeFamily(platform)
    if platform:GetAttribute("ChaosPermanentRoute") ~= true
        or not platform.Name:match("^Platform%d+$") then
        return nil, nil
    end
    local step = platform:GetAttribute("SkySpineStep")
    if platform:GetAttribute("SkySpineInterchange") == true
        and type(step) == "number" and step % 1 == 0
        and step >= 1 and step <= 10 then
        return "spine", step
    end
    local lane = platform:GetAttribute("PromenadeLane")
    step = platform:GetAttribute("PromenadeStep")
    if type(lane) == "number" and lane % 1 == 0
        and lane >= 1 and lane <= 2
        and type(step) == "number" and step % 1 == 0
        and step >= 1 and step <= 8 then
        return "promenade" .. tostring(lane), step
    end
    return nil, nil
end

local function realRouteJunction(first, second)
    if not first or not second or first == second
        or not first:IsA("BasePart") or not second:IsA("BasePart")
        or not first.Parent or first.Parent ~= second.Parent
        or first.Parent.Name ~= "Platforms"
        or not first.Anchored or not second.Anchored
        or not safePlatform(first) or not safePlatform(second) then
        return false
    end
    local familyA, stepA = routeFamily(first)
    local familyB, stepB = routeFamily(second)
    if not familyA or not familyB then return false end
    local delta = first.CFrame:PointToObjectSpace(second.Position)
    if math.abs(delta.Y) > 0.35 then return false end
    local alongA = first.Size.X >= first.Size.Z
        and first.CFrame.RightVector or first.CFrame.LookVector
    local alongB = second.Size.X >= second.Size.Z
        and second.CFrame.RightVector or second.CFrame.LookVector
    if familyA == familyB then
        if math.abs(stepA-stepB) ~= 1
            or math.abs(alongA:Dot(alongB)) < 0.96 then
            return false
        end
        local isX = first.Size.X >= first.Size.Z
        local forward = math.abs(isX and delta.X or delta.Z)
        local lateral = math.abs(isX and delta.Z or delta.X)
        local lengthA = math.max(first.Size.X, first.Size.Z)
        local lengthB = math.max(second.Size.X, second.Size.Z)
        local gap = forward - (lengthA+lengthB)*0.5
        return gap >= 0.35 and gap <= 4.5
            and lateral <= math.min(
                math.min(first.Size.X,first.Size.Z),
                math.min(second.Size.X,second.Size.Z))*0.25
    end
    -- The only genuine transverse interchange joins the first/last
    -- Sky Spine step to steps 4/5 on either of two sky promenades.
    local spineStep = familyA == "spine" and stepA
        or (familyB == "spine" and stepB or nil)
    local promenadeStep = familyA:match("^promenade") and stepA
        or (familyB:match("^promenade") and stepB or nil)
    if not spineStep or not promenadeStep
        or (spineStep ~= 1 and spineStep ~= 10)
        or (promenadeStep ~= 4 and promenadeStep ~= 5)
        or math.abs(alongA:Dot(alongB)) > 0.20 then
        return false
    end
    -- Exact oriented physical rectangle overlap, not merely arbitrary
    -- proximity or matching metadata on a disconnected high platform.
    local right = first.CFrame.RightVector
    local forward = first.CFrame.LookVector
    local widthX = math.abs(right:Dot(second.CFrame.RightVector))
            * second.Size.X*0.5
        + math.abs(right:Dot(second.CFrame.LookVector))
            * second.Size.Z*0.5
    local widthZ = math.abs(forward:Dot(second.CFrame.RightVector))
            * second.Size.X*0.5
        + math.abs(forward:Dot(second.CFrame.LookVector))
            * second.Size.Z*0.5
    return math.abs(delta.X) <= first.Size.X*0.5 + widthX + 0.25
        and math.abs(delta.Z) <= first.Size.Z*0.5 + widthZ + 0.25
end

-- Exposed for the real-engine geometry regression only. The helper never
-- creates a pathfinding edge, collision, safe platform or client Part.
PremiumRouteMeshKit.realRouteJunction = realRouteJunction

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
    -- hard deck/bridge/segment caps remain enforced per tier.
    local priority = dist - (resident and retention * 0.65 or 0)
    -- Nearest-only sorting used to fill scarce mesh slots with routes
    -- BEHIND the third-person camera. Prefer the next real leap in front,
    -- while keeping a stable landing within 48 studs and retaining every
    -- tier's explicit MeshPart/model quota.
    -- Rotating the camera must not suddenly evict the current landing.
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
function PremiumRouteMeshKit.sync(arena, cameraPoint, quality, cameraReady,
    cameraLook, pressure, touch, pbrDisabled)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local budget = BUDGET[quality] or BUDGET.Low
    local stress = math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    local deckCap, bridgeCap, underdeckCap =
        budget.decks, budget.bridges, budget.underdecks
    -- This is the existing 0.65/0.90-second cosmetic LOD sampler. Under
    -- actual frame pressure, evict optional dense 3D BEFORE lowering
    -- server-owned real routes or hazard warnings (those never change).
    if stress == 1 then
        deckCap = math.max(1,math.ceil(deckCap*.68))
        bridgeCap = math.max(0,math.floor(bridgeCap*.70))
        underdeckCap = math.floor(underdeckCap*.50)
    elseif stress == 2 then
        deckCap = math.max(1,math.ceil(deckCap*.38))
        bridgeCap = 0
        underdeckCap = 0
    end
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
        -- Near-camera quota should buy COMPLETE authentic source coverage,
        -- not reserve slots for early native rectangles whose footprint
        -- cannot fit the approved sculpted jump-deck import. Preflight the
        -- same exact imported bounds the mount uses; prefer covers that can
        -- actually retire the original flat PlatformPanel. No extra models,
        -- new assets, rendering loop or physical platform changes.
        local _, deckBounds = deckTemplate:GetBoundingBox()
        local fittedDecks = {}
        for _, item in ipairs(decks) do
            local fit = fitSourceToDeck(item.platform, deckBounds, 1, false)
            if fit then
                fittedDecks[#fittedDecks + 1] = {
                    item = item,
                    -- Local 3D shells with incomplete two-axis coverage
                    -- remain eligible only AFTER comparably near full fits.
                    score = item.priority + (fit.panelCovered and 0 or 48),
                }
            end
        end
        table.sort(fittedDecks, function(a, b)
            if a.score ~= b.score then return a.score < b.score end
            if a.item.distance ~= b.item.distance then
                return a.item.distance < b.item.distance
            end
            return a.item.platform.Name < b.item.platform.Name
        end)
        for i = 1, math.min(#fittedDecks, deckCap) do
            local platform = fittedDecks[i].item.platform
            wanted[platform] = {template = deckTemplate, count = 1,
                bridge = false}
        end
    end
    if bridgeTemplate then
        local _, sourceBox = bridgeTemplate:GetBoundingBox()
        local qualified = {}
        for _, item in ipairs(bridges) do
            local count = chooseBridgeSegments(
                item.platform, sourceBox, budget.segments)
            local fit = count and fitSourceToDeck(
                item.platform, sourceBox, count, true)
            -- A tiny fragment on a narrow Towers gate never becomes a
            -- bogus 3D bridge, even if it is near the camera.
            if fit and fit.longCoverage >= 0.68
                and fit.widthCoverage >= 0.65 then
                qualified[#qualified + 1] = {item = item, count = count}
            end
        end
        local selected = {}
        -- A per-deck nearest-only ranking can alternate expensive 3D
        -- and native boxes along one HIGHLY visible H-shaped sky route.
        -- Once the nearest real deck is chosen, prefer its physically
        -- adjacent approved neighbours. Never sacrifice hard slot caps.
        for _ = 1, math.min(bridgeCap, #qualified) do
            local best, bestScore = nil, math.huge
            for _, candidate in ipairs(qualified) do
                if not candidate.selected then
                    local score = candidate.item.priority
                    for _, previous in ipairs(selected) do
                        if realRouteJunction(
                            candidate.item.platform, previous.item.platform) then
                            score -= 38
                            break
                        end
                    end
                    if score < bestScore or (score == bestScore and best
                        and candidate.item.platform.Name
                            < best.item.platform.Name) then
                        best = candidate
                        bestScore = score
                    end
                end
            end
            if not best then break end
            best.selected = true
            selected[#selected + 1] = best
            wanted[best.item.platform] = {
                template = bridgeTemplate,
                count = best.count,
                bridge = true,
            }
        end
    end

    -- A 3K-triangle hollow chassis is genuinely useful on long visible
    -- sky route foundations; never attach it to every streamed platform.
    -- The existing 0/2/4 UNDERDECK MODEL quota is additional but stays
    -- inside the SAME PremiumRouteMeshLocal adaptive Android Parts ledger.
    -- Prefer eligible real 26-stud connector routes, then large safe decks.
    local underdeckTemplate = getTemplate("OriginalUnderdeckChassis")
    local underdeckSlots = underdeckCap
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
                and math.min(size.X, size.Z) >= 9.5
                and item.platform:GetAttribute(
                    "LocalOriginalLongCradleMounted") ~= true then
                -- One approved open-frame model already provides this
                -- nonphysical undercarriage. Avoid stacking a second
                -- 3K-triangle approved chassis underneath the same deck.
                wanted[item.platform].underdeck = underdeckTemplate
                underdeckSlots -= 1
            end
        end
    end

    for platform, entry in pairs(mounted) do
        local desired = wanted[platform]
        if not desired or desired.count ~= entry.count
            or (desired.underdeck ~= nil) ~= entry.underdeck
            or not modelsIntact(entry) then
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
    -- Late-streamed panel/geometry alignment is reconciled by this SAME
    -- 0.65/0.90-second camera owner; no extra heartbeat or per-Part polling.
    for platform, entry in pairs(mounted) do
        if entry.refreshNativePanel then entry.refreshNativePanel() end
    end
    -- Give the nearest REAL contiguous bridge one coherent 2K PBR finish,
    -- not just its first segment. Healthy desktop can keep two; Android
    -- gets at most one and releases it first under pressure. Source
    -- imported GRIP/CARBON/SIGNAL parts are deliberately left intact.
    local pbrSlots = PremiumRoutePbrKit.entryBudget(
        quality, pressure, touch, pbrDisabled)
    local pbrSelected = {}
    for _, item in ipairs(bridges) do
        if pbrSlots <= 0 then break end
        local entry = mounted[item.platform]
        if entry and entry.panelCovered
            and wanted[item.platform]
            and wanted[item.platform].template == bridgeTemplate then
            pbrSelected[item.platform] = true
            pbrSlots -= 1
        end
    end
    local variant = arena:GetAttribute("VariantId")
    for platform, entry in pairs(mounted) do
        PremiumRoutePbrKit.apply(entry, "route", variant,
            pbrSelected[platform] == true and safePlatform(
                platform, entry.initialSize))
    end
end

function PremiumRouteMeshKit.count()
    local n = 0
    for _, entry in pairs(mounted) do
        n += #entry.models
    end
    return n
end

-- Diagnostic only: count real attached 2K appearance instances on
-- authenticated near-camera models, not loaded textures or FPS.
-- Number of REAL physical adjacent route pairs where BOTH approved
-- 3D skins actually exist and the authoritative collision remains safe.
-- This measures visual continuity, not guaranteed crossing or jump AI.
function PremiumRouteMeshKit.connectedPairsCount()
    local platforms = {}
    for platform, entry in pairs(mounted) do
        if entry.bridge and entry.models[1]
            and entry.models[1].Parent == folder
            and safePlatform(platform, entry.initialSize) then
            platforms[#platforms + 1] = platform
        end
    end
    local pairsCount = 0
    for i = 1, #platforms do
        for j = i + 1, #platforms do
            if realRouteJunction(platforms[i], platforms[j]) then
                pairsCount += 1
            end
        end
    end
    return pairsCount
end

function PremiumRouteMeshKit.pbrCount()
    local models, appearances = 0, 0
    for _, entry in pairs(mounted) do
        local n, m = PremiumRoutePbrKit.count(entry)
        models += n
        appearances += m
    end
    return models, appearances
end

-- Diagnostics count REAL imported additional Model instances (not a
-- pretended on-device screenshot or guessed complete texture residency).
-- Pure footprint contract, also exercised in real Roblox Engine on actual
-- Part / Vector3 instances at the major graphical milestone.
function PremiumRouteMeshKit.sourceFit(platform, sourceBounds, count, bridge)
    return fitSourceToDeck(platform, sourceBounds, count, bridge)
end

function PremiumRouteMeshKit.bridgeSegmentCount(platform, sourceBounds, cap)
    return chooseBridgeSegments(platform, sourceBounds, cap)
end

-- Counts actually installed owner-verified top-cover replacements, not
-- surfaces we merely WANTED to replace. Diagnostic only, never collision.
function PremiumRouteMeshKit.coveredPanelCount()
    local count = 0
    for platform, entry in pairs(mounted) do
        if entry.panel and entry.panel.Parent
            and entry.panelCovered
            and safePlatform(platform, entry.initialSize)
            and entry.panel.LocalTransparencyModifier == 1 then
            count += 1
        end
    end
    return count
end

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
