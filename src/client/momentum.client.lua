local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalizationService = game:GetService("LocalizationService")

local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local finalRushActive = false

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosMomentum"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 26
gui.Parent = player:WaitForChild("PlayerGui")

local chip = Instance.new("Frame")
chip.Name = "MomentumChip"
chip.AnchorPoint = Vector2.new(1, 0.5)
chip.Position = UDim2.fromScale(0.975, 0.31)
chip.Size = UDim2.fromScale(0.22, 0.055)
chip.BackgroundColor3 = Color3.fromRGB(18, 24, 36)
chip.BackgroundTransparency = 1
chip.BorderSizePixel = 0
chip.Visible = false
chip.Parent = gui

local constraint = Instance.new("UISizeConstraint")
constraint.MinSize = Vector2.new(120, 38)
constraint.MaxSize = Vector2.new(230, 54)
constraint.Parent = chip

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = chip

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(85, 220, 255)
stroke.Thickness = 1.4
stroke.Transparency = 1
stroke.Parent = chip

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new(
    Color3.fromRGB(24, 38, 62),
    Color3.fromRGB(45, 25, 66)
)
gradient.Rotation = 15
gradient.Parent = chip

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBlack
label.Text = CoreLocalization.text(localeId, "RESULT_MOMENTUM_TAG", 2)
label.TextColor3 = Color3.fromRGB(225, 245, 255)
label.TextScaled = true
label.TextTransparency = 1
label.Parent = chip

local scale = Instance.new("UIScale")
scale.Scale = 0.82
scale.Parent = chip

local token = 0

local function hide(current)
    task.delay(1.05, function()
        if current ~= token then
            return
        end

        TweenService:Create(
            chip,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}
        ):Play()
        TweenService:Create(
            label,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {TextTransparency = 1}
        ):Play()
        TweenService:Create(
            stroke,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Transparency = 1}
        ):Play()
        TweenService:Create(
            scale,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Scale = 0.92}
        ):Play()

        task.wait(0.2)
        if current == token then
            chip.Visible = false
        end
    end)
end

local function refresh()
    local combo = math.max(0, math.floor(tonumber(player:GetAttribute("RoundMomentum")) or 0))
    local active = player:GetAttribute("RoundParticipant") == true
        and player:GetAttribute("RoundEliminated") ~= true

    if not active or combo < 2 or finalRushActive then
        if finalRushActive and chip.Visible then
            token += 1
            chip.Visible = false
        end
        return
    end

    token += 1
    local current = token

    local elite = combo >= 4
    label.Text = CoreLocalization.text(localeId, "RESULT_MOMENTUM_TAG", combo)
    label.TextColor3 = elite and Color3.fromRGB(255, 225, 105) or Color3.fromRGB(225, 245, 255)
    stroke.Color = elite and Color3.fromRGB(255, 190, 65) or Color3.fromRGB(85, 220, 255)

    chip.Visible = true
    chip.BackgroundTransparency = 1
    label.TextTransparency = 1
    stroke.Transparency = 1
    scale.Scale = 0.82

    TweenService:Create(
        chip,
        TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.08}
    ):Play()
    TweenService:Create(
        label,
        TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    ):Play()
    TweenService:Create(
        stroke,
        TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Transparency = elite and 0.08 or 0.22}
    ):Play()
    TweenService:Create(
        scale,
        TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = elite and 1.06 or 1}
    ):Play()

    hide(current)
end

player:GetAttributeChangedSignal("RoundMomentum"):Connect(refresh)
player:GetAttributeChangedSignal("RoundEliminated"):Connect(function()
    if player:GetAttribute("RoundEliminated") == true then
        token += 1
        chip.Visible = false
    end
end)


stateEvent.OnClientEvent:Connect(function(state)
    local nextFinalRush = state.phase == "round" and state.finalRush == true
    if nextFinalRush ~= finalRushActive then
        finalRushActive = nextFinalRush
        if finalRushActive then
            token += 1
            chip.Visible = false
        else
            refresh()
        end
    end
end)
