local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local gui = Instance.new("ScreenGui")
gui.Name = "ArenaGuide"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 4
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "StrategyCard"
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.fromScale(0.5, 0.165)
card.Size = UDim2.fromScale(0.72, 0.072)
card.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
card.BackgroundTransparency = 1
card.Visible = false
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(105, 175, 255)
stroke.Transparency = 0.45
stroke.Thickness = 1.5
stroke.Parent = card

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -24, 1, -12)
label.Position = UDim2.fromOffset(12, 6)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamMedium
label.TextColor3 = Color3.fromRGB(230, 237, 250)
label.TextScaled = true
label.TextWrapped = true
label.Text = ""
label.TextTransparency = 1
label.Parent = card

local token = 0

local function currentArenaHint()
    local root = Workspace:FindFirstChild("GeneratedMap")
    local arena = root and root:FindFirstChild("Arena")
    if not arena then
        return nil
    end

    local hint = arena:GetAttribute("StrategyHint")
    if type(hint) ~= "string" or hint == "" then
        return nil
    end

    return hint
end

local function hide()
    token += 1
    local thisToken = token
    TweenService:Create(card, TweenInfo.new(0.16), {BackgroundTransparency = 1}):Play()
    TweenService:Create(label, TweenInfo.new(0.16), {TextTransparency = 1}):Play()
    task.delay(0.18, function()
        if token == thisToken then
            card.Visible = false
        end
    end)
end

local function show(arenaName)
    local hint = currentArenaHint()
    if not hint then
        hide()
        return
    end

    token += 1
    label.Text = string.format("%s  •  %s", arenaName or "ARENA", hint)
    card.Visible = true
    card.BackgroundTransparency = 1
    label.TextTransparency = 1
    TweenService:Create(card, TweenInfo.new(0.18), {BackgroundTransparency = 0.10}):Play()
    TweenService:Create(label, TweenInfo.new(0.18), {TextTransparency = 0}):Play()
end

stateEvent.OnClientEvent:Connect(function(state)
    if state.phase == "ready" then
        show(state.arenaName)
    elseif state.phase == "round" or state.phase == "waiting" then
        hide()
    end
end)
