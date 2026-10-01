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
local lobbyGateLinks = {}
local beaconEmitters = {}
local arenaGlowParts = {}
local arenaEnergyLinks = {}
local hologramParts = {}
local phase = "waiting"
local accent = Color3.fromRGB(90, 185, 255)
local secondaryAccent = nil
local doubleChaos = false
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

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    local tier = quality()
    applyLightBudget()
    local linkTier = quality()
    for _, attachment in ipairs(arenaEnergyLinks) do
        if attachment.Parent then
            local beam = attachment:FindFirstChildOfClass("Beam")
            if beam then
                beam.Enabled = linkTier.Name ~= "Low"
                beam.Color = ColorSequence.new(blendedAccent)
                local linkWave = (math.sin(clock * 3.1) + 1) * 0.5
                beam.Width0 = 0.07 + linkWave * 0.08 * linkTier.Scale
                beam.Width1 = beam.Width0
                beam.Transparency = NumberSequence.new(
                    math.clamp(0.30 + (1 - linkTier.Scale) * 0.24 + linkWave * 0.10, 0.24, 0.80)
                )
            end
        end
    end

    for index, part in ipairs(hologramParts) do
        if part.Parent then
            local shimmer = (math.sin(clock * 2.1 + index * 0.8) + 1) * 0.5
            if part.Name == "ArenaIdentityGlow" then
                part.Color = blendedAccent
                part.Transparency = 0.58 + shimmer * 0.20
            else
                part.Transparency = 0.16 + shimmer * 0.08
            end
        end
    end

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
            and 1.55
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
                glow.Color = blendedAccent
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
                emitter.Color = ColorSequence.new(blendedAccent, Color3.new(1, 1, 1))
                local baseRate = phase == "round"
                    and 12
                    or (phase == "ready" and (7 + readyBoost * 8) or 6)
                local targetRate = baseRate * tier.ParticleScale * intensity
                emitter.Rate += (targetRate - emitter.Rate) * math.min(1, elapsed * 6)
            end
        end
    end
end)
