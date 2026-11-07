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

-- Creator Dashboard is now configured for eight HUMAN seats.
-- Fill any missing ACTIVE round seats with original AI contestants.
-- One human + seven bots = eight at READY, not eight living forever:
-- real disaster eliminations remain authoritative.
AISurvivorRules.TargetVisibleParticipants = 8
AISurvivorRules.MaxBots = 7

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
function AISurvivorRules.committedWorldRoute(targetIsSkyrail, targetPart, activeExpedition)
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
    -- A deliberate 8-stage climb (or 4-step side branch) stays committed
    -- beyond stage two. Do NOT lock an unrelated casual roam target on
    -- an elevated deck just because its metadata mentions PerimeterStep.
    local branch = tonumber(targetPart:GetAttribute("BranchStep"))
    if activeExpedition == true then
        if step and step >= 1 and step <= 8
            and step == math.floor(step) then
            return true
        end
        if branch and branch >= 1 and branch <= 4
            and branch == math.floor(branch) then
            return true
        end
    end
    -- The connected 200-stud promenades and transverse Sky Spine
    -- have real 2.4-stud gaps. A casual lateral strafe or random
    -- rethink near their edges sent bots into open air despite the
    -- intentional guided route. Treat only these actual decks as
    -- committed for the existing bounded five-second grace period.
    return step == 1 or step == 2
        or targetPart:GetAttribute("PromenadeLane") ~= nil
        or targetPart:GetAttribute("SkySpineStep") ~= nil
        or targetPart:GetAttribute("GridCircuitIndex") ~= nil
        or targetPart:GetAttribute("FluxRelayIndex") ~= nil
end

-- Long world routes must survive the ordinary roaming rethink clock.
-- Arrival, urgent hazard overrides, invalid targets and stuck recovery
-- still clear the goal; a bounded grace period prevents permanent locks.
-- A bot moving sideways into the SAME wall every second is stuck
-- even if its root moved 2 studs left/right. Only displacement TOWARD
-- the chosen physical route counts as navigation progress.
function AISurvivorRules.forwardTravel(from, to, target)
    if typeof(from) ~= "Vector3" or typeof(to) ~= "Vector3"
        or typeof(target) ~= "Vector3" then return 0 end
    local heading = Vector3.new(target.X - from.X, 0, target.Z - from.Z)
    local moved = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
    if heading.Magnitude < 0.2 then return moved.Magnitude end
    return moved:Dot(heading.Unit)
end

-- Physical local detours after confirmed loss of forward progress. A
-- world-space target is NOT the same as the bot's current facing; using
-- a fixed RightVector made seven NPCs ricochet at the same obstacle.
-- Alternate their first sidestep by slot; both directions and a small
-- retreat remain valid physical walk paths, never teleport/flight.
-- Recovery side alternation must survive a successfully completed detour.
-- Reset only after a genuine 12-second period without another stall;
-- ordinary progress toward the sideways detour is not proof the original
-- obstacle has been cleared.
function AISurvivorRules.nextRecoveryAttempt(previous, lastAt, now)
    local time = tonumber(now) or 0
    local prior = tonumber(previous) or 0
    local previousAt = tonumber(lastAt) or 0
    if time ~= time or previousAt ~= previousAt
        or math.abs(time) == math.huge
        or math.abs(previousAt) == math.huge
        or time < previousAt or time - previousAt > 12 then
        prior = 0
    end
    return (math.floor(math.max(0, prior)) % 8) + 1
end

function AISurvivorRules.recoveryDirections(position, target, slot)
    if typeof(position) ~= "Vector3" or typeof(target) ~= "Vector3" then
        return {}
    end
    local heading = Vector3.new(
        target.X - position.X, 0, target.Z - position.Z)
    if heading.Magnitude < 0.5 then return {} end
    local forward = heading.Unit
    local right = Vector3.new(-forward.Z, 0, forward.X)
    local sign = math.floor(tonumber(slot) or 1) % 2 == 0 and -1 or 1
    local first = right * sign
    local other = -first
    return {
        (first + forward * 0.28).Unit,
        (other + forward * 0.28).Unit,
        first,
        other,
        (first - forward * 0.42).Unit,
        (other - forward * 0.42).Unit,
        -forward,
    }
end

-- A new target is a success only if its intended world-space progress
-- is measurable. Repeated side-to-side oscillations are still a stall.
-- Return false for held prompts and nonmovement so optional co-op
-- interactions never trigger recovery attempts.
-- Reject seemingly safe detour endpoints separated by a gap or a
-- surprise raised slab. Collidable support must be validated by actual
-- engine raycasts at BOTH places before these numeric constraints apply.
function AISurvivorRules.recoveryGroundIsContinuous(
    rootY, midpointY, endpointY, distance, originFloorY)
    for _, value in ipairs({rootY, midpointY, endpointY, distance}) do
        if type(value) ~= "number" or value ~= value
            or math.abs(value) == math.huge then return false end
    end
    -- The historical 2.7-stud HRP offset is still supported for callers
    -- without physics. Live navigation supplies the actual grounded
    -- raycast height: body scaling and platform thickness must not make
    -- every valid detour look like a vertical cliff.
    if originFloorY ~= nil and (
        type(originFloorY) ~= "number" or originFloorY ~= originFloorY
        or math.abs(originFloorY) == math.huge
    ) then return false end
    local floorY = originFloorY or (rootY - 2.7)
    return distance >= 4.5 and distance <= 8.2
        and math.abs(midpointY - floorY) <= 2.4
        and math.abs(endpointY - floorY) <= 2.4
        and math.abs(midpointY - endpointY) <= 1.25
end

-- A quarantined unreachable goal must not enter the ordinary
-- candidate lottery again on the very next brain tick. Keep all other
-- real physical targets eligible; never fabricate a waypoint in midair.
-- If a tiny map has no alternative, preserve the original list so the
-- existing physical recovery/idle fallback remains authoritative.
function AISurvivorRules.filterRecentlyFailedCandidates(
    candidates, failedTarget, now, expiresAt)
    if type(candidates) ~= "table" then return {} end
    if typeof(failedTarget) ~= "Vector3"
        or (tonumber(now) or 0) >= (tonumber(expiresAt) or 0)
    then return candidates end

    local viable = {}
    for _, candidate in ipairs(candidates) do
        if type(candidate) == "table"
            and typeof(candidate.position) == "Vector3" then
            local dx = candidate.position.X - failedTarget.X
            local dz = candidate.position.Z - failedTarget.Z
            if dx * dx + dz * dz >= 121 then
                table.insert(viable, candidate)
            end
        end
    end
    -- A quarantined goal must never be reintroduced just because all
    -- available candidates happen to be near it. The caller already
    -- handles an empty list by holding the bot on its real footing;
    -- otherwise a single inaccessible destination can cause an
    -- endless walk-into-wall / recover / walk-into-wall cycle.
    return viable
end

-- Five grounded samples along a detour prevent a bot from trying
-- to cross the unseen void between two otherwise safe landing spots.
-- This is a pure rule, so Roblox engine specs can certify it without
-- simulating an entire AI round or relying on arbitrary NPC rig height.
function AISurvivorRules.recoveryGroundSamplesSafe(
    rootY, originY, quarterY, midpointY, threeQuarterY, endpointY, distance)
    -- ipairs skips nil holes in Lua arrays: validate every sample
    -- explicitly before iterating, so an actual gap is always rejected.
    if type(originY) ~= "number" or type(quarterY) ~= "number"
        or type(midpointY) ~= "number"
        or type(threeQuarterY) ~= "number"
        or type(endpointY) ~= "number" then return false end
    for _, height in ipairs({originY, quarterY, midpointY,
        threeQuarterY, endpointY}) do
        if type(height) ~= "number" or height ~= height
            or math.abs(height) == math.huge then return false end
    end
    if not AISurvivorRules.recoveryGroundIsContinuous(
        rootY, midpointY, endpointY, distance, originY
    ) then return false end
    return math.abs(quarterY - originY) <= 1.25
        and math.abs(midpointY - quarterY) <= 1.25
        and math.abs(threeQuarterY - midpointY) <= 1.25
        and math.abs(endpointY - threeQuarterY) <= 1.25
end

function AISurvivorRules.isGenuineStall(
    previousPosition, position, target, elapsed, grounded, moving)
    if grounded ~= true or moving ~= true
        or typeof(previousPosition) ~= "Vector3"
        or typeof(position) ~= "Vector3"
        or typeof(target) ~= "Vector3"
        or type(elapsed) ~= "number" or elapsed < 1.15 then
        return false
    end
    return AISurvivorRules.forwardTravel(
        previousPosition, position, target) < 0.85
end

function AISurvivorRules.shouldReplanTarget(phase, now, nextThink, target, targetIsSkyrail, targetPart, urgent, activeExpedition)
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
        and AISurvivorRules.committedWorldRoute(
            targetIsSkyrail, targetPart, activeExpedition
        )
    then
        -- Limit long crossings to a five-second grace period beyond the
        -- normal rethink deadline, even if the rig keeps moving in circles.
        return (tonumber(now) or 0) >= (tonumber(nextThink) or 0) + 5
    end
    return true
end

-- Free-form side-to-side motion looks natural on the main floor but can
-- knock an NPC off a narrow perimeter step or out of a mastery trigger.
function AISurvivorRules.allowRouteStrafe(
    targetIsPad, targetIsSkyrail, targetPart, activeExpedition)
    -- Mid/high-tier genuine parkour decks are too narrow for arbitrary
    -- sideways crowd-avoidance curves, even when the route was chosen
    -- casually rather than by a deliberate expedition.
    local tier = typeof(targetPart) == "Instance"
        and tonumber(targetPart:GetAttribute("RouteTier")) or nil
    return targetIsPad ~= true
        and (not tier or tier < 3)
        and not AISurvivorRules.committedWorldRoute(
            targetIsSkyrail, targetPart, activeExpedition
        )
end

-- Confirm a grounded landing on the REAL rotated collision deck.
-- A horizontal-distance-only test incorrectly completes a stage while
-- an NPC is airborne beside or above the platform. No raycasts, no
-- extra physics queries and no client-replicated progress claims.
function AISurvivorRules.landedOnRouteDeck(deckFrame, deckSize, rootPosition, grounded)
    if grounded ~= true
        or typeof(deckFrame) ~= "CFrame"
        or typeof(deckSize) ~= "Vector3"
        or typeof(rootPosition) ~= "Vector3"
        or deckSize.X <= 0 or deckSize.Y <= 0 or deckSize.Z <= 0
    then
        return false
    end
    local localRoot = deckFrame:PointToObjectSpace(rootPosition)
    -- Slightly inset the footprint so stepping along an outside edge
    -- is not mistaken for a successful landing.
    local halfX = math.max(0.1, deckSize.X * 0.5 - 0.3)
    local halfZ = math.max(0.1, deckSize.Z * 0.5 - 0.3)
    return math.abs(localRoot.X) <= halfX
        and math.abs(localRoot.Z) <= halfZ
        and localRoot.Y >= deckSize.Y * 0.5 + 1.0
        and localRoot.Y <= deckSize.Y * 0.5 + 5.5
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
    -- A downward target is not automatically walkable: choosing the
    -- arena floor from a 20-stud sky bridge makes bots simply run off
    -- the edge. Descend through nearby physical steps instead; the
    -- urgent threat-escape system can still preempt normal roaming.
    if rise < -10 then return false end
    if rise <= 0 then return true end

    local limit = variantId == "Towers" and 8.5 or 7.5
    return rise <= limit
end

-- Elevated bots should choose the NEXT physical 20-32-stud sky
-- landing, not another sky bridge on the opposite side of the 320-stud
-- world. The latter looked like a valid same-height waypoint to the
-- old AI and sent runners straight into empty air. Ground runners keep
-- the long-distance freedom needed to reach a real entrance terrace.
-- Short level crossings have 2.4-stud REAL air gaps. A human
-- naturally jumps, but ordinary bot height-based jumps never fire
-- when the destination is at the same altitude. Only authorize a
-- normal Humanoid jump when grounded support is present beneath the
-- bot, missing directly ahead, and resumes on a reachable landing.
-- Sample physics separately in the runtime, never fabricate a floor.
-- On elevated routes, two waypoints are physically neighboring
-- only if a straight line between the actual solid deck centers crosses
-- no gap wider than the 3-stud ordinary R15 jump contract. This uses
-- the directional footprint of each rotated deck (not just center
-- distance), so a nearby diagonal platform across open air cannot be
-- scored as a walkable next stage.
-- A missing floor ray beneath an elevated NPC must never unlock
-- every same-height sky waypoint. If its supporting deck vanished,
-- the bot needs a local safe recovery, not a 30-stud run over void.
-- On the ground the normal candidate system remains unrestricted.
-- ComputeAsync is a yielding external engine call. A stalled query
-- must never monopolize the bot's navigation state indefinitely;
-- the async callback is invalidated separately with its generation token.
-- Ordinary grounded roaming can inspect ONE short physical corridor
-- before committing to a distant target. No preview during hazards,
-- jumps, elevated parkour, co-op station holds or real route challenges.
-- The live caller additionally requires a raycast onto the actual Base.
function AISurvivorRules.groundObstaclePreviewAllowed(
    now, nextAt, inRound, grounded, urgent, committed,
    rootY, baseTopY, goalY, horizontalDistance)
    if inRound ~= true or grounded ~= true
        or urgent == true or committed == true then return false end
    for _, value in ipairs({now,nextAt,rootY,baseTopY,goalY,
        horizontalDistance}) do
        if type(value) ~= "number" or value ~= value
            or math.abs(value) == math.huge then return false end
    end
    return now >= nextAt
        and rootY >= baseTopY + 1.2
        and rootY <= baseTopY + 6.5
        and math.abs(goalY - rootY) <= 4.5
        and horizontalDistance >= 9
        and horizontalDistance <= 110
end

-- Pathfinding's regular 3.8-stud arrival window is too permissive at a
-- right-angle turn: an NPC can skip a corner and steer through its wall.
-- Use the normal tolerance on straight lanes and actually reach a sharp
-- turn before switching to the following verified navmesh waypoint.
function AISurvivorRules.groundNavigationArrivalRadius(previous, current, upcoming)
    if typeof(previous) ~= "Vector3"
        or typeof(current) ~= "Vector3"
        or typeof(upcoming) ~= "Vector3" then
        return 3.8
    end
    local before = Vector3.new(current.X - previous.X, 0,
        current.Z - previous.Z)
    local after = Vector3.new(upcoming.X - current.X, 0,
        upcoming.Z - current.Z)
    if before.Magnitude < 0.25 or after.Magnitude < 0.25 then
        return 3.8
    end
    return before.Unit:Dot(after.Unit) < 0.76 and 2.25 or 3.8
end

function AISurvivorRules.groundNavigationQueryTimedOut(
    pending, startedAt, now)
    return pending == true
        and type(startedAt) == "number"
        and type(now) == "number"
        and now == now and startedAt == startedAt
        and now - startedAt >= 6
end

function AISurvivorRules.elevatedRouteHasSupport(
    rootY, baseTopY, standingDeckConfirmed)
    if type(rootY) ~= "number" or type(baseTopY) ~= "number"
        or rootY ~= rootY or baseTopY ~= baseTopY then return false end
    return rootY <= baseTopY + 8 or standingDeckConfirmed == true
end

function AISurvivorRules.neighboringPhysicalDeck(
    firstFrame, firstSize, nextFrame, nextSize)
    if typeof(firstFrame) ~= "CFrame" or typeof(nextFrame) ~= "CFrame"
        or typeof(firstSize) ~= "Vector3"
        or typeof(nextSize) ~= "Vector3" then return false end
    if firstSize.X <= 0 or firstSize.Z <= 0
        or nextSize.X <= 0 or nextSize.Z <= 0 then return false end

    local firstTop = firstFrame.Position.Y
        + firstFrame.UpVector.Y * firstSize.Y * 0.5
    local nextTop = nextFrame.Position.Y
        + nextFrame.UpVector.Y * nextSize.Y * 0.5
    if nextTop - firstTop > 5 or firstTop - nextTop > 7 then
        return false
    end

    local delta = nextFrame.Position - firstFrame.Position
    local horizontal = Vector3.new(delta.X, 0, delta.Z)
    local distance = horizontal.Magnitude
    if distance < 0.05 then return true end
    local unit = horizontal / distance
    local function reach(frame, size)
        local x = math.abs(frame.RightVector:Dot(unit))
        local z = math.abs(frame.LookVector:Dot(unit))
        local xReach = x > 0.0001 and size.X * 0.5 / x or math.huge
        local zReach = z > 0.0001 and size.Z * 0.5 / z or math.huge
        return math.min(xReach, zReach)
    end
    return distance - reach(firstFrame, firstSize)
        - reach(nextFrame, nextSize) <= 3.05
end

-- When a high, real platform announces a collapse, bot escape must
-- move to an AVAILABLE, physically adjacent deck rather than running
-- toward the arena's distant centre through empty air. This shared
-- predicate is deterministic and exercised in the Roblox engine.
-- A doomed elevated platform is not a reason to IGNORE a fresh
-- bomb, meteor or active crane lane. Hold only if no safer active
-- disaster response exists. The choice is a pure, testable rule.
function AISurvivorRules.collapseFallbackTarget(
    activeThreatTarget, noSafeDeck, currentPosition)
    if typeof(activeThreatTarget) == "Vector3" then
        return activeThreatTarget
    end
    if noSafeDeck == true and typeof(currentPosition) == "Vector3" then
        return currentPosition
    end
    return nil
end

function AISurvivorRules.safeCollapseNeighbor(
    threatenedFrame, threatenedSize,
    candidateFrame, candidateSize, available)
    -- A physically colliding but nearly vanished/shrunken tile is not
    -- a viable emergency landing for a full R15 avatar.
    if typeof(candidateSize) ~= "Vector3"
        or candidateSize.X < 6 or candidateSize.Z < 6 then
        return false
    end
    return available == true and AISurvivorRules.neighboringPhysicalDeck(
        threatenedFrame, threatenedSize, candidateFrame, candidateSize
    )
end

function AISurvivorRules.skyGapJumpReady(
    grounded, heightAboveBase, horizontalDistance,
    originFloorY, gapIsSupported, landingFloorY)
    if grounded ~= true or gapIsSupported ~= false then return false end
    if type(heightAboveBase) ~= "number"
        or type(horizontalDistance) ~= "number"
        or type(originFloorY) ~= "number"
        or type(landingFloorY) ~= "number" then return false end
    for _, value in ipairs({
        heightAboveBase, horizontalDistance, originFloorY, landingFloorY
    }) do
        if value ~= value or math.abs(value) == math.huge then return false end
    end
    return heightAboveBase >= 7
        and horizontalDistance >= 4.2
        and horizontalDistance <= 34
        and math.abs(landingFloorY - originFloorY) <= 2.0
end

-- Bot-to-bot separation can displace a center waypoint by several
-- studs. Clamp the result inside the ACTUAL physics deck with room for
-- an R15 collision capsule, rather than asking a survivor to dodge an
-- ally by walking off the edge of a 10-stud sky walkway.
function AISurvivorRules.clampWaypointToDeck(deckFrame, deckSize, waypoint)
    if typeof(deckFrame) ~= "CFrame" or typeof(deckSize) ~= "Vector3"
        or typeof(waypoint) ~= "Vector3" then return nil end
    local localPoint = deckFrame:PointToObjectSpace(waypoint)
    local safeHalfX = math.max(0, deckSize.X * 0.5 - 2)
    local safeHalfZ = math.max(0, deckSize.Z * 0.5 - 2)
    return deckFrame:PointToWorldSpace(Vector3.new(
        math.clamp(localPoint.X, -safeHalfX, safeHalfX),
        localPoint.Y,
        math.clamp(localPoint.Z, -safeHalfZ, safeHalfZ)
    ))
end

-- Meteor/Bomb evasions are selected along physical lanes, never
-- into the air around a tall roof. On a 320-stud arena floor, retain
-- the ordinary long dodge. On an elevated landing, stay inside its
-- actual oriented collision footprint. No valid deck = HOLD position.
function AISurvivorRules.safeElevatedImpactEscape(
    origin, destination, groundTopY, deckFrame, deckSize)
    if typeof(origin) ~= "Vector3" or typeof(destination) ~= "Vector3"
        or type(groundTopY) ~= "number"
        or groundTopY ~= groundTopY
        or math.abs(groundTopY) == math.huge then return nil end
    if origin.Y <= groundTopY + 8 then return destination end
    if typeof(deckSize) ~= "Vector3"
        or deckSize.X < 6 or deckSize.Z < 6 then return origin end
    return AISurvivorRules.clampWaypointToDeck(
        deckFrame, deckSize, destination
    ) or origin
end

function AISurvivorRules.elevatedWaypointNearby(
    current, destination, groundTopY)
    if typeof(current) ~= "Vector3"
        or typeof(destination) ~= "Vector3"
        or type(groundTopY) ~= "number" then return false end
    if current.Y <= groundTopY + 8 then return true end
    local dx = current.X - destination.X
    local dz = current.Z - destination.Z
    return dx * dx + dz * dz <= 34 * 34
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

-- Timed metal shutters are NOT collapsing bridges. On the same physical
-- elevated deck, a surviving bot retreats toward the nearest supported
-- endpoint; at the center of the rising sill it waits rather than crossing
-- a collision that may close during its run. No extra jump power, warp or
-- path through open air. The server supplies the REAL bridge and gate phase.
function AISurvivorRules.skybridgeShutterEscapeTarget(
    position, bridgeFrame, size, phase
)
    if phase ~= "Warning" and phase ~= "Raising"
        and phase ~= "Raised" then
        return nil
    end
    if typeof(position) ~= "Vector3"
        or typeof(bridgeFrame) ~= "CFrame"
        or typeof(size) ~= "Vector3" then
        return nil
    end
    local alongX = size.X > size.Z
    local span = math.max(size.X, size.Z)
    local width = math.min(size.X, size.Z)
    if span < 16 or width < 4 then return nil end
    local localPosition = bridgeFrame:PointToObjectSpace(position)
    local distance = alongX and localPosition.X or localPosition.Z
    local lateral = alongX and localPosition.Z or localPosition.X
    local expectedHeight = size.Y * 0.5 + 2.4
    if math.abs(lateral) > width * 0.5 + 1.6
        or math.abs(localPosition.Y - expectedHeight) > 3.2
        or math.abs(distance) > span * 0.5 + 1.5 then
        return nil
    end

    -- Stopping inside the centerline is safer than forcing a runner
    -- through the blocker. The gate's server occupancy test will refuse
    -- to activate collision over an avatar already here.
    if math.abs(distance) < 3.2 then return position end
    local retreat = (distance < 0 and -1 or 1) * (span * 0.5 + 2.8)
    return bridgeFrame:PointToWorldSpace(
        alongX and Vector3.new(retreat, expectedHeight, 0)
            or Vector3.new(0, expectedHeight, retreat)
    )
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

-- Actual Skybridge shutter state is a route obstruction even though its
-- underlying platform is collidable. This optional fourth argument keeps
-- the original three-argument API working on normal decks.
function AISurvivorRules.platformAvailable(
    canCollide, transparency, collapsePhase, shutterPhase)
    if canCollide ~= true then return false end
    if (tonumber(transparency) or 0) >= 0.90 then return false end
    if collapsePhase == "Warning" or collapsePhase == "Gone" then
        return false
    end
    return shutterPhase == nil or shutterPhase == "Idle"
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

    -- Preserve the original total server-side AI decision budget even
    -- when filling six or seven seats. Each R15 still has its own real
    -- physics/animations, but the shared brain loop cannot spiral from
    -- ~17 steps/sec for three to ~39 steps/sec for seven NPCs.
    -- One hazard reaction can take longer at 7 bots (0.42s); verify
    -- actual survival / responsiveness during engine and Android QA.
    if count >= 4 then
        return count * 0.06
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

-- Server-owned floor sweeps run in an oriented rectangular corridor.
-- Choose the closest of the FOUR real exits: the end of a long lane can
-- be nearer than either side. The center distance is a tiny tie-breaker
-- toward the safe arena interior, not a teleport or movement advantage.
-- This is a pure spatial decision; the humanoid must walk there normally.
function AISurvivorRules.floorSweepExitTarget(frame, size, position, center)
    if typeof(frame) ~= "CFrame" or typeof(size) ~= "Vector3"
        or typeof(position) ~= "Vector3"
        or typeof(center) ~= "Vector3"
        or size.X <= 0 or size.Z <= 0 then
        return nil
    end
    local relative = frame:PointToObjectSpace(position)
    local margin = 5.5
    local candidates = {
        Vector3.new(-size.X * 0.5 - margin, relative.Y, relative.Z),
        Vector3.new(size.X * 0.5 + margin, relative.Y, relative.Z),
        Vector3.new(relative.X, relative.Y, -size.Z * 0.5 - margin),
        Vector3.new(relative.X, relative.Y, size.Z * 0.5 + margin),
    }
    local chosen, bestScore = nil, math.huge
    for _, point in ipairs(candidates) do
        local destination = frame:PointToWorldSpace(point)
        local delta = destination - position
        local walking = Vector3.new(delta.X, 0, delta.Z).Magnitude
        -- Tie only: inside a lane the distance to a physical escape
        -- boundary must dominate the orientation of the arena.
        local interior = destination - center
        local centerDistance = Vector3.new(interior.X, 0, interior.Z).Magnitude
        local score = walking + math.min(centerDistance, 160) * 0.003
        if score < bestScore then
            chosen, bestScore = destination, score
        end
    end
    return chosen
end

-- A circular meteor/bomb escape can cross a *second* rectangular
-- floor sweep. Score the WHOLE walking segment against the real oriented
-- server corridor; a safe-looking endpoint is not enough.
-- Ground-level sweeps do not affect an NPC already on a high platform.
-- Pure bounded geometry: no raycasts, new watchers or privileged movement.
function AISurvivorRules.floorSweepRoutePenalty(origin, destination, bandFrame, bandSize)
    if typeof(origin) ~= "Vector3"
        or typeof(destination) ~= "Vector3"
        or typeof(bandFrame) ~= "CFrame"
        or typeof(bandSize) ~= "Vector3"
        or bandSize.X <= 0 or bandSize.Z <= 0
    then
        return 0
    end
    local start = bandFrame:PointToObjectSpace(origin)
    local finish = bandFrame:PointToObjectSpace(destination)
    -- The real hazard checks RootPart local Y within 1..5.1 studs.
    -- A character safe on an elevated walkway is not crossing the pulse.
    if start.Y < 0.5 or start.Y > 5.8
        or finish.Y < 0.5 or finish.Y > 5.8 then
        return 0
    end

    local halfX = bandSize.X * 0.5 + 1.2
    local halfZ = bandSize.Z * 0.5 + 1.2
    local function inside(p)
        return math.abs(p.X) <= halfX and math.abs(p.Z) <= halfZ
    end
    local beginsInside = inside(start)
    local endsInside = inside(finish)
    -- Leaving the dangerous strip should never be penalized; otherwise
    -- an NPC trapped inside has no incentive to get out immediately.
    if beginsInside then return endsInside and 125 or 0 end

    local travel = finish - start
    local entry, exit = 0, 1
    for _, isX in ipairs({true, false}) do
        local bound = isX and halfX or halfZ
        local offset = isX and start.X or start.Z
        local delta = isX and travel.X or travel.Z
        if math.abs(delta) < 0.0001 then
            if math.abs(offset) > bound then return 0 end
        else
            local a = (-bound - offset) / delta
            local z = (bound - offset) / delta
            if a > z then a, z = z, a end
            entry = math.max(entry, a)
            exit = math.min(exit, z)
            if entry > exit then return 0 end
        end
    end
    return endsInside and 125 or 90
end

-- Score the actual RAYCAST CONTACT height, never the centre of a
-- thick floor slab. Using BasePart.Position.Y falsely punished legal routes
-- on raised decks and favored the wrong direction around a meteor.
-- HumanoidRootPart is ~2.5-3 studs above its contact surface.
function AISurvivorRules.escapeGroundStepPenalty(rootY, contactY)
    local start = tonumber(rootY)
    local surface = tonumber(contactY)
    if not start or not surface
        or start ~= start or surface ~= surface
        or math.abs(start) == math.huge
        or math.abs(surface) == math.huge then
        return 100
    end
    local verticalDrop = start - surface
    if verticalDrop > 8 then return 65 end
    if verticalDrop < -4 then return 45 end
    return 0
end

-- A humanlike bot can commit to a dodge for a fraction of a second, but
-- never keep blindly following that route when a NEW real warning is
-- created or removed. No extra raycasts or Workspace traversal are needed:
-- the warning owner already tracks direct-child lifecycle events.
function AISurvivorRules.keepEscapeRoute(
    target, position, now, holdUntil, plannedWarningVersion, currentWarningVersion
)
    if typeof(target) ~= "Vector3" or typeof(position) ~= "Vector3"
        or type(now) ~= "number" or type(holdUntil) ~= "number"
        or now ~= now or holdUntil ~= holdUntil
        or math.abs(now) == math.huge or math.abs(holdUntil) == math.huge
        or type(plannedWarningVersion) ~= "number"
        or type(currentWarningVersion) ~= "number"
        or plannedWarningVersion ~= currentWarningVersion
    then
        return false
    end
    return now < holdUntil and (position - target).Magnitude >= 4
end

-- Detect only a NEW visible impact footprint crossing a bot's current
-- escape path. The warning event counter may change for faraway impacts;
-- they must NOT multiply ground raycasts during Double Chaos. The final
-- server warning diameter is the same data used by the existing planner.
function AISurvivorRules.newImpactIntersectsEscape(
    origin, target, warningName, center, visibleRadius, endDiameter
)
    if warningName ~= "MeteorWarning" and warningName ~= "BombWarning" then
        return false
    end
    local radius = math.max(5, AISurvivorRules.warningDetectionRadius(
        warningName, visibleRadius, endDiameter
    ) - 9)
    return AISurvivorRules.routeWarningPenalty(
        origin, target, center, radius
    ) >= 20
end

-- Direct impact warnings take precedence over global timing cues during
-- Double Chaos. The priorities only arbitrate *already detected* warnings;
-- they do not expand detection radii or suppress normal reaction delays.
function AISurvivorRules.warningThreatPriority(name)
    if name == "MeteorWarning" or name == "BombWarning" then
        return 2
    end
    if name == "JumpShockWarning" or name == "FreezeWarning" then
        return 1
    end
    return 0
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


-- The storm's outer glass/ribbon pieces are cosmetic; bots read the
-- authoritative replicated LowerFunnel, which follows veteran drift.
-- Missing or pre-spawn visuals fall back to the arena center.
function AISurvivorRules.tornadoCenter(model, fallback)
    if typeof(fallback) ~= "Vector3" then return nil end
    if typeof(model) ~= "Instance" or not model:IsA("Model") then
        return fallback
    end
    local lower = model:FindFirstChild("LowerFunnel")
    if not lower or not lower:IsA("BasePart") then return fallback end
    return lower.Position - Vector3.new(0, 3, 0)
end

-- Respect the tornado's 42-stud horizontal force radius and its upper
-- counterplay band. The personality risk factor keeps daring survivors
-- somewhat closer to the funnel than cautious ones.
function AISurvivorRules.tornadoRouteScore(position, center, risk)
    if typeof(position) ~= "Vector3" or typeof(center) ~= "Vector3" then
        return 0
    end
    local r = math.clamp(tonumber(risk) or 0.5, 0, 1)
    local dx, dz = position.X - center.X, position.Z - center.Z
    local distance = math.sqrt(dx * dx + dz * dz)
    local highGround = math.clamp((position.Y - center.Y - 12) / 16, 0, 1)
    return math.min(distance, 44) * (0.72 - r * 0.16)
        + highGround * (8 - r * 4)
end

return AISurvivorRules
