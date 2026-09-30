local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DailyRewards = require(script.Parent.DailyRewards)

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
