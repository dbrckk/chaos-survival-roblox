local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local UITheme = require(ReplicatedStorage.Shared.UITheme)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "LobbyTimeTrialLocal"
folder.Parent = workspace

local gui = Instance.new("ScreenGui")
gui.Name = "LobbyTimeTrialUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 17
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.fromScale(0.5, 0.18)
card.Size = UDim2.new(0.34, 0, 0, 48)
card.BackgroundColor3 = UITheme.Colors.Panel
card.BackgroundTransparency = 0.08
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui
UITheme.addCorner(card, UITheme.Corners.Pill)
local cardStroke = UITheme.addStroke(card, UITheme.Colors.Cyan, 1.2, 0.34)

local constraint = Instance.new("UISizeConstraint")
constraint.MinSize = Vector2.new(220, 44)
constraint.MaxSize = Vector2.new(390, 54)
constraint.Parent = card

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBlack
label.Text = "PRACTICE COURSE  •  1/4"
label.TextColor3 = UITheme.Colors.Text
label.TextScaled = true
label.Parent = card

local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = card

local offsets = {
    Vector3.new(-27, 2.4, -19),
    Vector3.new(27, 2.4, -19),
    Vector3.new(27, 2.4, 19),
    Vector3.new(-27, 2.4, 19),
}

local checkpointParts = {}
local currentIndex = 1
local startedAt = nil
local bestTime = nil
local activePhase = false
local updateClock = 0
local completedToken = 0

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function makeCheckpoint(index, offset)
    local part = Instance.new("Part")
    part.Name = "PracticeCheckpoint" .. index
    part.Shape = Enum.PartType.Cylinder
    part.Size = Vector3.new(0.18, 8.5, 8.5)
    part.CFrame = CFrame.new(Config.LobbyCenter + offset)
        * CFrame.Angles(0, 0, math.rad(90))
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Color = index == 1 and UITheme.Colors.Cyan or UITheme.Colors.Violet
    part.Transparency = 0.72
    part.Parent = folder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CheckpointLabel"
    billboard.Adornee = part
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.Size = UDim2.fromOffset(86, 28)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 4.8, 0)
    billboard.MaxDistance = 80
    billboard.Parent = folder

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundColor3 = UITheme.Colors.Panel
    text.BackgroundTransparency = 0.18
    text.BorderSizePixel = 0
    text.Font = Enum.Font.GothamBlack
    text.Text = "CHECK " .. index
    text.TextColor3 = part.Color
    text.TextScaled = true
    text.Parent = billboard
    UITheme.addCorner(text, UITheme.Corners.Pill)

    checkpointParts[index] = {
        part = part,
        billboard = billboard,
        text = text,
    }
end

for index, offset in ipairs(offsets) do
    makeCheckpoint(index, offset)
end

local function resetCourse()
for _, bundle in ipairs(checkpointParts) do
    bundle.part.Transparency = 1
    bundle.billboard.Enabled = false
end
    currentIndex = 1
    startedAt = nil

    for index, bundle in ipairs(checkpointParts) do
        bundle.part.Color = index == 1 and UITheme.Colors.Cyan or UITheme.Colors.Violet
        bundle.part.Transparency = index == 1 and 0.34 or 0.78
        bundle.text.TextColor3 = bundle.part.Color
        bundle.text.Text = index == 1 and "START" or ("CHECK " .. index)
    end

    label.Text = bestTime
        and string.format("PRACTICE COURSE  •  START  •  BEST %.2fs", bestTime)
        or "PRACTICE COURSE  •  TOUCH START"
end

local function pulseCard(color)
    cardStroke.Color = color
    scale.Scale = 1.06
    TweenService:Create(
        scale,
        TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()
end

local function completeCheckpoint()
    local now = os.clock()

    if currentIndex == 1 and not startedAt then
        startedAt = now
    end

    local bundle = checkpointParts[currentIndex]
    if bundle then
        bundle.part.Transparency = 0.88
        bundle.text.Text = "DONE"
        bundle.text.TextColor3 = UITheme.Colors.Green
    end

    if currentIndex >= #checkpointParts then
        local elapsed = startedAt and math.max(0, now - startedAt) or 0
        if not bestTime or elapsed < bestTime then
            bestTime = elapsed
            label.Text = string.format("NEW BEST  •  %.2fs", elapsed)
            pulseCard(UITheme.Colors.Gold)
        else
            label.Text = string.format("FINISH  •  %.2fs  •  BEST %.2fs", elapsed, bestTime)
            pulseCard(UITheme.Colors.Green)
        end

        completedToken += 1
        local token = completedToken
        task.delay(2.0, function()
            if token == completedToken then
                resetCourse()
            end
        end)
        return
    end

    currentIndex += 1
    local nextBundle = checkpointParts[currentIndex]
    nextBundle.part.Color = UITheme.Colors.Cyan
    nextBundle.part.Transparency = 0.32
    nextBundle.text.Text = "NEXT"
    nextBundle.text.TextColor3 = UITheme.Colors.Cyan
    pulseCard(UITheme.Colors.Cyan)
end

local function setActive(active)
    activePhase = active
    card.Visible = active

    for _, bundle in ipairs(checkpointParts) do
        bundle.part.Transparency = active and bundle.part.Transparency or 1
        bundle.billboard.Enabled = active
    end

    if active then
        resetCourse()
    else
        completedToken += 1
        startedAt = nil
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    local phase = tostring(state.phase or "waiting")
    local shouldBeActive = phase == "waiting" or phase == "intermission"
    if shouldBeActive ~= activePhase then
        setActive(shouldBeActive)
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    local tier = quality()
    for index, bundle in ipairs(checkpointParts) do
        bundle.billboard.MaxDistance = tier.Name == "Low" and 58 or 80
        if activePhase and index ~= currentIndex then
            bundle.part.Transparency = tier.Name == "Low" and 0.88 or 0.78
        end
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if not activePhase then
        return
    end

    updateClock += dt
    if updateClock < 0.10 then
        return
    end
    updateClock = 0

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local bundle = checkpointParts[currentIndex]
    if not root or not root:IsA("BasePart") or not bundle then
        return
    end

    local distance = (root.Position - bundle.part.Position).Magnitude
    if distance <= 5.4 then
        completeCheckpoint()
    elseif startedAt then
        local elapsed = os.clock() - startedAt
        label.Text = string.format(
            "PRACTICE COURSE  •  %d/%d  •  %.2fs",
            currentIndex,
            #checkpointParts,
            elapsed
        )
    end
end)

resetCourse()
