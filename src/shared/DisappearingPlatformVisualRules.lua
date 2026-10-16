-- Pure ownership/visibility checks for client-only collapse contours.
-- Gameplay collapse phases and physical collision remain server-authoritative.
local Rules = {}

function Rules.ownsPart(part, platforms)
    return typeof(part) == "Instance" and part:IsA("BasePart")
        and typeof(platforms) == "Instance"
        and part.Parent == platforms
end

function Rules.shouldDisplay(part, platforms)
    if not Rules.ownsPart(part, platforms) then return false end
    local phase = part:GetAttribute("CollapsePhase")
    return phase == "Warning" or phase == "Gone"
end

return Rules
