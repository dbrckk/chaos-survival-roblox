local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)
local ArenaPresentation = require(ReplicatedStorage.Shared.ArenaPresentation)
local ArenaFloorFollowerKit = require(script.Parent.ArenaFloorFollowerKit)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "ArenaNavigationLanguageLocal"
folder.Parent = workspace

local dynamicIndicators = {}
local perimeterGuides = {}
local stopCenterFollowing = nil
local shrinkingActive = false
local rootConnection = nil
local arenaAddedConnection = nil
local arenaRemovedConnection = nil

local function clear()
    if stopCenterFollowing then
        stopCenterFollowing()
        stopCenterFollowing = nil
    end
    folder:ClearAllChildren()
    table.clear(dynamicIndicators)
    table.clear(perimeterGuides)
end

local function makePart(name, size, cframe, color, material, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = material
    part.Color = color
    part.Transparency = transparency
    part.Parent = folder
    return part
end

local function padImpulse(pad)
    return Vector3.new(
        tonumber(pad:GetAttribute("ImpulseX")) or 0,
        tonumber(pad:GetAttribute("ImpulseY")) or 0,
        tonumber(pad:GetAttribute("ImpulseZ")) or 0
    )
end

local function flattenedUnit(v)
    local flat = Vector3.new(v.X, 0, v.Z)
    if flat.Magnitude < 0.01 then
        return Vector3.zero
    end
    return flat.Unit
end

local function addGroundChevron(position, direction, color, alpha, index)
    if direction.Magnitude < 0.01 then
        return
    end

    local yaw = math.atan2(-direction.X, -direction.Z)
    local lateral = Vector3.new(direction.Z, 0, -direction.X)
    local back = -direction

    local left = position + back * 0.65 - lateral * 0.58
    local right = position + back * 0.65 + lateral * 0.58

    local leftPart = makePart(
        "RouteChevronL" .. index,
        Vector3.new(1.7, 0.05, 0.18),
        CFrame.new(left) * CFrame.Angles(0, yaw + math.rad(38), 0),
        color,
        Enum.Material.Neon,
        alpha
    )

    local rightPart = makePart(
        "RouteChevronR" .. index,
        Vector3.new(1.7, 0.05, 0.18),
        CFrame.new(right) * CFrame.Angles(0, yaw - math.rad(38), 0),
        color,
        Enum.Material.Neon,
        alpha
    )

    return leftPart, rightPart
end

local function addVerticalBeacon(pad, color, tier, index)
    local height = tier.Name == "High" and 7.5 or 5.2
    local beam = makePart(
        "VerticalRouteBeacon" .. index,
        Vector3.new(0.18, height, 0.18),
        CFrame.new(pad.Position + Vector3.new(0, height * 0.5 + 0.4, 0)),
        color,
        Enum.Material.Neon,
        tier.Name == "High" and 0.48 or 0.62
    )
    beam:SetAttribute("NavBaseTransparency", beam.Transparency)

    local cap = makePart(
        "VerticalRouteCap" .. index,
        Vector3.new(1.35, 0.10, 1.35),
        CFrame.new(pad.Position + Vector3.new(0, height + 0.4, 0)),
        color:Lerp(Color3.new(1, 1, 1), 0.28),
        Enum.Material.Neon,
        tier.Name == "High" and 0.36 or 0.52
    )

    return beam, cap, height
end

local function addCenterLandmark(base, theme, variant, tier)
    -- These center-route glyphs were hidden inside the server ArenaDeckInset.
    -- Place thin local lines just above its real top face.
    local center = (base.CFrame * CFrame.new(
        0, ArenaPresentation.deckArtOffset(base, 0.05), 0
    )).Position
    local span = math.min(base.Size.X, base.Size.Z)

    if variant == "Orbital" then
        local segments = tier.Name == "High" and 12 or 8
        local radius = span * 0.12
        for i = 1, segments do
            local angle = ((i - 1) / segments) * math.pi * 2
            local tangent = angle + math.pi * 0.5
            local pos = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
            makePart(
                "CenterOrbitMark" .. i,
                Vector3.new(2.6, 0.05, 0.16),
                CFrame.new(pos) * CFrame.Angles(0, -tangent, 0),
                i % 4 == 0 and theme.Secondary or (i % 3 == 0 and theme.Accent or theme.Detail),
                i % 3 == 0 and Enum.Material.Neon or Enum.Material.Metal,
                i % 3 == 0 and 0.66 or 0.30
            )
        end
    elseif variant == "Crossroads" then
        local arm = span * 0.18
        makePart(
            "CenterCrossX",
            Vector3.new(arm, 0.05, 0.22),
            CFrame.new(center),
            theme.Accent,
            Enum.Material.Neon,
            0.66
        )
        makePart(
            "CenterCrossZ",
            Vector3.new(0.22, 0.05, arm),
            CFrame.new(center),
            theme.Detail,
            Enum.Material.Metal,
            0.26
        )
    elseif variant == "Towers" then
        local radius = span * 0.10
        for i = 1, 4 do
            local angle = math.rad(45 + (i - 1) * 90)
            local pos = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
            makePart(
                "CenterTowerAnchor" .. i,
                Vector3.new(1.6, 0.05, 1.6),
                CFrame.new(pos) * CFrame.Angles(0, -angle, 0),
                i == 1 and theme.Accent or theme.Detail,
                i == 1 and Enum.Material.Neon or Enum.Material.Metal,
                i == 1 and 0.64 or 0.24
            )
        end
    elseif variant == "Harbor" then
        -- Harbor had silently inherited Classic's crossed calibration
        -- grid. Two separated short dock-berth index marks communicate
        -- port infrastructure without implying a glowing walkable path.
        -- Same two-part allocation as Classic, within the true Base
        -- footprint; ArenaFloorFollowerKit keeps both attached during
        -- Shrinking Arena and no new path or collider is created.
        for side = -1, 1, 2 do
            makePart(
                side == -1 and "CenterHarborPortBerth"
                    or "CenterHarborStarboardBerth",
                Vector3.new(0.24, 0.05, span * 0.14),
                base.CFrame * CFrame.new(
                    side * span * 0.092,
                    ArenaPresentation.deckArtOffset(base, 0.05),
                    0),
                side == -1 and theme.Detail or theme.Secondary,
                Enum.Material.CorrodedMetal,
                side == -1 and 0.24 or 0.30
            )
        end
    else
        local half = span * 0.11
        makePart(
            "CenterGridX",
            Vector3.new(half * 2, 0.05, 0.18),
            CFrame.new(center),
            theme.Accent,
            Enum.Material.Neon,
            0.66
        )
        makePart(
            "CenterGridZ",
            Vector3.new(0.18, 0.05, half * 2),
            CFrame.new(center),
            theme.Detail,
            Enum.Material.Metal,
            0.28
        )
    end
end

-- Physical first steps are discoverable on every map, but the old
-- wayfinding covered only optional boost pads and the center sigil.
-- Paint short nonblocking arrows from the safe floor toward all FOUR
-- actual entry terraces. No fake directions, user-tracking raycasts or
-- per-frame work. Names use Center* so the existing floor-follow system
-- retracts them during Shrinking Arena (never floating beyond its edge).
local function routeEntrySafe(target, platforms, routeId)
    if not target or target.Parent ~= platforms
        or not CollectionService:HasTag(target, "ChaosPerimeterEntry")
        or target:GetAttribute("PerimeterStep") ~= 1
        or tonumber(target:GetAttribute("PerimeterRoute")) ~= routeId
        or not target:IsA("BasePart") or not target.Anchored
        or not target.CanCollide or target.Transparency >= 0.75 then
        return false
    end
    local collapse = target:GetAttribute("CollapsePhase")
    return collapse == nil or collapse == "Normal" or collapse == "Safe"
end

local function refreshPerimeterGuides()
    for routeId, entry in pairs(perimeterGuides) do
        local safe = routeEntrySafe(entry.target, entry.platforms, routeId)
        for _, part in ipairs(entry.parts) do
            if part.Parent then
                part.Transparency = safe
                    and part:GetAttribute("NavBaseTransparency") or 1
            end
        end
    end
end

local function addPerimeterRouteGuides(base, arena, theme, tier)
    local platforms = arena:FindFirstChild("Platforms")
    if not platforms then return end
    local deckY = base.Position.Y + ArenaPresentation.deckArtOffset(base, 0.05)
    local firstSteps = {}
    for _, platform in ipairs(platforms:GetChildren()) do
        if platform:IsA("BasePart")
            and CollectionService:HasTag(platform, "ChaosPerimeterEntry")
            and platform:GetAttribute("PerimeterStep") == 1 then
            local routeId = tonumber(platform:GetAttribute("PerimeterRoute"))
            if routeId and routeId >= 1 and routeId <= 4 then
                firstSteps[routeId] = platform
            end
        end
    end
    for routeId = 1, 4 do
        local target = firstSteps[routeId]
        if target then
            local guide = {target = target, platforms = platforms, parts = {}}
            perimeterGuides[routeId] = guide
            local toward = target.Position - base.Position
            local direction = flattenedUnit(toward)
            if direction.Magnitude > 0 then
                local count = tier.Name == "Low" and 2 or 3
                local color = routeId % 2 == 0 and theme.Secondary or theme.Accent
                for step = 1, count do
                    local point = target.Position
                        - direction * (24 - (step - 1) * 7)
                    local pos = Vector3.new(point.X, deckY, point.Z)
                    local left, right = addGroundChevron(
                        pos, direction, color, 0.28 + (count - step) * 0.09,
                        100 + routeId * 10 + step
                    )
                    if left then
                        left.Name = "CenterPerimeterArrowL" .. routeId .. "_" .. step
                        left:SetAttribute("NavBaseTransparency", left.Transparency)
                        guide.parts[#guide.parts + 1] = left
                    end
                    if right then
                        right.Name = "CenterPerimeterArrowR" .. routeId .. "_" .. step
                        right:SetAttribute("NavBaseTransparency", right.Transparency)
                        guide.parts[#guide.parts + 1] = right
                    end
                end
            end
        end
    end
end

local function rebuild()
    clear()

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    local mechanics = arena and arena:FindFirstChild("Mechanics")
    -- The four server-tagged entrance routes and the true floor exist
    -- independently of optional mobility pads. On first-join streaming,
    -- Arena.Mechanics can replicate seconds AFTER Arena.Base/Platforms.
    -- Do not erase every route cue until a completely unrelated folder
    -- arrives: render floor/navigation now, pad markers only when ready.
    if not arena or not base or not base:IsA("BasePart") then
        return
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local theme = VisualTheme.arena(variant)
    local tier = VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled)
    local low = tier.Name == "Low"

    addCenterLandmark(base, theme, variant, tier)
    addPerimeterRouteGuides(base, arena, theme, tier)
    -- No false blue arrows to streamed-out, collapsed or disabled entry
    -- platforms. Round hazards only toggle these EXISTING six or fewer
    -- short strokes per route, without reconstructing arena geometry.
    refreshPerimeterGuides()
    -- Center paint is anchored to the floor, not to mobility pads.
    -- Scale it with the real shrinking collision deck, while pad beacons
    -- and route chevrons remain owned by their existing pad follower.
    -- No new Instances or RenderStepped callback.
    stopCenterFollowing = ArenaFloorFollowerKit.bind(
        base, folder, {namePrefix = "Center"}
    )

    local pads = {}
    if mechanics then
        for _, child in ipairs(mechanics:GetChildren()) do
            if child:IsA("BasePart")
                and child:GetAttribute("ArenaMobilityPad") == true then
                table.insert(pads, child)
            end
        end
    end
    table.sort(pads, function(a, b)
        return a.Name < b.Name
    end)

    for index, pad in ipairs(pads) do
        local impulse = padImpulse(pad)
        local direction = flattenedUnit(impulse)
        local routeColor = index % 2 == 0 and theme.Secondary or theme.Accent

        if variant == "Towers" then
            if not low then
                local beam, cap, height = addVerticalBeacon(pad, routeColor, tier, index)
                table.insert(dynamicIndicators, {
                    kind = "vertical",
                    pad = pad,
                    beam = beam,
                    cap = cap,
                    height = height,
                })
            end
        elseif direction.Magnitude > 0.01 then
            local steps = low and 1 or (tier.Name == "Medium" and 2 or 3)
            for step = 1, steps do
                local distance = 4 + (step - 1) * 3.1
                local pos = pad.Position - direction * distance + Vector3.new(0, pad.Size.Y * 0.5 + 0.08, 0)
                local left, right = addGroundChevron(
                    pos,
                    direction,
                    routeColor,
                    low and 0.72 or (0.58 + (step - 1) * 0.06),
                    index * 10 + step
                )
                table.insert(dynamicIndicators, {
                    kind = "chevron",
                    pad = pad,
                    direction = direction,
                    step = step,
                    left = left,
                    right = right,
                })
            end
        end
    end
end

local function updateDynamicIndicators()
    for _, state in ipairs(dynamicIndicators) do
        local pad = state.pad
        if not pad or not pad.Parent then
            continue
        end

        if state.kind == "vertical" then
            local height = state.height
            if state.beam and state.beam.Parent then
                state.beam.CFrame = CFrame.new(pad.Position + Vector3.new(0, height * 0.5 + 0.4, 0))
            end
            if state.cap and state.cap.Parent then
                state.cap.CFrame = CFrame.new(pad.Position + Vector3.new(0, height + 0.4, 0))
            end
        elseif state.kind == "chevron" then
            local direction = state.direction
            local step = state.step
            local distance = 4 + (step - 1) * 3.1
            local position = pad.Position - direction * distance + Vector3.new(0, pad.Size.Y * 0.5 + 0.08, 0)
            local yaw = math.atan2(-direction.X, -direction.Z)
            local lateral = Vector3.new(direction.Z, 0, -direction.X)
            local back = -direction
            local left = position + back * 0.65 - lateral * 0.58
            local right = position + back * 0.65 + lateral * 0.58

            if state.left and state.left.Parent then
                state.left.CFrame = CFrame.new(left) * CFrame.Angles(0, yaw + math.rad(38), 0)
            end
            if state.right and state.right.Parent then
                state.right.CFrame = CFrame.new(right) * CFrame.Angles(0, yaw - math.rad(38), 0)
            end
        end
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    -- A malformed snapshot or disaster list must not crash a guidance UI.
    local ids = type(state) == "table"
        and type(state.disasterIds) == "table" and state.disasterIds or {}
    shrinkingActive = type(state) == "table"
        and state.phase == "round"
        and table.find(ids, "ShrinkingArena") ~= nil
end)

task.spawn(function()
    while true do
        if shrinkingActive and #dynamicIndicators > 0 then
            updateDynamicIndicators()
            task.wait(0.12)
        else
            task.wait(0.5)
        end
    end
end)

-- Readiness and replication order differ on Android streaming:
-- Arena, Base, Mechanics, pads, marker and impulse attributes may arrive
-- on separate scheduler turns. Track each level, and release old signals.
local watchedMap = nil
local watchedArena = nil
local disconnectBaseWatch = nil
local disconnectPlatformsWatch = nil
local disconnectPadAttributes = nil
local rootRemovedConnection = nil
local watchedPlatforms = nil
local trackedEntrySignals = {}
local platformAddedSignal = nil
local platformRemovedSignal = nil
local refreshPending = false

local function scheduleRebuild()
    if refreshPending then return end
    refreshPending = true
    -- One bounded first-join batch; a 320-stud streamed arena can
    -- replicate its Base, Mechanics and tagged route entries in bursts.
    task.delay(0.12, function()
        refreshPending = false
        -- Rebuild using the CURRENT map; queued callbacks never capture
        -- an old arena or a pad removed during a round transition.
        rebuild()
    end)
end

-- Server CollectionService exposes exactly four physical route-entry
-- Parts. Watch ONLY these Parts (rather than subscribing to all 200+
-- platforms) so late PerimeterStep/Route attributes and hazard transitions
-- are handled without mobile connection or full-map rebuild storms.
local function forgetEntry(part)
    local signals = trackedEntrySignals[part]
    if not signals then return end
    trackedEntrySignals[part] = nil
    for _, signal in ipairs(signals) do signal:Disconnect() end
end

local function watchEntry(part)
    if not watchedPlatforms or part.Parent ~= watchedPlatforms
        or not part:IsA("BasePart")
        or not CollectionService:HasTag(part, "ChaosPerimeterEntry")
        or trackedEntrySignals[part] then return end
    local signals = {}
    trackedEntrySignals[part] = signals
    for _, attribute in ipairs({"PerimeterRoute", "PerimeterStep"}) do
        signals[#signals + 1] =
            part:GetAttributeChangedSignal(attribute):Connect(scheduleRebuild)
    end
    signals[#signals + 1] =
        part:GetAttributeChangedSignal("CollapsePhase")
            :Connect(refreshPerimeterGuides)
    signals[#signals + 1] =
        part:GetPropertyChangedSignal("CanCollide")
            :Connect(refreshPerimeterGuides)
    signals[#signals + 1] =
        part:GetPropertyChangedSignal("Transparency")
            :Connect(refreshPerimeterGuides)
    scheduleRebuild()
end

local function bindPlatforms(platforms)
    if watchedPlatforms == platforms then return end
    if platformAddedSignal then platformAddedSignal:Disconnect() end
    if platformRemovedSignal then platformRemovedSignal:Disconnect() end
    platformAddedSignal, platformRemovedSignal = nil, nil
    for part in pairs(trackedEntrySignals) do forgetEntry(part) end
    watchedPlatforms = platforms
    if platforms then
        platformAddedSignal = platforms.ChildAdded:Connect(function(part)
            watchEntry(part)
        end)
        platformRemovedSignal = platforms.ChildRemoved:Connect(function(part)
            if trackedEntrySignals[part] then
                forgetEntry(part)
                scheduleRebuild()
            end
        end)
        for _, part in ipairs(platforms:GetChildren()) do watchEntry(part) end
    end
    scheduleRebuild()
end

CollectionService:GetInstanceAddedSignal("ChaosPerimeterEntry")
    :Connect(watchEntry)
CollectionService:GetInstanceRemovedSignal("ChaosPerimeterEntry")
    :Connect(function(part)
        if trackedEntrySignals[part] then
            forgetEntry(part)
            scheduleRebuild()
        end
    end)

local function bindMechanics(mechanics)
    if disconnectPadAttributes then
        disconnectPadAttributes()
        disconnectPadAttributes = nil
    end

    if mechanics then
        disconnectPadAttributes = MapVisualReadiness.watchChildrenAttributes(
            mechanics,
            {"ArenaMobilityPad", "ImpulseX", "ImpulseY", "ImpulseZ"},
            scheduleRebuild
        )
    end
    -- The scheduled current-map rebuild discards stale PAD markers and
    -- keeps all genuine floor arrows and center identity when only the
    -- optional Mechanics folder streams out. Clear everything only when
    -- the authoritative Arena/Base itself disappears.
    scheduleRebuild()
end

local function bindArena(arena)
    if arenaAddedConnection then
        arenaAddedConnection:Disconnect()
        arenaAddedConnection = nil
    end
    if arenaRemovedConnection then
        arenaRemovedConnection:Disconnect()
        arenaRemovedConnection = nil
    end
    watchedArena = arena

    if not arena then
        bindPlatforms(nil)
        bindMechanics(nil)
        return
    end

    arenaAddedConnection = arena.ChildAdded:Connect(function(child)
        if child.Name == "Mechanics" then
            bindMechanics(child)
        elseif child.Name == "Platforms" then
            bindPlatforms(child)
        end
    end)
    arenaRemovedConnection = arena.ChildRemoved:Connect(function(child)
        if child.Name == "Mechanics" then
            bindMechanics(arena:FindFirstChild("Mechanics"))
        elseif child == watchedPlatforms then
            bindPlatforms(arena:FindFirstChild("Platforms"))
        end
    end)
    bindPlatforms(arena:FindFirstChild("Platforms"))
    bindMechanics(arena:FindFirstChild("Mechanics"))
end

local function bindGeneratedMap(root)
    if rootConnection then
        rootConnection:Disconnect()
        rootConnection = nil
    end
    if rootRemovedConnection then
        rootRemovedConnection:Disconnect()
        rootRemovedConnection = nil
    end
    if disconnectBaseWatch then
        disconnectBaseWatch()
        disconnectBaseWatch = nil
    end
    if disconnectPlatformsWatch then
        disconnectPlatformsWatch()
        disconnectPlatformsWatch = nil
    end
    bindArena(nil)
    watchedMap = root

    if not root then return end

    -- Base and VariantId are needed for the four distinct center motifs.
    disconnectBaseWatch = MapVisualReadiness.watch(
        root, "Arena", "Base", scheduleRebuild
    )
    disconnectPlatformsWatch = MapVisualReadiness.watch(
        root, "Arena", "Platforms", function()
            local arena = root:FindFirstChild("Arena")
            bindPlatforms(arena and arena:FindFirstChild("Platforms"))
        end
    )
    rootConnection = root.ChildAdded:Connect(function(child)
        if child.Name == "Arena" then
            bindArena(child)
        end
    end)
    rootRemovedConnection = root.ChildRemoved:Connect(function(child)
        if child == watchedArena then
            bindArena(root:FindFirstChild("Arena"))
        end
    end)
    bindArena(root:FindFirstChild("Arena"))
    scheduleRebuild()
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap"
        and workspace:FindFirstChild("GeneratedMap") == child then
        bindGeneratedMap(child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child == watchedMap then
        bindGeneratedMap(workspace:FindFirstChild("GeneratedMap"))
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(scheduleRebuild)

bindGeneratedMap(workspace:FindFirstChild("GeneratedMap"))
