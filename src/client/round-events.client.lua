local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosRoundEvents"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 27
gui.Parent = player:WaitForChild("PlayerGui")

local flash = Instance.new("Frame")
flash.Name = "EventFlash"
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = UITheme.Colors.Cyan
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Visible = false
flash.Parent = gui

local flashGradient = Instance.new("UIGradient")
flashGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.72),
    NumberSequenceKeypoint.new(0.18, 0.96),
    NumberSequenceKeypoint.new(0.82, 0.96),
    NumberSequenceKeypoint.new(1, 0.72),
})
flashGradient.Rotation = 90
flashGradient.Parent = flash

local card = Instance.new("Frame")
card.Name = "EventCard"
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.27)
card.Size = UDim2.new(0.54, 0, 0, 74)
card.BackgroundColor3 = UITheme.Colors.Panel
card.BackgroundTransparency = 1
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui
UITheme.addCorner(card, UITheme.Corners.Large)

local size = Instance.new("UISizeConstraint")
size.MinSize = Vector2.new(250, 62)
size.MaxSize = Vector2.new(520, 82)
size.Parent = card

local stroke = UITheme.addStroke(card, UITheme.Colors.Cyan, 1.8, 1)
local gradient = UITheme.addGradient(card, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local accent = Instance.new("Frame")
accent.AnchorPoint = Vector2.new(0.5, 0)
accent.Position = UDim2.fromScale(0.5, 0.08)
accent.Size = UDim2.new(0.84, 0, 0, 4)
accent.BackgroundColor3 = UITheme.Colors.Cyan
accent.BorderSizePixel = 0
accent.Parent = card
UITheme.addCorner(accent, UITheme.Corners.Pill)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0.52, 0)
title.Position = UDim2.fromOffset(12, 7)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "OVERDRIVE"
title.TextColor3 = UITheme.Colors.Text
title.TextScaled = true
title.Parent = card

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -28, 0.28, 0)
subtitle.Position = UDim2.new(0, 14, 0.64, 0)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamBold
subtitle.Text = "BOOST PADS • SHARD SURGE"
subtitle.TextColor3 = UITheme.Colors.Muted
subtitle.TextScaled = true
subtitle.TextWrapped = true
subtitle.Parent = card

local scale = Instance.new("UIScale")
scale.Scale = 0.80
scale.Parent = card

local token = 0
local lastOverdrive = false
local lastFinalRush = false
local lastFusionKey = nil

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function show(mainText, subText, color, duration)
    token += 1
    local current = token

    title.Text = mainText
    subtitle.Text = subText
    accent.BackgroundColor3 = color
    stroke.Color = color
    gradient.Color = ColorSequence.new(
        color:Lerp(UITheme.Colors.PanelRaised, 0.72),
        UITheme.Colors.Panel
    )

    card.Visible = true
    card.BackgroundTransparency = 1
    stroke.Transparency = 1
    title.TextTransparency = 1
    subtitle.TextTransparency = 1
    scale.Scale = 0.80

    TweenService:Create(card, TweenInfo.new(0.16), {BackgroundTransparency = 0.06}):Play()
    TweenService:Create(stroke, TweenInfo.new(0.16), {Transparency = 0.16}):Play()
    TweenService:Create(title, TweenInfo.new(0.13), {TextTransparency = 0}):Play()
    TweenService:Create(subtitle, TweenInfo.new(0.13), {TextTransparency = 0}):Play()
    TweenService:Create(
        scale,
        TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()

    if quality().Name ~= "Low" then
        flash.BackgroundColor3 = color
        flash.Visible = true
        flash.BackgroundTransparency = 0.90
        TweenService:Create(
            flash,
            TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        ):Play()
    end

    task.delay(duration or 1.15, function()
        if current ~= token then
            return
        end

        TweenService:Create(card, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.18), {Transparency = 1}):Play()
        TweenService:Create(title, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
        TweenService:Create(subtitle, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
        TweenService:Create(scale, TweenInfo.new(0.18), {Scale = 0.90}):Play()

        task.wait(0.20)
        if current == token then
            card.Visible = false
            flash.Visible = false
        end
    end)
end

stateEvent.OnClientEvent:Connect(function(state)
    local phase = tostring(state.phase or "waiting")
    local overdrive = phase == "round" and state.overdrive == true
    local finalRush = phase == "round" and state.finalRush == true
    local fusionName = type(state.fusionName) == "string" and state.fusionName or nil
    local fusionKey = state.doubleChaos and fusionName or nil

    if finalRush and not lastFinalRush then
        show(
            "FINAL RUSH",
            "LAST 5 SECONDS • PADS RECHARGE FASTER",
            UITheme.Colors.Orange,
            1.05
        )
    elseif overdrive and not lastOverdrive then
        show(
            "OVERDRIVE",
            "BOOST PADS • SHARD SURGE • GOLDEN SHARD",
            UITheme.Colors.Gold,
            1.20
        )
    elseif fusionKey and fusionKey ~= lastFusionKey and (phase == "ready" or phase == "round") then
        show(
            tostring(fusionName),
            "CHAOS FUSION • TWO HAZARDS • +5 SURVIVAL BONUS",
            UITheme.Colors.Violet,
            1.35
        )
    end

    lastOverdrive = overdrive
    lastFinalRush = finalRush
    lastFusionKey = fusionKey
end)
