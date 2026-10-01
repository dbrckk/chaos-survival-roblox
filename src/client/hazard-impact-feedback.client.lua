local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local feedbackEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("HazardImpactFeedback")

local MAX_DISTANCE = 150

local function tier()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function renderBurst(payload)
    local position = payload.position
    local color = payload.color
    local radius = tonumber(payload.radius) or 8

    if typeof(position) ~= "Vector3" or typeof(color) ~= "Color3" then
        return
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and (root.Position - position).Magnitude > MAX_DISTANCE then
        return
    end

    local profile = tier()
    local burst = Instance.new("Part")
    burst.Name = "LocalHazardImpactBurst"
    burst.Shape = Enum.PartType.Ball
    burst.Size = Vector3.new(1, 1, 1)
    burst.Position = position
    burst.Anchored = true
    burst.CanCollide = false
    burst.CanTouch = false
    burst.CanQuery = false
    burst.CastShadow = false
    burst.Material = Enum.Material.Neon
    burst.Color = color
    burst.Transparency = 0.2
    burst.Parent = workspace

    local light
    if profile.Name ~= "Low" then
        light = Instance.new("PointLight")
        light.Color = color
        light.Brightness = 2.2 * profile.Scale
        light.Range = math.max(10, radius * (1.7 + 0.4 * profile.Scale))
        light.Shadows = false
        light.Parent = burst
    end

    local duration = profile.Name == "Low" and 0.18 or 0.24
    local targetDiameter = radius * 2 * (0.85 + (0.15 * profile.Scale))
    TweenService:Create(
        burst,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = Vector3.new(targetDiameter, targetDiameter, targetDiameter),
            Transparency = 1,
        }
    ):Play()

    if light then
        TweenService:Create(
            light,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Brightness = 0}
        ):Play()
    end

    if profile.Name == "High" then
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "ImpactSparks"
        emitter.Rate = 0
        emitter.Lifetime = NumberRange.new(0.16, 0.28)
        emitter.Speed = NumberRange.new(5, 11)
        emitter.SpreadAngle = Vector2.new(180, 180)
        emitter.LightEmission = 0.9
        emitter.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.24),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.08),
            NumberSequenceKeypoint.new(1, 1),
        })
        emitter.Parent = burst
        emitter:Emit(VfxQuality.particleCount("High", 18, 8))
    elseif profile.Name == "Medium" then
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "ImpactSparks"
        emitter.Rate = 0
        emitter.Lifetime = NumberRange.new(0.14, 0.22)
        emitter.Speed = NumberRange.new(4, 8)
        emitter.SpreadAngle = Vector2.new(180, 180)
        emitter.LightEmission = 0.8
        emitter.Color = ColorSequence.new(color)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.20),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Parent = burst
        emitter:Emit(VfxQuality.particleCount("Medium", 14, 6))
    end

    Debris:AddItem(burst, duration + 0.08)
end

feedbackEvent.OnClientEvent:Connect(renderBurst)
