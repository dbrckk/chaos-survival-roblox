local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local ArenaSpatialAudioRules = require(ReplicatedStorage.Shared.ArenaSpatialAudioRules)
local ArenaCrisisSurfaceRules = require(ReplicatedStorage.Shared.ArenaCrisisSurfaceRules)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)
local AudioConfig = require(ReplicatedStorage.Shared.AudioConfig)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local group = SoundService:FindFirstChild("ChaosArenaAmbience") or Instance.new("SoundGroup")
group.Name = "ChaosArenaAmbience"
group.Volume = 1
group.Parent = SoundService

local folder = Instance.new("Folder")
folder.Name = "ArenaSpatialAudioLocal"
folder.Parent = workspace

local activeSounds = {}
local phase = "waiting"
local overdrive = false
local finalRush = false
local activeDisasters = {}
local currentVariant = "Classic"
local disconnectMapWatch = nil

local function clear()
    for _, sound in ipairs(activeSounds) do
        if sound and sound.Parent then
            sound:Stop()
        end
    end
    table.clear(activeSounds)
    folder:ClearAllChildren()
end

local function arenaInfo()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not arena or not base or not base:IsA("BasePart") then
        return nil, nil
    end
    return arena, base
end

local function applyTreatment(sound, profile)
    local eq = Instance.new("EqualizerSoundEffect")
    eq.Name = "ArenaSpatialEQ"
    eq.LowGain = math.clamp(tonumber(profile.EQ.Low) or 0, -20, 10)
    eq.MidGain = math.clamp(tonumber(profile.EQ.Mid) or 0, -20, 10)
    eq.HighGain = math.clamp(tonumber(profile.EQ.High) or 0, -20, 10)
    eq.Parent = sound

    local reverb = Instance.new("ReverbSoundEffect")
    reverb.Name = "ArenaSpatialReverb"
    reverb.WetLevel = math.clamp(tonumber(profile.Reverb.Wet) or -30, -80, 10)
    reverb.DryLevel = 0
    reverb.DecayTime = math.clamp(tonumber(profile.Reverb.Decay) or 0.5, 0.1, 20)
    reverb.Density = math.clamp(tonumber(profile.Reverb.Density) or 0.6, 0, 1)
    reverb.Diffusion = math.clamp(tonumber(profile.Reverb.Diffusion) or 0.8, 0, 1)
    reverb.Parent = sound
end

local function makeLoop(anchor, name, soundName, pitch, baseVolume, minDistance, maxDistance, profile)
    local definition = AudioConfig.Sfx[soundName]
    if not definition then
        return nil
    end

    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = definition.SoundId
    sound.Looped = true
    sound.Volume = 0
    sound.PlaybackSpeed = pitch
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = minDistance
    sound.RollOffMaxDistance = maxDistance
    sound.EmitterSize = 7
    sound.SoundGroup = group
    sound:SetAttribute("ArenaBaseVolume", baseVolume)
    sound:SetAttribute("ArenaBasePitch", pitch)
    applyTreatment(sound, profile)
    sound.Parent = anchor
    sound:Play()
    table.insert(activeSounds, sound)
    return sound
end

local function targetScale()
    return ArenaSpatialAudioRules.phaseScale(phase, overdrive, finalRush)
end

local function refreshVolumes(duration)
    local scale = targetScale()
    local reaction = ArenaCrisisSurfaceRules.profile(
        activeDisasters, phase,
        VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name,
        player:GetAttribute("ReduceMotion") == true, finalRush
    )
    for _, sound in ipairs(activeSounds) do
        if sound and sound.Parent then
            local base = tonumber(sound:GetAttribute("ArenaBaseVolume")) or 0
            local basePitch = tonumber(sound:GetAttribute("ArenaBasePitch")) or 1
            TweenService:Create(
                sound,
                TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Volume = base * scale,
                    PlaybackSpeed = ArenaCrisisSurfaceRules.audio(basePitch, reaction),
                }
            ):Play()
        end
    end
end

local function rebuild()
    clear()

    local arena, base = arenaInfo()
    if not arena or not base then
        return
    end

    currentVariant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local profile = ArenaSpatialAudioRules.profile(currentVariant)
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local count = ArenaSpatialAudioRules.sourceCount(tier.Name)
    local minDistance, maxDistance = ArenaSpatialAudioRules.rolloff(tier.Name)
    local radius = math.min(
        profile.Radius,
        math.max(base.Size.X, base.Size.Z) * 0.50
    )

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2
            + (currentVariant == "Crossroads" and math.rad(45) or 0)
        local y = currentVariant == "Towers"
            and (7 + i * 3.5)
            or (currentVariant == "Orbital" and 10 or 5.5)

        local anchor = Instance.new("Part")
        anchor.Name = "ArenaAmbienceAnchor" .. i
        anchor.Size = Vector3.new(0.2, 0.2, 0.2)
        anchor.Position = base.CFrame:PointToWorldSpace(Vector3.new(
            math.cos(angle) * radius,
            base.Size.Y * 0.5 + 5.5 + y,
            math.sin(angle) * radius
        ))
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false
        anchor.Transparency = 1
        anchor.Parent = folder

        makeLoop(
            anchor,
            "ArenaBed" .. i,
            profile.Bed,
            profile.Pitch + (i - 1) * 0.012,
            profile.Volume / math.sqrt(count),
            minDistance,
            maxDistance,
            profile
        )

        if (tier.Name == "High" and i <= 2)
            or (tier.Name == "Medium" and i == 1)
        then
            makeLoop(
                anchor,
                "ArenaSecondary" .. i,
                profile.Secondary,
                profile.SecondaryPitch + (i - 1) * 0.010,
                profile.SecondaryVolume,
                minDistance,
                maxDistance * 0.88,
                profile
            )
        end
    end

    refreshVolumes(0.18)
end

local function bindMap()
    if disconnectMapWatch then
        disconnectMapWatch()
        disconnectMapWatch = nil
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    if generated then
        disconnectMapWatch = MapVisualReadiness.watch(
            generated, "Arena", "Base",
            function()
                task.defer(function()
                    -- Discard queued rebuilds from a replaced or removed map.
                    if generated == workspace:FindFirstChild("GeneratedMap") then
                        rebuild()
                    end
                end)
            end
        )
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(function()
            if workspace:FindFirstChild("GeneratedMap") == child then
                bindMap()
            end
        end)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clear()
        bindMap()
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(rebuild)

stateEvent.OnClientEvent:Connect(function(state)
    phase = tostring(state.phase or "waiting")
    overdrive = phase == "round" and state.overdrive == true
    finalRush = phase == "round" and state.finalRush == true
    activeDisasters = state.disasterIds or {}
    refreshVolumes(finalRush and 0.08 or 0.24)
end)

bindMap()
