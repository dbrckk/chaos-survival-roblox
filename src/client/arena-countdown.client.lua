local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local gui = Instance.new("BillboardGui")
gui.Name = "ArenaCountdown"
gui.ResetOnSpawn = false
gui.AlwaysOnTop = true
gui.LightInfluence = 0
gui.Size = UDim2.fromOffset(220, 110)
gui.StudsOffsetWorldSpace = Vector3.new(0, 4.2, 0)
gui.MaxDistance = 150
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBlack
label.Text = "3"
label.TextColor3 = UITheme.Colors.Text
label.TextStrokeColor3 = UITheme.Colors.Cyan
label.TextStrokeTransparency = 0.18
label.TextScaled = true
label.Parent = gui

local scale = Instance.new("UIScale")
scale.Scale = 0.7
scale.Parent = label

local token = 0
local lastPhase = "waiting"
local lastSecond = nil

local function centerBeacon()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local decor = arena and arena:FindFirstChild("Decor")
    local beacon = decor and decor:FindFirstChild("CenterBeacon")
    return beacon and beacon:IsA("BasePart") and beacon or nil
end

local function accentFor(state)
    if state.doubleChaos then
        return UITheme.Colors.Violet
    end

    local primary = state.disasterIds and state.disasterIds[1]
    return UITheme.disasterAccent(primary, UITheme.Colors.Cyan)
end

local function pulse(text, color, hold)
    token += 1
    local current = token

    gui.Adornee = centerBeacon()
    if not gui.Adornee then
        gui.Enabled = false
        return
    end

    label.Text = text
    label.TextStrokeColor3 = color
    label.TextTransparency = 1
    scale.Scale = 0.62
    gui.Enabled = true

    TweenService:Create(
        label,
        TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    ):Play()
    TweenService:Create(
        scale,
        TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = text == "GO!" and 1.15 or 1}
    ):Play()

    task.delay(hold or 0.68, function()
        if current ~= token then
            return
        end
        TweenService:Create(
            label,
            TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {TextTransparency = 1}
        ):Play()
        TweenService:Create(
            scale,
            TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Scale = 1.28}
        ):Play()

        task.wait(0.18)
        if current == token then
            gui.Enabled = false
        end
    end)
end

stateEvent.OnClientEvent:Connect(function(state)
    local phase = tostring(state.phase or "waiting")
    local second = math.max(0, math.floor(tonumber(state.seconds) or 0))
    local accent = accentFor(state)

    if phase == "ready" and second > 0 and second ~= lastSecond then
        pulse(tostring(second), accent, 0.64)
        lastSecond = second
    elseif phase == "round" and lastPhase == "ready" then
        pulse("GO!", state.doubleChaos and UITheme.Colors.Magenta or accent, 0.72)
        lastSecond = nil
    elseif phase ~= "ready" and phase ~= "round" then
        token += 1
        gui.Enabled = false
        lastSecond = nil
    end

    lastPhase = phase
end)
