-- Studio-only spectator camera for a 15-frame real-engine visual review.
-- Follows ACTUAL autonomous AI survivors; never puppeteers their movement.
-- The companion Windows runner captures rendered pixels from the Studio window.
-- No fake images, automatic Roblox gallery uploads, or production-side code.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Roblox documents that StudioTestService:GetTestArgs() can fail inside
-- client LocalScripts. Use the test server's replicated opt-in flag
-- instead; published servers never set it.
local activateBy = os.clock() + 12
while ReplicatedStorage:GetAttribute("ChaosVisualAISuite") ~= true
    and os.clock() < activateBy do
    task.wait(0.15)
end
if ReplicatedStorage:GetAttribute("ChaosVisualAISuite") ~= true then
    return
end
local player = Players.LocalPlayer
if not player then return end

local report = ReplicatedStorage:WaitForChild("ChaosVisualAIReport", 20)
if not report or not report:IsA("RemoteEvent") then
    warn("CHAOS_VISUAL_AI: report channel unavailable")
    return
end

local count = math.clamp(
    math.floor(tonumber(ReplicatedStorage:GetAttribute("ChaosVisualAISamples")) or 15), 1, 15
)
local interval = math.clamp(
    tonumber(ReplicatedStorage:GetAttribute("ChaosVisualAIInterval")) or 3, 2, 8
)
local expectedArena = tostring(
    ReplicatedStorage:GetAttribute("ChaosVisualAIArena") or "Harbor"
)
local phase = "waiting"
local roundState = ReplicatedStorage:WaitForChild("Remotes", 15)
local stateEvent = roundState and roundState:FindFirstChild("RoundState")
if stateEvent and stateEvent:IsA("RemoteEvent") then
    stateEvent.OnClientEvent:Connect(function(state)
        if type(state) == "table" then
            phase = tostring(state.phase or "waiting")
        end
    end)
end

local function availableBots()
    local folder = workspace:FindFirstChild("AISurvivors")
    local bots = {}
    if folder then
        for _, model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") and model:GetAttribute("AISurvivor") == true then
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                local root = model:FindFirstChild("HumanoidRootPart")
                if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
                    bots[#bots + 1] = model
                end
            end
        end
    end
    table.sort(bots, function(a, b)
        return a.Name < b.Name
    end)
    return bots
end

local function actualArena()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    return arena and arena:GetAttribute("VariantId")
end

local function liveRoundBots()
    local result = {}
    for _, model in ipairs(availableBots()) do
        if model:GetAttribute("AISurvivorInRound") == true then
            result[#result + 1] = model
        end
    end
    return result
end

local function lookDirection(root)
    local velocity = root.AssemblyLinearVelocity
    local planar = Vector3.new(velocity.X, 0, velocity.Z)
    if planar.Magnitude >= 3.5 then
        return planar.Unit
    end
    local facing = root.CFrame.LookVector
    local flat = Vector3.new(facing.X, 0, facing.Z)
    return flat.Magnitude > 0.05 and flat.Unit or Vector3.new(0, 0, -1)
end

-- A tiny provenance tag INSIDE the real Roblox render confirms whose
-- autonomous viewpoint the external Windows PNG is observing. Only present
-- in the opt-in Studio suite; production never creates this GUI.
local proofGui = Instance.new("ScreenGui")
proofGui.Name = "ChaosVisualAIProof"
proofGui.ResetOnSpawn = false
proofGui.IgnoreGuiInset = true
proofGui.DisplayOrder = 96
proofGui.Parent = player:WaitForChild("PlayerGui")

local proofLabel = Instance.new("TextLabel")
proofLabel.Name = "AICameraIdentity"
proofLabel.AnchorPoint = Vector2.new(0, 1)
proofLabel.Position = UDim2.new(0, 14, 1, -14)
proofLabel.Size = UDim2.fromOffset(540, 34)
proofLabel.BackgroundColor3 = Color3.fromRGB(11, 18, 32)
proofLabel.BackgroundTransparency = 0.16
proofLabel.TextColor3 = Color3.fromRGB(235, 246, 255)
proofLabel.Font = Enum.Font.GothamBold
proofLabel.TextSize = 14
proofLabel.TextXAlignment = Enum.TextXAlignment.Center
proofLabel.Text = "STUDIO AI VISUAL QA  |  WAITING FOR BOT"
proofLabel.Parent = proofGui
local proofCorner = Instance.new("UICorner")
proofCorner.CornerRadius = UDim.new(0, 9)
proofCorner.Parent = proofLabel

local currentBot = nil
local currentMode = "CHASE"
local sampleIndex = 0
local renderFrames = 0
local totalDt = 0
local previousCamera = nil
local previousCameraType = nil
local previousCameraSubject = nil
local bindName = "ChaosVisualAIStudioCamera"

local function restore()
    RunService:UnbindFromRenderStep(bindName)
    local camera = workspace.CurrentCamera
    if camera and camera == previousCamera then
        camera.CameraType = previousCameraType or Enum.CameraType.Custom
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid or previousCameraSubject then
            camera.CameraSubject = humanoid or previousCameraSubject
        end
    end
    currentBot = nil
    if proofGui.Parent then proofGui:Destroy() end
end

RunService:BindToRenderStep(bindName, Enum.RenderPriority.Camera.Value + 3, function(dt)
    renderFrames += 1
    totalDt += dt

    local bot = currentBot
    local camera = workspace.CurrentCamera
    if not bot or not camera or not bot.Parent then return end
    local root = bot:FindFirstChild("HumanoidRootPart")
    local humanoid = bot:FindFirstChildOfClass("Humanoid")
    if not root or not root:IsA("BasePart")
        or not humanoid or humanoid.Health <= 0 then
        return
    end
    if previousCamera ~= camera then
        previousCamera = camera
        previousCameraType = camera.CameraType
        previousCameraSubject = camera.CameraSubject
    end

    camera.CameraType = Enum.CameraType.Scriptable
    local dir = lookDirection(root)
    local head = bot:FindFirstChild("Head")
    local eye = head and head:IsA("BasePart")
        and head.Position or (root.Position + Vector3.new(0, 1.8, 0))
    local pos, aim
    if currentMode == "POV" then
        -- Bot eye-level: avoid clipping the visible avatar's face/hair.
        pos = eye + dir * 0.72 + Vector3.new(0, 0.15, 0)
        aim = pos + dir * 18 + Vector3.new(0, -0.4, 0)
    elseif currentMode == "SIDE" then
        local lateral = Vector3.new(-dir.Z, 0, dir.X)
        pos = eye - dir * 7 + lateral * 5.5 + Vector3.new(0, 3, 0)
        aim = eye + dir * 5
    else
        pos = eye - dir * 10 + Vector3.new(0, 4.0, 0)
        aim = eye + dir * 4
    end

    -- Prevent an exterior wall from swallowing the actual camera. The
    -- protected screenshot remains a real rendered Roblox frame.
    if currentMode ~= "POV" then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local localCharacter = player.Character
        params.FilterDescendantsInstances = localCharacter
            and {bot, localCharacter} or {bot}
        params.IgnoreWater = true
        local delta = pos - eye
        local collision = workspace:Raycast(eye, delta, params)
        if collision then
            pos = collision.Position - delta.Unit * 0.55
        end
    end

    local desired = CFrame.lookAt(pos, aim)
    -- Stabilize instantly on bot switches; then smooth movement naturally.
    if camera:GetAttribute("ChaosVisualAIBot") ~= bot.Name then
        camera.CFrame = desired
        camera:SetAttribute("ChaosVisualAIBot", bot.Name)
    else
        camera.CFrame = camera.CFrame:Lerp(desired, math.clamp(dt * 9, 0, 1))
    end
    camera.Focus = CFrame.new(eye)
end)

task.spawn(function()
    local readyDeadline = os.clock() + 28
    while os.clock() < readyDeadline and #availableBots() < 1 do
        task.wait(0.15)
    end

    if #availableBots() == 0 then
        report:FireServer({kind = "failure", error = "No living autonomous AI model available"})
        restore()
        return
    end

    print("CHAOS_VISUAL_AI_CLIENT_READY")
    -- Capture genuine active gameplay, not fourteen lobby/result frames
    -- and one accidental in-round sample. The Studio server lengthens
    -- only this opt-in round so all fifteen spaced PNGs can be in-round.
    local roundDeadline = os.clock() + 50
    while os.clock() < roundDeadline do
        if phase == "round" and actualArena() == expectedArena
            and #liveRoundBots() >= 2 then
            break
        end
        task.wait(0.15)
    end
    if phase ~= "round" or actualArena() ~= expectedArena
        or #liveRoundBots() < 2 then
        report:FireServer({
            kind = "failure",
            error = "No verified live " .. expectedArena .. " AI round available",
        })
        restore()
        return
    end

    for index = 1, count do
        local bots = liveRoundBots()
        if #bots == 0 then
            report:FireServer({kind = "failure", error = "All AI subjects unavailable"})
            restore()
            return
        end

        -- Five samples per actual AI survivor; alternating views reveal
        -- locomotion, full-body silhouette, ground hazards and sightlines.
        local group = math.floor((index - 1) / 5)
        local desiredSlot = (group % #bots) + 1
        if currentBot ~= bots[desiredSlot] then
            currentBot = bots[desiredSlot]
        end
        currentMode = ((index - 1) % 5 == 4) and "POV"
            or (((index - 1) % 5 == 2) and "SIDE" or "CHASE")
        sampleIndex = index
        proofLabel.Text = string.format(
            "REAL %s AI  %02d/%02d   |   %s   |   %s / %s",
            expectedArena, index, count, tostring(currentBot and currentBot.Name),
            string.upper(phase), currentMode
        )

        -- Let the camera settle before the Windows runner captures pixels.
        task.wait(index == 1 and 1 or 0.18)
        local camera = workspace.CurrentCamera
        local root = currentBot and currentBot:FindFirstChild("HumanoidRootPart")
        local viewport = camera and camera.ViewportSize or Vector2.zero
        local guiRoot = player:FindFirstChildOfClass("PlayerGui")
        local vote = guiRoot and guiRoot:FindFirstChild("VotePanel", true)
        local practiceGui = guiRoot and guiRoot:FindFirstChild("LobbyTimeTrialUI")
        local practice = practiceGui and practiceGui:FindFirstChildOfClass("Frame")
        report:FireServer({
            kind = "frame",
            index = index,
            phase = phase,
            arenaVariant = actualArena(),
            bot = currentBot and currentBot.Name or "",
            mode = currentMode,
            viewport = viewport,
            cameraPosition = camera and camera.CFrame.Position or Vector3.zero,
            botPosition = root and root.Position or Vector3.zero,
            renderedFrames = renderFrames,
            fps = totalDt > 0 and renderFrames / totalDt or 0,
            inRound = currentBot and currentBot:GetAttribute("AISurvivorInRound") == true,
            voteVisible = vote and vote:IsA("GuiObject") and vote.Visible or false,
            practiceVisible = practice and practice.Visible or false,
        })
        print(string.format(
            "CHAOS_VISUAL_AI_FRAME %02d/%02d arena=%s bot=%s mode=%s phase=%s viewport=%dx%d",
            index, count, tostring(actualArena()),
            tostring(currentBot and currentBot.Name), currentMode,
            phase, viewport.X, viewport.Y
        ))
        if index < count then
            task.wait(math.max(0.1, interval - 0.18))
        end
    end
    -- Keep the last bot's authentic camera and on-screen provenance
    -- visible longer than the SERVER's 18-second closing grace. The
    -- Windows collector still certifies its own 15th PNG/hash and PASS;
    -- restoring at 12 seconds could instead capture the local spectator.
    task.wait(22)
    restore()
end)
