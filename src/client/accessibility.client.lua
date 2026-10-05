local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)

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

local panel = Instance.new("Frame")
panel.Name = "SettingsPanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.fromScale(0.985, 0.09)
panel.Size = UDim2.fromOffset(190, 100)
panel.BackgroundColor3 = UITheme.Colors.Panel
panel.BackgroundTransparency = 0.03
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
UITheme.addCorner(panel, UITheme.Corners.Medium)
UITheme.addStroke(panel, UITheme.Colors.Border, 1.0, 0.42)

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
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
    button.Size = UDim2.new(1, 0, 0, UserInputService.TouchEnabled and 38 or 34)
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

local currentPhase = "waiting"
local voteVisible = false
local viewportConnection = nil

local function available()
    local criticalPhase = currentPhase == "ready"
        or currentPhase == "round"
        or currentPhase == "result"
    local experienced = math.max(0, tonumber(player:GetAttribute("Games")) or 0) > 0

    return player:GetAttribute("DataLoaded") == true
        and experienced
        and not criticalPhase
        and not voteVisible
end

local function applyResponsive()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local profile = UIResponsive.mobileProfile(viewport)

    if UserInputService.TouchEnabled then
        local width = profile.veryNarrow and 156 or 168
        toggle.Size = UDim2.fromOffset(width, 44)
        toggle.Position = UDim2.new(1, -10, 0, profile.topHeight + 18)
        panel.Size = UDim2.fromOffset(math.max(176, width + 18), 100)
        panel.Position = UDim2.new(1, -10, 0, profile.topHeight + 68)
    else
        toggle.Size = UDim2.fromOffset(150, 36)
        toggle.Position = UDim2.fromScale(0.985, 0.03)
        panel.Size = UDim2.fromOffset(178, 92)
        panel.Position = UDim2.fromScale(0.985, 0.085)
    end
end

local function refresh()
    local reduced = player:GetAttribute("ReduceMotion") == true
    local muted = player:GetAttribute("AudioMuted") == true

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

for _, attribute in ipairs({
    "ReduceMotion",
    "AudioMuted",
    "Games",
    "DataLoaded",
}) do
    player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

stateEvent.OnClientEvent:Connect(function(state)
    currentPhase = tostring(state.phase or "waiting")
    voteVisible = state.voteOptions ~= nil
    refresh()
end)

refresh()
