local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local effect = Lighting:FindFirstChild("ArenaIdentityColor")
if not effect then
    effect = Instance.new("ColorCorrectionEffect")
    effect.Name = "ArenaIdentityColor"
    effect.Parent = Lighting
end

local atmosphere = Lighting:FindFirstChild("ArenaIdentityAtmosphere")
if not atmosphere then
    atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "ArenaIdentityAtmosphere"
    atmosphere.Parent = Lighting
end

local bloom = Lighting:FindFirstChild("ArenaIdentityBloom")
if not bloom then
    bloom = Instance.new("BloomEffect")
    bloom.Name = "ArenaIdentityBloom"
    bloom.Intensity = 0
    bloom.Size = 18
    bloom.Threshold = 1.22
    bloom.Parent = Lighting
end

local depth = Lighting:FindFirstChild("ArenaIdentityDepth")
if not depth then
    depth = Instance.new("DepthOfFieldEffect")
    depth.Name = "ArenaIdentityDepth"
    depth.Enabled = true
    depth.FocusDistance = 55
    depth.InFocusRadius = 45
    depth.NearIntensity = 0
    depth.FarIntensity = 0
    depth.Parent = Lighting
end

local sunRays = Lighting:FindFirstChild("ArenaIdentitySunRays")
if not sunRays then
    sunRays = Instance.new("SunRaysEffect")
    sunRays.Name = "ArenaIdentitySunRays"
    sunRays.Intensity = 0
    sunRays.Spread = 0.78
    sunRays.Parent = Lighting
end

local terrain = workspace:FindFirstChildOfClass("Terrain")
local clouds = terrain and terrain:FindFirstChildOfClass("Clouds")
if terrain and not clouds then
    clouds = Instance.new("Clouds")
    clouds.Name = "ArenaIdentityClouds"
    clouds.Enabled = true
    clouds.Cover = 0.38
    clouds.Density = 0.18
    clouds.Parent = terrain
end

local MOODS = {
    Classic = {
        Tint = Color3.fromRGB(224, 236, 255),
        Ambient = Color3.fromRGB(72, 83, 112),
        Outdoor = Color3.fromRGB(104, 120, 154),
        Saturation = 0.025,
        Contrast = 0.018,
        ColorShiftTop = Color3.fromRGB(8, 14, 24),
        ColorShiftBottom = Color3.fromRGB(4, 7, 13),
        ShadowSoftness = 0.34,
        CloudColor = Color3.fromRGB(205, 220, 245),
        AtmosColor = Color3.fromRGB(184, 209, 242),
        AtmosDecay = Color3.fromRGB(68, 82, 116),
        Density = 0.18,
        Haze = 1.20,
        Glare = 0.10,
        ClockTime = 18.45,
        Exposure = -0.10,
        EnvironmentDiffuse = 0.34,
        EnvironmentSpecular = 0.78,
        SunRays = 0.030,
        AtmosOffset = 0.10,
        CloudCover = 0.34,
        CloudDensity = 0.16,
        Wind = Vector3.new(6, 0, -3),
    },
    Towers = {
        Tint = Color3.fromRGB(210, 244, 250),
        Ambient = Color3.fromRGB(65, 84, 101),
        Outdoor = Color3.fromRGB(94, 130, 143),
        Saturation = 0.015,
        Contrast = 0.030,
        ColorShiftTop = Color3.fromRGB(4, 18, 22),
        ColorShiftBottom = Color3.fromRGB(3, 8, 12),
        ShadowSoftness = 0.26,
        CloudColor = Color3.fromRGB(190, 225, 232),
        AtmosColor = Color3.fromRGB(164, 220, 228),
        AtmosDecay = Color3.fromRGB(48, 82, 92),
        Density = 0.20,
        Haze = 1.35,
        Glare = 0.08,
        ClockTime = 17.85,
        Exposure = -0.08,
        EnvironmentDiffuse = 0.38,
        EnvironmentSpecular = 0.84,
        SunRays = 0.026,
        AtmosOffset = 0.14,
        CloudCover = 0.48,
        CloudDensity = 0.22,
        Wind = Vector3.new(9, 0, -5),
    },
    Crossroads = {
        Tint = Color3.fromRGB(242, 218, 255),
        Ambient = Color3.fromRGB(83, 66, 101),
        Outdoor = Color3.fromRGB(126, 101, 148),
        Saturation = 0.035,
        Contrast = 0.026,
        ColorShiftTop = Color3.fromRGB(18, 7, 24),
        ColorShiftBottom = Color3.fromRGB(8, 4, 13),
        ShadowSoftness = 0.42,
        CloudColor = Color3.fromRGB(226, 198, 238),
        AtmosColor = Color3.fromRGB(222, 181, 240),
        AtmosDecay = Color3.fromRGB(78, 48, 96),
        Density = 0.17,
        Haze = 1.10,
        Glare = 0.12,
        ClockTime = 19.10,
        Exposure = -0.14,
        EnvironmentDiffuse = 0.30,
        EnvironmentSpecular = 0.72,
        SunRays = 0.036,
        AtmosOffset = 0.08,
        CloudCover = 0.42,
        CloudDensity = 0.20,
        Wind = Vector3.new(5, 0, 7),
    },
    Orbital = {
        Tint = Color3.fromRGB(214, 255, 241),
        Ambient = Color3.fromRGB(61, 91, 91),
        Outdoor = Color3.fromRGB(91, 137, 132),
        Saturation = 0.030,
        Contrast = 0.022,
        ColorShiftTop = Color3.fromRGB(5, 20, 17),
        ColorShiftBottom = Color3.fromRGB(3, 9, 9),
        ShadowSoftness = 0.30,
        CloudColor = Color3.fromRGB(190, 232, 220),
        AtmosColor = Color3.fromRGB(164, 230, 210),
        AtmosDecay = Color3.fromRGB(44, 88, 78),
        Density = 0.19,
        Haze = 1.25,
        Glare = 0.09,
        ClockTime = 18.20,
        Exposure = -0.06,
        EnvironmentDiffuse = 0.42,
        EnvironmentSpecular = 0.88,
        SunRays = 0.032,
        AtmosOffset = 0.18,
        CloudCover = 0.26,
        CloudDensity = 0.13,
        Wind = Vector3.new(7, 0, 4),
    },
}

local phase = "waiting"
local currentVariant = "Classic"
local mapConnection = nil

local function readVariant()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    return tostring(arena and arena:GetAttribute("VariantId") or "Classic")
end

local function applyMood(duration)
    currentVariant = readVariant()
    local mood = MOODS[currentVariant] or MOODS.Classic
    local reducedMotion = player:GetAttribute("ReduceMotion") == true
    local quality = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local roundScale = phase == "round" and 0.34 or (phase == "ready" and 0.62 or 1)
    local accessibilityScale = reducedMotion and 0.72 or 1
    local scale = roundScale * accessibilityScale

    local colorShiftScale = quality.Name == "Low" and 0.42
        or (quality.Name == "Medium" and 0.72 or 1)
    local bloomBase = quality.Name == "Low" and 0.045
        or (quality.Name == "Medium" and 0.11 or 0.18)
    local bloomPhaseScale = phase == "round" and 0.34
        or (phase == "ready" and 0.68 or 1)
    local bloomIntensity = bloomBase * bloomPhaseScale
    local bloomSize = quality.Name == "Low" and 12
        or (quality.Name == "Medium" and 18 or 24)
    local bloomThreshold = phase == "round" and 1.42
        or (phase == "ready" and 1.30 or 1.18)
    local depthQualityScale = quality.Name == "Low" and 0
        or (quality.Name == "Medium" and 0.45 or 1)
    local depthPhaseScale = phase == "round" and 0
        or (phase == "ready" and 0.36 or (phase == "result" and 0.72 or 1))
    local depthMotionScale = reducedMotion and 0.45 or 1
    local farIntensity = 0.12 * depthQualityScale * depthPhaseScale * depthMotionScale
    local nearIntensity = 0.035 * depthQualityScale * depthPhaseScale * depthMotionScale
    local renderScale = quality.Name == "Low" and 0.48
        or (quality.Name == "Medium" and 0.76 or 1)
    local environmentDiffuse = (mood.EnvironmentDiffuse or 0.30) * renderScale
    local environmentSpecular = (mood.EnvironmentSpecular or 0.70) * renderScale
    local exposure = (mood.Exposure or 0) * (quality.Name == "Low" and 0.45 or 1)
    local sunRayIntensity = (mood.SunRays or 0.025)
        * (phase == "round" and 0 or (phase == "ready" and 0.35 or 1))
        * (quality.Name == "Low" and 0 or 1)
        * accessibilityScale
    local disasterOwnsEnvironment = phase == "round" or phase == "ready"
    local shadowSoftness = math.clamp(
        (mood.ShadowSoftness or 0.35) + (quality.Name == "Low" and 0.20 or 0),
        0,
        1
    )
    local colorShiftTop = Color3.new():Lerp(mood.ColorShiftTop or Color3.new(), colorShiftScale)
    local colorShiftBottom = Color3.new():Lerp(mood.ColorShiftBottom or Color3.new(), colorShiftScale)

    TweenService:Create(
        effect,
        TweenInfo.new(duration or 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            TintColor = Color3.new(1, 1, 1):Lerp(mood.Tint, 0.34 * scale),
            Saturation = mood.Saturation * scale,
            Contrast = mood.Contrast * scale,
        }
    ):Play()

    pcall(function()
        Lighting.LightingStyle = Enum.LightingStyle.Realistic
        Lighting.PrioritizeLightingQuality = quality.Name ~= "Low"
        Lighting.GlobalShadows = true
    end)

    local lightingGoal = {
        Ambient = mood.Ambient,
        OutdoorAmbient = mood.Outdoor,
        ColorShift_Top = colorShiftTop,
        ColorShift_Bottom = colorShiftBottom,
        ShadowSoftness = shadowSoftness,
        ClockTime = mood.ClockTime or 18,
    }
    if not disasterOwnsEnvironment then
        lightingGoal.ExposureCompensation = exposure
        lightingGoal.EnvironmentDiffuseScale = environmentDiffuse
        lightingGoal.EnvironmentSpecularScale = environmentSpecular
    end

    TweenService:Create(
        Lighting,
        TweenInfo.new(duration or 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        lightingGoal
    ):Play()

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

    TweenService:Create(
        atmosphere,
        TweenInfo.new(duration or 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Color = mood.AtmosColor or mood.Tint,
            Decay = mood.AtmosDecay or mood.Ambient,
            Density = (mood.Density or 0.18)
                * (phase == "round" and 0.28 or (phase == "ready" and 0.55 or 1))
                * (quality.Name == "Low" and 0.58 or 1),
            Haze = (mood.Haze or 1.0)
                * (phase == "round" and 0.32 or (phase == "ready" and 0.62 or 1))
                * (quality.Name == "Low" and 0.55 or 1),
            Glare = (mood.Glare or 0.08)
                * (phase == "round" and 0.25 or (phase == "ready" and 0.50 or 1))
                * (quality.Name == "Low" and 0 or 1),
            Offset = (mood.AtmosOffset or 0.10)
                * (quality.Name == "Low" and 0.55 or 1),
        }
    ):Play()

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

local function bindMap()
    if mapConnection then
        mapConnection:Disconnect()
        mapConnection = nil
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    if generated then
        mapConnection = generated.ChildAdded:Connect(function(child)
            if child.Name == "Arena" then
                task.delay(0.05, function()
                    applyMood(0.85)
                end)
            end
        end)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(function()
            bindMap()
            applyMood(0.85)
        end)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindMap()
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    phase = tostring(state.phase or "waiting")
    applyMood(phase == "round" and 0.35 or 0.65)
end)

player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    applyMood(0.35)
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    applyMood(0.35)
end)

bindMap()
applyMood(0)
