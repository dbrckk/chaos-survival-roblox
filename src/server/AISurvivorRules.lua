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

function AISurvivorRules.padInterest(baseChance, variantId, lowOnMap, risingLava)
    local chance = math.clamp(tonumber(baseChance) or 0, 0, 1)

    if variantId == "Towers" and lowOnMap == true then
        chance += 0.24
    elseif variantId == "Orbital" then
        chance += 0.10
    elseif variantId == "Crossroads" then
        chance += 0.08
    end

    if risingLava == true then
        chance += 0.24
    end

    return math.clamp(chance, 0, 0.72)
end

function AISurvivorRules.reachableElevation(currentY, targetY, variantId)
    local rise = (tonumber(targetY) or 0) - (tonumber(currentY) or 0)
    if rise <= 0 then
        return true
    end

    local limit = variantId == "Towers" and 8.5 or 7.5
    return rise <= limit
end

function AISurvivorRules.routeContinuity(variantId, currentPosition, targetPosition, center, directionBias)
    if typeof(currentPosition) ~= "Vector3"
        or typeof(targetPosition) ~= "Vector3"
        or typeof(center) ~= "Vector3"
    then
        return 0
    end

    local currentOffset = Vector3.new(
        currentPosition.X - center.X,
        0,
        currentPosition.Z - center.Z
    )
    local targetOffset = Vector3.new(
        targetPosition.X - center.X,
        0,
        targetPosition.Z - center.Z
    )
    local travel = Vector3.new(
        targetPosition.X - currentPosition.X,
        0,
        targetPosition.Z - currentPosition.Z
    )

    if variantId == "Orbital" and currentOffset.Magnitude > 4 and travel.Magnitude > 0.5 then
        local tangent = Vector3.new(-currentOffset.Z, 0, currentOffset.X).Unit
        if (tonumber(directionBias) or 0) < 0 then
            tangent = -tangent
        end
        return tangent:Dot(travel.Unit) * 6
    elseif variantId == "Towers" then
        local sameX = currentOffset.X == 0
            or targetOffset.X == 0
            or math.sign(currentOffset.X) == math.sign(targetOffset.X)
        local sameZ = currentOffset.Z == 0
            or targetOffset.Z == 0
            or math.sign(currentOffset.Z) == math.sign(targetOffset.Z)
        return (sameX and sameZ) and 3 or -2
    elseif variantId == "Crossroads" then
        local currentOnX = math.abs(currentOffset.Z) <= 9
        local targetOnX = math.abs(targetOffset.Z) <= 9
        local currentOnZ = math.abs(currentOffset.X) <= 9
        local targetOnZ = math.abs(targetOffset.X) <= 9
        return ((currentOnX and targetOnX) or (currentOnZ and targetOnZ)) and 3 or -1
    end

    return 0
end

function AISurvivorRules.routeAffinity(variantId, position, center)
    if typeof(position) ~= "Vector3" or typeof(center) ~= "Vector3" then
        return 0
    end

    local offset = Vector3.new(position.X - center.X, 0, position.Z - center.Z)
    local radius = offset.Magnitude

    if variantId == "Orbital" then
        local ringError = math.abs(radius - 29)
        return 8 - math.min(12, ringError * 0.45)
    elseif variantId == "Crossroads" then
        local laneDistance = math.min(math.abs(offset.X), math.abs(offset.Z))
        return 7 - math.min(11, laneDistance * 0.55)
    elseif variantId == "Towers" then
        local cornerDistance = math.abs(math.abs(offset.X) - math.abs(offset.Z))
        return 4 - math.min(7, cornerDistance * 0.18)
    end

    local preferredRadius = 24
    return 4 - math.min(7, math.abs(radius - preferredRadius) * 0.20)
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
