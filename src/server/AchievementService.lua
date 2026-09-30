local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

local Achievements = require(script.Parent.Achievements)

local AchievementService = {}

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
    if not player:GetAttribute("DataLoaded") then
        return
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
                player:SetAttribute("Coins", (player:GetAttribute("Coins") or 0) + def.Coins)
                player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + def.XP)
                awardRobloxBadge(player, def)
            end
        end
    end

    sendState(player, unlockedNow)
end

local function setupPlayer(player)
    task.spawn(function()
        if not player:GetAttribute("DataLoaded") then
            player:GetAttributeChangedSignal("DataLoaded"):Wait()
        end

        if player.Parent ~= Players then
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

function AchievementService.init(remotes)
    stateEvent = remotes:FindFirstChild("AchievementState") or Instance.new("RemoteEvent")
    stateEvent.Name = "AchievementState"
    stateEvent.Parent = remotes

    Players.PlayerAdded:Connect(setupPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        setupPlayer(player)
    end
end

return AchievementService
