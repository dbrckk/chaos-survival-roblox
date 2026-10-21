local FirstTimeExperience = {}

-- Games are persisted only while DataStore ownership is available. During a
-- temporary/no-save visit, count rounds entered in this server session so the
-- first-round tutorial and difficulty do not reset forever. Never write this
-- fallback back to player data or use it for purchase/unlock eligibility.
function FirstTimeExperience.effectiveGames(savedGames, sessionRoundsPlayed)
    local saved = math.max(0, math.floor(tonumber(savedGames) or 0))
    local played = math.max(0, math.floor(tonumber(sessionRoundsPlayed) or 0))
    return math.max(saved, played)
end

function FirstTimeExperience.isFirstRound(games)
    return math.max(0, math.floor(tonumber(games) or 0)) <= 1
end

function FirstTimeExperience.isRookie(games)
    return math.max(0, math.floor(tonumber(games) or 0)) <= 2
end

-- Games/SessionRoundsPlayed are incremented on round entry, not only when
-- a round finishes. Keep the third active round and its result in the guided
-- presentation, but return advanced lobby choices once it is over.
function FirstTimeExperience.isGuidedPhase(games, phase)
    local played = math.max(0, math.floor(tonumber(games) or 0))
    if played <= 2 then
        return true
    end
    return played == 3
        and (phase == "ready" or phase == "round" or phase == "result")
end

-- All visual voting surfaces must agree on an actionable ballot.
-- The authoritative server sends one to three distinct {id=...} entries.
-- Reject malformed payloads instead of constructing dead buttons.
function FirstTimeExperience.validVoteOptions(options)
    if type(options) ~= "table" or #options < 1 or #options > 3 then
        return false
    end
    local seen = {}
    for index = 1, #options do
        local option = options[index]
        if type(option) ~= "table"
            or type(option.id) ~= "string" or option.id == ""
            or seen[option.id] then
            return false
        end
        seen[option.id] = true
    end
    return true
end

function FirstTimeExperience.hasVoteOptions(state)
    return type(state) == "table"
        and FirstTimeExperience.validVoteOptions(state.voteOptions)
end

-- Cheap, deterministic UI invalidation key. A new server RoundState (usually
-- every countdown second) does not imply that vote cards changed. The key
-- covers every card field displayed by the client, local selection and the
-- compact Android layout. Length-prefix fields to avoid separator collisions.
function FirstTimeExperience.voteRenderKey(options, selected, compact)
    if not FirstTimeExperience.validVoteOptions(options) then
        return nil
    end

    local pieces = {compact == true and "compact" or "normal"}
    local function add(value)
        local text = tostring(value or "")
        pieces[#pieces + 1] = tostring(#text) .. ":" .. text
    end

    add(selected)
    for _, option in ipairs(options) do
        add(option.id)
        add(option.name or "CHAOS")
        add(option.hint)
        add(tonumber(option.votes) or 0)
    end
    return table.concat(pieces, "|")
end


-- The ready-phase RoundState carries the server-owned arena ID. Replicated
-- ArenaMetadata can still describe the previous map for a short time.
-- Never display strategy/mechanic hints from mismatched metadata.
function FirstTimeExperience.arenaGuideIdentity(state, replicatedId)
    if type(state) ~= "table" then
        return nil, false
    end
    if type(state.arenaId) == "string" and state.arenaId ~= "" then
        return state.arenaId, state.arenaId == replicatedId
    end
    if type(state.arenaName) == "string" and state.arenaName ~= "" then
        return state.arenaName, false
    end
    if type(replicatedId) == "string" and replicatedId ~= "" then
        return replicatedId, true
    end
    return nil, false
end

-- Identify only map-owned first-run cues. Their marker attributes may
-- replicate after the BasePart, so callers observe those attributes too.
function FirstTimeExperience.guideAnchorKind(part, generated)
    if typeof(part) ~= "Instance" or not part:IsA("BasePart")
        or typeof(generated) ~= "Instance" then
        return nil
    end
    local container = part.Parent
    local section = container and container.Parent
    if not section or section.Parent ~= generated then
        return nil
    end
    if section.Name == "Lobby" then
        if container.Name == "Activities" then
            return "practice"
        elseif container.Name == "Decor" and part.Name == "ArenaRunway" then
            return "runway"
        end
    elseif section.Name == "Arena" and container.Name == "Mechanics" then
        return "mobility"
    end
    return nil
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
        -- Empty or malformed voteOptions are not an actionable vote.
        -- Match the lobby's shared presentation predicate.
        if FirstTimeExperience.hasVoteOptions(state) then
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
