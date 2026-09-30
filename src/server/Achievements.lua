local Achievements = {}

Achievements.Definitions = {
    FIRST_SURVIVOR = {
        Id = "FIRST_SURVIVOR",
        Title = "First Survivor",
        Description = "Survive your first round",
        Stat = "Wins",
        Target = 1,
        Coins = 50,
        XP = 30,
    },
    VETERAN_10 = {
        Id = "VETERAN_10",
        Title = "Getting Serious",
        Description = "Play 10 rounds",
        Stat = "Games",
        Target = 10,
        Coins = 75,
        XP = 40,
    },
    SURVIVOR_10 = {
        Id = "SURVIVOR_10",
        Title = "Hard To Kill",
        Description = "Survive 10 rounds",
        Stat = "Wins",
        Target = 10,
        Coins = 150,
        XP = 75,
    },
    CHAOS_TAMER = {
        Id = "CHAOS_TAMER",
        Title = "Chaos Tamer",
        Description = "Survive 3 Double Chaos rounds",
        Stat = "DoubleChaosSurvivals",
        Target = 3,
        Coins = 200,
        XP = 100,
    },
    LEVEL_5 = {
        Id = "LEVEL_5",
        Title = "Rising Star",
        Description = "Reach level 5",
        Stat = "Level",
        Target = 5,
        Coins = 125,
        XP = 75,
    },
    STREAK_7 = {
        Id = "STREAK_7",
        Title = "Seven Days Strong",
        Description = "Reach a 7-day login streak",
        Stat = "BestStreak",
        Target = 7,
        Coins = 175,
        XP = 100,
    },
}

Achievements.Order = {
    "FIRST_SURVIVOR",
    "VETERAN_10",
    "SURVIVOR_10",
    "CHAOS_TAMER",
    "LEVEL_5",
    "STREAK_7",
}

function Achievements.get(id)
    return Achievements.Definitions[id]
end

function Achievements.deserialize(raw)
    local set = {}
    if type(raw) ~= "string" or raw == "" then
        return set
    end

    for id in string.gmatch(raw, "[^,]+") do
        if Achievements.Definitions[id] then
            set[id] = true
        end
    end

    return set
end

function Achievements.serialize(set)
    local ids = {}
    for _, id in ipairs(Achievements.Order) do
        if set[id] then
            table.insert(ids, id)
        end
    end
    return table.concat(ids, ",")
end

function Achievements.evaluate(stats, rawUnlocked)
    local unlocked = Achievements.deserialize(rawUnlocked)
    local newlyUnlocked = {}

    for _, id in ipairs(Achievements.Order) do
        local def = Achievements.Definitions[id]
        local current = tonumber(stats[def.Stat]) or 0

        if current >= def.Target and not unlocked[id] then
            unlocked[id] = true
            table.insert(newlyUnlocked, id)
        end
    end

    return Achievements.serialize(unlocked), newlyUnlocked
end

function Achievements.publicState(stats, rawUnlocked)
    local owned = Achievements.deserialize(rawUnlocked)
    local list = {}

    for _, id in ipairs(Achievements.Order) do
        local def = Achievements.Definitions[id]
        local progress = math.min(def.Target, tonumber(stats[def.Stat]) or 0)

        table.insert(list, {
            id = def.Id,
            title = def.Title,
            description = def.Description,
            progress = progress,
            target = def.Target,
            unlocked = owned[id] == true,
            coins = def.Coins,
            xp = def.XP,
        })
    end

    return {
        achievements = list,
        unlocked = owned,
    }
end

return Achievements
