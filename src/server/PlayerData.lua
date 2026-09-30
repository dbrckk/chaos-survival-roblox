local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DailyRewards = require(script.Parent.DailyRewards)
local DailyQuests = require(script.Parent.DailyQuests)

local store = DataStoreService:GetDataStore("ChaosSurvival_v3")
local PlayerData = {}

local DEFAULT = {
    Coins = 0,
    XP = 0,
    Wins = 0,
    Games = 0,
    Level = 1,
    BestStreak = 0,
    DailyStreak = 0,
    LastDailyDay = -1,

    QuestDay = -1,
    Quest1Id = "",
    Quest1Progress = 0,
    Quest1Claimed = false,
    Quest2Id = "",
    Quest2Progress = 0,
    Quest2Claimed = false,
    Quest3Id = "",
    Quest3Progress = 0,
    Quest3Claimed = false,

    OwnedCosmetics = "",
    EquippedCosmetic = "",
}

local function cloneDefault()
    local t = {}
    for k,v in pairs(DEFAULT) do t[k] = v end
    return t
end

local function levelForXP(xp)
    return math.max(1, math.floor(math.sqrt(math.max(0, xp) / 100)) + 1)
end

local function applyAttributes(player, data)
    data.Level = levelForXP(data.XP)
    for k,v in pairs(data) do
        player:SetAttribute(k, v)
    end
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
    local data = cloneDefault()
    local ok, saved = pcall(function()
        return store:GetAsync("u_" .. player.UserId)
    end)

    if ok and type(saved) == "table" then
        for k,v in pairs(DEFAULT) do
            if type(saved[k]) == type(v) then
                data[k] = saved[k]
            end
        end
    elseif not ok then
        warn("Failed to load player data", player.UserId, saved)
    end

    applyAttributes(player, data)
    PlayerData.ensureDailyQuests(player)
    player:SetAttribute("DataLoaded", true)
end

function PlayerData.save(player)
    local data = {}
    for k,_ in pairs(DEFAULT) do
        data[k] = player:GetAttribute(k)
        if data[k] == nil then
            data[k] = DEFAULT[k]
        end
    end

    local ok, err = pcall(function()
        store:UpdateAsync("u_" .. player.UserId, function()
            return data
        end)
    end)

    if not ok then
        warn("Failed to save player data", player.UserId, err)
    end

    return ok
end

function PlayerData.add(player, field, amount)
    local value = (player:GetAttribute(field) or 0) + amount
    player:SetAttribute(field, value)

    if field == "XP" then
        player:SetAttribute("Level", levelForXP(value))
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
    Players.PlayerAdded:Connect(PlayerData.load)
    Players.PlayerRemoving:Connect(PlayerData.save)

    for _,p in ipairs(Players:GetPlayers()) do
        task.spawn(PlayerData.load, p)
    end

    game:BindToClose(function()
        for _,p in ipairs(Players:GetPlayers()) do
            PlayerData.save(p)
        end
    end)
end

return PlayerData
