local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local RoundEventPresentation = require(ReplicatedStorage.Shared.RoundEventPresentation)

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

UITheme.addTextConstraint(title, 15, 30)
UITheme.addTextConstraint(subtitle, 12, 18)

local countdown = Instance.new("TextLabel")
countdown.Name = "ReadyCountdown"
countdown.AnchorPoint = Vector2.new(0.5, 0.5)
countdown.Position = UDim2.fromScale(0.5, 0.46)
countdown.Size = UDim2.fromOffset(150, 150)
countdown.BackgroundTransparency = 1
countdown.Font = Enum.Font.GothamBlack
countdown.Text = "3"
countdown.TextColor3 = UITheme.Colors.Text
countdown.TextScaled = true
countdown.TextTransparency = 1
countdown.Visible = false
countdown.ZIndex = 4
countdown.Parent = gui
UITheme.addTextConstraint(countdown, 42, 92)
local countdownStroke = Instance.new("UIStroke")
countdownStroke.Thickness = 3
countdownStroke.Color = UITheme.Colors.Cyan
countdownStroke.Transparency = 1
countdownStroke.Parent = countdown
local countdownScale = Instance.new("UIScale")
countdownScale.Scale = 1
countdownScale.Parent = countdown

local edgeTop = Instance.new("Frame")
edgeTop.Name = "EventEdgeTop"
edgeTop.AnchorPoint = Vector2.new(0.5, 0)
edgeTop.Position = UDim2.fromScale(0.5, 0)
edgeTop.Size = UDim2.new(0, 0, 0, 4)
edgeTop.BackgroundColor3 = UITheme.Colors.Cyan
edgeTop.BackgroundTransparency = 1
edgeTop.BorderSizePixel = 0
edgeTop.ZIndex = 3
edgeTop.Parent = gui

local edgeBottom = edgeTop:Clone()
edgeBottom.Name = "EventEdgeBottom"
edgeBottom.AnchorPoint = Vector2.new(0.5, 1)
edgeBottom.Position = UDim2.fromScale(0.5, 1)
edgeBottom.Parent = gui

local token = 0
local countdownToken = 0
local activePriority = 0
local activeUntil = 0
local lastOverdrive = false
local lastFinalRush = false
local lastFusionKey = nil
local previousPhase = "waiting"
local lastReadySecond = nil
local touchDevice = UserInputService.TouchEnabled

local function applyResponsive()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

    if touchDevice then
        local profile = UIResponsive.mobileProfile(viewport)
        card.Position = UDim2.fromScale(0.5, profile.tinyHeight and 0.42 or 0.34)
        card.Size = UDim2.new(profile.veryNarrow and 0.90 or 0.72, 0, 0, profile.tinyHeight and 66 or 74)
        countdown.Position = UDim2.fromScale(0.5, profile.tinyHeight and 0.58 or 0.50)
        countdown.Size = UDim2.fromOffset(
            profile.tinyHeight and 118 or 140,
            profile.tinyHeight and 118 or 140
        )
    else
        card.Position = UDim2.fromScale(0.5, 0.27)
        card.Size = UDim2.new(0.54, 0, 0, 74)
        countdown.Position = UDim2.fromScale(0.5, 0.46)
        countdown.Size = UDim2.fromOffset(150, 150)
    end
end

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function show(kind, mainText, subText, color, duration)
    local priority = RoundEventPresentation.priority(kind)
    local now = os.clock()
    if now < activeUntil and priority < activePriority then
        return false
    end

    token += 1
    local current = token
    activePriority = priority
    activeUntil = now + (duration or 1.15) + 0.22

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
    local reduceMotion = player:GetAttribute("ReduceMotion") == true
    scale.Scale = reduceMotion and 0.96 or 0.80

    edgeTop.BackgroundColor3 = color
    edgeBottom.BackgroundColor3 = color
    edgeTop.BackgroundTransparency = 0.12
    edgeBottom.BackgroundTransparency = 0.12
    edgeTop.Size = reduceMotion and UDim2.new(0.86, 0, 0, 3) or UDim2.new(0, 0, 0, 4)
    edgeBottom.Size = edgeTop.Size

    TweenService:Create(
        edgeTop,
        TweenInfo.new(reduceMotion and 0.12 or 0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0.86, 0, 0, 3)}
    ):Play()
    TweenService:Create(
        edgeBottom,
        TweenInfo.new(reduceMotion and 0.12 or 0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0.86, 0, 0, 3)}
    ):Play()

    TweenService:Create(card, TweenInfo.new(0.16), {BackgroundTransparency = 0.06}):Play()
    TweenService:Create(stroke, TweenInfo.new(0.16), {Transparency = 0.16}):Play()
    TweenService:Create(title, TweenInfo.new(0.13), {TextTransparency = 0}):Play()
    TweenService:Create(subtitle, TweenInfo.new(0.13), {TextTransparency = 0}):Play()
    TweenService:Create(
        scale,
        reduceMotion
            and TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            or TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
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
        TweenService:Create(edgeTop, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
        TweenService:Create(edgeBottom, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
        TweenService:Create(stroke, TweenInfo.new(0.18), {Transparency = 1}):Play()
        TweenService:Create(title, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
        TweenService:Create(subtitle, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
        TweenService:Create(scale, TweenInfo.new(0.18), {Scale = 0.90}):Play()

        task.wait(0.20)
        if current == token then
            card.Visible = false
            flash.Visible = false
            activePriority = 0
            activeUntil = 0
        end
    end)

    return true
end

local function showCountdown(value, color)
    countdownToken += 1
    local current = countdownToken
    local reduceMotion = player:GetAttribute("ReduceMotion") == true

    countdown.Text = tostring(value)
    countdown.TextColor3 = UITheme.Colors.Text
    countdownStroke.Color = color
    countdown.Visible = true
    countdown.TextTransparency = 1
    countdownStroke.Transparency = 1
    countdownScale.Scale = reduceMotion and 1 or 1.30

    TweenService:Create(
        countdown,
        TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    ):Play()
    TweenService:Create(
        countdownStroke,
        TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Transparency = 0.08}
    ):Play()

    if not reduceMotion then
        TweenService:Create(
            countdownScale,
            TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1}
        ):Play()
    end

    task.delay(0.48, function()
        if current ~= countdownToken then
            return
        end
        TweenService:Create(countdown, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
        TweenService:Create(countdownStroke, TweenInfo.new(0.18), {Transparency = 1}):Play()
        task.wait(0.18)
        if current == countdownToken then
            countdown.Visible = false
        end
    end)
end

stateEvent.OnClientEvent:Connect(function(state)
    local phase = tostring(state.phase or "waiting")
    local overdrive = phase == "round" and state.overdrive == true
    local finalRush = phase == "round" and state.finalRush == true
    local fusionName = type(state.fusionName) == "string" and state.fusionName or nil
    local fusionKey = state.doubleChaos and fusionName or nil
    local eventColor = RoundEventPresentation.accent(
        state.disasterIds,
        function(id)
            return UITheme.disasterAccent(id, UITheme.Colors.Cyan)
        end
    )

    -- The primary ready countdown/reveal is owned by ChaosHUD.
    -- Keep this layer reserved for mid-round escalation events so mobile
    -- never receives stacked countdowns or duplicate round-start cards.
    lastReadySecond = nil

    if finalRush and not lastFinalRush then
        show(
            "finalRush",
            "FINAL RUSH",
            "LAST 5 SECONDS • PADS RECHARGE FASTER",
            UITheme.Colors.Orange,
            1.05
        )
    elseif overdrive and not lastOverdrive then
        show(
            "overdrive",
            "OVERDRIVE",
            "BOOST PADS • SHARD SURGE • GOLDEN SHARD",
            UITheme.Colors.Gold,
            1.20
        )
    end

    lastOverdrive = overdrive
    lastFinalRush = finalRush
    lastFusionKey = fusionKey
    previousPhase = phase
end)


applyResponsive()

local responsiveCamera = nil
local viewportConnection = nil

local function bindResponsiveCamera(camera)
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end

    responsiveCamera = camera
    if responsiveCamera then
        applyResponsive()
        viewportConnection = responsiveCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsive)
    end
end

bindResponsiveCamera(workspace.CurrentCamera)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    bindResponsiveCamera(workspace.CurrentCamera)
end)
