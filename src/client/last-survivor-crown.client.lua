local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local gui = Instance.new("BillboardGui")
gui.Name = "LastSurvivorCrown"
gui.ResetOnSpawn = false
gui.AlwaysOnTop = true
gui.LightInfluence = 0
gui.Size = UDim2.fromOffset(190, 48)
gui.StudsOffsetWorldSpace = Vector3.new(0, 3.7, 0)
gui.MaxDistance = 180
gui.Enabled = false
gui.Parent = localPlayer:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundColor3 = Color3.fromRGB(30, 24, 10)
label.BackgroundTransparency = 0.10
label.BorderSizePixel = 0
label.Font = Enum.Font.GothamBlack
label.Text = "★  LAST SURVIVOR"
label.TextColor3 = Color3.fromRGB(255, 225, 100)
label.TextScaled = true
label.TextStrokeColor3 = Color3.fromRGB(60, 34, 5)
label.TextStrokeTransparency = 0.35
label.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = label

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 190, 55)
stroke.Thickness = 1.4
stroke.Transparency = 0.18
stroke.Parent = label

local scale = Instance.new("UIScale")
scale.Scale = 0.86
scale.Parent = label

local activeHighlight = nil
local activeCharacter = nil
local activeUserId = nil

local function clear()
    activeUserId = nil
    activeCharacter = nil
    gui.Enabled = false
    gui.Adornee = nil

    if activeHighlight then
        activeHighlight:Destroy()
        activeHighlight = nil
    end
end

local function bind(userId)
    if not userId then
        clear()
        return
    end

    local target = Players:GetPlayerByUserId(userId)
    local character = target and target.Character
    local head = character and character:FindFirstChild("Head")
    if not target or not character or not head or not head:IsA("BasePart") then
        clear()
        return
    end

    if activeUserId == userId and activeCharacter == character then
        return
    end

    clear()
    activeUserId = userId
    activeCharacter = character
    gui.Adornee = head
    gui.Enabled = true

    label.TextTransparency = 1
    label.BackgroundTransparency = 1
    stroke.Transparency = 1
    scale.Scale = 0.78

    TweenService:Create(label, TweenInfo.new(0.18), {
        TextTransparency = 0,
        BackgroundTransparency = 0.10,
    }):Play()
    TweenService:Create(stroke, TweenInfo.new(0.18), {
        Transparency = 0.18,
    }):Play()
    TweenService:Create(
        scale,
        TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()

    local highlight = Instance.new("Highlight")
    highlight.Name = "LastSurvivorHighlightLocal"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 205, 70)
    highlight.FillTransparency = 0.88
    highlight.OutlineColor = Color3.fromRGB(255, 235, 145)
    highlight.OutlineTransparency = 0.10
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = character
    activeHighlight = highlight
end

stateEvent.OnClientEvent:Connect(function(state)
    if state.phase ~= "round" then
        clear()
        return
    end

    local userId = tonumber(state.lastSurvivorUserId)
    if userId then
        bind(userId)
    else
        clear()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if activeUserId == player.UserId then
        clear()
    end
end)
