local EliminationCauseRules = {}

local DEFAULT_RECENT_WINDOW = 2.25

function EliminationCauseRules.recentHazardKind(recent, now, window)
    if type(recent) ~= "table" then
        return nil
    end

    local kind = recent.kind
    local at = tonumber(recent.at)
    local current = tonumber(now)
    local maxAge = math.max(0, tonumber(window) or DEFAULT_RECENT_WINDOW)

    if type(kind) ~= "string" or kind == "" or not at or not current then
        return nil
    end

    local age = current - at
    if age < 0 or age > maxAge then
        return nil
    end

    return kind
end

function EliminationCauseRules.fallbackFallCause(activeHazards)
    local active = type(activeHazards) == "table" and activeHazards or {}

    -- Tornado and JumpShock are intentionally excluded here. Both hazards
    -- publish OnHazardContact when they actually knock a contestant, so they
    -- must only receive credit through the short recent-contact window.
    if active.LowGravity then
        return "LowGravity"
    elseif active.DisappearingPlatforms then
        return "DisappearingPlatforms"
    elseif active.ShrinkingArena then
        return "ShrinkingArena"
    end

    return "Fall"
end

return EliminationCauseRules
