local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalizationService = game:GetService("LocalizationService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local localeId = LocalizationService.RobloxLocaleId

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosBootSplash"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.Parent = playerGui

local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(6, 9, 16)
backdrop.BorderSizePixel = 0
backdrop.Active = true
backdrop.Parent = gui

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 14, 24)),
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(14, 18, 34)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(23, 13, 34)),
})
gradient.Rotation = 18
gradient.Parent = backdrop

local glow = Instance.new("Frame")
glow.Name = "Glow"
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.Position = UDim2.fromScale(0.5, 0.44)
glow.Size = UDim2.fromScale(0.64, 0.40)
glow.BackgroundColor3 = UITheme.Colors.Cyan
glow.BackgroundTransparency = 0.90
glow.BorderSizePixel = 0
glow.Parent = backdrop
UITheme.addCorner(glow, UDim.new(1, 0))

local glowGradient = Instance.new("UIGradient")
glowGradient.Color = ColorSequence.new(
    UITheme.Colors.Cyan,
    UITheme.Colors.Violet
)
glowGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.34),
    NumberSequenceKeypoint.new(0.5, 0.10),
    NumberSequenceKeypoint.new(1, 0.42),
})
glowGradient.Parent = glow

local card = Instance.new("Frame")
card.Name = "BrandCard"
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.48)
card.Size = UDim2.new(0.70, 0, 0, 180)
card.BackgroundColor3 = UITheme.Colors.Panel
card.BackgroundTransparency = 0.12
card.BorderSizePixel = 0
card.Parent = backdrop
UITheme.addCorner(card, UDim.new(0, 24))
UITheme.addStroke(card, UITheme.Colors.Cyan, 1.4, 0.38)
UITheme.addGradient(card, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(280, 154)
sizeConstraint.MaxSize = Vector2.new(680, 190)
sizeConstraint.Parent = card

local scale = Instance.new("UIScale")
scale.Scale = 0.96
scale.Parent = card

local kicker = Instance.new("TextLabel")
kicker.Name = "Kicker"
kicker.Position = UDim2.fromScale(0.07, 0.10)
kicker.Size = UDim2.fromScale(0.86, 0.14)
kicker.BackgroundTransparency = 1
kicker.Font = Enum.Font.GothamBold
kicker.Text = CoreLocalization.text(localeId, "ENTER_ARENA")
kicker.TextColor3 = UITheme.Colors.Cyan
kicker.TextScaled = true
kicker.Parent = card
UITheme.addTextConstraint(kicker, 11, 16)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.fromScale(0.06, 0.27)
title.Size = UDim2.fromScale(0.88, 0.30)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "CHAOS SURVIVAL"
title.TextColor3 = UITheme.Colors.Text
title.TextScaled = true
title.Parent = card
UITheme.addTextConstraint(title, 26, 48)

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Position = UDim2.fromScale(0.08, 0.59)
subtitle.Size = UDim2.fromScale(0.84, 0.12)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamMedium
subtitle.Text = CoreLocalization.text(localeId, "SURVIVE_ADAPT_ESCAPE")
subtitle.TextColor3 = UITheme.Colors.Muted
subtitle.TextScaled = true
subtitle.Parent = card
UITheme.addTextConstraint(subtitle, 10, 15)

local track = Instance.new("Frame")
track.Name = "ProgressTrack"
track.Position = UDim2.fromScale(0.10, 0.78)
track.Size = UDim2.fromScale(0.80, 0.045)
track.BackgroundColor3 = UITheme.Colors.PanelSoft
track.BackgroundTransparency = 0.18
track.BorderSizePixel = 0
track.Parent = card
UITheme.addCorner(track, UDim.new(1, 0))

local fill = Instance.new("Frame")
fill.Name = "ProgressFill"
fill.Size = UDim2.fromScale(0.08, 1)
fill.BackgroundColor3 = UITheme.Colors.Cyan
fill.BorderSizePixel = 0
fill.Parent = track
UITheme.addCorner(fill, UDim.new(1, 0))

local fillGradient = Instance.new("UIGradient")
fillGradient.Color = ColorSequence.new(UITheme.Colors.Cyan, UITheme.Colors.Violet)
fillGradient.Parent = fill

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Position = UDim2.fromScale(0.10, 0.845)
status.Size = UDim2.fromScale(0.80, 0.09)
status.BackgroundTransparency = 1
status.Font = Enum.Font.GothamBold
status.Text = CoreLocalization.text(localeId, "SYNCING_PROGRESS")
status.TextColor3 = UITheme.Colors.Muted
status.TextScaled = true
status.Parent = card
UITheme.addTextConstraint(status, 9, 13)

local reduceMotion = player:GetAttribute("ReduceMotion") == true
local startedAt = os.clock()
local finished = false

if not reduceMotion then
    TweenService:Create(
        scale,
        TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()
end

TweenService:Create(
    fill,
    TweenInfo.new(1.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    {Size = UDim2.fromScale(0.72, 1)}
):Play()

local function fadeOut()
    if finished then
        return
    end
    finished = true

    local elapsed = os.clock() - startedAt
    local minimumHold = 0.72
    if elapsed < minimumHold then
        task.wait(minimumHold - elapsed)
    end

    status.Text = CoreLocalization.text(localeId, "READY")
    status.TextColor3 = UITheme.Colors.Green
    TweenService:Create(
        fill,
        TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.fromScale(1, 1)}
    ):Play()

    task.wait(0.18)

    local fade = TweenInfo.new(
        reduceMotion and 0.12 or 0.24,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )

    TweenService:Create(backdrop, fade, {BackgroundTransparency = 1}):Play()
    TweenService:Create(card, fade, {BackgroundTransparency = 1}):Play()
    TweenService:Create(glow, fade, {BackgroundTransparency = 1}):Play()

    for _, descendant in ipairs(card:GetDescendants()) do
        if descendant:IsA("TextLabel") then
            TweenService:Create(descendant, fade, {TextTransparency = 1}):Play()
        elseif descendant:IsA("Frame") then
            TweenService:Create(descendant, fade, {BackgroundTransparency = 1}):Play()
        elseif descendant:IsA("UIStroke") then
            TweenService:Create(descendant, fade, {Transparency = 1}):Play()
        end
    end

    task.wait((reduceMotion and 0.12 or 0.24) + 0.04)
    gui:Destroy()
end

local function dataReady()
    return player:GetAttribute("DataLoaded") == true
end

if dataReady() then
    task.spawn(fadeOut)
else
    local connection
    connection = player:GetAttributeChangedSignal("DataLoaded"):Connect(function()
        if dataReady() then
            if connection then
                connection:Disconnect()
                connection = nil
            end
            task.spawn(fadeOut)
        end
    end)

    task.delay(2.4, function()
        if finished then
            return
        end
        if connection then
            connection:Disconnect()
            connection = nil
        end
        status.Text = CoreLocalization.text(localeId, "ENTERING_ARENA")
        task.spawn(fadeOut)
    end)
end
