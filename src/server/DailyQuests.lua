local DailyQuests = {}

DailyQuests.Definitions = {
    PLAY_3 = {
        Id = "PLAY_3",
        Title = "Play 3 rounds",
        Event = "play_round",
        Target = 3,
        Coins = 40,
        XP = 25,
    },
    SURVIVE_2 = {
        Id = "SURVIVE_2",
        Title = "Survive 2 rounds",
        Event = "survive_round",
        Target = 2,
        Coins = 60,
        XP = 35,
    },
    DOUBLE_CHAOS = {
        Id = "DOUBLE_CHAOS",
        Title = "Survive a Double Chaos",
        Event = "survive_double",
        Target = 1,
        Coins = 90,
        XP = 50,
    },
    EARN_75 = {
        Id = "EARN_75",
        Title = "Earn 75 round coins",
        Event = "coins_earned",
        Target = 75,
        Coins = 70,
        XP = 40,
    },
    PLAY_5 = {
        Id = "PLAY_5",
        Title = "Play 5 rounds",
        Event = "play_round",
        Target = 5,
        Coins = 65,
        XP = 35,
    },
    SURVIVE_3 = {
        Id = "SURVIVE_3",
        Title = "Survive 3 rounds",
        Event = "survive_round",
        Target = 3,
        Coins = 85,
        XP = 45,
    },
}

local ORDER = {
    "PLAY_3",
    "SURVIVE_2",
    "DOUBLE_CHAOS",
    "EARN_75",
    "PLAY_5",
    "SURVIVE_3",
}

function DailyQuests.dayNumber(timestamp)
    return math.floor(timestamp / 86400)
end

function DailyQuests.selectForDay(day, count)
    local wanted = math.clamp(count or 3, 1, #ORDER)
    local selected = {}

    local start = (math.abs(day) % #ORDER) + 1
    for i = 0, wanted - 1 do
        local index = ((start + i - 1) % #ORDER) + 1
        table.insert(selected, ORDER[index])
    end

    return selected
end

function DailyQuests.definition(id)
    return DailyQuests.Definitions[id]
end

function DailyQuests.applyProgress(id, currentProgress, eventName, amount)
    local definition = DailyQuests.Definitions[id]
    if not definition or definition.Event ~= eventName then
        return currentProgress or 0, false
    end

    local before = math.max(0, tonumber(currentProgress) or 0)
    local after = math.min(definition.Target, before + math.max(0, tonumber(amount) or 0))
    return after, after >= definition.Target and before < definition.Target
end

return DailyQuests
