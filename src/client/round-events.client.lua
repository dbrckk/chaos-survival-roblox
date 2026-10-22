local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local RoundEventPresentation = require(ReplicatedStorage.Shared.RoundEventPresentation)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
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
title.Text = CoreLocalization.text(localeId, "OVERDRIVE")
title.TextColor3 = UITheme.Colors.Text
title.TextScaled = true
title.Parent = card

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -28, 0.28, 0)
subtitle.Position = UDim2.new(0, 14, 0.64, 0)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.GothamBold
subtitle.Text = CoreLocalization.text(localeId, "OVERDRIVE_SUB")
subtitle.TextColor3 = UITheme.Colors.Muted
subtitle.TextScaled = true
subtitle.TextWrapped = true
subtitle.Parent = card

local scale = Instance.new("UIScale")
scale.Scale = 0.80
scale.Parent = card

UITheme.addTextConstraint(title, 15, 30)
UITheme.addTextConstraint(subtitle, 12, 18)

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
local activePriority = 0
local activeUntil = 0
local lastOverdrive = false
local lastFinalRush = false
local lastImpactWaveMode = nil
local lastDoubleCollapseUnlocked = false
local lastSpeedTempoPhase = nil
local lastFusionKey = nil
local previousPhase = "waiting"
local touchDevice = UserInputService.TouchEnabled

local function applyResponsive()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

    if touchDevice then
        local profile = UIResponsive.mobileProfile(viewport)
        -- Keep escalation notifications below the round header, but above
        -- the avatar and the ground warnings. A brief compact toast is
        -- preferable to a second full-width central announcement.
        card.Position = UDim2.fromScale(0.5, profile.tinyHeight and 0.37 or 0.34)
        card.Size = UDim2.new(profile.veryNarrow and 0.76 or 0.54, 0, 0, profile.tinyHeight and 52 or 56)
        size.MinSize = Vector2.new(220, 50)
        size.MaxSize = Vector2.new(470, 64)
    else
        card.Position = UDim2.fromScale(0.5, 0.27)
        card.Size = UDim2.new(0.54, 0, 0, 74)
        size.MinSize = Vector2.new(250, 62)
        size.MaxSize = Vector2.new(520, 82)
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

    -- Mobile gameplay never needs a full-screen flash. Keep the brief
    -- colored edge cue, and honor reduced-motion on all platforms.
    if quality().Name ~= "Low" and not touchDevice and not reduceMotion then
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

-- Any pending notification and its delayed hide callback are invalid
-- as soon as a round finishes or the local survivor is eliminated.
local function clearRoundToast()
    token += 1
    activePriority = 0
    activeUntil = 0
    card.Visible = false
    card.BackgroundTransparency = 1
    stroke.Transparency = 1
    title.TextTransparency = 1
    subtitle.TextTransparency = 1
    scale.Scale = 1
    flash.Visible = false
    flash.BackgroundTransparency = 1
    edgeTop.BackgroundTransparency = 1
    edgeBottom.BackgroundTransparency = 1
end

player:GetAttributeChangedSignal("RoundEliminated"):Connect(function()
    if player:GetAttribute("RoundEliminated") == true
        and previousPhase == "round" then
        clearRoundToast()
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    local phase = tostring(state.phase or "waiting")
    if RoundEventPresentation.shouldClearRoundToast(
        previousPhase, phase, player:GetAttribute("RoundEliminated") == true
    ) then
        clearRoundToast()
    end
    local overdrive = phase == "round" and state.overdrive == true
    local finalRush = phase == "round" and state.finalRush == true
    local speedTempoPhase = phase == "round"
        and (state.speedTempoPhase == "Surge" or state.speedTempoPhase == "Recover")
        and state.speedTempoPhase or nil
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

    if finalRush and not lastFinalRush then
        show(
            "finalRush",
            CoreLocalization.text(localeId, "FINAL_RUSH"),
            CoreLocalization.text(localeId, "FINAL_RUSH_SUB"),
            UITheme.Colors.Orange,
            1.05
        )
    elseif overdrive and not lastOverdrive then
        show(
            "overdrive",
            CoreLocalization.text(localeId, "OVERDRIVE"),
            CoreLocalization.text(localeId, "OVERDRIVE_SUB"),
            UITheme.Colors.Gold,
            1.20
        )
    elseif phase == "round" and state.impactWaveMode
        and state.impactWaveMode ~= lastImpactWaveMode
        and player:GetAttribute("RoundParticipant") == true
        and player:GetAttribute("RoundEliminated") ~= true
    then
        -- Use the existing brief mobile-safe toast, never a second HUD
        -- or additional world flash. Final Rush/Overdrive retain priority.
        local sweep = state.impactWaveMode == "Sweep"
        local flanks = state.impactWaveMode == "Flanks"
        if sweep or flanks then
            local key = sweep and "IMPACT_WAVE_SWEEP" or "IMPACT_WAVE_FLANKS"
            show(
                "impactWave",
                CoreLocalization.text(localeId, key),
                CoreLocalization.text(localeId, key .. "_SUB"),
                sweep and UITheme.Colors.Orange or UITheme.Colors.Red,
                0.95
            )
        end
    elseif phase == "round" and state.doubleCollapseUnlocked == true
        and not lastDoubleCollapseUnlocked
        and player:GetAttribute("RoundParticipant") == true
        and player:GetAttribute("RoundEliminated") ~= true
    then
        -- Announce a real server-staged double-deck warning once. The
        -- original yellow contours remain the essential, local cue.
        show(
            "collapseWave",
            CoreLocalization.text(localeId, "DOUBLE_COLLAPSE"),
            CoreLocalization.text(localeId, "DOUBLE_COLLAPSE_SUB"),
            UITheme.Colors.Orange,
            0.95
        )
    elseif phase == "round" and speedTempoPhase ~= nil
        and lastSpeedTempoPhase ~= nil
        and speedTempoPhase ~= lastSpeedTempoPhase
        and player:GetAttribute("RoundParticipant") == true
        and player:GetAttribute("RoundEliminated") ~= true
    then
        -- No round-start spam. Only announce a real change in the
        -- server-authoritative stage, using the existing mobile-safe toast.
        local recovering = speedTempoPhase == "Recover"
        local key = recovering and "SPEED_TEMPO_RECOVER" or "SPEED_TEMPO_SURGE"
        show(
            "speedTempo",
            CoreLocalization.text(localeId, key),
            CoreLocalization.text(localeId, key .. "_SUB"),
            recovering and UITheme.Colors.Cyan or UITheme.Colors.Gold,
            0.95
        )
    end

    lastSpeedTempoPhase = speedTempoPhase
    lastImpactWaveMode = phase == "round" and state.impactWaveMode or nil
    lastDoubleCollapseUnlocked = phase == "round"
        and state.doubleCollapseUnlocked == true
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
