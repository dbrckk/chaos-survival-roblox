local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")
local Stats = game:GetService("Stats")

local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualBudgetRules = require(ReplicatedStorage.Shared.VisualBudgetRules)
local PerformancePulseRules = require(ReplicatedStorage.Shared.PerformancePulseRules)
local FramePacingRules = require(ReplicatedStorage.Shared.FramePacingRules)
local CloudLayer = require(script.Parent.CloudLayer)
local ArenaPostProcessLayer = require(script.Parent.ArenaPostProcessLayer)
local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local MobileHudNotices = require(ReplicatedStorage.Shared.MobileHudNotices)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local RoundEventPresentation = require(ReplicatedStorage.Shared.RoundEventPresentation)
local CameraFeelBus = require(script.Parent.CameraFeelBus)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("RoundState")
local feedbackEvent = remotes:WaitForChild("RoundFeedback")
local performancePulseEvent = remotes:WaitForChild("PerformancePulse")

local camera = workspace.CurrentCamera
local terrain = workspace.Terrain

local baseFovValue = Instance.new("NumberValue")
baseFovValue.Name = "ChaosBaseFovDriver"
baseFovValue.Value = camera and camera.FieldOfView or 70
local baseFovTween = nil
local lastCameraFovTarget = nil
local damageFovKick = 0
local damageFadeTween = nil
local damageHitSerial = 0
local resultPulseSerial = 0

local clouds = CloudLayer.getOrCreate()
local post = ArenaPostProcessLayer.get()
local bloom = post.Bloom
local color = post.Color
local rays = post.SunRays
local atmosphere = post.Atmosphere

-- One owner for the hazard's exposure curve. Blackout transitions are
-- deliberately slow enough for mobile players to read the route, with no
-- screen flash and no additional post-processing instances. Reset at
-- result/lobby so an old blackout never darkens a victory or next round.
local brightnessTween = nil
local brightnessTarget = nil
local function setHazardBrightness(target, fade)
    if brightnessTarget ~= nil and math.abs(brightnessTarget - target) < 0.001 then
        return
    end
    brightnessTarget = target
    if brightnessTween then
        brightnessTween:Cancel()
        brightnessTween = nil
    end
    if fade then
        brightnessTween = TweenService:Create(
            color,
            TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Brightness = target}
        )
        brightnessTween:Play()
    else
        color.Brightness = target
    end
end

-- Arena identity owns baseline post-processing. This controller only overrides
-- the shared layer while a disaster is preparing or active.

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
banner.Name = "RoundIntroBanner"
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

local bannerTitleLimit = Instance.new("UITextSizeConstraint")
bannerTitleLimit.MinTextSize = 11
bannerTitleLimit.MaxTextSize = 48
bannerTitleLimit.Parent = bannerTitle
local bannerSubLimit = Instance.new("UITextSizeConstraint")
bannerSubLimit.MinTextSize = 10
bannerSubLimit.MaxTextSize = 28
bannerSubLimit.Parent = bannerSub

-- One viewport listener (never another RenderStepped owner) keeps the
-- disaster introduction clear of Android's central avatar/parkour lane.
local bannerViewportConnection = nil
local function updateBannerViewport()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    if UserInputService.TouchEnabled then
        local layout = UIResponsive.mobileRoundBanner(viewport)
        banner.Position = UDim2.fromScale(0.5, layout.centerYScale)
        banner.Size = UDim2.new(layout.widthScale, 0, 0, layout.height)
        bannerTitleLimit.MaxTextSize = layout.titleMaxTextSize
        bannerSubLimit.MaxTextSize = layout.subtitleMaxTextSize
    else
        banner.Position = UDim2.fromScale(0.5, 0.42)
        banner.Size = UDim2.fromScale(0.86, 0.18)
        bannerTitleLimit.MaxTextSize = 48
        bannerSubLimit.MaxTextSize = 28
    end
end
local function bindBannerCamera()
    if bannerViewportConnection then
        bannerViewportConnection:Disconnect()
        bannerViewportConnection = nil
    end
    local camera = workspace.CurrentCamera
    if camera then
        bannerViewportConnection = camera:GetPropertyChangedSignal("ViewportSize")
            :Connect(updateBannerViewport)
    end
    updateBannerViewport()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindBannerCamera)
bindBannerCamera()

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
local bannerFadingOut = false
local bannerTweens = {}
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
local sampleWorstFrameDt = 0
local qualityPacing = FramePacingRules.new()
local performancePacing = FramePacingRules.new()
local frameSampleCount = 0
local qualitySampleClock = 0
local qualityCandidate = nil
local qualityCandidateSamples = 0
local visualUpdateClock = 0
local performancePulseClock = 0
local performanceFrameCount = 0
local vfxTierTransitions = 0
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
    local target = math.clamp(tonumber(targetFov) or 70, 60, 90)
    if not RoundEventPresentation.cameraTargetChanged(lastCameraFovTarget, target) then
        return
    end
    lastCameraFovTarget = target
    if baseFovTween then
        baseFovTween:Cancel()
        baseFovTween = nil
    end
    if player:GetAttribute("ReduceMotion") == true then
        baseFovValue.Value = target
        return
    end
    baseFovTween = TweenService:Create(
        baseFovValue,
        TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Value = target}
    )
    baseFovTween:Play()
end

local function cancelBannerTweens()
    for item, tween in pairs(bannerTweens) do
        tween:Cancel()
        bannerTweens[item] = nil
    end
end

local function animateBanner(item, info, properties)
    if bannerTweens[item] then
        bannerTweens[item]:Cancel()
        bannerTweens[item] = nil
    end
    if player:GetAttribute("ReduceMotion") == true then
        for property, value in pairs(properties) do
            item[property] = value
        end
        return
    end
    local tween = TweenService:Create(item, info, properties)
    bannerTweens[item] = tween
    tween:Play()
end

local function showBanner(mainText, subText, accent, duration)
    bannerToken += 1
    local token = bannerToken
    bannerFadingOut = false
    cancelBannerTweens()

    local resolvedAccent = accent or UITheme.Colors.Blue
    banner.BackgroundColor3 = UITheme.Colors.Panel
    bannerStroke.Color = resolvedAccent
    bannerGradient.Color = ColorSequence.new(
        resolvedAccent:Lerp(UITheme.Colors.PanelRaised, 0.62),
        UITheme.Colors.Panel
    )
    bannerTitle.Text = mainText or ""
    bannerSub.Text = subText or ""
    -- An urgent disaster introduction is the only foreground notification
    -- on Android. Escalation and pickup toasts must yield while it appears.
    if UserInputService.TouchEnabled then
        MobileHudNotices.claim("intro", 100)
    end
    banner.Visible = true
    local reduced = player:GetAttribute("ReduceMotion") == true
    banner.BackgroundTransparency = reduced and 0.08 or 1
    bannerScale.Scale = reduced and 1 or 0.72

    if not reduced then
        animateBanner(
            banner,
            TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.08}
        )
        animateBanner(
            bannerScale,
            TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1}
        )
    end

    task.delay(duration or 1.8, function()
        if token ~= bannerToken then return end
        bannerFadingOut = true
        if player:GetAttribute("ReduceMotion") == true then
            cancelBannerTweens()
            banner.BackgroundTransparency = 1
            bannerScale.Scale = 1
            banner.Visible = false
            if UserInputService.TouchEnabled then
                MobileHudNotices.release("intro")
            end
            return
        end
        animateBanner(banner, TweenInfo.new(0.22), {BackgroundTransparency = 1})
        animateBanner(bannerScale, TweenInfo.new(0.22), {Scale = 0.88})
        task.wait(0.24)
        if token == bannerToken then
            banner.Visible = false
            if UserInputService.TouchEnabled then
                MobileHudNotices.release("intro")
            end
        end
    end)
end

player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    if player:GetAttribute("ReduceMotion") ~= true then
        return
    end
    if baseFovTween then
        baseFovTween:Cancel()
        baseFovTween = nil
    end
    if lastCameraFovTarget then
        baseFovValue.Value = lastCameraFovTarget
    end
    damageFovKick = 0
    cancelBannerTweens()
    if banner.Visible then
        if bannerFadingOut then
            banner.Visible = false
            banner.BackgroundTransparency = 1
            if UserInputService.TouchEnabled then
                MobileHudNotices.release("intro")
            end
        else
            banner.BackgroundTransparency = 0.08
        end
        bannerScale.Scale = 1
    end
end)

local function setMood(state)
    local phase = state.phase
    local doubleChaos = state.doubleChaos == true
    local ids = state.disasterIds or {}
    local primaryId = ids[1]

    if phase == "round" or phase == "ready" then
        clouds.Enabled = vfxTier.Name ~= "Low"
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
    end

    if phase == "round" then
        Lighting.ExposureCompensation = doubleChaos and -0.04 or 0.02
        Lighting.EnvironmentDiffuseScale = 0.34
        Lighting.EnvironmentSpecularScale = 0.76
    elseif phase == "ready" then
        Lighting.ExposureCompensation = 0.04
        Lighting.EnvironmentDiffuseScale = 0.38
        Lighting.EnvironmentSpecularScale = 0.72
    end

    if phase == "round" or phase == "ready" then
        rays.Enabled = phase == "ready" and vfxTier.RaysEnabled
        rays.Intensity = phase == "ready" and (0.018 * vfxTier.Scale) or 0
        rays.Spread = 0.78

        bloom.Enabled = true
        bloom.Size = 22
        bloom.Threshold = phase == "round" and 1.22 or 1.26

        atmosphere.Glare = 0
        atmosphere.Offset = 0.08

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
            local targetBrightness = (roundParticipant and not roundEliminated)
                and (profile.Brightness or 0) or 0
            local blackoutWindow = phase == "round"
                and primaryId == "Darkness" and not doubleChaos
                and (state.blackoutStage == "PowerReturn"
                    or state.blackoutStage == "Dark")
            if blackoutWindow and roundParticipant and not roundEliminated
                and state.blackoutStage == "PowerReturn" then
                -- Still darker than the arena's normal ambient state:
                -- just enough light to scan a safe route for three seconds.
                targetBrightness = player:GetAttribute("ReduceMotion") == true
                    and -0.14 or -0.08
            end
            setHazardBrightness(targetBrightness, blackoutWindow)
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
            setHazardBrightness(0, false)
            color.Contrast = 0.16
            color.Saturation = 0.22
            color.TintColor = Color3.fromRGB(245, 225, 255)
            vignette.BackgroundColor3 = Color3.fromRGB(115, 15, 160)
            tweenCamera(roundDanger and 82 or 78, 0.24)
        else
            atmosphere.Density = 0.18
            atmosphere.Haze = 0.82
            bloom.Intensity = 0.48 * vfxTier.Scale
            setHazardBrightness(0, false)
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
            local localizedTitle = CoreLocalization.hazardTitle(
                localeId,
                state.disasterIds,
                state.title or "CHAOS!"
            )
            local localizedSub = phase == "ready"
                and CoreLocalization.text(localeId, "POSITION_YOURSELF")
                or CoreLocalization.arenaName(
                    localeId,
                    state.arenaId or state.arenaName,
                    state.arenaName or ""
                )
            showBanner(
                localizedTitle,
                localizedSub,
                doubleChaos
                    and UITheme.Colors.Violet
                    or (profile and profile.Accent or UITheme.Colors.Blue),
                phase == "ready" and 1.15 or 1.6
            )
            lastRoundTitle = state.title
        end
    elseif phase == "result" then
        setHazardBrightness(0, false)
        resetActiveBeacon()
        roundDanger = false
        activeDoubleChaos = false
        secondaryAccent = nil
        tweenCamera(72, 0.35)
    else
        setHazardBrightness(0, false)
        resetActiveBeacon()
        roundDanger = false
        activeDoubleChaos = false
        secondaryAccent = nil
        tweenCamera(70, 0.4)
    end
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
    if type(state) ~= "table" then return end
    if not currentState or currentState.phase ~= state.phase
        or (currentState.roundNumber ~= nil
            and state.roundNumber ~= nil
            and currentState.roundNumber ~= state.roundNumber) then
        resultPulseSerial += 1
    end
    currentState = state
    if state.phase ~= "round" then
        -- A late health event/tween may not repaint the READY, victory
        -- or lobby screen with combat-red after the authoritative phase.
        damageHitSerial += 1
        if damageFadeTween then
            damageFadeTween:Cancel()
            damageFadeTween = nil
        end
        damageFlash.BackgroundTransparency = 1
        damageFovKick = 0
    end
    currentIntensity = math.clamp(tonumber(state.intensity) or 1, 0.85, 1.25)
    setMood(state)

    local alive = tonumber(state.survivorsAlive)
    local total = tonumber(state.contestantCount)

    if state.phase == "round" and total and total > 1 and alive == 1 then
        if not lastSurvivorAnnounced then
            lastSurvivorAnnounced = true
            showBanner(
                CoreLocalization.text(localeId, "RESULT_SOLE_SURVIVOR"),
                CoreLocalization.text(localeId, "ONE_PLAYER_REMAINS"),
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
    if type(feedback) ~= "table" then return end
    resultPulseSerial += 1
    local pulseSerial = resultPulseSerial
    local pulseCharacter = player.Character
    local survivalStreak = tonumber(feedback.streak) or 0

    if survivalStreak >= 2 then
        streak.Text = CoreLocalization.text(localeId, "RESULT_STREAK_TAG", survivalStreak)
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
                CoreLocalization.text(localeId, "JUICE_MASTER_TITLE"),
                CoreLocalization.text(localeId, "JUICE_MASTER_SUB", momentumBest),
                Color3.fromRGB(80, 205, 235),
                2.2
            )
        elseif feedback.criticalSurvival then
            showBanner(
                CoreLocalization.text(localeId, "JUICE_LAST_BREATH_TITLE"),
                CoreLocalization.text(localeId, "JUICE_LAST_BREATH_SUB"),
                Color3.fromRGB(125, 42, 38),
                1.9
            )
        elseif survivalStreak >= 5 then
            showBanner(
                CoreLocalization.text(localeId, "JUICE_UNSTOPPABLE", survivalStreak),
                CoreLocalization.text(
                    localeId,
                    "JUICE_STREAK_BONUS",
                    tonumber(feedback.streakBonusCoins) or 0
                ),
                Color3.fromRGB(115, 72, 18),
                2.0
            )
        elseif survivalStreak >= 3 then
            showBanner(
                CoreLocalization.text(localeId, "JUICE_HOT_STREAK", survivalStreak),
                CoreLocalization.text(localeId, "JUICE_KEEP_RUN"),
                Color3.fromRGB(82, 48, 18),
                1.7
            )
        end

        if player:GetAttribute("ReduceMotion") ~= true then
            tweenCamera(67, 0.12)
            task.delay(0.13, function()
                -- A fresh round or respawn owns its own FOV. Never replay
                -- a delayed old victory zoom over the next disaster.
                if pulseSerial ~= resultPulseSerial
                    or player.Character ~= pulseCharacter
                    or not currentState or currentState.phase ~= "result"
                    or player:GetAttribute("ReduceMotion") == true then
                    return
                end
                tweenCamera(72, 0.28)
            end)
        end
    else
        if player:GetAttribute("ReduceMotion") ~= true then
            tweenCamera(76, 0.10)
            task.delay(0.12, function()
                if pulseSerial ~= resultPulseSerial
                    or player.Character ~= pulseCharacter
                    or not currentState or currentState.phase ~= "result"
                    or player:GetAttribute("ReduceMotion") == true then
                    return
                end
                tweenCamera(72, 0.30)
            end)
        end
    end
end)

-- The 45-second diagnostics used to enumerate thousands of visual
-- Instances *inside RenderStepped*, creating the very hitch we want to
-- measure. Snapshot numeric pacing there; count objects in a yielding task.
-- Do not add a second frame/render owner or change gameplay VFX priorities.
local performancePulsePending = false
local function queuePerformancePulse(snapshot)
    if performancePulsePending then return end
    performancePulsePending = true
    task.spawn(function()
        local ok, err = pcall(function()
            -- Stats availability varies across Android client builds and
            -- permissions. This optional 45-second pulse must never crash
            -- the primary RenderStepped owner that drives adaptive VFX,
            -- lighting and feedback for the rest of the player's session.
            local function optionalStat(read)
                local ok, value = pcall(read)
                return ok and value or 0
            end
            local okVisual, visualMetrics = pcall(VisualBudgetRules.collect,
                workspace, function()
                    -- Yield only in this 45-second, non-authoritative census.
                    -- Other callers retain the synchronous snapshot API.
                    task.wait()
                end)
            if not okVisual or type(visualMetrics) ~= "table" then
                visualMetrics = {Parts = 0, Lights = 0, Effects = 0}
            end
            local sample = PerformancePulseRules.sanitize({
                averageFps = math.floor(snapshot.averageFps + 0.5),
                p95FrameMs = snapshot.p95FrameMs,
                slowFramePercent = snapshot.slowFramePercent,
                vfxTier = snapshot.tier,
                deviceClass = snapshot.deviceClass,
                tierTransitions = snapshot.tierTransitions,
                visualParts = visualMetrics.Parts,
                visualLights = visualMetrics.Lights,
                visualEffects = visualMetrics.Effects,
                totalMemoryMb = optionalStat(function()
                    return Stats:GetTotalMemoryUsageMb()
                end),
                instanceCount = optionalStat(function()
                    return Stats.InstanceCount
                end),
                frameTimeMs = optionalStat(function()
                    return Stats.FrameTime * 1000
                end),
                renderCpuMs = optionalStat(function()
                    return Stats.RenderCPUFrameTime * 1000
                end),
                renderGpuMs = optionalStat(function()
                    return Stats.RenderGPUFrameTime * 1000
                end),
            })

            performancePulseEvent:FireServer(sample)
        end)
        performancePulsePending = false
        if not ok then
            warn("Chaos performance diagnostics unavailable: ", tostring(err))
        end
    end)
end

RunService.RenderStepped:Connect(function(dt)
    if type(dt) ~= "number" or dt ~= dt or dt < 0 then return end
    camera = workspace.CurrentCamera or camera
    damageFovKick *= math.exp(-math.max(0, dt) * 11.5)

    if camera then
        camera.FieldOfView = math.clamp(
            baseFovValue.Value
                + (player:GetAttribute("ReduceMotion") == true
                    and 0 or CameraFeelBus.getMovementFovOffset())
                + (player:GetAttribute("ReduceMotion") == true
                    and 0 or damageFovKick),
            60,
            90
        )
    end

    -- A multi-second frame after switching Android apps is not an FPS
    -- sample; discard the interrupted window rather than punishing the
    -- phone with a false transition to Low graphics. Real 2-5 FPS frames
    -- are still counted and drive appropriate performance reductions.
    local activeDt = VfxQuality.activeFrameSeconds(dt)
    pulseClock += math.min(dt, 1 / 10)
    if activeDt > 0 then
        frameTimeAccumulator += activeDt
        sampleWorstFrameDt = math.max(sampleWorstFrameDt, activeDt)
        FramePacingRules.add(qualityPacing, activeDt)
        FramePacingRules.add(performancePacing, activeDt)
        frameSampleCount += 1
        qualitySampleClock += activeDt
    elseif dt > 0.60 then
        frameTimeAccumulator = 0
        sampleWorstFrameDt = 0
        FramePacingRules.reset(qualityPacing)
        FramePacingRules.reset(performancePacing)
        frameSampleCount = 0
        qualitySampleClock = 0
        qualityCandidate = nil
        qualityCandidateSamples = 0
        performancePulseClock = 0
        performanceFrameCount = 0
    end

    if activeDt > 0 then
        performancePulseClock += activeDt
        performanceFrameCount += 1

        if performancePulseClock >= 45 and performanceFrameCount > 0 then
            local averageFps = math.clamp(
                performanceFrameCount / performancePulseClock,
                0,
                240
            )
            local deviceClass = UserInputService.TouchEnabled and "Touch" or "Desktop"
            local p95FrameMs, slowFramePercent =
                FramePacingRules.summary(performancePacing)

            -- Only snapshot O(1) pacing data on the render callback.
            -- The optional Workspace census runs separately with yields.
            queuePerformancePulse({
                averageFps = averageFps,
                p95FrameMs = p95FrameMs,
                slowFramePercent = slowFramePercent,
                tier = vfxTierName,
                tierTransitions = vfxTierTransitions,
                deviceClass = deviceClass,
            })

            performancePulseClock = 0
            performanceFrameCount = 0
            FramePacingRules.reset(performancePacing)
        end
    end

    if qualitySampleClock >= 2.5 and frameSampleCount > 0 then
        local averageDt = frameTimeAccumulator / frameSampleCount
        local averageFps = averageDt > 0 and (1 / averageDt) or 60
        -- Reuse this authoritative existing frame sampler for staging QA.
        -- Avoid a second RenderStepped owner on weaker Android devices.
        player:SetAttribute("ClientObservedFps", math.floor(math.clamp(averageFps, 0, 240) + 0.5))
        player:SetAttribute("ClientObservedWorstFrameMs",
            math.floor(math.clamp(sampleWorstFrameDt * 1000, 0, 2000) + 0.5))
        -- A single worst frame cannot distinguish sustained stutter from
        -- an isolated OS scheduling spike. Expose robust 2.5-second pacing.
        local observedP95Ms, observedSlowPercent =
            FramePacingRules.summary(qualityPacing)
        player:SetAttribute("ClientObservedP95FrameMs", observedP95Ms)
        player:SetAttribute("ClientObservedSlowFramePercent", observedSlowPercent)
        local nextTierName = VfxQuality.nextTier(
            vfxTierName, averageFps, UserInputService.TouchEnabled
        )

        if nextTierName == vfxTierName then
            qualityCandidate = nil
            qualityCandidateSamples = 0
        else
            if qualityCandidate == nextTierName then
                qualityCandidateSamples += 1
            else
                qualityCandidate = nextTierName
                qualityCandidateSamples = 1
            end

            local requiredSamples = VfxQuality.requiredStableSamples(
                vfxTierName,
                nextTierName,
                UserInputService.TouchEnabled
            )

            if qualityCandidateSamples >= requiredSamples then
                vfxTierName = nextTierName
                vfxTierTransitions += 1
                vfxTier = VfxQuality.get(vfxTierName)
                player:SetAttribute("VfxQualityTier", vfxTierName)
                if currentState and (
                    currentState.phase == "ready"
                    or currentState.phase == "round"
                ) then
                    setMood(currentState)
                end
                qualityCandidate = nil
                qualityCandidateSamples = 0
            end
        end

        frameTimeAccumulator = 0
        sampleWorstFrameDt = 0
        FramePacingRules.reset(qualityPacing)
        frameSampleCount = 0
        qualitySampleClock = 0
    end

    visualUpdateClock += math.min(dt, 1 / 15)
    if visualUpdateClock < vfxTier.UpdateInterval then
        return
    end
    visualUpdateClock = 0

    local reducedMotion = player:GetAttribute("ReduceMotion") == true
    local pulseSpeed = (activeDoubleChaos and 5.2 or 3.6) * currentIntensity
    local wave = reducedMotion and 0.5 or (math.sin(pulseClock * pulseSpeed) + 1) * 0.5
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
    local finalRushActive = currentState
        and currentState.phase == "round"
        and currentState.finalRush == true
        and player:GetAttribute("RoundParticipant") == true
        and player:GetAttribute("RoundEliminated") ~= true

    if finalRushActive then
        local finalWave = reducedMotion
            and 0.5
            or ((math.sin(pulseClock * 6.6) + 1) * 0.5)
        targetTransparency = 0.865 + finalWave * 0.055
        criticalStroke.Color = activeAccent:Lerp(UITheme.Colors.Red, 0.46)
        criticalStroke.Thickness = 5 + finalWave * 2.5
        criticalStroke.Transparency = 0.44 + finalWave * 0.22
    elseif roundDanger then
        targetTransparency = reducedMotion
            and 0.91
            or (0.91 + math.sin(pulseClock * 8) * 0.035)
    end

    local criticalHealth = currentState
        and currentState.phase == "round"
        and player:GetAttribute("RoundParticipant") == true
        and player:GetAttribute("RoundEliminated") ~= true
        and healthRatio > 0
        and healthRatio <= 0.30

    if criticalHealth and not finalRushActive then
        criticalStroke.Color = UITheme.Colors.Red
        criticalStroke.Transparency = reducedMotion and 0.60 or (0.54 + wave * 0.24)
        criticalStroke.Thickness = reducedMotion and 5 or (4 + wave * 2)
    elseif not finalRushActive then
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
            CoreLocalization.text(localeId, "JUICE_FIRST_TITLE"),
            CoreLocalization.text(localeId, "JUICE_FIRST_SUB"),
            Color3.fromRGB(28, 42, 64),
            3.2
        )
    end
end)


-- Health feedback belongs to one LIVE local Humanoid only. Streaming may
-- add a Humanoid well after CharacterAdded, or replace it without respawn.
-- An event-driven binding avoids WaitForChild(5), stale callbacks and
-- duplicate red flashes on Android network stalls.
local healthConnection = nil
local healthChildAddedConnection = nil
local healthChildRemovedConnection = nil
local healthBoundCharacter = nil
local healthBoundHumanoid = nil
local healthBindSerial = 0

local function resetDamagePresentation()
    damageHitSerial += 1
    if damageFadeTween then
        damageFadeTween:Cancel()
        damageFadeTween = nil
    end
    damageFlash.BackgroundTransparency = 1
    damageFovKick = 0
    healthRatio = 1
end

local function detachDamageFeedback()
    healthBindSerial += 1
    if healthConnection then
        healthConnection:Disconnect()
        healthConnection = nil
    end
    if healthChildAddedConnection then
        healthChildAddedConnection:Disconnect()
        healthChildAddedConnection = nil
    end
    if healthChildRemovedConnection then
        healthChildRemovedConnection:Disconnect()
        healthChildRemovedConnection = nil
    end
    healthBoundCharacter = nil
    healthBoundHumanoid = nil
    resetDamagePresentation()
end

local function bindDamageFeedback(character)
    -- The initial task.defer may run after a newer CharacterAdded.
    if player.Character ~= character then return end
    detachDamageFeedback()
    local serial = healthBindSerial
    healthBoundCharacter = character

    local function bindLiveHumanoid()
        if serial ~= healthBindSerial
            or player.Character ~= character
            or healthBoundCharacter ~= character then
            return
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Parent ~= character
            or healthBoundHumanoid == humanoid then
            return
        end
        if healthConnection then
            healthConnection:Disconnect()
            healthConnection = nil
        end
        healthBoundHumanoid = humanoid
        resetDamagePresentation()
        local previousHealth = humanoid.Health
        healthRatio = humanoid.MaxHealth > 0
            and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) or 1
        healthConnection = humanoid.HealthChanged:Connect(function(health)
            if not RoundEventPresentation.damageOwnerValid(
                serial, healthBindSerial, character, player.Character,
                humanoid, healthBoundHumanoid
            ) then
                return
            end
            healthRatio = humanoid.MaxHealth > 0
                and math.clamp(health / humanoid.MaxHealth, 0, 1) or 1
            local lost = previousHealth - health
            previousHealth = health
            -- Spectators, eliminated avatars and the lobby must not
            -- display combat damage after a server round transition.
            if lost <= 0 or health <= 0
                or not currentState or currentState.phase ~= "round"
                or player:GetAttribute("RoundParticipant") ~= true
                or player:GetAttribute("RoundEliminated") == true then
                return
            end
            local damageRatio = humanoid.MaxHealth > 0
                and math.clamp(lost / humanoid.MaxHealth, 0, 1) or 0
            local criticalHit = damageRatio >= 0.22
            damageFlash.BackgroundColor3 = criticalHit
                and Color3.fromRGB(255, 74, 54)
                or Color3.fromRGB(210, 35, 35)
            damageGradient.Rotation = (damageGradient.Rotation + 37) % 360
            if damageFadeTween then
                damageFadeTween:Cancel()
            end
            damageFlash.BackgroundTransparency = math.clamp(
                0.90 - damageRatio * 0.82, 0.58, 0.88
            )
            damageFadeTween = TweenService:Create(
                damageFlash,
                TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundTransparency = 1}
            )
            damageFadeTween:Play()

            local fovKick = 1.4 + damageRatio * 4.6
            if player:GetAttribute("ReduceMotion") == true then
                fovKick *= 0.16
            end
            damageFovKick = math.max(
                damageFovKick, math.min(6.0, fovKick)
            )

            damageHitSerial += 1
            local hitSerial = damageHitSerial
            if criticalHit and vfxTier.Name ~= "Low" then
                bloom.Intensity = math.min(
                    1.15, bloom.Intensity + 0.22 * vfxTier.Scale
                )
                task.delay(0.10, function()
                    if hitSerial ~= damageHitSerial
                        or not RoundEventPresentation.damageOwnerValid(
                            serial, healthBindSerial, character, player.Character,
                            humanoid, healthBoundHumanoid
                        ) then
                        return
                    end
                    if currentState then
                        setMood(currentState)
                    end
                end)
            end
        end)
    end

    healthChildAddedConnection = character.ChildAdded:Connect(function(child)
        if child:IsA("Humanoid") then task.defer(bindLiveHumanoid) end
    end)
    healthChildRemovedConnection = character.ChildRemoved:Connect(function(child)
        if child ~= healthBoundHumanoid then return end
        if healthConnection then
            healthConnection:Disconnect()
            healthConnection = nil
        end
        healthBoundHumanoid = nil
        resetDamagePresentation()
        task.defer(bindLiveHumanoid)
    end)
    bindLiveHumanoid()
end

if player.Character then
    task.defer(bindDamageFeedback, player.Character)
end

player.CharacterAdded:Connect(bindDamageFeedback)
player.CharacterRemoving:Connect(function(removingCharacter)
    if healthBoundCharacter == removingCharacter then
        detachDamageFeedback()
    end
end)
