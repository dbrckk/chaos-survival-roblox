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
        return "CHAOS FUSION", tostring(state.fusionName)
    end

    local title = tostring(state.title or "CHAOS LIVE")
    title = title:gsub("^SOLO RUSH:%s*", "")
    title = title:gsub("^CHAOS FUSION:%s*", "")
    return "CHAOS LIVE", title
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

function RoundEventPresentation.priority(kind)
    local priorities = {
        finalRush = 50,
        roundStart = 40,
        fusion = 35,
        overdrive = 30,
        readyCountdown = 20,
    }
    return priorities[kind] or 0
end

return RoundEventPresentation
