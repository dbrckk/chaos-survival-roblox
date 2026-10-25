-- Actual Roblox Studio client/server visual QA from an AI survivor's
-- perspective. This script NEVER starts in any published live server.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local StudioTestService = game:GetService("StudioTestService")
local ok, args = pcall(StudioTestService.GetTestArgs, StudioTestService)
if not ok or type(args) ~= "table" or args.suite ~= "ChaosVisualAI" then
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sampleCount = math.clamp(math.floor(tonumber(args.sampleCount) or 15), 1, 15)
local timeout = math.clamp(tonumber(args.timeoutSeconds) or 110, 65, 145)
-- StudioTestService:GetTestArgs() has a known issue when invoked in
-- LocalScripts. The server is authoritative, so forward only the safe
-- suite activation/configuration through replicated attributes.
ReplicatedStorage:SetAttribute("ChaosVisualAISuite", true)
ReplicatedStorage:SetAttribute("ChaosVisualAISamples", sampleCount)
ReplicatedStorage:SetAttribute(
    "ChaosVisualAIInterval", math.clamp(tonumber(args.intervalSeconds) or 3, 2, 8)
)
local report = Instance.new("RemoteEvent")
report.Name = "ChaosVisualAIReport"
report.Parent = ReplicatedStorage

local samples = {}
local problems = {}
local botNames = {}
local hasRound = false
local previousTime = nil
local firstTime = nil
local samplePlayer = nil
local lastRenderFrames = -1

local function reject(message)
    problems[#problems + 1] = tostring(message)
    warn("CHAOS_VISUAL_AI_REJECTED", message)
end

local function finite(n)
    return type(n) == "number" and n == n and math.abs(n) < math.huge
end

report.OnServerEvent:Connect(function(player, payload)
    if samplePlayer and player ~= samplePlayer then return end
    if type(payload) ~= "table" then
        reject("malformed client report")
        return
    end
    if payload.kind == "failure" then
        reject(payload.error or "client failure")
        return
    end
    if payload.kind ~= "frame" then return end
    samplePlayer = player
    local index = #samples + 1
    if payload.index ~= index or index > sampleCount then
        reject("out-of-order or extra visual sample")
        return
    end

    local folder = workspace:FindFirstChild("AISurvivors")
    local model = folder and folder:FindFirstChild(tostring(payload.bot or ""))
    local root = model and model:FindFirstChild("HumanoidRootPart")
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    if not model or model:GetAttribute("AISurvivor") ~= true
        or not root or not root:IsA("BasePart")
        or not humanoid or humanoid.Health <= 0 then
        reject("visual subject is not a living AI survivor")
        return
    end

    local cameraPos = payload.cameraPosition
    local botPos = payload.botPosition
    local vp = payload.viewport
    if typeof(cameraPos) ~= "Vector3"
        or typeof(botPos) ~= "Vector3"
        or typeof(vp) ~= "Vector2" then
        reject("invalid camera/viewport vector types")
        return
    end
    if not (finite(cameraPos.X) and finite(cameraPos.Y)
        and finite(cameraPos.Z) and finite(vp.X) and finite(vp.Y))
        or vp.X < 320 or vp.Y < 240
        or (botPos - root.Position).Magnitude > 10
        or (cameraPos - root.Position).Magnitude > 19 then
        reject("camera not rendering from the bot viewpoint")
        return
    end

    local frames = tonumber(payload.renderedFrames)
    if not finite(frames) or frames <= lastRenderFrames then
        reject("renderer did not advance between samples")
        return
    end
    lastRenderFrames = frames

    local now = os.clock()
    if previousTime and now - previousTime < 2.1 then
        reject("visual samples are too close together")
        return
    end
    previousTime = now
    if not firstTime then firstTime = now end

    -- Regression observed in the user's actual Android screenshots:
    -- voting choices must never compete with the optional practice HUD.
    if payload.voteVisible == true and payload.practiceVisible == true then
        reject("voting panel and optional practice banner overlap")
        return
    end

    local mode = tostring(payload.mode or "")
    if mode ~= "CHASE" and mode ~= "SIDE" and mode ~= "POV" then
        reject("unknown bot camera mode")
        return
    end

    botNames[model.Name] = true
    hasRound = hasRound or payload.inRound == true
        or payload.phase == "round"
    samples[index] = {
        index = index,
        bot = model.Name,
        mode = mode,
        phase = tostring(payload.phase or ""),
        fps = math.floor(tonumber(payload.fps) or 0),
        viewport = string.format("%dx%d", vp.X, vp.Y),
        voteVisible = payload.voteVisible == true,
        practiceVisible = payload.practiceVisible == true,
    }
    print(string.format(
        "CHAOS_VISUAL_AI_CAPTURE_MARKER %02d/%02d bot=%s mode=%s phase=%s fps=%d",
        index, sampleCount, model.Name, mode, tostring(payload.phase), samples[index].fps
    ))
end)

task.spawn(function()
    local deadline = os.clock() + timeout
    while #samples < sampleCount and #problems == 0
        and os.clock() < deadline do
        task.wait(0.15)
    end

    if #problems > 0 then
        StudioTestService:EndTest("FAIL: visual AI: " .. table.concat(problems, " | "))
        return
    end
    if #samples ~= sampleCount then
        StudioTestService:EndTest(string.format(
            "FAIL: visual AI: only %d/%d camera frames observed", #samples, sampleCount
        ))
        return
    end

    local different = 0
    for _ in pairs(botNames) do different += 1 end
    if different < 2 or not hasRound then
        StudioTestService:EndTest(string.format(
            "FAIL: visual AI: bot variety=%d, round observed=%s",
            different, tostring(hasRound)
        ))
        return
    end
    if sampleCount == 15 and previousTime - firstTime < 35 then
        StudioTestService:EndTest("FAIL: visual AI: 15 frames not spread over real play")
        return
    end

    -- Give the external Windows desktop collector time to finish the last
    -- real PNG before Studio closes. This is NOT proof that PNGs exist:
    -- the workflow independently checks image count, size and diversity.
    task.wait(11)
    print("CHAOS_VISUAL_AI_VERIFIED", sampleCount, "samples", different, "AI subjects", "round=", hasRound)
    StudioTestService:EndTest(string.format(
        "PASS: visual AI: %d renderer frames, %d autonomous bots, live round witnessed",
        sampleCount, different
    ))
end)
