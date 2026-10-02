local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)

local player = Players.LocalPlayer
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
    and UDim2.fromScale(0.26, 0.045)
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

local currentPhase = "waiting"

local function refresh()
    local reduced = player:GetAttribute("ReduceMotion") == true
    button.Text = reduced and "MOTION • REDUCED" or "MOTION • FULL"
    stroke.Color = reduced and UITheme.Colors.Green or UITheme.Colors.Cyan
    button.BackgroundColor3 = reduced
        and UITheme.Colors.Green:Lerp(UITheme.Colors.Panel, 0.72)
        or UITheme.Colors.PanelRaised

    local criticalPhase = currentPhase == "ready" or currentPhase == "round"
    button.Visible = player:GetAttribute("DataLoaded") == true and not criticalPhase
end

button.Activated:Connect(function()
    local nextValue = player:GetAttribute("ReduceMotion") ~= true
    player:SetAttribute("ReduceMotion", nextValue)
    accessibilityEvent:FireServer("ReduceMotion", nextValue)
    refresh()
end)

player:GetAttributeChangedSignal("ReduceMotion"):Connect(refresh)
player:GetAttributeChangedSignal("DataLoaded"):Connect(refresh)

stateEvent.OnClientEvent:Connect(function(state)
    currentPhase = tostring(state.phase or "waiting")
    refresh()
end)

refresh()
