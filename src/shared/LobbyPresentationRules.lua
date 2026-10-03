local LobbyPresentationRules = {}

function LobbyPresentationRules.mode(phase, voteOptions)
    local value = tostring(phase or "waiting")
    if value == "intermission"
        and type(voteOptions) == "table"
        and #voteOptions > 0
    then
        return "vote"
    elseif value == "vote" then
        return "vote"
    elseif value == "ready" then
        return "launch"
    elseif value == "intermission" or value == "waiting" then
        return "social"
    end
    return "inactive"
end

function LobbyPresentationRules.emphasis(phase, voteOptions)
    local mode = LobbyPresentationRules.mode(phase, voteOptions)
    if mode == "vote" then
        return {
            Center = 1.00,
            Practice = 0.22,
            Runway = 0.36,
            Social = 0.48,
        }
    elseif mode == "launch" then
        return {
            Center = 0.62,
            Practice = 0.10,
            Runway = 1.00,
            Social = 0.28,
        }
    elseif mode == "social" then
        return {
            Center = 0.72,
            Practice = 0.90,
            Runway = 0.40,
            Social = 0.82,
        }
    end

    return {
        Center = 0.12,
        Practice = 0.05,
        Runway = 0.10,
        Social = 0.05,
    }
end

function LobbyPresentationRules.statusText(phase, seconds, title, voteOptions)
    local mode = LobbyPresentationRules.mode(phase, voteOptions)
    local remaining = math.max(0, math.floor(tonumber(seconds) or 0))

    if mode == "vote" then
        return "VOTE NOW", remaining > 0 and (tostring(remaining) .. "s") or "CHOOSE CHAOS"
    elseif mode == "launch" then
        local clean = tostring(title or "NEXT ROUND")
        clean = clean:gsub("^SOLO RUSH:%s*", "")
        clean = clean:gsub("^CHAOS FUSION:%s*", "")
        return "ENTERING ARENA", clean
    elseif mode == "social" then
        if tostring(phase or "") == "waiting" then
            return "LOBBY OPEN", "PRACTICE WHILE PLAYERS JOIN"
        end

        local clean = tostring(title or "NEXT ROUND")
        if clean == "" then
            clean = "NEXT ROUND"
        end
        return clean, "PRACTICE • MOVE • GET READY"
    end

    return "ROUND ACTIVE", "ARENA IN PROGRESS"
end

function LobbyPresentationRules.pulseCadence(tierName, reduceMotion, mode)
    if reduceMotion == true then
        return 0.90
    end

    local tier = tostring(tierName or "Medium")
    local state = tostring(mode or "social")

    if state == "launch" then
        return tier == "Low" and 0.58 or 0.42
    elseif state == "vote" then
        return tier == "Low" and 0.72 or 0.56
    end
    return tier == "Low" and 0.92 or 0.72
end

function LobbyPresentationRules.decorBudget(tierName)
    local tier = tostring(tierName or "Medium")
    if tier == "Low" then
        return 4
    elseif tier == "Medium" then
        return 7
    end
    return 10
end

return LobbyPresentationRules
