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
function GameAnalytics.sessionStarted(player, playerCount)
    local solo = (tonumber(playerCount) or 1) <= 1
    sessions[player.UserId] = {
        startedAt = os.clock(),
        rounds = 0,
        joinedSolo = solo,
    }

    GameAnalytics.custom(player, "SessionStarted", 1, "Mode:" .. GameAnalytics.modeLabel(solo))
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
        "Device:" .. tostring(player:GetAttribute("ClientDeviceClass") or "Unknown")
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
        "Rounds:" .. tostring(session.rounds)
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
