local RoundMedals = {}

function RoundMedals.evaluate(stats)
    stats = stats or {}
    local medals = {}

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
    if stats.criticalSurvival == true then
        table.insert(medals, "CLUTCH")
    end

    return medals
end

return RoundMedals
