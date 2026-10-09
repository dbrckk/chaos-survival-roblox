local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local ImpactSetpiece = require(script.Parent.ImpactSetpiece)
local CinematicPulseRingKit = require(script.Parent.CinematicPulseRingKit)
local ImpactPulseRules = require(ReplicatedStorage.Shared.ImpactPulseRules)
local ImpactMaterialRules = require(ReplicatedStorage.Shared.ImpactMaterialRules)

local player = Players.LocalPlayer
local feedbackEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("HazardImpactFeedback")

local MAX_DISTANCE = 150
local activeBursts = 0

-- Single telemetry-visible folder for every temporary impact setpiece.
-- This is registered in VisualBudgetRules so live Studio audits count it.
local setpieceFolder = Instance.new("Folder")
setpieceFolder.Name = "ImpactSetpieceLocal"
setpieceFolder.Parent = workspace

local function maxConcurrentBursts(profile, reduced)
    if reduced then
        return profile.Name == "Low" and 3 or 4
    elseif profile.Name == "Low" then
        return 6
    elseif profile.Name == "Medium" then
        return 8
    end
    return 10
end

local function tier()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

-- One raycast per eligible impact, restricted to the generated arena.
-- A missing/streamed-out deck resolves to neutral stone, never another player.
local function sampleGround(position, color, kind, profile, reduced)
    local generated = workspace:FindFirstChild("GeneratedMap")
    local hit = nil
    if generated then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances = {generated}
        params.IgnoreWater = true
        hit = workspace:Raycast(
            position + Vector3.new(0, 14, 0),
            Vector3.new(0, -58, 0),
            params
        )
    end
    local surfaceColor = hit and hit.Instance:IsA("BasePart")
        and hit.Instance.Color or Color3.fromRGB(112, 105, 99)
    local style = ImpactMaterialRules.palette(
        hit and hit.Material or Enum.Material.Slate,
        surfaceColor, color, kind, profile.Name, reduced
    )
    local frame = ImpactMaterialRules.surfaceFrame(
        hit and (hit.Position + hit.Normal * 0.04) or position,
        hit and hit.Normal or Vector3.yAxis
    )
    return style, frame
end

local function makeAftermath(kind, profile, style, frame, radius)
    -- The persistent crater/scorch is owned by disaster-residue.client.lua.
    -- This uses the *existing* six/three temporary airborne pieces only,
    -- now shaded/oriented by the raycast material and surface normal.
    if not style or style.Count == 0 or not frame then return end
    for i = 1, style.Count do
        local fragment = ImpactMaterialRules.fragment(
            frame, i, style.Count, radius, style.Motion
        )
        if fragment then
            local meteor = kind == "Meteor"
            local shard = meteor and Instance.new("WedgePart") or Instance.new("Part")
            shard.Name = meteor and "LocalMeteorSurfaceFragment" or "LocalBombSurfaceFragment"
            shard.Size = fragment.Size
            shard.CFrame = fragment.Start
            shard.Anchored = true
            shard.CanCollide = false
            shard.CanTouch = false
            shard.CanQuery = false
            shard.CastShadow = false
            shard.Material = style.Material
            shard.Color = style.Color
            shard.Transparency = 0.16
            shard:SetAttribute("ImpactSurfaceFamily", style.Family)
            shard.Parent = setpieceFolder
            local duration = 0.62 + (((i * 37) % 11) / 10) * 0.25
            TweenService:Create(
                shard,
                TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = shard.Position + fragment.Travel, Transparency = 1}
            ):Play()
            Debris:AddItem(shard, duration + 0.14)
        end
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

    local spectating = player:GetAttribute("RoundEliminated") == true
        or player:GetAttribute("RoundParticipant") ~= true
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera
    local observer = spectating and camera and camera.CFrame.Position
        or (root and root.Position)
    if not observer or (observer - position).Magnitude > MAX_DISTANCE then
        return
    end
    local viewerDistance = (observer - position).Magnitude

    local profile = tier()
    local reduced = player:GetAttribute("ReduceMotion") == true
    local concurrentLimit = maxConcurrentBursts(profile, reduced)
    if activeBursts >= concurrentLimit then
        return
    end
    activeBursts += 1
    local materialStyle, groundFrame = sampleGround(
        position, color, kind, profile, reduced
    )
    materialStyle.Count = ImpactMaterialRules.chipCount(
        profile.Name, reduced, viewerDistance, activeBursts
    )
    local duration = reduced and 0.12 or (profile.Name == "Low" and 0.18 or 0.24)
    local targetDiameter = radius * 2
        * (reduced and 0.72 or (0.85 + (0.15 * profile.Scale)))
    local pulseRecipe = ImpactPulseRules.pulse(
        profile.Name, reduced, viewerDistance, activeBursts, kind
    )
    if pulseRecipe then
        CinematicPulseRingKit.emit(
            setpieceFolder, pulseRecipe.Name,
            CFrame.new(position + Vector3.new(0, 0.16, 0)),
            color, math.max(1, targetDiameter * 0.15),
            targetDiameter * pulseRecipe.Scale,
            pulseRecipe.Duration, profile.Name, reduced, pulseRecipe.Alpha
        )
    end

    -- Layer one brief, profile-bounded signature over the existing impact
    -- ring/plume. This never alters damage, hit detection or scorch ownership.
    ImpactSetpiece.spawn(setpieceFolder, {
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
    burst.Parent = setpieceFolder

    -- Hollow arcs above replace screen-covering circular pressure discs.
    local plumeAnchor = nil
    if profile.Name ~= "Low" and not reduced then
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
        plumeAnchor.Parent = setpieceFolder

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
                materialStyle.DustColor:Lerp(color, 0.20),
                materialStyle.DustColor:Lerp(Color3.fromRGB(58, 54, 60), 0.55)
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
        core.Parent = setpieceFolder
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

    TweenService:Create(
        burst,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            -- Squashed kind-dependent volume reveals the playfield behind it
            -- instead of a huge generic glowing sphere.
            Size = kind == "Meteor"
                and Vector3.new(targetDiameter * 0.54,
                    targetDiameter * 0.68, targetDiameter * 0.54)
                or Vector3.new(targetDiameter * 0.82,
                    targetDiameter * 0.24, targetDiameter * 0.82),
            Transparency = 1,
        }
    ):Play()

    if core then
        TweenService:Create(
            core,
            TweenInfo.new(duration * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = kind == "Meteor"
                    and Vector3.new(targetDiameter * 0.25, targetDiameter * 0.36,
                        targetDiameter * 0.25)
                    or Vector3.new(targetDiameter * 0.38, targetDiameter * 0.15,
                        targetDiameter * 0.38),
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
            materialStyle.DustColor:Lerp(color, 0.18),
            materialStyle.DustColor:Lerp(Color3.fromRGB(48, 45, 46), 0.42)
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
    elseif profile.Name == "Medium" and not reduced then
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

    makeAftermath(kind, profile, materialStyle, groundFrame, radius)

    local lifetime = duration * 1.35 + 0.08
    Debris:AddItem(burst, lifetime)
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
