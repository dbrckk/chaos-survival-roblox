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

return RoundVariety
