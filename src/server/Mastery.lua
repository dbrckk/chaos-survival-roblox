local Mastery = {}

Mastery.Thresholds = {
    {Name = "ROOKIE", Points = 0},
    {Name = "BRONZE", Points = 3},
    {Name = "SILVER", Points = 9},
    {Name = "GOLD", Points = 18},
    {Name = "ELITE", Points = 36},
}

function Mastery.deserialize(raw)
    local result = {}
    if type(raw) ~= "string" or raw == "" then
        return result
    end

    for entry in string.gmatch(raw, "[^;]+") do
        local id, value = string.match(entry, "^([^=]+)=(%d+)$")
        if id and value then
            result[id] = math.max(0, math.floor(tonumber(value) or 0))
        end
    end
    return result
end

function Mastery.serialize(values)
    local keys = {}
    for id, value in pairs(values or {}) do
        if type(id) == "string" and id ~= "" and (tonumber(value) or 0) > 0 then
            table.insert(keys, id)
        end
    end
    table.sort(keys)

    local entries = {}
    for _, id in ipairs(keys) do
        table.insert(entries, id .. "=" .. tostring(math.max(0, math.floor(tonumber(values[id]) or 0))))
    end
    return table.concat(entries, ";")
end

function Mastery.add(raw, id, amount)
    if type(id) ~= "string" or id == "" then
        return raw or "", 0
    end

    local values = Mastery.deserialize(raw)
    local nextValue = math.max(0, (values[id] or 0) + math.max(0, math.floor(tonumber(amount) or 0)))
    values[id] = nextValue
    return Mastery.serialize(values), nextValue
end

function Mastery.points(raw, id)
    return Mastery.deserialize(raw)[id] or 0
end

function Mastery.state(points)
    local value = math.max(0, math.floor(tonumber(points) or 0))
    local current = Mastery.Thresholds[1]
    local nextTier = nil

    for index, tier in ipairs(Mastery.Thresholds) do
        if value >= tier.Points then
            current = tier
            nextTier = Mastery.Thresholds[index + 1]
        else
            nextTier = tier
            break
        end
    end

    return {
        points = value,
        tier = current.Name,
        nextTier = nextTier and nextTier.Name or nil,
        nextPoints = nextTier and nextTier.Points or nil,
        remaining = nextTier and math.max(0, nextTier.Points - value) or 0,
        maxed = nextTier == nil,
    }
end

function Mastery.roundGain(survived)
    return survived and 3 or 1
end

return Mastery
