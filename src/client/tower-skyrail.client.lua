-- Tower Run / Skyrail Conductor.
-- A small original industrial skyline signal kit floating above permanent
-- bridges. The server owns every collision deck. This client layer creates
-- local visuals only: no touching, querying, shadow casting or server loops.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local CelebrationMeshes = require(script.Parent.LobbyCelebrationMeshes)
local player = Players.LocalPlayer

local art = Instance.new("Folder")
art.Name = "TowerSkyrailLocal"
art.Parent = workspace

local currentPlatforms = nil
local currentTier = nil
local currentReduced = nil
local currentMeshEligible = nil
local currentProfiles = {}
local nextProfileCheck = 0
local profileKeys = {"casting", "shaft", "swept", "fragment"}
local bridges = {}
local canopy = {}
local signalConnections = {}
local activeSurges = {}
local activeBurst = {}
local burstBridge = nil
local draw

local colors = {
    Armor = Color3.fromRGB(28, 42, 63),
    Spine = Color3.fromRGB(78, 107, 132),
    Cyan = Color3.fromRGB(90, 229, 250),
    Gold = Color3.fromRGB(255, 203, 122),
}

local function findPlatforms()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    if not arena or arena:GetAttribute("VariantId") ~= "Towers" then
        return nil
    end
    return arena:FindFirstChild("Platforms")
end

local function readBridges(platforms)
    local result = {}
    if platforms then
        for _, part in ipairs(platforms:GetChildren()) do
            if part:IsA("BasePart")
                and part:GetAttribute("ChaosSkybridge") == true
            then
                table.insert(result, part)
            end
        end
    end
    table.sort(result, function(a, b)
        return a.Name < b.Name
    end)
    return result
end

local function createPart(parts, name, size, bridge, localCf, color, material, opacity, source)
    local mesh = CelebrationMeshes.cloneProfile(source)
    local p = mesh or Instance.new("Part")
    if mesh and source.Size.Y < math.max(source.Size.X, source.Size.Z)
        and math.abs(source.Size.X - source.Size.Z) > 0.01
        and (source.Size.X > source.Size.Z) ~= (size.X > size.Z) then
        size = Vector3.new(size.Z, size.Y, size.X)
        localCf *= CFrame.Angles(0, math.pi * 0.5, 0)
    end
    p.Name = name
    p.Size = size
    p.CFrame = bridge.CFrame * localCf
    p.Color = color
    p.Material = material
    p.Transparency = opacity
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = art
    table.insert(parts, {
        Part = p,
        LocalCf = localCf,
        BaseTransparency = opacity,
        BaseColor = color,
    })
    return p
end

local function routeTransform(alongX, longitudinal, up, lateral)
    -- Bridge X is the longitudinal axis on north/south links; bridge Z
    -- becomes longitudinal on east/west links, keeping the same silhouette.
    return CFrame.new(
        alongX and longitudinal or lateral,
        up,
        alongX and lateral or longitudinal
    )
end

local function buildCanopy(bridge, tier, reduced, profiles)
    local alongX = bridge.Size.X > bridge.Size.Z
    local parts = {}
    local animate = {}
    local n = #canopy + 1

    if tier == "Low" then
        for side = -1, 1, 2 do
            createPart(parts, "SkyrailGroundMarker" .. n,
                alongX and Vector3.new(0.74, 0.10, 0.40) or Vector3.new(0.40, 0.10, 0.74),
                bridge, routeTransform(alongX, 0, bridge.Size.Y * 0.5 + 0.09,
                    side * (math.min(bridge.Size.X, bridge.Size.Z) * 0.5 - 0.3)),
                colors.Cyan, Enum.Material.Metal, 0.32, profiles.casting or profiles.swept)
        end
    else
        -- Seat each pillar into the outside edge of the solid deck.
        -- Its upper end still overlaps the transverse header.
        local deck = bridge.Size.Y * 0.5
        local sideways = math.min(bridge.Size.X, bridge.Size.Z) * 0.5 + 0.27
        local pillarSize = alongX and Vector3.new(0.58, 4.95, 0.72) or Vector3.new(0.72, 4.95, 0.58)
        local fiberSize = alongX and Vector3.new(0.14, 3.65, 0.13) or Vector3.new(0.13, 3.65, 0.14)
        for side = -1, 1, 2 do
            createPart(parts, "SkyrailPillar" .. n,
                pillarSize,
                bridge, routeTransform(alongX, 0, deck + 2.30, side * sideways),
                colors.Armor, Enum.Material.DiamondPlate, 0.04, profiles.shaft or profiles.casting)

            createPart(parts, "SkyrailInsetFiber" .. n,
                fiberSize,
                bridge, routeTransform(alongX, 0, deck + 2.52,
                    side * (sideways - 0.42)),
                side < 0 and colors.Cyan or colors.Gold,
                Enum.Material.Neon, 0.20, profiles.shaft or profiles.casting)

            if tier == "High" then
                createPart(parts, "SkyrailCounterweight" .. n,
                    Vector3.new(1.10, 0.28, 1.03),
                    bridge, routeTransform(alongX, 0, deck + 4.45,
                        side * sideways),
                    colors.Spine, Enum.Material.Metal, 0.12, profiles.casting or profiles.swept)
            end
        end

        createPart(parts, "SkyrailHeader" .. n,
            alongX and Vector3.new(0.88, 0.62, sideways * 2 + 0.6)
                or Vector3.new(sideways * 2 + 0.6, 0.62, 0.88),
            bridge, routeTransform(alongX, 0, deck + 4.89, 0),
            colors.Armor, Enum.Material.Metal, 0.04, profiles.swept or profiles.casting)
        createPart(parts, "SkyrailCrownBeam" .. n,
            alongX and Vector3.new(0.28, 0.15, sideways * 1.5)
                or Vector3.new(sideways * 1.5, 0.15, 0.28),
            bridge, routeTransform(alongX, 0, deck + 5.26, 0),
            colors.Cyan, Enum.Material.Neon, 0.23, profiles.swept or profiles.casting)

        if tier == "High" then
            -- Two asymmetric upper wing fins echo an aerospace rail signal.
            for side = -1, 1, 2 do
                createPart(parts, "SkyrailSignalWing" .. n,
                    alongX and Vector3.new(1.9, 0.20, 0.47)
                        or Vector3.new(0.47, 0.20, 1.9),
                    bridge, routeTransform(alongX, side * 0.45,
                        deck + 5.18, side * 1.2),
                    side < 0 and colors.Cyan or colors.Gold,
                    Enum.Material.Neon, 0.24, profiles.casting or profiles.swept)
            end
        end

        if not reduced then
            for index = 1, tier == "High" and 2 or 1 do
                local runner = createPart(parts, "SkyrailPulseCourier" .. n,
                    alongX and Vector3.new(0.65, 0.10, 0.35) or Vector3.new(0.35, 0.10, 0.65),
                    bridge, routeTransform(alongX, 0, deck + 5.50, 0),
                    index == 1 and colors.Cyan or colors.Gold,
                    Enum.Material.Neon, 0.25, profiles.fragment)
                parts[#parts].Runner = true
                table.insert(animate, {
                    Part = runner,
                    Offset = (index - 1) * 0.5,
                    Rotation = parts[#parts].LocalCf.Rotation,
                })
            end
        end
    end

    return {Bridge = bridge, Parts = parts, Runners = animate, AlongX = alongX,
        Width = math.min(bridge.Size.X, bridge.Size.Z), Height = bridge.Size.Y}
end

local function clearBurst()
    for _, item in ipairs(activeBurst) do
        if item.Parent then item:Destroy() end
    end
    table.clear(activeBurst)
    burstBridge = nil
end

local function bridgeIsCurrent(bridge)
    return currentPlatforms ~= nil and bridge.Parent == currentPlatforms
        and currentPlatforms:IsDescendantOf(workspace)
end

-- One-shot courier flare. It uses existing bridge transforms, with
-- a bounded local part count and no per-frame server replication.
local function surgeBurst(bridge, tier, reduced)
    local pressure = tonumber(player:GetAttribute("OptionalVfxPressure")) or 0
    if reduced or tier == "Low" or pressure >= 1 or not bridgeIsCurrent(bridge) then return end
    local shutter = bridge:GetAttribute("BridgeShutterPhase")
    if not bridge.CanCollide or (shutter ~= nil and shutter ~= "Idle")
        or bridge:GetAttribute("CollapsePhase") ~= nil then
        return
    end
    local camera = workspace.CurrentCamera
    if camera and (camera.CFrame.Position - bridge.Position).Magnitude > 120 then
        return
    end
    local alongX = bridge.Size.X > bridge.Size.Z
    local axis = alongX and bridge.CFrame.RightVector or bridge.CFrame.LookVector
    local travelSign = bridge:GetAttribute("SkyrailRunDirection") == -1 and -1 or 1
    local direction = axis * travelSign
    local rank = math.clamp(tonumber(bridge:GetAttribute("SkyrailFlowTier")) or 1, 1, 3)
    local pieces = tier == "High" and (rank == 3 and 10 or 8)
        or (rank == 3 and 6 or 4)
    local top = bridge.Size.Y * 0.5 + 0.13
    clearBurst()
    burstBridge = bridge
    local source = CelebrationMeshes.readyProfile("fragment", pressure)
    for index = 1, pieces do
        local side = (index % 2 == 0) and 1 or -1
        local offset = (index - (pieces + 1) * 0.5) / pieces
        local start = bridge.CFrame * CFrame.new(
            alongX and offset * 3 or side * 1.4,
            top,
            alongX and side * 1.4 or offset * 3
        )
        local p = CelebrationMeshes.cloneProfile(source) or Instance.new("Part")
        p.Name = "SkyrailImpulseFacet"
        p.Size = Vector3.new(0.19, 0.09, 0.65)
        p.CFrame = CFrame.lookAt(start.Position, start.Position + direction)
        p.Material = Enum.Material.Neon
        p.Color = rank == 3 and (side == 1 and colors.Gold or colors.Cyan)
            or (side == 1 and colors.Cyan or colors.Gold)
        p.Transparency = 0.18
        p.Anchored = true
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.CastShadow = false
        p.Parent = art
        local finish = start.Position + direction * 5.4
        TweenService:Create(p,
            TweenInfo.new(0.40, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
            {CFrame = CFrame.lookAt(finish, finish + direction),
                Size = Vector3.new(0.10, 0.055, 1.35),
                Transparency = 1}
        ):Play()
        table.insert(activeBurst, p)
        Debris:AddItem(p, 0.48)
    end

    if rank >= 2 then
        -- Spectator-readable but short-lived world cue, without HUD clutter.
        local display = Instance.new("BillboardGui")
        display.Name = "SkyrailMasteryFlash"
        display.Adornee = bridge
        display.Size = UDim2.fromOffset(178, 36)
        display.StudsOffsetWorldSpace = Vector3.new(0, 6.6, 0)
        display.AlwaysOnTop = false
        display.MaxDistance = 78
        display.Parent = art
        local label = Instance.new("TextLabel")
        label.Name = "SkyrailMasteryTitle"
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundColor3 = Color3.fromRGB(13, 28, 43)
        label.BackgroundTransparency = 0.18
        label.BorderSizePixel = 0
        label.Font = Enum.Font.GothamBlack
        label.TextScaled = true
        label.TextColor3 = rank == 3 and colors.Gold or colors.Cyan
        label.Text = rank == 3 and "SKYRAIL ACE ×3" or "SKYRAIL CHAIN ×2"
        label.Parent = display
        local rounded = Instance.new("UICorner")
        rounded.CornerRadius = UDim.new(0, 7)
        rounded.Parent = label
        table.insert(activeBurst, display)
        Debris:AddItem(display, 1.1)
    end
end

local function readProfiles(tier, reduced, pressure, hasBridges)
    if not hasBridges or pressure >= 1 then return {} end
    local profiles = {casting = CelebrationMeshes.readyProfile("casting", pressure)}
    if tier ~= "Low" or not profiles.casting then
        profiles.swept = CelebrationMeshes.readyProfile("runway", pressure)
    end
    if tier ~= "Low" then
        profiles.shaft = CelebrationMeshes.readyProfile("pylon", pressure)
        if not reduced then profiles.fragment = CelebrationMeshes.readyProfile("fragment", pressure) end
    end
    -- A same-name replacement or a newly preloaded file can become ready
    -- midway through a round. Only rebuild when the selected geometry changes.
    for _, key in ipairs(profileKeys) do
        local part = profiles[key]
        profiles[key .. "Id"] = part and part.MeshId
    end
    return profiles
end

local function rebuildCanopies(tier, reduced, profiles)
    for _, structure in ipairs(canopy) do
        for _, item in ipairs(structure.Parts) do item.Part:Destroy() end
    end
    table.clear(canopy)
    for _, bridge in ipairs(bridges) do
        table.insert(canopy, buildCanopy(bridge, tier, reduced, profiles))
    end
end

local function rebuild(platforms, tier, reduced, ordered, profiles)
    for _, connection in ipairs(signalConnections) do
        connection:Disconnect()
    end
    table.clear(signalConnections)
    table.clear(activeSurges)
    clearBurst()
    art:ClearAllChildren()
    table.clear(canopy)
    currentPlatforms = platforms
    currentTier = tier
    currentReduced = reduced
    bridges = ordered
    rebuildCanopies(tier, reduced, profiles)
    for _, bridge in ipairs(bridges) do
        -- Hazard changes use the same draw path immediately, even on Low.
        local function syncHazard()
            if draw then draw(os.clock()) end
        end
        table.insert(signalConnections, bridge.AncestryChanged:Connect(syncHazard))
        table.insert(signalConnections, bridge:GetAttributeChangedSignal("CollapsePhase"):Connect(syncHazard))
        table.insert(signalConnections, bridge:GetAttributeChangedSignal("BridgeShutterPhase"):Connect(syncHazard))
        table.insert(signalConnections, bridge:GetPropertyChangedSignal("CanCollide"):Connect(syncHazard))
        table.insert(signalConnections, bridge:GetAttributeChangedSignal(
            "SkyrailUsedAt"
        ):Connect(function()
            if bridgeIsCurrent(bridge) and bridge.CanCollide
                and bridge:GetAttribute("CollapsePhase") == nil
                and (bridge:GetAttribute("BridgeShutterPhase") or "Idle") == "Idle" then
                activeSurges[bridge] = os.clock() + 0.8
                surgeBurst(bridge, tier, reduced)
            end
        end))
    end
end

draw = function(timestamp)
    -- One personal server-earned future Skyrail surge changes the actual
    -- next traversable bridge signal, not a disconnected UI icon.
    -- Reuse the existing canopy draw; no additional loop or world Parts.
    local aceReady = player:GetAttribute("RoundSkyrailAceBoostReady") == true
        and player:GetAttribute("RoundParticipant") == true
        and player:GetAttribute("RoundEliminated") ~= true
    for _, structure in ipairs(canopy) do
        local bridge = structure.Bridge
        local phase = bridge:GetAttribute("CollapsePhase")
        local gone = not bridgeIsCurrent(bridge) or phase == "Gone" or not bridge.CanCollide
        local shutter = bridge:GetAttribute("BridgeShutterPhase")
        local warning = phase == "Warning"
            or (shutter ~= nil and shutter ~= "Idle")
        local safeAce = aceReady and not warning and not gone
            and phase == nil
        if gone or warning then
            activeSurges[bridge] = nil
            if bridge == burstBridge then clearBurst() end
        end
        local surging = not warning and not gone
            and (activeSurges[bridge] or 0) > timestamp
        for _, item in ipairs(structure.Parts) do
            if item.Part.Parent and not item.Runner then
                item.Part.CFrame = bridge.CFrame * item.LocalCf
                local alpha = item.BaseTransparency
                if gone then
                    alpha = 1
                elseif warning then
                    -- Client canopy must never conceal the amber
                    -- authoritative bridge warning or suggest safety.
                    alpha = math.max(alpha, 0.78)
                elseif item.Part.Name:find("SkyrailInsetFiber")
                    or item.Part.Name:find("SkyrailCrownBeam") then
                    alpha = surging and 0.03 or 0.23
                end
                -- These existing real-bridge fittings are personal
                -- navigational signals. Never recolor warning bridges,
                -- never hide the original server danger palette.
                local name = item.Part.Name
                local accent = name:find("SkyrailCrownBeam")
                    or name:find("SkyrailInsetFiber")
                    or name:find("SkyrailGroundMarker")
                    or name:find("SkyrailSignalWing")
                if accent then
                    local desired = safeAce and colors.Gold
                        or (name:find("SkyrailGroundMarker")
                            and colors.Cyan
                            or (name:find("SkyrailCrownBeam")
                                and colors.Cyan
                                or item.BaseColor))
                    if item.Part.Color ~= desired then
                        item.Part.Color = desired
                    end
                end
                item.Part.Transparency = alpha
            end
        end

        -- Match the server's run direction. On a Z-oriented bridge
        -- the forward LookVector points toward negative local Z.
        local travelSign = bridge:GetAttribute("SkyrailRunDirection") == -1 and -1 or 1
        local localDirection = structure.AlongX and travelSign or -travelSign
        for _, runner in ipairs(structure.Runners) do
            if not runner.Part.Parent then continue end
            local progress = (timestamp * 0.27 + runner.Offset) % 1
            local span = math.max(2, math.max(bridge.Size.X, bridge.Size.Z) - 5)
            local distance = (progress - 0.5) * span * 0.77 * localDirection
            local cf = routeTransform(structure.AlongX, distance,
                bridge.Size.Y * 0.5 + 5.50, 0)
            runner.Part.CFrame = bridge.CFrame * cf * runner.Rotation
            runner.Part.Transparency = (gone or warning) and 1
                or (safeAce and 0.13
                    or (0.34 + 0.28 * math.abs(2 * progress - 1)))
            local runnerColor = safeAce and colors.Gold
                or (runner.Offset == 0 and colors.Cyan or colors.Gold)
            if runner.Part.Color ~= runnerColor then
                runner.Part.Color = runnerColor
            end
        end
    end
end

task.spawn(function()
    while art.Parent do
        local platforms = findPlatforms()
        local tier = VfxQuality.deviceTier(
            player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled
        ).Name
        local reduced = player:GetAttribute("ReduceMotion") == true
        local pressure = tonumber(player:GetAttribute("OptionalVfxPressure")) or 0
        local meshEligible = pressure < 1
        if not meshEligible and burstBridge then clearBurst() end
        local ordered = readBridges(platforms)
        local changed = platforms ~= currentPlatforms or tier ~= currentTier
            or reduced ~= currentReduced or #ordered ~= #bridges
        if not changed then
            for index, bridge in ipairs(ordered) do
                if bridge ~= bridges[index] then
                    changed = true
                    break
                end
            end
        end
        local now = os.clock()
        local profilesChanged = false
        if changed or currentMeshEligible ~= meshEligible or now >= nextProfileCheck then
            local profiles = readProfiles(tier, reduced, pressure, #ordered > 0)
            for _, key in ipairs(profileKeys) do
                if currentProfiles[key] ~= profiles[key]
                    or currentProfiles[key .. "Id"] ~= profiles[key .. "Id"] then
                    profilesChanged = true
                    break
                end
            end
            currentProfiles = profiles
            nextProfileCheck = now + 1
        end
        local refit = false
        if not changed then
            for _, structure in ipairs(canopy) do
                local size = structure.Bridge.Size
                if structure.AlongX ~= (size.X > size.Z)
                    or structure.Width ~= math.min(size.X, size.Z) or structure.Height ~= size.Y then
                    refit = true
                    break
                end
            end
        end
        if changed then
            rebuild(platforms, tier, reduced, ordered, currentProfiles)
        elseif profilesChanged or refit then
            rebuildCanopies(tier, reduced, currentProfiles)
        end
        currentMeshEligible = meshEligible
        if #canopy > 0 then
            draw(os.clock())
            task.wait(reduced and 0.35
                or (tier == "High" and 0.10
                    or (tier == "Medium" and 0.22 or 0.65)))
        else
            task.wait(0.75)
        end
    end
end)
