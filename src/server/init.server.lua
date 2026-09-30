local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local MapBuilder = require(script.MapBuilder)
local PlayerData = require(script.PlayerData)
local RateLimiter = require(script.RateLimiter)
local CosmeticService = require(script.CosmeticService)
local AchievementService = require(script.AchievementService)
local SoloRules = require(script.SoloRules)
local GameAnalytics = require(script.GameAnalytics)
local ArenaVariants = require(script.ArenaVariants)
local DisasterBalance = require(script.DisasterBalance)

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

PlayerData.init()
CosmeticService.init(remotes, RateLimiter)
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
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local spawns = workspace.GeneratedMap.Arena.Spawns:GetChildren()
    if root and #spawns > 0 then
        root.CFrame = spawns[((index - 1) % #spawns) + 1].CFrame + Vector3.new(0, 4, 0)
    end
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
    local pool = shuffledPool()
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

Players.PlayerAdded:Connect(function(player)
    GameAnalytics.sessionStarted(player, #Players:GetPlayers())
    setupDailyReward(player)
end)

Players.PlayerRemoving:Connect(function(player)
    GameAnalytics.sessionEnded(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    GameAnalytics.sessionStarted(player, #Players:GetPlayers())
    setupDailyReward(player)
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

local function winningOption()
    local counts = {}
    for _, d in ipairs(currentOptions) do counts[d.Id] = 0 end
    for _, id in pairs(currentVotes) do
        if counts[id] ~= nil then counts[id] += 1 end
    end

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
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            deathConnections[player.UserId] = hum.Died:Connect(function()
                eliminated[player.UserId] = true
            end)
        end
    end

    local function anyContestantRemaining()
        for _, player in ipairs(contestants) do
            if player.Parent == Players and not eliminated[player.UserId] then
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    return true
                end
            end
        end
        return false
    end

    local ctx = {
        Config = Config,
        RoundSeconds = roundSettings.RoundSeconds,
        Cleanup = cleanup,
        OnCleanup = onCleanup,
        Active = function() return roundActive end,
        Contestants = contestants,
        BalanceProfile = DisasterBalance.mobileProfile(#contestants),
    }

    for _, disaster in ipairs(selected) do
        local ok, err = pcall(disaster.start, ctx)
        if not ok then
            warn("Disaster failed to start:", disaster.Id, err)
        end
    end

    local endedEarly = false
    for t = roundSettings.RoundSeconds, 1, -1 do
        if not anyContestantRemaining() then
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

        broadcast({
            phase = "round",
            title = title,
            hint = roundSettings.Solo and ("Solo bonus active • " .. hint) or hint,
            seconds = t,
            doubleChaos = #selected > 1,
            soloMode = roundSettings.Solo,
            arenaName = roundSettings.ArenaName or currentArenaVariant,
        })

        task.wait(1)
    end

    roundActive = false

    for _, connection in pairs(deathConnections) do
        connection:Disconnect()
    end

    for _, fn in ipairs(onCleanup) do pcall(fn) end
    for _, obj in ipairs(cleanup) do
        if obj and obj.Parent then obj:Destroy() end
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

    currentArenaVariant = ArenaVariants.choose(currentArenaVariant)
    local arenaDefinition = ArenaVariants.get(currentArenaVariant)
    local intermissionSettings = SoloRules.resolve(Config, #Players:GetPlayers())

    for t = intermissionSettings.IntermissionSeconds, 1, -1 do
        local options = nil
        if t <= intermissionSettings.VoteSeconds then
            voteOpen = true
            options = {}
            for _, d in ipairs(currentOptions) do
                table.insert(options, {id = d.Id, name = d.Name, hint = d.Hint})
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
    roundNumber += 1

    local contestants = Players:GetPlayers()
    local roundSettings = SoloRules.resolve(Config, #contestants)
    roundSettings.ArenaName = arenaDefinition and arenaDefinition.Name or currentArenaVariant

    MapBuilder.buildArena(Config, currentArenaVariant, ArenaVariants)
    for i, p in ipairs(contestants) do
        if not p.Character or not alive(p) then
            p:LoadCharacter()
            task.wait(0.1)
        end
        teleportToArena(p, i)
        PlayerData.add(p, "Games", 1)
        progressQuest(p, "play_round", 1)
    end

    local selectedSet = {selected}
    local forceDouble = (roundNumber % roundSettings.DoubleChaosEvery == 0)
    if forceDouble or math.random() < roundSettings.DoubleChaosChance then
        local candidates = DisasterBalance.filterCompatible(selected.Id, disasters)
        if #candidates > 0 then
            table.insert(selectedSet, candidates[math.random(1, #candidates)])
        end
    end

    for _, p in ipairs(contestants) do
        if p.Parent == Players then
            GameAnalytics.roundStarted(p, roundNumber, roundSettings.Solo, selected.Id, #selectedSet > 1)
        end
    end

    local eliminated, endedEarly, roundElapsed = runDisasterSet(selectedSet, contestants, roundSettings)

    local survivors = 0
    local winCoins = SoloRules.reward(Config.WinCoins, roundSettings.WinCoinMultiplier)
    local winXP = SoloRules.reward(Config.WinXP, roundSettings.WinXPMultiplier)
    for _, p in ipairs(contestants) do
        if p.Parent == Players then
            local survived = eliminated[p.UserId] ~= true and alive(p)
            if survived then
                survivors += 1
                PlayerData.add(p, "Coins", winCoins)
                PlayerData.add(p, "XP", winXP)
                PlayerData.add(p, "Wins", 1)

                GameAnalytics.economySource(p, winCoins, "RoundSurvival", selected.Id, roundSettings.Solo)
                progressQuest(p, "survive_round", 1)
                progressQuest(p, "coins_earned", winCoins)

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

            roundFeedbackEvent:FireClient(p, {
                survived = survived,
                coins = survived and winCoins or Config.ParticipationCoins,
                xp = survived and winXP or Config.ParticipationXP,
                soloMode = roundSettings.Solo,
                doubleChaos = #selectedSet > 1,
                arenaName = arenaDefinition and arenaDefinition.Name or currentArenaVariant,
                disasterName = selected.Name,
                elapsedSeconds = math.floor(roundElapsed + 0.5),
            })

            p:LoadCharacter()
        end
    end

    local resultTitle
    local resultHint

    if roundSettings.Solo then
        resultTitle = survivors > 0 and "SOLO SURVIVED!" or "ELIMINATED"
        resultHint = survivors > 0
            and ("Solo reward +" .. winCoins .. " coins")
            or (endedEarly and "Quick retry incoming" or "Try again")
    else
        resultTitle = survivors .. " SURVIVED"
        resultHint = "Survivors +" .. winCoins .. " coins"
    end

    for t = roundSettings.PostRoundSeconds, 1, -1 do
        broadcast({
            phase = "results",
            title = resultTitle,
            hint = resultHint,
            seconds = t,
            soloMode = roundSettings.Solo,
            arenaName = roundSettings.ArenaName,
        })
        task.wait(1)
    end
end
