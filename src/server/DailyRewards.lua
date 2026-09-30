local DailyRewards = {}

DailyRewards.Rewards = {
    {Coins = 25, XP = 15},
    {Coins = 35, XP = 20},
    {Coins = 50, XP = 25},
    {Coins = 65, XP = 30},
    {Coins = 80, XP = 35},
    {Coins = 100, XP = 45},
    {Coins = 150, XP = 75},
}

function DailyRewards.dayNumber(timestamp)
    return math.floor(timestamp / 86400)
end

function DailyRewards.compute(lastClaimDay, currentDay, currentStreak)
    if type(currentDay) ~= "number" then
        return nil
    end

    if type(lastClaimDay) == "number" and lastClaimDay == currentDay then
        return nil
    end

    local streak
    if type(lastClaimDay) == "number" and lastClaimDay == currentDay - 1 then
        streak = math.max(0, tonumber(currentStreak) or 0) + 1
    else
        streak = 1
    end

    local rewardIndex = ((streak - 1) % #DailyRewards.Rewards) + 1
    local reward = DailyRewards.Rewards[rewardIndex]

    return {
        Day = currentDay,
        Streak = streak,
        RewardIndex = rewardIndex,
        Coins = reward.Coins,
        XP = reward.XP,
    }
end

return DailyRewards
