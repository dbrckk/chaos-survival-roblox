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

function AISurvivorRules.roundTraits(profile, slot, roundNumber)
    local base = profile or {}
    local safeSlot = math.max(1, math.floor(tonumber(slot) or 1))
    local safeRound = math.max(1, math.floor(tonumber(roundNumber) or 1))

    local function wave(multiplier, offset)
        local value = ((safeSlot * multiplier + safeRound * (multiplier + 6) + offset) % 101) / 100
        return (value - 0.5) * 2
    end

    local risk = math.clamp((tonumber(base.Risk) or 0.5) + wave(17, 11) * 0.10, 0.12, 0.88)
    local social = math.clamp((tonumber(base.SocialChance) or 0.2) + wave(23, 7) * 0.09, 0.06, 0.46)
    local mistake = math.clamp((tonumber(base.MistakeChance) or 0.12) + wave(31, 3) * 0.055, 0.035, 0.27)
    local padChance = math.clamp((tonumber(base.PadChance) or 0.2) + wave(13, 19) * 0.07, 0.07, 0.52)

    return {
        Risk = risk,
        SocialChance = social,
        MistakeChance = mistake,
        PadChance = padChance,
        HesitationChance = math.clamp(0.035 + mistake * 0.55, 0.05, 0.18),
        ReconsiderChance = math.clamp(0.03 + social * 0.16 + risk * 0.05, 0.05, 0.13),
        FollowThrough = math.clamp(0.88 + (1 - mistake) * 0.24, 0.92, 1.12),
        DirectionBias = wave(29, 5),
    }
end

function AISurvivorRules.voteIndex(slot, optionCount, roundNumber)
    local count = math.max(1, math.floor(tonumber(optionCount) or 1))
    local safeSlot = math.max(1, math.floor(tonumber(slot) or 1))
    local safeRound = math.max(1, math.floor(tonumber(roundNumber) or 1))
    return ((safeSlot * 2 + safeRound - 2) % count) + 1
end

function AISurvivorRules.appearanceStyle(identityIndex)
    local index = math.max(1, math.floor(tonumber(identityIndex) or 1))
    return ((index - 1) % 5) + 1
end

function AISurvivorRules.bodyScales(identityIndex)
    local index = math.max(1, math.floor(tonumber(identityIndex) or 1))
    local body = 0.04 + ((index * 17) % 5) * 0.04
    local proportion = 0.08 + ((index * 13) % 5) * 0.05
    return math.clamp(body, 0.04, 0.20), math.clamp(proportion, 0.08, 0.28)
end

function AISurvivorRules.resultReaction(roll, risk)
    local value = math.clamp(tonumber(roll) or 0, 0, 0.999)
    local r = math.clamp(tonumber(risk) or 0.5, 0, 1)

    local jumpCutoff = 0.24 + r * 0.16
    local sidestepCutoff = jumpCutoff + 0.27
    local acknowledgeCutoff = sidestepCutoff + 0.23

    if value < jumpCutoff then
        return "jump"
    elseif value < sidestepCutoff then
        return "sidestep"
    elseif value < acknowledgeCutoff then
        return "acknowledge"
    end
    return "still"
end

function AISurvivorRules.steeredDirection(previousDirection, desiredDirection, urgent)
    local desired = typeof(desiredDirection) == "Vector3" and desiredDirection or Vector3.zero
    desired = Vector3.new(desired.X, 0, desired.Z)
    if desired.Magnitude <= 0.001 then
        return Vector3.zero
    end
    desired = desired.Unit

    if urgent == true then
        return desired
    end

    local previous = typeof(previousDirection) == "Vector3" and previousDirection or Vector3.zero
    previous = Vector3.new(previous.X, 0, previous.Z)
    if previous.Magnitude <= 0.001 then
        return desired
    end
    previous = previous.Unit

    local dot = math.clamp(previous:Dot(desired), -1, 1)
    local blend = dot < -0.35 and 0.34
        or (dot < 0.35 and 0.46 or 0.62)
    local mixed = previous:Lerp(desired, blend)
    if mixed.Magnitude <= 0.001 then
        return desired
    end

    return mixed.Unit
end

function AISurvivorRules.turnPauseSeconds(previousDirection, desiredDirection, urgent, pressure)
    if urgent == true then
        return 0
    end

    local previous = typeof(previousDirection) == "Vector3" and previousDirection or Vector3.zero
    local desired = typeof(desiredDirection) == "Vector3" and desiredDirection or Vector3.zero
    previous = Vector3.new(previous.X, 0, previous.Z)
    desired = Vector3.new(desired.X, 0, desired.Z)
    if previous.Magnitude <= 0.001 or desired.Magnitude <= 0.001 then
        return 0
    end

    local dot = math.clamp(previous.Unit:Dot(desired.Unit), -1, 1)
    if dot > -0.15 then
        return 0
    end

    local p = math.clamp(tonumber(pressure) or 0, 0, 1)
    return math.clamp(0.12 + (-dot) * 0.10 - p * 0.08, 0.08, 0.22)
end

function AISurvivorRules.routeChoiceWidth(risk, candidateCount)
    local count = math.max(1, math.floor(tonumber(candidateCount) or 1))
    local value = math.clamp(tonumber(risk) or 0.5, 0, 1)

    if value >= 0.66 then
        return math.min(3, count)
    elseif value >= 0.36 then
        return math.min(2, count)
    end

    return 1
end

function AISurvivorRules.freeJumpChance(baseChance, pressure, lowGravity)
    local chance = math.clamp(tonumber(baseChance) or 0, 0, 1)
    local p = math.clamp(tonumber(pressure) or 0, 0, 1)

    chance *= 1 - p * 0.44
    if lowGravity == true then
        chance += 0.16 * (1 - p * 0.35)
    end

    return math.clamp(chance, 0.04, 0.42)
end

function AISurvivorRules.padChoiceWidth(risk, candidateCount)
    local count = math.max(1, math.floor(tonumber(candidateCount) or 1))
    local value = math.clamp(tonumber(risk) or 0.5, 0, 1)
    return value >= 0.68 and math.min(2, count) or 1
end

function AISurvivorRules.survivalPressure(health, maxHealth, finalRush, doubleChaos)
    local maximum = math.max(1, tonumber(maxHealth) or 100)
    local ratio = math.clamp((tonumber(health) or maximum) / maximum, 0, 1)

    local pressure = (1 - ratio) * 0.62
    if finalRush == true then
        pressure += 0.20
    end
    if doubleChaos == true then
        pressure += 0.10
    end

    return math.clamp(pressure, 0, 0.82)
end

function AISurvivorRules.pressuredTraits(traits, pressure)
    local source = traits or {}
    local p = math.clamp(tonumber(pressure) or 0, 0, 1)

    return {
        Risk = math.clamp((tonumber(source.Risk) or 0.5) * (1 - p * 0.36), 0.10, 0.88),
        SocialChance = math.clamp((tonumber(source.SocialChance) or 0.2) * (1 - p * 0.58), 0.02, 0.46),
        MistakeChance = math.clamp((tonumber(source.MistakeChance) or 0.12) * (1 - p * 0.18), 0.03, 0.27),
        PadChance = math.clamp((tonumber(source.PadChance) or 0.2) + p * 0.08, 0.07, 0.58),
        HesitationChance = math.clamp((tonumber(source.HesitationChance) or 0.08) * (1 - p * 0.32), 0.035, 0.18),
        ReconsiderChance = math.clamp((tonumber(source.ReconsiderChance) or 0.08) + p * 0.025, 0.05, 0.15),
        FollowThrough = math.clamp((tonumber(source.FollowThrough) or 1) - p * 0.05, 0.88, 1.12),
        DirectionBias = math.clamp(tonumber(source.DirectionBias) or 0, -1, 1),
    }
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
