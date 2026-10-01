local HapticService = game:GetService("HapticService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local AudioConfig = require(ReplicatedStorage.Shared.AudioConfig)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local feedbackEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ArenaMechanicFeedback")

local soundGroup = game:GetService("SoundService"):FindFirstChild("ChaosSFX")
local sound = Instance.new("Sound")
sound.Name = "MobilityPadLocal"
sound.SoundId = AudioConfig.Sfx.MobilityPad.SoundId
sound.Volume = AudioConfig.Sfx.MobilityPad.Volume or 0.34
sound.PlaybackSpeed = AudioConfig.Sfx.MobilityPad.PlaybackSpeed or 1.25
sound.SoundGroup = soundGroup
sound.Parent = game:GetService("SoundService")

local gui = Instance.new("ScreenGui")
gui.Name = "ArenaMechanicFeedback"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 60
gui.Parent = player:WaitForChild("PlayerGui")

local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(110, 210, 255)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.ZIndex = 1
flash.Parent = gui

local ACCENTS = {
    Classic = Color3.fromRGB(90, 180, 255),
    Towers = Color3.fromRGB(65, 220, 255),
    Crossroads = Color3.fromRGB(235, 105, 220),
    Orbital = Color3.fromRGB(65, 255, 205),
}

local lastTrigger = 0

local function currentVfxTier()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function pulseHaptics()
    if not UserInputService.TouchEnabled then
        return
    end

    pcall(function()
        if HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1) then
            HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0.5)
            task.delay(0.08, function()
                pcall(function()
                    HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
                end)
            end)
        end
    end)
end

local function pulseCamera()
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    local base = camera.FieldOfView
    TweenService:Create(
        camera,
        TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {FieldOfView = math.min(86, base + 4)}
    ):Play()

    task.delay(0.09, function()
        camera = workspace.CurrentCamera
        if camera then
            TweenService:Create(
                camera,
                TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {FieldOfView = base}
            ):Play()
        end
    end)
end

local function pulseCharacter(accent)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "MobilityBurst"
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(0.18, 0.32)
    emitter.Speed = NumberRange.new(2, 5)
    emitter.SpreadAngle = Vector2.new(70, 70)
    emitter.LightEmission = 0.9
    emitter.Color = ColorSequence.new(accent, Color3.new(1, 1, 1))
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.26),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.08),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = root
    local tier = currentVfxTier()
    emitter:Emit(math.max(6, math.floor(18 * tier.ParticleScale + 0.5)))

    task.delay(0.45, function()
        if emitter.Parent then
            emitter:Destroy()
        end
    end)
end

feedbackEvent.OnClientEvent:Connect(function(payload)
    local now = os.clock()
    if now - lastTrigger < 0.18 then
        return
    end
    lastTrigger = now

    local accent = ACCENTS[payload.variantId] or Color3.fromRGB(110, 210, 255)
    local tier = currentVfxTier()
    flash.BackgroundColor3 = accent
    flash.BackgroundTransparency = 0.91 + ((1 - tier.Scale) * 0.04)
    TweenService:Create(flash, TweenInfo.new(0.22), {BackgroundTransparency = 1}):Play()

    sound.PlaybackSpeed = (AudioConfig.Sfx.MobilityPad.PlaybackSpeed or 1.25) + ((math.random() - 0.5) * 0.08)
    sound.TimePosition = 0
    sound:Play()

    if tier.Name ~= "Low" then
        pulseCamera()
    end
    pulseCharacter(accent)
    pulseHaptics()
end)
