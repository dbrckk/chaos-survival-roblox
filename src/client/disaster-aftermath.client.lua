local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local tint = Lighting:FindFirstChild("ChaosAftermathTint")
if tint and not tint:IsA("ColorCorrectionEffect") then
    tint:Destroy()
    tint = nil
end
if not tint then
    tint = Instance.new("ColorCorrectionEffect")
end
tint.Name = "ChaosAftermathTint"
tint.Enabled = true
tint.Brightness = 0
tint.Contrast = 0
tint.Saturation = 0
tint.TintColor = Color3.new(1, 1, 1)
tint.Parent = Lighting

local blur = Lighting:FindFirstChild("ChaosAftermathBlur")
if blur and not blur:IsA("BlurEffect") then
    blur:Destroy()
    blur = nil
end
if not blur then
    blur = Instance.new("BlurEffect")
end
blur.Name = "ChaosAftermathBlur"
blur.Enabled = true
blur.Size = 0
blur.Parent = Lighting

local lastPhase = "waiting"
local lastDisasters = {}
local token = 0
local tintTween = nil
local blurTween = nil

local PROFILES = {
    RisingLava = {
        Tint = Color3.fromRGB(255, 205, 170),
        Saturation = -0.04,
        Contrast = 0.035,
        Blur = 0,
    },
    Meteors = {
        Tint = Color3.fromRGB(255, 220, 190),
        Saturation = -0.07,
        Contrast = 0.045,
        Blur = 0.7,
    },
    LowGravity = {
        Tint = Color3.fromRGB(210, 220, 255),
        Saturation = -0.04,
        Contrast = 0.018,
        Blur = 0.35,
    },
    DisappearingPlatforms = {
        Tint = Color3.fromRGB(255, 235, 185),
        Saturation = -0.03,
        Contrast = 0.028,
        Blur = 0.20,
    },
    SpeedSurge = {
        Tint = Color3.fromRGB(255, 205, 245),
        Saturation = -0.02,
        Contrast = 0.035,
        Blur = 0.45,
    },
    Tornado = {
        Tint = Color3.fromRGB(210, 225, 235),
        Saturation = -0.18,
        Contrast = 0.02,
        Blur = 1.2,
    },
    Freeze = {
        Tint = Color3.fromRGB(195, 225, 255),
        Saturation = -0.10,
        Contrast = 0.02,
        Blur = 0.8,
    },
    Bombs = {
        Tint = Color3.fromRGB(255, 215, 185),
        Saturation = -0.08,
        Contrast = 0.05,
        Blur = 0.9,
    },
    Darkness = {
        Tint = Color3.fromRGB(205, 195, 235),
        Saturation = -0.16,
        Contrast = 0.055,
        Blur = 0.5,
    },
    ShrinkingArena = {
        Tint = Color3.fromRGB(255, 210, 225),
        Saturation = -0.06,
        Contrast = 0.035,
        Blur = 0,
    },
    JumpShock = {
        Tint = Color3.fromRGB(220, 210, 255),
        Saturation = -0.03,
        Contrast = 0.025,
        Blur = 0.6,
    },
}

local function cancelTweens()
    if tintTween then
        tintTween:Cancel()
        tintTween = nil
    end
    if blurTween then
        blurTween:Cancel()
        blurTween = nil
    end
end

local function reset(duration)
    cancelTweens()

    tintTween = TweenService:Create(
        tint,
        TweenInfo.new(duration or 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Brightness = 0,
            Contrast = 0,
            Saturation = 0,
            TintColor = Color3.new(1, 1, 1),
        }
    )
    blurTween = TweenService:Create(
        blur,
        TweenInfo.new(duration or 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = 0}
    )
    tintTween:Play()
    blurTween:Play()
end

local function strongestProfile(ids)
    local selected = nil
    local weight = -math.huge

    for _, id in ipairs(ids or {}) do
        local profile = PROFILES[id]
        if profile then
            local candidateWeight =
                math.abs(profile.Saturation or 0)
                + math.abs(profile.Contrast or 0)
                + ((profile.Blur or 0) * 0.02)
            if candidateWeight > weight then
                selected = profile
                weight = candidateWeight
            end
        end
    end

    return selected
end

local function playAftermath(ids)
    local profile = strongestProfile(ids)
    if not profile then
        return
    end

    token += 1
    local current = token
    local quality = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local reducedMotion = player:GetAttribute("ReduceMotion") == true
    local scale = quality.Name == "Low" and 0.36 or (quality.Name == "Medium" and 0.68 or 1)
    if reducedMotion then
        scale *= 0.28
    end

    cancelTweens()
    tint.TintColor = Color3.new(1, 1, 1)
    tint.Saturation = 0
    tint.Contrast = 0
    blur.Size = 0

    tintTween = TweenService:Create(
        tint,
        TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            TintColor = Color3.new(1, 1, 1):Lerp(profile.Tint, 0.28 * scale),
            Saturation = (profile.Saturation or 0) * scale,
            Contrast = (profile.Contrast or 0) * scale,
        }
    )
    blurTween = TweenService:Create(
        blur,
        TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = reducedMotion and 0 or ((profile.Blur or 0) * scale)}
    )
    tintTween:Play()
    blurTween:Play()

    task.delay(quality.Name == "Low" and 0.45 or 0.85, function()
        if current == token then
            reset(quality.Name == "Low" and 0.45 or 0.9)
        end
    end)
end

stateEvent.OnClientEvent:Connect(function(state)
    local phase = tostring(state.phase or "waiting")

    if phase == "round" then
        lastDisasters = table.clone(state.disasterIds or {})
        token += 1
        reset(0.18)
    elseif lastPhase == "round" and phase == "result" then
        playAftermath(lastDisasters)
    elseif phase ~= "result" then
        token += 1
        reset(0.35)
    end

    lastPhase = phase
end)
