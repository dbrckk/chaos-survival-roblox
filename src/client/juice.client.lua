local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("RoundState")
local feedbackEvent = remotes:WaitForChild("RoundFeedback")

local camera = workspace.CurrentCamera

local bloom = Lighting:FindFirstChild("ChaosBloom") or Instance.new("BloomEffect")
bloom.Name = "ChaosBloom"
bloom.Intensity = 0.35
bloom.Size = 28
bloom.Threshold = 1.1
bloom.Parent = Lighting

local color = Lighting:FindFirstChild("ChaosColor") or Instance.new("ColorCorrectionEffect")
color.Name = "ChaosColor"
color.Brightness = 0
color.Contrast = 0.06
color.Saturation = 0.08
color.TintColor = Color3.new(1, 1, 1)
color.Parent = Lighting

local rays = Lighting:FindFirstChild("ChaosRays") or Instance.new("SunRaysEffect")
rays.Name = "ChaosRays"
rays.Intensity = 0.035
rays.Spread = 0.82
rays.Parent = Lighting

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosJuice"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.Parent = player:WaitForChild("PlayerGui")

local vignette = Instance.new("Frame")
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundColor3 = Color3.fromRGB(110, 0, 155)
vignette.BackgroundTransparency = 1
vignette.BorderSizePixel = 0
vignette.ZIndex = 1
vignette.Parent = gui

local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.fromScale(0.5, 0.42)
banner.Size = UDim2.fromScale(0.86, 0.18)
banner.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
banner.BackgroundTransparency = 1
banner.Visible = false
banner.ZIndex = 5
banner.Parent = gui
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 22)

local bannerScale = Instance.new("UIScale")
bannerScale.Scale = 0.72
bannerScale.Parent = banner

local bannerTitle = Instance.new("TextLabel")
bannerTitle.Size = UDim2.new(1, -32, 0.58, 0)
bannerTitle.Position = UDim2.fromOffset(16, 8)
bannerTitle.BackgroundTransparency = 1
bannerTitle.Font = Enum.Font.GothamBlack
bannerTitle.TextColor3 = Color3.new(1, 1, 1)
bannerTitle.TextScaled = true
bannerTitle.TextStrokeTransparency = 0.72
bannerTitle.ZIndex = 6
bannerTitle.Text = ""
bannerTitle.Parent = banner

local bannerSub = Instance.new("TextLabel")
bannerSub.Size = UDim2.new(1, -32, 0.28, 0)
bannerSub.Position = UDim2.new(0, 16, 0.66, 0)
bannerSub.BackgroundTransparency = 1
bannerSub.Font = Enum.Font.GothamBold
bannerSub.TextColor3 = Color3.fromRGB(218, 224, 240)
bannerSub.TextScaled = true
bannerSub.ZIndex = 6
bannerSub.Text = ""
bannerSub.Parent = banner

local streak = Instance.new("TextLabel")
streak.AnchorPoint = Vector2.new(1, 0)
streak.Position = UDim2.fromScale(0.98, 0.18)
streak.Size = UDim2.fromScale(0.23, 0.055)
streak.BackgroundColor3 = Color3.fromRGB(31, 35, 48)
streak.BackgroundTransparency = 0.12
streak.Font = Enum.Font.GothamBlack
streak.TextColor3 = Color3.fromRGB(255, 225, 100)
streak.TextScaled = true
streak.Visible = false
streak.ZIndex = 5
streak.Parent = gui
Instance.new("UICorner", streak).CornerRadius = UDim.new(1, 0)

local bannerToken = 0
local lastPhase = nil
local lastRoundTitle = nil
local pulseClock = 0
local roundDanger = false

local function tweenCamera(targetFov, duration)
    camera = workspace.CurrentCamera or camera
    if camera then
        TweenService:Create(
            camera,
            TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {FieldOfView = targetFov}
        ):Play()
    end
end

local function showBanner(mainText, subText, accent, duration)
    bannerToken += 1
    local token = bannerToken

    banner.BackgroundColor3 = accent or Color3.fromRGB(15, 17, 24)
    bannerTitle.Text = mainText or ""
    bannerSub.Text = subText or ""
    banner.Visible = true
    banner.BackgroundTransparency = 1
    bannerScale.Scale = 0.72

    TweenService:Create(
        banner,
        TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.08}
    ):Play()
    TweenService:Create(
        bannerScale,
        TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()

    task.delay(duration or 1.8, function()
        if token ~= bannerToken then return end
        TweenService:Create(banner, TweenInfo.new(0.22), {BackgroundTransparency = 1}):Play()
        TweenService:Create(bannerScale, TweenInfo.new(0.22), {Scale = 0.88}):Play()
        task.wait(0.24)
        if token == bannerToken then
            banner.Visible = false
        end
    end)
end

local function setMood(state)
    local phase = state.phase
    local doubleChaos = state.doubleChaos == true

    if phase == "round" then
        roundDanger = (tonumber(state.seconds) or 99) <= 5

        if doubleChaos then
            bloom.Intensity = 0.75
            color.Contrast = 0.16
            color.Saturation = 0.22
            color.TintColor = Color3.fromRGB(245, 225, 255)
            vignette.BackgroundColor3 = Color3.fromRGB(115, 15, 160)
            tweenCamera(roundDanger and 82 or 78, 0.24)
        else
            bloom.Intensity = 0.48
            color.Contrast = 0.10
            color.Saturation = 0.14
            color.TintColor = Color3.new(1, 1, 1)
            vignette.BackgroundColor3 = Color3.fromRGB(255, 70, 35)
            tweenCamera(roundDanger and 79 or 75, 0.24)
        end

        if phase ~= lastPhase or state.title ~= lastRoundTitle then
            showBanner(
                state.title or "CHAOS!",
                state.arenaName or "",
                doubleChaos and Color3.fromRGB(78, 24, 105) or Color3.fromRGB(28, 35, 52),
                1.6
            )
            lastRoundTitle = state.title
        end
    elseif phase == "results" then
        roundDanger = false
        bloom.Intensity = 0.42
        color.Contrast = 0.08
        color.Saturation = 0.10
        color.TintColor = Color3.new(1, 1, 1)
        tweenCamera(72, 0.35)
    else
        roundDanger = false
        bloom.Intensity = 0.30
        color.Contrast = 0.05
        color.Saturation = 0.06
        color.TintColor = Color3.new(1, 1, 1)
        tweenCamera(70, 0.4)
    end

    lastPhase = phase
end

stateEvent.OnClientEvent:Connect(function(state)
    setMood(state)
end)

feedbackEvent.OnClientEvent:Connect(function(feedback)
    local survivalStreak = tonumber(feedback.survivalStreak) or 0

    if survivalStreak >= 2 then
        streak.Text = "SURVIVAL STREAK x" .. survivalStreak
        streak.Visible = true
        streak.TextTransparency = 1
        streak.BackgroundTransparency = 1
        TweenService:Create(streak, TweenInfo.new(0.2), {
            TextTransparency = 0,
            BackgroundTransparency = 0.12,
        }):Play()
    else
        streak.Visible = false
    end

    if feedback.survived then
        tweenCamera(67, 0.12)
        task.delay(0.13, function()
            tweenCamera(72, 0.28)
        end)
    else
        tweenCamera(76, 0.10)
        task.delay(0.12, function()
            tweenCamera(72, 0.30)
        end)
    end
end)

RunService.RenderStepped:Connect(function(dt)
    pulseClock += dt

    local targetTransparency = 1
    if roundDanger then
        targetTransparency = 0.91 + math.sin(pulseClock * 8) * 0.035
    end

    vignette.BackgroundTransparency += (targetTransparency - vignette.BackgroundTransparency) * math.min(1, dt * 10)
end)
