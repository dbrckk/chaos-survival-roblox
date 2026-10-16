-- Classic Grid: four-station skill circuit, individually tracked per
-- contestant. The circuit is optional; never changes survival or rewards.
local GridCircuitRules = {}

GridCircuitRules.Window = 20
GridCircuitRules.TouchCooldown = 0.65
GridCircuitRules.Count = 4
GridCircuitRules.Offsets = {
    Vector3.new(-16, 0, -16),
    Vector3.new(16, 0, -16),
    Vector3.new(16, 0, 16),
    Vector3.new(-16, 0, 16),
}
GridCircuitRules.Names = {"NW", "NE", "SE", "SW"}
GridCircuitRules.RouteChevronsPerEdge = {
    High = 3,
    Medium = 2,
    Low = 0,
}

function GridCircuitRules.previous(index)
    local n = tonumber(index)
    if not n or n % 1 ~= 0 or n < 1 or n > GridCircuitRules.Count then
        return nil
    end
    return ((n + GridCircuitRules.Count - 2) % GridCircuitRules.Count) + 1
end

function GridCircuitRules.routeChevrons(tier)
    return GridCircuitRules.RouteChevronsPerEdge[tier] or 0
end

function GridCircuitRules.next(index)
    local n = tonumber(index)
    if not n or n % 1 ~= 0 or n < 1 or n > GridCircuitRules.Count then
        return nil
    end
    return (n % GridCircuitRules.Count) + 1
end

-- Returns independent immutable updates for every progress event.
-- Any of the four nodes can start the run; the next three must be visited
-- clockwise, with one unbroken 20-second deadline from the first touch.
function GridCircuitRules.advance(previous, nodeIndex, serverTime)
    local node = tonumber(nodeIndex)
    local at = tonumber(serverTime)
    if not node or node % 1 ~= 0 or node < 1 or node > 4 or not at then
        return nil, false
    end

    local old = type(previous) == "table" and previous or nil
    if old and old.completed == true then return old, false end

    if not old or (tonumber(old.expiresAt) or 0) < at then
        return {
            step = 1,
            nextNode = GridCircuitRules.next(node),
            expiresAt = at + GridCircuitRules.Window,
            completed = false,
        }, true
    end

    if old.nextNode ~= node then
        return old, false
    end

    local step = math.clamp((tonumber(old.step) or 0) + 1, 1, 4)
    return {
        step = step,
        nextNode = step == 4 and 0 or GridCircuitRules.next(node),
        expiresAt = old.expiresAt,
        completed = step == 4,
    }, true
end

function GridCircuitRules.eligible(active, contestant, health, distance, vertical, now, readyAt)
    return active == true and contestant == true
        and (tonumber(health) or 0) > 0
        and (tonumber(distance) or math.huge) <= 7.5
        and math.abs(tonumber(vertical) or math.huge) <= 6
        and (tonumber(now) or 0) >= (tonumber(readyAt) or 0)
end

return GridCircuitRules
