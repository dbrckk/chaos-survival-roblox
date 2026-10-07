local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StudioTestService = game:GetService("StudioTestService")

local VisualBudgetRules = require(ReplicatedStorage.Shared.VisualBudgetRules)

local okArgs, args = pcall(StudioTestService.GetTestArgs, StudioTestService)
if not okArgs or type(args) ~= "table" or args.suite ~= "ChaosE2E" then
    return
end

local expectedInitial = tonumber(args.initialPlayers) or 2
local addPlayers = tonumber(args.addPlayers) or 2
local expectedTotal = expectedInitial + addPlayers
local timeoutSeconds = tonumber(args.timeoutSeconds) or 55

ReplicatedStorage:SetAttribute("ChaosE2EActive", true)

local reportEvent = ReplicatedStorage:FindFirstChild("ChaosE2EReport") or Instance.new("RemoteEvent")
reportEvent.Name = "ChaosE2EReport"
reportEvent.Parent = ReplicatedStorage

local reports = {}
local spectatorProbeReports = {}
local arenaProbeReports = {
    Classic = false,
    Towers = false,
    Crossroads = false,
    Orbital = false,
}
local arenaEntryProbeReports = {
    Classic = false,
    Towers = false,
    Crossroads = false,
    Orbital = false,
}
local visualPhaseProbeReports = {
    ready = 0,
    round = 0,
    result = 0,
}
local roundArenaVisualReports = {
    Classic = false,
    Towers = false,
    Crossroads = false,
    Orbital = false,
}
local uxPhaseProbeReports = {
    ready = 0,
    result = 0,
}
local failures = {}
local removedUserId = nil

local function fail(message)
    table.insert(failures, tostring(message))
    warn("CHAOS_E2E_FAIL", message)
end

local function visualPhasesReady()
    for _, phase in ipairs({"ready", "round", "result"}) do
        if visualPhaseProbeReports[phase] < 1 then
            return false
        end
    end
    return true
end

local function arenaCoverageReady()
    for _, arenaId in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
        if arenaProbeReports[arenaId] ~= true then
            return false
        end
    end
    return true
end

local function arenaEntryCoverageReady()
    for _, arenaId in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
        if arenaEntryProbeReports[arenaId] ~= true then
            return false
        end
    end
    return true
end

local function roundArenaVisualCoverageReady()
    for _, arenaId in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
        if roundArenaVisualReports[arenaId] ~= true then
            return false
        end
    end
    return true
end

reportEvent.OnServerEvent:Connect(function(player, report)
    if type(report) ~= "table" then
        fail("invalid report from " .. player.Name)
        return
    end

    if report.kind == "arena_entry_probe" then
        local arenaId = tostring(report.arenaId or "")
        if arenaEntryProbeReports[arenaId] == nil then
            fail(player.Name .. ": invalid arena entry probe " .. arenaId)
            return
        end
        if report.ok ~= true
            or report.characterReady ~= true
            or report.insideFootprint ~= true
        then
            fail(
                player.Name
                    .. ": arena entry probe failed for "
                    .. arenaId
                    .. ": "
                    .. tostring(report.error or "unknown")
            )
            return
        end

        arenaEntryProbeReports[arenaId] = true
        print("CHAOS_E2E_ARENA_ENTRY", player.Name, arenaId)
        return
    end

    if report.kind == "arena_probe" then
        local arenaId = tostring(report.arenaId or "")
        local worldArenaId = tostring(report.worldArenaId or "")
        if arenaProbeReports[arenaId] == nil then
            fail(player.Name .. ": invalid arena probe " .. arenaId)
            return
        end
        if report.ok ~= true or worldArenaId ~= arenaId then
            fail(
                player.Name
                    .. ": arena probe mismatch state="
                    .. arenaId
                    .. " world="
                    .. worldArenaId
            )
            return
        end

        arenaProbeReports[arenaId] = true
        print("CHAOS_E2E_ARENA", player.Name, arenaId, "world=" .. worldArenaId)
        return
    end

    if report.kind == "ux_phase_probe" then
        local phase = tostring(report.phase or "")
        if uxPhaseProbeReports[phase] == nil then
            fail(player.Name .. ": invalid UX phase probe: " .. phase)
            return
        end
        if report.ok ~= true then
            fail(
                player.Name
                    .. ": "
                    .. phase
                    .. " UX probe failed: "
                    .. tostring(report.error or "unknown")
            )
            return
        end
        uxPhaseProbeReports[phase] += 1
        return
    end

    if report.kind == "visual_phase_probe" then
        local phase = tostring(report.phase or "")
        if visualPhaseProbeReports[phase] == nil then
            fail(player.Name .. ": invalid visual phase probe " .. phase)
            return
        end

        local metrics = report.visualMetrics
        local fieldOfView = tonumber(report.fieldOfView) or 0
        local tierName = tostring(report.vfxTier or "High")
        local arenaId = tostring(report.arenaId or "")

        if type(metrics) ~= "table"
            or type(metrics.Parts) ~= "number"
            or type(metrics.Lights) ~= "number"
            or type(metrics.Effects) ~= "number"
        then
            fail(player.Name .. ": invalid " .. phase .. " visual metrics")
            return
        end

        if fieldOfView < 60 or fieldOfView > 90 then
            fail(player.Name .. ": " .. phase .. " FOV outside safe bounds")
        end

        if not VisualBudgetRules.withinBudget(tierName, metrics) then
            fail(string.format(
                "%s: %s visual budget exceeded for %s (parts=%d lights=%d effects=%d)",
                player.Name,
                phase,
                tierName,
                metrics.Parts,
                metrics.Lights,
                metrics.Effects
            ))
        end

        local post = report.postProcess
        if type(post) ~= "table"
            or type(post.depthNearIntensity) ~= "number"
            or type(post.depthFarIntensity) ~= "number"
            or type(post.sunRaysEnabled) ~= "boolean"
            or type(post.sunRaysIntensity) ~= "number"
        then
            fail(player.Name .. ": " .. phase .. " invalid post-process probe")
        else
            if post.depthNearIntensity < 0 or post.depthNearIntensity > 1
                or post.depthFarIntensity < 0 or post.depthFarIntensity > 1
                or post.sunRaysIntensity < 0 or post.sunRaysIntensity > 1
            then
                fail(player.Name .. ": " .. phase .. " post-process values out of bounds")
            end

            if phase == "round" then
                if post.depthNearIntensity > 0.005
                    or post.depthFarIntensity > 0.005
                then
                    fail(player.Name .. ": ROUND depth of field must be effectively disabled")
                end
                if post.sunRaysEnabled or post.sunRaysIntensity > 0.005 then
                    fail(player.Name .. ": ROUND sun rays must be disabled for hazard readability")
                end
            end
        end

        visualPhaseProbeReports[phase] += 1
        if phase == "round" then
            if roundArenaVisualReports[arenaId] == nil then
                fail(player.Name .. ": ROUND visual probe has invalid arenaId " .. arenaId)
            else
                roundArenaVisualReports[arenaId] = true
            end
        end

        print(
            "CHAOS_E2E_VISUAL_PHASE",
            player.Name,
            phase,
            arenaId,
            tierName,
            string.format(
                "parts=%d lights=%d effects=%d fov=%.1f folders=%d depth=%.3f/%.3f rays=%s/%.3f",
                metrics.Parts,
                metrics.Lights,
                metrics.Effects,
                fieldOfView,
                tonumber(report.auditedFolders) or 0,
                type(report.postProcess) == "table"
                    and tonumber(report.postProcess.depthNearIntensity) or -1,
                type(report.postProcess) == "table"
                    and tonumber(report.postProcess.depthFarIntensity) or -1,
                type(report.postProcess) == "table"
                    and tostring(report.postProcess.sunRaysEnabled) or "invalid",
                type(report.postProcess) == "table"
                    and tonumber(report.postProcess.sunRaysIntensity) or -1
            )
        )
        return
    end

    if report.kind == "spectator_probe" then
        spectatorProbeReports[player.UserId] = report
        if report.ok ~= true or report.spectatorVisible ~= true then
            fail(player.Name .. ": spectator probe failed")
        end
        return
    end

    reports[player.UserId] = report

    if report.ok ~= true then
        fail(player.Name .. ": " .. tostring(report.error or "client report failed"))
    end

    if report.roundStateReceived ~= true then
        fail(player.Name .. ": current RoundState snapshot was not received")
    end

    if type(report.roundPhase) ~= "string" or report.roundPhase == "" then
        fail(player.Name .. ": missing round phase in E2E report")
    end

    if typeof(report.viewport) ~= "Vector2" or report.viewport.X <= 0 or report.viewport.Y <= 0 then
        fail(player.Name .. ": invalid viewport reported")
    end

    local fieldOfView = tonumber(report.fieldOfView) or 0
    if fieldOfView < 60 or fieldOfView > 90 then
        fail(player.Name .. ": reported FOV outside safe bounds")
    end

    local metrics = report.visualMetrics
    if type(metrics) ~= "table"
        or type(metrics.Parts) ~= "number"
        or type(metrics.Lights) ~= "number"
        or type(metrics.Effects) ~= "number"
    then
        fail(player.Name .. ": invalid visual metrics")
    else
        print(
            "CHAOS_E2E_VISUAL",
            player.Name,
            tostring(report.vfxTier or "Unknown"),
            string.format(
                "parts=%d lights=%d effects=%d fov=%.1f",
                metrics.Parts,
                metrics.Lights,
                metrics.Effects,
                fieldOfView
            )
        )
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player:GetAttribute("ChaosE2EShouldLeave") == true then
        removedUserId = player.UserId
    end
end)

task.spawn(function()
    local started = os.clock()

    while #Players:GetPlayers() < expectedInitial and os.clock() - started < 12 do
        task.wait(0.2)
    end

    if #Players:GetPlayers() < expectedInitial then
        fail("initial clients did not connect")
        StudioTestService:EndTest("FAIL: initial clients")
        return
    end

    if addPlayers > 0 then
        local okAdd, err = pcall(StudioTestService.AddPlayers, StudioTestService, addPlayers)
        if not okAdd then
            fail("AddPlayers failed: " .. tostring(err))
        end
    end

    while #Players:GetPlayers() < expectedTotal and os.clock() - started < 20 do
        task.wait(0.2)
    end

    if #Players:GetPlayers() < expectedTotal then
        fail("staggered clients did not connect")
    end

    local root = workspace:FindFirstChild("GeneratedMap")
    if not root then
        fail("GeneratedMap missing")
    else
        if not root:FindFirstChild("Lobby") then fail("Lobby missing") end
        if not root:FindFirstChild("Arena") then fail("Arena missing") end
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then
        fail("Remotes missing")
    else
        for _, name in ipairs({
            "RoundState",
            "VoteDisaster",
            "DailyReward",
            "QuestUpdate",
            "CosmeticState",
            "CosmeticAction",
            "AchievementState",
            "RoundFeedback",
            "ClientReady",
            "ArenaMechanicFeedback",
            "HazardImpactFeedback",
            "HazardNearMiss",
            "ChaosShardCollected",
            "PerformancePulse",
            "AccessibilitySettings",
            "SocialSignal",
            "SocialReaction",
            "MonetizationState",
            "MonetizationAction",
        }) do
            if not remotes:FindFirstChild(name) then
                fail("remote missing: " .. name)
            end
        end
    end

    while os.clock() - started < timeoutSeconds do
        local reported = 0
        for _ in pairs(reports) do
            reported += 1
        end

        local played = true
        for _, player in ipairs(Players:GetPlayers()) do
            if (player:GetAttribute("Games") or 0) < 1 then
                played = false
                break
            end
        end

        local uxReady = uxPhaseProbeReports.ready >= 1
            and uxPhaseProbeReports.result >= 1
        if reported >= expectedTotal
            and played
            and visualPhasesReady()
            and uxReady
            and arenaCoverageReady()
            and arenaEntryCoverageReady()
            and roundArenaVisualCoverageReady()
        then
            break
        end

        task.wait(0.25)
    end

    local reportCount = 0
    for _ in pairs(reports) do reportCount += 1 end
    if reportCount < expectedTotal then
        fail(string.format("only %d/%d clients reported", reportCount, expectedTotal))
    end

    for _, phase in ipairs({"ready", "round", "result"}) do
        if visualPhaseProbeReports[phase] < 1 then
            fail("missing visual phase probe: " .. phase)
        end
    end

    for _, arenaId in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
        if arenaProbeReports[arenaId] ~= true then
            fail("missing arena coverage probe: " .. arenaId)
        end
    end

    for _, arenaId in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
        if arenaEntryProbeReports[arenaId] ~= true then
            fail("missing arena entry probe: " .. arenaId)
        end
    end

    for _, arenaId in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
        if roundArenaVisualReports[arenaId] ~= true then
            fail("missing ROUND visual budget probe: " .. arenaId)
        end
    end

    for _, phase in ipairs({"ready", "result"}) do
        if uxPhaseProbeReports[phase] < 1 then
            fail("missing UX phase probe: " .. phase)
        end
    end

    local players = Players:GetPlayers()
    if #players > 1 then
        local probePlayer = players[#players]
        local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
        local roundState = remotesFolder and remotesFolder:FindFirstChild("RoundState")

        if roundState and roundState:IsA("RemoteEvent") then
            probePlayer:SetAttribute("RoundParticipant", false)
            probePlayer:SetAttribute("RoundEliminated", false)
            probePlayer:SetAttribute("ChaosE2ESpectatorProbe", true)
            task.wait(0.25)
            roundState:FireClient(probePlayer, {
                phase = "round",
                title = "E2E SPECTATOR PROBE",
                hint = "",
                seconds = 3,
            })

            local probeDeadline = os.clock() + 5
            while spectatorProbeReports[probePlayer.UserId] == nil and os.clock() < probeDeadline do
                task.wait(0.1)
            end

            local probeReport = spectatorProbeReports[probePlayer.UserId]
            if not probeReport or probeReport.spectatorVisible ~= true then
                fail("spectator UI did not activate for E2E probe")
            end
        else
            fail("RoundState remote unavailable for spectator probe")
        end
    end

    players = Players:GetPlayers()
    if #players > 1 then
        players[#players]:SetAttribute("ChaosE2EShouldLeave", true)

        local leaveDeadline = os.clock() + 8
        while removedUserId == nil and os.clock() < leaveDeadline do
            task.wait(0.2)
        end

        if removedUserId == nil then
            fail("client leave flow did not complete")
        end
    end

    if #failures > 0 then
        StudioTestService:EndTest("FAIL: " .. table.concat(failures, " | "))
    else
        StudioTestService:EndTest(string.format(
            "PASS: %d clients, 4 arena entries + per-arena ROUND visual budgets + UI/input/vote/movement/round-state/visual-phases/spectator/join-leave verified",
            expectedTotal
        ))
    end
end)
