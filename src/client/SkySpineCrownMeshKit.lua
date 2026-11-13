-- Original, creator-owned UV/tangent sky interchange sculpture, Roblox
-- Approved Model #71492051540032. All four real Sky Spine gateway decks
-- (steps 2, 5, 6 and 9) qualify; never creates a walkway or collision.
-- Reuses the existing scenery-lod.client.lua camera/quality owner and budget.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PremiumRoutePbrKit = if script and script.Parent
    and script.Parent:FindFirstChild("PremiumRoutePbrKit")
    then require(script.Parent.PremiumRoutePbrKit)
    else require("./PremiumRoutePbrKit")

local Kit = {}
local ASSET_ID = 71492051540032
local BUDGET = {
    -- Low Android now shows one approved crown at 122 studs.
    -- The authentic near-camera sculpture shares the main visual census.
    Low = {count = 1, distance = 122, retention = 14},
    Medium = {count = 2, distance = 175, retention = 22},
    High = {count = 4, distance = 245, retention = 28},
}
local ORIGINAL_NATIVE = {
    ["MonumentalPylon-1"] = true,
    ["MonumentalPylon1"] = true,
    ["SignalInlay-1"] = true,
    ["SignalInlay1"] = true,
    InterchangeCrown = true,
    OverheadPulse = true,
    CommandRadar = true,
    SurveyBeacon = true,
    CargoOverpass = true,
    HangingTransitCabin = true,
    ["RoutingAileron-1"] = true,
    RoutingAileron1 = true,
    OrbitalPowerOrb = true,
    OrbitRing = true,
    DryDockHighCrane = true,
    CableLift = true,
    FreightPod = true,
}

local folder = Instance.new("Folder")
folder.Name = "OriginalSkySpineCrownLocal"
folder.Parent = workspace
local activeArena = nil
local watchedBase = nil
local baseChanged = nil
local mounted = {}
-- Until the existing RoundState controller reports Darkness, optional
-- decorative lights fail closed. No independent gameplay-state reader.
local darknessGuard = true

function Kit.lightBudget(tier, pressure, touch)
    if tier ~= "High" and tier ~= "Medium" then return 0 end
    local value = tonumber(pressure)
    local stress = if value and value == value
        then math.clamp(math.floor(value), 0, 2) else 0
    if stress > 0 then return 0 end
    if tier == "Medium" then return 1 end
    return touch == true and 1 or 2
end

local function source()
    local templates = ReplicatedStorage:FindFirstChild("PremiumRouteMeshTemplates")
    if not templates or templates:GetAttribute("OwnerVerified") ~= true then
        return nil
    end
    local model = templates:FindFirstChild("OriginalSkySpineCrown")
    if not model or not model:IsA("Model")
        or model.Parent ~= templates
        or model:GetAttribute("OwnerVerified") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true
        or model:GetAttribute("PremiumSkySpineCrown3D") ~= true
        or model:GetAttribute("Original3DAssetId") ~= ASSET_ID then
        return nil
    end
    local n = 0
    for _, piece in ipairs(model:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then return nil end
            n += 1
        elseif piece:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if n < 1 or n > 12 then return nil end
    local _, size = model:GetBoundingBox()
    if math.max(size.X, size.Z) < 17 or math.max(size.X, size.Z) > 21
        or math.min(size.X, size.Z) < 3 or math.min(size.X, size.Z) > 7
        or size.Y < 19 or size.Y > 23 then
        return nil
    end
    return model
end

-- A genuine Sky Spine entrance is welded to a server-authored
-- RouteTier deck. ShrinkingArena scales that REAL deck in horizontal X/Z,
-- and the nonphysical upper sculpture must follow it without pretending
-- the old full-width bridge still exists.
local function realFloorScale(base, arena)
    local generated=workspace:FindFirstChild("GeneratedMap")
    if not arena or arena.Name~="Arena"
        or not generated or arena.Parent~=generated
        or not base or not base:IsA("BasePart") or base.Parent~=arena
        or not base.Anchored or not base.CanCollide then return nil end
    local sx=base:GetAttribute("OriginalSizeX")
    local sz=base:GetAttribute("OriginalSizeZ")
    if typeof(sx)~="number" or typeof(sz)~="number"
        or sx~=sx or sz~=sz or sx<318 or sz<318
        or sx>=math.huge or sz>=math.huge then return nil end
    local x,z=base.Size.X/sx,base.Size.Z/sz
    if x<.445 or x>1.005 or z<.445 or z>1.005
        or math.abs(x-z)>.012 then return nil end
    return math.min(x,z)
end

local function authentic(deck, arena, base)
    local scale=realFloorScale(base, arena)
    if not scale or not deck or not deck:IsA("BasePart")
        or deck.Parent ~= arena:FindFirstChild("Platforms")
        or not deck.Name:match("^Platform%d+$")
        or deck:GetAttribute("ChaosPermanentRoute") ~= true
        or deck:GetAttribute("SkySpineInterchange") ~= true
        or type(deck:GetAttribute("RouteTier")) ~= "number"
        or not deck.Anchored or not deck.CanCollide
        or deck.Transparency >= 0.75
        or math.abs(deck.Size.X / scale - 12) > 0.22
        or deck.Size.Y < 1.8 or deck.Size.Y > 2.2
        or deck.Size.Z / scale < 14.3
        or deck.Size.Z / scale > 33.2 then
        return false
    end
    local step = deck:GetAttribute("SkySpineStep")
    if step ~= 2 and step ~= 5 and step ~= 6 and step ~= 9 then
        return false
    end
    local collapse = deck:GetAttribute("CollapsePhase")
    if collapse ~= nil and collapse ~= "Normal" and collapse ~= "Safe" then
        return false
    end
    local shutter = deck:GetAttribute("BridgeShutterPhase")
    if shutter ~= nil and shutter ~= "Idle" then return false end
    return true
end

local function isOriginalUpperPart(piece, deck)
    local index = deck.Name:match("^Platform(%d+)$")
    if not index or not piece:IsA("BasePart")
        or piece:GetAttribute("SkySpineDecor") ~= true
        or piece:GetAttribute("PerimeterPlatformIndex") ~= tonumber(index) then
        return false
    end
    local suffix = piece.Name:match("^SkySpine" .. index .. "_(.+)$")
    return suffix ~= nil and ORIGINAL_NATIVE[suffix] == true
end

local function originalUpperParts(decor, deck)
    local upper = {}
    if not decor then return upper end
    for _, piece in ipairs(decor:GetChildren()) do
        if isOriginalUpperPart(piece, deck) then
            upper[#upper + 1] = piece
        end
    end
    return upper
end

local function safeAfterMount(entry)
    -- A streamed or externally removed ONE-piece crown is not a complete
    -- approved original. Leaving the surviving MeshParts visible would keep
    -- the native Sky Spine portico hidden behind a broken 3D silhouette.
    -- Check the same exact source pieces and cosmetic welds on every
    -- event-driven fallback, PBR/light decision, and existing LOD sample.
    if entry.restoring or not entry.model
        or entry.model.Parent ~= folder
        or entry.arena ~= activeArena
        or not authentic(entry.deck, entry.arena, entry.base)
        or not entry.pieces or #entry.pieces < 1
        or #entry.pieces > 12 then
        return false
    end
    for _, piece in ipairs(entry.pieces) do
        if not piece:IsA("MeshPart")
            or not piece:IsDescendantOf(entry.model)
            or piece.Anchored or not piece.Massless
            or piece.CanCollide or piece.CanTouch or piece.CanQuery then
            return false
        end
        local joint = entry.joints and entry.joints[piece]
        if not joint or joint.Parent ~= piece
            or joint.Part0 ~= entry.deck or joint.Part1 ~= piece
            or not entry.frames[piece] or not entry.sizes[piece] then
            return false
        end
    end
    return true
end

local function refreshLight(entry)
    local light = entry.signalLight
    if not light then return end
    if not light.Parent or not light.Parent:IsA("MeshPart")
        or not light.Parent:IsDescendantOf(entry.model) then
        entry.signalLight = nil
        return
    end
    light.Enabled = not darknessGuard and entry.signalLightRequested == true
        and safeAfterMount(entry)
end

local function sourceSignal(entry)
    for _, part in ipairs(entry.pieces) do
        if part:IsA("MeshPart") and part:IsDescendantOf(entry.model)
            and string.find(string.upper(part.Name), "SIGNAL", 1, true) then
            return part
        end
    end
    return nil
end

local function setSignalLight(entry, requested)
    entry.signalLightRequested = requested == true
    if not requested then
        if entry.signalLight then entry.signalLight:Destroy() end
        entry.signalLight = nil
        return
    end
    if not entry.signalLight or not entry.signalLight.Parent then
        local signal = sourceSignal(entry)
        if not signal or not safeAfterMount(entry) then return end
        local light = Instance.new("PointLight")
        light.Name = "OriginalSkySpineSignalFill"
        light.Color = Color3.fromRGB(212, 230, 238)
        light.Brightness = 0.31
        light.Range = 17
        light.Shadows = false
        light.Enabled = false
        light.Parent = signal
        entry.signalLight = light
    end
    refreshLight(entry)
end

function Kit.setDarknessGuard(active)
    darknessGuard = active == true
    for _, entry in pairs(mounted) do refreshLight(entry) end
end

-- Only the cosmetic MeshParts follow the shrinking deck. Their Y
-- heights remain original, matching ShrinkingArena's x/z-only resizing of
-- server-owned nonphysical upper details. The adjustable local Weld does
-- not move or resize the actual anchored gameplay platform.
local function refit(entry)
    if not safeAfterMount(entry) then return false end
    local scale=realFloorScale(entry.base, entry.arena)
    if not scale then return false end
    for _, piece in ipairs(entry.pieces) do
        local weld=entry.joints[piece]
        if not weld or weld.Parent~=piece or weld.Part0~=entry.deck
            or weld.Part1~=piece or not entry.frames[piece]
            or not entry.sizes[piece] then return false end
    end
    if entry.lastScale and math.abs(entry.lastScale-scale)<.008 then
        return true
    end
    for _, piece in ipairs(entry.pieces) do
        local frame=entry.frames[piece]
        local original=entry.sizes[piece]
        piece.Size=Vector3.new(original.X*scale,
            original.Y,original.Z*scale)
        entry.joints[piece].C0=CFrame.new(
            frame.Position.X*scale,frame.Position.Y,
            frame.Position.Z*scale)*(frame-frame.Position)
    end
    entry.lastScale=scale
    return true
end

local function updateVisibility(entry)
    local visible = refit(entry)
    if not visible then PremiumRoutePbrKit.detach(entry) end
    refreshLight(entry)
    for _, part in ipairs(entry.pieces) do
        if part.Parent then
            part.LocalTransparencyModifier = visible and 0 or 1
        end
    end
    for _, saved in ipairs(entry.native) do
        if saved.part.Parent then
            saved.part.LocalTransparencyModifier =
                visible and 1 or saved.original
        end
    end
end

local function restore(entry)
    if entry.restoring then return end
    entry.restoring = true
    setSignalLight(entry, false)
    PremiumRoutePbrKit.detach(entry)
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    for _, saved in ipairs(entry.native) do
        if saved.part.Parent then
            saved.part.LocalTransparencyModifier = saved.original
        end
    end
    entry.model:Destroy()
end

-- A genuine imported Model that streams out between camera samples must
-- reveal its server-authored portico instantly. One folder observer; no
-- new per-frame owner, networking, fake collider or render polling.
folder.ChildRemoved:Connect(function(child)
    if not child:IsA("Model") then return end
    for deck, entry in pairs(mounted) do
        if not entry.restoring and child == entry.model then
            restore(entry)
            mounted[deck] = nil
        end
    end
end)

local function clearModels()
    for deck, entry in pairs(mounted) do
        restore(entry)
        mounted[deck] = nil
    end
end

local function clear()
    clearModels()
    if baseChanged then baseChanged:Disconnect() end
    baseChanged = nil
    watchedBase = nil
    activeArena = nil
    folder:ClearAllChildren()
end

local function mount(deck, arena, base, decor, template)
    local clone = template:Clone()
    local frame, bounds = clone:GetBoundingBox()
    local yaw = bounds.X < bounds.Z and math.pi * 0.5 or 0
    local target = deck.CFrame
        * CFrame.new(0, deck.Size.Y * 0.5 + bounds.Y * 0.5 + 0.02, 0)
        * CFrame.Angles(0, yaw, 0)
    local pieces = {}
    for _, piece in ipairs(clone:GetDescendants()) do
        if piece:IsA("BasePart") then
            if not piece:IsA("MeshPart") then
                clone:Destroy()
                return nil
            end
            piece.CFrame = target * frame:ToObjectSpace(piece.CFrame)
            piece.Anchored = false
            piece.Massless = true
            piece.CanCollide = false
            piece.CanTouch = false
            piece.CanQuery = false
            piece.CastShadow = false
            pieces[#pieces + 1] = piece
        end
    end
    if #pieces < 1 or #pieces > 12 then
        clone:Destroy()
        return nil
    end
    local entry = {
        deck = deck, arena = arena, base = base,
        model = clone, pieces = pieces, native = {}, connections = {},
        joints = {}, frames = {}, sizes = {}, lastScale = nil,
    }
    local knownNative = {}
    local function watchNative(part)
        -- StreamingEnabled may replicate the real server crown AFTER the
        -- approved mesh was mounted. Never show overlapping native blocks
        -- above the new sculpted 3D silhouette on a late streaming packet.
        if knownNative[part] or not isOriginalUpperPart(part, deck) then
            return
        end
        knownNative[part] = true
        entry.native[#entry.native + 1] = {
            part = part, original = part.LocalTransparencyModifier,
        }
        if entry.model.Parent == folder and safeAfterMount(entry) then
            part.LocalTransparencyModifier = 1
        end
    end
    for _, part in ipairs(originalUpperParts(decor, deck)) do
        watchNative(part)
    end
    clone.Name = "OriginalApprovedSkySpineCrown3D"
    clone:SetAttribute("CosmeticOnly", true)
    clone:SetAttribute("Original3DAssetId", ASSET_ID)
    clone:SetAttribute("OriginalSkySpineStep", deck:GetAttribute("SkySpineStep"))
    clone:SetAttribute("OriginalSkySpinePlatform", deck.Name)
    clone.Parent = folder
    for _, piece in ipairs(pieces) do
        local joint = Instance.new("Weld")
        joint.Name = "SkySpineCrownCosmeticWeld"
        joint.Part0 = deck
        joint.Part1 = piece
        joint.C0 = deck.CFrame:ToObjectSpace(piece.CFrame)
        joint.C1 = CFrame.identity
        joint.Parent = piece
        entry.joints[piece] = joint
        entry.frames[piece] = deck.CFrame:ToObjectSpace(piece.CFrame)
        entry.sizes[piece] = piece.Size
    end
    local function changed()
        -- Live deck scaling adjusts authentic 3D at its Size event.
        -- A collapse/stream hazard reveals original 2D immediately.
        updateVisibility(entry)
    end
    for _, property in ipairs({"Size", "CanCollide", "Transparency",
        "Anchored"}) do
        entry.connections[#entry.connections + 1] =
            deck:GetPropertyChangedSignal(property):Connect(changed)
    end
    for _, attribute in ipairs({"CollapsePhase", "BridgeShutterPhase",
        "ChaosPermanentRoute", "SkySpineStep", "SkySpineInterchange",
        "RouteTier"}) do
        entry.connections[#entry.connections + 1] =
            deck:GetAttributeChangedSignal(attribute):Connect(changed)
    end
    entry.connections[#entry.connections + 1] =
        deck.AncestryChanged:Connect(changed)
    entry.connections[#entry.connections + 1] =
        decor.ChildAdded:Connect(watchNative)
    -- DescendantRemoving fires BEFORE the MeshPart leaves its Model.
    -- Re-evaluate on defer so the original, nonphysical portico is revealed
    -- immediately after a partial StreamingEnabled loss, not after the
    -- next 0.65/0.90-second scenery residency sample.
    entry.connections[#entry.connections + 1] =
        clone.DescendantRemoving:Connect(function(child)
            if not entry.restoring and child:IsA("MeshPart")
                and table.find(entry.pieces, child) then
                task.defer(function()
                    if not entry.restoring then updateVisibility(entry) end
                end)
            end
        end)
    updateVisibility(entry)
    return entry
end

-- The ONLY invocation is the shared camera/quality sampler, not a new loop.
function Kit.sync(arena, cameraPoint, tier, cameraReady, cameraLook,
    pressure, touch, pbrDisabled)
    if arena ~= activeArena then
        clear()
        activeArena = arena
    end
    local budget = BUDGET[tier] or BUDGET.Low
    local stress = math.clamp(math.floor(tonumber(pressure) or 0), 0, 2)
    local limit = budget.count
    -- Optional approved 3D yields to actual Android pressure BEFORE any
    -- native gameplay platform, hazard line or collision is affected.
    if tier == "High" then
        limit = stress == 0 and 4 or (stress == 1 and 2 or 1)
    elseif tier == "Medium" then
        limit = stress == 0 and 2 or (stress == 1 and 1 or 0)
    elseif tier == "Low" and stress >= 2 then
        limit = 0
    end
    if not arena or not cameraReady or limit == 0
        or typeof(cameraPoint) ~= "Vector3" then
        clearModels()
        return
    end
    local base = arena:FindFirstChild("Base")
    local platforms = arena:FindFirstChild("Platforms")
    local decor = arena:FindFirstChild("Decor")
    if not platforms or not platforms:IsA("Folder")
        or not decor or not decor:IsA("Folder")
        or not realFloorScale(base, arena) then
        clearModels()
        return
    end
    if watchedBase ~= base then
        if baseChanged then baseChanged:Disconnect() end
        watchedBase = base
        baseChanged = base:GetPropertyChangedSignal("Size"):Connect(function()
            if not realFloorScale(base, arena) then clearModels() end
        end)
    end
    local template = source()
    if not template then
        clearModels()
        return
    end
    local choices = {}
    for _, deck in ipairs(platforms:GetChildren()) do
        if authentic(deck, arena, base) then
            local dist = (cameraPoint - deck.Position).Magnitude
            local resident = mounted[deck] ~= nil
            if dist <= budget.distance + (resident and budget.retention or 0) then
                local priority = dist - (resident and budget.retention * 0.6 or 0)
                if typeof(cameraLook) == "Vector3" and cameraLook.Magnitude > 0.5
                    and dist > 40 then
                    local direction = (deck.Position - cameraPoint).Unit
                    local facing = direction:Dot(cameraLook.Unit)
                    priority -= math.min(32, dist * 0.18) * facing
                end
                choices[#choices + 1] = {deck = deck, score = priority}
            end
        end
    end
    table.sort(choices, function(a, b)
        if a.score == b.score then return a.deck.Name < b.deck.Name end
        return a.score < b.score
    end)
    local wanted = {}
    for i = 1, math.min(#choices, limit) do
        wanted[choices[i].deck] = true
    end
    for deck, entry in pairs(mounted) do
        if not wanted[deck] or not safeAfterMount(entry) then
            restore(entry)
            mounted[deck] = nil
        else
            updateVisibility(entry)
        end
    end
    for deck in pairs(wanted) do
        if not mounted[deck] then
            mounted[deck] = mount(deck, arena, base, decor, template)
        end
    end
    local slots = PremiumRoutePbrKit.entryBudget(
        tier, pressure, touch, pbrDisabled)
    local textured = {}
    for _, choice in ipairs(choices) do
        if slots <= 0 then break end
        if mounted[choice.deck] and wanted[choice.deck] then
            textured[choice.deck] = true
            slots -= 1
        end
    end
    local variant = arena:GetAttribute("VariantId")
    for deck, entry in pairs(mounted) do
        PremiumRoutePbrKit.apply(entry, "crown", variant,
            textured[deck] == true and safeAfterMount(entry))
    end

    -- Only real, nearby model SIGNAL regions receive a local lamp.
    -- Low or pressure >= 1 is free of added GPU lights.
    local lightSlots = Kit.lightBudget(tier, pressure, touch)
    local illuminated = {}
    for _, choice in ipairs(choices) do
        if lightSlots <= 0 then break end
        local entry = mounted[choice.deck]
        if entry and wanted[choice.deck] and sourceSignal(entry)
            and safeAfterMount(entry) then
            illuminated[choice.deck] = true
            lightSlots -= 1
        end
    end
    for deck, entry in pairs(mounted) do
        setSignalLight(entry, illuminated[deck] == true)
    end
end

function Kit.lightCount()
    local n = 0
    for _, entry in pairs(mounted) do
        if entry.signalLight and entry.signalLight.Parent
            and entry.signalLight.Enabled and safeAfterMount(entry) then
            n += 1
        end
    end
    return n
end

function Kit.pbrCount()
    local models, appearances = 0, 0
    for _, entry in pairs(mounted) do
        if safeAfterMount(entry) then
            local n, m = PremiumRoutePbrKit.count(entry)
            models += n
            appearances += m
        end
    end
    return models, appearances
end

function Kit.count()
    local count = 0
    for _, entry in pairs(mounted) do
        if safeAfterMount(entry) then count += 1 end
    end
    return count
end

-- Count the TWO formerly rectangular outer porticos only if their
-- authentic MeshParts are still in the active camera owner and safe.
function Kit.outerCount()
    local count = 0
    for deck, entry in pairs(mounted) do
        local step = deck:GetAttribute("SkySpineStep")
        if entry.model.Parent == folder and safeAfterMount(entry)
            and (step == 2 or step == 9) then
            count += 1
        end
    end
    return count
end

return Kit
