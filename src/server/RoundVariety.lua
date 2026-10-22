local RoundVariety = {}

function RoundVariety.excludeImmediateRepeat(pool, lastPrimaryId, minimumChoices)
    local required = math.max(1, tonumber(minimumChoices) or 3)

    if not lastPrimaryId or #pool <= required then
        return table.clone(pool)
    end

    local filtered = {}
    for _, disaster in ipairs(pool) do
        if disaster.Id ~= lastPrimaryId then
            table.insert(filtered, disaster)
        end
    end

    if #filtered < required then
        return table.clone(pool)
    end

    return filtered
end

function RoundVariety.excludeRecent(pool, recentIds, minimumChoices)
    local required = math.max(1, tonumber(minimumChoices) or 3)
    if #pool <= required or type(recentIds) ~= "table" or #recentIds == 0 then
        return table.clone(pool)
    end

    local excluded = {}
    for _, id in ipairs(recentIds) do
        if type(id) == "string" and id ~= "" then
            excluded[id] = true
        end
    end

    local filtered = {}
    for _, disaster in ipairs(pool) do
        if not excluded[disaster.Id] then
            table.insert(filtered, disaster)
        end
    end

    if #filtered >= required then
        return filtered
    end

    -- Relax oldest exclusions first until the vote can still offer enough choices.
    for index = 1, #recentIds do
        excluded[recentIds[index]] = nil
        filtered = {}
        for _, disaster in ipairs(pool) do
            if not excluded[disaster.Id] then
                table.insert(filtered, disaster)
            end
        end
        if #filtered >= required then
            return filtered
        end
    end

    return table.clone(pool)
end

function RoundVariety.pushRecent(recentIds, id, maximumHistory)
    local result = {}
    local maximum = math.max(1, tonumber(maximumHistory) or 2)

    if type(recentIds) == "table" then
        for _, existing in ipairs(recentIds) do
            if existing ~= id then
                table.insert(result, existing)
            end
        end
    end

    if type(id) == "string" and id ~= "" then
        table.insert(result, id)
    end

    while #result > maximum do
        table.remove(result, 1)
    end

    return result
end

-- Double Chaos used to choose its second catastrophe uniformly, which could
-- recreate the same fusion in successive matches despite 11 available kits.
-- Prefer an unseen *unordered pair*; retain the full compatible pool if all
-- choices are recent so this can never prevent a scheduled Double Chaos.
function RoundVariety.fusionKey(firstId, secondId)
    if type(firstId) ~= "string" or firstId == ""
        or type(secondId) ~= "string" or secondId == ""
        or firstId == secondId then
        return nil
    end
    if firstId < secondId then
        return firstId .. "+" .. secondId
    end
    return secondId .. "+" .. firstId
end

function RoundVariety.freshFusionCandidates(primaryId, compatible, recentPairs)
    if type(compatible) ~= "table" then return {} end
    local recent = {}
    if type(recentPairs) == "table" then
        for _, key in ipairs(recentPairs) do
            if type(key) == "string" then recent[key] = true end
        end
    end
    local fresh = {}
    for _, candidate in ipairs(compatible) do
        if type(candidate) == "table" then
            local key = RoundVariety.fusionKey(primaryId, candidate.Id)
            if key and not recent[key] then
                table.insert(fresh, candidate)
            end
        end
    end
    if #fresh > 0 then return fresh end
    return table.clone(compatible)
end

return RoundVariety
