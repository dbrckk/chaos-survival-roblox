local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local ArenaLightingReadabilityRules = require(ReplicatedStorage.Shared.ArenaLightingReadabilityRules)
local CloudLayer = require(script.Parent.CloudLayer)
local ArenaPostProcessLayer = require(script.Parent.ArenaPostProcessLayer)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local post = ArenaPostProcessLayer.get()
local effect = post.Color
local atmosphere = post.Atmosphere
local bloom = post.Bloom
local depth = post.Depth
local sunRays = post.SunRays

bloom.Intensity = bloom.Intensity or 0
bloom.Size = bloom.Size > 0 and bloom.Size or 18
bloom.Threshold = bloom.Threshold > 0 and bloom.Threshold or 1.22

depth.Enabled = true
depth.FocusDistance = depth.FocusDistance > 0 and depth.FocusDistance or 55
depth.InFocusRadius = depth.InFocusRadius > 0 and depth.InFocusRadius or 45
depth.NearIntensity = depth.NearIntensity or 0
depth.FarIntensity = depth.FarIntensity or 0

sunRays.Intensity = sunRays.Intensity or 0
sunRays.Spread = sunRays.Spread > 0 and sunRays.Spread or 0.78

local terrain = workspace:FindFirstChildOfClass("Terrain")
local clouds = CloudLayer.getOrCreate()

local MOODS = {
    Classic = {
        Tint = Color3.fromRGB(237, 243, 255),
        Ambient = Color3.fromRGB(151, 160, 175),
        Outdoor = Color3.fromRGB(190, 202, 211),
        Saturation = 0.025,
        Contrast = 0.032,
        ColorShiftTop = Color3.fromRGB(8, 14, 24),
        ColorShiftBottom = Color3.fromRGB(4, 7, 13),
        ShadowSoftness = 0.34,
        CloudColor = Color3.fromRGB(205, 220, 245),
        AtmosColor = Color3.fromRGB(200, 217, 238),
        AtmosDecay = Color3.fromRGB(68, 82, 116),
        Density = 0.155,
        Haze = 0.92,
        Glare = 0.10,
        ClockTime = 14.25,
        Latitude = 36,
        Exposure = 0.13,
        EnvironmentDiffuse = 0.45,
        EnvironmentSpecular = 0.70,
        SunRays = 0.030,
        AtmosOffset = 0.10,
        CloudCover = 0.34,
        CloudDensity = 0.16,
        Wind = Vector3.new(6, 0, -3),
    },
    Towers = {
        Tint = Color3.fromRGB(232, 246, 249),
        Ambient = Color3.fromRGB(150, 165, 172),
        Outdoor = Color3.fromRGB(189, 201, 207),
        Saturation = 0.015,
        Contrast = 0.041,
        ColorShiftTop = Color3.fromRGB(4, 18, 22),
        ColorShiftBottom = Color3.fromRGB(3, 8, 12),
        ShadowSoftness = 0.26,
        CloudColor = Color3.fromRGB(190, 225, 232),
        AtmosColor = Color3.fromRGB(189, 222, 230),
        AtmosDecay = Color3.fromRGB(48, 82, 92),
        Density = 0.155,
        Haze = 1.00,
        Glare = 0.08,
        ClockTime = 11.30,
        Latitude = 59,
        Exposure = 0.14,
        EnvironmentDiffuse = 0.47,
        EnvironmentSpecular = 0.72,
        SunRays = 0.026,
        AtmosOffset = 0.14,
        CloudCover = 0.48,
        CloudDensity = 0.22,
        Wind = Vector3.new(9, 0, -5),
    },
    Crossroads = {
        Tint = Color3.fromRGB(238, 232, 249),
        Ambient = Color3.fromRGB(153, 150, 164),
        Outdoor = Color3.fromRGB(192, 184, 200),
        Saturation = 0.035,
        Contrast = 0.036,
        ColorShiftTop = Color3.fromRGB(18, 7, 24),
        ColorShiftBottom = Color3.fromRGB(8, 4, 13),
        ShadowSoftness = 0.42,
        CloudColor = Color3.fromRGB(226, 198, 238),
        AtmosColor = Color3.fromRGB(210, 203, 225),
        AtmosDecay = Color3.fromRGB(78, 48, 96),
        Density = 0.155,
        Haze = 0.90,
        Glare = 0.12,
        ClockTime = 16.15,
        Latitude = 27,
        Exposure = 0.14,
        EnvironmentDiffuse = 0.44,
        EnvironmentSpecular = 0.68,
        SunRays = 0.036,
        AtmosOffset = 0.08,
        CloudCover = 0.42,
        CloudDensity = 0.20,
        Wind = Vector3.new(5, 0, 7),
    },
    Orbital = {
        Tint = Color3.fromRGB(232, 250, 245),
        Ambient = Color3.fromRGB(145, 165, 162),
        Outdoor = Color3.fromRGB(190, 207, 202),
        Saturation = 0.030,
        Contrast = 0.035,
        ColorShiftTop = Color3.fromRGB(5, 20, 17),
        ColorShiftBottom = Color3.fromRGB(3, 9, 9),
        ShadowSoftness = 0.30,
        CloudColor = Color3.fromRGB(190, 232, 220),
        AtmosColor = Color3.fromRGB(190, 222, 217),
        AtmosDecay = Color3.fromRGB(44, 88, 78),
        Density = 0.145,
        Haze = 0.85,
        Glare = 0.09,
        ClockTime = 12.10,
        Latitude = 72,
        Exposure = 0.14,
        EnvironmentDiffuse = 0.49,
        EnvironmentSpecular = 0.77,
        SunRays = 0.032,
        AtmosOffset = 0.18,
        CloudCover = 0.26,
        CloudDensity = 0.13,
        Wind = Vector3.new(7, 0, 4),
    },
    -- Storm Harbor should never inherit Classic's cold blue survey-grid
    -- light: ocean haze, painted steel, cargo timber and warning decals
    -- need a distinct neutral maritime palette with readable contrast.
    -- No new lights or post-process instances; reuse the same controller,
    -- one existing atmosphere layer and Android Low/Medium/High budgets.
    Harbor = {
        Tint = Color3.fromRGB(237, 240, 230),
        Ambient = Color3.fromRGB(155, 166, 161),
        Outdoor = Color3.fromRGB(194, 204, 197),
        Saturation = -0.008,
        Contrast = 0.040,
        ColorShiftTop = Color3.fromRGB(13, 16, 13),
        ColorShiftBottom = Color3.fromRGB(7, 10, 11),
        ShadowSoftness = 0.38,
        CloudColor = Color3.fromRGB(212, 222, 217),
        AtmosColor = Color3.fromRGB(204, 216, 213),
        AtmosDecay = Color3.fromRGB(83, 96, 101),
        Density = 0.175,
        Haze = 1.10,
        Glare = 0.065,
        ClockTime = 10.75,
        Latitude = 44,
        Exposure = 0.13,
        EnvironmentDiffuse = 0.47,
        EnvironmentSpecular = 0.69,
        SunRays = 0.025,
        AtmosOffset = 0.07,
        CloudCover = 0.45,
        CloudDensity = 0.19,
        Wind = Vector3.new(8, 0, -6),
    },
}

local phase = "waiting"
local darknessActive = false
local currentVariant = "Classic"
local disconnectMapWatch = nil
local refreshPending = false

local function readVariant()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    return tostring(arena and arena:GetAttribute("VariantId") or "Classic")
end

local function applyMood(duration)
    currentVariant = readVariant()
    local mood = MOODS[currentVariant] or MOODS.Classic
    local reducedMotion = player:GetAttribute("ReduceMotion") == true
    local quality = VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled)
    local roundScale = phase == "round" and 0.14 or (phase == "ready" and 0.50 or 1)
    local accessibilityScale = reducedMotion and 0.72 or 1
    local scale = roundScale * accessibilityScale

    local colorShiftScale = quality.Name == "Low" and 0.42
        or (quality.Name == "Medium" and 0.72 or 1)
    -- A small halo is enough for neon; high settings previously made
    -- cyan trim bleed over silhouettes, especially on OLED phones.
    local bloomBase = quality.Name == "Low" and 0.035
        or (quality.Name == "Medium" and 0.070 or 0.105)
    local bloomPhaseScale = phase == "round" and 0.16
        or (phase == "ready" and 0.52 or 1)
    local bloomIntensity = bloomBase * bloomPhaseScale
    local bloomSize = quality.Name == "Low" and 12
        or (quality.Name == "Medium" and 18 or 24)
    local bloomThreshold = phase == "round" and 1.48
        or (phase == "ready" and 1.38 or 1.30)
    local depthQualityScale = quality.Name == "Low" and 0
        or (quality.Name == "Medium" and 0.45 or 1)
    local depthPhaseScale = phase == "round" and 0
        or (phase == "ready" and 0.36 or (phase == "result" and 0.72 or 1))
    local depthMotionScale = reducedMotion and 0.45 or 1
    local farIntensity = 0.12 * depthQualityScale * depthPhaseScale * depthMotionScale
    local nearIntensity = 0.035 * depthQualityScale * depthPhaseScale * depthMotionScale
    -- Keep genuine material surface relief readable on Low/Medium as
    -- well as High. The disaster owner takes over during ready/round,
    -- so these scales affect only lobby, results and ambient daylight.
    local renderScale, exposureScale =
        ArenaLightingReadabilityRules.identityScale(quality.Name)
    local environmentDiffuse = (mood.EnvironmentDiffuse or 0.30) * renderScale
    local environmentSpecular = (mood.EnvironmentSpecular or 0.70) * renderScale
    local exposure = (mood.Exposure or 0) * exposureScale
    local sunRayIntensity = (mood.SunRays or 0.025)
        * (phase == "round" and 0 or (phase == "ready" and 0.35 or 1))
        * (quality.Name == "Low" and 0 or 1)
        * accessibilityScale
    local disasterOwnsEnvironment = phase == "round" or phase == "ready"
    local disasterOwnsPostProcess = disasterOwnsEnvironment
    local shadowSoftness = math.clamp(
        (mood.ShadowSoftness or 0.35) + (quality.Name == "Low" and 0.20 or 0),
        0,
        1
    )

    -- Source-only visual QA identity. Numeric values describe our
    -- *authored* profile, not measured FPS, screenshots, shadows or
    -- final disaster-controlled exposure. No RemoteEvents or new loops.
    local diagnostic = {
        LocalLightingArtVariant = currentVariant,
        LocalLightingSolarClock = mood.ClockTime or 15,
        LocalLightingLatitude = mood.Latitude or 36,
        LocalLightingQualityTier = quality.Name,
        -- Desired profile, NOT a measured pixel/lighting screenshot.
        LocalIdentityDarknessFillSuppressed = darknessActive
            and disasterOwnsEnvironment,
    }
    for name, value in pairs(diagnostic) do
        if player:GetAttribute(name) ~= value then
            player:SetAttribute(name, value)
        end
    end

    local colorShiftTop = Color3.new():Lerp(mood.ColorShiftTop or Color3.new(), colorShiftScale)
    local colorShiftBottom = Color3.new():Lerp(mood.ColorShiftBottom or Color3.new(), colorShiftScale)

    if not disasterOwnsPostProcess then
        TweenService:Create(
            effect,
            TweenInfo.new(duration or 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                TintColor = Color3.new(1, 1, 1):Lerp(mood.Tint, 0.34 * scale),
                Saturation = mood.Saturation * scale,
                Contrast = mood.Contrast * scale,
            }
        ):Play()
    end

    pcall(function()
        Lighting.LightingStyle = Enum.LightingStyle.Realistic
        Lighting.PrioritizeLightingQuality = quality.Name ~= "Low"
        Lighting.GlobalShadows = quality.Name ~= "Low"
    end)

    local lightingGoal = {
        Ambient = mood.Ambient,
        OutdoorAmbient = mood.Outdoor,
        ColorShift_Top = colorShiftTop,
        ColorShift_Bottom = colorShiftBottom,
        ShadowSoftness = shadowSoftness,
        ClockTime = mood.ClockTime or 15,
        GeographicLatitude = mood.Latitude or 36,
        -- Five physically distinct sun elevations and latitudes provide
        -- deliberate key-light/shadow directions without new light Parts.
        -- Balanced daylight rather than almost-black dusk: players must
        -- distinguish real platform sides from empty sky on phones.
        -- Server disaster warnings/blackouts still own their own effects.
        Brightness = quality.Name == "Low" and 2.80 or 2.60,
    }
    if not disasterOwnsEnvironment then
        lightingGoal.ExposureCompensation = exposure
        lightingGoal.EnvironmentDiffuseScale = environmentDiffuse
        lightingGoal.EnvironmentSpecularScale = environmentSpecular
    elseif UserInputService.TouchEnabled and not darknessActive then
        -- Darkness (primary OR secondary) is a deliberate low-visibility
        -- catastrophe. Do not reintroduce bright neutral mobile fill
        -- after the disaster owner has enabled its blackout materials.
        -- Actual Android screenshots: during live RisingLava/JumpShock,
        -- the HUD/neon were legible but the real floor and bot silhouettes
        -- were near black. Preserve disaster-owned color grading and fog;
        -- provide a modest neutral fill for physical route readability.
        -- Do NOT override ExposureCompensation: Darkness and other
        -- disaster-specific exposure effects retain server ownership.
        lightingGoal.Ambient = mood.Ambient:Lerp(
            Color3.fromRGB(166, 171, 177), 0.38)
        lightingGoal.OutdoorAmbient = mood.Outdoor:Lerp(
            Color3.fromRGB(188, 192, 194), 0.30)
        lightingGoal.Brightness = quality.Name == "Low" and 3.0 or 2.85
    end

    TweenService:Create(
        Lighting,
        TweenInfo.new(duration or 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        lightingGoal
    ):Play()

    if not disasterOwnsPostProcess then
        bloom.Enabled = true
        sunRays.Enabled = quality.Name ~= "Low"

        TweenService:Create(
            bloom,
            TweenInfo.new(duration or 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Intensity = bloomIntensity,
                Size = bloomSize,
                Threshold = bloomThreshold,
            }
        ):Play()

        TweenService:Create(
            sunRays,
            TweenInfo.new(duration or 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Intensity = sunRayIntensity,
                Spread = quality.Name == "High" and 0.82 or 0.70,
            }
        ):Play()
    end

    TweenService:Create(
        depth,
        TweenInfo.new(duration or 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            FocusDistance = currentVariant == "Towers" and 62
                or (currentVariant == "Orbital" and 58 or 54),
            InFocusRadius = phase == "round" and 72 or 46,
            NearIntensity = nearIntensity,
            FarIntensity = farIntensity,
        }
    ):Play()

    if not disasterOwnsPostProcess then
        TweenService:Create(
            atmosphere,
            TweenInfo.new(duration or 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Color = mood.AtmosColor or mood.Tint,
                Decay = mood.AtmosDecay or mood.Ambient,
                Density = (mood.Density or 0.18)
                    * (quality.Name == "Low" and 0.58 or 1),
                Haze = (mood.Haze or 1.0)
                    * (quality.Name == "Low" and 0.55 or 1),
                Glare = (mood.Glare or 0.08)
                    * (quality.Name == "Low" and 0 or 1),
                Offset = (mood.AtmosOffset or 0.10)
                    * (quality.Name == "Low" and 0.55 or 1),
            }
        ):Play()
    end

    if clouds and not disasterOwnsEnvironment then
        clouds.Enabled = quality.Name ~= "Low"
        clouds.Color = mood.CloudColor or Color3.fromRGB(210, 220, 240)
        clouds.Cover = math.clamp(mood.CloudCover or 0.35, 0, 1)
        clouds.Density = math.clamp(
            (mood.CloudDensity or 0.18)
                * (quality.Name == "Medium" and 0.82 or 1),
            0,
            1
        )
    end

    pcall(function()
        local wind = mood.Wind or Vector3.new(5, 0, -3)
        workspace.GlobalWind = wind * (quality.Name == "Low" and 0.45 or 1)
    end)
end

-- A map can arrive before Arena.Base and its VariantId attribute.
-- Keep the art direction synchronized without stacking duplicate tweens.
local function scheduleMoodRefresh()
    if refreshPending then return end
    refreshPending = true
    task.defer(function()
        refreshPending = false
        applyMood(0.65)
    end)
end

local function bindMap(generated)
    if disconnectMapWatch then
        disconnectMapWatch()
        disconnectMapWatch = nil
    end
    if generated then
        disconnectMapWatch = MapVisualReadiness.watch(
            generated, "Arena", "Base", scheduleMoodRefresh
        )
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindMap(child)
        scheduleMoodRefresh()
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindMap(nil)
        scheduleMoodRefresh()
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    local nextPhase = tostring(state.phase or "waiting")
    -- The disaster pairing can change inside the SAME phase (including
    -- Darkness in slot 2). Do not ignore that authoritative difference
    -- just because another RoundState countdown second arrived.
    -- With a partial packet, preserve the previous guard until the
    -- disaster list is explicitly supplied or the round ends.
    local hasIds = type(state.disasterIds) == "table"
    local nextDarkness = nextPhase == "round" or nextPhase == "ready"
    nextDarkness = nextDarkness and (hasIds
        and ArenaLightingReadabilityRules.hasDarkness(state.disasterIds)
        or (not hasIds and nextPhase == phase and darknessActive))
    if nextPhase == phase and nextDarkness == darknessActive then return end
    phase = nextPhase
    darknessActive = nextDarkness
    applyMood(phase == "round" and 0.35 or 0.65)
end)

player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    applyMood(0.35)
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    applyMood(0.35)
end)

bindMap(workspace:FindFirstChild("GeneratedMap"))
applyMood(0)
