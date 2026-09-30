local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)

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

local atmosphere = Lighting:FindFirstChild("ChaosAtmosphere") or Instance.new("Atmosphere")
atmosphere.Name = "ChaosAtmosphere"
atmosphere.Density = 0.18
atmosphere.Offset = 0.15
atmosphere.Color = Color3.fromRGB(205, 215, 235)
atmosphere.Decay = Color3.fromRGB(90, 100, 125)
atmosphere.Glare = 0.04
atmosphere.Haze = 0.8
atmosphere.Parent = Lighting

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

local damageFlash = Instance.new("Frame")
damageFlash.Name = "DamageFlash"
damageFlash.Size = UDim2.fromScale(1, 1)
damageFlash.BackgroundColor3 = Color3.fromRGB(210, 35, 35)
damageFlash.BackgroundTransparency = 1
damageFlash.BorderSizePixel = 0
damageFlash.ZIndex = 24
damageFlash.Parent = gui

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
local activeAccent = Color3.fromRGB(115, 15, 160)
local secondaryAccent = nil
local activeBeacon = nil
local activeBeaconLight = nil
local activeDoubleChaos = false
local currentIntensity = 1
local lastSurvivorAnnounced = false

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

    if phase == "round" or phase == "ready" then
        roundDanger = phase == "round" and (tonumber(state.seconds) or 99) <= 5

        local ids = state.disasterIds or {}
        local profile = DisasterVisuals.combine(ids)
        local primaryProfile = ids[1] and DisasterVisuals.get(ids[1])
        local secondaryProfile = ids[2] and DisasterVisuals.get(ids[2])

        if profile then
            activeAccent = profile.Accent
            secondaryAccent = secondaryProfile and secondaryProfile.Accent or nil
            activeDoubleChaos = doubleChaos
            atmosphere.Density = profile.Density
            atmosphere.Haze = profile.Haze
            atmosphere.Color = profile.Atmosphere
            bloom.Intensity = profile.Bloom
            color.Contrast = profile.Contrast
            color.Saturation = profile.Saturation
            color.TintColor = profile.Tint
            vignette.BackgroundColor3 = profile.Accent
            local targetFov = profile.Fov
            if phase == "ready" then
                targetFov = math.max(72, profile.Fov - 3)
            elseif roundDanger then
                targetFov = profile.Fov + 3
            end
            tweenCamera(targetFov, 0.24)
        elseif doubleChaos then
            atmosphere.Density = 0.23
            atmosphere.Haze = 1.15
            bloom.Intensity = 0.75
            color.Contrast = 0.16
            color.Saturation = 0.22
            color.TintColor = Color3.fromRGB(245, 225, 255)
            vignette.BackgroundColor3 = Color3.fromRGB(115, 15, 160)
            tweenCamera(roundDanger and 82 or 78, 0.24)
        else
            atmosphere.Density = 0.18
            atmosphere.Haze = 0.82
            bloom.Intensity = 0.48
            color.Contrast = 0.10
            color.Saturation = 0.14
            color.TintColor = Color3.new(1, 1, 1)
            vignette.BackgroundColor3 = Color3.fromRGB(255, 70, 35)
            tweenCamera(roundDanger and 79 or 75, 0.24)
        end

        local generatedMap = workspace:FindFirstChild("GeneratedMap")
        local arena = generatedMap and generatedMap:FindFirstChild("Arena")
        local decor = arena and arena:FindFirstChild("Decor")
        local beacon = decor and decor:FindFirstChild("CenterBeacon")
        local light = beacon and beacon:FindFirstChild("ArenaGlow")

        activeBeacon = beacon and beacon:IsA("BasePart") and beacon or nil
        activeBeaconLight = light and light:IsA("PointLight") and light or nil

        if profile and activeBeacon then
            activeBeacon.Color = profile.Accent
            if activeBeaconLight then
                activeBeaconLight.Color = profile.Accent
                activeBeaconLight.Brightness = doubleChaos and 2.2 or 1.5
            end
        end

        if phase ~= lastPhase or state.title ~= lastRoundTitle then
            showBanner(
                state.title or "CHAOS!",
                phase == "ready" and "POSITION YOURSELF" or (state.arenaName or ""),
                doubleChaos and Color3.fromRGB(78, 24, 105) or Color3.fromRGB(28, 35, 52),
                phase == "ready" and 1.15 or 1.6
            )
            lastRoundTitle = state.title
        end
    elseif phase == "results" then
        roundDanger = false
        activeDoubleChaos = false
        secondaryAccent = nil
        atmosphere.Density = 0.15
        atmosphere.Haze = 0.65
        bloom.Intensity = 0.42
        color.Contrast = 0.08
        color.Saturation = 0.10
        color.TintColor = Color3.new(1, 1, 1)
        atmosphere.Color = Color3.fromRGB(205, 215, 235)
        tweenCamera(72, 0.35)
    else
        roundDanger = false
        activeDoubleChaos = false
        secondaryAccent = nil
        atmosphere.Density = 0.14
        atmosphere.Haze = 0.55
        bloom.Intensity = 0.30
        color.Contrast = 0.05
        color.Saturation = 0.06
        color.TintColor = Color3.new(1, 1, 1)
        atmosphere.Color = Color3.fromRGB(205, 215, 235)
        tweenCamera(70, 0.4)
    end

    lastPhase = phase
end

stateEvent.OnClientEvent:Connect(function(state)
    currentIntensity = math.clamp(tonumber(state.intensity) or 1, 0.85, 1.25)
    setMood(state)

    local alive = tonumber(state.survivorsAlive)
    local total = tonumber(state.contestantCount)

    if state.phase == "round" and total and total > 1 and alive == 1 then
        if not lastSurvivorAnnounced then
            lastSurvivorAnnounced = true
            showBanner(
                "LAST SURVIVOR",
                "One player remains",
                Color3.fromRGB(115, 38, 38),
                1.6
            )
        end
    elseif state.phase ~= "round" or (alive and alive > 1) then
        lastSurvivorAnnounced = false
    end
end)

local function celebrateCharacter()
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local sparkles = Instance.new("Sparkles")
    sparkles.Name = "VictorySparkles"
    sparkles.SparkleColor = Color3.fromRGB(255, 225, 95)
    sparkles.Parent = rootPart

    local glow = Instance.new("PointLight")
    glow.Name = "VictoryGlow"
    glow.Color = Color3.fromRGB(255, 220, 110)
    glow.Brightness = 2
    glow.Range = 14
    glow.Shadows = false
    glow.Parent = rootPart

    task.delay(1.8, function()
        if sparkles.Parent then sparkles:Destroy() end
        if glow.Parent then glow:Destroy() end
    end)
end

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
        celebrateCharacter()

        if survivalStreak >= 5 then
            showBanner(
                "UNSTOPPABLE x" .. survivalStreak,
                "Survival streak bonus +" .. tostring(feedback.streakBonusCoins or 0) .. " coins",
                Color3.fromRGB(115, 72, 18),
                2.0
            )
        elseif survivalStreak >= 3 then
            showBanner(
                "HOT STREAK x" .. survivalStreak,
                "Keep the run alive",
                Color3.fromRGB(82, 48, 18),
                1.7
            )
        end

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

    local pulseSpeed = (activeDoubleChaos and 5.2 or 3.6) * currentIntensity
    local wave = (math.sin(pulseClock * pulseSpeed) + 1) * 0.5
    local accent = activeAccent

    if activeDoubleChaos and secondaryAccent then
        accent = activeAccent:Lerp(secondaryAccent, wave)
        vignette.BackgroundColor3 = accent
    end

    if activeBeacon and activeBeacon.Parent then
        activeBeacon.Color = accent
        activeBeacon.Transparency = 0.22 + (wave * 0.20)

        if activeBeaconLight and activeBeaconLight.Parent then
            activeBeaconLight.Color = accent
            activeBeaconLight.Brightness = ((activeDoubleChaos and 1.8 or 1.15) + wave * (activeDoubleChaos and 1.4 or 0.75)) * currentIntensity
            activeBeaconLight.Range = 24 + wave * (10 + (currentIntensity * 3))
        end
    end

    local targetTransparency = 1
    if roundDanger then
        targetTransparency = 0.91 + math.sin(pulseClock * 8) * 0.035
    end

    vignette.BackgroundTransparency += (targetTransparency - vignette.BackgroundTransparency) * math.min(1, dt * 10)
end)


task.spawn(function()
    while player:GetAttribute("DataLoaded") ~= true do
        task.wait(0.1)
    end

    if (player:GetAttribute("Games") or 0) == 0 then
        task.wait(0.8)
        showBanner(
            "SURVIVE THE CHAOS",
            "Vote • Move • Climb • Stay alive until the timer hits 0",
            Color3.fromRGB(28, 42, 64),
            3.2
        )
    end
end)


local healthConnection = nil

local function bindDamageFeedback(character)
    if healthConnection then
        healthConnection:Disconnect()
        healthConnection = nil
    end

    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then
        return
    end

    local previousHealth = humanoid.Health
    healthConnection = humanoid.HealthChanged:Connect(function(health)
        if health < previousHealth and health > 0 then
            local lost = previousHealth - health
            damageFlash.BackgroundTransparency = math.clamp(0.88 - (lost / 250), 0.66, 0.88)
            TweenService:Create(
                damageFlash,
                TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            ):Play()

            tweenCamera(math.min(84, (camera and camera.FieldOfView or 72) + 2.5), 0.06)
        end
        previousHealth = health
    end)
end

if player.Character then
    task.spawn(bindDamageFeedback, player.Character)
end

player.CharacterAdded:Connect(bindDamageFeedback)
