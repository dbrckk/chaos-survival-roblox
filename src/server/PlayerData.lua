local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local DailyRewards = require(script.Parent.DailyRewards)
local DailyQuests = require(script.Parent.DailyQuests)
local DataSchema = require(script.Parent.DataSchema)
local DataSession = require(script.Parent.DataSession)

local store = DataStoreService:GetDataStore("ChaosSurvival_v3")
local PlayerData = {}

local MAX_ATTEMPTS = 4
local AUTOSAVE_SECONDS = 60
local AUTOSAVE_SPREAD_SECONDS = 12
local SHUTDOWN_SAVE_DEADLINE_SECONDS = 27

local active = {}
local loading = {}
local saving = {}
local revisions = {}
local savedRevisions = {}
local sessionTokens = {}
local dataConnections = {}

local function withRetry(operationName, userId, callback)
    local lastError

    for attempt = 1, MAX_ATTEMPTS do
        local ok, result = pcall(callback)
        if ok then
            return true, result
        end

        lastError = result
        warn(
            string.format(
                "%s failed for user %s (attempt %d/%d): %s",
                operationName,
                tostring(userId),
                attempt,
                MAX_ATTEMPTS,
                tostring(result)
            )
        )

        if attempt < MAX_ATTEMPTS then
            task.wait(DataSchema.retryDelay(attempt))
        end
    end

    return false, lastError
end

local function applyAttributes(player, data)
    for key, value in pairs(data) do
        player:SetAttribute(key, value)
    end
end

local function disconnectDataConnections(player)
    local connections = dataConnections[player]
    if connections then
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
    end
    dataConnections[player] = nil
end

local function trackPersistentChanges(player)
    disconnectDataConnections(player)

    local connections = {}
    for key in pairs(DataSchema.Defaults) do
        connections[#connections+1] = player:GetAttributeChangedSignal(key):Connect(function()
            if active[player] then
                revisions[player] = (revisions[player] or 0) + 1
            end
        end)
    end
    dataConnections[player] = connections
end

local function setupLeaderstats(player)
    local folder = player:FindFirstChild("leaderstats")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "leaderstats"
        folder.Parent = player
    end

    local wins = folder:FindFirstChild("Wins")
    if not wins then
        wins = Instance.new("IntValue")
        wins.Name = "Wins"
        wins.Parent = folder
    end

    local level = folder:FindFirstChild("Level")
    if not level then
        level = Instance.new("IntValue")
        level.Name = "Level"
        level.Parent = folder
    end

    local function refresh()
        wins.Value = math.max(0, tonumber(player:GetAttribute("Wins")) or 0)
        level.Value = math.max(1, tonumber(player:GetAttribute("Level")) or 1)
    end

    player:GetAttributeChangedSignal("Wins"):Connect(refresh)
    player:GetAttributeChangedSignal("Level"):Connect(refresh)
    refresh()
end

local function resetDailyQuests(player, day)
    local ids = DailyQuests.selectForDay(day, 3)
    player:SetAttribute("QuestDay", day)

    for i = 1, 3 do
        player:SetAttribute("Quest" .. i .. "Id", ids[i])
        player:SetAttribute("Quest" .. i .. "Progress", 0)
        player:SetAttribute("Quest" .. i .. "Claimed", false)
    end
end

function PlayerData.ensureDailyQuests(player, nowTimestamp)
    local day = DailyQuests.dayNumber(nowTimestamp or os.time())
    if player:GetAttribute("QuestDay") ~= day then
        resetDailyQuests(player, day)
    end
end

function PlayerData.load(player)
    if active[player] then
        return player:GetAttribute("DataPersistenceAvailable") == true
    end

    if loading[player] then
        while player.Parent == Players and loading[player] do
            task.wait(0.05)
        end
        return active[player] == true
            and player:GetAttribute("DataPersistenceAvailable") == true
    end

    loading[player] = true

    player:SetAttribute("DataLoaded", false)
    player:SetAttribute("DataPersistenceAvailable", false)
    player:SetAttribute("DataLoadFailed", false)
    player:SetAttribute("DataSaveConflict", false)

    local sessionToken = HttpService:GenerateGUID(false)
    local ok, savedOrError = withRetry("DataStore load", player.UserId, function()
        return store:UpdateAsync("u_" .. player.UserId, function(saved)
            return DataSession.claim(saved, sessionToken, os.time())
        end)
    end)

    local data
    if ok then
        sessionTokens[player] = sessionToken
        data = DataSchema.normalize(savedOrError)
        player:SetAttribute("DataPersistenceAvailable", true)
    else
        data = DataSchema.cloneDefaults()
        player:SetAttribute("DataLoadFailed", true)
        warn(
            "Using temporary session data; persistent saves disabled for user",
            player.UserId,
            savedOrError
        )
    end

    if player.Parent ~= Players then
        loading[player] = nil
        return false
    end

    applyAttributes(player, data)
    setupLeaderstats(player)
    PlayerData.ensureDailyQuests(player)

    active[player] = true
    revisions[player] = ok and 1 or 0
    savedRevisions[player] = 0
    trackPersistentChanges(player)
    player:SetAttribute("DataLoaded", true)
    loading[player] = nil
    return ok
end

function PlayerData.save(player, waitForExisting)
    if not active[player] then
        return false
    end

    if player:GetAttribute("DataPersistenceAvailable") ~= true then
        return false
    end

    if saving[player] then
        if not waitForExisting then
            return false
        end

        local deadline = os.clock() + 10
        while saving[player] and os.clock() < deadline do
            task.wait(0.05)
        end

        if saving[player] then
            warn("Timed out waiting for existing save", player.UserId)
            return false
        end
    end

    local currentRevision = revisions[player] or 0
    local lastSavedRevision = savedRevisions[player] or 0
    if currentRevision == lastSavedRevision then
        return true
    end

    saving[player] = true
    local revisionAtStart = revisions[player] or 0

    local data = DataSchema.snapshot(function(key)
        return player:GetAttribute(key)
    end)

    local sessionToken = sessionTokens[player]
    if type(sessionToken) ~= "string" or sessionToken == "" then
        saving[player] = nil
        player:SetAttribute("LastSaveFailed", true)
        warn("Missing DataStore session ownership token", player.UserId)
        return false
    end

    local ownershipConflict = false
    local ok, err = withRetry("DataStore save", player.UserId, function()
        return store:UpdateAsync("u_" .. player.UserId, function(saved)
            local merged = DataSession.merge(saved, data, sessionToken, os.time())
            if not merged then
                ownershipConflict = true
                return nil
            end
            return merged
        end)
    end)

    saving[player] = nil

    if ownershipConflict then
        player:SetAttribute("DataPersistenceAvailable", false)
        player:SetAttribute("DataSaveConflict", true)
        warn("Skipped stale DataStore save after session ownership changed", player.UserId)
        return false
    end

    if ok then
        savedRevisions[player] = math.max(savedRevisions[player] or 0, revisionAtStart)
        player:SetAttribute("LastSaveUnix", os.time())
        player:SetAttribute("LastSaveFailed", false)
    else
        player:SetAttribute("LastSaveFailed", true)
        warn("Failed to persist player data after retries", player.UserId, err)
    end

    return ok
end

function PlayerData.canMutate(player)
    return player ~= nil
        and player.Parent == Players
        and active[player] == true
        and player:GetAttribute("DataLoaded") == true
        and player:GetAttribute("DataPersistenceAvailable") == true
end

function PlayerData.add(player, field, amount)
    if not PlayerData.canMutate(player) then
        return tonumber(player and player:GetAttribute(field)) or 0
    end

    local value = (player:GetAttribute(field) or 0) + amount
    player:SetAttribute(field, value)

    if field == "XP" then
        player:SetAttribute("Level", DataSchema.levelForXP(value))
    end

    return value
end

function PlayerData.claimDaily(player, nowTimestamp)
    if not PlayerData.canMutate(player) then
        return nil
    end

    local currentDay = DailyRewards.dayNumber(nowTimestamp or os.time())
    local claim = DailyRewards.compute(
        player:GetAttribute("LastDailyDay"),
        currentDay,
        player:GetAttribute("DailyStreak")
    )

    if not claim then
        return nil
    end

    player:SetAttribute("LastDailyDay", claim.Day)
    player:SetAttribute("DailyStreak", claim.Streak)

    local best = math.max(player:GetAttribute("BestStreak") or 0, claim.Streak)
    player:SetAttribute("BestStreak", best)

    PlayerData.add(player, "Coins", claim.Coins)
    PlayerData.add(player, "XP", claim.XP)

    return claim
end

function PlayerData.getQuestState(player, nowTimestamp)
    if not PlayerData.canMutate(player) then
        return {
            day = player and player:GetAttribute("QuestDay") or -1,
            quests = {},
        }
    end

    PlayerData.ensureDailyQuests(player, nowTimestamp)

    local quests = {}
    for i = 1, 3 do
        local id = player:GetAttribute("Quest" .. i .. "Id")
        local definition = DailyQuests.definition(id)
        if definition then
            table.insert(quests, {
                slot = i,
                id = id,
                title = definition.Title,
                target = definition.Target,
                progress = player:GetAttribute("Quest" .. i .. "Progress") or 0,
                claimed = player:GetAttribute("Quest" .. i .. "Claimed") == true,
                coins = definition.Coins,
                xp = definition.XP,
            })
        end
    end

    return {
        day = player:GetAttribute("QuestDay"),
        quests = quests,
    }
end

function PlayerData.progressQuestEvent(player, eventName, amount, nowTimestamp)
    if not PlayerData.canMutate(player) then
        return {}, PlayerData.getQuestState(player, nowTimestamp)
    end

    PlayerData.ensureDailyQuests(player, nowTimestamp)

    local completed = {}

    for i = 1, 3 do
        local idKey = "Quest" .. i .. "Id"
        local progressKey = "Quest" .. i .. "Progress"
        local claimedKey = "Quest" .. i .. "Claimed"

        local id = player:GetAttribute(idKey)
        local definition = DailyQuests.definition(id)
        local claimed = player:GetAttribute(claimedKey) == true

        if definition and not claimed then
            local progress, justCompleted = DailyQuests.applyProgress(
                id,
                player:GetAttribute(progressKey) or 0,
                eventName,
                amount or 1
            )

            player:SetAttribute(progressKey, progress)

            if justCompleted then
                player:SetAttribute(claimedKey, true)
                PlayerData.add(player, "Coins", definition.Coins)
                PlayerData.add(player, "XP", definition.XP)

                table.insert(completed, {
                    slot = i,
                    id = id,
                    title = definition.Title,
                    coins = definition.Coins,
                    xp = definition.XP,
                })
            end
        end
    end

    return completed, PlayerData.getQuestState(player, nowTimestamp)
end

function PlayerData.init()
    Players.PlayerAdded:Connect(function(player)
        task.spawn(PlayerData.load, player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        PlayerData.save(player, true)
        disconnectDataConnections(player)
        active[player] = nil
        loading[player] = nil
        saving[player] = nil
        revisions[player] = nil
        savedRevisions[player] = nil
        sessionTokens[player] = nil
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(PlayerData.load, player)
    end

    task.spawn(function()
        while true do
            task.wait(AUTOSAVE_SECONDS)

            local players = Players:GetPlayers()
            local count = #players
            for index, player in ipairs(players) do
                local delaySeconds = 0
                if count > 1 then
                    delaySeconds = ((index - 1) / count) * AUTOSAVE_SPREAD_SECONDS
                end

                task.delay(delaySeconds, function()
                    if player.Parent == Players
                        and active[player]
                        and player:GetAttribute("DataPersistenceAvailable") == true
                    then
                        PlayerData.save(player)
                    end
                end)
            end
        end
    end)

    game:BindToClose(function()
        local pending = 0

        for _, player in ipairs(Players:GetPlayers()) do
            if active[player] and player:GetAttribute("DataPersistenceAvailable") == true then
                pending += 1
                task.spawn(function()
                    PlayerData.save(player, true)
                    pending -= 1
                end)
            end
        end

        local deadline = os.clock() + SHUTDOWN_SAVE_DEADLINE_SECONDS
        while pending > 0 and os.clock() < deadline do
            task.wait(0.1)
        end

        if pending > 0 then
            warn("Server shutdown reached save deadline with pending player saves:", pending)
        end
    end)
end

return PlayerData
