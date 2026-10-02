local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local UITheme = require(ReplicatedStorage.Shared.UITheme)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("RoundState")
local feedbackEvent = remotes:WaitForChild("RoundFeedback")
local performancePulseEvent = remotes:WaitForChild("PerformancePulse")

local camera = workspace.CurrentCamera
local terrain = workspace.Terrain

local clouds = terrain:FindFirstChildOfClass("Clouds")
if not clouds then
    clouds = Instance.new("Clouds")
    clouds.Name = "ChaosClouds"
    clouds.Parent = terrain
end
clouds.Enabled = true
clouds.Cover = 0.28
clouds.Density = 0.32
clouds.Color = Color3.fromRGB(210, 220, 240)

local function getOrCreateLightingEffect(name, className)
    local existing = Lighting:FindFirstChild(name)
    if existing and not existing:IsA(className) then
        existing:Destroy()
        existing = nil
    end

    local effect = existing or Instance.new(className)
    effect.Name = name
    effect.Parent = Lighting
    return effect
end

Lighting.Brightness = 2
Lighting.ExposureCompensation = 0.05
Lighting.EnvironmentDiffuseScale = 0.38
Lighting.EnvironmentSpecularScale = 0.72
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.22
Lighting.ClockTime = 15.8
Lighting.Ambient = Color3.fromRGB(78, 86, 112)
Lighting.OutdoorAmbient = Color3.fromRGB(105, 116, 145)

local bloom = getOrCreateLightingEffect("ChaosBloom", "BloomEffect")
bloom.Intensity = 0.32
bloom.Size = 22
bloom.Threshold = 1.18

local color = getOrCreateLightingEffect("ChaosColor", "ColorCorrectionEffect")
color.Brightness = 0
color.Contrast = 0.06
color.Saturation = 0.08
color.TintColor = Color3.new(1, 1, 1)

local rays = getOrCreateLightingEffect("ChaosRays", "SunRaysEffect")
rays.Intensity = 0.035
rays.Spread = 0.82

local atmosphere = getOrCreateLightingEffect("ChaosAtmosphere", "Atmosphere")
atmosphere.Density = 0.16
atmosphere.Offset = 0.18
atmosphere.Color = Color3.fromRGB(185, 205, 235)
atmosphere.Decay = Color3.fromRGB(58, 72, 105)
atmosphere.Glare = 0.03
atmosphere.Haze = 0.72
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

local damageGradient = Instance.new("UIGradient")
damageGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.34),
    NumberSequenceKeypoint.new(0.22, 0.78),
    NumberSequenceKeypoint.new(0.50, 0.94),
    NumberSequenceKeypoint.new(0.78, 0.78),
    NumberSequenceKeypoint.new(1, 0.34),
})
damageGradient.Rotation = 90
damageGradient.Parent = damageFlash

local criticalFrame = Instance.new("Frame")
criticalFrame.Name = "CriticalHealthEdge"
criticalFrame.Size = UDim2.fromScale(1, 1)
criticalFrame.BackgroundTransparency = 1
criticalFrame.BorderSizePixel = 0
criticalFrame.ZIndex = 23
criticalFrame.Parent = gui

local criticalStroke = Instance.new("UIStroke")
criticalStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
criticalStroke.Color = UITheme.Colors.Red
criticalStroke.Thickness = 5
criticalStroke.Transparency = 1
criticalStroke.Parent = criticalFrame

local banner = Instance.new("Frame")
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.fromScale(0.5, 0.42)
banner.Size = UDim2.fromScale(0.86, 0.18)
banner.BackgroundColor3 = UITheme.Colors.Panel
banner.BackgroundTransparency = 1
banner.Visible = false
banner.ZIndex = 5
banner.Parent = gui
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 22)
local bannerStroke = UITheme.addStroke(banner, UITheme.Colors.Blue, 1.4, 0.30)
local bannerGradient = UITheme.addGradient(banner, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local bannerScale = Instance.new("UIScale")
bannerScale.Scale = 0.72
bannerScale.Parent = banner

local bannerTitle = Instance.new("TextLabel")
bannerTitle.Size = UDim2.new(1, -32, 0.58, 0)
bannerTitle.Position = UDim2.fromOffset(16, 8)
bannerTitle.BackgroundTransparency = 1
bannerTitle.Font = Enum.Font.GothamBlack
bannerTitle.TextColor3 = UITheme.Colors.Text
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
bannerSub.TextColor3 = UITheme.Colors.Muted
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
local activeBeaconDefaults = nil
local activeDoubleChaos = false
local currentIntensity = 1
local lastSurvivorAnnounced = false
local vfxTierName = VfxQuality.initialTier(UserInputService.TouchEnabled)
local vfxTier = VfxQuality.get(vfxTierName)
local frameTimeAccumulator = 0
local frameSampleCount = 0
local qualitySampleClock = 0
local visualUpdateClock = 0
local performancePulseClock = 0
local performanceFpsAccumulator = 0
local performanceFpsSamples = 0
local healthRatio = 1
player:SetAttribute("VfxQualityTier", vfxTierName)

local function setActiveBeacon(beacon, light)
    if activeBeacon ~= beacon then
        activeBeacon = beacon
        activeBeaconLight = light
        activeBeaconDefaults = beacon and {
            color = beacon.Color,
            transparency = beacon.Transparency,
            lightColor = light and light.Color or nil,
            lightBrightness = light and light.Brightness or nil,
            lightRange = light and light.Range or nil,
        } or nil
    else
        activeBeaconLight = light
    end
end

local function resetActiveBeacon()
    if activeBeacon and activeBeacon.Parent and activeBeaconDefaults then
        activeBeacon.Color = activeBeaconDefaults.color
        activeBeacon.Transparency = activeBeaconDefaults.transparency
    end
    if activeBeaconLight and activeBeaconLight.Parent and activeBeaconDefaults then
        if activeBeaconDefaults.lightColor then
            activeBeaconLight.Color = activeBeaconDefaults.lightColor
        end
        if activeBeaconDefaults.lightBrightness then
            activeBeaconLight.Brightness = activeBeaconDefaults.lightBrightness
        end
        if activeBeaconDefaults.lightRange then
            activeBeaconLight.Range = activeBeaconDefaults.lightRange
        end
    end
    activeBeacon = nil
    activeBeaconLight = nil
    activeBeaconDefaults = nil
end

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

    local resolvedAccent = accent or UITheme.Colors.Blue
    banner.BackgroundColor3 = UITheme.Colors.Panel
    bannerStroke.Color = resolvedAccent
    bannerGradient.Color = ColorSequence.new(
        resolvedAccent:Lerp(UITheme.Colors.PanelRaised, 0.62),
        UITheme.Colors.Panel
    )
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
    local ids = state.disasterIds or {}
    local primaryId = ids[1]

    if phase == "round" or phase == "ready" then
        if primaryId == "Tornado" then
            clouds.Cover = 0.72
            clouds.Density = 0.58
            clouds.Color = Color3.fromRGB(145, 175, 185)
        elseif primaryId == "Darkness" then
            clouds.Cover = 0.82
            clouds.Density = 0.66
            clouds.Color = Color3.fromRGB(78, 88, 118)
        elseif primaryId == "RisingLava" then
            clouds.Cover = 0.42
            clouds.Density = 0.38
            clouds.Color = Color3.fromRGB(225, 165, 125)
        elseif primaryId == "Freeze" then
            clouds.Cover = 0.50
            clouds.Density = 0.42
            clouds.Color = Color3.fromRGB(190, 220, 238)
        elseif primaryId == "Meteors" or primaryId == "Bombs" then
            clouds.Cover = 0.46
            clouds.Density = 0.44
            clouds.Color = Color3.fromRGB(195, 150, 140)
        elseif doubleChaos then
            clouds.Cover = 0.58
            clouds.Density = 0.50
            clouds.Color = Color3.fromRGB(165, 145, 205)
        else
            clouds.Cover = 0.32
            clouds.Density = 0.34
            clouds.Color = Color3.fromRGB(205, 215, 235)
        end
    elseif phase == "intermission" then
        clouds.Cover = 0.20
        clouds.Density = 0.24
        clouds.Color = Color3.fromRGB(215, 228, 246)
    elseif phase == "vote" then
        clouds.Cover = 0.26
        clouds.Density = 0.30
        clouds.Color = Color3.fromRGB(195, 210, 242)
    elseif phase == "result" then
        clouds.Cover = 0.30
        clouds.Density = 0.30
        clouds.Color = Color3.fromRGB(208, 220, 238)
    else
        clouds.Cover = 0.24
        clouds.Density = 0.28
        clouds.Color = Color3.fromRGB(215, 225, 242)
    end

    if phase == "round" then
        Lighting.ExposureCompensation = doubleChaos and -0.04 or 0.02
        Lighting.EnvironmentDiffuseScale = 0.34
        Lighting.EnvironmentSpecularScale = 0.76
    elseif phase == "ready" then
        Lighting.ExposureCompensation = 0.04
        Lighting.EnvironmentDiffuseScale = 0.38
        Lighting.EnvironmentSpecularScale = 0.72
    else
        Lighting.ExposureCompensation = 0.07
        Lighting.EnvironmentDiffuseScale = 0.42
        Lighting.EnvironmentSpecularScale = 0.68
    end

    if phase == "round" or phase == "ready" then
        roundDanger = phase == "round" and (tonumber(state.seconds) or 99) <= 5

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
            bloom.Intensity = profile.Bloom * vfxTier.Scale
            local roundParticipant = player:GetAttribute("RoundParticipant") == true
            local roundEliminated = player:GetAttribute("RoundEliminated") == true
            color.Brightness = (roundParticipant and not roundEliminated)
                and (profile.Brightness or 0)
                or 0
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
            bloom.Intensity = 0.75 * vfxTier.Scale
            color.Brightness = 0
            color.Contrast = 0.16
            color.Saturation = 0.22
            color.TintColor = Color3.fromRGB(245, 225, 255)
            vignette.BackgroundColor3 = Color3.fromRGB(115, 15, 160)
            tweenCamera(roundDanger and 82 or 78, 0.24)
        else
            atmosphere.Density = 0.18
            atmosphere.Haze = 0.82
            bloom.Intensity = 0.48 * vfxTier.Scale
            color.Brightness = 0
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

        setActiveBeacon(
            beacon and beacon:IsA("BasePart") and beacon or nil,
            light and light:IsA("PointLight") and light or nil
        )

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
                doubleChaos
                    and UITheme.Colors.Violet
                    or (profile and profile.Accent or UITheme.Colors.Blue),
                phase == "ready" and 1.15 or 1.6
            )
            lastRoundTitle = state.title
        end
    elseif phase == "result" then
        Lighting.ExposureCompensation = 0.08
        Lighting.EnvironmentDiffuseScale = 0.44
        Lighting.EnvironmentSpecularScale = 0.66
        resetActiveBeacon()
        roundDanger = false
        activeDoubleChaos = false
        secondaryAccent = nil
        atmosphere.Density = 0.15
        atmosphere.Haze = 0.65
        bloom.Intensity = 0.42 * vfxTier.Scale
        color.Brightness = 0
        color.Contrast = 0.08
        color.Saturation = 0.10
        color.TintColor = Color3.new(1, 1, 1)
        atmosphere.Color = Color3.fromRGB(205, 215, 235)
        tweenCamera(72, 0.35)
    else
        if phase == "vote" then
            Lighting.ExposureCompensation = 0.10
            color.Contrast = 0.08
            color.Saturation = 0.10
        elseif phase == "intermission" then
            Lighting.ExposureCompensation = 0.09
        end

        resetActiveBeacon()
        roundDanger = false
        activeDoubleChaos = false
        secondaryAccent = nil
        atmosphere.Density = 0.14
        atmosphere.Haze = 0.55
        bloom.Intensity = 0.30 * vfxTier.Scale
        color.Brightness = 0
        color.Contrast = 0.05
        color.Saturation = 0.06
        color.TintColor = Color3.new(1, 1, 1)
        atmosphere.Color = Color3.fromRGB(205, 215, 235)
        tweenCamera(70, 0.4)
    end

    rays.Enabled = vfxTier.RaysEnabled
    lastPhase = phase
end

local currentState = nil

local function refreshParticipantMood()
    if currentState then
        setMood(currentState)
    end
end

player:GetAttributeChangedSignal("RoundParticipant"):Connect(refreshParticipantMood)
player:GetAttributeChangedSignal("RoundEliminated"):Connect(refreshParticipantMood)

stateEvent.OnClientEvent:Connect(function(state)
    currentState = state
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

local function celebrateCharacter(masterRound)
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local sparkles = nil
    if tier.Name ~= "Low" then
        sparkles = Instance.new("Sparkles")
        sparkles.Name = "VictorySparkles"
        sparkles.SparkleColor = masterRound
            and Color3.fromRGB(110, 230, 255)
            or Color3.fromRGB(255, 225, 95)
        sparkles.Parent = rootPart
    end

    local glow = Instance.new("PointLight")
    glow.Name = "VictoryGlow"
    glow.Color = masterRound
        and Color3.fromRGB(100, 220, 255)
        or Color3.fromRGB(255, 220, 110)
    glow.Brightness = (masterRound and 3 or 2) * tier.Scale
    glow.Range = (masterRound and 16 or 10) + (4 * tier.Scale)
    glow.Shadows = false
    glow.Parent = rootPart

    task.delay(1.8, function()
        if sparkles and sparkles.Parent then sparkles:Destroy() end
        if glow.Parent then glow:Destroy() end
    end)
end

feedbackEvent.OnClientEvent:Connect(function(feedback)
    local survivalStreak = tonumber(feedback.streak) or 0

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
        local momentumBest = math.max(0, math.floor(tonumber(feedback.momentumBest) or 0))
        local masterRound = feedback.challengeCompleted == true and momentumBest >= 4
        celebrateCharacter(masterRound)

        if masterRound then
            showBanner(
                "MASTER ROUND",
                "Challenge complete • Momentum x" .. tostring(momentumBest),
                Color3.fromRGB(80, 205, 235),
                2.2
            )
        elseif feedback.criticalSurvival then
            showBanner(
                "LAST-BREATH SURVIVAL",
                "You escaped with almost no health left",
                Color3.fromRGB(125, 42, 38),
                1.9
            )
        elseif survivalStreak >= 5 then
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
    frameTimeAccumulator += dt
    frameSampleCount += 1
    qualitySampleClock += dt

    if dt > 0 then
        performancePulseClock += dt
        performanceFpsAccumulator += math.clamp(1 / dt, 0, 240)
        performanceFpsSamples += 1

        if performancePulseClock >= 45 and performanceFpsSamples > 0 then
            local averageFps = performanceFpsAccumulator / performanceFpsSamples
            local deviceClass = UserInputService.TouchEnabled and "Touch" or "Desktop"

            performancePulseEvent:FireServer({
                averageFps = math.floor(averageFps + 0.5),
                vfxTier = vfxTierName,
                deviceClass = deviceClass,
            })

            performancePulseClock = 0
            performanceFpsAccumulator = 0
            performanceFpsSamples = 0
        end
    end

    if qualitySampleClock >= 2.5 and frameSampleCount > 0 then
        local averageDt = frameTimeAccumulator / frameSampleCount
        local averageFps = averageDt > 0 and (1 / averageDt) or 60
        local nextTierName = VfxQuality.nextTier(vfxTierName, averageFps)

        if nextTierName ~= vfxTierName then
            vfxTierName = nextTierName
            vfxTier = VfxQuality.get(vfxTierName)
            player:SetAttribute("VfxQualityTier", vfxTierName)
            rays.Enabled = vfxTier.RaysEnabled
        end

        frameTimeAccumulator = 0
        frameSampleCount = 0
        qualitySampleClock = 0
    end

    visualUpdateClock += dt
    if visualUpdateClock < vfxTier.UpdateInterval then
        return
    end
    visualUpdateClock = 0

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
            activeBeaconLight.Brightness = ((activeDoubleChaos and 1.8 or 1.15) + wave * (activeDoubleChaos and 1.4 or 0.75)) * currentIntensity * vfxTier.Scale
            activeBeaconLight.Range = (24 + wave * (10 + (currentIntensity * 3))) * (0.82 + (vfxTier.Scale * 0.18))
        end
    end

    local targetTransparency = 1
    if roundDanger then
        targetTransparency = 0.91 + math.sin(pulseClock * 8) * 0.035
    end

    local criticalHealth = currentState
        and currentState.phase == "round"
        and player:GetAttribute("RoundParticipant") == true
        and player:GetAttribute("RoundEliminated") ~= true
        and healthRatio > 0
        and healthRatio <= 0.30

    if criticalHealth then
        criticalStroke.Transparency = 0.54 + wave * 0.24
        criticalStroke.Thickness = 4 + wave * 2
    else
        criticalStroke.Transparency += (1 - criticalStroke.Transparency) * math.min(1, dt * 10)
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
    healthRatio = humanoid.MaxHealth > 0 and (humanoid.Health / humanoid.MaxHealth) or 1
    healthConnection = humanoid.HealthChanged:Connect(function(health)
        healthRatio = humanoid.MaxHealth > 0 and math.clamp(health / humanoid.MaxHealth, 0, 1) or 1
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
