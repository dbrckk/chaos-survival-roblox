local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("HazardNearMiss")

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosNearMiss"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 28
gui.Parent = player:WaitForChild("PlayerGui")

local flash = Instance.new("Frame")
flash.Name = "EdgeFlash"
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(255, 185, 90)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Visible = false
flash.Parent = gui

local gradient = Instance.new("UIGradient")
gradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.35),
    NumberSequenceKeypoint.new(0.18, 0.92),
    NumberSequenceKeypoint.new(0.82, 0.92),
    NumberSequenceKeypoint.new(1, 0.35),
})
gradient.Rotation = 90
gradient.Parent = flash

local card = Instance.new("Frame")
card.Name = "NearMissCard"
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.34)
card.Size = UDim2.new(0.48, 0, 0, 62)
card.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
card.BackgroundTransparency = 1
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(220, 54)
sizeConstraint.MaxSize = Vector2.new(420, 72)
sizeConstraint.Parent = card

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = card

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 185, 90)
stroke.Thickness = 1.5
stroke.Transparency = 0.35
stroke.Parent = card

local scale = Instance.new("UIScale")
scale.Scale = 0.82
scale.Parent = card

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0.55, 0)
title.Position = UDim2.fromOffset(12, 5)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "CLOSE CALL!"
title.TextColor3 = Color3.fromRGB(255, 225, 165)
title.TextScaled = true
title.Parent = card

local detail = Instance.new("TextLabel")
detail.Size = UDim2.new(1, -24, 0.30, 0)
detail.Position = UDim2.new(0, 12, 0.62, 0)
detail.BackgroundTransparency = 1
detail.Font = Enum.Font.GothamBold
detail.Text = ""
detail.TextColor3 = Color3.fromRGB(215, 220, 235)
detail.TextScaled = true
detail.Parent = card

local combo = 0
local lastNearMissAt = 0
local token = 0

local function readableKind(kind)
    local value = tostring(kind or "HAZARD")
    value = value:gsub("([a-z])([A-Z])", "%1 %2")
    return string.upper(value)
end

local function show(payload)
    local now = os.clock()
    if now - lastNearMissAt <= 5 then
        combo += 1
    else
        combo = 1
    end
    lastNearMissAt = now

    token += 1
    local current = token

    local distance = tonumber(payload.distance)
    local radius = tonumber(payload.radius)
    local dangerRatio = nil
    if distance and radius and radius > 0 then
        dangerRatio = math.clamp(distance / radius, 0, 2)
    end

    title.Text = combo >= 2 and ("CLOSE CALL  x" .. tostring(combo)) or "CLOSE CALL!"
    detail.Text = readableKind(payload.kind)
    if dangerRatio then
        detail.Text ..= string.format("  •  %.1fx EDGE", dangerRatio)
    end

    card.Visible = true
    card.BackgroundTransparency = 1
    scale.Scale = 0.82
    flash.Visible = true
    flash.BackgroundTransparency = 0.88

    TweenService:Create(
        card,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.08}
    ):Play()
    TweenService:Create(
        scale,
        TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()
    TweenService:Create(
        flash,
        TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1}
    ):Play()

    task.delay(0.85, function()
        if current ~= token then
            return
        end

        TweenService:Create(
            card,
            TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}
        ):Play()
        TweenService:Create(
            scale,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Scale = 0.90}
        ):Play()

        task.wait(0.21)
        if current == token then
            card.Visible = false
            flash.Visible = false
        end
    end)
end

event.OnClientEvent:Connect(show)
