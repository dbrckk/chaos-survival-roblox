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
for name, definition in pairs(AudioConfig.Sfx) do
    sfx[name] = makeSound(name, definition, sfxGroup)
end

local lobbyMusic = makeSound("LobbyMusic", AudioConfig.Music.Lobby, musicGroup)
lobbyMusic:Play()

local activeLoopName = nil
local lastPhase = nil
local lastTitle = nil
local lastCountdown = nil
local lastLevel = player:GetAttribute("Level") or 1

local function play(name)
    local sound = sfx[name]
    if not sound then return end
    sound.TimePosition = 0
    sound:Play()
end

local function bindButton(instance)
    if not instance:IsA("GuiButton") or boundButtons[instance] then
        return
    end

    boundButtons[instance] = true
    instance.Activated:Connect(function()
        play("UISelect")
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

    if phase == "round" then
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
            play("Countdown")
            lastCountdown = seconds
        end

        musicVolume(state.doubleChaos and 0.045 or 0.065, 0.2)
    elseif phase == "results" then
        stopDisasterLoop()
        musicVolume(0.09, 0.35)
        lastCountdown = nil
    else
        stopDisasterLoop()
        musicVolume(0.11, 0.4)
        lastCountdown = nil
    end

    lastPhase = phase
    lastTitle = state.title
end)

feedbackEvent.OnClientEvent:Connect(function(feedback)
    play(feedback.survived and "Survived" or "Eliminated")

    if (tonumber(feedback.streakBonusCoins) or 0) > 0 then
        task.delay(0.16, function()
            play("Reward")
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

player:GetAttributeChangedSignal("Level"):Connect(function()
    local level = player:GetAttribute("Level") or 1
    if level > lastLevel then
        play("LevelUp")
    end
    lastLevel = level
end)
