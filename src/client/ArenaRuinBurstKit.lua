-- Cosmetic collapse response: original noncolliding debris at each
-- server-authorized structural failure, bounded by graphics tier.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Kit = {}
local BUDGET = {Low = 4, Medium = 8, High = 12}
function Kit.burst(parent, platform, tier, theme)
    if not parent or not parent.Parent or not platform
        or not platform:IsA("BasePart") or not platform.Parent then
        return 0
    end
    local count = BUDGET[tier] or 8
    local platformIndex = tonumber(platform.Name:match("%d+")) or 1
    local rng = Random.new(platformIndex * 173)
    local origin = platform.CFrame * CFrame.new(
        0, platform.Size.Y * 0.5 + 13, 0)
    for i = 1, count do
        local side = i % 2 == 0 and 1 or -1
        local shard = Instance.new(i % 2 == 0 and "WedgePart" or "Part")
        shard.Name = "FallingSteelFragment"
        shard.Anchored = true
        shard.CanCollide = false
        shard.CanTouch = false
        shard.CanQuery = false
        shard.CastShadow = false
        shard.Size = Vector3.new(rng:NextNumber(0.8, 2.6),
            rng:NextNumber(1.8, 4.2), rng:NextNumber(0.4, 1.4))
        shard.Material = Enum.Material.Metal
        shard.Color = i % 3 == 0 and theme.Secondary or theme.Structure
        shard.Transparency = 0.07
        shard.CFrame = origin * CFrame.new(
            side * rng:NextNumber(0.8, 8),
            rng:NextNumber(-2, 3), rng:NextNumber(-5, 5))
        shard.Parent = parent
        local target = shard.CFrame
            * CFrame.new(side * rng:NextNumber(7, 15),
                -rng:NextNumber(10, 20), rng:NextNumber(-8, 8))
            * CFrame.Angles(rng:NextNumber(-1.2, 1.2),
                rng:NextNumber(-1.2, 1.2), side * 1.3)
        TweenService:Create(shard,
            TweenInfo.new(1.1, Enum.EasingStyle.Quad,
                Enum.EasingDirection.In),
            {CFrame = target, Transparency = 1}):Play()
        Debris:AddItem(shard, 1.4)
    end

    -- One localized dust plume per genuine server-authored failure.
    -- All particles are brief, muted and emitted only once, never
    -- an opaque screen-filling cloud or an artificial hazard warning.
    local source = Instance.new("Part")
    source.Name = "GatewayDustSource"
    source.Size = Vector3.new(0.1, 0.1, 0.1)
    source.CFrame = origin
    source.Transparency = 1
    source.Anchored = true
    source.CanCollide = false
    source.CanTouch = false
    source.CanQuery = false
    source.CastShadow = false
    source.Parent = parent
    local dust = Instance.new("ParticleEmitter")
    dust.Name = "LocalStructuralDust"
    dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
    dust.Rate = 0
    dust.Speed = NumberRange.new(3, 10)
    dust.Lifetime = NumberRange.new(0.65, 1.35)
    dust.SpreadAngle = Vector2.new(105, 105)
    dust.Drag = 3
    dust.LightInfluence = 1
    dust.LightEmission = 0
    dust.Color = ColorSequence.new(
        theme.Structure:Lerp(Color3.fromRGB(140, 145, 147), 0.30),
        theme.Surface)
    dust.Size = NumberSequence.new(3.0, 7.0)
    dust.Transparency = NumberSequence.new(0.52, 1)
    dust.Parent = source
    dust:Emit(tier == "Low" and 5 or (tier == "Medium" and 12 or 21))
    Debris:AddItem(source, 2.0)

    if tier ~= "Low" then
        local ring = Instance.new("Part")
        ring.Name = "AirborneCollapsePressureRing"
        ring.Shape = Enum.PartType.Cylinder
        ring.Size = Vector3.new(0.15, 4, 4)
        ring.CFrame = origin * CFrame.Angles(0, 0, math.pi * 0.5)
        ring.Anchored = true
        ring.CanCollide = false
        ring.CanTouch = false
        ring.CanQuery = false
        ring.CastShadow = false
        ring.Material = Enum.Material.Glass
        ring.Color = theme.Detail
        ring.Transparency = 0.55
        ring.Parent = parent
        TweenService:Create(ring, TweenInfo.new(
            0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = Vector3.new(0.15, 23, 23), Transparency = 1}
        ):Play()
        Debris:AddItem(ring, 0.9)
    end
    return count
end
return Kit
