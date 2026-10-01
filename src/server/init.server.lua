local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

if RunService:IsStudio() then
    local okService, StudioTestService = pcall(game.GetService, game, "StudioTestService")
    if okService and StudioTestService then
        local okArgs, args = pcall(StudioTestService.GetTestArgs, StudioTestService)
        if okArgs and type(args) == "table" and args.suite == "ChaosE2E" then
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
local PlayerData = require(script.PlayerData)
local RateLimiter = require(script.RateLimiter)
local CosmeticService = require(script.CosmeticService)
local MonetizationService = require(script.MonetizationService)
local AchievementService = require(script.AchievementService)
local SoloRules = require(script.SoloRules)
local GameAnalytics = require(script.GameAnalytics)
local ArenaVariants = require(script.ArenaVariants)
local ArenaMechanics = require(script.ArenaMechanics)
local DisasterBalance = require(script.DisasterBalance)
local SessionStreak = require(script.SessionStreak)
local RoundVariety = require(script.RoundVariety)
local RoundIntensity = require(script.RoundIntensity)
local RoundCleanup = require(script.RoundCleanup)

local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local stateEvent = remotes:FindFirstChild("RoundState") or Instance.new("RemoteEvent")
stateEvent.Name = "RoundState"
stateEvent.Parent = remotes

local voteEvent = remotes:FindFirstChild("VoteDisaster") or Instance.new("RemoteEvent")
voteEvent.Name = "VoteDisaster"
voteEvent.Parent = remotes

local dailyRewardEvent = remotes:FindFirstChild("DailyReward") or Instance.new("RemoteEvent")
dailyRewardEvent.Name = "DailyReward"
dailyRewardEvent.Parent = remotes

local questEvent = remotes:FindFirstChild("QuestUpdate") or Instance.new("RemoteEvent")
questEvent.Name = "QuestUpdate"
questEvent.Parent = remotes

local roundFeedbackEvent = remotes:FindFirstChild("RoundFeedback") or Instance.new("RemoteEvent")
roundFeedbackEvent.Name = "RoundFeedback"
roundFeedbackEvent.Parent = remotes

local clientReadyEvent = remotes:FindFirstChild("ClientReady") or Instance.new("RemoteEvent")
clientReadyEvent.Name = "ClientReady"
clientReadyEvent.Parent = remotes

local arenaMechanicFeedbackEvent = remotes:FindFirstChild("ArenaMechanicFeedback") or Instance.new("RemoteEvent")
arenaMechanicFeedbackEvent.Name = "ArenaMechanicFeedback"
arenaMechanicFeedbackEvent.Parent = remotes

local hazardImpactFeedbackEvent = remotes:FindFirstChild("HazardImpactFeedback") or Instance.new("RemoteEvent")
hazardImpactFeedbackEvent.Name = "HazardImpactFeedback"
hazardImpactFeedbackEvent.Parent = remotes

local hazardNearMissEvent = remotes:FindFirstChild("HazardNearMiss") or Instance.new("RemoteEvent")
hazardNearMissEvent.Name = "HazardNearMiss"
hazardNearMissEvent.Parent = remotes

PlayerData.init()
CosmeticService.init(remotes, RateLimiter)
MonetizationService.init(remotes, RateLimiter, CosmeticService)
AchievementService.init(remotes)
MapBuilder.build(Config, "Classic", ArenaVariants)

local disasters = {}
for _, module in ipairs(script.Disasters:GetChildren()) do
    if module:IsA("ModuleScript") then
        local loaded = require(module)
        loaded.Id = module.Name
        table.insert(disasters, loaded)
    end
end
assert(#disasters >= 3, "At least 3 disasters are required")

local roundNumber = 0
local currentArenaVariant = "Classic"
local recentArenaVariantIds = {currentArenaVariant}
local recentPrimaryDisasterIds = {}
local currentVotes = {}
local currentOptions = {}
local voteOpen = false
local allowVote = RateLimiter.new(0.2)

local function broadcast(payload)
    stateEvent:FireAllClients(payload)
end

local function sendQuestState(player, completed)
    questEvent:FireClient(player, {
        state = PlayerData.getQuestState(player),
        completed = completed or {},
    })
end

local function progressQuest(player, eventName, amount)
    if player.Parent ~= Players or not player:GetAttribute("DataLoaded") then
        return
    end

    local completed = PlayerData.progressQuestEvent(player, eventName, amount or 1)
    sendQuestState(player, completed)

    for _, quest in ipairs(completed) do
        GameAnalytics.custom(
            player,
            "QuestCompleted",
            1,
            "Quest:" .. tostring(quest.id),
            "Level:" .. tostring(player:GetAttribute("Level") or 1)
        )
        GameAnalytics.economySource(player, quest.coins or 0, "Quest", quest.id, #Players:GetPlayers() <= 1)
    end
end

local function alive(player)
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
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
        if not player:GetAttribute("DataLoaded") then
            player:GetAttributeChangedSignal("DataLoaded"):Wait()
        end

        if player.Parent ~= Players or not player:GetAttribute("DataLoaded") then
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

    task.spawn(function()
        if not player:GetAttribute("DataLoaded") then
            player:GetAttributeChangedSignal("DataLoaded"):Wait()
        end

        if player.Parent ~= Players or not player:GetAttribute("DataLoaded") then
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

Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("RoundParticipant", false)
    player:SetAttribute("RoundEliminated", false)
    GameAnalytics.sessionStarted(player, #Players:GetPlayers())
end)

Players.PlayerRemoving:Connect(function(player)
    clientReady[player] = nil
    currentVotes[player.UserId] = nil
    GameAnalytics.sessionEnded(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    GameAnalytics.sessionStarted(player, #Players:GetPlayers())
end

voteEvent.OnServerEvent:Connect(function(player, disasterId)
    if not voteOpen then return end
    if type(disasterId) ~= "string" then return end
    if not allowVote(player.UserId) then return end
    if not validOption(disasterId) then return end
    currentVotes[player.UserId] = disasterId

    local currentRules = SoloRules.resolve(Config, #Players:GetPlayers())
    GameAnalytics.vote(player, disasterId, currentRules.Solo)
end)

local function currentVoteCounts()
    local counts = {}
    for _, d in ipairs(currentOptions) do
        counts[d.Id] = 0
    end

    for userId, id in pairs(currentVotes) do
        if Players:GetPlayerByUserId(userId) and counts[id] ~= nil then
            counts[id] += 1
        end
    end

    return counts
end

local function winningOption()
    local counts = currentVoteCounts()

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
    local roundActive = true
    local cleanup = {}
    local onCleanup = {}
    local eliminated = {}
    local deathConnections = {}

    for _, player in ipairs(contestants) do
        eliminated[player.UserId] = false
        player:SetAttribute("RoundParticipant", true)
        player:SetAttribute("RoundEliminated", false)

        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            deathConnections[player.UserId] = hum.Died:Connect(function()
                eliminated[player.UserId] = true
                if player.Parent == Players then
                    player:SetAttribute("RoundEliminated", true)
                end
            end)
        end
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
        Contestants = contestants,
        IsContestantActive = function(player)
            if player.Parent ~= Players or eliminated[player.UserId] then
                return false
            end

            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
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
        OnHazardImpact = function(position, color, radius, kind)
            hazardImpactFeedbackEvent:FireAllClients({
                position = position,
                color = color,
                radius = radius,
                kind = kind,
            })
        end,
        OnHazardNearMiss = function(player, kind, distance, radius)
            hazardNearMissEvent:FireClient(player, {
                kind = kind,
                distance = distance,
                radius = radius,
            })
        end,
        OnArenaMechanicUsed = function(player, variantId, mechanicName)
            arenaMechanicFeedbackEvent:FireClient(player, {
                variantId = variantId,
                mechanicName = mechanicName,
            })

            GameAnalytics.custom(
                player,
                "ArenaMechanicUsed",
                1,
                "Arena:" .. tostring(variantId),
                "Mechanic:" .. tostring(mechanicName),
                "Mode:" .. GameAnalytics.modeLabel(roundSettings.Solo)
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

    for _, disaster in ipairs(selected) do
        local ok, err = pcall(disaster.start, ctx)
        if not ok then
            warn("Disaster failed to start:", disaster.Id, err)
        end
    end

    local endedEarly = false
    for t = roundSettings.RoundSeconds, 1, -1 do
        local survivorsAlive = countContestantsRemaining()
        if survivorsAlive <= 0 then
            endedEarly = true
            break
        end

        local title = selected[1].Name
        local hint = selected[1].Hint

        if #selected > 1 then
            title = "DOUBLE CHAOS: " .. selected[1].Name .. " + " .. selected[2].Name
            hint = selected[1].Hint .. " / " .. selected[2].Hint
        elseif roundSettings.Solo then
            title = "SOLO RUSH: " .. title
        end

        local disasterIds = {}
        for _, disaster in ipairs(selected) do
            table.insert(disasterIds, disaster.Id)
        end

        broadcast({
            phase = "round",
            title = title,
            hint = roundSettings.Solo and ("Solo bonus active • " .. hint) or hint,
            seconds = t,
            doubleChaos = #selected > 1,
            soloMode = roundSettings.Solo,
            arenaName = roundSettings.ArenaName or currentArenaVariant,
            disasterIds = disasterIds,
            survivorsAlive = survivorsAlive,
            contestantCount = #contestants,
            arenaMechanicName = arenaMechanic and arenaMechanic.name or nil,
            arenaMechanicHint = arenaMechanic and arenaMechanic.hint or nil,
            intensity = RoundIntensity.factor(
                roundSettings.RoundSeconds - t,
                roundSettings.RoundSeconds,
                roundSettings.Solo,
                #selected > 1
            ),
        })

        task.wait(1)
    end

    roundActive = false

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

    return eliminated, endedEarly, math.max(0, os.clock() - roundStartedAt)
end

while true do
    while #Players:GetPlayers() < Config.MinimumPlayers do
        broadcast({phase = "waiting", title = "WAITING FOR PLAYERS", hint = "", seconds = 0})
        task.wait(1)
    end

    currentVotes = {}
    currentOptions = chooseVoteOptions()
    voteOpen = false

    currentArenaVariant = ArenaVariants.chooseRecent(recentArenaVariantIds)
    recentArenaVariantIds = ArenaVariants.pushRecent(recentArenaVariantIds, currentArenaVariant, 2)
    local arenaDefinition = ArenaVariants.get(currentArenaVariant)
    local intermissionSettings = SoloRules.resolve(Config, #Players:GetPlayers())

    for t = intermissionSettings.IntermissionSeconds, 1, -1 do
        local options = nil
        if t <= intermissionSettings.VoteSeconds then
            voteOpen = true
            options = {}
            local voteCounts = currentVoteCounts()

            for _, d in ipairs(currentOptions) do
                table.insert(options, {
                    id = d.Id,
                    name = d.Name,
                    hint = d.Hint,
                    votes = voteCounts[d.Id] or 0,
                })
            end
        end

        broadcast({
            phase = "intermission",
            title = options and "VOTE FOR THE NEXT CHAOS" or (intermissionSettings.Solo and "SOLO RUSH" or "NEXT ROUND"),
            hint = options and "Choose one" or ((arenaDefinition and arenaDefinition.Name or "ARENA") .. " • " .. (intermissionSettings.Solo and "Fast rounds • bonus rewards" or "Get ready")),
            seconds = t,
            voteOptions = options,
            soloMode = intermissionSettings.Solo,
            arenaName = arenaDefinition and arenaDefinition.Name or currentArenaVariant,
        })
        task.wait(1)
    end

    voteOpen = false

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
    local forceDouble = (upcomingRoundNumber % roundSettings.DoubleChaosEvery == 0)
    if forceDouble or math.random() < roundSettings.DoubleChaosChance then
        local candidates = DisasterBalance.filterCompatible(selected.Id, disasters)
        if #candidates > 0 then
            table.insert(selectedSet, candidates[math.random(1, #candidates)])
        end
    end

    local readyTitle = selectedSet[1].Name
    local readyHint = selectedSet[1].Hint
    if #selectedSet > 1 then
        readyTitle = "DOUBLE CHAOS: " .. selectedSet[1].Name .. " + " .. selectedSet[2].Name
        readyHint = selectedSet[1].Hint .. " / " .. selectedSet[2].Hint
    elseif roundSettings.Solo then
        readyTitle = "SOLO RUSH: " .. readyTitle
    end

    local readyDisasterIds = {}
    for _, disaster in ipairs(selectedSet) do
        table.insert(readyDisasterIds, disaster.Id)
    end

    for t = roundSettings.ReadySeconds, 1, -1 do
        broadcast({
            phase = "ready",
            title = "READY: " .. readyTitle,
            hint = "Find your position • " .. readyHint,
            seconds = t,
            doubleChaos = #selectedSet > 1,
            soloMode = roundSettings.Solo,
            arenaName = roundSettings.ArenaName,
            disasterIds = readyDisasterIds,
            survivorsAlive = #contestants,
            contestantCount = #contestants,
        })
        task.wait(1)
    end

    local startingContestants = {}
    for _, p in ipairs(contestants) do
        if p.Parent == Players
            and p:GetAttribute("DataLoaded") == true
            and alive(p)
        then
            table.insert(startingContestants, p)
        else
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

    roundNumber = upcomingRoundNumber
    recentPrimaryDisasterIds = RoundVariety.pushRecent(recentPrimaryDisasterIds, selected.Id, 2)

    for _, p in ipairs(contestants) do
        GameAnalytics.roundStarted(p, roundNumber, roundSettings.Solo, selected.Id, #selectedSet > 1)
    end

    local eliminated, endedEarly, roundElapsed = runDisasterSet(selectedSet, contestants, roundSettings)

    local survivors = 0
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

            local criticalSurvival = false
            if survived then
                local humanoid = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.MaxHealth > 0 then
                    criticalSurvival = (humanoid.Health / humanoid.MaxHealth) <= 0.20
                end
            end

            if survived then
                survivors += 1
                PlayerData.add(p, "Coins", winCoins + streakBonusCoins)
                PlayerData.add(p, "XP", winXP)
                PlayerData.add(p, "Wins", 1)

                GameAnalytics.economySource(p, winCoins, "RoundSurvival", selected.Id, roundSettings.Solo)
                if streakBonusCoins > 0 then
                    GameAnalytics.economySource(p, streakBonusCoins, "SurvivalStreak", "Streak" .. tostring(survivalStreak), roundSettings.Solo)
                end
                progressQuest(p, "survive_round", 1)
                progressQuest(p, "coins_earned", winCoins + streakBonusCoins)

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

            GameAnalytics.roundCompleted(
                p,
                survived,
                roundSettings.Solo,
                selected.Id,
                #selectedSet > 1,
                roundElapsed
            )

            local newlyUnlockedAchievements = AchievementService.evaluate(p)
            if #newlyUnlockedAchievements > 0 then
                GameAnalytics.custom(
                    p,
                    "AchievementUnlocked",
                    #newlyUnlockedAchievements,
                    "First:" .. tostring(newlyUnlockedAchievements[1]),
                    "Level:" .. tostring(p:GetAttribute("Level") or 1)
                )
            end

            roundFeedbackEvent:FireClient(p, {
                survived = survived,
                coins = survived and (winCoins + streakBonusCoins) or Config.ParticipationCoins,
                xp = survived and winXP or Config.ParticipationXP,
                streak = survivalStreak,
                streakBonusCoins = survived and streakBonusCoins or 0,
                bestSessionStreak = bestSessionStreak,
                arenaName = roundSettings.ArenaName,
                disasterName = feedbackDisasterName,
                doubleChaos = #selectedSet > 1,
                soloMode = roundSettings.Solo,
                elapsedSeconds = math.floor(roundElapsed + 0.5),
                criticalSurvival = criticalSurvival,
            })
        end
    end

    broadcast({
        phase = "result",
        title = endedEarly and "TOTAL WIPEOUT" or (survivors .. " SURVIVED"),
        hint = "Next round soon",
        seconds = roundSettings.PostRoundSeconds,
        doubleChaos = #selectedSet > 1,
        soloMode = roundSettings.Solo,
        arenaName = roundSettings.ArenaName,
    })

    for t = roundSettings.PostRoundSeconds, 1, -1 do
        broadcast({
            phase = "result",
            title = endedEarly and "TOTAL WIPEOUT" or (survivors .. " SURVIVED"),
            hint = "Next round soon",
            seconds = t,
            doubleChaos = #selectedSet > 1,
            soloMode = roundSettings.Solo,
            arenaName = roundSettings.ArenaName,
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