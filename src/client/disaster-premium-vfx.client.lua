local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local HazardWarningSignatureRules = require(ReplicatedStorage.Shared.HazardWarningSignatureRules)
local DisasterCosmeticRules = require(ReplicatedStorage.Shared.DisasterCosmeticRules)

local player = Players.LocalPlayer
local localFolder = Instance.new("Folder")
localFolder.Name = "ChaosPremiumDisasterVfxLocal"
localFolder.Parent = workspace

local lavaState = nil
local freezeStates = {}
-- A FreezeWarning can stream before the server's four timing/size attrs.
-- Only pending warnings own metadata listeners; remove them at bind/teardown.
local pendingFreezeMetadata = {}
local clock = 0
local loopStarted = false
local ensureRenderLoop

local function quality()
    return VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled)
end

-- CrackedLava is a native Roblox surface with actual fissure relief;
-- keep its color/transparency consistent through quality switches.
-- No custom texture, extra mesh, emitter, or additional render pass.
local function lavaSurfaceAlpha(tierName, reduced, pulse)
    local base = tierName == "Low" and 0.23 or 0.13
    return base + (reduced and 0 or math.clamp(pulse, 0, 1) * 0.08)
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
        if instance then instance:Destroy() end
    end
    lavaState = nil
end

local function bindLava(lava)
    if not lava:IsA("BasePart") then return end
    local tier = quality()
    local reduced = player:GetAttribute("ReduceMotion") == true
    if DisasterCosmeticRules.reusableLava(lavaState, lava) then
        -- Reconfigure existing GPU instances instead of recreating them
        -- when accessibility or tier changes during an active hazard.
        local rate = DisasterCosmeticRules.lavaEmberRate(tier.ParticleScale, reduced)
        if lavaState.embers.Rate ~= rate then lavaState.embers.Rate = rate end
        lavaState.light.Range = 20 + 8 * tier.Scale
        lavaState.light.Brightness = 1.25 * tier.Scale
        lavaState.surface.Transparency = lavaSurfaceAlpha(tier.Name, reduced, 0.5)
        return
    end

    clearLava()
    local instances = {}

    local surface = localPart(
        "LavaSurfaceLocal",
        Vector3.new(math.max(1, lava.Size.X - 1.2), 0.12, math.max(1, lava.Size.Z - 1.2)),
        Color3.fromRGB(235, 104, 40),
        Enum.Material.CrackedLava
    )
    -- Place the overlay immediately: the dormant renderer may be sleeping
    -- when a new lava part replicates, and must never show a piece at (0,0,0).
    surface.CFrame = lava.CFrame * CFrame.new(0, lava.Size.Y * 0.5 + 0.08, 0)
    surface.Transparency = lavaSurfaceAlpha(tier.Name, reduced, 0.5)
    table.insert(instances, surface)

    local attachment = Instance.new("Attachment")
    attachment.Name = "LavaHeatLocal"
    attachment.Parent = lava
    table.insert(instances, attachment)

    local embers = Instance.new("ParticleEmitter")
    embers.Name = "LavaEmbers"
    embers.Rate = DisasterCosmeticRules.lavaEmberRate(tier.ParticleScale, reduced)
    embers.Lifetime = NumberRange.new(0.7, 1.5)
    embers.Speed = NumberRange.new(2.5, 6.5)
    embers.Acceleration = Vector3.new(0, 4.5, 0)
    embers.SpreadAngle = Vector2.new(180, 180)
    -- Hot sparks cool into dark cinders; the separate surface light
    -- remains the only broad source of lava illumination.
    embers.LightEmission = 0.68
    embers.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 225, 85)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 105, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(79, 36, 28)),
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
        attachment = attachment,
        embers = embers,
        light = light,
        instances = instances,
    }

    if ensureRenderLoop then
        ensureRenderLoop()
    end
end

local function stopPendingFreeze(warning)
    local listeners = pendingFreezeMetadata[warning]
    if not listeners then return end
    pendingFreezeMetadata[warning] = nil
    for _, connection in ipairs(listeners) do
        connection:Disconnect()
    end
end

local function clearFreeze(warning)
    stopPendingFreeze(warning)
    local state = freezeStates[warning]
    if not state then
        return
    end
    freezeStates[warning] = nil
    for _, instance in ipairs(state.instances) do
        if instance then instance:Destroy() end
    end
end

local function bindFreeze(warning, snapshot)
    if not warning:IsA("BasePart") or not snapshot then return end
    local current = freezeStates[warning]
    if current and DisasterCosmeticRules.reusableFreeze(current, warning) then
        -- A delayed or re-replicated authoritative timeline must replace
        -- any old local schedule on quality/accessibility refresh.
        current.startedAt = snapshot.StartedAt
        current.duration = snapshot.Duration
        current.diameter = snapshot.EndSize
        -- Same-piece-count refreshes reuse the glass ring and mist emitter.
        local tier = quality()
        local reduced = player:GetAttribute("ReduceMotion") == true
        local count = HazardWarningSignatureRules.count("Freeze", tier.Name, reduced)
        if #current.segments == count then
            local frame = HazardWarningSignatureRules.frame(warning.Position, current.deck)
            local elapsed = workspace:GetServerTimeNow() - current.startedAt
            local alpha = math.clamp(elapsed / current.duration, 0, 1)
            for index, segment in ipairs(current.segments) do
                local style = HazardWarningSignatureRules.recipe(
                    "Freeze", index, count, current.diameter, reduced and 0 or alpha
                )
                segment.Size = style.Size
                segment.CFrame = frame * CFrame.new(style.Offset) * style.Rotation
                segment.Transparency = reduced and 0.66 or style.Transparency
            end
            local rate = DisasterCosmeticRules.freezeMistRate(tier.ParticleScale, reduced)
            local emittedBefore = current.mist.Rate > 0
            if current.mist.Rate ~= rate then current.mist.Rate = rate end
            if reduced and emittedBefore then
                -- Zero emission does not retire already alive mist particles.
                -- Clear on the real transition, not on repeated tier updates.
                current.mist:Clear()
            end
            current.staticPose = nil
            return
        end
    end
    if current then clearFreeze(warning) end

    local tier = quality()
    local reduced = player:GetAttribute("ReduceMotion") == true
    local diameter = snapshot.EndSize
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
    mist.Rate = DisasterCosmeticRules.freezeMistRate(tier.ParticleScale, reduced)
    -- One existing emitter now reads as a short cold condensation plume:
    -- small crystal seed -> wide translucent frost -> dissolved vapour.
    -- No extra Part, Light, ParticleEmitter or Texture asset is allocated.
    mist.Lifetime = NumberRange.new(0.48, 0.92)
    mist.Speed = NumberRange.new(0.75, 1.9)
    mist.Drag = 2.2
    mist.Acceleration = Vector3.new(0, 0.7, 0)
    mist.SpreadAngle = Vector2.new(145, 145)
    mist.Rotation = NumberRange.new(-22, 22)
    mist.RotSpeed = NumberRange.new(-18, 18)
    mist.LightEmission = 0.38
    mist.LightInfluence = 0.45
    mist.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 250, 255)),
        ColorSequenceKeypoint.new(0.38, Color3.fromRGB(162, 225, 248)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(88, 153, 205)),
    })
    mist.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18),
        NumberSequenceKeypoint.new(0.32, 0.55),
        NumberSequenceKeypoint.new(0.72, 0.48),
        NumberSequenceKeypoint.new(1, 0),
    })
    mist.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.78),
        NumberSequenceKeypoint.new(0.26, 0.46),
        NumberSequenceKeypoint.new(0.68, 0.77),
        NumberSequenceKeypoint.new(1, 1),
    })
    mist.Parent = attachment

    freezeStates[warning] = {
        warning = warning,
        attachment = attachment,
        segments = segments,
        instances = instances,
        diameter = diameter,
        deck = deck,
        startedAt = snapshot.StartedAt,
        duration = snapshot.Duration,
        mist = mist,
        staticPose = nil,
    }

    if ensureRenderLoop then
        ensureRenderLoop()
    end
end

-- Event-driven streaming tolerance: use the same complete timing
-- snapshot as the authoritative hazard-warning owner. An incomplete
-- warning is never animated using guessed durations or a guessed start.
local function tryBindFreeze(warning)
    if warning.Parent ~= workspace then
        stopPendingFreeze(warning)
        return
    end
    local snapshot = HazardWarningSignatureRules.snapshot(
        warning, workspace:GetServerTimeNow())
    if snapshot then
        stopPendingFreeze(warning)
        bindFreeze(warning, snapshot)
        return
    end
    if pendingFreezeMetadata[warning] then return end
    local listeners = {}
    pendingFreezeMetadata[warning] = listeners
    for _, name in ipairs({
        "WarningKind", "WarningStartedAt", "WarningDuration",
        "WarningStartSize", "WarningEndSize",
    }) do
        listeners[#listeners + 1] =
            warning:GetAttributeChangedSignal(name):Connect(function()
                tryBindFreeze(warning)
            end)
    end
    -- Catch a complete metadata set that arrived during subscriptions.
    local latest = HazardWarningSignatureRules.snapshot(
        warning, workspace:GetServerTimeNow())
    if latest then
        stopPendingFreeze(warning)
        bindFreeze(warning, latest)
    end
end

local function maybeBind(instance)
    if instance.Name == "RoundLava" and instance:IsA("BasePart") then
        bindLava(instance)
    elseif instance.Name == "FreezeWarning" and instance:IsA("BasePart") then
        task.defer(function()
            if instance.Parent == workspace then
                tryBindFreeze(instance)
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
        if warning.Parent then
            tryBindFreeze(warning)
        else
            clearFreeze(warning)
        end
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
            -- The warning/lava renderer should not wake at 30 Hz in the
            -- lobby or between hazards on Android devices.
            if not lavaState and next(freezeStates) == nil then
                task.wait(0.16)
                continue
            end
            local tier = quality()
            local dt = task.wait(VfxQuality.decorativeInterval(tier.Name,
                player:GetAttribute("ReduceMotion") == true))
            if not lavaState and next(freezeStates) == nil then
                continue
            end

            local reduceMotion = player:GetAttribute("ReduceMotion") == true
            if not reduceMotion then
                -- Pause decorative phase in accessibility mode and clamp
                -- backgrounded/mobile frame gaps, without altering lava
                -- collision, damage or the server's warning geometry.
                clock += math.clamp(tonumber(dt) or 0, 0, 0.22)
            end

    if lavaState and lavaState.lava and lavaState.lava.Parent then
        local lava = lavaState.lava
        local surface = lavaState.surface
        if surface and surface.Parent then
            local pulse = reduceMotion and 0.5
                or (math.sin(clock * 2.8) + 1) * 0.5
            local nextSize = Vector3.new(
                math.max(1, lava.Size.X - 1.2),
                0.12,
                math.max(1, lava.Size.Z - 1.2)
            )
            local nextFrame = lava.CFrame
                * CFrame.new(0, lava.Size.Y * 0.5 + 0.08, 0)
            -- The server can raise lava during ReduceMotion. Retain
            -- positional tracking but skip identical GPU property writes.
            if surface.Size ~= nextSize then surface.Size = nextSize end
            if surface.CFrame ~= nextFrame then surface.CFrame = nextFrame end
            local nextColor = Color3.fromRGB(
                235, 92 + math.floor(pulse * 32), 40
            )
            if surface.Color ~= nextColor then surface.Color = nextColor end
            local nextAlpha = lavaSurfaceAlpha(tier.Name, reduceMotion, pulse)
            if surface.Transparency ~= nextAlpha then
                surface.Transparency = nextAlpha
            end
        end
        if lavaState.embers and lavaState.embers.Parent then
            local rate = DisasterCosmeticRules.lavaEmberRate(tier.ParticleScale, reduceMotion)
            if lavaState.embers.Rate ~= rate then
                lavaState.embers.Rate = rate
            end
        end
        if lavaState.light and lavaState.light.Parent then
            local brightness = (
                1.0 + math.sin(clock * 3.1)
                    * (reduceMotion and 0 or 0.22)
            ) * tier.Scale
            if lavaState.light.Brightness ~= brightness then
                lavaState.light.Brightness = brightness
            end
        end
    end

    local serverNow = workspace:GetServerTimeNow()
    for warning, state in pairs(freezeStates) do
        if not warning.Parent then
            clearFreeze(warning)
            continue
        end

        -- Server warning timing owns the cosmetic deadline. After the
        -- actual impact, do not continue drawing static ice for a lingering
        -- replicated warning Part. Keep metadata listeners available if
        -- that same Part is ever re-armed by the server.
        if serverNow >= state.startedAt + state.duration then
            clearFreeze(warning)
            if warning.Parent == workspace then tryBindFreeze(warning) end
            continue
        end

        if not DisasterCosmeticRules.reusableFreeze(state, warning) then
            clearFreeze(warning)
            tryBindFreeze(warning)
            continue
        end
        local count = #state.segments
        local position = warning.Position
        local previous = state.staticPose
        -- Under ReduceMotion the final ice footprint is static. Only
        -- recompute it if the warning moved, its tier/size changed, or
        -- a fragment was lost (reusableFreeze validated the children).
        local reusePose = reduceMotion and previous
            and previous.position == position
            and previous.diameter == state.diameter
            and previous.tier == tier.Name
            and previous.count == count
        if not reusePose then
            local alpha = math.clamp(
                (serverNow - state.startedAt) / state.duration, 0, 1)
            local frame = HazardWarningSignatureRules.frame(position, state.deck)
            for i, segment in ipairs(state.segments) do
                if segment.Parent then
                    local design = HazardWarningSignatureRules.recipe(
                        "Freeze", i, count, state.diameter,
                        reduceMotion and 0 or alpha
                    )
                    local transform = frame * CFrame.new(design.Offset)
                        * design.Rotation
                    if segment.CFrame ~= transform then
                        segment.CFrame = transform
                    end
                    if segment.Size ~= design.Size then
                        segment.Size = design.Size
                    end
                    local transparency = reduceMotion and 0.66
                        or design.Transparency
                    if segment.Transparency ~= transparency then
                        segment.Transparency = transparency
                    end
                end
            end
            state.staticPose = reduceMotion and {
                position = position,
                diameter = state.diameter,
                tier = tier.Name,
                count = count,
            } or nil
        end

        if state.mist and state.mist.Parent then
            local rate = DisasterCosmeticRules.freezeMistRate(tier.ParticleScale, reduceMotion)
            if state.mist.Rate ~= rate then
                state.mist.Rate = rate
            end
        end
    end
        end
    end)
end

ensureRenderLoop()
