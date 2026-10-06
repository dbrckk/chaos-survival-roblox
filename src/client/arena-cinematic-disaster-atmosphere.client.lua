local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "ArenaCinematicDisasterAtmosphereLocal"
folder.Parent = workspace

local phase = "waiting"
local finalRush = false
local disasterIds = {}
local clock = 0
local mapConnection = nil
local loopStarted = false
local beaconParts = {}
local beamStates = {}
local emitters = {}

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function clear()
    table.clear(beaconParts)
    table.clear(beamStates)
    table.clear(emitters)
    folder:ClearAllChildren()
end

local function arenaContext()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not arena or not base or not base:IsA("BasePart") then
        return nil
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    return arena, base, variant, VisualTheme.arena(variant)
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
    part.Color = color
    part.Material = material or Enum.Material.Neon
    part.Transparency = transparency or 0
    part.Parent = folder
    return part
end

local function roleFor(id)
    if id == "RisingLava" or id == "Bombs" or id == "Meteors" then
        return "embers"
    elseif id == "Freeze" then
        return "mist"
    elseif id == "Tornado" then
        return "debris"
    elseif id == "Darkness" then
        return "void"
    elseif id == "LowGravity" then
        return "lift"
    elseif id == "SpeedSurge" then
        return "streak"
    elseif id == "ShrinkingArena" then
        return "edge"
    elseif id == "JumpShock" then
        return "shock"
    end
    return "energy"
end

local function emitterFor(anchor, id, color, tier)
    -- Tornado already owns orbiting debris around the authoritative RoundTornado
    -- model in tornado-visuals.client.lua; do not duplicate debris at the arena edge.
    if tier.Name == "Low" or id == "Tornado" then
        return nil
    end

    local role = roleFor(id)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "ArenaAtmosphere_" .. tostring(id)
    emitter.Enabled = phase == "round"
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(0.65, 1.45)
    emitter.LightEmission = role == "mist" and 0.35 or 0.85
    emitter.LightInfluence = role == "void" and 0.8 or 0
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.RotSpeed = NumberRange.new(-45, 45)
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.Color = ColorSequence.new(
        color:Lerp(Color3.new(1, 1, 1), 0.18),
        color:Lerp(Color3.new(0, 0, 0), 0.30)
    )

    if role == "embers" then
        emitter.Speed = NumberRange.new(2.5, 7.5)
        emitter.Acceleration = Vector3.new(0, 5.5, 0)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(0.55, 0.10),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.12),
            NumberSequenceKeypoint.new(1, 1),
        })
    elseif role == "mist" then
        emitter.Speed = NumberRange.new(0.6, 2.0)
        emitter.Acceleration = Vector3.new(0, 0.8, 0)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(0.45, 1.8),
            NumberSequenceKeypoint.new(1, 2.6),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.62),
            NumberSequenceKeypoint.new(0.5, 0.76),
            NumberSequenceKeypoint.new(1, 1),
        })
    elseif role == "debris" then
        emitter.Speed = NumberRange.new(5, 11)
        emitter.Acceleration = Vector3.new(0, 0.5, 0)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.22),
            NumberSequenceKeypoint.new(1, 0.05),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.28),
            NumberSequenceKeypoint.new(1, 1),
        })
    elseif role == "lift" then
        emitter.Speed = NumberRange.new(1.4, 3.8)
        emitter.Acceleration = Vector3.new(0, 5.2, 0)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.12),
            NumberSequenceKeypoint.new(0.7, 0.22),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.26),
            NumberSequenceKeypoint.new(1, 1),
        })
    elseif role == "streak" then
        emitter.Speed = NumberRange.new(8, 15)
        emitter.Acceleration = Vector3.new(6, 0, -6)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.12),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.20),
            NumberSequenceKeypoint.new(1, 1),
        })
    else
        emitter.Speed = NumberRange.new(1.5, 4.5)
        emitter.Acceleration = Vector3.new(0, 2.5, 0)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.14),
            NumberSequenceKeypoint.new(0.6, 0.22),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.34),
            NumberSequenceKeypoint.new(1, 1),
        })
    end

    emitter.Parent = anchor
    table.insert(emitters, emitter)
    return emitter
end

local function addVolumetricBeam(index, base, angle, radius, color, tier)
    if tier.Name == "Low" then
        return
    end

    local height = tier.Name == "High" and 42 or 30
    local width = tier.Name == "High" and 1.1 or 0.75
    local pos = base.Position + Vector3.new(
        math.cos(angle) * radius,
        height * 0.5 + 4,
        math.sin(angle) * radius
    )

    local shaft = makePart(
        "DisasterLightShaft" .. index,
        Vector3.new(width, height, width),
        CFrame.new(pos),
        color,
        Enum.Material.Neon,
        tier.Name == "High" and 0.86 or 0.90
    )

    table.insert(beamStates, {
        part = shaft,
        angle = angle,
        radius = radius,
        base = base,
        height = height,
        index = index,
    })
end

local function rebuild()
    clear()

    local _, base, variant, theme = arenaContext()
    if not base then
        return
    end

    local tier = quality()
    local profile = DisasterVisuals.combine(disasterIds)
    local secondaryProfile = disasterIds[2] and DisasterVisuals.get(disasterIds[2]) or nil
    local accent = profile and profile.Accent or theme.Accent
    local secondary = secondaryProfile and secondaryProfile.Accent or theme.Secondary

    local radius = math.max(base.Size.X, base.Size.Z) * 0.52
    local beaconCount = tier.Name == "Low" and 4 or (tier.Name == "Medium" and 6 or 8)

    for i = 1, beaconCount do
        local angle = ((i - 1) / beaconCount) * math.pi * 2
        local pos = base.Position + Vector3.new(
            math.cos(angle) * radius,
            base.Size.Y * 0.5 + 0.8,
            math.sin(angle) * radius
        )

        local beacon = makePart(
            "DisasterPerimeterBeacon" .. i,
            Vector3.new(0.44, 1.8, 0.44),
            CFrame.new(pos),
            i % 2 == 0 and secondary or accent,
            Enum.Material.Neon,
            tier.Name == "Low" and 0.50 or 0.30
        )
        beacon:SetAttribute("BaseTransparency", beacon.Transparency)
        table.insert(beaconParts, beacon)

        local attachment = Instance.new("Attachment")
        attachment.Name = "DisasterAtmosphereAttachment"
        attachment.Parent = beacon

        local id = disasterIds[((i - 1) % math.max(1, #disasterIds)) + 1]
        if id then
            emitterFor(attachment, id, beacon.Color, tier)
        end

        if tier.Name ~= "Low" and i % 2 == 1 then
            addVolumetricBeam(i, base, angle, radius * 1.08, beacon.Color, tier)
        end
    end

    if variant == "Orbital" and tier.Name == "High" then
        local core = makePart(
            "DisasterOrbitalCoreAura",
            Vector3.new(8, 8, 8),
            CFrame.new(base.Position + Vector3.new(0, 13, 0)),
            accent,
            Enum.Material.Neon,
            phase == "round" and 0.72 or 0.86
        )
        core.Shape = Enum.PartType.Ball
    end
end

local function refreshRates()
    local tier = quality()
    local reduced = player:GetAttribute("ReduceMotion") == true
    local baseRate = tier.Name == "High" and 7 or 4

    for _, emitter in ipairs(emitters) do
        if emitter and emitter.Parent then
            emitter.Enabled = phase == "round"
            emitter.Rate = phase == "round"
                and baseRate * tier.ParticleScale * (finalRush and 1.45 or 1) * (reduced and 0.35 or 1)
                or 0
        end
    end
end

local function ensureRenderLoop()
    if loopStarted then
        return
    end
    loopStarted = true

    task.spawn(function()
        while true do
            local tier = quality()
            local dt = task.wait(math.max(1 / 30, tier.UpdateInterval))

            if #beaconParts == 0 and #beamStates == 0 then
                continue
            end

            clock += dt

        local reduced = player:GetAttribute("ReduceMotion") == true
        local motion = reduced and 0.16 or 1
        local activeScale = phase == "round" and 1 or 0.42
        if finalRush then
            activeScale *= 1.28
        end

        for i, beacon in ipairs(beaconParts) do
            if beacon and beacon.Parent then
                local baseTransparency = tonumber(beacon:GetAttribute("BaseTransparency")) or 0.34
                local pulse = (math.sin(clock * (2.4 + i * 0.13) * motion) + 1) * 0.5
                beacon.Transparency = math.clamp(
                    baseTransparency + (1 - activeScale) * 0.16 - pulse * 0.10 * activeScale,
                    0.18,
                    0.86
                )
            end
        end

        for _, state in ipairs(beamStates) do
            local part = state.part
            local base = state.base
            if part and part.Parent and base and base.Parent then
                local sweep = math.sin(clock * 0.38 * motion + state.index * 0.9) * 0.12
                local angle = state.angle + sweep
                local pos = base.Position + Vector3.new(
                    math.cos(angle) * state.radius,
                    state.height * 0.5 + 4,
                    math.sin(angle) * state.radius
                )
                part.CFrame = CFrame.new(pos)
                    * CFrame.Angles(math.rad(4 * math.sin(clock * 0.5 + state.index)), 0, math.rad(5 * math.cos(clock * 0.43 + state.index)))
                part.Transparency = phase == "round"
                    and (finalRush and 0.78 or 0.84)
                    or 0.93
            end
        end
        end
    end)
end

local function bindMap()
    if mapConnection then
        mapConnection:Disconnect()
        mapConnection = nil
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    if generated then
        mapConnection = generated.ChildAdded:Connect(function(child)
            if child.Name == "Arena" then
                task.delay(0.08, function()
                    rebuild()
                    refreshRates()
                end)
            end
        end)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(function()
            bindMap()
            rebuild()
            refreshRates()
        end)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clear()
        bindMap()
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    rebuild()
    refreshRates()
end)

player:GetAttributeChangedSignal("ReduceMotion"):Connect(refreshRates)

stateEvent.OnClientEvent:Connect(function(state)
    local newPhase = tostring(state.phase or "waiting")
    local newIds = state.disasterIds or {}
    local changed = newPhase ~= phase or #newIds ~= #disasterIds

    if not changed then
        for i, id in ipairs(newIds) do
            if disasterIds[i] ~= id then
                changed = true
                break
            end
        end
    end

    phase = newPhase
    finalRush = phase == "round" and state.finalRush == true
    disasterIds = newIds

    if changed then
        rebuild()
    end
    refreshRates()
end)

bindMap()
rebuild()
refreshRates()
ensureRenderLoop()
