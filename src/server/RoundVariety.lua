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

return RoundVariety
