local AISurvivorRules = {}

AISurvivorRules.TargetVisibleParticipants = 4
AISurvivorRules.MaxBots = 3

AISurvivorRules.Profiles = {
    {
        Id = "Cautious",
        WalkSpeed = 15.2,
        ReactionSeconds = 0.20,
        Risk = 0.22,
        PadChance = 0.16,
        JumpChance = 0.14,
        TargetHoldMin = 1.4,
        TargetHoldMax = 2.8,
        MistakeChance = 0.08,
        SocialChance = 0.16,
    },
    {
        Id = "Balanced",
        WalkSpeed = 16.1,
        ReactionSeconds = 0.34,
        Risk = 0.48,
        PadChance = 0.28,
        JumpChance = 0.20,
        TargetHoldMin = 1.2,
        TargetHoldMax = 2.5,
        MistakeChance = 0.13,
        SocialChance = 0.24,
    },
    {
        Id = "Bold",
        WalkSpeed = 17.0,
        ReactionSeconds = 0.50,
        Risk = 0.74,
        PadChance = 0.40,
        JumpChance = 0.27,
        TargetHoldMin = 0.9,
        TargetHoldMax = 2.1,
        MistakeChance = 0.20,
        SocialChance = 0.31,
    },
}

function AISurvivorRules.desiredBotCount(realPlayerCount)
    local real = math.max(0, math.floor(tonumber(realPlayerCount) or 0))
    if real <= 0 then
        return 0
    end

    return math.clamp(
        AISurvivorRules.TargetVisibleParticipants - real,
        0,
        AISurvivorRules.MaxBots
    )
end

function AISurvivorRules.profileForSlot(slot)
    local count = #AISurvivorRules.Profiles
    local index = ((math.max(1, math.floor(tonumber(slot) or 1)) - 1) % count) + 1
    return AISurvivorRules.Profiles[index]
end

function AISurvivorRules.voteIndex(slot, optionCount, roundNumber)
    local count = math.max(1, math.floor(tonumber(optionCount) or 1))
    local safeSlot = math.max(1, math.floor(tonumber(slot) or 1))
    local safeRound = math.max(1, math.floor(tonumber(roundNumber) or 1))
    return ((safeSlot * 2 + safeRound - 2) % count) + 1
end

function AISurvivorRules.platformAvailable(canCollide, transparency, collapsePhase)
    if canCollide ~= true then
        return false
    end

    if (tonumber(transparency) or 0) >= 0.90 then
        return false
    end

    return collapsePhase ~= "Warning" and collapsePhase ~= "Gone"
end

function AISurvivorRules.reactionReady(firstSeenAt, now, reactionSeconds)
    local seen = tonumber(firstSeenAt)
    local current = tonumber(now)
    if not seen or not current or current < seen then
        return false
    end

    local elapsed = current - seen
    local required = math.max(0, tonumber(reactionSeconds) or 0)
    return elapsed + 1e-6 >= required
end

return AISurvivorRules
