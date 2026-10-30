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
    -- Physical traversal is verified by the server's ParkourFlow sampler:
    -- no touch pickups or client-claimed jumps qualify for these medals.
    local parkour = math.clamp(
        math.floor(tonumber(stats.parkourBest) or 0), 0, 7
    )
    if parkour >= 3 then
        table.insert(medals, "PARKOUR ACE")
    end
    if parkour >= 6 then
        table.insert(medals, "RIDGE LEGEND")
    end
    if stats.criticalSurvival == true then
        table.insert(medals, "CLUTCH")
    end

    return medals
end

return RoundMedals
