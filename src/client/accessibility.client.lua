local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local FirstTimeExperience = require(ReplicatedStorage.Shared.FirstTimeExperience)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local AudioMixRules = require(ReplicatedStorage.Shared.AudioMixRules)
local BuildIdentity = require(ReplicatedStorage.Shared.BuildIdentity)
local MobileHudNotices = require(ReplicatedStorage.Shared.MobileHudNotices)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("RoundState")
local accessibilityEvent = remotes:WaitForChild("AccessibilitySettings")

local gui = Instance.new("ScreenGui")
gui.Name = "AccessibilityQuickSettings"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 17
gui.Parent = player:WaitForChild("PlayerGui")

local toggle = Instance.new("TextButton")
toggle.Name = "SettingsToggle"
toggle.AnchorPoint = Vector2.new(1, 0)
toggle.Position = UDim2.fromScale(0.985, 0.03)
toggle.Size = UserInputService.TouchEnabled
    and UDim2.fromOffset(168, 44)
    or UDim2.fromOffset(150, 36)
toggle.BackgroundColor3 = UITheme.Colors.PanelRaised
toggle.BackgroundTransparency = 0.06
toggle.BorderSizePixel = 0
toggle.Font = Enum.Font.GothamBold
toggle.TextScaled = true
toggle.TextColor3 = UITheme.Colors.Text
toggle.AutoButtonColor = false
toggle.Visible = false
toggle.Parent = gui
UITheme.addCorner(toggle, UITheme.Corners.Pill)
UITheme.addStroke(toggle, UITheme.Colors.Cyan, 1.0, 0.45)
UITheme.addPressFeedback(toggle, 0.96)
UITheme.addTextConstraint(toggle, 11, 16)

local panel = Instance.new("ScrollingFrame")
panel.Name = "SettingsPanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.fromScale(0.985, 0.09)
panel.Size = UDim2.fromOffset(190, 160)
panel.BackgroundColor3 = UITheme.Colors.Panel
panel.BackgroundTransparency = 0.03
panel.BorderSizePixel = 0
panel.ScrollBarThickness = 3
panel.ScrollingDirection = Enum.ScrollingDirection.Y
panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
panel.CanvasSize = UDim2.fromOffset(0, 0)
panel.ClipsDescendants = true
panel.Visible = false
panel.Parent = gui
UITheme.addCorner(panel, UITheme.Corners.Medium)
UITheme.addStroke(panel, UITheme.Colors.Border, 1.0, 0.42)

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = panel

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.PaddingTop = UDim.new(0, 7)
padding.PaddingBottom = UDim.new(0, 7)
padding.Parent = panel

local function makeSettingButton(name)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, 0, 0, UserInputService.TouchEnabled and 44 or 36)
    button.BackgroundColor3 = UITheme.Colors.PanelRaised
    button.BackgroundTransparency = 0.06
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.TextScaled = true
    button.TextColor3 = UITheme.Colors.Text
    button.AutoButtonColor = false
    button.Parent = panel
    UITheme.addCorner(button, UITheme.Corners.Pill)
    local stroke = UITheme.addStroke(button, UITheme.Colors.Cyan, 1.0, 0.45)
    UITheme.addPressFeedback(button, 0.96)
    UITheme.addTextConstraint(button, 10, 15)
    return button, stroke
end

local motionButton, motionStroke = makeSettingButton("ReduceMotionToggle")
local soundButton, soundStroke = makeSettingButton("AudioToggle")
local hapticsButton, hapticsStroke = makeSettingButton("HapticsToggle")
local perfButton, perfStroke = makeSettingButton("PerformanceOverlayToggle")
motionButton.LayoutOrder = 1
soundButton.LayoutOrder = 2
hapticsButton.LayoutOrder = 3
perfButton.LayoutOrder = 6

-- Dedicated tap-safe buttons instead of precision sliders: every change
-- is an explicit, server-validated 10% step. No per-frame input polling.
local function makeVolumeRow(name, order)
    local row = Instance.new("Frame")
    row.Name = name
    row.LayoutOrder = order
    row.Size = UDim2.new(1, 0, 0, UserInputService.TouchEnabled and 44 or 36)
    row.BackgroundTransparency = 1
    row.Parent = panel

    local function stepButton(direction, atRight)
        local button = Instance.new("TextButton")
        button.Name = atRight and "Increase" or "Decrease"
        button.AnchorPoint = Vector2.new(atRight and 1 or 0, 0)
        button.Position = UDim2.fromScale(atRight and 1 or 0, 0)
        button.Size = UDim2.new(0, UserInputService.TouchEnabled and 44 or 36, 1, 0)
        button.BackgroundColor3 = UITheme.Colors.PanelRaised
        button.BorderSizePixel = 0
        button.Text = direction
        button.TextScaled = true
        button.Font = Enum.Font.GothamBold
        button.TextColor3 = UITheme.Colors.Text
        button.Parent = row
        UITheme.addCorner(button, UITheme.Corners.Small)
        UITheme.addTextConstraint(button, 14, 20)
        UITheme.addPressFeedback(button, 0.95)
        return button
    end
    local decrease = stepButton("-", false)
    local increase = stepButton("+", true)
    local label = Instance.new("TextLabel")
    label.Name = "VolumeLabel"
    label.Position = UDim2.new(0, UserInputService.TouchEnabled and 47 or 39, 0, 0)
    label.Size = UDim2.new(1, -(UserInputService.TouchEnabled and 94 or 78), 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = UITheme.Colors.Text
    label.TextScaled = true
    label.Parent = row
    UITheme.addTextConstraint(label, 10, 14)
    return label, decrease, increase
end

local musicLabel, musicDecrease, musicIncrease =
    makeVolumeRow("MusicVolumeControl", 4)
local effectsLabel, effectsDecrease, effectsIncrease =
    makeVolumeRow("EffectsVolumeControl", 5)

-- Visible only inside Settings, never over the playfield. An Android
-- tester can read the actual packaged revision without the Studio console.
-- SOURCE/UNSTAMPED explicitly means the place was not built by GitHub CI.
local buildIdentity = Instance.new("TextLabel")
buildIdentity.Name = "BuildIdentityLabel"
buildIdentity.LayoutOrder = 7
buildIdentity.Size = UDim2.new(1, 0, 0, 20)
buildIdentity.BackgroundTransparency = 1
buildIdentity.BorderSizePixel = 0
buildIdentity.Font = Enum.Font.GothamMedium
buildIdentity.TextSize = 10
buildIdentity.TextColor3 = UITheme.Colors.Muted
buildIdentity.TextXAlignment = Enum.TextXAlignment.Center
local buildChannels = {
    CANDIDATE = "RC",
    STAGING = "STAGE",
    PUBLIC_PLAYTEST = "TEST",
    PRODUCTION = "LIVE",
    SOURCE = "DEV",
}
local buildChannel = tostring(BuildIdentity.Channel or "SOURCE")
buildIdentity.Text = "BUILD " .. tostring(BuildIdentity.SourceSha or "UNSTAMPED"):sub(1, 12)
    .. " / " .. (buildChannels[buildChannel] or "DEV")
buildIdentity.Parent = panel

-- This optional label uses the EXISTING 2.5-second VFX sampler. It has no
-- RenderStepped connection, new RemoteEvent or touch-intercepting controls.
-- The setting is session-local and off by default, including on public servers.
local performanceEnabled = false
local performanceFits = false
local performanceLabel = Instance.new("TextLabel")
performanceLabel.Name = "OptionalPerformanceOverlay"
performanceLabel.AnchorPoint = Vector2.new(0, 0)
performanceLabel.Size = UDim2.fromOffset(176, 48)
performanceLabel.BackgroundColor3 = UITheme.Colors.Panel
performanceLabel.BackgroundTransparency = 0.26
performanceLabel.BorderSizePixel = 0
performanceLabel.Font = Enum.Font.GothamBold
performanceLabel.TextColor3 = UITheme.Colors.Text
performanceLabel.TextSize = 12
performanceLabel.TextXAlignment = Enum.TextXAlignment.Center
performanceLabel.TextYAlignment = Enum.TextYAlignment.Center
performanceLabel.TextWrapped = false
performanceLabel.Active = false
performanceLabel.Selectable = false
performanceLabel.Visible = false
performanceLabel.Parent = gui
UITheme.addCorner(performanceLabel, UITheme.Corners.Small)
UITheme.addStroke(performanceLabel, UITheme.Colors.Border, 1, 0.56)

local function displayMetric(value)
    return type(value) == "number" and value >= 0
        and value < math.huge and tostring(math.floor(value + 0.5)) or "--"
end

local function refreshPerformance()
    performanceLabel.Visible = UIResponsive.showPerformanceOverlay(
        performanceEnabled, performanceFits, MobileHudNotices.current()
    )
    if not performanceLabel.Visible then return end
    local fps = displayMetric(player:GetAttribute("ClientObservedFps"))
    local p95 = displayMetric(player:GetAttribute("ClientObservedP95FrameMs"))
    local slow = displayMetric(player:GetAttribute("ClientObservedSlowFramePercent"))
    local tier = tostring(player:GetAttribute("VfxQualityTier") or "Medium")
    if tier ~= "High" and tier ~= "Medium" and tier ~= "Low" then
        tier = "Medium"
    end
    performanceLabel.Text = string.format(
        "FPS %s  P95 %sms\nSLOW %s%%  %s",
        fps, p95, slow, string.upper(tier)
    )
    local actualP95 = player:GetAttribute("ClientObservedP95FrameMs")
    local actualSlow = player:GetAttribute("ClientObservedSlowFramePercent")
    local struggling = (type(actualP95) == "number"
        and actualP95 >= 50) or (type(actualSlow) == "number"
        and actualSlow >= 10)
    performanceLabel.TextColor3 = struggling
        and UITheme.Colors.Orange or UITheme.Colors.Text
end

-- A MOMENTUM combo and a diagnostic HUD use the same small left-side
-- space. Always yield instantly to the notification owner. On release,
-- restore only if the player explicitly enabled diagnostics.
MobileHudNotices.Changed:Connect(refreshPerformance)

local currentPhase = "waiting"
local voteVisible = false
local viewportConnection = nil

local function available()
    local criticalPhase = currentPhase == "ready"
        or currentPhase == "round"
        or currentPhase == "result"
    return player:GetAttribute("DataLoaded") == true
        and not criticalPhase
        and not voteVisible
end

local function applyResponsive()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local profile = UIResponsive.mobileProfile(viewport)
    local perfLayout = UIResponsive.mobilePerformanceOverlay(viewport)
    performanceFits = perfLayout.fits
    performanceLabel.Position = UDim2.fromOffset(
        perfLayout.leftInset, perfLayout.topOffset
    )
    performanceLabel.Size = UDim2.fromOffset(
        perfLayout.width, perfLayout.height
    )
    refreshPerformance()

    if UserInputService.TouchEnabled then
        local width = profile.veryNarrow and 156 or 168
        toggle.Size = UDim2.fromOffset(width, 44)
        toggle.Position = UDim2.new(1, -10, 0, profile.topHeight + 18)
        local top = profile.topHeight + 68
        panel.Size = UDim2.fromOffset(math.max(190, width + 18),
            math.max(104, math.min(330, viewport.Y - top - 12)))
        panel.Position = UDim2.new(1, -10, 0, top)
    else
        toggle.Size = UDim2.fromOffset(150, 36)
        toggle.Position = UDim2.fromScale(0.985, 0.03)
        local top = math.floor(viewport.Y * 0.085)
        panel.Size = UDim2.fromOffset(200,
            math.max(104, math.min(285, viewport.Y - top - 12)))
        panel.Position = UDim2.new(1, -12, 0, top)
    end
end

local function refresh()
    local reduced = player:GetAttribute("ReduceMotion") == true
    local muted = player:GetAttribute("AudioMuted") == true
    local hapticsDisabled = player:GetAttribute("HapticsDisabled") == true
    perfButton.Text = performanceEnabled and "FPS / P95 : ON" or "FPS / P95 : OFF"
    perfStroke.Color = performanceEnabled and UITheme.Colors.Green
        or UITheme.Colors.Cyan
    perfButton.BackgroundColor3 = performanceEnabled
        and UITheme.Colors.Green:Lerp(UITheme.Colors.Panel, 0.78)
        or UITheme.Colors.PanelRaised
    local musicPercent = AudioMixRules.percent(player:GetAttribute("MusicVolume"))
    local effectsPercent = AudioMixRules.percent(player:GetAttribute("EffectsVolume"))

    musicLabel.Text = CoreLocalization.text(localeId, "MUSIC_VOLUME", musicPercent)
    effectsLabel.Text = CoreLocalization.text(localeId, "EFFECTS_VOLUME", effectsPercent)
    musicDecrease.Active = musicPercent > 0
    musicIncrease.Active = musicPercent < 100
    effectsDecrease.Active = effectsPercent > 0
    effectsIncrease.Active = effectsPercent < 100
    musicDecrease.TextTransparency = musicPercent == 0 and 0.55 or 0
    musicIncrease.TextTransparency = musicPercent == 100 and 0.55 or 0
    effectsDecrease.TextTransparency = effectsPercent == 0 and 0.55 or 0
    effectsIncrease.TextTransparency = effectsPercent == 100 and 0.55 or 0

    toggle.Text = CoreLocalization.text(localeId, "SETTINGS")

    motionButton.Text = CoreLocalization.text(
        localeId,
        reduced and "MOTION_REDUCED" or "MOTION_FULL"
    )
    motionStroke.Color = reduced and UITheme.Colors.Green or UITheme.Colors.Cyan
    motionButton.BackgroundColor3 = reduced
        and UITheme.Colors.Green:Lerp(UITheme.Colors.Panel, 0.72)
        or UITheme.Colors.PanelRaised

    soundButton.Text = CoreLocalization.text(
        localeId,
        muted and "SOUND_OFF" or "SOUND_ON"
    )
    soundStroke.Color = muted and UITheme.Colors.Orange or UITheme.Colors.Green
    soundButton.BackgroundColor3 = muted
        and UITheme.Colors.Orange:Lerp(UITheme.Colors.Panel, 0.78)
        or UITheme.Colors.Green:Lerp(UITheme.Colors.Panel, 0.78)

    hapticsButton.Text = CoreLocalization.text(
        localeId,
        hapticsDisabled and "HAPTICS_OFF" or "HAPTICS_ON"
    )
    hapticsStroke.Color = hapticsDisabled and UITheme.Colors.Orange or UITheme.Colors.Green
    hapticsButton.BackgroundColor3 = hapticsDisabled
        and UITheme.Colors.Orange:Lerp(UITheme.Colors.Panel, 0.78)
        or UITheme.Colors.Green:Lerp(UITheme.Colors.Panel, 0.78)

    local visible = available()
    toggle.Visible = visible
    if not visible then
        panel.Visible = false
    end

    applyResponsive()
end

local function bindCamera()
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end

    local camera = workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsive)
    end
    applyResponsive()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()

toggle.Activated:Connect(function()
    if not available() then
        panel.Visible = false
        return
    end
    panel.Visible = not panel.Visible
end)

motionButton.Activated:Connect(function()
    local nextValue = player:GetAttribute("ReduceMotion") ~= true
    player:SetAttribute("ReduceMotion", nextValue)
    accessibilityEvent:FireServer("ReduceMotion", nextValue)
    refresh()
end)

soundButton.Activated:Connect(function()
    local nextValue = player:GetAttribute("AudioMuted") ~= true
    player:SetAttribute("AudioMuted", nextValue)
    accessibilityEvent:FireServer("AudioMuted", nextValue)
    refresh()
end)

hapticsButton.Activated:Connect(function()
    local nextValue = player:GetAttribute("HapticsDisabled") ~= true
    player:SetAttribute("HapticsDisabled", nextValue)
    accessibilityEvent:FireServer("HapticsDisabled", nextValue)
    refresh()
end)

perfButton.Activated:Connect(function()
    if not available() then return end
    performanceEnabled = not performanceEnabled
    -- Local display only; never persist a developer-style overlay on
    -- another device or require any server-side permissions.
    refresh()
    refreshPerformance()
end)

for _, attribute in ipairs({
    "ClientObservedFps",
    "ClientObservedP95FrameMs",
    "ClientObservedSlowFramePercent",
    "VfxQualityTier",
}) do
    player:GetAttributeChangedSignal(attribute):Connect(refreshPerformance)
end

local lastVolumeChange = {}
local function changeVolume(setting, delta)
    if not available() then return end
    local now = os.clock()
    if now - (lastVolumeChange[setting] or -100) < 0.38 then return end
    local current = AudioMixRules.percent(player:GetAttribute(setting))
    local nextValue = math.clamp(current + delta, 0, 100)
    if nextValue == current then return end
    lastVolumeChange[setting] = now
    player:SetAttribute(setting, nextValue)
    accessibilityEvent:FireServer(setting, nextValue)
    refresh()
end
musicDecrease.Activated:Connect(function() changeVolume("MusicVolume", -10) end)
musicIncrease.Activated:Connect(function() changeVolume("MusicVolume", 10) end)
effectsDecrease.Activated:Connect(function() changeVolume("EffectsVolume", -10) end)
effectsIncrease.Activated:Connect(function() changeVolume("EffectsVolume", 10) end)

for _, attribute in ipairs({
    "ReduceMotion",
    "AudioMuted",
    "HapticsDisabled",
    "MusicVolume",
    "EffectsVolume",
    "Games",
    "DataLoaded",
}) do
    player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

stateEvent.OnClientEvent:Connect(function(state)
    -- A missing, empty or malformed ballot is not an active vote.
    -- Preserve the last valid snapshot if a malformed packet arrives.
    if type(state) ~= "table" then return end
    currentPhase = tostring(state.phase or "waiting")
    voteVisible = currentPhase == "intermission"
        and FirstTimeExperience.hasVoteOptions(state)
    refresh()
end)

refresh()
