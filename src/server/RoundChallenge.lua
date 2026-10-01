local RoundChallenge = {}

RoundChallenge.Definitions = {
    {
        Id = "SHARD_HUNT",
        Title = "SHARD HUNT",
        Short = "SHARDS",
        Metric = "shards",
        Target = 2,
        Coins = 6,
        XP = 6,
    },
    {
        Id = "MOBILITY_MASTER",
        Title = "MOBILITY MASTER",
        Short = "PADS",
        Metric = "pads",
        Target = 2,
        Coins = 6,
        XP = 6,
    },
    {
        Id = "DANGER_DANCE",
        Title = "DANGER DANCE",
        Short = "CLOSE CALL",
        Metric = "nearMisses",
        Target = 1,
        Coins = 7,
        XP = 7,
    },
}

function RoundChallenge.forRound(roundNumber)
    local count = #RoundChallenge.Definitions
    local index = ((math.max(1, math.floor(tonumber(roundNumber) or 1)) - 1) % count) + 1
    return RoundChallenge.Definitions[index]
end

function RoundChallenge.progress(definition, shards, pads, nearMisses)
    if not definition then
        return 0
    end

    local value = 0
    if definition.Metric == "shards" then
        value = shards
    elseif definition.Metric == "pads" then
        value = pads
    elseif definition.Metric == "nearMisses" then
        value = nearMisses
    end

    return math.clamp(math.floor(tonumber(value) or 0), 0, definition.Target)
end

function RoundChallenge.completed(definition, shards, pads, nearMisses)
    return RoundChallenge.progress(definition, shards, pads, nearMisses) >= (definition and definition.Target or math.huge)
end

return RoundChallenge
