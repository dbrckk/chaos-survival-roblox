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

local MOODS = {
    Classic = {
        Tint = Color3.fromRGB(224, 236, 255),
        Ambient = Color3.fromRGB(72, 83, 112),
        Outdoor = Color3.fromRGB(104, 120, 154),
        Saturation = 0.025,
        Contrast = 0.018,
        Diffuse = 0.72,
        Specular = 0.88,
        ShadowSoftness = 0.34,
    },
    Towers = {
        Tint = Color3.fromRGB(210, 244, 250),
        Ambient = Color3.fromRGB(65, 84, 101),
        Outdoor = Color3.fromRGB(94, 130, 143),
        Saturation = 0.015,
        Contrast = 0.030,
        Diffuse = 0.66,
        Specular = 0.94,
        ShadowSoftness = 0.26,
    },
    Crossroads = {
        Tint = Color3.fromRGB(242, 218, 255),
        Ambient = Color3.fromRGB(83, 66, 101),
        Outdoor = Color3.fromRGB(126, 101, 148),
        Saturation = 0.035,
        Contrast = 0.026,
        Diffuse = 0.68,
        Specular = 0.84,
        ShadowSoftness = 0.42,
    },
    Orbital = {
        Tint = Color3.fromRGB(214, 255, 241),
        Ambient = Color3.fromRGB(61, 91, 91),
        Outdoor = Color3.fromRGB(91, 137, 132),
        Saturation = 0.030,
        Contrast = 0.022,
        Diffuse = 0.62,
        Specular = 1.00,
        ShadowSoftness = 0.30,
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

    local materialScale = quality.Name == "Low" and 0.70
        or (quality.Name == "Medium" and 0.86 or 1)
    local diffuse = math.clamp((mood.Diffuse or 0.7) * materialScale, 0.35, 1)
    local specular = math.clamp((mood.Specular or 0.9) * materialScale, 0.30, 1)
    local shadowSoftness = math.clamp(
        (mood.ShadowSoftness or 0.35) + (quality.Name == "Low" and 0.20 or 0),
        0,
        1
    )

    TweenService:Create(
        effect,
        TweenInfo.new(duration or 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            TintColor = Color3.new(1, 1, 1):Lerp(mood.Tint, 0.34 * scale),
            Saturation = mood.Saturation * scale,
            Contrast = mood.Contrast * scale,
        }
    ):Play()

    TweenService:Create(
        Lighting,
        TweenInfo.new(duration or 0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Ambient = mood.Ambient,
            OutdoorAmbient = mood.Outdoor,
            EnvironmentDiffuseScale = diffuse,
            EnvironmentSpecularScale = specular,
            ShadowSoftness = shadowSoftness,
        }
    ):Play()
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
