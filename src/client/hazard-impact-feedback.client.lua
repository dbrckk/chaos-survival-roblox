local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local ImpactSetpiece = require(script.Parent.ImpactSetpiece)

local player = Players.LocalPlayer
local feedbackEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("HazardImpactFeedback")

local MAX_DISTANCE = 150
local activeBursts = 0

local function maxConcurrentBursts(profile, reduced)
    if reduced then
        return profile.Name == "Low" and 3 or 4
    elseif profile.Name == "Low" then
        return 6
    elseif profile.Name == "Medium" then
        return 10
    end
    return 14
end

local function tier()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function makeAftermath(position, color, radius, kind, profile, reduced)
    -- Persistent ground traces are owned by disaster-residue.client.lua.
    -- This layer only keeps short-lived airborne debris tied to the impact burst.
    if profile.Name == "Low" or reduced then
        return
    end

    local debrisCount = profile.Name == "High" and 6 or 3
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
        shard.Color = kind == "Meteor"
            and color:Lerp(Color3.fromRGB(42, 34, 28), 0.70)
            or color:Lerp(Color3.fromRGB(35, 38, 48), 0.72)
        shard.Transparency = 0.12
        shard.Parent = workspace

        TweenService:Create(
            shard,
            TweenInfo.new(0.66 + math.random() * 0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Position = shard.Position + Vector3.new(
                    math.cos(angle) * (1.5 + math.random() * 2.2),
                    0.15 + math.random() * 0.45,
                    math.sin(angle) * (1.5 + math.random() * 2.2)
                ),
                Transparency = 1,
            }
        ):Play()
        Debris:AddItem(shard, 1.0)
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
    local reduced = player:GetAttribute("ReduceMotion") == true
    local concurrentLimit = maxConcurrentBursts(profile, reduced)
    if activeBursts >= concurrentLimit then
        return
    end
    activeBursts += 1

    -- Layer one brief, profile-bounded signature over the existing impact
    -- ring/plume. This never alters damage, hit detection or scorch ownership.
    ImpactSetpiece.spawn(workspace, {
        position = position,
        color = color,
        radius = radius,
        kind = kind,
    }, profile.Name, reduced)

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

    local secondaryRing = nil
    local plumeAnchor = nil
    if profile.Name ~= "Low" and not reduced then
        secondaryRing = Instance.new("Part")
        secondaryRing.Name = "LocalHazardSecondaryShockRing"
        secondaryRing.Shape = Enum.PartType.Cylinder
        secondaryRing.Size = Vector3.new(0.08, 1, 1)
        secondaryRing.CFrame = CFrame.new(position + Vector3.new(0, 0.22, 0))
            * CFrame.Angles(0, 0, math.rad(90))
        secondaryRing.Anchored = true
        secondaryRing.CanCollide = false
        secondaryRing.CanTouch = false
        secondaryRing.CanQuery = false
        secondaryRing.CastShadow = false
        secondaryRing.Material = Enum.Material.Neon
        secondaryRing.Color = kind == "Meteor"
            and Color3.fromRGB(255, 205, 95)
            or color:Lerp(Color3.new(1, 1, 1), 0.22)
        secondaryRing.Transparency = 0.34
        secondaryRing.Parent = workspace

        plumeAnchor = Instance.new("Part")
        plumeAnchor.Name = "LocalHazardImpactPlumeAnchor"
        plumeAnchor.Size = Vector3.new(0.2, 0.2, 0.2)
        plumeAnchor.Position = position + Vector3.new(0, 0.22, 0)
        plumeAnchor.Anchored = true
        plumeAnchor.CanCollide = false
        plumeAnchor.CanTouch = false
        plumeAnchor.CanQuery = false
        plumeAnchor.CastShadow = false
        plumeAnchor.Transparency = 1
        plumeAnchor.Parent = workspace

        local attachment = Instance.new("Attachment")
        attachment.Name = "ImpactPlumeAttachment"
        attachment.Parent = plumeAnchor

        local plumeEmitter = Instance.new("ParticleEmitter")
        plumeEmitter.Name = kind == "Meteor"
            and "MeteorImpactColumn"
            or "BombBlastCloud"
        plumeEmitter.Rate = 0
        plumeEmitter.LightEmission = kind == "Meteor" and 0.78 or 0.38
        plumeEmitter.LightInfluence = kind == "Meteor" and 0.08 or 0.42
        plumeEmitter.Color = kind == "Meteor"
            and ColorSequence.new(
                Color3.fromRGB(255, 220, 120),
                Color3.fromRGB(255, 110, 48)
            )
            or ColorSequence.new(
                color:Lerp(Color3.fromRGB(165, 120, 105), 0.50),
                Color3.fromRGB(58, 54, 60)
            )
        plumeEmitter.Lifetime = kind == "Meteor"
            and NumberRange.new(0.30, 0.56)
            or NumberRange.new(0.36, 0.68)
        plumeEmitter.Speed = kind == "Meteor"
            and NumberRange.new(math.max(6, radius * 0.65), math.max(10, radius * 1.05))
            or NumberRange.new(math.max(3, radius * 0.36), math.max(6, radius * 0.72))
        plumeEmitter.Acceleration = kind == "Meteor"
            and Vector3.new(0, 7.5, 0)
            or Vector3.new(0, 2.0, 0)
        plumeEmitter.SpreadAngle = kind == "Meteor"
            and Vector2.new(26, 26)
            or Vector2.new(170, 170)
        plumeEmitter.Size = kind == "Meteor"
            and NumberSequence.new({
                NumberSequenceKeypoint.new(0, math.max(0.34, radius * 0.055)),
                NumberSequenceKeypoint.new(0.45, math.max(0.70, radius * 0.11)),
                NumberSequenceKeypoint.new(1, 0),
            })
            or NumberSequence.new({
                NumberSequenceKeypoint.new(0, math.max(0.42, radius * 0.07)),
                NumberSequenceKeypoint.new(0.50, math.max(0.90, radius * 0.15)),
                NumberSequenceKeypoint.new(1, 0),
            })
        plumeEmitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, kind == "Meteor" and 0.18 or 0.36),
            NumberSequenceKeypoint.new(0.72, 0.58),
            NumberSequenceKeypoint.new(1, 1),
        })
        plumeEmitter.Parent = attachment
        plumeEmitter:Emit(
            VfxQuality.particleCount(
                profile.Name,
                kind == "Meteor" and 18 or 22,
                kind == "Meteor" and 8 or 10
            )
        )
    end

    local core = nil
    if profile.Name ~= "Low" and not reduced then
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
    if profile.Name ~= "Low" and not reduced then
        light = Instance.new("PointLight")
        light.Color = color
        light.Brightness = 2.2 * profile.Scale
        light.Range = math.max(10, radius * (1.7 + 0.4 * profile.Scale))
        light.Shadows = false
        light.Parent = burst
    end

    local duration = reduced and 0.12 or (profile.Name == "Low" and 0.18 or 0.24)
    local targetDiameter = radius * 2
        * (reduced and 0.72 or (0.85 + (0.15 * profile.Scale)))
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

    if secondaryRing then
        TweenService:Create(
            secondaryRing,
            TweenInfo.new(duration * 1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = Vector3.new(
                    0.08,
                    targetDiameter * 1.52,
                    targetDiameter * 1.52
                ),
                Transparency = 1,
            }
        ):Play()
    end

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

    if profile.Name == "High" and not reduced then
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

        local dust = Instance.new("ParticleEmitter")
        dust.Name = "ImpactDust"
        dust.Rate = 0
        dust.Lifetime = NumberRange.new(0.28, 0.55)
        dust.Speed = NumberRange.new(math.max(2, radius * 0.45), math.max(4, radius * 0.85))
        dust.Acceleration = Vector3.new(0, 1.5, 0)
        dust.SpreadAngle = Vector2.new(180, 180)
        dust.LightEmission = 0.28
        dust.LightInfluence = 0.45
        dust.Color = ColorSequence.new(
            color:Lerp(Color3.fromRGB(88, 82, 78), 0.65),
            Color3.fromRGB(48, 45, 46)
        )
        dust.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, math.max(0.35, radius * 0.05)),
            NumberSequenceKeypoint.new(0.45, math.max(0.65, radius * 0.09)),
            NumberSequenceKeypoint.new(1, 0),
        })
        dust.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.42),
            NumberSequenceKeypoint.new(1, 1),
        })
        dust.Parent = burst
        dust:Emit(VfxQuality.particleCount("High", 14, 6))
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

    makeAftermath(position, color, radius, kind, profile, reduced)

    local lifetime = duration * 1.35 + 0.08
    Debris:AddItem(burst, lifetime)
    Debris:AddItem(ring, lifetime)
    if secondaryRing then
        Debris:AddItem(secondaryRing, lifetime * 1.4)
    end
    if plumeAnchor then
        Debris:AddItem(plumeAnchor, math.max(0.85, lifetime * 2.2))
    end
    if core then
        Debris:AddItem(core, lifetime)
    end
    task.delay(lifetime, function()
        activeBursts = math.max(0, activeBursts - 1)
    end)
end

feedbackEvent.OnClientEvent:Connect(renderBurst)
