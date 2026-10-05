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
gui.IgnoreGuiInset = true
gui.DisplayOrder = 17
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Name = "ReduceMotionToggle"
button.AnchorPoint = Vector2.new(1, 0)
button.Position = UDim2.fromScale(0.985, 0.03)
button.Size = UserInputService.TouchEnabled
    and UDim2.fromOffset(190, 44)
    or UDim2.fromScale(0.17, 0.04)
button.BackgroundColor3 = UITheme.Colors.PanelRaised
button.BackgroundTransparency = 0.06
button.BorderSizePixel = 0
button.Font = Enum.Font.GothamBold
button.TextScaled = true
button.TextColor3 = UITheme.Colors.Text
button.AutoButtonColor = false
button.Visible = false
button.Parent = gui
UITheme.addCorner(button, UITheme.Corners.Pill)
local stroke = UITheme.addStroke(button, UITheme.Colors.Cyan, 1.0, 0.45)
UITheme.addPressFeedback(button, 0.96)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(150, UserInputService.TouchEnabled and 44 or 30)
sizeConstraint.MaxSize = Vector2.new(220, 48)
sizeConstraint.Parent = button

local soundButton = Instance.new("TextButton")
soundButton.Name = "AudioToggle"
soundButton.AnchorPoint = Vector2.new(1, 0)
soundButton.Position = UDim2.fromScale(0.985, 0.085)
soundButton.Size = UserInputService.TouchEnabled
    and UDim2.fromOffset(190, 44)
    or UDim2.fromScale(0.17, 0.04)
soundButton.BackgroundColor3 = UITheme.Colors.PanelRaised
soundButton.BackgroundTransparency = 0.06
soundButton.BorderSizePixel = 0
soundButton.Font = Enum.Font.GothamBold
soundButton.TextScaled = true
soundButton.TextColor3 = UITheme.Colors.Text
soundButton.AutoButtonColor = false
soundButton.Visible = false
soundButton.Parent = gui
UITheme.addCorner(soundButton, UITheme.Corners.Pill)
local soundStroke = UITheme.addStroke(soundButton, UITheme.Colors.Cyan, 1.0, 0.45)
UITheme.addPressFeedback(soundButton, 0.96)

local soundConstraint = Instance.new("UISizeConstraint")
soundConstraint.MinSize = Vector2.new(150, UserInputService.TouchEnabled and 44 or 30)
soundConstraint.MaxSize = Vector2.new(220, 48)
soundConstraint.Parent = soundButton

local currentPhase = "waiting"
local voteVisible = false
local viewportConnection = nil

local function applyResponsive()
    if not UserInputService.TouchEnabled then
        button.Position = UDim2.fromScale(0.985, 0.03)
        soundButton.Position = UDim2.fromScale(0.985, 0.085)
        return
    end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local profile = UIResponsive.mobileProfile(viewport)
    local width = profile.veryNarrow and 168 or 190

    button.Size = UDim2.fromOffset(width, 44)
    button.Position = UDim2.new(1, -10, 0, profile.topHeight + 18)
    soundButton.Size = UDim2.fromOffset(width, 44)
    soundButton.Position = UDim2.new(1, -10, 0, profile.topHeight + 68)
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

local function refresh()
    local reduced = player:GetAttribute("ReduceMotion") == true
    local muted = player:GetAttribute("AudioMuted") == true

    button.Text = CoreLocalization.text(
        localeId,
        reduced and "MOTION_REDUCED" or "MOTION_FULL"
    )
    stroke.Color = reduced and UITheme.Colors.Green or UITheme.Colors.Cyan
    button.BackgroundColor3 = reduced
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

    local criticalPhase = currentPhase == "ready"
        or currentPhase == "round"
        or currentPhase == "result"
    local experienced = math.max(0, tonumber(player:GetAttribute("Games")) or 0) > 0
    local visible = player:GetAttribute("DataLoaded") == true
        and experienced
        and not criticalPhase
        and not voteVisible

    button.Visible = visible
    soundButton.Visible = visible
end

button.Activated:Connect(function()
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

player:GetAttributeChangedSignal("ReduceMotion"):Connect(refresh)
player:GetAttributeChangedSignal("AudioMuted"):Connect(refresh)
player:GetAttributeChangedSignal("Games"):Connect(refresh)
player:GetAttributeChangedSignal("DataLoaded"):Connect(refresh)

stateEvent.OnClientEvent:Connect(function(state)
    currentPhase = tostring(state.phase or "waiting")
    voteVisible = state.voteOptions ~= nil
    refresh()
end)

refresh()
