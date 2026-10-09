-- Crossroads Flux Relays: alternating timed return routes. The mechanic
-- derives its state from synchronized server time; no perpetual server loop.
local FluxRelayRules = {}

FluxRelayRules.Period = 8
FluxRelayRules.ChargeDuration = 3.2
FluxRelayRules.TouchCooldown = 3.5
FluxRelayRules.Offsets = {
    Vector3.new(34, 0, 0),
    Vector3.new(0, 0, 34),
    Vector3.new(-34, 0, 0),
    Vector3.new(0, 0, -34),
}

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
    local horizontal = Vector3.new(previous.X, 0, previous.Z) * 0.15
        + direction * (overdrive == true and 47 or 41)
    if horizontal.Magnitude > 54 then
        horizontal = horizontal.Unit * 54
    end
    return Vector3.new(horizontal.X, math.clamp(math.max(previous.Y, 5), -52, 58), horizontal.Z)
end

return FluxRelayRules
