local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)

local player = Players.LocalPlayer
local touchDevice = UserInputService.TouchEnabled
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosRoundFocus"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 18
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Name = "FocusBar"
root.AnchorPoint = Vector2.new(0.5, touchDevice and 0.5 or 1)
root.Position = touchDevice
    and UDim2.fromScale(0.5, 0.77)
    or UDim2.new(0.5, 0, 1, -18)
root.Size = touchDevice
    and UDim2.new(0.62, 0, 0, 48)
    or UDim2.new(0.82, 0, 0, 54)
root.BackgroundColor3 = UITheme.Colors.Panel
root.BackgroundTransparency = 0.05
root.BorderSizePixel = 0
root.Visible = false
root.Parent = gui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(250, 48)
sizeConstraint.MaxSize = Vector2.new(620, 58)
sizeConstraint.Parent = root

UITheme.addCorner(root, UITheme.Corners.Large)
local stroke = UITheme.addStroke(root, UITheme.Colors.Blue, 1.2, 0.30)
UITheme.addGradient(root, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local accentRail = Instance.new("Frame")
accentRail.Name = "DisasterAccent"
accentRail.AnchorPoint = Vector2.new(0.5, 0)
accentRail.Position = UDim2.fromScale(0.5, 0)
accentRail.Size = UDim2.new(0.90, 0, 0, 4)
accentRail.BackgroundColor3 = UITheme.Colors.Cyan
accentRail.BorderSizePixel = 0
accentRail.Parent = root
UITheme.addCorner(accentRail, UITheme.Corners.Pill)

local scale = Instance.new("UIScale")
scale.Scale = 0.96
scale.Parent = root

local shard = Instance.new("TextLabel")
shard.Name = "ShardCount"
shard.Position = UDim2.fromScale(0.025, 0.12)
shard.Size = UDim2.fromScale(0.27, 0.43)
shard.BackgroundColor3 = UITheme.Colors.PanelSoft
shard.BackgroundTransparency = 0.16
shard.BorderSizePixel = 0
shard.Font = Enum.Font.GothamBlack
shard.Text = "SHARDS  0"
shard.TextColor3 = UITheme.Colors.Cyan
shard.TextScaled = true
shard.TextXAlignment = Enum.TextXAlignment.Left
shard.Parent = root
UITheme.addCorner(shard, UITheme.Corners.Pill)

local challenge = Instance.new("TextLabel")
challenge.Name = "RoundChallenge"
challenge.Position = UDim2.fromScale(0.31, 0.12)
challenge.Size = UDim2.fromScale(0.32, 0.43)
challenge.BackgroundColor3 = UITheme.Colors.PanelSoft
challenge.BackgroundTransparency = 0.18
challenge.BorderSizePixel = 0
challenge.Font = Enum.Font.GothamBold
challenge.Text = "ROUND CHALLENGE"
challenge.TextColor3 = UITheme.Colors.Muted
challenge.TextScaled = true
challenge.TextWrapped = true
challenge.Parent = root
UITheme.addCorner(challenge, UITheme.Corners.Pill)

local status = Instance.new("TextLabel")
status.Name = "Status"
status.AnchorPoint = Vector2.new(1, 0)
status.Position = UDim2.fromScale(0.975, 0.12)
status.Size = UDim2.fromScale(0.36, 0.43)
status.BackgroundColor3 = UITheme.Colors.PanelSoft
status.BackgroundTransparency = 0.18
status.BorderSizePixel = 0
status.Font = Enum.Font.GothamBold
status.Text = "STABLE"
status.TextColor3 = UITheme.Colors.Muted
status.TextScaled = true
status.TextXAlignment = Enum.TextXAlignment.Right
status.Parent = root
UITheme.addCorner(status, UITheme.Corners.Pill)

local barBg = Instance.new("Frame")
barBg.Name = "IntensityBackground"
barBg.Position = UDim2.fromScale(0.025, 0.68)
barBg.Size = UDim2.fromScale(0.95, 0.14)
barBg.BackgroundColor3 = UITheme.Colors.PanelSoft
barBg.BackgroundTransparency = 0.08
barBg.BorderSizePixel = 0
barBg.Parent = root

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(1, 0)
bgCorner.Parent = barBg

local fill = Instance.new("Frame")
fill.Name = "IntensityFill"
fill.Size = UDim2.fromScale(0.08, 1)
fill.BackgroundColor3 = UITheme.Colors.Blue
fill.BorderSizePixel = 0
fill.Parent = barBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 190, 255)),
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(175, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 85, 70)),
})
gradient.Parent = fill


local function applyResponsiveLayout()
    if not touchDevice then
        root.AnchorPoint = Vector2.new(0.5, 1)
        root.Position = UDim2.new(0.5, 0, 1, -18)
        root.Size = UDim2.new(0.82, 0, 0, 54)
        return
    end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local aspect = viewport.Y > 0 and (viewport.X / viewport.Y) or 1.78
    local narrow = aspect < 1.7
    local wide = aspect > 2.0

    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.Position = UDim2.fromScale(0.5, narrow and 0.75 or 0.77)
    root.Size = UDim2.new(
        narrow and 0.70 or (wide and 0.55 or 0.62),
        0,
        0,
        narrow and 50 or 48
    )
end

applyResponsiveLayout()

local responsiveCamera = workspace.CurrentCamera
if responsiveCamera then
    responsiveCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveLayout)
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    responsiveCamera = workspace.CurrentCamera
    if responsiveCamera then
        applyResponsiveLayout()
        responsiveCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveLayout)
    end
end)

local currentState = nil
local visibleToken = 0
local completedChallengeId = nil

local function shardCount()
    return math.max(0, math.floor(tonumber(player:GetAttribute("RoundChaosShards")) or 0))
end

local function challengeProgress(state)
    local metric = state and state.challengeMetric
    if metric == "shards" then
        return math.max(0, math.floor(tonumber(player:GetAttribute("RoundChaosShards")) or 0))
    elseif metric == "pads" then
        return math.max(0, math.floor(tonumber(player:GetAttribute("RoundMechanicUses")) or 0))
    elseif metric == "nearMisses" then
        return math.max(0, math.floor(tonumber(player:GetAttribute("RoundNearMisses")) or 0))
    elseif metric == "momentum" then
        return math.max(0, math.floor(tonumber(player:GetAttribute("RoundMomentumBest")) or 0))
    end
    return 0
end

local function intensityLabel(value, seconds)
    if seconds <= 5 then
        return "FINAL RUSH", Color3.fromRGB(255, 105, 92)
    elseif value >= 1.18 then
        return "MAX CHAOS", Color3.fromRGB(245, 115, 190)
    elseif value >= 1.08 then
        return "DANGER RISING", Color3.fromRGB(235, 175, 105)
    end
    return "CHAOS BUILDING", Color3.fromRGB(205, 220, 240)
end

local function refresh()
    local state = currentState
    local isParticipant = player:GetAttribute("RoundParticipant") == true
    local isEliminated = player:GetAttribute("RoundEliminated") == true

    if not state or state.phase ~= "round" or not isParticipant or isEliminated then
        if root.Visible then
            visibleToken += 1
            local token = visibleToken
            TweenService:Create(root, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
            TweenService:Create(scale, TweenInfo.new(0.18), {Scale = 0.9}):Play()
            task.delay(0.2, function()
                if token == visibleToken then
                    root.Visible = false
                    root.BackgroundTransparency = 0.12
                end
            end)
        end
        return
    end

    if not root.Visible then
        visibleToken += 1
        root.Visible = true
        root.BackgroundTransparency = 1
        scale.Scale = 0.9
        TweenService:Create(root, TweenInfo.new(0.2), {BackgroundTransparency = 0.12}):Play()
        TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    end

    local count = shardCount()
    shard.Text = count == 1 and "SHARD  1" or ("SHARDS  " .. count)

    local challengeId = state.challengeId
    local challengeTarget = math.max(1, math.floor(tonumber(state.challengeTarget) or 1))
    local progress = math.min(challengeTarget, challengeProgress(state))
    if state.finalRush then
        challenge.Text = "SURVIVE"
        challenge.TextColor3 = UITheme.Colors.Orange
        challenge.BackgroundColor3 = UITheme.Colors.Red:Lerp(UITheme.Colors.PanelSoft, 0.82)
        completedChallengeId = nil
    elseif challengeId then
        local completed = progress >= challengeTarget
        challenge.Text = completed
            and ("DONE  " .. tostring(state.challengeShort or "CHALLENGE"))
            or string.format("%s  %d/%d", tostring(state.challengeShort or "CHALLENGE"), progress, challengeTarget)
        challenge.TextColor3 = completed and UITheme.Colors.Green or UITheme.Colors.Text

        if completed and completedChallengeId ~= challengeId then
            completedChallengeId = challengeId
            challenge.BackgroundColor3 = UITheme.Colors.Green:Lerp(UITheme.Colors.PanelSoft, 0.68)
            scale.Scale = 1.05
            TweenService:Create(scale, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        elseif not completed then
            completedChallengeId = nil
            challenge.BackgroundColor3 = UITheme.Colors.PanelSoft
        end
    else
        challenge.Text = "ROUND CHALLENGE"
        challenge.TextColor3 = UITheme.Colors.Muted
        challenge.BackgroundColor3 = UITheme.Colors.PanelSoft
        completedChallengeId = nil
    end

    local intensity = math.clamp(tonumber(state.intensity) or 1, 0.85, 1.25)
    local normalized = math.clamp((intensity - 0.85) / 0.40, 0.08, 1)
    TweenService:Create(
        fill,
        TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.fromScale(normalized, 1)}
    ):Play()

    local text, color = intensityLabel(intensity, tonumber(state.seconds) or 0)
    if state.finalRush then
        text = "FINAL RUSH  " .. tostring(math.max(0, math.floor(tonumber(state.seconds) or 0))) .. "s"
        color = UITheme.Colors.Red
    elseif state.overdrive then
        text = "OVERDRIVE  " .. tostring(math.max(1, math.floor(tonumber(state.overdriveSeconds) or 1))) .. "s"
        color = UITheme.Colors.Gold
    elseif state.doubleChaos then
        text = "CHAOS FUSION"
        color = UITheme.Colors.Violet
    end
    status.Text = text
    status.TextColor3 = color

    local primaryId = state.disasterIds and state.disasterIds[1]
    local disasterAccent = UITheme.disasterAccent(primaryId, UITheme.Colors.Cyan)
    accentRail.BackgroundColor3 = disasterAccent
    fill.BackgroundColor3 = disasterAccent
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, disasterAccent),
        ColorSequenceKeypoint.new(0.55, disasterAccent:Lerp(UITheme.Colors.Violet, 0.45)),
        ColorSequenceKeypoint.new(1, UITheme.Colors.Red),
    })

    if state.finalRush then
        stroke.Color = UITheme.Colors.Red
        accentRail.BackgroundColor3 = UITheme.Colors.Orange
        shard.TextColor3 = UITheme.Colors.Orange
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, UITheme.Colors.Orange),
            ColorSequenceKeypoint.new(0.5, UITheme.Colors.Red),
            ColorSequenceKeypoint.new(1, UITheme.Colors.Magenta),
        })
    elseif state.overdrive then
        stroke.Color = UITheme.Colors.Gold
        accentRail.BackgroundColor3 = UITheme.Colors.Gold
        shard.TextColor3 = UITheme.Colors.Gold
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, UITheme.Colors.Gold),
            ColorSequenceKeypoint.new(0.55, UITheme.Colors.Cyan),
            ColorSequenceKeypoint.new(1, UITheme.Colors.Violet),
        })
    elseif state.doubleChaos then
        stroke.Color = UITheme.Colors.Violet
        shard.TextColor3 = Color3.fromRGB(215, 165, 255)
    else
        stroke.Color = disasterAccent
        shard.TextColor3 = disasterAccent
    end
end

player:GetAttributeChangedSignal("RoundParticipant"):Connect(refresh)
player:GetAttributeChangedSignal("RoundEliminated"):Connect(refresh)

player:GetAttributeChangedSignal("RoundNearMisses"):Connect(refresh)
player:GetAttributeChangedSignal("RoundMechanicUses"):Connect(refresh)
player:GetAttributeChangedSignal("RoundMomentumBest"):Connect(refresh)

player:GetAttributeChangedSignal("RoundChaosShards"):Connect(function()
    local previous = shard.Text
    refresh()

    if root.Visible and shard.Text ~= previous then
        shard.TextTransparency = 0.1
        TweenService:Create(
            shard,
            TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 0}
        ):Play()

        scale.Scale = 1.04
        TweenService:Create(
            scale,
            TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1}
        ):Play()
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    currentState = state
    refresh()
end)
