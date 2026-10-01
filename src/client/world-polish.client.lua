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
local beaconEmitters = {}
local arenaGlowParts = {}
local phase = "waiting"
local accent = Color3.fromRGB(90, 185, 255)
local secondaryAccent = nil
local doubleChaos = false
local intensity = 1
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
    clearTableInstances(beaconEmitters)
    clearTableInstances(arenaGlowParts)
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
    for _, attachment in ipairs(beaconEmitters) do
        local emitter = attachment and attachment:FindFirstChildOfClass("ParticleEmitter")
        if emitter then
            local baseRate = tonumber(emitter:GetAttribute("BaseRate")) or 9
            emitter.Rate = baseRate * tier.ParticleScale
        end
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    phase = tostring(state.phase or "waiting")
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

    local arenaSpeed = (phase == "round" and 1.55 or 0.65) * intensity
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
                glow.Transparency = phase == "round" and 0.12 or 0.38
            end
        end
    end

    for _, attachment in ipairs(beaconEmitters) do
        if attachment.Parent then
            local emitter = attachment:FindFirstChildOfClass("ParticleEmitter")
            if emitter then
                emitter.Color = ColorSequence.new(blendedAccent, Color3.new(1, 1, 1))
                local targetRate = (phase == "round" and 12 or 6) * tier.ParticleScale * intensity
                emitter.Rate += (targetRate - emitter.Rate) * math.min(1, elapsed * 6)
            end
        end
    end
end)
