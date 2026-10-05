local FirstTimeExperience = {}

function FirstTimeExperience.isFirstRound(games)
    return math.max(0, math.floor(tonumber(games) or 0)) <= 1
end

function FirstTimeExperience.isRookie(games)
    return math.max(0, math.floor(tonumber(games) or 0)) <= 2
end

function FirstTimeExperience.allowDoubleChaos(gamesValues)
    if type(gamesValues) ~= "table" then
        return true
    end

    for _, games in ipairs(gamesValues) do
        if FirstTimeExperience.isFirstRound(games) then
            return false
        end
    end
    return true
end

function FirstTimeExperience.coachText(state, metrics)
    state = type(state) == "table" and state or {}
    metrics = type(metrics) == "table" and metrics or {}

    local games = math.max(0, math.floor(tonumber(metrics.games) or 0))
    if not FirstTimeExperience.isRookie(games) then
        return nil
    end

    local phase = tostring(state.phase or "")
    local firstRound = FirstTimeExperience.isFirstRound(games)
    local practiceUses = math.max(0, math.floor(tonumber(metrics.practiceUses) or 0))
    local mechanicUses = math.max(0, math.floor(tonumber(metrics.mechanicUses) or 0))
    local shards = math.max(0, math.floor(tonumber(metrics.shards) or 0))

    if phase == "waiting" or phase == "intermission" then
        if state.voteOptions then
            return firstRound
                and "VOTE  •  TAP THE CHAOS YOU WANT TO FACE"
                or "VOTE  •  PICK THE NEXT CHAOS"
        end

        if games == 0 and practiceUses <= 0 then
            return "HOW TO PLAY  •  SURVIVE UNTIL 0  •  MOVE + JUMP  •  SHARDS = BONUS"
        elseif games == 0 then
            return "ROUND GOAL  •  SURVIVE UNTIL 0  •  AVOID RED/ORANGE WARNINGS"
        end
        return nil
    elseif phase == "ready" then
        return firstRound
            and "ROUND GOAL  •  SURVIVE UNTIL 0  •  AVOID THE HAZARD  •  SHARDS = BONUS"
            or "GET READY  •  SURVIVE UNTIL 0  •  WATCH THE HAZARD WARNING"
    elseif phase == "round" then
        -- The round focus bar owns the live survival objective/timer.
        -- READY teaches the rules, shard/mechanic actions have dedicated
        -- feedback, so the coach stays out of active gameplay entirely.
        return nil
    end

    return nil
end

return FirstTimeExperience
