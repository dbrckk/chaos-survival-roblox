-- Crossroads Flux Relays: alternating timed return routes. The mechanic
-- derives its state from synchronized server time; no perpetual server loop.
local FluxRelayRules = {}

FluxRelayRules.Period = 8
FluxRelayRules.ChargeDuration = 3.2
FluxRelayRules.TouchCooldown = 3.5
FluxRelayRules.WeaveWindow = 12
FluxRelayRules.WeaveCap = 3
FluxRelayRules.Offsets = {
    Vector3.new(34, 0, 0),
    Vector3.new(0, 0, 34),
    Vector3.new(-34, 0, 0),
    Vector3.new(0, 0, -34),
}

-- Alternate between perpendicular charged lane pairs to earn Flux Weave.
-- A -> B -> A can score rank 3 only if all three physical gates differ.
-- Same lane pair, repeated gate and fully mastered runs cannot farm rank.
function FluxRelayRules.advanceWeave(previous, laneIndex, now)
    local lane = tonumber(laneIndex)
    local time = tonumber(now)
    if not lane or lane % 1 ~= 0 or lane < 1
        or lane > #FluxRelayRules.Offsets or not time or time ~= time
    then
        return nil, false
    end

    local group = lane % 2
    local old = type(previous) == "table" and previous or nil
    if old and type(old.at) == "number"
        and time >= old.at and time - old.at <= FluxRelayRules.WeaveWindow
    then
        local visited = type(old.visited) == "table"
            and old.visited or {[old.lane] = true}
        if old.group == group or visited[lane]
            or (tonumber(old.tier) or 1) >= FluxRelayRules.WeaveCap
        then
            return old, false
        end
        local nextVisited = table.clone(visited)
        nextVisited[lane] = true
        return {
            tier = (tonumber(old.tier) or 1) + 1,
            lane = lane, group = group, at = time,
            visited = nextVisited,
        }, true
    end
    return {
        tier = 1, lane = lane, group = group, at = time,
        visited = {[lane] = true},
    }, true
end

-- Client navigation uses a server-replicated target parity, not
-- a client-submitted score. -1 means no outstanding pair is required.
function FluxRelayRules.nextParity(progress)
    if type(progress) ~= "table"
        or (tonumber(progress.tier) or 0) < 1
        or (tonumber(progress.tier) or 0) >= FluxRelayRules.WeaveCap
    then
        return -1
    end
    local group = tonumber(progress.group)
    if group ~= 0 and group ~= 1 then return -1 end
    return 1 - group
end

function FluxRelayRules.offsetFor(index)
    -- Opposite lanes charge together. Adjacent lanes alternate.
    return (index == 2 or index == 4) and FluxRelayRules.Period * 0.5 or 0
end

function FluxRelayRules.progress(serverTime, epoch, offset)
    local time = tonumber(serverTime) or 0
    local origin = tonumber(epoch) or 0
    local shift = tonumber(offset) or 0
    return ((time - origin + shift) % FluxRelayRules.Period)
        / FluxRelayRules.Period
end

function FluxRelayRules.charged(serverTime, epoch, offset)
    return FluxRelayRules.progress(serverTime, epoch, offset)
        < FluxRelayRules.ChargeDuration / FluxRelayRules.Period
end

function FluxRelayRules.canTrigger(active, contestant, health, serverTime, epoch, offset, now, readyAt)
    return active == true
        and contestant == true
        and (tonumber(health) or 0) > 0
        and FluxRelayRules.charged(serverTime, epoch, offset)
        and (tonumber(now) or 0) >= (tonumber(readyAt) or 0)
end

-- NPC planning: only chase a charged gate when the expected arrival
-- still falls inside that gate's actual active window. Never steer all
-- agents to an inactive landmark just because it is visually prominent.
function FluxRelayRules.viableRoute(serverTime, epoch, offset, distance, walkSpeed)
    if tonumber(epoch) == nil or tonumber(offset) == nil then
        return false
    end
    local travel = math.max(0, tonumber(distance) or math.huge)
    local speed = math.max(1, tonumber(walkSpeed) or 16)
    if travel > 24 then return false end
    local eta = travel / speed + 0.18
    local at = tonumber(serverTime)
    if not at or not FluxRelayRules.charged(at, epoch, offset) then
        return false
    end
    local chargedPhaseSeconds = FluxRelayRules.progress(at, epoch, offset)
        * FluxRelayRules.Period
    return chargedPhaseSeconds + eta <= FluxRelayRules.ChargeDuration - 0.12
end

function FluxRelayRules.nextAllowed(now)
    return (tonumber(now) or 0) + FluxRelayRules.TouchCooldown
end

function FluxRelayRules.velocity(current, gatePosition, center, overdrive)
    local previous = typeof(current) == "Vector3" and current or Vector3.zero
    local gate = typeof(gatePosition) == "Vector3" and gatePosition or Vector3.zero
    local hub = typeof(center) == "Vector3" and center or Vector3.zero
    local toward = Vector3.new(hub.X - gate.X, 0, hub.Z - gate.Z)
    if toward.Magnitude <= 0.01 then
        return previous
    end
    local direction = toward.Unit
    local carry = Vector3.new(previous.X, 0, previous.Z)
    if carry.Magnitude > 40 then
        carry = carry.Unit * 40
    end
    -- Never allow extreme pre-existing knockback to overpower the inward
    -- relay direction; even stacked Speed Surge/Dash must return to the hub.
    local horizontal = carry * 0.15
        + direction * (overdrive == true and 47 or 41)
    if horizontal.Magnitude > 54 then
        horizontal = horizontal.Unit * 54
    end
    return Vector3.new(horizontal.X, math.clamp(math.max(previous.Y, 5), -52, 58), horizontal.Z)
end

return FluxRelayRules
