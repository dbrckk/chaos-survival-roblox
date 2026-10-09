-- Real single-client Studio test. Never runs in published live servers.
-- Trigger with Chaos Solo AI in studio/ChaosAutoplay.plugin.lua.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
    return
end

local Players = game:GetService("Players")
local StudioTestService = game:GetService("StudioTestService")

local okArgs, args = pcall(StudioTestService.GetTestArgs, StudioTestService)
if not okArgs or type(args) ~= "table" or args.suite ~= "ChaosSoloAI" then
    return
end

local EXPECTED_BOTS = 3
local timeoutSeconds = math.clamp(tonumber(args.timeoutSeconds) or 45, 15, 90)

local function botsIn(folder)
    local bots = {}
    if not folder then
        return bots
    end
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") and child:GetAttribute("AISurvivor") == true then
            table.insert(bots, child)
        end
    end
    return bots
end

task.spawn(function()
    local deadline = os.clock() + timeoutSeconds
    local folder
    local bots = {}

    repeat
        if #Players:GetPlayers() > 1 then
            StudioTestService:EndTest("FAIL: solo test received multiple real players")
            return
        end

        folder = workspace:FindFirstChild("AISurvivors")
        bots = botsIn(folder)
        if #Players:GetPlayers() == 1 and #bots == EXPECTED_BOTS then
            break
        end
        task.wait(0.2)
    until os.clock() >= deadline - 9

    if #Players:GetPlayers() ~= 1 or #bots ~= EXPECTED_BOTS then
        StudioTestService:EndTest(string.format(
            "FAIL: expected 1 human + %d AI, got humans=%d AI=%d",
            EXPECTED_BOTS, #Players:GetPlayers(), #bots
        ))
        return
    end

    -- Allow the bounded server ownership retries to complete.
    task.wait(1)
    local positions = {}
    local names = {}
    for _, bot in ipairs(bots) do
        local root = bot:FindFirstChild("HumanoidRootPart")
        local humanoid = bot:FindFirstChildOfClass("Humanoid")
        if not root or not root:IsA("BasePart") or not humanoid
            or humanoid.Health <= 0 or root.Anchored
        then
            StudioTestService:EndTest("FAIL: invalid living R15 bot rig: " .. bot.Name)
            return
        end
        if names[bot.Name] then
            StudioTestService:EndTest("FAIL: duplicate AI identity: " .. bot.Name)
            return
        end
        names[bot.Name] = true

        local ownerOk, owner = pcall(root.GetNetworkOwner, root)
        if not ownerOk or owner ~= nil then
            StudioTestService:EndTest("FAIL: bot physics not server-owned: " .. bot.Name)
            return
        end
        positions[bot] = root.Position
    end

    local movingBots = {}
    local animatedMotionSeen = false
    local samplingUntil = math.min(deadline, os.clock() + 10)
    while os.clock() < samplingUntil do
        for bot, origin in pairs(positions) do
            local root = bot:FindFirstChild("HumanoidRootPart")
            local humanoid = bot:FindFirstChildOfClass("Humanoid")
            if root and humanoid and root:IsA("BasePart") and humanoid.Health > 0 then
                local shift = root.Position - origin
                local horizontalTravel = Vector3.new(shift.X, 0, shift.Z).Magnitude
                if horizontalTravel > 1.2 then
                    movingBots[bot] = true
                end

                local velocity = root.AssemblyLinearVelocity
                local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
                if humanoid.MoveDirection.Magnitude > 0.05 and horizontalSpeed > 0.5
                    and humanoid.FloorMaterial ~= Enum.Material.Air
                then
                    local animator = humanoid:FindFirstChildOfClass("Animator")
                    if animator then
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            if track.IsPlaying
                                and track.Priority == Enum.AnimationPriority.Movement
                                and track.WeightCurrent > 0.01
                            then
                                animatedMotionSeen = true
                                break
                            end
                        end
                    end
                end
            end
        end
        local active = 0
        for _ in pairs(movingBots) do
            active += 1
        end
        -- Distinct moving bots, not camera offsets or a single NPC falling.
        if active >= 2 and animatedMotionSeen then
            break
        end
        task.wait(0.15)
    end

    local movedCount = 0
    for _ in pairs(movingBots) do
        movedCount += 1
    end
    if movedCount < 2 or not animatedMotionSeen then
        StudioTestService:EndTest(string.format(
            "FAIL: solo locomotion insufficient (movingBots=%d/3, activeMovementAnimation=%s)",
            movedCount, tostring(animatedMotionSeen)
        ))
        return
    end

    print("CHAOS_SOLO_AI_E2E", "human=1", "bots=3", "network=server", "movement=PASS")
    StudioTestService:EndTest("PASS: solo AI: three distinct living server-owned bots, two moving with active locomotion animation")
end)
