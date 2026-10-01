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

local scale = Instance.new("UIScale")
scale.Scale = 0.96
scale.Parent = root

local shard = Instance.new("TextLabel")
shard.Name = "ShardCount"
shard.Position = UDim2.fromScale(0.025, 0.12)
shard.Size = UDim2.fromScale(0.27, 0.43)
shard.BackgroundTransparency = 1
shard.Font = Enum.Font.GothamBlack
shard.Text = "SHARDS  0"
shard.TextColor3 = UITheme.Colors.Cyan
shard.TextScaled = true
shard.TextXAlignment = Enum.TextXAlignment.Left
shard.Parent = root

local status = Instance.new("TextLabel")
status.Name = "Status"
status.AnchorPoint = Vector2.new(1, 0)
status.Position = UDim2.fromScale(0.975, 0.12)
status.Size = UDim2.fromScale(0.36, 0.43)
status.BackgroundTransparency = 1
status.Font = Enum.Font.GothamBold
status.Text = "STABLE"
status.TextColor3 = UITheme.Colors.Muted
status.TextScaled = true
status.TextXAlignment = Enum.TextXAlignment.Right
status.Parent = root

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

local currentState = nil
local visibleToken = 0

local function shardCount()
    return math.max(0, math.floor(tonumber(player:GetAttribute("RoundChaosShards")) or 0))
end

local function intensityLabel(value, seconds)
    if seconds <= 5 then
        return "FINAL SECONDS", Color3.fromRGB(255, 105, 92)
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

    local intensity = math.clamp(tonumber(state.intensity) or 1, 0.85, 1.25)
    local normalized = math.clamp((intensity - 0.85) / 0.40, 0.08, 1)
    TweenService:Create(
        fill,
        TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.fromScale(normalized, 1)}
    ):Play()

    local text, color = intensityLabel(intensity, tonumber(state.seconds) or 0)
    status.Text = text
    status.TextColor3 = color

    if state.doubleChaos then
        stroke.Color = UITheme.Colors.Violet
        shard.TextColor3 = Color3.fromRGB(215, 165, 255)
    else
        stroke.Color = UITheme.Colors.Blue
        shard.TextColor3 = UITheme.Colors.Cyan
    end
end

player:GetAttributeChangedSignal("RoundParticipant"):Connect(refresh)
player:GetAttributeChangedSignal("RoundEliminated"):Connect(refresh)

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
