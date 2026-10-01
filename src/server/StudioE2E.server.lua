local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StudioTestService = game:GetService("StudioTestService")

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
local failures = {}
local removedUserId = nil

local function fail(message)
    table.insert(failures, tostring(message))
    warn("CHAOS_E2E_FAIL", message)
end

reportEvent.OnServerEvent:Connect(function(player, report)
    if type(report) ~= "table" then
        fail("invalid report from " .. player.Name)
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

        if reported >= expectedTotal and played then
            break
        end

        task.wait(0.25)
    end

    local reportCount = 0
    for _ in pairs(reports) do reportCount += 1 end
    if reportCount < expectedTotal then
        fail(string.format("only %d/%d clients reported", reportCount, expectedTotal))
    end

    local players = Players:GetPlayers()
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
            "PASS: %d clients, UI/input/vote/movement/round-state/join-leave verified",
            expectedTotal
        ))
    end
end)
