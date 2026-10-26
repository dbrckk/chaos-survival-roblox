local AnalyticsService = game:GetService("AnalyticsService")

local GameAnalytics = {}

local sessions = {}
local onboardingSteps = {}

local function fields(a, b, c)
    local result = {}

    if a ~= nil then
        result[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = tostring(a)
    end
    if b ~= nil then
        result[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = tostring(b)
    end
    if c ~= nil then
        result[Enum.AnalyticsCustomFieldKeys.CustomField03.Name] = tostring(c)
    end

    return result
end

local function safe(call)
    local ok, err = pcall(call)
    if not ok then
        warn("Analytics event failed:", err)
    end
    return ok
end

function GameAnalytics.fields(a, b, c)
    return fields(a, b, c)
end

function GameAnalytics.modeLabel(solo)
    return solo and "Solo" or "Multiplayer"
end

local ARRIVAL_PHASES = {
    waiting = true, intermission = true, ready = true,
    round = true, result = true,
}
-- Low-cardinality cohorts compare early exits by the server phase at join.
function GameAnalytics.arrivalPhase(phase)
    return ARRIVAL_PHASES[phase] and phase or "unknown"
end
function GameAnalytics.phaseRemainingBand(seconds)
    local n = tonumber(seconds)
    if not n or n ~= n or n < 0 or n == math.huge or n == -math.huge then
        return "Unknown"
    elseif n <= 10 then return "0-10s"
    elseif n <= 30 then return "11-30s"
    elseif n <= 60 then return "31-60s"
    end
    return "61s+"
end

function GameAnalytics.custom(player, eventName, value, a, b, c)
    if not player then return false end

    return safe(function()
        AnalyticsService:LogCustomEvent(
            player,
            eventName,
            tonumber(value) or 1,
            fields(a, b, c)
        )
    end)
end

function GameAnalytics.economySource(player, amount, reason, itemSku, solo)
    local numericAmount = math.max(0, tonumber(amount) or 0)
    if numericAmount <= 0 then return false end

    return safe(function()
        AnalyticsService:LogEconomyEvent(
            player,
            Enum.AnalyticsEconomyFlowType.Source,
            "Coins",
            numericAmount,
            math.max(0, player:GetAttribute("Coins") or 0),
            reason == "DailyReward"
                and Enum.AnalyticsEconomyTransactionType.TimedReward.Name
                or Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
            itemSku or "",
            fields("Mode:" .. GameAnalytics.modeLabel(solo), "Source:" .. tostring(reason), nil)
        )
    end)
end


function GameAnalytics.economySink(player, amount, reason, itemSku, solo)
    local numericAmount = math.max(0, tonumber(amount) or 0)
    if numericAmount <= 0 then return false end

    return safe(function()
        AnalyticsService:LogEconomyEvent(
            player,
            Enum.AnalyticsEconomyFlowType.Sink,
            "Coins",
            numericAmount,
            math.max(0, player:GetAttribute("Coins") or 0),
            Enum.AnalyticsEconomyTransactionType.Shop.Name,
            itemSku or "",
            fields("Mode:" .. GameAnalytics.modeLabel(solo), "Sink:" .. tostring(reason), nil)
        )
    end)
end

function GameAnalytics.onboarding(player, step, stepName, solo)
    if not player then return false end

    local userSteps = onboardingSteps[player.UserId]
    if not userSteps then
        userSteps = {}
        onboardingSteps[player.UserId] = userSteps
    end

    if userSteps[step] then
        return true
    end
    userSteps[step] = true

    return safe(function()
        AnalyticsService:LogOnboardingFunnelStepEvent(
            player,
            step,
            stepName,
            fields("Mode:" .. GameAnalytics.modeLabel(solo), nil, nil)
        )
    end)
end

-- Measure the first-session funnel from the authoritative server clock. Each
-- checkpoint fires once per visit, even if the same remote/action is retried.
-- This lets us distinguish joining, seeing the HUD, voting and truly playing.
function GameAnalytics.sessionStarted(player, playerCount, currentPhase, phaseSeconds)
    local solo = (tonumber(playerCount) or 1) <= 1
    local arrival = GameAnalytics.arrivalPhase(currentPhase)
    sessions[player.UserId] = {
        startedAt = os.clock(),
        rounds = 0,
        joinedSolo = solo,
        arrivalPhase = arrival,
    }

    GameAnalytics.custom(player, "SessionStarted", 1,
        "Mode:" .. GameAnalytics.modeLabel(solo),
        "Arrival:" .. arrival,
        "PhaseRemaining:" .. GameAnalytics.phaseRemainingBand(phaseSeconds))
    GameAnalytics.onboarding(player, 1, "Joined", solo)
end

local function markFirstSessionMilestone(player, key, eventName, solo)
    local session = sessions[player.UserId]
    if not session or session[key] then return end

    local reachedAt = os.clock()
    session[key] = reachedAt
    GameAnalytics.custom(
        player,
        eventName,
        math.max(0, reachedAt - session.startedAt),
        "Mode:" .. GameAnalytics.modeLabel(solo),
        "Device:" .. tostring(player:GetAttribute("ClientDeviceClass") or "Unknown"),
        "Arrival:" .. tostring(session.arrivalPhase or "unknown")
    )
end

function GameAnalytics.clientReady(player)
    local session = sessions[player.UserId]
    if not session then return end
    markFirstSessionMilestone(
        player, "clientReadyAt", "TimeToClientReadySeconds", session.joinedSolo
    )
end

function GameAnalytics.sessionEnded(player)
    local session = sessions[player.UserId]
    if not session then return end

    local duration = math.max(0, os.clock() - session.startedAt)
    GameAnalytics.custom(
        player,
        "SessionDurationSeconds",
        duration,
        "Rounds:" .. tostring(session.rounds),
        "Arrival:" .. tostring(session.arrivalPhase or "unknown"),
        "FirstRound:" .. tostring(session.firstRoundAt ~= nil)
    )

    -- Attribute drop-off without guessing why the player left. Roblox
    -- disconnects, voluntary exits and crashes all reach this same hook.
    local stage = "BeforeHUD"
    if session.firstCompletedAt then
        stage = "RoundCompleted"
    elseif session.firstRoundAt then
        stage = "InRound"
    elseif session.firstVoteAt then
        stage = "Voted"
    elseif session.clientReadyAt then
        stage = "Lobby"
    end

    GameAnalytics.custom(
        player,
        "SessionExitStage",
        1,
        "Stage:" .. stage,
        "Rounds:" .. tostring(session.rounds),
        "Device:" .. tostring(player:GetAttribute("ClientDeviceClass") or "Unknown")
    )

    sessions[player.UserId] = nil
    onboardingSteps[player.UserId] = nil
end

function GameAnalytics.roundStarted(player, roundNumber, solo, disasterId, doubleChaos)
    local session = sessions[player.UserId]
    if session then
        session.rounds += 1
    end
    markFirstSessionMilestone(
        player, "firstRoundAt", "TimeToFirstRoundSeconds", solo
    )

    GameAnalytics.custom(
        player,
        "RoundStarted",
        roundNumber,
        "Mode:" .. GameAnalytics.modeLabel(solo),
        "Disaster:" .. tostring(disasterId),
        "Double:" .. tostring(doubleChaos == true)
    )
    GameAnalytics.onboarding(player, 3, "FirstRoundStarted", solo)
end

function GameAnalytics.roundCompleted(player, survived, solo, disasterId, doubleChaos, elapsedSeconds)
    markFirstSessionMilestone(
        player, "firstCompletedAt", "TimeToFirstCompletionSeconds", solo
    )
    GameAnalytics.custom(
        player,
        "RoundCompleted",
        tonumber(elapsedSeconds) or 0,
        "Mode:" .. GameAnalytics.modeLabel(solo),
        "Result:" .. (survived and "Survived" or "Eliminated"),
        "Disaster:" .. tostring(disasterId)
    )

    if doubleChaos then
        GameAnalytics.custom(
            player,
            "DoubleChaosResult",
            survived and 1 or 0,
            "Mode:" .. GameAnalytics.modeLabel(solo),
            "Result:" .. (survived and "Survived" or "Eliminated")
        )
    end

    GameAnalytics.onboarding(player, 4, "FirstRoundCompleted", solo)
    if survived then
        GameAnalytics.onboarding(player, 5, "FirstSurvival", solo)
    end
end

-- One lightweight ArenaSurvived and one ArenaTimeAliveSeconds sample per
-- human at round completion. Existing ArenaMechanicUsed samples provide the
-- interaction counts; no per-tick or per-hazard telemetry is introduced.
-- Restrict the field values to known, stable dimensions to preserve Roblox's
-- cross-experience custom-field cardinality budget.
local KNOWN_ARENAS = {
    Classic = true, Towers = true, Crossroads = true, Orbital = true,
}

local function finiteNonnegative(value, maxValue)
    local number = tonumber(value)
    if not number or number ~= number
        or number == math.huge or number == -math.huge
    then return 0 end
    return math.clamp(number, 0, maxValue)
end

function GameAnalytics.arenaRoundFields(arenaId, solo, primaryId, doubleChaos, dynamicActive)
    local arena = KNOWN_ARENAS[arenaId] and arenaId or "Unknown"
    local primary = tostring(primaryId or "Unknown")
    -- No free-form values from clients and no growing round number fields.
    if not primary:match("^[%w_]+$") or #primary > 25 then
        primary = "Unknown"
    end
    return "Arena:" .. arena,
        "Mode:" .. GameAnalytics.modeLabel(solo),
        "Primary:" .. primary
            .. "|Fusion:" .. (doubleChaos == true and "Yes" or "No")
            .. "|Extra:" .. (dynamicActive == true and "Yes" or "No")
end

-- Character deaths are measured on the same monotonic clock as the
-- round, not from the latest HUD countdown. Clamp unavailable timestamps
-- conservatively rather than inventing an exact instant of elimination.
function GameAnalytics.roundAliveSeconds(roundElapsed, deathSeconds, survived)
    local elapsed = finiteNonnegative(roundElapsed, 120)
    if survived == true or deathSeconds == nil then return elapsed end
    return math.min(elapsed, finiteNonnegative(deathSeconds, 120))
end

function GameAnalytics.arenaRoundMetrics(player, metrics)
    if not player or type(metrics) ~= "table" then return false end
    local arena, mode, context = GameAnalytics.arenaRoundFields(
        metrics.arenaId, metrics.solo, metrics.primaryId,
        metrics.doubleChaos, metrics.dynamicActive
    )
    local survived = metrics.survived == true
    local aliveSeconds = finiteNonnegative(metrics.aliveSeconds, 120)
    local resultLogged = GameAnalytics.custom(
        player, "ArenaSurvived", survived and 1 or 0,
        arena, mode, context
    )
    local durationLogged = GameAnalytics.custom(
        player, "ArenaTimeAliveSeconds", aliveSeconds,
        arena, mode, context
    )
    return resultLogged and durationLogged
end

-- This is ONE server-round aggregate, attributed to the first present
-- human solely because Roblox custom events require a Player. It must not
-- be interpreted as that particular human's bot performance or win rate.
function GameAnalytics.botSurvivalFraction(started, survived)
    local initial = math.floor(finiteNonnegative(started, 20))
    if initial <= 0 then return nil end
    return math.clamp(finiteNonnegative(survived, 20) / initial, 0, 1)
end

function GameAnalytics.arenaBotMetrics(anchorPlayer, metrics)
    if not anchorPlayer or type(metrics) ~= "table" then return false end
    local fraction = GameAnalytics.botSurvivalFraction(
        metrics.botsStarted, metrics.botsSurvived
    )
    if fraction == nil then return false end
    local arena = KNOWN_ARENAS[metrics.arenaId]
        and metrics.arenaId or "Unknown"
    local roster = math.floor(finiteNonnegative(metrics.botsStarted, 20))
    return GameAnalytics.custom(
        anchorPlayer, "ArenaBotSurvivalFraction", fraction,
        "Arena:" .. arena,
        "Mode:" .. GameAnalytics.modeLabel(metrics.solo),
        "Bots:" .. tostring(roster)
            .. "|Early:" .. (metrics.endedEarly == true and "Yes" or "No")
    )
end

function GameAnalytics.vote(player, disasterId, solo)
    markFirstSessionMilestone(
        player, "firstVoteAt", "TimeToFirstVoteSeconds", solo
    )
    GameAnalytics.custom(
        player,
        "DisasterVote",
        1,
        "Mode:" .. GameAnalytics.modeLabel(solo),
        "Disaster:" .. tostring(disasterId)
    )
    GameAnalytics.onboarding(player, 2, "FirstVote", solo)
end

return GameAnalytics
