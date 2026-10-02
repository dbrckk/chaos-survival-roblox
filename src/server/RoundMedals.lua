local RoundMedals = {}

function RoundMedals.evaluate(stats)
    stats = stats or {}
    local medals = {}

    if stats.firstRound == true then
        table.insert(medals, "FIRST CHAOS")
    end

    if (tonumber(stats.shards) or 0) >= 3 then
        table.insert(medals, "SHARD HUNTER")
    end
    if (tonumber(stats.pads) or 0) >= 3 then
        table.insert(medals, "MOBILITY ACE")
    end
    if (tonumber(stats.nearMisses) or 0) >= 3 then
        table.insert(medals, "DAREDEVIL")
    end
    if (tonumber(stats.overdriveUses) or 0) >= 1 then
        table.insert(medals, "OVERDRIVE RIDER")
    end
    if (tonumber(stats.momentumBest) or 0) >= 4 then
        table.insert(medals, "MOMENTUM MASTER")
    end
    if stats.criticalSurvival == true then
        table.insert(medals, "CLUTCH")
    end

    return medals
end

return RoundMedals
