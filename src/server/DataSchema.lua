local DataSchema = {}

DataSchema.Version = 7

DataSchema.Defaults = {
    DataVersion = DataSchema.Version,

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

    WeeklyChallengeWeek = -1,
    Weekly1Id = "",
    Weekly1Progress = 0,
    Weekly1Claimed = false,
    Weekly2Id = "",
    Weekly2Progress = 0,
    Weekly2Claimed = false,

    OwnedCosmetics = "",
    EquippedTrail = "",
    EquippedAura = "",

    DoubleChaosSurvivals = 0,
    UnlockedAchievements = "",

    ArenaMastery = "",
    DisasterMastery = "",

    ReduceMotion = false,
    AudioMuted = false,
    HapticsDisabled = false,
}

function DataSchema.cloneDefaults()
    local result = {}
    for key, value in pairs(DataSchema.Defaults) do
        result[key] = value
    end
    return result
end

function DataSchema.levelForXP(xp)
    local numericXP = math.max(0, tonumber(xp) or 0)
    return math.max(1, math.floor(math.sqrt(numericXP / 100)) + 1)
end

local function migrateLegacyEquipped(saved, data)
    if type(saved) ~= "table" then
        return
    end

    local legacy = saved.EquippedCosmetic
    if type(legacy) ~= "string" or legacy == "" then
        return
    end

    if string.sub(legacy, 1, 6) == "trail_" and data.EquippedTrail == "" then
        data.EquippedTrail = legacy
    elseif string.sub(legacy, 1, 5) == "aura_" and data.EquippedAura == "" then
        data.EquippedAura = legacy
    end
end

function DataSchema.normalize(saved)
    local data = DataSchema.cloneDefaults()

    if type(saved) == "table" then
        for key, defaultValue in pairs(DataSchema.Defaults) do
            local value = saved[key]
            if type(value) == type(defaultValue) then
                data[key] = value
            end
        end
        migrateLegacyEquipped(saved, data)
    end

    data.Coins = math.max(0, data.Coins)
    data.XP = math.max(0, data.XP)
    data.Wins = math.max(0, data.Wins)
    data.Games = math.max(0, data.Games)
    data.BestStreak = math.max(0, data.BestStreak)
    data.DailyStreak = math.max(0, data.DailyStreak)
    data.DoubleChaosSurvivals = math.max(0, data.DoubleChaosSurvivals)
    data.Level = DataSchema.levelForXP(data.XP)
    data.DataVersion = DataSchema.Version

    return data
end

function DataSchema.snapshot(getAttribute)
    local data = DataSchema.cloneDefaults()

    for key, defaultValue in pairs(DataSchema.Defaults) do
        local value = getAttribute(key)
        if value ~= nil and type(value) == type(defaultValue) then
            data[key] = value
        end
    end

    data = DataSchema.normalize(data)
    return data
end

function DataSchema.retryDelay(attempt)
    local n = math.max(1, tonumber(attempt) or 1)
    return math.min(8, 0.5 * (2 ^ (n - 1)))
end

return DataSchema
