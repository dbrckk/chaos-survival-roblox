local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local feedbackEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("HazardImpactFeedback")

local MAX_DISTANCE = 150
local activeBursts = 0

local function maxConcurrentBursts(profile)
    if profile.Name == "Low" then
        return 6
    elseif profile.Name == "Medium" then
        return 10
    end
    return 14
end

local function tier()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function makeAftermath(position, color, radius, kind, profile)
    local afterglow = Instance.new("Part")
    afterglow.Name = "LocalHazardAfterglow"
    afterglow.Shape = Enum.PartType.Cylinder
    afterglow.Size = Vector3.new(0.06, math.max(2.4, radius * 1.25), math.max(2.4, radius * 1.25))
    afterglow.CFrame = CFrame.new(position + Vector3.new(0, 0.08, 0))
        * CFrame.Angles(0, 0, math.rad(90))
    afterglow.Anchored = true
    afterglow.CanCollide = false
    afterglow.CanTouch = false
    afterglow.CanQuery = false
    afterglow.CastShadow = false
    afterglow.Material = Enum.Material.Neon
    afterglow.Color = kind == "Meteor"
        and Color3.fromRGB(255, 145, 70)
        or color:Lerp(Color3.fromRGB(95, 80, 105), 0.42)
    afterglow.Transparency = profile.Name == "Low" and 0.82 or 0.72
    afterglow.Parent = workspace

    TweenService:Create(
        afterglow,
        TweenInfo.new(profile.Name == "Low" and 0.7 or 1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = Vector3.new(0.06, radius * 1.8, radius * 1.8),
            Transparency = 1,
        }
    ):Play()
    Debris:AddItem(afterglow, 1.25)

    if profile.Name == "Low" then
        return
    end

    local debrisCount = profile.Name == "High" and 7 or 4
    for i = 1, debrisCount do
        local angle = ((i - 1) / debrisCount) * math.pi * 2 + math.random() * 0.45
        local distance = radius * (0.28 + math.random() * 0.40)
        local shard = Instance.new("Part")
        shard.Name = "LocalImpactDebris"
        shard.Size = Vector3.new(
            0.18 + math.random() * 0.28,
            0.08 + math.random() * 0.12,
            0.30 + math.random() * 0.42
        )
        shard.CFrame = CFrame.new(
            position
                + Vector3.new(math.cos(angle) * distance, 0.13, math.sin(angle) * distance)
        ) * CFrame.Angles(
            math.random() * 1.4,
            math.random() * math.pi,
            math.random() * 1.4
        )
        shard.Anchored = true
        shard.CanCollide = false
        shard.CanTouch = false
        shard.CanQuery = false
        shard.CastShadow = false
        shard.Material = Enum.Material.Metal
        shard.Color = color:Lerp(Color3.fromRGB(35, 38, 48), 0.72)
        shard.Transparency = 0.12
        shard.Parent = workspace

        TweenService:Create(
            shard,
            TweenInfo.new(0.72 + math.random() * 0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Position = shard.Position + Vector3.new(
                    math.cos(angle) * (1.5 + math.random() * 2.2),
                    0.15 + math.random() * 0.45,
                    math.sin(angle) * (1.5 + math.random() * 2.2)
                ),
                Transparency = 1,
            }
        ):Play()
        Debris:AddItem(shard, 1.1)
    end
end

local function renderBurst(payload)
    local position = payload.position
    local color = payload.color
    local radius = math.clamp(tonumber(payload.radius) or 8, 1, 40)
    local kind = tostring(payload.kind or "")

    if typeof(position) ~= "Vector3" or typeof(color) ~= "Color3" then
        return
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and (root.Position - position).Magnitude > MAX_DISTANCE then
        return
    end

    local profile = tier()
    if activeBursts >= maxConcurrentBursts(profile) then
        return
    end
    activeBursts += 1

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

    local ring = Instance.new("Part")
    ring.Name = "LocalHazardShockRing"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.12, 1, 1)
    ring.CFrame = CFrame.new(position + Vector3.new(0, 0.16, 0))
        * CFrame.Angles(0, 0, math.rad(90))
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.CastShadow = false
    ring.Material = Enum.Material.Neon
    ring.Color = color
    ring.Transparency = 0.18
    ring.Parent = workspace

    local core = nil
    if profile.Name ~= "Low" then
        core = Instance.new("Part")
        core.Name = "LocalHazardImpactCore"
        core.Shape = Enum.PartType.Ball
        core.Size = Vector3.new(1.2, 1.2, 1.2)
        core.Position = position
        core.Anchored = true
        core.CanCollide = false
        core.CanTouch = false
        core.CanQuery = false
        core.CastShadow = false
        core.Material = Enum.Material.Neon
        core.Color = kind == "Meteor"
            and Color3.fromRGB(255, 218, 115)
            or color:Lerp(Color3.new(1, 1, 1), 0.18)
        core.Transparency = 0.05
        core.Parent = workspace
    end

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

    TweenService:Create(
        ring,
        TweenInfo.new(duration * 1.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = Vector3.new(0.12, targetDiameter * 1.18, targetDiameter * 1.18),
            Transparency = 1,
        }
    ):Play()

    if core then
        TweenService:Create(
            core,
            TweenInfo.new(duration * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = Vector3.new(targetDiameter * 0.42, targetDiameter * 0.42, targetDiameter * 0.42),
                Transparency = 1,
            }
        ):Play()
    end

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

    makeAftermath(position, color, radius, kind, profile)

    local lifetime = duration * 1.35 + 0.08
    Debris:AddItem(burst, lifetime)
    Debris:AddItem(ring, lifetime)
    if core then
        Debris:AddItem(core, lifetime)
    end
    task.delay(lifetime, function()
        activeBursts = math.max(0, activeBursts - 1)
    end)
end

feedbackEvent.OnClientEvent:Connect(renderBurst)
