local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local localFolder = Instance.new("Folder")
localFolder.Name = "ChaosWorldPolishLocal"
localFolder.Parent = workspace

local lobbySegments = {}
local lobbyCoreParts = {}
local lobbyGateLinks = {}
local beaconEmitters = {}
local arenaGlowParts = {}
local arenaEnergyLinks = {}
local hologramParts = {}
local phase = "waiting"
local accent = Color3.fromRGB(90, 185, 255)
local secondaryAccent = nil
local doubleChaos = false
local overdrive = false
local finalRush = false
local fusionName = nil
local intensity = 1
local previousPhase = "waiting"
local readyPulseStartedAt = nil
local clock = 0
local updateClock = 0
local currentMap = nil
local currentMapConnection = nil
local secondaryLights = {}

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function clearTableInstances(collection)
    for _, instance in pairs(collection) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
    table.clear(collection)
end

local function clearPolish()
    clearTableInstances(lobbySegments)
    clearTableInstances(lobbyCoreParts)
    clearTableInstances(lobbyGateLinks)
    clearTableInstances(beaconEmitters)
    clearTableInstances(arenaGlowParts)
    clearTableInstances(arenaEnergyLinks)
    table.clear(hologramParts)
    table.clear(secondaryLights)
end

local function collectSecondaryLights(root)
    table.clear(secondaryLights)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("PointLight")
            and (
                descendant.Name == "LobbyPylonLight"
                or descendant.Name == "EdgeBeaconLight"
                or descendant.Name == "OrbitalCoreLight"
            )
        then
            table.insert(secondaryLights, descendant)
        end
    end
end

local function applyLightBudget()
    local tier = quality()
    for index, light in ipairs(secondaryLights) do
        if light.Parent then
            if tier.Name == "Low" then
                light.Enabled = false
            elseif tier.Name == "Medium" then
                light.Enabled = index % 2 == 1
            else
                light.Enabled = true
            end
        end
    end
end

local function makeSegment(name, position, size, color)
    local segment = Instance.new("Part")
    segment.Name = name
    segment.Anchored = true
    segment.CanCollide = false
    segment.CanTouch = false
    segment.CanQuery = false
    segment.CastShadow = false
    segment.Material = Enum.Material.Neon
    segment.Color = color
    segment.Transparency = 0.22
    segment.Size = size
    segment.Position = position
    segment.Parent = localFolder
    return segment
end

local function decorateLobby(root)
    local lobby = root:FindFirstChild("Lobby")
    if not lobby then
        return
    end

    local decor = lobby:FindFirstChild("Decor")
    local center = decor and decor:FindFirstChild("CenterPlatform")
    if not center or not center:IsA("BasePart") then
        return
    end

    local tier = quality()
    local coreCenter = center.Position + Vector3.new(0, 5.2, 0)

    local orb = makeSegment(
        "LobbyChaosCoreOrb",
        coreCenter,
        Vector3.new(3.6, 3.6, 3.6),
        Color3.fromRGB(86, 210, 255)
    )
    orb.Shape = Enum.PartType.Ball
    orb.Transparency = tier.Name == "Low" and 0.46 or 0.26
    orb:SetAttribute("CorePartIndex", 0)
    table.insert(lobbyCoreParts, orb)

    local coreLight = Instance.new("PointLight")
    coreLight.Name = "LobbyChaosCoreLight"
    coreLight.Color = Color3.fromRGB(105, 185, 255)
    coreLight.Brightness = tier.Name == "Low" and 0 or (1.2 * tier.Scale)
    coreLight.Range = 18 + 6 * tier.Scale
    coreLight.Shadows = false
    coreLight.Enabled = tier.Name ~= "Low"
    coreLight.Parent = orb

    if tier.Name ~= "Low" then
        for i = 1, 3 do
            local blade = makeSegment(
                "LobbyChaosCoreBlade" .. i,
                coreCenter,
                Vector3.new(0.42, 6.4, 1.15),
                i == 2 and Color3.fromRGB(180, 95, 255) or Color3.fromRGB(70, 220, 255)
            )
            blade.Transparency = 0.28
            blade:SetAttribute("CorePartIndex", i)
            table.insert(lobbyCoreParts, blade)
        end
    end

    local segmentCount = 12
    local radius = 15.5
    for i = 1, segmentCount do
        local angle = ((i - 1) / segmentCount) * math.pi * 2
        local position = center.Position + Vector3.new(math.cos(angle) * radius, 1.0, math.sin(angle) * radius)
        local segment = makeSegment(
            "LobbyEnergySegment" .. i,
            position,
            Vector3.new(4.4, 0.16, 0.62),
            Color3.fromRGB(82, 178, 255)
        )
        segment.CFrame = CFrame.new(position) * CFrame.Angles(0, -angle, 0)
        segment:SetAttribute("OrbitAngle", angle)
        table.insert(lobbySegments, segment)
    end


    local leftColumn = decor and decor:FindFirstChild("ArenaGateLeft")
    local rightColumn = decor and decor:FindFirstChild("ArenaGateRight")
    if leftColumn and rightColumn
        and leftColumn:IsA("BasePart")
        and rightColumn:IsA("BasePart")
    then
        for level = 1, 4 do
            local height = -4.2 + (level * 2.2)

            local a = Instance.new("Attachment")
            a.Name = "GateLinkA" .. level
            a.Position = Vector3.new(0, height, 0)
            a.Parent = leftColumn

            local b = Instance.new("Attachment")
            b.Name = "GateLinkB" .. level
            b.Position = Vector3.new(0, height, 0)
            b.Parent = rightColumn

            local beam = Instance.new("Beam")
            beam.Name = "GateEnergyLink" .. level
            beam.Attachment0 = a
            beam.Attachment1 = b
            beam.FaceCamera = true
            beam.Width0 = 0.07
            beam.Width1 = 0.07
            beam.LightEmission = 1
            beam.LightInfluence = 0
            beam.Segments = 1
            beam.Color = ColorSequence.new(
                Color3.fromRGB(110, 105, 255),
                Color3.fromRGB(75, 215, 255)
            )
            beam.Transparency = NumberSequence.new(0.56)
            beam.Parent = a

            table.insert(lobbyGateLinks, a)
            table.insert(lobbyGateLinks, b)
        end
    end


    local gateTop = decor and decor:FindFirstChild("ArenaGateTop")
    if gateTop and gateTop:IsA("BasePart") then
        local attachment = Instance.new("Attachment")
        attachment.Name = "GateEnergyLocal"
        attachment.Position = Vector3.new(0, -1.7, 0)
        attachment.Parent = gateTop

        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "GateEnergy"
        emitter:SetAttribute("BaseRate", 7)
        emitter.Rate = 7 * quality().ParticleScale
        emitter.Lifetime = NumberRange.new(0.55, 1.05)
        emitter.Speed = NumberRange.new(0.3, 1.2)
        emitter.SpreadAngle = Vector2.new(12, 12)
        emitter.LightEmission = 0.85
        emitter.LockedToPart = false
        emitter.Color = ColorSequence.new(
            Color3.fromRGB(105, 90, 255),
            Color3.fromRGB(90, 205, 255)
        )
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.34),
            NumberSequenceKeypoint.new(0.55, 0.18),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(1, 1),
        })
        emitter.Parent = attachment
        table.insert(beaconEmitters, attachment)
    end
end

local function addBeaconParticles(part)
    if not part:IsA("BasePart") then
        return
    end

    local attachment = Instance.new("Attachment")
    attachment.Name = "ChaosBeaconVfxLocal"
    attachment.Parent = part

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "BeaconMotes"
    emitter:SetAttribute("BaseRate", 9)
    emitter.Rate = 9 * quality().ParticleScale
    emitter.Lifetime = NumberRange.new(0.45, 0.95)
    emitter.Speed = NumberRange.new(0.8, 2.2)
    emitter.Acceleration = Vector3.new(0, 1.2, 0)
    emitter.SpreadAngle = Vector2.new(22, 22)
    emitter.LightEmission = 0.92
    emitter.Color = ColorSequence.new(part.Color, Color3.new(1, 1, 1))
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.24),
        NumberSequenceKeypoint.new(0.65, 0.14),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.22),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment

    table.insert(beaconEmitters, attachment)
end

local function addEnergyLink(a, b, name)
    if not a or not b or not a:IsA("BasePart") or not b:IsA("BasePart") then
        return
    end

    local attachmentA = Instance.new("Attachment")
    attachmentA.Name = name .. "A"
    attachmentA.Parent = a

    local attachmentB = Instance.new("Attachment")
    attachmentB.Name = name .. "B"
    attachmentB.Parent = b

    local beam = Instance.new("Beam")
    beam.Name = name
    beam.Attachment0 = attachmentA
    beam.Attachment1 = attachmentB
    beam.FaceCamera = true
    beam.Width0 = 0.11
    beam.Width1 = 0.11
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Segments = 1
    beam.Transparency = NumberSequence.new(0.34)
    beam.Color = ColorSequence.new(accent)
    beam.Parent = attachmentA

    table.insert(arenaEnergyLinks, attachmentA)
    table.insert(arenaEnergyLinks, attachmentB)
end

local function decorateArena(root)
    local arena = root:FindFirstChild("Arena")
    local decor = arena and arena:FindFirstChild("Decor")
    if not decor then
        return
    end

    for _, child in ipairs(decor:GetChildren()) do
        if child:IsA("BasePart")
            and (child.Name == "CenterBeacon" or string.find(child.Name, "EdgeBeaconGlow", 1, true) == 1)
        then
            addBeaconParticles(child)
        end
    end

    local beaconParts = {}
    for i = 1, 4 do
        local beacon = decor:FindFirstChild("EdgeBeaconGlow" .. i)
        if beacon and beacon:IsA("BasePart") then
            beaconParts[i] = beacon
        end
    end

    if beaconParts[1] and beaconParts[2] and beaconParts[3] and beaconParts[4] then
        addEnergyLink(beaconParts[1], beaconParts[2], "NorthEnergyLink")
        addEnergyLink(beaconParts[2], beaconParts[4], "EastEnergyLink")
        addEnergyLink(beaconParts[4], beaconParts[3], "SouthEnergyLink")
        addEnergyLink(beaconParts[3], beaconParts[1], "WestEnergyLink")
    end

    local hologram = decor:FindFirstChild("ArenaIdentityHologram")
    local hologramGlow = decor:FindFirstChild("ArenaIdentityGlow")
    if hologram and hologram:IsA("BasePart") then
        table.insert(hologramParts, hologram)
    end
    if hologramGlow and hologramGlow:IsA("BasePart") then
        table.insert(hologramParts, hologramGlow)
    end

    local centerBeacon = decor:FindFirstChild("CenterBeacon")
    if centerBeacon and centerBeacon:IsA("BasePart") then
        for i = 1, 4 do
            local angle = ((i - 1) / 4) * math.pi * 2
            local p = makeSegment(
                "ArenaOrbitLight" .. i,
                centerBeacon.Position + Vector3.new(math.cos(angle) * 4.2, -5.2, math.sin(angle) * 4.2),
                Vector3.new(1.8, 0.12, 0.38),
                centerBeacon.Color
            )
            p.CFrame = CFrame.new(p.Position) * CFrame.Angles(0, -angle, 0)
            p:SetAttribute("OrbitAngle", angle)
            table.insert(arenaGlowParts, p)
        end
    end
end

local function rebuild(root)
    if currentMapConnection then
        currentMapConnection:Disconnect()
        currentMapConnection = nil
    end

    clearPolish()
    currentMap = root
    decorateLobby(root)
    decorateArena(root)
    collectSecondaryLights(root)
    applyLightBudget()
    refreshArenaHologramText()

    currentMapConnection = root.ChildAdded:Connect(function(child)
        if child.Name == "Arena" and root == currentMap then
            task.defer(function()
                if root == currentMap and root.Parent then
                    rebuild(root)
                end
            end)
        end
    end)
end

local function bindGeneratedMap()
    local root = workspace:FindFirstChild("GeneratedMap")
    if root and root ~= currentMap then
        rebuild(root)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(rebuild, child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child == currentMap then
        if currentMapConnection then
            currentMapConnection:Disconnect()
            currentMapConnection = nil
        end
        currentMap = nil
        clearPolish()
    end
end)

local function refreshArenaHologramText()
    if not currentMap then
        return
    end

    local arena = currentMap:FindFirstChild("Arena")
    local decor = arena and arena:FindFirstChild("Decor")
    local hologram = decor and decor:FindFirstChild("ArenaIdentityHologram")
    local gui = hologram and hologram:FindFirstChild("ArenaIdentityGui")
    if not gui then
        return
    end

    local title = gui:FindFirstChild("ArenaIdentityTitle")
    local hint = gui:FindFirstChild("ArenaIdentityHint")
    local separator = gui:FindFirstChild("ArenaIdentitySeparator")

    if not title or not title:IsA("TextLabel") or not hint or not hint:IsA("TextLabel") then
        return
    end

    local titleText = tostring(title:GetAttribute("BaseText") or "CHAOS ARENA")
    local hintText = tostring(hint:GetAttribute("BaseText") or "ADAPT • MOVE • SURVIVE")
    local eventColor = nil

    if phase == "round" and finalRush then
        titleText = "FINAL RUSH"
        hintText = "LAST 5 SECONDS • PADS RECHARGE FASTER"
        eventColor = Color3.fromRGB(255, 92, 58)
    elseif phase == "round" and overdrive then
        titleText = "OVERDRIVE"
        hintText = "BOOST PADS • SHARD SURGE • GOLDEN SHARD"
        eventColor = Color3.fromRGB(255, 205, 85)
    elseif doubleChaos and fusionName then
        titleText = tostring(fusionName)
        hintText = "CHAOS FUSION • SURVIVE BOTH HAZARDS"
        eventColor = Color3.fromRGB(185, 100, 255)
    end

    title.Text = titleText
    hint.Text = hintText

    if eventColor then
        title.TextStrokeColor3 = eventColor
        hint.TextColor3 = eventColor:Lerp(Color3.new(1, 1, 1), 0.48)
        if separator and separator:IsA("Frame") then
            separator.BackgroundColor3 = eventColor
        end
    else
        title.TextStrokeColor3 = accent
        hint.TextColor3 = Color3.fromRGB(190, 210, 230)
        if separator and separator:IsA("Frame") then
            separator.BackgroundColor3 = accent
        end
    end
end

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    local tier = quality()
    applyLightBudget()

    for _, attachment in ipairs(beaconEmitters) do
        local emitter = attachment and attachment:FindFirstChildOfClass("ParticleEmitter")
        if emitter then
            local baseRate = tonumber(emitter:GetAttribute("BaseRate")) or 9
            emitter.Rate = baseRate * tier.ParticleScale
        end
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    previousPhase = phase
    phase = tostring(state.phase or "waiting")
    if phase == "ready" and previousPhase ~= "ready" then
        readyPulseStartedAt = clock
    elseif phase ~= "ready" then
        readyPulseStartedAt = nil
    end
    doubleChaos = state.doubleChaos == true
    overdrive = state.phase == "round" and state.overdrive == true
    finalRush = state.phase == "round" and state.finalRush == true
    fusionName = type(state.fusionName) == "string" and state.fusionName or nil
    intensity = math.clamp(tonumber(state.intensity) or 1, 0.85, 1.25)

    local ids = state.disasterIds or {}
    local profile = DisasterVisuals.combine(ids)
    local secondary = ids[2] and DisasterVisuals.get(ids[2]) or nil

    if profile then
        accent = profile.Accent
        secondaryAccent = secondary and secondary.Accent or nil
    else
        accent = Color3.fromRGB(90, 185, 255)
        secondaryAccent = nil
    end

    refreshArenaHologramText()
end)

bindGeneratedMap()

RunService.RenderStepped:Connect(function(dt)
    clock += dt
    updateClock += dt

    local tier = quality()
    if updateClock < math.max(0.025, tier.UpdateInterval) then
        return
    end
    local elapsed = updateClock
    updateClock = 0

    local coreTier = quality()
    local coreCenter = Config.LobbyCenter + Vector3.new(0, 6.65, 0)
    if currentMap then
        local lobby = currentMap:FindFirstChild("Lobby")
        local decor = lobby and lobby:FindFirstChild("Decor")
        local centerPart = decor and decor:FindFirstChild("CenterPlatform")
        if centerPart and centerPart:IsA("BasePart") then
            coreCenter = centerPart.Position + Vector3.new(0, 5.2, 0)
        end
    end

    for _, corePart in ipairs(lobbyCoreParts) do
        if corePart.Parent then
            local index = tonumber(corePart:GetAttribute("CorePartIndex")) or 0
            local verticalWave = math.sin(clock * 1.8) * 0.22
            if index == 0 then
                corePart.Position = coreCenter + Vector3.new(0, verticalWave, 0)
                corePart.Color = Color3.fromRGB(80, 205, 255):Lerp(
                    Color3.fromRGB(175, 95, 255),
                    (math.sin(clock * 1.4) + 1) * 0.5
                )
                corePart.Transparency = coreTier.Name == "Low"
                    and 0.46
                    or (0.22 + ((math.sin(clock * 2.3) + 1) * 0.5) * 0.12)

                local light = corePart:FindFirstChild("LobbyChaosCoreLight")
                if light and light:IsA("PointLight") then
                    light.Enabled = coreTier.Name ~= "Low"
                    light.Brightness = (1.0 + ((math.sin(clock * 2.2) + 1) * 0.5) * 0.7) * coreTier.Scale
                end
            else
                local angle = clock * (0.45 + index * 0.10) + math.rad(index * 60)
                corePart.CFrame = CFrame.new(coreCenter + Vector3.new(0, verticalWave, 0))
                    * CFrame.Angles(math.rad(18), angle, math.rad(28 + index * 10))
                corePart.Transparency = coreTier.Name == "Low" and 1 or 0.26
            end
        end
    end

    local gateTier = quality()
    for index, attachment in ipairs(lobbyGateLinks) do
        if attachment.Parent then
            local beam = attachment:FindFirstChildOfClass("Beam")
            if beam then
                beam.Enabled = gateTier.Name ~= "Low"
                local gateWave = (math.sin(clock * 2.4 + index * 0.45) + 1) * 0.5
                beam.Width0 = 0.05 + gateWave * 0.05 * gateTier.Scale
                beam.Width1 = beam.Width0
                beam.Transparency = NumberSequence.new(
                    math.clamp(0.48 + gateWave * 0.18 + (1 - gateTier.Scale) * 0.16, 0.42, 0.82)
                )
            end
        end
    end

    local lobbySpeed = phase == "round" and 0.55 or 0.34
    for i, segment in ipairs(lobbySegments) do
        if segment.Parent then
            local baseAngle = segment:GetAttribute("OrbitAngle") or 0
            local angle = baseAngle + clock * lobbySpeed
            local center = Config.LobbyCenter
            if currentMap then
                local lobby = currentMap:FindFirstChild("Lobby")
                local decor = lobby and lobby:FindFirstChild("Decor")
                local centerPart = decor and decor:FindFirstChild("CenterPlatform")
                if centerPart and centerPart:IsA("BasePart") then
                    center = centerPart.Position
                end
            end

            local radius = 15.5
            local position = center + Vector3.new(math.cos(angle) * radius, 1.0, math.sin(angle) * radius)
            segment.CFrame = CFrame.new(position) * CFrame.Angles(0, -angle, 0)
            local wave = (math.sin(clock * 2.8 + i * 0.7) + 1) * 0.5
            segment.Transparency = 0.18 + wave * 0.34
        end
    end

    local blendedAccent = accent
    if doubleChaos and secondaryAccent then
        local blend = (math.sin(clock * 4.2) + 1) * 0.5
        blendedAccent = accent:Lerp(secondaryAccent, blend)
    end

    local visualAccent = blendedAccent
    if finalRush then
        visualAccent = Color3.fromRGB(255, 92, 58):Lerp(blendedAccent, 0.20)
    elseif overdrive then
        visualAccent = Color3.fromRGB(255, 205, 85):Lerp(blendedAccent, 0.28)
    end

    local linkTier = quality()
    for _, attachment in ipairs(arenaEnergyLinks) do
        if attachment.Parent then
            local beam = attachment:FindFirstChildOfClass("Beam")
            if beam then
                beam.Enabled = linkTier.Name ~= "Low"
                if doubleChaos and secondaryAccent and not overdrive and not finalRush then
                    beam.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, accent),
                        ColorSequenceKeypoint.new(1, secondaryAccent),
                    })
                else
                    beam.Color = ColorSequence.new(visualAccent)
                end
                local linkWave = (math.sin(clock * (finalRush and 7.2 or (overdrive and 5.4 or 3.1))) + 1) * 0.5
                beam.Width0 = (finalRush and 0.15 or (overdrive and 0.12 or 0.07)) + linkWave * 0.08 * linkTier.Scale
                beam.Width1 = beam.Width0
                beam.Transparency = NumberSequence.new(
                    math.clamp(
                        (finalRush and 0.12 or (overdrive and 0.18 or 0.30))
                            + (1 - linkTier.Scale) * 0.24
                            + linkWave * 0.10,
                        0.14,
                        0.80
                    )
                )
            end
        end
    end

    for index, part in ipairs(hologramParts) do
        if part.Parent then
            local shimmer = (math.sin(clock * (finalRush and 6.0 or (overdrive and 4.2 or 2.1)) + index * 0.8) + 1) * 0.5
            if part.Name == "ArenaIdentityGlow" then
                part.Color = visualAccent
                part.Transparency = (finalRush and 0.34 or (overdrive and 0.42 or 0.58)) + shimmer * 0.18
            else
                part.Transparency = (finalRush and 0.06 or (overdrive and 0.10 or 0.16)) + shimmer * 0.08
            end
        end
    end

    local readyBoost = 0
    if phase == "ready" and readyPulseStartedAt then
        local elapsedReady = clock - readyPulseStartedAt
        if elapsedReady >= 0 and elapsedReady <= 1.6 then
            local normalized = elapsedReady / 1.6
            readyBoost = math.sin(normalized * math.pi)
        end
    end

    local arenaSpeed = (
        phase == "round"
            and (finalRush and 3.25 or (overdrive and 2.45 or 1.55))
            or (phase == "ready" and (0.95 + readyBoost * 1.35) or 0.65)
    ) * intensity
    for i, glow in ipairs(arenaGlowParts) do
        if glow.Parent then
            local baseAngle = glow:GetAttribute("OrbitAngle") or 0
            local angle = baseAngle + clock * arenaSpeed
            local root = currentMap
            local arena = root and root:FindFirstChild("Arena")
            local decor = arena and arena:FindFirstChild("Decor")
            local beacon = decor and decor:FindFirstChild("CenterBeacon")

            if beacon and beacon:IsA("BasePart") then
                local radius = 4.2 + math.sin(clock * 2 + i) * 0.35
                local position = beacon.Position + Vector3.new(
                    math.cos(angle) * radius,
                    -5.2 + math.sin(clock * 3.2 + i) * 0.18,
                    math.sin(angle) * radius
                )
                glow.CFrame = CFrame.new(position) * CFrame.Angles(0, -angle, 0)
                glow.Color = visualAccent
                glow.Transparency = phase == "round"
                    and 0.12
                    or (phase == "ready"
                        and math.clamp(0.34 - readyBoost * 0.20, 0.10, 0.40)
                        or 0.38)
            end
        end
    end

    for _, attachment in ipairs(beaconEmitters) do
        if attachment.Parent then
            local emitter = attachment:FindFirstChildOfClass("ParticleEmitter")
            if emitter then
                emitter.Color = ColorSequence.new(visualAccent, Color3.new(1, 1, 1))
                local baseRate = phase == "round"
                    and (finalRush and 22 or (overdrive and 18 or 12))
                    or (phase == "ready" and (7 + readyBoost * 8) or 6)
                local targetRate = baseRate * tier.ParticleScale * intensity
                emitter.Rate += (targetRate - emitter.Rate) * math.min(1, elapsed * 6)
            end
        end
    end
end)
