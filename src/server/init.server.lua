local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Config = require(ReplicatedStorage.Shared.Config)
local isStudioE2E = false

if RunService:IsStudio() then
    local okService, StudioTestService = pcall(game.GetService, game, "StudioTestService")
    if okService and StudioTestService then
        local okArgs, args = pcall(StudioTestService.GetTestArgs, StudioTestService)
        if okArgs and type(args) == "table" and args.suite == "ChaosE2E" then
            isStudioE2E = true
            Config.IntermissionSeconds = 2
            Config.VoteSeconds = 2
            Config.ReadySeconds = 1
            Config.RoundSeconds = 6
            Config.PostRoundSeconds = 2
            Config.Solo.IntermissionSeconds = 2
            Config.Solo.VoteSeconds = 2
            Config.Solo.ReadySeconds = 1
            Config.Solo.RoundSeconds = 5
            Config.Solo.PostRoundSeconds = 2
        end
    end
end
local MapBuilder = require(script.MapBuilder)
local LobbyActivities = require(script.LobbyActivities)
local PlayerData = require(script.PlayerData)
local PlayerReadiness = require(script.PlayerReadiness)
local RemoteRegistry = require(script.RemoteRegistry)
local RateLimiter = require(script.RateLimiter)
local CosmeticService = require(script.CosmeticService)
local MonetizationService = require(script.MonetizationService)
local AchievementService = require(script.AchievementService)
local SoloRules = require(script.SoloRules)
local GameAnalytics = require(script.GameAnalytics)
local ArenaVariants = require(script.ArenaVariants)
local ArenaMechanics = require(script.ArenaMechanics)
local DisasterBalance = require(script.DisasterBalance)
local EliminationCauseRules = require(script.EliminationCauseRules)
local SessionStreak = require(script.SessionStreak)
local RoundVariety = require(script.RoundVariety)
local RoundIntensity = require(script.RoundIntensity)
local RoundCleanup = require(script.RoundCleanup)
local SurvivalFeedback = require(script.SurvivalFeedback)
local RoundCollectibles = require(script.RoundCollectibles)
local RoundChallenge = require(script.RoundChallenge)
local RoundMedals = require(script.RoundMedals)
local FlowCombo = require(script.FlowCombo)
local ChaosFusion = require(script.ChaosFusion)
local RoundMomentum = require(script.RoundMomentum)
local AISurvivorService = require(script.AISurvivorService)
local Mastery = require(script.Mastery)
local FirstTimeExperience = require(ReplicatedStorage.Shared.FirstTimeExperience)
local SocialExperienceRules = require(ReplicatedStorage.Shared.SocialExperienceRules)
local VisualBudgetRules = require(ReplicatedStorage.Shared.VisualBudgetRules)
local ResultPresentation = require(ReplicatedStorage.Shared.ResultPresentation)

local remotes = RemoteRegistry.ensureFolder(ReplicatedStorage, "Remotes")
local stateEvent = RemoteRegistry.ensureRemoteEvent(remotes, "RoundState")
local voteEvent = RemoteRegistry.ensureRemoteEvent(remotes, "VoteDisaster")
local dailyRewardEvent = RemoteRegistry.ensureRemoteEvent(remotes, "DailyReward")
local questEvent = RemoteRegistry.ensureRemoteEvent(remotes, "QuestUpdate")
local roundFeedbackEvent = RemoteRegistry.ensureRemoteEvent(remotes, "RoundFeedback")
local clientReadyEvent = RemoteRegistry.ensureRemoteEvent(remotes, "ClientReady")
local arenaMechanicFeedbackEvent = RemoteRegistry.ensureRemoteEvent(remotes, "ArenaMechanicFeedback")
local hazardImpactFeedbackEvent = RemoteRegistry.ensureRemoteEvent(remotes, "HazardImpactFeedback")
local hazardNearMissEvent = RemoteRegistry.ensureRemoteEvent(remotes, "HazardNearMiss")
local chaosShardCollectedEvent = RemoteRegistry.ensureRemoteEvent(remotes, "ChaosShardCollected")
local performancePulseEvent = RemoteRegistry.ensureRemoteEvent(remotes, "PerformancePulse")
local accessibilitySettingsEvent = RemoteRegistry.ensureRemoteEvent(remotes, "AccessibilitySettings")
local socialSignalEvent = RemoteRegistry.ensureRemoteEvent(remotes, "SocialSignal")
local socialReactionEvent = RemoteRegistry.ensureRemoteEvent(remotes, "SocialReaction")

PlayerData.init()
CosmeticService.init(remotes, RateLimiter)
MonetizationService.init(remotes, RateLimiter, CosmeticService)
AchievementService.init(remotes)

local allowAccessibilityChange = RateLimiter.new(0.35)
accessibilitySettingsEvent.OnServerEvent:Connect(function(player, setting, value)
    if type(setting) ~= "string" or type(value) ~= "boolean" then
        return
    end
    if setting ~= "ReduceMotion"
        and setting ~= "AudioMuted"
        and setting ~= "HapticsDisabled"
    then
        return
    end
    if not allowAccessibilityChange(tostring(player.UserId) .. ":" .. setting) then
        return
    end
    if not PlayerData.canMutate(player) then
        return
    end

    player:SetAttribute(setting, value)
    task.spawn(PlayerData.save, player, true)
    GameAnalytics.custom(
        player,
        "AccessibilitySettingChanged",
        value and 1 or 0,
        "Setting:" .. setting,
        "Device:" .. (player:GetAttribute("ClientDeviceClass") or "Unknown")
    )
end)

MapBuilder.build(Config, "Classic", ArenaVariants)
local lobbyActivitiesOk, lobbyActivitiesError = pcall(LobbyActivities.start, Config)
if not lobbyActivitiesOk then
    warn("Lobby activities failed to start:", lobbyActivitiesError)
end

local aiSurvivorsOk, aiSurvivorsError = pcall(AISurvivorService.start, Config)
if not aiSurvivorsOk then
    warn("AI Survivors failed to start:", aiSurvivorsError)
end

local disasterModules = {}
for _, module in ipairs(script.Disasters:GetChildren()) do
    if module:IsA("ModuleScript") then
        table.insert(disasterModules, module)
    end
end
table.sort(disasterModules, function(a, b)
    return a.Name < b.Name
end)

local disasters = {}
for _, module in ipairs(disasterModules) do
        local ok, loaded = pcall(require, module)
        if not ok then
            warn("Disaster module failed to load:", module.Name, loaded)
            continue
        end

        if type(loaded) ~= "table"
            or type(loaded.start) ~= "function"
            or type(loaded.Name) ~= "string"
            or loaded.Name == ""
        then
            warn("Disaster module has an invalid contract:", module.Name)
            continue
        end

        loaded.Id = module.Name
        table.insert(disasters, loaded)
end
assert(#disasters >= 3, "At least 3 valid disasters are required")

local roundNumber = 0
local currentArenaVariant = "Classic"
local recentArenaVariantIds = {currentArenaVariant}
local studioE2EArenaIndex = 0
local recentPrimaryDisasterIds = {}
local currentVotes = {}
local currentOptions = {}
local voteOpen = false
local botVoteStarted = false
local allowVote = RateLimiter.new(0.2)
local allowHazardNearMiss = RateLimiter.new(0.9)
local allowPerformancePulse = RateLimiter.new(45)
local allowSocialSignal = RateLimiter.new(1.5)
local allowSocialReaction = RateLimiter.new(0.8)
local reactionRoundByUser = {}
local lastRoundState = {
    phase = "waiting",
    title = "WAITING FOR PLAYERS",
    hint = "",
    seconds = 0,
}

local function broadcast(payload)
    lastRoundState = payload
    pcall(AISurvivorService.setRoundState, payload)
    stateEvent:FireAllClients(payload)
end

performancePulseEvent.OnServerEvent:Connect(function(player, payload)
    if player.Parent ~= Players
        or type(payload) ~= "table"
        or not allowPerformancePulse(player.UserId)
    then
        return
    end

    local fps = math.clamp(tonumber(payload.averageFps) or 0, 0, 240)
    local tier = tostring(payload.vfxTier or "Unknown")
    if tier ~= "High" and tier ~= "Medium" and tier ~= "Low" then
        tier = "Unknown"
    end

    local deviceClass = tostring(payload.deviceClass or "Unknown")
    if #deviceClass > 24 then
        deviceClass = string.sub(deviceClass, 1, 24)
    end

    local tierTransitions = math.clamp(
        math.floor(tonumber(payload.tierTransitions) or 0),
        0,
        99
    )
    local visualParts = math.clamp(
        math.floor(tonumber(payload.visualParts) or 0),
        0,
        5000
    )
    local visualLights = math.clamp(
        math.floor(tonumber(payload.visualLights) or 0),
        0,
        1000
    )
    local visualEffects = math.clamp(
        math.floor(tonumber(payload.visualEffects) or 0),
        0,
        2000
    )
    local totalMemoryMb = math.clamp(
        tonumber(payload.totalMemoryMb) or 0,
        0,
        65536
    )
    local instanceCount = math.clamp(
        math.floor(tonumber(payload.instanceCount) or 0),
        0,
        250000
    )
    local frameTimeMs = math.clamp(
        tonumber(payload.frameTimeMs) or 0,
        0,
        1000
    )
    local renderCpuMs = math.clamp(
        tonumber(payload.renderCpuMs) or 0,
        0,
        1000
    )
    local renderGpuMs = math.clamp(
        tonumber(payload.renderGpuMs) or 0,
        0,
        1000
    )

    local budgetStatus = VisualBudgetRules.status(tier, {
        Parts = visualParts,
        Lights = visualLights,
        Effects = visualEffects,
    })

    local phase = tostring(lastRoundState.phase or "unknown")
    local allowedPhases = {
        waiting = true,
        intermission = true,
        vote = true,
        ready = true,
        round = true,
        result = true,
    }
    if not allowedPhases[phase] then
        phase = "unknown"
    end
    local chaosCount = lastRoundState.doubleChaos == true and 2 or 1
    local finalRush = phase == "round" and lastRoundState.finalRush == true and 1 or 0

    GameAnalytics.custom(
        player,
        "ClientPerformancePulse",
        math.floor(fps + 0.5),
        "VFX:" .. tier,
        "Device:" .. deviceClass,
        "Round:" .. tostring(roundNumber)
            .. "|TierChanges:" .. tostring(tierTransitions)
            .. "|Visual:" .. tostring(visualParts)
            .. "/" .. tostring(visualLights)
            .. "/" .. tostring(visualEffects)
            .. "|Budget:" .. budgetStatus
            .. "|Phase:" .. phase
            .. "|Chaos:" .. tostring(chaosCount)
            .. "|Rush:" .. tostring(finalRush)
    )

    GameAnalytics.custom(
        player,
        "ClientMemoryPulse",
        math.floor(totalMemoryMb + 0.5),
        "VFX:" .. tier .. "|Device:" .. deviceClass,
        "Instances:" .. tostring(instanceCount),
        "FrameMs:" .. string.format("%.1f", frameTimeMs)
            .. "|CPU:" .. string.format("%.1f", renderCpuMs)
            .. "|GPU:" .. string.format("%.1f", renderGpuMs)
    )
end)


local allowedSocialSignals = {
    invite_cta_shown = true,
    invite_prompt_opened = true,
    share_cta_shown = true,
    share_capture_requested = true,
    share_accepted = true,
    share_denied = true,
    share_failed = true,
}

socialSignalEvent.OnServerEvent:Connect(function(player, action)
    local signal = tostring(action or "")
    if not allowedSocialSignals[signal] then
        return
    end
    if not allowSocialSignal(player.UserId .. ":" .. signal) then
        return
    end

    local analyticsEvent = string.sub(signal, 1, 6) == "share_"
        and "SocialShare"
        or "SocialInvite"

    GameAnalytics.custom(
        player,
        analyticsEvent,
        1,
        "Action:" .. signal,
        "Games:" .. tostring(math.max(0, math.floor(tonumber(player:GetAttribute("Games")) or 0))),
        "Players:" .. tostring(#Players:GetPlayers())
    )
end)


socialReactionEvent.OnServerEvent:Connect(function(player, reactionId)
    if player.Parent ~= Players then
        return
    end

    local reactionKey = SocialExperienceRules.reactionKey(reactionId)
    if not reactionKey
        or not SocialExperienceRules.canReact(
            lastRoundState.phase,
            #Players:GetPlayers(),
            player:GetAttribute("Games")
        )
    then
        return
    end

    if reactionRoundByUser[player.UserId] == roundNumber
        or not allowSocialReaction(player.UserId)
    then
        return
    end
    reactionRoundByUser[player.UserId] = roundNumber

    socialReactionEvent:FireAllClients({
        userId = player.UserId,
        reactionId = tostring(reactionId),
    })
    GameAnalytics.custom(
        player,
        "SocialReaction",
        1,
        "Reaction:" .. tostring(reactionId),
        "Players:" .. tostring(#Players:GetPlayers())
    )
end)


local function sendQuestState(player, completed)
    questEvent:FireClient(player, {
        state = PlayerData.getQuestState(player),
        completed = completed or {},
    })
end

local function progressQuest(player, eventName, amount)
    if player.Parent ~= Players
        or player:GetAttribute("DataLoaded") ~= true
        or player:GetAttribute("DataPersistenceAvailable") ~= true
    then
        return
    end

    local completed = PlayerData.progressQuestEvent(player, eventName, amount or 1)
    sendQuestState(player, completed)

    if #completed > 0 then
        task.spawn(PlayerData.save, player, true)
    end

    for _, quest in ipairs(completed) do
        local weekly = quest.scope == "weekly"
        local eventName = weekly and "WeeklyChallengeCompleted" or "QuestCompleted"
        local economySource = weekly and "WeeklyChallenge" or "Quest"

        GameAnalytics.custom(
            player,
            eventName,
            1,
            (weekly and "Weekly:" or "Quest:") .. tostring(quest.id),
            "Level:" .. tostring(player:GetAttribute("Level") or 1)
        )
        GameAnalytics.economySource(
            player,
            quest.coins or 0,
            economySource,
            quest.id,
            #Players:GetPlayers() <= 1
        )
    end
end

local function alive(player)
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function readyPlayerCount()
    local count = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("DataLoaded") == true then
            count += 1
        end
    end
    return count
end

local function teleportToArena(player, index)
    local generatedMap = workspace:FindFirstChild("GeneratedMap")
    local arena = generatedMap and generatedMap:FindFirstChild("Arena")
    local spawnFolder = arena and arena:FindFirstChild("Spawns")
    if not spawnFolder then
        return false, "arena spawns unavailable"
    end

    local spawns = spawnFolder:GetChildren()
    if #spawns == 0 then
        return false, "arena has no spawns"
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false, "character root unavailable"
    end

    local spawn = spawns[((index - 1) % #spawns) + 1]
    if not spawn:IsA("BasePart") then
        return false, "invalid arena spawn"
    end

    root.CFrame = spawn.CFrame + Vector3.new(0, 4, 0)
    return true
end

local function ensureContestantReady(player, timeoutSeconds)
    local deadline = os.clock() + math.max(0.5, tonumber(timeoutSeconds) or 4)

    while player.Parent == Players and os.clock() < deadline do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local dataReady = player:GetAttribute("DataLoaded") == true

        if dataReady and humanoid and humanoid.Health > 0 and root then
            return true
        end

        task.wait(0.05)
    end

    return false
end

local function shuffledPool()
    local pool = table.clone(disasters)
    for i = #pool, 2, -1 do
        local j = math.random(1, i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    return pool
end

local function chooseVoteOptions()
    local pool = RoundVariety.excludeRecent(
        shuffledPool(),
        recentPrimaryDisasterIds,
        3
    )
    return {pool[1], pool[2], pool[3]}
end

local function validOption(id)
    for _, d in ipairs(currentOptions) do
        if d.Id == id then return true end
    end
    return false
end

local function setupDailyReward(player)
    task.spawn(function()
        if not PlayerReadiness.waitForDataLoaded(player) then
            return
        end

        if player:GetAttribute("DataPersistenceAvailable") ~= true then
            sendQuestState(player)
            return
        end

        local claim = PlayerData.claimDaily(player)
        if claim then
            dailyRewardEvent:FireClient(player, {
                streak = claim.Streak,
                coins = claim.Coins,
                xp = claim.XP,
                rewardIndex = claim.RewardIndex,
            })

            GameAnalytics.custom(
                player,
                "DailyRewardClaimed",
                claim.Streak,
                "RewardDay:" .. tostring(claim.RewardIndex),
                "Streak:" .. tostring(claim.Streak)
            )
            GameAnalytics.economySource(player, claim.Coins, "DailyReward", "DailyDay" .. tostring(claim.RewardIndex), #Players:GetPlayers() <= 1)
            task.spawn(PlayerData.save, player, true)
        end

        sendQuestState(player)
    end)
end

local clientReady = {}

local function syncInitialClientState(player)
    if clientReady[player] then
        return
    end
    clientReady[player] = true
    stateEvent:FireClient(player, lastRoundState)

    task.spawn(function()
        if not PlayerReadiness.waitForDataLoaded(player) then
            return
        end

        setupDailyReward(player)
        CosmeticService.sync(player)
        AchievementService.sync(player)
    end)
end

clientReadyEvent.OnServerEvent:Connect(function(player)
    syncInitialClientState(player)
end)

local function markCrewRound(contestants)
    local entries = {}
    local playersById = {}

    for _, contestant in ipairs(contestants or {}) do
        if contestant and contestant.Parent == Players then
            playersById[contestant.UserId] = contestant
            table.insert(entries, {
                userId = contestant.UserId,
                inviterUserId = contestant:GetAttribute("CrewSourceUserId")
                    or contestant:GetAttribute("InvitedByUserId"),
            })
        end
    end

    local participantIds = SocialExperienceRules.crewParticipantIds(entries)
    if #participantIds < 2 then
        return 0
    end

    for _, userId in ipairs(participantIds) do
        local target = playersById[userId]
        if target then
            local nextRounds = math.max(
                0,
                math.floor(tonumber(target:GetAttribute("SessionCrewRounds")) or 0)
            ) + 1
            target:SetAttribute("SessionCrewRounds", nextRounds)
            GameAnalytics.custom(
                target,
                "CrewRound",
                nextRounds,
                "CrewSize:" .. tostring(#participantIds),
                "Round:" .. tostring(roundNumber + 1)
            )
        end
    end

    return #participantIds
end

local function processInviteJoinData(player)
    task.spawn(function()
        for _ = 1, 10 do
            if player.Parent ~= Players then
                return
            end

            local okJoin, joinData = pcall(player.GetJoinData, player)
            local launchData = okJoin and type(joinData) == "table" and joinData.LaunchData or nil
            if type(launchData) == "string" and launchData ~= "" then
                local okDecode, payload = pcall(HttpService.JSONDecode, HttpService, launchData)
                local inviterUserId = okDecode
                    and SocialExperienceRules.inviterUserId(payload, player.UserId)
                    or nil
                local shareUserId = okDecode
                    and SocialExperienceRules.shareSourceUserId(payload, player.UserId)
                    or nil

                if inviterUserId then
                    player:SetAttribute("InvitedByUserId", inviterUserId)
                    player:SetAttribute("CrewSourceUserId", inviterUserId)
                    local inviter = Players:GetPlayerByUserId(inviterUserId)

                    GameAnalytics.custom(
                        player,
                        "InviteJoin",
                        1,
                        "InviterPresent:" .. tostring(inviter ~= nil),
                        "Players:" .. tostring(#Players:GetPlayers())
                    )

                    if inviter and inviter.Parent == Players then
                        inviter:SetAttribute(
                            "SessionFriendJoins",
                            math.max(0, math.floor(tonumber(inviter:GetAttribute("SessionFriendJoins")) or 0)) + 1
                        )
                        GameAnalytics.custom(
                            inviter,
                            "InviteFriendArrived",
                            1,
                            "SameServer:true",
                            "Players:" .. tostring(#Players:GetPlayers())
                        )
                        socialSignalEvent:FireClient(inviter, {
                            kind = "friend_joined",
                            displayName = player.DisplayName,
                        })
                    end
                elseif shareUserId then
                    player:SetAttribute("CrewSourceUserId", shareUserId)
                    local sharer = Players:GetPlayerByUserId(shareUserId)
                    local shareReason = SocialExperienceRules.shareReason(payload) or "highlight"

                    GameAnalytics.custom(
                        player,
                        "ShareJoin",
                        1,
                        "SharerPresent:" .. tostring(sharer ~= nil),
                        "Reason:" .. tostring(shareReason)
                    )

                    if sharer and sharer.Parent == Players then
                        GameAnalytics.custom(
                            sharer,
                            "SharedMomentPlayerArrived",
                            1,
                            "Reason:" .. tostring(shareReason),
                            "Players:" .. tostring(#Players:GetPlayers())
                        )
                        socialSignalEvent:FireClient(sharer, {
                            kind = "share_joined",
                            displayName = player.DisplayName,
                        })
                    end
                end
                return
            end

            task.wait(1)
        end
    end)
end

Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("RoundParticipant", false)
    player:SetAttribute("RoundEliminated", false)
    player:SetAttribute("SessionCrewRounds", 0)
    GameAnalytics.sessionStarted(player, #Players:GetPlayers())
    processInviteJoinData(player)
end)

Players.PlayerRemoving:Connect(function(player)
    clientReady[player] = nil
    currentVotes[player.UserId] = nil
    reactionRoundByUser[player.UserId] = nil
    GameAnalytics.sessionEnded(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player:GetAttribute("SessionCrewRounds") == nil then
        player:SetAttribute("SessionCrewRounds", 0)
    end
    GameAnalytics.sessionStarted(player, #Players:GetPlayers())
    processInviteJoinData(player)
end

voteEvent.OnServerEvent:Connect(function(player, disasterId)
    if not voteOpen then return end
    if player.Parent ~= Players or player:GetAttribute("DataLoaded") ~= true then return end
    if type(disasterId) ~= "string" then return end
    if not allowVote(player.UserId) then return end
    if not validOption(disasterId) then return end
    currentVotes[player.UserId] = disasterId

    local currentRules = SoloRules.resolve(Config, readyPlayerCount())
    GameAnalytics.vote(player, disasterId, currentRules.Solo)
end)

local function humanVoteCounts()
    local counts = {}
    for _, d in ipairs(currentOptions) do
        counts[d.Id] = 0
    end

    for userId, id in pairs(currentVotes) do
        local player = Players:GetPlayerByUserId(userId)
        if player
            and player:GetAttribute("DataLoaded") == true
            and counts[id] ~= nil
        then
            counts[id] += 1
        end
    end

    return counts
end

local function currentVoteCounts()
    local counts = humanVoteCounts()
    local aiCounts = AISurvivorService.voteCounts()

    for id, amount in pairs(aiCounts) do
        if counts[id] ~= nil then
            counts[id] += math.max(0, math.floor(tonumber(amount) or 0))
        end
    end

    return counts
end

local function winningOption()
    local humanCounts = humanVoteCounts()
    local humanVotes = 0
    for _, count in pairs(humanCounts) do
        humanVotes += count
    end

    -- AI votes make the lobby feel populated, but humans always keep agency.
    local counts = humanVotes > 0 and humanCounts or currentVoteCounts()

    local bestCount = -1
    local winners = {}
    for _, d in ipairs(currentOptions) do
        local count = counts[d.Id] or 0
        if count > bestCount then
            bestCount = count
            winners = {d}
        elseif count == bestCount then
            table.insert(winners, d)
        end
    end

    return winners[math.random(1, #winners)]
end

local function runDisasterSet(selected, contestants, roundSettings)
    local roundStartedAt = os.clock()
    local fusionName = #selected > 1 and ChaosFusion.name(selected[1].Id, selected[2].Id) or nil
    local roundActive = true
    local overdriveActive = false
    local finalRushActive = false
    local overdriveEligible = roundSettings.RoundSeconds >= 20
    local overdriveStartRemaining = math.floor(roundSettings.RoundSeconds * 0.58)
    local overdriveDuration = math.clamp(math.floor(roundSettings.RoundSeconds * 0.16), 5, 7)
    local overdriveEndRemaining = math.max(0, overdriveStartRemaining - overdriveDuration)
    local firstRoundContestant = false
    for _, player in ipairs(contestants) do
        if FirstTimeExperience.isFirstRound(player:GetAttribute("Games")) then
            firstRoundContestant = true
            break
        end
    end

    local roundChallenge = RoundChallenge.forContext(
        roundNumber,
        firstRoundContestant
    )
    local hazardContestants = AISurvivorService.hazardContestants(contestants)
    local cleanup = {}
    local onCleanup = {}
    local eliminated = {}
    local eliminationCauses = {}
    local recentHazards = {}
    local deathConnections = {}
    local lastMechanicAt = {}
    local flowComboClaimed = {}
    local momentumLastAt = {}

    local activeHazards = {}
    for _, disaster in ipairs(selected) do
        activeHazards[tostring(disaster.Id)] = true
    end

    local function fallCause()
        return EliminationCauseRules.fallbackFallCause(activeHazards)
    end

    for _, player in ipairs(contestants) do
        eliminated[player.UserId] = false
        player:SetAttribute("RoundParticipant", true)
        player:SetAttribute("RoundEliminated", false)
        player:SetAttribute("RoundChaosShards", 0)
        player:SetAttribute("RoundShardCoins", 0)
        player:SetAttribute("RoundNearMisses", 0)
        player:SetAttribute("RoundMechanicUses", 0)
        player:SetAttribute("RoundOverdriveUses", 0)
        player:SetAttribute("RoundFlowCoins", 0)
        player:SetAttribute("RoundMomentum", 0)
        player:SetAttribute("RoundMomentumBest", 0)

        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            deathConnections[player.UserId] = hum.Died:Connect(function()
                eliminated[player.UserId] = true

                local cause = EliminationCauseRules.recentHazardKind(
                    recentHazards[player.UserId],
                    os.clock(),
                    2.25
                )

                if not cause then
                    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if root
                        and root:IsA("BasePart")
                        and root.Position.Y < (Config.ArenaCenter.Y - 14)
                    then
                        cause = fallCause()
                    end
                end

                eliminationCauses[player.UserId] = tostring(cause or "Unknown")

                if player.Parent == Players then
                    player:SetAttribute("RoundEliminated", true)
                end
            end)
        end
    end

    local function bumpMomentum(player)
        if player.Parent ~= Players then
            return
        end

        local now = os.clock()
        local current = math.max(0, math.floor(tonumber(player:GetAttribute("RoundMomentum")) or 0))
        local nextCombo = RoundMomentum.next(current, momentumLastAt[player.UserId], now)
        momentumLastAt[player.UserId] = now

        player:SetAttribute("RoundMomentum", nextCombo)
        local best = math.max(
            nextCombo,
            math.max(0, math.floor(tonumber(player:GetAttribute("RoundMomentumBest")) or 0))
        )
        player:SetAttribute("RoundMomentumBest", best)
    end

    local function lastSurvivorUserId()
        local survivorUserId = nil
        local count = 0

        for _, player in ipairs(contestants) do
            if player.Parent == Players and not eliminated[player.UserId] then
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    count += 1
                    survivorUserId = player.UserId
                    if count > 1 then
                        return nil
                    end
                end
            end
        end

        return count == 1 and survivorUserId or nil
    end

    local function countContestantsRemaining()
        local count = 0
        for _, player in ipairs(contestants) do
            if player.Parent == Players and not eliminated[player.UserId] then
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    count += 1
                end
            end
        end
        return count
    end

    local ctx = {
        Config = Config,
        RoundSeconds = roundSettings.RoundSeconds,
        Cleanup = cleanup,
        OnCleanup = onCleanup,
        Active = function() return roundActive end,
        Overdrive = function() return overdriveActive end,
        FinalRush = function() return finalRushActive end,
        Contestants = contestants,
        HazardContestants = hazardContestants,
        IsContestantActive = function(subject)
            if AISurvivorService.isBotSubject(subject) then
                return AISurvivorService.isSubjectActive(subject)
            end

            if subject.Parent ~= Players or eliminated[subject.UserId] then
                return false
            end

            local hum = subject.Character and subject.Character:FindFirstChildOfClass("Humanoid")
            return hum ~= nil and hum.Health > 0
        end,
        BalanceProfile = DisasterBalance.mobileProfile(#contestants),
        Intensity = function()
            return RoundIntensity.factor(
                os.clock() - roundStartedAt,
                roundSettings.RoundSeconds,
                roundSettings.Solo,
                #selected > 1
            )
        end,
        OnHazardContact = function(subject, kind)
            if AISurvivorService.isBotSubject(subject) then
                return
            end
            if subject and subject.Parent == Players then
                recentHazards[subject.UserId] = {
                    kind = tostring(kind or "Unknown"),
                    at = os.clock(),
                }
            end
        end,
        OnHazardDamage = function(subject, kind, damage)
            if AISurvivorService.isBotSubject(subject) then
                return
            end
            if subject
                and subject.Parent == Players
                and (tonumber(damage) or 0) > 0
            then
                recentHazards[subject.UserId] = {
                    kind = tostring(kind or "Unknown"),
                    at = os.clock(),
                }
            end
        end,
        OnFatalHazard = function(subject, kind)
            if AISurvivorService.isBotSubject(subject) then
                return
            end
            if subject and subject.Parent == Players then
                recentHazards[subject.UserId] = {
                    kind = tostring(kind or "Unknown"),
                    at = os.clock(),
                }
            end
        end,
        OnHazardImpact = function(position, color, radius, kind)
            for _, player in ipairs(Players:GetPlayers()) do
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if root and (root.Position - position).Magnitude <= 180 then
                    hazardImpactFeedbackEvent:FireClient(player, {
                        position = position,
                        color = color,
                        radius = radius,
                        kind = kind,
                    })
                end
            end
        end,
        OnHazardNearMiss = function(player, kind, distance, radius)
            if player.Parent ~= Players or not allowHazardNearMiss(player.UserId) then
                return
            end

            local total = math.max(0, math.floor(tonumber(player:GetAttribute("RoundNearMisses")) or 0)) + 1
            player:SetAttribute("RoundNearMisses", total)
            bumpMomentum(player)

            hazardNearMissEvent:FireClient(player, {
                kind = kind,
                distance = distance,
                radius = radius,
                total = total,
            })
        end,
        OnArenaMechanicUsed = function(player, variantId, mechanicName, usedOverdrive)
            if player.Parent ~= Players then
                return
            end

            local mechanicUses = math.max(0, math.floor(tonumber(player:GetAttribute("RoundMechanicUses")) or 0)) + 1
            player:SetAttribute("RoundMechanicUses", mechanicUses)
            lastMechanicAt[player.UserId] = os.clock()
            bumpMomentum(player)
            if usedOverdrive == true then
                local overdriveUses = math.max(0, math.floor(tonumber(player:GetAttribute("RoundOverdriveUses")) or 0)) + 1
                player:SetAttribute("RoundOverdriveUses", overdriveUses)
            end

            arenaMechanicFeedbackEvent:FireClient(player, {
                variantId = variantId,
                mechanicName = mechanicName,
                overdrive = usedOverdrive == true,
            })

            GameAnalytics.custom(
                player,
                "ArenaMechanicUsed",
                1,
                "Arena:" .. tostring(variantId),
                "Mechanic:" .. tostring(mechanicName),
                "Mode:" .. GameAnalytics.modeLabel(roundSettings.Solo)
                    .. "|Overdrive:" .. (usedOverdrive == true and "Yes" or "No")
            )
        end,
        SoloMode = roundSettings.Solo,
        OnCollected = function(player, reward, position, golden)
            if player.Parent ~= Players
                or player:GetAttribute("DataLoaded") ~= true
                or eliminated[player.UserId]
            then
                return
            end

            local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                return
            end

            local amount = math.max(0, math.floor(tonumber(reward) or 0))
            if amount <= 0 then
                return
            end

            local total = (tonumber(player:GetAttribute("RoundChaosShards")) or 0) + 1
            local shardCoinTotal = math.max(0, math.floor(tonumber(player:GetAttribute("RoundShardCoins")) or 0)) + amount
            local flowBonus = 0
            if FlowCombo.qualifies(lastMechanicAt[player.UserId], os.clock(), flowComboClaimed[player.UserId]) then
                flowComboClaimed[player.UserId] = true
                flowBonus = FlowCombo.BonusCoins
            end

            player:SetAttribute("RoundChaosShards", total)
            player:SetAttribute("RoundShardCoins", shardCoinTotal)
            bumpMomentum(player)
            if flowBonus > 0 then
                local flowTotal = math.max(0, math.floor(tonumber(player:GetAttribute("RoundFlowCoins")) or 0)) + flowBonus
                player:SetAttribute("RoundFlowCoins", flowTotal)
            end

            PlayerData.add(player, "Coins", amount + flowBonus)

            chaosShardCollectedEvent:FireClient(player, {
                reward = amount,
                total = total,
                position = position,
                golden = golden == true,
                flowBonus = flowBonus,
            })

            progressQuest(player, "collect_shard", 1)
            progressQuest(player, "coins_earned", amount + flowBonus)

            GameAnalytics.economySource(
                player,
                amount,
                golden == true and "GoldenChaosShard" or "ChaosShard",
                currentArenaVariant,
                roundSettings.Solo
            )
            if flowBonus > 0 then
                GameAnalytics.economySource(
                    player,
                    flowBonus,
                    "FlowCombo",
                    currentArenaVariant,
                    roundSettings.Solo
                )
                GameAnalytics.custom(
                    player,
                    "FlowComboCompleted",
                    1,
                    "Arena:" .. tostring(currentArenaVariant),
                    "Mode:" .. GameAnalytics.modeLabel(roundSettings.Solo)
                )
            end

            GameAnalytics.custom(
                player,
                "ChaosShardCollected",
                1,
                "Arena:" .. tostring(currentArenaVariant),
                "Mode:" .. GameAnalytics.modeLabel(roundSettings.Solo),
                "Count:" .. tostring(total)
            )
            GameAnalytics.onboarding(
                player,
                6,
                "FirstShardCollected",
                roundSettings.Solo
            )
        end,
    }

    local arenaMechanic = nil
    local mechanicOk, mechanicResult = pcall(ArenaMechanics.start, ctx, currentArenaVariant)
    if mechanicOk then
        arenaMechanic = mechanicResult
    else
        warn("Arena mechanic failed to start:", currentArenaVariant, mechanicResult)
    end

    local collectibleOk, collectibleResult = pcall(RoundCollectibles.start, ctx)
    if not collectibleOk then
        warn("Round collectibles failed to start:", collectibleResult)
    end

    for _, disaster in ipairs(selected) do
        local ok, err = pcall(disaster.start, ctx)
        if not ok then
            warn("Disaster failed to start:", disaster.Id, err)
        end
    end

    local endedEarly = false
    for t = roundSettings.RoundSeconds, 1, -1 do
        overdriveActive = overdriveEligible
            and t <= overdriveStartRemaining
            and t > overdriveEndRemaining
        finalRushActive = t <= 5

        local humanSurvivorsAlive = countContestantsRemaining()
        local aiSurvivorsAlive = AISurvivorService.aliveRoundCount()
        local survivorsAlive = humanSurvivorsAlive + aiSurvivorsAlive
        if humanSurvivorsAlive <= 0 then
            endedEarly = true

            if aiSurvivorsAlive > 0 then
                local spectateDisasterIds = {}
                for _, disaster in ipairs(selected) do
                    table.insert(spectateDisasterIds, disaster.Id)
                end

                broadcast({
                    phase = "round",
                    title = "YOU WERE ELIMINATED",
                    hint = "WATCH THE SURVIVORS • NEXT ROUND SOON",
                    seconds = math.min(3, t),
                    doubleChaos = #selected > 1,
                    fusionName = fusionName,
                    soloMode = roundSettings.Solo,
                    arenaName = roundSettings.ArenaName or currentArenaVariant,
                    disasterIds = spectateDisasterIds,
                    survivorsAlive = aiSurvivorsAlive,
                    contestantCount = #contestants + AISurvivorService.visibleCount(),
                    aiSurvivors = aiSurvivorsAlive,
                    spectating = true,
                })
                task.wait(2.25)
            end
            break
        end

        local title = selected[1].Name
        local hint = selected[1].Hint

        if #selected > 1 then
            title = "CHAOS FUSION: " .. tostring(fusionName)
            hint = selected[1].Name .. " + " .. selected[2].Name .. " • " .. selected[1].Hint .. " / " .. selected[2].Hint
        elseif roundSettings.Solo then
            title = "QUICK RUSH: " .. title
        end

        local disasterIds = {}
        for _, disaster in ipairs(selected) do
            table.insert(disasterIds, disaster.Id)
        end

        local roundHint = roundSettings.Solo and ("Rush bonus active • " .. hint) or hint
        if firstRoundContestant then
            roundHint = "SURVIVE UNTIL 0 • " .. hint .. " • SHARDS = BONUS"
        end
        if finalRushActive then
            roundHint = "FINAL RUSH • Pads recharge faster • " .. roundHint
        elseif overdriveActive then
            roundHint = "OVERDRIVE • Boost pads + Shard surge • " .. roundHint
        end

        broadcast({
            phase = "round",
            title = title,
            hint = roundHint,
            seconds = t,
            doubleChaos = #selected > 1,
            fusionName = fusionName,
            soloMode = roundSettings.Solo,
            arenaName = roundSettings.ArenaName or currentArenaVariant,
            disasterIds = disasterIds,
            survivorsAlive = survivorsAlive,
            contestantCount = #contestants + AISurvivorService.visibleCount(),
            aiSurvivors = aiSurvivorsAlive,
            lastSurvivorUserId = (survivorsAlive == 1 and humanSurvivorsAlive == 1) and lastSurvivorUserId() or nil,
            arenaMechanicName = arenaMechanic and arenaMechanic.name or nil,
            arenaMechanicHint = arenaMechanic and arenaMechanic.hint or nil,
            overdrive = overdriveActive,
            overdriveSeconds = overdriveActive and math.max(1, t - overdriveEndRemaining) or 0,
            finalRush = finalRushActive,
            challengeId = roundChallenge.Id,
            challengeTitle = roundChallenge.Title,
            challengeShort = roundChallenge.Short,
            challengeMetric = roundChallenge.Metric,
            challengeTarget = roundChallenge.Target,
            challengeCoins = roundChallenge.Coins,
            challengeXP = roundChallenge.XP,
            intensity = RoundIntensity.factor(
                roundSettings.RoundSeconds - t,
                roundSettings.RoundSeconds,
                roundSettings.Solo,
                #selected > 1
            ),
        })

        task.wait(1)
    end

    overdriveActive = false
    finalRushActive = false
    roundActive = false
    local roundElapsed = math.max(0, os.clock() - roundStartedAt)

    local cleanupFailures = RoundCleanup.execute(
        deathConnections,
        onCleanup,
        cleanup,
        function(kind, key, err)
            warn("Round cleanup failure:", kind, key, err)
        end
    )
    if cleanupFailures > 0 then
        warn("Round cleanup completed with failures:", cleanupFailures)
    end

    return eliminated, endedEarly, roundElapsed, eliminationCauses
end

while true do
    while readyPlayerCount() < Config.MinimumPlayers do
        local connected = #Players:GetPlayers()
        broadcast({
            phase = "waiting",
            title = connected >= Config.MinimumPlayers and "PREPARING PLAYER DATA" or "WAITING FOR PLAYERS",
            hint = connected >= Config.MinimumPlayers and "Syncing your progress safely" or "",
            seconds = 0,
        })
        task.wait(1)
    end

    currentVotes = {}
    currentOptions = chooseVoteOptions()
    voteOpen = false
    botVoteStarted = false
    AISurvivorService.clearVotes()

    if isStudioE2E then
        studioE2EArenaIndex += 1
        local order = ArenaVariants.Order
        currentArenaVariant = order[((studioE2EArenaIndex - 1) % #order) + 1]
    else
        currentArenaVariant = ArenaVariants.chooseRecent(recentArenaVariantIds)
    end
    local arenaDefinition = ArenaVariants.get(currentArenaVariant)
    local intermissionSettings = SoloRules.resolve(Config, readyPlayerCount())

    local firstSessionVote = false
    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("DataLoaded") == true
            and math.max(0, math.floor(tonumber(player:GetAttribute("Games")) or 0)) <= 0
        then
            firstSessionVote = true
            break
        end
    end

    local intermissionCancelled = false
    local remainingIntermission = intermissionSettings.IntermissionSeconds
    if firstSessionVote then
        -- Give a brand-new touch player a calm four-second control-reading
        -- window before the eight-second vote opens.
        remainingIntermission = math.max(remainingIntermission, 12)
    end
    local previousSoloMode = intermissionSettings.Solo

    while remainingIntermission >= 1 do
        local loadedCount = readyPlayerCount()
        if loadedCount < Config.MinimumPlayers then
            voteOpen = false
            broadcast({
                phase = "waiting",
                title = #Players:GetPlayers() >= Config.MinimumPlayers and "PREPARING PLAYER DATA" or "WAITING FOR PLAYERS",
                hint = #Players:GetPlayers() >= Config.MinimumPlayers and "Syncing your progress safely" or "",
                seconds = 0,
            })
            intermissionCancelled = true
            break
        end

        intermissionSettings = SoloRules.resolve(Config, loadedCount)
        if intermissionSettings.Solo ~= previousSoloMode then
            if intermissionSettings.Solo then
                remainingIntermission = math.min(remainingIntermission, intermissionSettings.IntermissionSeconds)
            else
                remainingIntermission = math.max(remainingIntermission, intermissionSettings.IntermissionSeconds)
            end
            previousSoloMode = intermissionSettings.Solo
        end

        local options = nil
        local voteWindowSeconds = firstSessionVote
            and math.max(intermissionSettings.VoteSeconds, 8)
            or intermissionSettings.VoteSeconds
        if remainingIntermission <= voteWindowSeconds then
            voteOpen = true
            if not botVoteStarted then
                botVoteStarted = true
                AISurvivorService.beginVote(currentOptions, roundNumber + 1)
            end
            options = {}
            -- Display only player votes. AI votes remain a fallback when no
            -- human votes, but showing them here would make the visible
            -- "leading" card disagree with the human-authoritative winner.
            local voteCounts = humanVoteCounts()

            for _, d in ipairs(currentOptions) do
                table.insert(options, {
                    id = d.Id,
                    name = d.Name,
                    hint = d.Hint,
                    votes = voteCounts[d.Id] or 0,
                })
            end
        else
            voteOpen = false
        end

        broadcast({
            phase = "intermission",
            title = options and "VOTE FOR THE NEXT CHAOS" or (intermissionSettings.Solo and "QUICK RUSH" or "NEXT ROUND"),
            hint = options
                and (intermissionSettings.Solo and "YOUR VOTE DECIDES • TAP A CHAOS" or "TAP A CHAOS TO VOTE")
                or ("SURVIVE UNTIL 0 • SHARDS = BONUS • " .. (arenaDefinition and arenaDefinition.Name or "ARENA")),
            seconds = remainingIntermission,
            voteOptions = options,
            soloMode = intermissionSettings.Solo,
            arenaName = arenaDefinition and arenaDefinition.Name or currentArenaVariant,
        })
        task.wait(1)
        remainingIntermission -= 1
    end

    voteOpen = false

    if intermissionCancelled then
        task.wait(1)
        continue
    end

    local selected = winningOption()

    local contestants = Players:GetPlayers()
    local roundSettings = SoloRules.resolve(Config, #contestants)
    roundSettings.ArenaName = arenaDefinition and arenaDefinition.Name or currentArenaVariant

    local arenaBuilt, arenaBuildError = pcall(
        MapBuilder.buildArena,
        Config,
        currentArenaVariant,
        ArenaVariants
    )
    if not arenaBuilt then
        warn("Arena build failed:", currentArenaVariant, arenaBuildError)

        local fallbackBuilt, fallbackError = pcall(
            MapBuilder.buildArena,
            Config,
            "Classic",
            ArenaVariants
        )

        if fallbackBuilt then
            currentArenaVariant = "Classic"
            local fallbackDefinition = ArenaVariants.get("Classic")
            roundSettings.ArenaName = fallbackDefinition and fallbackDefinition.Name or "Classic"
        else
            warn("Classic arena fallback failed:", fallbackError)
            broadcast({
                phase = "waiting",
                title = "ARENA RECOVERY",
                hint = "Rebuilding the arena",
                seconds = 0,
            })
            task.wait(1)
            continue
        end
    end

    local readyContestants = {}
    for i, p in ipairs(contestants) do
        if p.Parent == Players then
            if not p.Character or not alive(p) then
                pcall(p.LoadCharacter, p)
            end

            local contestantReady = ensureContestantReady(p, 4)
            local teleported, teleportError = false, "contestant not ready"
            if contestantReady then
                teleported, teleportError = teleportToArena(p, i)
            end

            if teleported then
                table.insert(readyContestants, p)
                PlayerData.add(p, "Games", 1)
                progressQuest(p, "play_round", 1)
            else
                warn("Skipping unready contestant:", p.Name, teleportError)
                p:SetAttribute("RoundParticipant", false)
                p:SetAttribute("RoundEliminated", false)
            end
        end
    end
    contestants = readyContestants

    if #contestants == 0 then
        broadcast({
            phase = "waiting",
            title = "WAITING FOR READY PLAYERS",
            hint = "Preparing the next round",
            seconds = 0,
        })
        task.wait(1)
        continue
    end

    local resolvedArenaName = roundSettings.ArenaName
    roundSettings = SoloRules.resolve(Config, #contestants)
    roundSettings.ArenaName = resolvedArenaName

    local upcomingRoundNumber = roundNumber + 1

    local selectedSet = {selected}
    local contestantGames = {}
    local firstRoundBriefing = false
    for _, player in ipairs(contestants) do
        local games = player:GetAttribute("Games")
        table.insert(contestantGames, games)
        if FirstTimeExperience.isFirstRound(games) then
            firstRoundBriefing = true
        end
    end

    local allowDoubleChaos = FirstTimeExperience.allowDoubleChaos(contestantGames)
    local forceDouble = allowDoubleChaos
        and (upcomingRoundNumber % roundSettings.DoubleChaosEvery == 0)
    if allowDoubleChaos
        and (forceDouble or math.random() < roundSettings.DoubleChaosChance)
    then
        local candidates = DisasterBalance.filterCompatible(selected.Id, disasters)
        if #candidates > 0 then
            table.insert(selectedSet, candidates[math.random(1, #candidates)])
        end
    end

    local fusionName = #selectedSet > 1
        and ChaosFusion.name(selectedSet[1].Id, selectedSet[2].Id)
        or nil
    local readyTitle = selectedSet[1].Name
    local readyHint = selectedSet[1].Hint
    if #selectedSet > 1 then
        readyTitle = "CHAOS FUSION: " .. tostring(fusionName)
        readyHint = selectedSet[1].Name .. " + " .. selectedSet[2].Name .. " • " .. selectedSet[1].Hint .. " / " .. selectedSet[2].Hint
    elseif roundSettings.Solo then
        readyTitle = "QUICK RUSH: " .. readyTitle
    end

    local readyDisasterIds = {}
    for _, disaster in ipairs(selectedSet) do
        table.insert(readyDisasterIds, disaster.Id)
    end

    local readyCancelled = false
    local readySeconds = roundSettings.ReadySeconds
    if firstRoundBriefing then
        readySeconds = math.max(readySeconds, 5)
    end

    for t = readySeconds, 1, -1 do
        local readyCount = 0
        for _, p in ipairs(contestants) do
            if p.Parent == Players
                and p:GetAttribute("DataLoaded") == true
                and alive(p)
            then
                readyCount += 1
            end
        end

        if readyCount == 0 then
            broadcast({
                phase = "waiting",
                title = "ROUND CANCELLED",
                hint = "No ready players remain",
                seconds = 0,
            })
            readyCancelled = true
            break
        end

        local displayTitle = readyTitle
        if readyCount == 1 and #selectedSet == 1 and not string.find(displayTitle, "QUICK RUSH:", 1, true) then
            displayTitle = "QUICK RUSH: " .. selectedSet[1].Name
        end

        broadcast({
            phase = "ready",
            title = "READY: " .. displayTitle,
            hint = firstRoundBriefing
                and ("SURVIVE UNTIL 0 • " .. readyHint .. " • SHARDS = BONUS")
                or ("SURVIVE UNTIL 0 • " .. readyHint),
            seconds = t,
            doubleChaos = #selectedSet > 1,
            fusionName = fusionName,
            soloMode = readyCount == 1,
            arenaName = roundSettings.ArenaName,
            disasterIds = readyDisasterIds,
            survivorsAlive = readyCount + AISurvivorService.visibleCount(),
            contestantCount = readyCount + AISurvivorService.visibleCount(),
            aiSurvivors = AISurvivorService.visibleCount(),
        })
        task.wait(1)
    end

    if readyCancelled then
        task.wait(1)
        continue
    end

    local startingContestants = {}
    for _, p in ipairs(contestants) do
        if p.Parent == Players
            and p:GetAttribute("DataLoaded") == true
            and alive(p)
        then
            table.insert(startingContestants, p)
        elseif p.Parent == Players then
            p:SetAttribute("RoundParticipant", false)
            p:SetAttribute("RoundEliminated", false)
        end
    end
    contestants = startingContestants

    if #contestants == 0 then
        broadcast({
            phase = "waiting",
            title = "ROUND CANCELLED",
            hint = "No ready players remain",
            seconds = 0,
        })
        task.wait(1)
        continue
    end

    local arenaName = roundSettings.ArenaName
    roundSettings = SoloRules.resolve(Config, #contestants)
    roundSettings.ArenaName = arenaName

    markCrewRound(contestants)

    roundNumber = upcomingRoundNumber
    recentArenaVariantIds = ArenaVariants.pushRecent(recentArenaVariantIds, currentArenaVariant, 2)
    recentPrimaryDisasterIds = RoundVariety.pushRecent(recentPrimaryDisasterIds, selected.Id, 2)

    for _, p in ipairs(contestants) do
        GameAnalytics.roundStarted(p, roundNumber, roundSettings.Solo, selected.Id, #selectedSet > 1)
    end

    local eliminated, endedEarly, roundElapsed, eliminationCauses =
        runDisasterSet(selectedSet, contestants, roundSettings)

    local survivors = 0
    local survivorUserIds = {}
    local aiSurvivorsAtFinish = AISurvivorService.aliveRoundCount()
    local feedbackDisasterName = selectedSet[1].Name
    if #selectedSet > 1 then
        feedbackDisasterName = selectedSet[1].Name .. " + " .. selectedSet[2].Name
    end

    local winCoins = SoloRules.reward(Config.WinCoins, roundSettings.WinCoinMultiplier)
    local winXP = SoloRules.reward(Config.WinXP, roundSettings.WinXPMultiplier)
    for _, p in ipairs(contestants) do
        if p.Parent == Players then
            local survived = eliminated[p.UserId] ~= true and alive(p)
            local survivalStreak, bestSessionStreak = SessionStreak.update(
                p:GetAttribute("SessionSurvivalStreak"),
                p:GetAttribute("BestSessionSurvivalStreak"),
                survived
            )

            p:SetAttribute("SessionSurvivalStreak", survivalStreak)
            p:SetAttribute("BestSessionSurvivalStreak", bestSessionStreak)

            local streakBonusCoins = SessionStreak.bonusCoins(survivalStreak)
            local fusionBonusCoins = survived and #selectedSet > 1 and ChaosFusion.bonusCoins() or 0

            local criticalSurvival = false
            if survived then
                local humanoid = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.MaxHealth > 0 then
                    criticalSurvival = SurvivalFeedback.isCriticalHealth(humanoid.Health, humanoid.MaxHealth)
                end
            end

            if survived then
                survivors += 1
                table.insert(survivorUserIds, p.UserId)
                PlayerData.add(p, "Coins", winCoins + streakBonusCoins + fusionBonusCoins)
                PlayerData.add(p, "XP", winXP)
                PlayerData.add(p, "Wins", 1)

                GameAnalytics.economySource(p, winCoins, "RoundSurvival", selected.Id, roundSettings.Solo)
                if streakBonusCoins > 0 then
                    GameAnalytics.economySource(p, streakBonusCoins, "SurvivalStreak", "Streak" .. tostring(survivalStreak), roundSettings.Solo)
                end
                if fusionBonusCoins > 0 then
                    GameAnalytics.economySource(
                        p,
                        fusionBonusCoins,
                        "ChaosFusionSurvival",
                        tostring(fusionName),
                        roundSettings.Solo
                    )
                end
                progressQuest(p, "survive_round", 1)
                progressQuest(p, "coins_earned", winCoins + streakBonusCoins + fusionBonusCoins)

                if #selectedSet > 1 then
                    PlayerData.add(p, "DoubleChaosSurvivals", 1)
                    progressQuest(p, "survive_double", 1)
                end
            else
                PlayerData.add(p, "Coins", Config.ParticipationCoins)
                PlayerData.add(p, "XP", Config.ParticipationXP)
                GameAnalytics.economySource(p, Config.ParticipationCoins, "RoundParticipation", selected.Id, roundSettings.Solo)
                progressQuest(p, "coins_earned", Config.ParticipationCoins)
            end

            local masteryGain = Mastery.roundGain(survived)
            local arenaMasteryRaw, arenaMasteryPoints = Mastery.add(
                p:GetAttribute("ArenaMastery"),
                tostring(currentArenaVariant),
                masteryGain
            )
            p:SetAttribute("ArenaMastery", arenaMasteryRaw)

            local disasterMasteryRaw = p:GetAttribute("DisasterMastery")
            local primaryDisasterMasteryPoints = 0
            for _, disaster in ipairs(selectedSet) do
                local nextRaw, points = Mastery.add(
                    disasterMasteryRaw,
                    tostring(disaster.Id),
                    masteryGain
                )
                disasterMasteryRaw = nextRaw
                if disaster.Id == selected.Id then
                    primaryDisasterMasteryPoints = points
                end
            end
            p:SetAttribute("DisasterMastery", disasterMasteryRaw)

            local arenaMasteryState = Mastery.state(arenaMasteryPoints)
            local disasterMasteryState = Mastery.state(primaryDisasterMasteryPoints)

            local roundShardCount = math.max(0, math.floor(tonumber(p:GetAttribute("RoundChaosShards")) or 0))
            local roundNearMissCount = math.max(0, math.floor(tonumber(p:GetAttribute("RoundNearMisses")) or 0))
            local roundMechanicUses = math.max(0, math.floor(tonumber(p:GetAttribute("RoundMechanicUses")) or 0))
            local roundOverdriveUses = math.max(0, math.floor(tonumber(p:GetAttribute("RoundOverdriveUses")) or 0))
            local roundMomentumBest = math.max(0, math.floor(tonumber(p:GetAttribute("RoundMomentumBest")) or 0))
            local roundFlowCoins = math.max(0, math.floor(tonumber(p:GetAttribute("RoundFlowCoins")) or 0))
            local challengeProgress = RoundChallenge.progress(
                roundChallenge,
                roundShardCount,
                roundMechanicUses,
                roundNearMissCount,
                roundMomentumBest,
                roundFlowCoins,
                survived
            )
            local challengeCompleted = challengeProgress >= roundChallenge.Target
            local challengeCoins = challengeCompleted and roundChallenge.Coins or 0
            local challengeXP = challengeCompleted and roundChallenge.XP or 0

            local medals = RoundMedals.evaluate({
                firstRound = math.max(0, tonumber(p:GetAttribute("Games")) or 0) == 1,
                shards = roundShardCount,
                pads = roundMechanicUses,
                nearMisses = roundNearMissCount,
                overdriveUses = roundOverdriveUses,
                momentumBest = roundMomentumBest,
                criticalSurvival = criticalSurvival,
                eliminationCause = survived and nil or eliminationCauses[p.UserId],
                arenaMastery = arenaMasteryState,
                arenaMasteryName = roundSettings.ArenaName,
                disasterMastery = disasterMasteryState,
                disasterMasteryName = selected.Name,
            })

            if challengeCompleted then
                PlayerData.add(p, "Coins", challengeCoins)
                PlayerData.add(p, "XP", challengeXP)
                progressQuest(p, "coins_earned", challengeCoins)
                GameAnalytics.economySource(p, challengeCoins, "RoundChallenge", roundChallenge.Id, roundSettings.Solo)
                GameAnalytics.custom(
                    p,
                    "RoundChallengeCompleted",
                    1,
                    "Challenge:" .. roundChallenge.Id,
                    "Arena:" .. tostring(currentArenaVariant),
                    "Mode:" .. GameAnalytics.modeLabel(roundSettings.Solo)
                )
            end

            GameAnalytics.roundCompleted(
                p,
                survived,
                roundSettings.Solo,
                selected.Id,
                #selectedSet > 1,
                roundElapsed
            )

            if criticalSurvival then
                GameAnalytics.custom(
                    p,
                    "CriticalSurvival",
                    1,
                    "Mode:" .. GameAnalytics.modeLabel(roundSettings.Solo),
                    "Disaster:" .. tostring(selected.Id),
                    "Double:" .. tostring(#selectedSet > 1)
                )
            end

            AchievementService.evaluate(p)

            roundFeedbackEvent:FireClient(p, {
                survived = survived,
                coins = survived and (winCoins + streakBonusCoins + fusionBonusCoins) or Config.ParticipationCoins,
                xp = survived and winXP or Config.ParticipationXP,
                streak = survivalStreak,
                streakBonusCoins = survived and streakBonusCoins or 0,
                fusionBonusCoins = fusionBonusCoins,
                fusionName = fusionName,
                shardCount = roundShardCount,
                shardCoins = math.max(0, math.floor(tonumber(p:GetAttribute("RoundShardCoins")) or 0)),
                flowCoins = roundFlowCoins,
                nearMissCount = roundNearMissCount,
                mechanicUses = roundMechanicUses,
                challengeId = roundChallenge.Id,
                challengeTitle = roundChallenge.Title,
                challengeProgress = challengeProgress,
                challengeTarget = roundChallenge.Target,
                challengeCompleted = challengeCompleted,
                challengeCoins = challengeCoins,
                challengeXP = challengeXP,
                medals = medals,
                momentumBest = roundMomentumBest,
                bestSessionStreak = bestSessionStreak,
                crewRounds = math.max(
                    0,
                    math.floor(tonumber(p:GetAttribute("SessionCrewRounds")) or 0)
                ),
                arenaName = roundSettings.ArenaName,
                arenaId = currentArenaVariant,
                disasterName = feedbackDisasterName,
                disasterIds = (function()
                    local ids = {}
                    for _, disaster in ipairs(selectedSet) do
                        table.insert(ids, disaster.Id)
                    end
                    return ids
                end)(),
                doubleChaos = #selectedSet > 1,
                soloMode = roundSettings.Solo,
                elapsedSeconds = math.floor(roundElapsed + 0.5),
                criticalSurvival = criticalSurvival,
                eliminationCause = ResultPresentation.feedbackEliminationCause(
                    survived,
                    eliminationCauses[p.UserId]
                ),
                arenaMastery = arenaMasteryState,
                arenaMasteryName = roundSettings.ArenaName,
                disasterMastery = disasterMasteryState,
                disasterMasteryName = selected.Name,
                masteryGain = masteryGain,
            })
        end
    end

    local displayedSurvivors = survivors + aiSurvivorsAtFinish
    local resultTitle = endedEarly
        and (aiSurvivorsAtFinish > 0 and "YOU WERE ELIMINATED" or "TOTAL WIPEOUT")
        or (displayedSurvivors .. " SURVIVED")

    broadcast({
        phase = "result",
        title = resultTitle,
        hint = fusionName and (tostring(fusionName) .. " complete • Next round soon") or "Next round soon",
        seconds = roundSettings.PostRoundSeconds,
        doubleChaos = #selectedSet > 1,
        fusionName = fusionName,
        soloMode = roundSettings.Solo,
        arenaName = roundSettings.ArenaName,
        arenaId = currentArenaVariant,
        disasterIds = readyDisasterIds,
        survivorsAlive = displayedSurvivors,
        contestantCount = #contestants + AISurvivorService.activeCount(),
        survivorUserIds = survivorUserIds,
    })

    for t = roundSettings.PostRoundSeconds, 1, -1 do
        broadcast({
            phase = "result",
            title = resultTitle,
            hint = fusionName and (tostring(fusionName) .. " complete • Next round soon") or "Next round soon",
            seconds = t,
            doubleChaos = #selectedSet > 1,
            fusionName = fusionName,
            soloMode = roundSettings.Solo,
            arenaName = roundSettings.ArenaName,
            arenaId = currentArenaVariant,
            disasterIds = readyDisasterIds,
            survivorsAlive = displayedSurvivors,
            contestantCount = #contestants + AISurvivorService.activeCount(),
            survivorUserIds = survivorUserIds,
        })
        task.wait(1)
    end

    for _, p in ipairs(contestants) do
        if p.Parent == Players then
            p:SetAttribute("RoundParticipant", false)
            p:SetAttribute("RoundEliminated", false)
        end
    end
end