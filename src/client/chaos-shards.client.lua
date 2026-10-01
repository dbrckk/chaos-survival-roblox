local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChaosShardCollected")

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosShardFeedback"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 24
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Name = "Reward"
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.66)
label.Size = UDim2.fromOffset(260, 54)
label.BackgroundColor3 = Color3.fromRGB(17, 30, 48)
label.BackgroundTransparency = 1
label.BorderSizePixel = 0
label.Font = Enum.Font.GothamBlack
label.Text = ""
label.TextColor3 = Color3.fromRGB(120, 225, 255)
label.TextStrokeTransparency = 0.65
label.TextScaled = true
label.TextTransparency = 1
label.Visible = false
label.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = label

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(126, 107, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.35
stroke.Parent = label

local scale = Instance.new("UIScale")
scale.Scale = 0.78
scale.Parent = label

local token = 0

local function show(reward, total)
    token += 1
    local current = token

    label.Text = "+" .. tostring(reward) .. " COIN  •  CHAOS SHARD " .. tostring(total)
    label.Visible = true
    label.TextTransparency = 1
    label.BackgroundTransparency = 1
    scale.Scale = 0.78

    TweenService:Create(
        label,
        TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0, BackgroundTransparency = 0.12}
    ):Play()
    TweenService:Create(
        scale,
        TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()

    task.delay(1.05, function()
        if current ~= token then
            return
        end

        TweenService:Create(
            label,
            TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {TextTransparency = 1, BackgroundTransparency = 1}
        ):Play()
        TweenService:Create(
            scale,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Scale = 0.9}
        ):Play()

        task.wait(0.23)
        if current == token then
            label.Visible = false
        end
    end)
end

event.OnClientEvent:Connect(function(payload)
    show(tonumber(payload.reward) or 1, tonumber(payload.total) or 1)
end)
