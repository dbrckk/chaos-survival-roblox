local WeeklyChallenges = {}

WeeklyChallenges.Definitions = {
    PLAY_20 = {
        Id = "PLAY_20",
        Title = "Play 20 rounds",
        Event = "play_round",
        Target = 20,
        Coins = 180,
        XP = 120,
    },
    SURVIVE_10 = {
        Id = "SURVIVE_10",
        Title = "Survive 10 rounds",
        Event = "survive_round",
        Target = 10,
        Coins = 220,
        XP = 150,
    },
    COLLECT_30 = {
        Id = "COLLECT_30",
        Title = "Collect 30 Chaos Shards",
        Event = "collect_shard",
        Target = 30,
        Coins = 200,
        XP = 130,
    },
    DOUBLE_3 = {
        Id = "DOUBLE_3",
        Title = "Survive 3 Double Chaos rounds",
        Event = "survive_double",
        Target = 3,
        Coins = 260,
        XP = 170,
    },
    EARN_500 = {
        Id = "EARN_500",
        Title = "Earn 500 round coins",
        Event = "coins_earned",
        Target = 500,
        Coins = 210,
        XP = 140,
    },
}

local ORDER = {
    "PLAY_20",
    "SURVIVE_10",
    "COLLECT_30",
    "DOUBLE_3",
    "EARN_500",
}

function WeeklyChallenges.weekNumber(timestamp)
    return math.floor((tonumber(timestamp) or 0) / (86400 * 7))
end

function WeeklyChallenges.selectForWeek(week, count)
    local wanted = math.clamp(count or 2, 1, #ORDER)
    local selected = {}
    local start = (math.abs(math.floor(tonumber(week) or 0)) % #ORDER) + 1

    for i = 0, wanted - 1 do
        local index = ((start + i - 1) % #ORDER) + 1
        table.insert(selected, ORDER[index])
    end

    return selected
end

function WeeklyChallenges.definition(id)
    return WeeklyChallenges.Definitions[id]
end

function WeeklyChallenges.applyProgress(id, currentProgress, eventName, amount)
    local definition = WeeklyChallenges.Definitions[id]
    if not definition or definition.Event ~= eventName then
        return currentProgress or 0, false
    end

    local before = math.max(0, tonumber(currentProgress) or 0)
    local after = math.min(
        definition.Target,
        before + math.max(0, tonumber(amount) or 0)
    )
    return after, after >= definition.Target and before < definition.Target
end

return WeeklyChallenges
