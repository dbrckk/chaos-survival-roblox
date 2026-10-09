local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local HazardWarningSignatureRules = require(ReplicatedStorage.Shared.HazardWarningSignatureRules)

local player = Players.LocalPlayer
local localFolder = Instance.new("Folder")
localFolder.Name = "ChaosPremiumDisasterVfxLocal"
localFolder.Parent = workspace

local lavaState = nil
local freezeStates = {}
local clock = 0
local loopStarted = false
local ensureRenderLoop

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function localPart(name, size, color, material, className)
    local p = Instance.new(className or "Part")
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
    embers.Rate = 10 * tier.ParticleScale
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

    if ensureRenderLoop then
        ensureRenderLoop()
    end
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
    local reduced = player:GetAttribute("ReduceMotion") == true
    local diameter = math.max(warning.Size.Y, warning.Size.Z)
    local count = HazardWarningSignatureRules.count("Freeze", tier.Name, reduced)
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    local deck = base and base:IsA("BasePart") and base.CFrame or nil
    local frame = HazardWarningSignatureRules.frame(warning.Position, deck)
    local instances = {}
    local segments = {}

    -- Short crystalline needles replace the former full neon perimeter bars
    -- and central opaque cylinder. The authoritative freeze warning remains.
    for i = 1, count do
        local design = HazardWarningSignatureRules.recipe(
            "Freeze", i, count, diameter, 0
        )
        local segment = localPart(
            "FreezeFacetWarning" .. i,
            design.Size,
            design.Secondary and design.SecondaryColor or design.Color,
            design.Material,
            design.Wedge and "WedgePart" or "Part"
        )
        segment.CFrame = frame * CFrame.new(design.Offset) * design.Rotation
        segment.Transparency = reduced and 0.66 or design.Transparency
        table.insert(instances, segment)
        table.insert(segments, segment)
    end

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
        instances = instances,
        diameter = diameter,
        deck = deck,
        startedAt = tonumber(warning:GetAttribute("WarningStartedAt"))
            or workspace:GetServerTimeNow(),
        duration = math.max(0.1, tonumber(warning:GetAttribute("WarningDuration")) or 0.7),
        mist = mist,
    }

    if ensureRenderLoop then
        ensureRenderLoop()
    end
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

local function rebuildQuality()
    if lavaState and lavaState.lava and lavaState.lava.Parent then
        bindLava(lavaState.lava)
    end
    local warnings = {}
    for warning in pairs(freezeStates) do
        table.insert(warnings, warning)
    end
    for _, warning in ipairs(warnings) do
        clearFreeze(warning)
        if warning.Parent then bindFreeze(warning) end
    end
end

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(rebuildQuality)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(rebuildQuality)

ensureRenderLoop = function()
    if loopStarted then
        return
    end
    loopStarted = true

    task.spawn(function()
        while true do
            local tier = quality()
            local dt = task.wait(math.max(1 / 30, tier.UpdateInterval))

            if not lavaState and next(freezeStates) == nil then
                continue
            end

            clock += dt

            local reduceMotion = player:GetAttribute("ReduceMotion") == true
            local motionScale = reduceMotion and 0.18 or 1

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
            lavaState.embers.Rate = 10 * tier.ParticleScale * (reduceMotion and 0.35 or 1)
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
        local count = #state.segments
        local frame = HazardWarningSignatureRules.frame(warning.Position, state.deck)
        for i, segment in ipairs(state.segments) do
            if segment.Parent then
                local design = HazardWarningSignatureRules.recipe(
                    "Freeze", i, count, state.diameter,
                    reduceMotion and 0 or alpha
                )
                segment.CFrame = frame * CFrame.new(design.Offset)
                    * design.Rotation
                segment.Size = design.Size
                segment.Transparency = reduceMotion and 0.66
                    or design.Transparency
            end
        end

        if state.mist and state.mist.Parent then
            state.mist.Rate = reduceMotion and 0
                or (8 * tier.ParticleScale)
        end
    end
        end
    end)
end

ensureRenderLoop()
