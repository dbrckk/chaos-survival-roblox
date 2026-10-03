local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local localFolder = Instance.new("Folder")
localFolder.Name = "ChaosPremiumDisasterVfxLocal"
localFolder.Parent = workspace

local lavaState = nil
local freezeStates = {}
local clock = 0
local updateClock = 0

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function localPart(name, size, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Size = size
    p.Color = color
    p.Material = material
    p.Parent = localFolder
    return p
end

local function clearLava()
    if not lavaState then
        return
    end
    for _, instance in ipairs(lavaState.instances) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
    lavaState = nil
end

local function bindLava(lava)
    clearLava()
    if not lava:IsA("BasePart") then
        return
    end

    local tier = quality()
    local instances = {}

    local surface = localPart(
        "LavaSurfaceLocal",
        Vector3.new(math.max(1, lava.Size.X - 1.2), 0.12, math.max(1, lava.Size.Z - 1.2)),
        Color3.fromRGB(255, 145, 35),
        Enum.Material.Neon
    )
    surface.Transparency = tier.Name == "Low" and 0.38 or 0.24
    table.insert(instances, surface)

    local attachment = Instance.new("Attachment")
    attachment.Name = "LavaHeatLocal"
    attachment.Parent = lava
    table.insert(instances, attachment)

    local embers = Instance.new("ParticleEmitter")
    embers.Name = "LavaEmbers"
    embers.Rate = 14 * tier.ParticleScale
    embers.Lifetime = NumberRange.new(0.7, 1.5)
    embers.Speed = NumberRange.new(2.5, 6.5)
    embers.Acceleration = Vector3.new(0, 4.5, 0)
    embers.SpreadAngle = Vector2.new(180, 180)
    embers.LightEmission = 1
    embers.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 225, 85)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 105, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(135, 25, 10)),
    })
    embers.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.22),
        NumberSequenceKeypoint.new(0.55, 0.12),
        NumberSequenceKeypoint.new(1, 0),
    })
    embers.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18),
        NumberSequenceKeypoint.new(1, 1),
    })
    embers.Parent = attachment

    local light = Instance.new("SurfaceLight")
    light.Name = "LavaGlowLocal"
    light.Face = Enum.NormalId.Top
    light.Color = Color3.fromRGB(255, 112, 38)
    light.Brightness = 1.25 * tier.Scale
    light.Range = 20 + 8 * tier.Scale
    light.Angle = 120
    light.Shadows = false
    light.Parent = lava
    table.insert(instances, light)

    lavaState = {
        lava = lava,
        surface = surface,
        embers = embers,
        light = light,
        instances = instances,
    }
end

local function clearFreeze(warning)
    local state = freezeStates[warning]
    if not state then
        return
    end
    freezeStates[warning] = nil
    for _, instance in ipairs(state.instances) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
end

local function bindFreeze(warning)
    if freezeStates[warning] or not warning:IsA("BasePart") then
        return
    end

    local tier = quality()
    local count = tier.Name == "Low" and 8 or (tier.Name == "Medium" and 12 or 16)
    local radius = math.max(warning.Size.Y, warning.Size.Z) * 0.5
    local instances = {}
    local segments = {}

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2
        local length = math.max(4.5, (2 * math.pi * radius / count) * 0.72)
        local segment = localPart(
            "FreezeRingSegment" .. i,
            Vector3.new(length, 0.18, 0.65),
            i % 2 == 0 and Color3.fromRGB(180, 245, 255) or Color3.fromRGB(90, 190, 255),
            Enum.Material.Neon
        )
        segment.Transparency = tier.Name == "Low" and 0.48 or 0.30
        segment:SetAttribute("FreezeAngle", angle)
        table.insert(instances, segment)
        table.insert(segments, segment)
    end

    local center = localPart(
        "FreezeCenterMist",
        Vector3.new(3.5, 0.12, 3.5),
        Color3.fromRGB(175, 235, 255),
        Enum.Material.Neon
    )
    center.Shape = Enum.PartType.Cylinder
    center.Transparency = 0.62
    table.insert(instances, center)

    local attachment = Instance.new("Attachment")
    attachment.Name = "FreezeMistLocal"
    attachment.Parent = warning
    table.insert(instances, attachment)

    local mist = Instance.new("ParticleEmitter")
    mist.Name = "FreezeMist"
    mist.Rate = 10 * tier.ParticleScale
    mist.Lifetime = NumberRange.new(0.45, 0.9)
    mist.Speed = NumberRange.new(0.8, 2)
    mist.SpreadAngle = Vector2.new(180, 180)
    mist.LightEmission = 0.75
    mist.Color = ColorSequence.new(Color3.fromRGB(185, 240, 255), Color3.fromRGB(85, 165, 255))
    mist.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.28),
        NumberSequenceKeypoint.new(1, 0),
    })
    mist.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.35),
        NumberSequenceKeypoint.new(1, 1),
    })
    mist.Parent = attachment

    freezeStates[warning] = {
        warning = warning,
        segments = segments,
        center = center,
        instances = instances,
        radius = radius,
        startedAt = workspace:GetServerTimeNow(),
        duration = math.max(0.1, tonumber(warning:GetAttribute("WarningDuration")) or 0.7),
        mist = mist,
    }
end

local function maybeBind(instance)
    if instance.Name == "RoundLava" and instance:IsA("BasePart") then
        bindLava(instance)
    elseif instance.Name == "FreezeWarning" and instance:IsA("BasePart") then
        task.defer(function()
            if instance.Parent then
                bindFreeze(instance)
            end
        end)
    end
end

for _, child in ipairs(workspace:GetChildren()) do
    maybeBind(child)
end

workspace.ChildAdded:Connect(maybeBind)
workspace.ChildRemoved:Connect(function(child)
    if lavaState and child == lavaState.lava then
        clearLava()
    end
    clearFreeze(child)
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    if lavaState and lavaState.lava and lavaState.lava.Parent then
        bindLava(lavaState.lava)
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not lavaState and next(freezeStates) == nil then
        return
    end

    clock += dt
    updateClock += dt

    local tier = quality()
    local reduceMotion = player:GetAttribute("ReduceMotion") == true
    local motionScale = reduceMotion and 0.18 or 1
    if updateClock < math.max(1 / 30, tier.UpdateInterval) then
        return
    end
    updateClock = 0

    if lavaState and lavaState.lava and lavaState.lava.Parent then
        local lava = lavaState.lava
        local surface = lavaState.surface
        if surface and surface.Parent then
            local pulse = (math.sin(clock * (reduceMotion and 0.9 or 2.8)) + 1) * 0.5
            surface.Size = Vector3.new(
                math.max(1, lava.Size.X - 1.2),
                0.12,
                math.max(1, lava.Size.Z - 1.2)
            )
            surface.CFrame = lava.CFrame + Vector3.new(0, (lava.Size.Y * 0.5) + 0.08, 0)
            surface.Color = Color3.fromRGB(
                255,
                128 + math.floor(pulse * (reduceMotion and 12 or 40)),
                25
            )
            surface.Transparency = 0.22 + pulse * (reduceMotion and 0.05 or 0.16)
        end
        if lavaState.embers and lavaState.embers.Parent then
            lavaState.embers.Rate = 14 * tier.ParticleScale * (reduceMotion and 0.35 or 1)
        end
        if lavaState.light and lavaState.light.Parent then
            lavaState.light.Brightness = (
                1.0 + math.sin(clock * (reduceMotion and 0.8 or 3.1))
                    * 0.22
                    * motionScale
            ) * tier.Scale
        end
    end

    for warning, state in pairs(freezeStates) do
        if not warning.Parent then
            clearFreeze(warning)
            continue
        end

        local elapsed = workspace:GetServerTimeNow() - state.startedAt
        local alpha = math.clamp(elapsed / state.duration, 0, 1)
        local expansion = 0.92 + alpha * 0.08
        local y = warning.Position.Y + 0.18

        for i, segment in ipairs(state.segments) do
            if segment.Parent then
                local angle = segment:GetAttribute("FreezeAngle") or 0
                local radius = state.radius * expansion
                local position = Vector3.new(
                    warning.Position.X + math.cos(angle) * radius,
                    y + math.sin(clock * (reduceMotion and 1.1 or 5) + i) * 0.07 * motionScale,
                    warning.Position.Z + math.sin(angle) * radius
                )
                segment.CFrame = CFrame.new(position) * CFrame.Angles(0, -angle, 0)
                segment.Transparency = 0.26 + alpha * 0.34
            end
        end

        if state.mist and state.mist.Parent then
            state.mist.Rate = 10 * tier.ParticleScale * (reduceMotion and 0.35 or 1)
        end

        if state.center and state.center.Parent then
            state.center.CFrame = CFrame.new(warning.Position + Vector3.new(0, 0.18, 0))
                * CFrame.Angles(0, 0, math.rad(90))
            state.center.Transparency = 0.58 + alpha * 0.30
        end
    end
end)
