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
            return "TRY A GLOWING BOOST PAD  •  STEP ON IT TO LAUNCH"
        elseif games == 0 then
            return "BOOST LEARNED  •  THE ROUND STARTS SOON"
        end
        return nil
    elseif phase == "ready" then
        return firstRound
            and "GET POSITIONED  •  GLOWING PADS ARE FAST ESCAPE ROUTES"
            or "GET READY  •  WATCH THE DISASTER TELEGRAPH"
    elseif phase == "round" then
        if not firstRound then
            return nil
        end

        local seconds = math.max(0, math.floor(tonumber(state.seconds) or 0))
        if mechanicUses > 0 then
            return "NICE ESCAPE  •  SURVIVE UNTIL THE TIMER HITS 0"
        elseif shards > 0 then
            return "SHARD COLLECTED  •  BONUS COINS ARE OPTIONAL  •  STAY ALIVE"
        elseif seconds <= 7 then
            return "FINAL SECONDS  •  STAY ALIVE  •  DON'T GREED FOR SHARDS"
        end

        return "SURVIVE UNTIL 0  •  WARNING COLORS = DANGER  •  KEEP MOVING"
    end

    return nil
end

return FirstTimeExperience
