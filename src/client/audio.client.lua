local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local AudioConfig = require(ReplicatedStorage.Shared.AudioConfig)
local GroundContactRules = require(ReplicatedStorage.Shared.GroundContactRules)
local ImpactAudioRules = require(ReplicatedStorage.Shared.ImpactAudioRules)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local stateEvent = remotes:WaitForChild("RoundState")
local feedbackEvent = remotes:WaitForChild("RoundFeedback")
local dailyRewardEvent = remotes:WaitForChild("DailyReward")
local questEvent = remotes:WaitForChild("QuestUpdate")
local achievementEvent = remotes:WaitForChild("AchievementState")
local cosmeticStateEvent = remotes:WaitForChild("CosmeticState")
local chaosShardCollectedEvent = remotes:WaitForChild("ChaosShardCollected")
local hazardNearMissEvent = remotes:WaitForChild("HazardNearMiss")
local hazardImpactFeedbackEvent = remotes:WaitForChild("HazardImpactFeedback")
local mechanicFeedbackEvent = remotes:WaitForChild("ArenaMechanicFeedback")

local playerGui = player:WaitForChild("PlayerGui")
local boundButtons = setmetatable({}, {__mode = "k"})

local musicGroup = SoundService:FindFirstChild("ChaosMusic") or Instance.new("SoundGroup")
musicGroup.Name = "ChaosMusic"
musicGroup.Volume = 1
musicGroup.Parent = SoundService

local sfxGroup = SoundService:FindFirstChild("ChaosSFX") or Instance.new("SoundGroup")
sfxGroup.Name = "ChaosSFX"
sfxGroup.Volume = 1
sfxGroup.Parent = SoundService

local uiGroup = SoundService:FindFirstChild("ChaosUI") or Instance.new("SoundGroup")
uiGroup.Name = "ChaosUI"
uiGroup.Volume = 1
uiGroup.Parent = SoundService

local hazardGroup = SoundService:FindFirstChild("ChaosHazard") or Instance.new("SoundGroup")
hazardGroup.Name = "ChaosHazard"
hazardGroup.Volume = 1
hazardGroup.Parent = SoundService

local rewardGroup = SoundService:FindFirstChild("ChaosReward") or Instance.new("SoundGroup")
rewardGroup.Name = "ChaosReward"
rewardGroup.Volume = 1
rewardGroup.Parent = SoundService

local musicEq = musicGroup:FindFirstChild("ChaosMusicEQ") or Instance.new("EqualizerSoundEffect")
musicEq.Name = "ChaosMusicEQ"
musicEq.LowGain = 0
musicEq.MidGain = 0
musicEq.HighGain = 0
musicEq.Parent = musicGroup

local sfxEq = sfxGroup:FindFirstChild("ChaosSFXEQ") or Instance.new("EqualizerSoundEffect")
sfxEq.Name = "ChaosSFXEQ"
sfxEq.LowGain = 0
sfxEq.MidGain = 0
sfxEq.HighGain = 0
sfxEq.Parent = sfxGroup

local function applySoundTreatment(sound, name)
    local treatment = AudioConfig.Treatment and AudioConfig.Treatment[name]
    if type(treatment) ~= "table" then
        return
    end

    local eq = treatment.EQ
    if type(eq) == "table" then
        local effect = Instance.new("EqualizerSoundEffect")
        effect.Name = "CueEQ"
        effect.LowGain = math.clamp(tonumber(eq.Low) or 0, -20, 10)
        effect.MidGain = math.clamp(tonumber(eq.Mid) or 0, -20, 10)
        effect.HighGain = math.clamp(tonumber(eq.High) or 0, -20, 10)
        effect.Parent = sound
    end

    local reverb = treatment.Reverb
    if type(reverb) == "table" then
        local effect = Instance.new("ReverbSoundEffect")
        effect.Name = "CueReverb"
        effect.WetLevel = math.clamp(tonumber(reverb.Wet) or -24, -80, 10)
        effect.DryLevel = math.clamp(tonumber(reverb.Dry) or 0, -80, 10)
        effect.DecayTime = math.clamp(tonumber(reverb.Decay) or 0.5, 0.1, 20)
        effect.Density = math.clamp(tonumber(reverb.Density) or 0.7, 0, 1)
        effect.Diffusion = math.clamp(tonumber(reverb.Diffusion) or 0.8, 0, 1)
        effect.Parent = sound
    end
end

local function makeSound(name, definition, group)
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = definition.SoundId
    sound.Volume = definition.Volume or 0.3
    sound.PlaybackSpeed = definition.PlaybackSpeed or 1
    sound.Looped = definition.Looped == true
    sound.SoundGroup = group
    applySoundTreatment(sound, name)
    sound.Parent = SoundService
    return sound
end

local UI_SOUNDS = {
    UISelect = true,
    Vote = true,
    Countdown = true,
    Ready = true,
}
local REWARD_SOUNDS = {
    Reward = true,
    ShardCollect = true,
    GoldenShard = true,
    LevelUp = true,
    Survived = true,
    MasterRound = true,
    FlowCombo = true,
    LastSurvivor = true,
}
local HAZARD_SOUNDS = {
    DoubleChaos = true,
    Eliminated = true,
    Hit = true,
    JumpShock = true,
    Meteor = true,
    Bombs = true,
    Wind = true,
    LowGravity = true,
    Lava = true,
    PlatformWarning = true,
    Tornado = true,
    Freeze = true,
    Speed = true,
    MobilityPad = true,
    Overdrive = true,
    FinalRush = true,
    Darkness = true,
    Shrink = true,
    RoundStart = true,
}

local function soundGroupFor(name)
    if UI_SOUNDS[name] then
        return uiGroup
    elseif REWARD_SOUNDS[name] then
        return rewardGroup
    elseif HAZARD_SOUNDS[name] then
        return hazardGroup
    end
    return sfxGroup
end

local sfx = {}
local basePlaybackSpeeds = {}
local baseVolumes = {}
for name, definition in pairs(AudioConfig.Sfx) do
    sfx[name] = makeSound(name, definition, soundGroupFor(name))
    basePlaybackSpeeds[name] = definition.PlaybackSpeed or 1
    baseVolumes[name] = definition.Volume or 0.3
end

local lobbyMusic = makeSound("LobbyMusic", AudioConfig.Music.Lobby, musicGroup)
lobbyMusic:Play()

local activeLoopName = nil
local loopVolumeTweens = {}
local lastPhase = nil
local lastTitle = nil
local lastCountdown = nil
local lastReadyCountdown = nil
local lastLevel = player:GetAttribute("Level") or 1
local lastSurvivorCuePlayed = false
local currentIntensity = 1
local lastOverdrive = false
local lastFinalRush = false

local ARENA_AUDIO = {
    Classic = {Pitch = 1.000, Low = 0.0, Mid = 0.2, High = 0.4},
    Towers = {Pitch = 0.988, Low = 0.8, Mid = -0.4, High = 1.0},
    Crossroads = {Pitch = 1.012, Low = -0.8, Mid = 1.1, High = 0.6},
    Orbital = {Pitch = 0.976, Low = 1.2, Mid = -0.7, High = -0.2},
}

local function arenaAudioProfile()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local id = arena and arena:GetAttribute("VariantId")
    return ARENA_AUDIO[tostring(id or "Classic")] or ARENA_AUDIO.Classic
end

local activeVoices = {}

local function playRaw(name, pitchVariance, volumeScale, pitchOffset)
    local baseSound = sfx[name]
    if not baseSound then return end

    local sound = baseSound
    local needsVoice = baseSound.Looped or baseSound.IsPlaying
    if needsVoice then
        local active = activeVoices[name] or 0
        if active >= 2 then
            return
        end

        sound = baseSound:Clone()
        sound.Name = name .. "Voice"
        sound.Looped = false
        sound.Parent = SoundService
        activeVoices[name] = active + 1

        local cleaned = false
        local function cleanup()
            if cleaned then
                return
            end
            cleaned = true
            activeVoices[name] = math.max(0, (activeVoices[name] or 1) - 1)
            if sound.Parent then
                sound:Destroy()
            end
        end

        sound.Ended:Connect(cleanup)
        task.delay(baseSound.Looped and 1.6 or 3.5, cleanup)
    end

    local baseSpeed = basePlaybackSpeeds[name] or 1
    local variance = math.max(0, tonumber(pitchVariance) or 0)
    local randomOffset = variance > 0 and ((math.random() * 2 - 1) * variance) or 0
    sound.PlaybackSpeed = math.clamp(
        baseSpeed + randomOffset + (tonumber(pitchOffset) or 0),
        0.5,
        2.5
    )
    sound.Volume = (baseVolumes[name] or sound.Volume) * math.max(0, tonumber(volumeScale) or 1)
    sound.TimePosition = 0
    sound:Play()
end

local function play(name, pitchVariance)
    local composite = AudioConfig.Composite and AudioConfig.Composite[name]
    if type(composite) ~= "table" then
        playRaw(name, pitchVariance, 1, 0)
        return
    end

    for _, layer in ipairs(composite) do
        local soundName = layer.Sound
        local delaySeconds = math.max(0, tonumber(layer.Delay) or 0)
        local volumeScale = math.max(0, tonumber(layer.VolumeScale) or 1)
        local pitchOffset = tonumber(layer.PitchOffset) or 0

        if delaySeconds > 0 then
            task.delay(delaySeconds, function()
                playRaw(soundName, pitchVariance, volumeScale, pitchOffset)
            end)
        else
            playRaw(soundName, pitchVariance, volumeScale, pitchOffset)
        end
    end
end

local function bindButton(instance)
    if not instance:IsA("GuiButton") or boundButtons[instance] then
        return
    end

    boundButtons[instance] = true
    instance.Activated:Connect(function()
        play("UISelect", 0.035)
    end)
end

for _, descendant in ipairs(playerGui:GetDescendants()) do
    bindButton(descendant)
end

playerGui.DescendantAdded:Connect(bindButton)

local function tweenLoopVolume(name, sound, targetVolume, duration)
    local previousTween = loopVolumeTweens[name]
    if previousTween then
        previousTween:Cancel()
    end

    local tween = TweenService:Create(
        sound,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Volume = targetVolume}
    )
    loopVolumeTweens[name] = tween
    tween:Play()

    task.delay(duration + 0.03, function()
        if loopVolumeTweens[name] == tween then
            loopVolumeTweens[name] = nil
        end
    end)
end

local function stopDisasterLoop()
    if not activeLoopName then
        return
    end

    local previousName = activeLoopName
    local sound = sfx[previousName]
    activeLoopName = nil

    if sound and sound.Looped then
        local duration = math.clamp(
            tonumber(AudioConfig.LoopCrossfadeSeconds) or 0.18,
            0.05,
            0.40
        )
        tweenLoopVolume(previousName, sound, 0, duration)
        task.delay(duration + 0.02, function()
            if activeLoopName ~= previousName and sound.Parent then
                sound:Stop()
                sound.Volume = baseVolumes[previousName] or sound.Volume
            end
        end)
    end
end

local function setDisasterLoop(disasterIds)
    local targetName = nil
    local bestPriority = -math.huge

    for _, id in ipairs(disasterIds or {}) do
        local candidate = AudioConfig.DisasterLoop[id]
        local priority = tonumber(
            AudioConfig.DisasterLoopPriority
                and AudioConfig.DisasterLoopPriority[id]
        ) or 0

        if candidate and priority > bestPriority then
            targetName = candidate
            bestPriority = priority
        end
    end

    if targetName == activeLoopName then return end

    stopDisasterLoop()
    if targetName and sfx[targetName] then
        activeLoopName = targetName
        local sound = sfx[targetName]
        local duration = math.clamp(
            tonumber(AudioConfig.LoopCrossfadeSeconds) or 0.18,
            0.05,
            0.40
        )

        sound.PlaybackSpeed = math.clamp(
            (basePlaybackSpeeds[targetName] or 1) * (0.96 + (currentIntensity * 0.04)),
            0.6,
            1.5
        )
        sound.Volume = 0
        if not sound.IsPlaying then
            sound:Play()
        end
        tweenLoopVolume(
            targetName,
            sound,
            baseVolumes[targetName] or 0.2,
            duration
        )
    end
end

local function musicVolume(target, duration)
    TweenService:Create(
        lobbyMusic,
        TweenInfo.new(duration or 0.25),
        {Volume = target}
    ):Play()
end

local function setMix(phase, overdrive, finalRush)
    local musicTarget = 1
    local sfxTarget = 1
    local uiTarget = 1
    local hazardTarget = 1
    local rewardTarget = 1
    local lowGain = 0
    local midGain = 0
    local highGain = 0
    local arenaProfile = arenaAudioProfile()

    if phase == "round" then
        musicTarget = finalRush and 0.72 or (overdrive and 0.82 or 0.90)
        sfxTarget = 0.96
        uiTarget = finalRush and 0.64 or 0.78
        hazardTarget = 1
        rewardTarget = finalRush and 0.70 or 0.86
        lowGain = finalRush and -2.5 or -1.2
        highGain = finalRush and -1.8 or -0.5
    elseif phase == "ready" then
        musicTarget = 0.88
        sfxTarget = 0.94
        uiTarget = 0.92
        hazardTarget = 0.96
        rewardTarget = 0.90
        lowGain = -0.8
    elseif phase == "result" then
        musicTarget = 1
        sfxTarget = 0.96
        uiTarget = 0.94
        hazardTarget = 0.88
        rewardTarget = 1
    end

    local userScale = player:GetAttribute("AudioMuted") == true and 0 or 1
    musicTarget *= userScale
    sfxTarget *= userScale
    uiTarget *= userScale
    hazardTarget *= userScale
    rewardTarget *= userScale

    TweenService:Create(musicGroup, TweenInfo.new(0.18), {Volume = musicTarget}):Play()
    TweenService:Create(sfxGroup, TweenInfo.new(0.12), {Volume = sfxTarget}):Play()
    TweenService:Create(uiGroup, TweenInfo.new(0.12), {Volume = uiTarget}):Play()
    TweenService:Create(hazardGroup, TweenInfo.new(0.10), {Volume = hazardTarget}):Play()
    TweenService:Create(rewardGroup, TweenInfo.new(0.14), {Volume = rewardTarget}):Play()
    TweenService:Create(musicEq, TweenInfo.new(0.18), {
        LowGain = lowGain + arenaProfile.Low,
        MidGain = midGain + arenaProfile.Mid,
        HighGain = highGain + arenaProfile.High,
    }):Play()
end

setMix(lastPhase or "waiting", lastOverdrive, lastFinalRush)

local lastSpatialImpactAt = 0
local function playSpatialImpact(payload)
    if type(payload) ~= "table" then return end
    local position = payload.position
    if typeof(position) ~= "Vector3" then return end

    local camera = workspace.CurrentCamera
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local observer = camera and camera.CFrame.Position
        or (root and root:IsA("BasePart") and root.Position)
    if not observer then return end

    local kind = tostring(payload.kind or "")
    local definition = kind == "Meteor" and AudioConfig.Sfx.Meteor
        or (kind == "Bomb" and AudioConfig.Sfx.Bombs or nil)
    if not definition then return end

    local tierName = VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
    local plan = ImpactAudioRules.plan(
        kind, (position - observer).Magnitude, tierName,
        player:GetAttribute("AudioMuted") == true)
    if not plan then return end

    local now = os.clock()
    if now - lastSpatialImpactAt < 0.10 then return end
    lastSpatialImpactAt = now

    local holder = Instance.new("Part")
    holder.Name = "LocalSpatialImpactAudio"
    holder.Size = Vector3.new(0.2, 0.2, 0.2)
    holder.Position = position
    holder.Anchored = true
    holder.CanCollide = false
    holder.CanTouch = false
    holder.CanQuery = false
    holder.Transparency = 1
    holder.Parent = workspace

    local function addLayer(name, layerDefinition, volumeScale, pitchOffset, delaySeconds)
        if not layerDefinition then
            return
        end

        local sound = Instance.new("Sound")
        sound.Name = name
        sound.SoundId = layerDefinition.SoundId
        sound.Volume = math.clamp(
            (layerDefinition.Volume or 0.3)
                * math.max(0, volumeScale or 1) * plan.VolumeScale,
            0, 0.7
        )
        sound.PlaybackSpeed = math.clamp(
            (layerDefinition.PlaybackSpeed or 1)
                + ((math.random() - 0.5) * 0.08)
                + (pitchOffset or 0),
            0.50,
            2.3
        )
        sound.RollOffMode = Enum.RollOffMode.InverseTapered
        sound.RollOffMinDistance = plan.MinDistance
        sound.RollOffMaxDistance = plan.MaxDistance
        sound.EmitterSize = 6
        sound.SoundGroup = hazardGroup
        sound.Parent = holder

        local delayValue = math.max(0, delaySeconds or 0)
        if delayValue > 0 then
            task.delay(delayValue, function()
                if sound.Parent then
                    sound:Play()
                end
            end)
        else
            sound:Play()
        end
    end

    addLayer(
        kind .. "Spatial",
        definition,
        0.88,
        kind == "Bomb" and -0.04 or 0.02,
        0
    )

    if plan.LayerCount >= 2 and kind == "Meteor" then
        addLayer(
            "MeteorAirTail",
            AudioConfig.Sfx.Wind,
            0.18,
            0.24,
            0.015
        )
        if plan.LayerCount >= 3 then
            addLayer(
                "MeteorBody",
                AudioConfig.Sfx.Hit,
                0.15,
                -0.34,
                0.045
            )
        end
    elseif plan.LayerCount >= 2 and kind == "Bomb" then
        addLayer(
            "BombBody",
            AudioConfig.Sfx.Hit,
            0.24,
            -0.46,
            0.018
        )
        if plan.LayerCount >= 3 then
            addLayer(
                "BombTail",
                AudioConfig.Sfx.Darkness,
                0.12,
                -0.26,
                0.070
            )
        end
    end

    Debris:AddItem(holder, plan.Lifetime)
end

stateEvent.OnClientEvent:Connect(function(state)
    local phase = state.phase
    local seconds = tonumber(state.seconds) or 0
    currentIntensity = math.clamp(tonumber(state.intensity) or 1, 0.85, 1.25)
    local overdrive = phase == "round" and state.overdrive == true
    local finalRush = phase == "round" and state.finalRush == true

    setMix(phase, overdrive, finalRush)

    if finalRush and not lastFinalRush then
        play("FinalRush")
    end

    if overdrive and not lastOverdrive then
        play("Overdrive")
        task.delay(0.10, function()
            play("Speed", 0.03)
        end)
    end

    local arenaProfile = arenaAudioProfile()
    lobbyMusic.PlaybackSpeed = math.clamp(
        (AudioConfig.Music.Lobby.PlaybackSpeed or 1)
            * arenaProfile.Pitch
            * (0.985 + ((currentIntensity - 0.9) * 0.05))
            * (overdrive and 1.035 or 1),
        0.94,
        1.10
    )

    if activeLoopName and sfx[activeLoopName] then
        sfx[activeLoopName].PlaybackSpeed = math.clamp(
            (basePlaybackSpeeds[activeLoopName] or 1) * (0.96 + (currentIntensity * 0.04)),
            0.6,
            1.5
        )
    end

    if phase == "ready" then
        stopDisasterLoop()
        if phase ~= lastPhase or state.title ~= lastTitle then
            play("Ready")
        end

        local readySecond = math.floor(seconds)
        if readySecond >= 1
            and readySecond <= 3
            and readySecond ~= lastReadyCountdown
        then
            playRaw(
                "Countdown",
                0,
                readySecond == 1 and 0.34 or 0.24,
                (3 - readySecond) * 0.10
            )
            lastReadyCountdown = readySecond
        end

        musicVolume(0.08, 0.18)
    elseif phase == "round" then
        lastReadyCountdown = nil
        setDisasterLoop(state.disasterIds)

        if phase ~= lastPhase or state.title ~= lastTitle then
            play(state.doubleChaos and "DoubleChaos" or "RoundStart")

            for index, id in ipairs(state.disasterIds or {}) do
                local accent = AudioConfig.DisasterAccent[id]
                if accent then
                    local doublePolicy = AudioConfig.DoubleChaosAccent or {}
                    local delaySeconds = 0.10
                        + ((index - 1) * (tonumber(doublePolicy.StaggerSeconds) or 0.055))

                    task.delay(delaySeconds, function()
                        if state.doubleChaos == true then
                            playRaw(
                                accent,
                                tonumber(doublePolicy.PitchVariance) or 0.018,
                                tonumber(doublePolicy.VolumeScale) or 0.52,
                                index == 1 and -0.015 or 0.025
                            )
                        else
                            play(accent)
                        end
                    end)
                end
            end
        end

        if seconds <= 5 and seconds > 0 and seconds ~= lastCountdown then
            play("Countdown", 0.02)
            lastCountdown = seconds
        end

        musicVolume(overdrive and 0.075 or (state.doubleChaos and 0.045 or 0.065), 0.2)
    elseif phase == "result" then
        stopDisasterLoop()
        musicVolume(0.09, 0.35)
        lastCountdown = nil
        lastReadyCountdown = nil
    else
        stopDisasterLoop()
        musicVolume(0.11, 0.4)
        lastCountdown = nil
        lastReadyCountdown = nil
    end

    local alive = tonumber(state.survivorsAlive)
    local total = tonumber(state.contestantCount)
    if phase == "round" and total and total > 1 and alive == 1 then
        if not lastSurvivorCuePlayed then
            lastSurvivorCuePlayed = true
            play("LastSurvivor")
        end
    elseif phase ~= "round" or (alive and alive > 1) then
        lastSurvivorCuePlayed = false
    end

    lastFinalRush = finalRush
    lastOverdrive = overdrive
    lastPhase = phase
    lastTitle = state.title
end)

player:GetAttributeChangedSignal("AudioMuted"):Connect(function()
    setMix(lastPhase or "waiting", lastOverdrive, lastFinalRush)
end)

feedbackEvent.OnClientEvent:Connect(function(feedback)
    local momentumBest = math.max(0, math.floor(tonumber(feedback.momentumBest) or 0))
    local masterRound = feedback.survived == true
        and feedback.challengeCompleted == true
        and momentumBest >= 4

    play(feedback.survived and "Survived" or "Eliminated", 0.025)
    if masterRound then
        task.delay(0.08, function()
            play("MasterRound", 0.02)
        end)
    end

    if feedback.criticalSurvival then
        task.delay(0.12, function()
            play("LastSurvivor", 0.03)
        end)
    end

    if feedback.challengeCompleted then
        task.delay(0.10, function()
            play("LevelUp", 0.03)
        end)
    elseif type(feedback.medals) == "table" and #feedback.medals > 0 then
        task.delay(0.12, function()
            play("Reward", 0.04)
        end)
    end

    if (tonumber(feedback.streakBonusCoins) or 0) > 0 then
        task.delay(0.16, function()
            play("Reward", 0.045)
        end)
    end
end)

dailyRewardEvent.OnClientEvent:Connect(function()
    play("Reward")
end)

questEvent.OnClientEvent:Connect(function(payload)
    if #(payload.completed or {}) > 0 then
        play("Reward")
    end
end)

achievementEvent.OnClientEvent:Connect(function(payload)
    if #(payload.unlockedNow or {}) > 0 then
        play("LevelUp")
    end
end)

cosmeticStateEvent.OnClientEvent:Connect(function(payload)
    if #(payload.unlocked or {}) > 0 then
        play("Reward")
    end
end)

chaosShardCollectedEvent.OnClientEvent:Connect(function(payload)
    local total = math.max(1, math.floor(tonumber(payload.total) or 1))
    local variance = math.min(0.08, total * 0.008)
    if payload.golden == true then
        play("GoldenShard", 0.025)
    else
        play("ShardCollect", variance)
    end

    if (tonumber(payload.flowBonus) or 0) > 0 then
        task.delay(0.06, function()
            play("FlowCombo", 0.03)
        end)
    end
end)

hazardNearMissEvent.OnClientEvent:Connect(function()
    play("NearMiss", 0.035)
end)

hazardImpactFeedbackEvent.OnClientEvent:Connect(playSpatialImpact)

mechanicFeedbackEvent.OnClientEvent:Connect(function(payload)
    play("MobilityPad", 0.025)
    if type(payload) == "table" and payload.overdrive == true then
        task.delay(0.045, function()
            playRaw("Overdrive", 0.02, 0.24, 0.10)
        end)
    end
end)

local lastLobbyPracticeUses = math.max(
    0,
    math.floor(tonumber(player:GetAttribute("LobbyPracticeUses")) or 0)
)
player:GetAttributeChangedSignal("LobbyPracticeUses"):Connect(function()
    local nextUses = math.max(
        0,
        math.floor(tonumber(player:GetAttribute("LobbyPracticeUses")) or 0)
    )
    if nextUses > lastLobbyPracticeUses then
        play("MobilityPad", 0.02)
    end
    lastLobbyPracticeUses = nextUses
end)

player:GetAttributeChangedSignal("Level"):Connect(function()
    local level = player:GetAttribute("Level") or 1
    if level > lastLevel then
        play("LevelUp")
    end
    lastLevel = level
end)


local healthConnection = nil
local stateConnection = nil

local function bindHealthAudio(character)
    if healthConnection then
        healthConnection:Disconnect()
        healthConnection = nil
    end
    if stateConnection then
        stateConnection:Disconnect()
        stateConnection = nil
    end

    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then
        return
    end

    local previousHealth = humanoid.Health
    local airborneAt = nil

    stateConnection = humanoid.StateChanged:Connect(function(_, state)
        if state == Enum.HumanoidStateType.Freefall then
            airborneAt = airborneAt or os.clock()
        elseif airborneAt and (
            state == Enum.HumanoidStateType.Landed
            or state == Enum.HumanoidStateType.Running
            or state == Enum.HumanoidStateType.RunningNoPhysics
        ) then
            local airtime = os.clock() - airborneAt
            airborneAt = nil

            if player.Character == character and humanoid.Health > 0
                and GroundContactRules.eligible(
                    lastPhase, true,
                    player:GetAttribute("RoundParticipant"),
                    player:GetAttribute("RoundEliminated"), false)
            then
                local plan = GroundContactRules.landingAudio(
                    humanoid.FloorMaterial, airtime,
                    VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name,
                    player:GetAttribute("ReduceMotion") == true)
                if plan then
                    playRaw("Hit", 0.015, plan.VolumeScale, plan.PitchOffset)
                end
            end
        end
    end)

    healthConnection = humanoid.HealthChanged:Connect(function(health)
        if health < previousHealth and health > 0 then
            play("Hit")
        end
        previousHealth = health
    end)
end

if player.Character then
    task.spawn(bindHealthAudio, player.Character)
end

player.CharacterAdded:Connect(bindHealthAudio)
