local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local AudioConfig = require(ReplicatedStorage.Shared.AudioConfig)

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

local function makeSound(name, definition, group)
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = definition.SoundId
    sound.Volume = definition.Volume or 0.3
    sound.PlaybackSpeed = definition.PlaybackSpeed or 1
    sound.Looped = definition.Looped == true
    sound.SoundGroup = group
    sound.Parent = SoundService
    return sound
end

local sfx = {}
local basePlaybackSpeeds = {}
local baseVolumes = {}
for name, definition in pairs(AudioConfig.Sfx) do
    sfx[name] = makeSound(name, definition, sfxGroup)
    basePlaybackSpeeds[name] = definition.PlaybackSpeed or 1
    baseVolumes[name] = definition.Volume or 0.3
end

local lobbyMusic = makeSound("LobbyMusic", AudioConfig.Music.Lobby, musicGroup)
lobbyMusic:Play()

local activeLoopName = nil
local lastPhase = nil
local lastTitle = nil
local lastCountdown = nil
local lastLevel = player:GetAttribute("Level") or 1
local lastSurvivorCuePlayed = false
local currentIntensity = 1
local lastOverdrive = false
local lastFinalRush = false

local function play(name, pitchVariance)
    local sound = sfx[name]
    if not sound then return end

    local baseSpeed = basePlaybackSpeeds[name] or 1
    local variance = math.max(0, tonumber(pitchVariance) or 0)
    local offset = variance > 0 and ((math.random() * 2 - 1) * variance) or 0
    sound.PlaybackSpeed = math.clamp(baseSpeed + offset, 0.5, 2.5)
    sound.Volume = baseVolumes[name] or sound.Volume
    sound.TimePosition = 0
    sound:Play()
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

local function stopDisasterLoop()
    if activeLoopName then
        local sound = sfx[activeLoopName]
        if sound and sound.Looped then
            sound:Stop()
        end
        activeLoopName = nil
    end
end

local function setDisasterLoop(disasterIds)
    local targetName = nil
    for _, id in ipairs(disasterIds or {}) do
        targetName = AudioConfig.DisasterLoop[id] or targetName
    end

    if targetName == activeLoopName then return end

    stopDisasterLoop()
    if targetName and sfx[targetName] then
        activeLoopName = targetName
        sfx[targetName].PlaybackSpeed = math.clamp(
            (basePlaybackSpeeds[targetName] or 1) * (0.96 + (currentIntensity * 0.04)),
            0.6,
            1.5
        )
        sfx[targetName]:Play()
    end
end

local function musicVolume(target, duration)
    TweenService:Create(
        lobbyMusic,
        TweenInfo.new(duration or 0.25),
        {Volume = target}
    ):Play()
end

stateEvent.OnClientEvent:Connect(function(state)
    local phase = state.phase
    local seconds = tonumber(state.seconds) or 0
    currentIntensity = math.clamp(tonumber(state.intensity) or 1, 0.85, 1.25)
    local overdrive = phase == "round" and state.overdrive == true
    local finalRush = phase == "round" and state.finalRush == true

    if finalRush and not lastFinalRush then
        play("FinalRush")
        task.delay(0.08, function()
            play("Countdown", 0.01)
        end)
    end

    if overdrive and not lastOverdrive then
        play("Overdrive")
        task.delay(0.10, function()
            play("Speed", 0.03)
        end)
    end

    lobbyMusic.PlaybackSpeed = math.clamp(
        (AudioConfig.Music.Lobby.PlaybackSpeed or 1)
            * (0.985 + ((currentIntensity - 0.9) * 0.05))
            * (overdrive and 1.035 or 1),
        0.96,
        1.08
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
        musicVolume(0.08, 0.18)
    elseif phase == "round" then
        setDisasterLoop(state.disasterIds)

        if phase ~= lastPhase or state.title ~= lastTitle then
            play(state.doubleChaos and "DoubleChaos" or "RoundStart")

            for _, id in ipairs(state.disasterIds or {}) do
                local accent = AudioConfig.DisasterAccent[id]
                if accent then
                    task.delay(0.10, function()
                        play(accent)
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
    else
        stopDisasterLoop()
        musicVolume(0.11, 0.4)
        lastCountdown = nil
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

feedbackEvent.OnClientEvent:Connect(function(feedback)
    play(feedback.survived and "Survived" or "Eliminated", 0.025)

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
        task.delay(0.07, function()
            play("Reward", 0.02)
        end)
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
    play("Speed", 0.05)
end)

player:GetAttributeChangedSignal("Level"):Connect(function()
    local level = player:GetAttribute("Level") or 1
    if level > lastLevel then
        play("LevelUp")
    end
    lastLevel = level
end)


local healthConnection = nil

local function bindHealthAudio(character)
    if healthConnection then
        healthConnection:Disconnect()
        healthConnection = nil
    end

    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then
        return
    end

    local previousHealth = humanoid.Health
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
