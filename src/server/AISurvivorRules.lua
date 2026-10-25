local AISurvivorRules = {}

-- Do not give an NPC the same visible identity as a real participant.
-- Stable cyclic fallback keeps the server's shuffled identities natural,
-- without querying or impersonating real Roblox accounts.
function AISurvivorRules.availableIdentityIndex(identities, preferredIndex, humans, reserved)
    if type(identities) ~= "table" or #identities == 0 then
        return nil
    end
    local occupied = {}
    local function mark(value)
        if type(value) == "string" and value ~= "" then
            occupied[value:lower()] = true
        end
    end
    for _, human in ipairs(type(humans) == "table" and humans or {}) do
        if type(human) == "table" then
            mark(human.Name)
            mark(human.DisplayName)
        elseif typeof(human) == "Instance" then
            -- Players:GetPlayers() returns Player Instances, not Lua tables.
            -- Read DisplayName defensively so non-Player instances supplied
            -- by callers cannot break identity selection.
            mark(human.Name)
            local ok, displayName = pcall(function()
                return human.DisplayName
            end)
            if ok then
                mark(displayName)
            end
        end
    end
    for _, identity in ipairs(type(reserved) == "table" and reserved or {}) do
        if type(identity) == "table" then
            mark(identity.Username)
            mark(identity.DisplayName)
        end
    end
    local start = math.max(1, math.floor(tonumber(preferredIndex) or 1))
    for offset = 0, #identities - 1 do
        local index = ((start - 1 + offset) % #identities) + 1
        local identity = identities[index]
        if type(identity) == "table"
            and type(identity.Username) == "string"
            and type(identity.DisplayName) == "string"
            and not occupied[identity.Username:lower()]
            and not occupied[identity.DisplayName:lower()] then
            return index
        end
    end
    return nil
end

AISurvivorRules.TargetVisibleParticipants = 4
AISurvivorRules.MaxBots = 3

AISurvivorRules.Profiles = {
    -- All three competitors move at normal player speed or slower. Skill
    -- comes from situational awareness and intentional decisions, not buffs.
    {
        Id = "Cautious",
        Role = "TACTICIAN",
        WalkSpeed = 15.8,
        ReactionSeconds = 0.17,
        Risk = 0.18,
        PadChance = 0.28,
        JumpChance = 0.13,
        TargetHoldMin = 0.95,
        TargetHoldMax = 1.85,
        MistakeChance = 0.035,
        SocialChance = 0.24,
        GestureChance = 0.68,
        FreezeJumpChance = 0.84,
    },
    {
        Id = "Balanced",
        Role = "TEAMMATE",
        WalkSpeed = 16.0,
        ReactionSeconds = 0.19,
        Risk = 0.43,
        PadChance = 0.44,
        JumpChance = 0.24,
        TargetHoldMin = 0.85,
        TargetHoldMax = 1.75,
        MistakeChance = 0.050,
        SocialChance = 0.39,
        GestureChance = 0.90,
        FreezeJumpChance = 0.76,
    },
    {
        Id = "Bold",
        Role = "DAREDEVIL",
        WalkSpeed = 16.0,
        ReactionSeconds = 0.20,
        Risk = 0.72,
        PadChance = 0.59,
        JumpChance = 0.32,
        TargetHoldMin = 0.75,
        TargetHoldMax = 1.50,
        MistakeChance = 0.075,
        SocialChance = 0.38,
        GestureChance = 0.84,
        FreezeJumpChance = 0.68,
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

-- A round roster is committed at the ready countdown. Late joiners do not
-- become active contestants, so do not add/remove AI during ready, round,
-- or the result celebration. Rebalance at the next intermission.
function AISurvivorRules.rosterLocked(phase)
    return phase == "ready" or phase == "round" or phase == "result"
end

-- The roster is locked after ready starts, but the exact transition into
-- ready is the last opportunity to fill missing bot slots. Ordinary
-- PlayerAdded / brain reconciliation never receives this boundary flag.
function AISurvivorRules.rosterReconciliationAllowed(phase, enteringReady)
    return not AISurvivorRules.rosterLocked(phase)
        or (phase == "ready" and enteringReady == true)
end

-- Only players who actually made it into the ready roster should count
-- against the solo AI population. Connected spectators / late arrivals are
-- not contestants, so they must not silently displace a competitor.
function AISurvivorRules.rosterHumanCount(phase, enteringReady, connectedCount, readyCount)
    if phase == "ready" and enteringReady == true then
        local eligible = tonumber(readyCount)
        if eligible and eligible == eligible and eligible >= 1
            and eligible < math.huge then
            return math.floor(eligible)
        end
    end
    local connected = tonumber(connectedCount)
    if not connected or connected ~= connected or connected == math.huge
        or connected == -math.huge then
        return 0
    end
    return math.max(0, math.floor(connected))
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
    local social = math.clamp((tonumber(base.SocialChance) or 0.2) + wave(23, 7) * 0.075, 0.06, 0.46)
    local mistake = math.clamp((tonumber(base.MistakeChance) or 0.12) + wave(31, 3) * 0.045, 0.035, 0.27)
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

-- Votes reveal each archetype's taste for risk while still respecting
-- the actual three disaster choices and deterministic round variation.
-- Balanced players rotate interests; tacticians avoid high-chaos choices;
-- daredevils seek the most spectacular options.
local VOTE_DANGER = {
    RisingLava = 5, Meteors = 7, Tornado = 8, Bombs = 8,
    ShrinkingArena = 8, DisappearingPlatforms = 7, Darkness = 5,
    Freeze = 5, JumpShock = 6, LowGravity = 3, SpeedSurge = 4,
}

function AISurvivorRules.personalityVoteIndex(profile, options, slot, roundNumber)
    local count = type(options) == "table" and #options or 0
    local default = AISurvivorRules.voteIndex(slot, math.max(1, count), roundNumber)
    if count == 0 then
        return default
    end

    local id = type(profile) == "table" and profile.Id or "Balanced"
    if id == "Balanced" then
        return default
    end

    local bestIndex = default
    local bestScore = -math.huge
    for index, option in ipairs(options) do
        local danger = type(option) == "table"
            and (VOTE_DANGER[option.Id] or 5) or 5
        local score = id == "Bold" and danger or (10 - danger)
        -- Stable deterministic tie breaking, different each round.
        score += (1 - math.abs(index - default) / math.max(1, count)) * 0.05
        if score > bestScore then
            bestScore = score
            bestIndex = index
        end
    end
    return bestIndex
end

function AISurvivorRules.personalityResultAction(profile, roll, risk)
    local kind = type(profile) == "table" and profile.Id or "Balanced"
    local value = math.clamp(tonumber(roll) or 0, 0, 0.999)
    if kind == "Cautious" and value < 0.65 then
        return "acknowledge"
    elseif kind == "Balanced" and value < 0.54 then
        return "acknowledge"
    elseif kind == "Bold" and value < 0.70 then
        return "jump"
    end
    return AISurvivorRules.resultReaction(value, risk)
end

function AISurvivorRules.lobbyActivity(roll, socialChance, practiceChance, voteActive)
    if voteActive == true then
        return "vote"
    end

    local value = math.clamp(tonumber(roll) or 0, 0, 0.999)
    local social = math.clamp(tonumber(socialChance) or 0.2, 0, 0.55)
    local practice = math.clamp(tonumber(practiceChance) or 0.2, 0, 0.45)

    if value < social then
        return "social"
    elseif value < social + practice then
        return "practice"
    end
    return "roam"
end

function AISurvivorRules.voteGatherOffset(slot, roundNumber)
    local safeSlot = math.max(1, math.floor(tonumber(slot) or 1))
    local safeRound = math.max(1, math.floor(tonumber(roundNumber) or 1))
    local angle = math.rad(((safeSlot * 113) + (safeRound * 37)) % 360)
    local radius = 6 + ((safeSlot * 7 + safeRound * 3) % 5)
    return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

function AISurvivorRules.lobbyNodeOffset(slot, cycle)
    local safeSlot = math.max(1, math.floor(tonumber(slot) or 1))
    local safeCycle = math.max(0, math.floor(tonumber(cycle) or 0))
    local nodes = {
        Vector3.new(-13, 0, -13),
        Vector3.new(13, 0, -13),
        Vector3.new(-13, 0, 13),
        Vector3.new(13, 0, 13),
    }
    local index = ((safeSlot + safeCycle - 2) % #nodes) + 1
    local base = nodes[index]
    local angle = math.rad((safeSlot * 47 + safeCycle * 31) % 360)
    local micro = Vector3.new(math.cos(angle), 0, math.sin(angle)) * 1.8
    return base + micro
end

function AISurvivorRules.socialSpacing(slot, partnerSlot)
    local a = math.max(1, math.floor(tonumber(slot) or 1))
    local b = math.max(1, math.floor(tonumber(partnerSlot) or 1))
    local phase = ((a * 41 + b * 29) % 360)
    local angle = math.rad(phase)
    local radius = 4.5 + ((a + b) % 4) * 0.65
    return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

function AISurvivorRules.appearanceStyle(identityIndex)
    local index = math.max(1, math.floor(tonumber(identityIndex) or 1))
    -- Eight grounded streetwear silhouettes for twenty rotating fictional
    -- identities; no external assets, animated cosmetics or paid avatars.
    return ((index - 1) % 8) + 1
end

function AISurvivorRules.bodyScales(identityIndex)
    local index = math.max(1, math.floor(tonumber(identityIndex) or 1))
    local body = 0.04 + ((index * 17) % 5) * 0.04
    local proportion = 0.08 + ((index * 13) % 5) * 0.05
    return math.clamp(body, 0.04, 0.20), math.clamp(proportion, 0.08, 0.28)
end

function AISurvivorRules.shapeScales(identityIndex)
    local index = math.max(1, math.floor(tonumber(identityIndex) or 1))
    local depth = 0.94 + ((index * 11) % 7) * 0.02
    local head = 0.95 + ((index * 19) % 6) * 0.02
    return math.clamp(depth, 0.94, 1.06), math.clamp(head, 0.95, 1.05)
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
    -- For a sharp turn, a minority blend (0.34) can keep movement pointed
    -- BACKWARDS forever: exactly opposing vectors normalize to the old
    -- direction at each brain step. After the brief humanlike turn pause,
    -- the new route must own the majority of the steering direction.
    local blend = dot < -0.35 and 0.68
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

-- Once an NPC chooses a deliberate world objective, avoid cancelling it
-- purely because a low-frequency random reconsideration roll succeeds.
-- This is NOT a hazard lock: immediateThreat, collapsing decks, stuck
-- recovery and a missing destination still override or clear the target.
-- Ordinary roaming remains spontaneous and may change its mind.
function AISurvivorRules.committedWorldRoute(targetIsSkyrail, targetPart)
    if targetIsSkyrail == true then
        return true
    end
    if typeof(targetPart) ~= "Instance"
        or not targetPart:IsA("BasePart")
        or not targetPart.Parent
    then
        return false
    end
    local step = tonumber(targetPart:GetAttribute("PerimeterStep"))
    return step == 1 or step == 2
        or targetPart:GetAttribute("GridCircuitIndex") ~= nil
        or targetPart:GetAttribute("FluxRelayIndex") ~= nil
end

-- Long world routes must survive the ordinary roaming rethink clock.
-- Arrival, urgent hazard overrides, invalid targets and stuck recovery
-- still clear the goal; a bounded grace period prevents permanent locks.
function AISurvivorRules.shouldReplanTarget(phase, now, nextThink, target, targetIsSkyrail, targetPart, urgent)
    -- Replanning a casual goal must never overwrite a live disaster escape
    -- after the ordinary timer expires. Survival always takes precedence.
    if urgent == true and typeof(target) == "Vector3" then
        return false
    end
    if typeof(target) ~= "Vector3" then
        return true
    end
    if (tonumber(now) or 0) < (tonumber(nextThink) or 0) then
        return false
    end
    if phase == "round"
        and AISurvivorRules.committedWorldRoute(targetIsSkyrail, targetPart)
    then
        -- Limit long crossings to a five-second grace period beyond the
        -- normal rethink deadline, even if the rig keeps moving in circles.
        return (tonumber(now) or 0) >= (tonumber(nextThink) or 0) + 5
    end
    return true
end

-- Free-form side-to-side motion looks natural on the main floor but can
-- knock an NPC off a narrow perimeter step or out of a mastery trigger.
function AISurvivorRules.allowRouteStrafe(targetIsPad, targetIsSkyrail, targetPart)
    return targetIsPad ~= true
        and not AISurvivorRules.committedWorldRoute(targetIsSkyrail, targetPart)
end

-- A runner heading for an authored outer parkour route needs time to
-- physically reach it. The usual 0.8–1.8 second target holds make bots
-- reverse before crossing the enlarged arenas, which reads as fake AI.
-- Commit only to real PerimeterStep waypoints. Urgent disaster evasion
-- still overrides this timer in AISurvivorService.
function AISurvivorRules.outerRouteHold(baseHold, distance, walkSpeed, perimeterStep)
    local hold = tonumber(baseHold) or 1
    if hold ~= hold or math.abs(hold) == math.huge then hold = 1 end
    hold = math.clamp(hold, 0.2, 6.2)
    local step = tonumber(perimeterStep)
    if step ~= 1 and step ~= 2 then return hold end

    local gap = tonumber(distance)
    local speed = tonumber(walkSpeed)
    if not gap or gap ~= gap or gap < 0 or gap == math.huge
        or not speed or speed ~= speed or speed <= 0 or speed == math.huge then
        return hold
    end
    if gap <= 12 then return hold end
    local travel = gap / math.max(8, speed)
    return math.clamp(math.max(hold, travel + 0.7), hold, 6.2)
end

-- Stage 2 is a high step across a real jump gap. Bots must approach the
-- physical first step instead of walking into the outside wall of Stage 2
-- from anywhere on the floor. No navigation exploits or phantom shortcuts.
function AISurvivorRules.outerStepReachable(step, fromPosition, targetPosition,
        shrinking)
    local n = tonumber(step)
    if n ~= 1 and n ~= 2 then return true end
    if shrinking == true then return false end
    if n == 1 then return true end
    if typeof(fromPosition) ~= "Vector3"
        or typeof(targetPosition) ~= "Vector3" then return false end
    local diff = targetPosition - fromPosition
    local horizontal = Vector3.new(diff.X, 0, diff.Z).Magnitude
    return horizontal <= 24 and diff.Y <= 5.8 and diff.Y >= -8
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
        -- Low gravity magnifies every jump. Realistic survivors become more
        -- conservative instead of repeatedly launching themselves off-map.
        chance *= 0.32
        return math.clamp(chance, 0.02, 0.14)
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

-- AI can use Helix Circuit only when already on an accessible upper
-- level. Otherwise it might try to walk through a ramp suspended above
-- the arena floor instead of seeking an updraft.
function AISurvivorRules.helixWaypointReachable(current, waypoint)
    if typeof(current) ~= "Vector3" or typeof(waypoint) ~= "Vector3" then
        return false
    end
    local diff = waypoint - current
    local horizontal = Vector3.new(diff.X, 0, diff.Z).Magnitude
    return horizontal <= 23 and math.abs(diff.Y) <= 5.5
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

-- Traversing from the actual tower deck, rather than aiming at mid-air.
-- The exit point sits past the midspan Slipstream trigger and safely
-- inside the far end of the physical bridge.
function AISurvivorRules.skyrailExitTarget(bridgeFrame, size, sign)
    if typeof(bridgeFrame) ~= "CFrame" or typeof(size) ~= "Vector3"
        or (sign ~= 1 and sign ~= -1)
    then return nil end
    local longX = size.X > size.Z
    local span = math.max(size.X, size.Z)
    local width = math.min(size.X, size.Z)
    if span < 16 or width < 4 then return nil end
    local finish = sign * (span * 0.5 - 4.8)
    local altitude = size.Y * 0.5 + 2.4
    return bridgeFrame:PointToWorldSpace(
        longX and Vector3.new(finish, altitude, 0)
            or Vector3.new(0, altitude, finish))
end

-- A collapsing Tower skybridge should make an in-round AI run toward
-- one of its *real supported tower decks*, not dodge sideways into the void.
-- This reuses the live bridge dimensions, works on either long axis and
-- rejects positions not actually on the elevated route.
function AISurvivorRules.skybridgeEscapeTarget(position, bridgeFrame, size, velocity)
    if typeof(position) ~= "Vector3"
        or typeof(bridgeFrame) ~= "CFrame"
        or typeof(size) ~= "Vector3"
    then return nil end
    local alongX = size.X > size.Z
    local span, width = math.max(size.X, size.Z), math.min(size.X, size.Z)
    if span < 16 or width < 4 then return nil end
    local localPosition = bridgeFrame:PointToObjectSpace(position)
    local distance = alongX and localPosition.X or localPosition.Z
    local lateral = alongX and localPosition.Z or localPosition.X
    local height = size.Y * 0.5 + 2.4
    if math.abs(lateral) > width * 0.5 + 1.6
        or math.abs(localPosition.Y - height) > 3.2
        or math.abs(distance) > span * 0.5 + 1.5
    then return nil end

    local localVelocity = typeof(velocity) == "Vector3"
        and bridgeFrame:VectorToObjectSpace(velocity) or Vector3.zero
    local speed = alongX and localVelocity.X or localVelocity.Z
    -- Near an endpoint, choose the short exit, never a 49-stud sprint.
    -- At midspan, retain the existing heading if clearly moving.
    local sign = if math.abs(distance) >= 4 then math.sign(distance)
        elseif math.abs(speed) >= 5 then math.sign(speed)
        elseif distance < 0 then -1 else 1
    local finish = sign * (span * 0.5 + 2.8)
    return bridgeFrame:PointToWorldSpace(
        alongX and Vector3.new(finish, height, 0)
            or Vector3.new(0, height, finish))
end

function AISurvivorRules.skyrailCrossingTarget(root, bridgeFrame, size)
    if typeof(root) ~= "Vector3"
        or typeof(bridgeFrame) ~= "CFrame"
        or typeof(size) ~= "Vector3"
    then return nil, nil end
    local longX = size.X > size.Z
    local span = math.max(size.X, size.Z)
    local width = math.min(size.X, size.Z)
    if span < 16 or width < 4 then return nil, nil end
    local localRoot = bridgeFrame:PointToObjectSpace(root)
    local distance = longX and localRoot.X or localRoot.Z
    local side = longX and localRoot.Z or localRoot.X
    local expectedY = size.Y * 0.5 + 2.4
    if math.abs(localRoot.Y - expectedY) > 3.2
        or math.abs(side) > width * 0.5 + 1.6
        or math.abs(distance) < span * 0.5 - 10.5
        or math.abs(distance) > span * 0.5 + 6.2
    then return nil, nil end
    local sign = distance >= 0 and -1 or 1
    return AISurvivorRules.skyrailExitTarget(bridgeFrame, size, sign), sign
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

function AISurvivorRules.locomotionAnimation(speed, airborne, gaitScale)
    local safeSpeed = math.max(0, tonumber(speed) or 0)
    local gait = math.clamp(tonumber(gaitScale) or 1, 0.80, 1.20)

    if airborne == true then
        return "fall", 1
    elseif safeSpeed <= 0.75 then
        return "idle", 1
    elseif safeSpeed < 12.5 then
        return "walk", math.clamp((safeSpeed / 10) * gait, 0.70, 1.25)
    end

    return "run", math.clamp((safeSpeed / 16) * gait, 0.78, 1.32)
end

function AISurvivorRules.animationPlaybackScale(kind, locomotionSpeed, gaitScale)
    local name = tostring(kind or "")
    local gait = math.clamp(tonumber(gaitScale) or 1, 0.80, 1.20)
    local speed = math.max(0.05, tonumber(locomotionSpeed) or 1)

    if name == "idle" then
        return math.clamp(0.98 + (gait - 1) * 0.65, 0.94, 1.06)
    elseif name == "fall" then
        return math.clamp(1 + (gait - 1) * 0.42, 0.96, 1.04)
    elseif name == "jump" then
        return math.clamp(1 + (gait - 1) * 0.55, 0.95, 1.05)
    end

    return speed
end

function AISurvivorRules.locomotionTransition(previousKind, nextKind)
    local previous = tostring(previousKind or "")
    local nextValue = tostring(nextKind or "")

    if previous == nextValue then
        return 0
    end

    if nextValue == "fall" then
        return 0.06
    elseif previous == "fall" then
        return 0.10
    elseif (previous == "idle" and nextValue == "walk")
        or (previous == "walk" and nextValue == "idle")
    then
        return 0.14
    elseif (previous == "walk" and nextValue == "run")
        or (previous == "run" and nextValue == "walk")
    then
        return 0.16
    elseif previous == "run" and nextValue == "idle" then
        return 0.12
    end

    return 0.10
end

-- An unexpected NPC runtime failure must not terminate the shared AI loop.
-- Each record is isolated, and diagnostics are throttled per character.
function AISurvivorRules.runBrainStep(record, now, stepFn)
    local success, result = pcall(stepFn, record, now)
    if success then
        return true, nil, false
    end

    local shouldReport = now >= (record.nextBrainWarningAt or -math.huge)
    if shouldReport then
        record.nextBrainWarningAt = now + 8
    end
    return false, tostring(result), shouldReport
end

function AISurvivorRules.brainCadence(recordCount, phase)
    local count = math.max(0, math.floor(tonumber(recordCount) or 0))
    if count == 0 then
        return 0.75
    end

    if tostring(phase or "waiting") == "result" then
        return 0.42
    end

    return 0.18
end

-- Rank a planned route against the full danger footprint, not merely
-- the destination. A contestant outside a meteor warning should not cut
-- across its center just because the far-side waypoint is technically safe.
-- When already inside the footprint, moving outward must remain possible.
function AISurvivorRules.routeWarningPenalty(origin, destination, warningCenter, warningRadius)
    if typeof(origin) ~= "Vector3" or typeof(destination) ~= "Vector3"
        or typeof(warningCenter) ~= "Vector3"
    then
        return 0
    end

    local radius = tonumber(warningRadius) or 0
    if radius ~= radius or radius <= 0 or math.abs(radius) == math.huge then
        return 0
    end
    radius = math.min(radius, 120)

    local start = Vector3.new(origin.X - warningCenter.X, 0, origin.Z - warningCenter.Z)
    local finish = Vector3.new(
        destination.X - warningCenter.X, 0, destination.Z - warningCenter.Z
    )
    local fromDistance = start.Magnitude
    local toDistance = finish.Magnitude
    if fromDistance <= radius then
        -- Escaping outward is preferred, but a waypoint STILL inside the
        -- final impact footprint is not considered fully safe.
        if toDistance >= fromDistance + 1 then
            return math.clamp((radius + 2 - toDistance) / (radius + 2), 0, 1) * 90
        end
        return 90
    end

    local travel = finish - start
    local distanceSquared = travel:Dot(travel)
    if distanceSquared < 0.01 then
        return toDistance < radius and 90 or 0
    end
    local time = math.clamp(-start:Dot(travel) / distanceSquared, 0, 1)
    local closest = (start + travel * time).Magnitude
    local buffer = radius + 3
    if closest >= buffer then
        return 0
    end
    return math.clamp(1 - closest / buffer, 0, 1) * 90
end

-- A bot that is already dodging one live warning should not switch
-- its attention on every brain tick when two equal-size blast footprints
-- overlap. Switch only when the competing warning is meaningfully closer.
-- The caller first verifies the existing warning is still active AND
-- actually within its detection radius; this only prevents oscillation.
function AISurvivorRules.keepThreatFocus(currentDistance, closestDistance, margin)
    local old = tonumber(currentDistance)
    local nearest = tonumber(closestDistance)
    if not old or not nearest
        or old ~= old or nearest ~= nearest
        or old < 0 or nearest < 0
        or old == math.huge or nearest == math.huge
    then
        return false
    end
    local tolerance = math.clamp(tonumber(margin) or 0, 0, 6)
    return old <= nearest + tolerance
end

-- Always return a NUMBER: a Lua `or` chain with a bare equality can
-- produce boolean true for FreezeWarning and crash distance comparisons.
-- Meteor and Bomb damage uses the final server WarningEndSize, not the
-- little initial warning disc. Keep nine studs of humanlike anticipation
-- outside that radius, but retain each personality's reaction delay.
function AISurvivorRules.warningDetectionRadius(warningName, visualRadius, endDiameter)
    if warningName == "FreezeWarning" or warningName == "JumpShockWarning" then
        return 80
    end

    local radius = tonumber(visualRadius) or 0
    if radius ~= radius or math.abs(radius) == math.huge then
        radius = 0
    end
    radius = math.max(0, radius)

    if warningName == "MeteorWarning" or warningName == "BombWarning" then
        local finalDiameter = tonumber(endDiameter)
        if finalDiameter and finalDiameter == finalDiameter
            and math.abs(finalDiameter) < math.huge and finalDiameter > 0 then
            radius = math.max(radius, finalDiameter * 0.5)
        end
    end
    return math.min(120, radius) + 9
end

-- A bot must not jump as soon as it sees a shock ring. The server awards
-- a real dodge only while the avatar is rising above the floor at impact.
-- Wait until the final part of the *authoritative* telegraph, leaving time
-- for the usual NPC decision cadence without fabricating immunity.
function AISurvivorRules.shockJumpWindow(startedAt, durationSeconds, now)
    local started = tonumber(startedAt)
    local duration = tonumber(durationSeconds)
    local current = tonumber(now)
    if not started or not duration or not current
        or started ~= started or duration ~= duration or current ~= current
        or math.abs(started) == math.huge
        or math.abs(duration) == math.huge
        or math.abs(current) == math.huge
        or duration <= 0 then
        return false
    end
    local remaining = started + duration - current
    return remaining >= 0.10 and remaining <= 0.34
end

-- A single pulse should generate at most one deliberate jump per survivor.
-- The caller marks a warning instance as handled even when a cautious bot
-- declines the Freeze jump. A newly spawned warning is a new opportunity.
function AISurvivorRules.shouldJumpForWarning(warningName, alreadyHandled, roll)
    if alreadyHandled == true then
        return false
    end
    if warningName == "JumpShockWarning" then
        return true
    end
    if warningName == "FreezeWarning" then
        return (tonumber(roll) or 1) < 0.55
    end
    return false
end

-- One-shot state lives in the server NPC record, never globally. Keys may be
-- weak so expired warning instances are collectable during long sessions.
function AISurvivorRules.consumeWarningJump(handled, warning, roll, freezeJumpChance)
    if type(handled) ~= "table" or typeof(warning) ~= "Instance" then
        return false
    end
    local name = warning.Name
    if name ~= "FreezeWarning" and name ~= "JumpShockWarning" then
        return false
    end
    if handled[warning] == true then
        return false
    end
    handled[warning] = true
    if name == "FreezeWarning" and type(freezeJumpChance) == "number" then
        return (tonumber(roll) or 1) < math.clamp(freezeJumpChance, 0, 1)
    end
    return AISurvivorRules.shouldJumpForWarning(name, false, roll)
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
