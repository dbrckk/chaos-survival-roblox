local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DailyRewards = require(script.Parent.DailyRewards)
local DailyQuests = require(script.Parent.DailyQuests)
local DataSchema = require(script.Parent.DataSchema)

local store = DataStoreService:GetDataStore("ChaosSurvival_v3")
local PlayerData = {}

local MAX_ATTEMPTS = 4
local AUTOSAVE_SECONDS = 60
local AUTOSAVE_SPREAD_SECONDS = 12
local SHUTDOWN_SAVE_DEADLINE_SECONDS = 27

local active = {}
local saving = {}

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
        return true
    end

    player:SetAttribute("DataLoaded", false)
    player:SetAttribute("DataPersistenceAvailable", false)
    player:SetAttribute("DataLoadFailed", false)

    local ok, savedOrError = withRetry("DataStore load", player.UserId, function()
        return store:GetAsync("u_" .. player.UserId)
    end)

    local data
    if ok then
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
        return false
    end

    applyAttributes(player, data)
    setupLeaderstats(player)
    PlayerData.ensureDailyQuests(player)

    active[player] = true
    player:SetAttribute("DataLoaded", true)
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

    saving[player] = true

    local data = DataSchema.snapshot(function(key)
        return player:GetAttribute(key)
    end)

    local ok, err = withRetry("DataStore save", player.UserId, function()
        return store:UpdateAsync("u_" .. player.UserId, function()
            return data
        end)
    end)

    saving[player] = nil

    if ok then
        player:SetAttribute("LastSaveUnix", os.time())
        player:SetAttribute("LastSaveFailed", false)
    else
        player:SetAttribute("LastSaveFailed", true)
        warn("Failed to persist player data after retries", player.UserId, err)
    end

    return ok
end

function PlayerData.add(player, field, amount)
    local value = (player:GetAttribute(field) or 0) + amount
    player:SetAttribute(field, value)

    if field == "XP" then
        player:SetAttribute("Level", DataSchema.levelForXP(value))
    end

    return value
end

function PlayerData.claimDaily(player, nowTimestamp)
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
        active[player] = nil
        saving[player] = nil
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
