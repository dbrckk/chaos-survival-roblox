local RoundChallenge = {}

RoundChallenge.FirstRoundDefinition = {
    Id = "FIRST_SURVIVAL",
    Title = "SURVIVE YOUR FIRST CHAOS",
    Short = "STAY ALIVE",
    Metric = "survive",
    Target = 1,
    Coins = 8,
    XP = 8,
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

-- A real platform-based challenge on every third experienced round.
-- One objective per distinct arena; all reuse the existing single HUD
-- challenge and the existing once-per-round Coins/XP payout.
RoundChallenge.HighGround = {
    Classic = {
        Id = "CLASSIC_RIDGE", Title = "RADAR RIDGE", Short = "RIDGE",
        Metric = "highGround", Target = 3, Coins = 8, XP = 9,
    },
    Towers = {
        Id = "TOWER_SUMMIT", Title = "TOWER SUMMIT", Short = "SUMMIT",
        Metric = "highGround", Target = 3, Coins = 8, XP = 9,
    },
    Crossroads = {
        Id = "CROSSROADS_HIGH", Title = "CROSSROADS OVERPASS",
        Short = "OVERPASS", Metric = "highGround", Target = 3,
        Coins = 8, XP = 9,
    },
    Orbital = {
        Id = "ORBITAL_HIGH", Title = "REACTOR LOOKOUT",
        Short = "REACTOR", Metric = "highGround", Target = 3,
        Coins = 8, XP = 9,
    },
    Harbor = {
        Id = "HARBOR_HIGH", Title = "STORM GANTRY LOOKOUT",
        Short = "GANTRY", Metric = "highGround", Target = 3,
        Coins = 8, XP = 9,
    },
}

function RoundChallenge.forRound(roundNumber)
    local count = #RoundChallenge.Definitions
    local index = ((math.max(1, math.floor(tonumber(roundNumber) or 1)) - 1) % count) + 1
    return RoundChallenge.Definitions[index]
end

-- Keep the entire protected three-round learning window focused on the
-- central survival objective. A new player joining a veteran server must not
-- inherit a shard/momentum challenge before learning the basic controls.
function RoundChallenge.forContext(roundNumber, firstRound, arenaId, activeDisasters)
    if firstRound == true then
        return RoundChallenge.FirstRoundDefinition
    end
    local sequence = math.floor(tonumber(roundNumber) or 1)
    local routeMission = RoundChallenge.HighGround[tostring(arenaId)]
    if routeMission and sequence > 0 and sequence % 3 == 0 then
        -- No unobtainable platform challenges while the arena floor
        -- is disappearing or shrinking. A dangerous but fully stable
        -- ordinary round may still offer a fair skill objective.
        local blocked = false
        for _, disaster in ipairs(activeDisasters or {}) do
            local id = type(disaster) == "table" and disaster.Id or disaster
            if id == "DisappearingPlatforms" or id == "ShrinkingArena"
                or id == "RisingLava" then
                blocked = true
                break
            end
        end
        if not blocked then return routeMission end
    end
    return RoundChallenge.forRound(roundNumber)
end

function RoundChallenge.progress(definition, shards, pads, nearMisses, momentumBest, flowCoins, survived, highGround)
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
    elseif definition.Metric == "highGround" then
        value = math.max(0, tonumber(highGround) or 0)
    elseif definition.Metric == "survive" then
        value = survived == true and 1 or 0
    elseif definition.Metric == "variety" then
        value = 0
        if (tonumber(shards) or 0) > 0 then value += 1 end
        if (tonumber(pads) or 0) > 0 then value += 1 end
        if (tonumber(nearMisses) or 0) > 0 then value += 1 end
        if (tonumber(momentumBest) or 0) >= 2 then value += 1 end
    end

    return math.clamp(math.floor(tonumber(value) or 0), 0, definition.Target)
end

function RoundChallenge.completed(definition, shards, pads, nearMisses, momentumBest, flowCoins, survived, highGround)
    return RoundChallenge.progress(
        definition,
        shards,
        pads,
        nearMisses,
        momentumBest,
        flowCoins,
        survived,
        highGround
    ) >= (definition and definition.Target or math.huge)
end

return RoundChallenge
