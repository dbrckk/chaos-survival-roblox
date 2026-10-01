local Players = game:GetService("Players")
local RemoteRegistry = require(script.Parent.RemoteRegistry)
local BadgeService = game:GetService("BadgeService")

local Achievements = require(script.Parent.Achievements)
local PlayerData = require(script.Parent.PlayerData)
local GameAnalytics = require(script.Parent.GameAnalytics)
local PlayerReadiness = require(script.Parent.PlayerReadiness)

local AchievementService = {}

local setupStarted = setmetatable({}, {__mode = "k"})

local stateEvent

local function statsFor(player)
    return {
        Wins = player:GetAttribute("Wins") or 0,
        Games = player:GetAttribute("Games") or 0,
        Level = player:GetAttribute("Level") or 1,
        BestStreak = player:GetAttribute("BestStreak") or 0,
        DoubleChaosSurvivals = player:GetAttribute("DoubleChaosSurvivals") or 0,
    }
end

local function awardRobloxBadge(player, def)
    local badgeId = def.BadgeId
    if type(badgeId) ~= "number" or badgeId <= 0 then
        return
    end

    task.spawn(function()
        local okOwned, owned = pcall(BadgeService.UserHasBadgeAsync, BadgeService, player.UserId, badgeId)
        if okOwned and not owned then
            pcall(BadgeService.AwardBadge, BadgeService, player.UserId, badgeId)
        end
    end)
end

local function sendState(player, newlyUnlocked)
    if not stateEvent then return end

    stateEvent:FireClient(player, {
        state = Achievements.publicState(
            statsFor(player),
            player:GetAttribute("UnlockedAchievements") or ""
        ),
        unlockedNow = newlyUnlocked or {},
    })
end

local function evaluate(player)
    if player.Parent ~= Players or player:GetAttribute("DataLoaded") ~= true then
        return {}
    end

    if player:GetAttribute("DataPersistenceAvailable") ~= true then
        sendState(player, {})
        return {}
    end

    local serialized, unlockedNow = Achievements.evaluate(
        statsFor(player),
        player:GetAttribute("UnlockedAchievements") or ""
    )

    if #unlockedNow > 0 then
        player:SetAttribute("UnlockedAchievements", serialized)

        for _, id in ipairs(unlockedNow) do
            local def = Achievements.get(id)
            if def then
                PlayerData.add(player, "Coins", def.Coins)
                PlayerData.add(player, "XP", def.XP)
                awardRobloxBadge(player, def)

                GameAnalytics.custom(
                    player,
                    "AchievementUnlocked",
                    1,
                    "Achievement:" .. id,
                    "Level:" .. tostring(player:GetAttribute("Level") or 1)
                )
                GameAnalytics.economySource(
                    player,
                    def.Coins,
                    "Achievement",
                    id,
                    #Players:GetPlayers() <= 1
                )
            end
        end
    end

    sendState(player, unlockedNow)
    return unlockedNow
end

function AchievementService.evaluate(player)
    return evaluate(player)
end

local function setupPlayer(player)
    if setupStarted[player] then
        return
    end
    setupStarted[player] = true
    task.spawn(function()
        if not PlayerReadiness.waitForDataLoaded(player) then
            return
        end

        evaluate(player)

        for _, attr in ipairs({"Wins", "Games", "Level", "BestStreak", "DoubleChaosSurvivals"}) do
            player:GetAttributeChangedSignal(attr):Connect(function()
                evaluate(player)
            end)
        end
    end)
end

function AchievementService.sync(player)
    evaluate(player)
end

function AchievementService.init(remotes)
    stateEvent = RemoteRegistry.ensureRemoteEvent(remotes, "AchievementState")

    Players.PlayerAdded:Connect(setupPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        setupPlayer(player)
    end
end

return AchievementService
