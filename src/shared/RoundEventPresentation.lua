local RoundEventPresentation = {}

function RoundEventPresentation.accent(disasterIds, accentResolver)
    local ids = type(disasterIds) == "table" and disasterIds or {}
    local resolve = type(accentResolver) == "function"
        and accentResolver
        or function()
            return Color3.fromRGB(72, 205, 255)
        end

    local first = resolve(ids[1])
    if #ids < 2 then
        return first
    end

    local second = resolve(ids[2])
    return first:Lerp(second, 0.50)
end

function RoundEventPresentation.roundTitle(state)
    state = type(state) == "table" and state or {}

    if state.doubleChaos == true and state.fusionName then
        return "SURVIVE THE FUSION!", tostring(state.fusionName) .. " • TWO HAZARDS ACTIVE"
    end

    local title = tostring(state.title or "CHAOS")
    title = title:gsub("^SOLO RUSH:%s*", "")
    title = title:gsub("^CHAOS FUSION:%s*", "")
    return "SURVIVE!", title
end

function RoundEventPresentation.countdownValue(state, previousPhase)
    state = type(state) == "table" and state or {}
    if tostring(state.phase or "") ~= "ready" then
        return nil
    end

    local seconds = math.floor(tonumber(state.seconds) or 0)
    if seconds < 1 or seconds > 3 then
        return nil
    end

    if previousPhase ~= "ready" or seconds <= 3 then
        return seconds
    end
    return nil
end

function RoundEventPresentation.cameraKick(previousPhase, state, lastFinalRush, lastOverdrive)
    state = type(state) == "table" and state or {}

    local phase = tostring(state.phase or "waiting")
    local finalRush = phase == "round" and state.finalRush == true
    local overdrive = phase == "round" and state.overdrive == true

    if phase == "round" and previousPhase ~= "round" then
        return state.doubleChaos == true and 1.0 or 0.82
    elseif finalRush and lastFinalRush ~= true then
        return 0.72
    elseif overdrive and lastOverdrive ~= true then
        return 0.50
    elseif phase == "ready" and previousPhase ~= "ready" and state.doubleChaos == true then
        return 0.38
    end

    return 0
end

-- Avoid resetting identical camera tweens for each countdown packet.
function RoundEventPresentation.cameraTargetChanged(previous, requested)
    local target = tonumber(requested)
    if not target then return false end
    local last = tonumber(previous)
    return not last or math.abs(target - last) >= 0.05
end

-- A delayed client-only pulse belongs to one precise transition and
-- one physical source. Reject callbacks after phase change, map replacement
-- or avatar respawn rather than drawing stale rings over results/next round.
function RoundEventPresentation.pulseStillCurrent(expectedEpoch, actualEpoch,
        source, currentSource)
    return type(expectedEpoch) == "number"
        and expectedEpoch == actualEpoch
        and typeof(source) == "Instance"
        and source.Parent ~= nil
        and source == currentSource
end

-- A delayed victory accent may only paint over its original avatar
-- during the same active/result round. A new READY or respawn invalidates
-- it even if the old avatar still exists in Workspace for a short time.
function RoundEventPresentation.celebrationStillCurrent(
        expectedEpoch, actualEpoch, source, currentSource,
        phase, expectedRound, observedRound)
    if phase ~= "result" and phase ~= "round" then
        return false
    end
    local expected = tonumber(expectedRound)
    local observed = tonumber(observedRound)
    if not expected or not observed or expected < 1 or observed < 1
        or expected ~= expected or observed ~= observed
        or math.abs(expected) == math.huge or math.abs(observed) == math.huge
        or expected ~= math.floor(expected) or observed ~= math.floor(observed)
        or expected ~= observed then
        return false
    end
    return RoundEventPresentation.pulseStillCurrent(
        expectedEpoch, actualEpoch, source, currentSource
    )
end

-- Escalation notifications belong only to living players mid-round.
-- Cancel them immediately at result/READY/lobby boundaries so they never
-- overlap the victory card or the next action prompt.
function RoundEventPresentation.shouldClearRoundToast(previousPhase, nextPhase, eliminated)
    return (previousPhase == "round" and nextPhase ~= "round")
        or (nextPhase == "round" and eliminated == true)
end

-- Server stages are mirrored in RoundState. Announce a change only once
-- after the client has already observed a valid stage this round. Never
-- synthesize a warning for a joining spectator or an invalid payload.
function RoundEventPresentation.gravityTideCue(previous, current)
    local stages = {
        Float = true,
        PullRising = true,
        Pull = true,
        FloatReturning = true,
    }
    if not stages[previous] or not stages[current] or previous == current then
        return nil
    end
    if current == "PullRising" or
        (previous == "Float" and current == "Pull") then
        return "GRAVITY_PULL_RISING"
    end
    if current == "FloatReturning" or
        (previous == "Pull" and current == "Float") then
        return "GRAVITY_FLOAT_RETURNING"
    end
    return nil
end

-- The UI observes authoritative stage transitions, not its own lava timer.
-- Joining halfway through a round must never fabricate a warning.
function RoundEventPresentation.lavaSurgeCue(previous, current)
    local valid = {
        Climb = true,
        SurgeSoon = true,
        Surge = true,
        FinalRise = true,
    }
    if not valid[previous] or not valid[current] or previous == current then
        return nil
    end
    if current == "SurgeSoon" then return "LAVA_SURGE_SOON" end
    if current == "Surge" then return "LAVA_SURGE_ACTIVE" end
    if current == "FinalRise" then return "LAVA_FINAL_RISE" end
    return nil
end

-- Avoid fabricated stage announcements on first packet, late join or
-- phase rollover. Only react to real consecutive server-confirmed stages.
function RoundEventPresentation.blackoutCue(previous, current)
    if previous == "Dark" and current == "PowerReturn" then
        return "BLACKOUT_POWER_RETURN"
    elseif previous == "PowerReturn" and current == "Dark" then
        return "BLACKOUT_LIGHTS_DIM"
    end
    return nil
end

function RoundEventPresentation.priority(kind)
    local priorities = {
        finalRush = 50,
        roundStart = 40,
        fusion = 35,
        overdrive = 30,
        impactWave = 25,
        collapseWave = 25,
        speedTempo = 25,
        gravityTide = 25,
        lavaSurge = 25,
        blackoutWindow = 25,
        readyCountdown = 20,
    }
    return priorities[kind] or 0
end

return RoundEventPresentation
