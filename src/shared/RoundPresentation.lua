local RoundPresentation = {}

local function cleanReadyTitle(value)
    local text = tostring(value or "CHAOS")
    text = string.gsub(text, "^READY:%s*", "")
    text = string.gsub(text, "^SOLO RUSH:%s*", "")
    return text
end

function RoundPresentation.readyCountdown(state)
    if type(state) ~= "table" or state.phase ~= "ready" then
        return nil
    end

    local seconds = math.floor(tonumber(state.seconds) or 0)
    if seconds >= 1 and seconds <= 3 then
        return seconds
    end
    return nil
end

function RoundPresentation.phaseCue(previousPhase, state)
    if type(state) ~= "table" then
        return nil
    end

    local phase = tostring(state.phase or "waiting")
    if phase == "ready" and previousPhase ~= "ready" then
        if state.doubleChaos == true and type(state.fusionName) == "string" then
            return {
                kind = "fusion",
                title = tostring(state.fusionName),
                subtitle = "CHAOS FUSION  •  TWO HAZARDS INCOMING",
            }
        end

        return {
            kind = "ready",
            title = "GET READY",
            subtitle = tostring(state.arenaName or "ARENA")
                .. "  •  "
                .. cleanReadyTitle(state.title),
        }
    end

    if phase == "round" and previousPhase ~= "round" then
        if state.doubleChaos == true and type(state.fusionName) == "string" then
            return {
                kind = "start",
                title = "SURVIVE!",
                subtitle = tostring(state.fusionName) .. "  •  TWO HAZARDS ACTIVE",
            }
        end

        return {
            kind = "start",
            title = "SURVIVE!",
            subtitle = cleanReadyTitle(state.title),
        }
    end

    return nil
end

function RoundPresentation.cameraKick(previousPhase, state, lastFinalRush, lastOverdrive)
    if type(state) ~= "table" then
        return 0
    end

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

return RoundPresentation
