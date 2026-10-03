local RoundChallenge = {}

RoundChallenge.FirstRoundDefinition = {
    Id = "FIRST_ESCAPE",
    Title = "TRY THE ESCAPE PAD",
    Short = "USE A PAD",
    Metric = "pads",
    Target = 1,
    Coins = 6,
    XP = 6,
}

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
    {
        Id = "MOMENTUM_3",
        Title = "KEEP THE FLOW",
        Short = "MOMENTUM",
        Metric = "momentum",
        Target = 3,
        Coins = 7,
        XP = 7,
    },
    {
        Id = "FLOW_CHAIN",
        Title = "FLOW CHAIN",
        Short = "FLOW",
        Metric = "flow",
        Target = 1,
        Coins = 8,
        XP = 8,
    },
    {
        Id = "MIX_IT_UP",
        Title = "MIX IT UP",
        Short = "VARIETY",
        Metric = "variety",
        Target = 2,
        Coins = 7,
        XP = 7,
    },
}

function RoundChallenge.forRound(roundNumber)
    local count = #RoundChallenge.Definitions
    local index = ((math.max(1, math.floor(tonumber(roundNumber) or 1)) - 1) % count) + 1
    return RoundChallenge.Definitions[index]
end

function RoundChallenge.forContext(roundNumber, firstRound)
    if firstRound == true then
        return RoundChallenge.FirstRoundDefinition
    end
    return RoundChallenge.forRound(roundNumber)
end

function RoundChallenge.progress(definition, shards, pads, nearMisses, momentumBest, flowCoins)
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
    elseif definition.Metric == "momentum" then
        value = momentumBest
    elseif definition.Metric == "flow" then
        value = (tonumber(flowCoins) or 0) > 0 and 1 or 0
    elseif definition.Metric == "variety" then
        value = 0
        if (tonumber(shards) or 0) > 0 then value += 1 end
        if (tonumber(pads) or 0) > 0 then value += 1 end
        if (tonumber(nearMisses) or 0) > 0 then value += 1 end
        if (tonumber(momentumBest) or 0) >= 2 then value += 1 end
    end

    return math.clamp(math.floor(tonumber(value) or 0), 0, definition.Target)
end

function RoundChallenge.completed(definition, shards, pads, nearMisses, momentumBest, flowCoins)
    return RoundChallenge.progress(definition, shards, pads, nearMisses, momentumBest, flowCoins) >= (definition and definition.Target or math.huge)
end

return RoundChallenge
