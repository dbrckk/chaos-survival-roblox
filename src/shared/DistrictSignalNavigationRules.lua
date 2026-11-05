--!strict
-- Pure, optimistic feasibility bound for an OPTIONAL, server-timed
-- district signal. The client must never present a lost 2-second signal
-- 120+ studs away as a live action to pursue. Does not grant rewards,
-- change authoritative deadlines or move a character.
local Rules = {}

-- Normal R15 sprint is ~16 studs/sec. Use a generous 28-stud/sec
-- optimistic ceiling for DASH and acceleration; suppress a cue ONLY
-- when even that favorable bound cannot beat the official server clock.
Rules.OptimisticStudsPerSecond = 28
Rules.SignalHoldSeconds = 0.32
Rules.TransitHoldSeconds = 0.55
Rules.InputMarginSeconds = 0.12

local function distance(value)
    return type(value) == "number"
        and value >= 0 and value < math.huge and value == value
end

-- The fast-travel branch is only legal when the actual enabled hub
-- prompt AND actual outer station were observed on the client. Server
-- validates the use independently, including floor/cooldown and safety.
function Rules.earliestArrivalSeconds(directStuds, toHub, afterTransit, transitHold)
    if not distance(directStuds) then return math.huge end
    local speed = Rules.OptimisticStudsPerSecond
    local best = directStuds / speed
        + Rules.SignalHoldSeconds + Rules.InputMarginSeconds

    if distance(toHub) and distance(afterTransit) then
        local hold = transitHold
        if type(hold) ~= "number" or hold ~= hold
            or hold < 0 or hold == math.huge then
            hold = Rules.TransitHoldSeconds
        end
        local throughHub = (toHub + afterTransit) / speed + hold
            + Rules.SignalHoldSeconds + Rules.InputMarginSeconds
        best = math.min(best, throughHub)
    end
    return best
end

function Rules.liveCueReachable(secondsLeft, directStuds,
        toHub, afterTransit, transitHold)
    if type(secondsLeft) ~= "number" or secondsLeft ~= secondsLeft
        or secondsLeft <= 0 or secondsLeft == math.huge then
        return false
    end
    -- Slight clock jitter must not flicker the cue on the last tenth.
    return Rules.earliestArrivalSeconds(
        directStuds, toHub, afterTransit, transitHold
    ) <= secondsLeft + 0.10
end

return Rules
