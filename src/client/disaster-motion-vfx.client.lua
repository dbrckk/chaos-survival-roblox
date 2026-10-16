local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local SceneRules = require(ReplicatedStorage.Shared.DisasterMotionSceneRules)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local worldEffects = Instance.new("Folder")
worldEffects.Name = "ChaosMotionDisasterVfxLocal"
worldEffects.Parent = workspace

local activeIds = {}
local characterEffects = {}
local shrinkParts = {}
local shrinkBase = nil
local shrinkPoseFrame = nil
local shrinkPoseSize = nil
local shrinkLastAlpha = nil
local blackoutParts = {}
local blackoutBase = nil
local blackoutPoseFrame = nil
local blackoutPoseSize = nil
local blackoutLastTier = nil
local blackoutLastReduced = nil
local clock = 0
local currentPhase = "waiting"
local activeSignature = ""
local loopStarted = false
local ensureRenderLoop

local function has(id)
    return activeIds[id] == true
end

local function clearCharacterEffects()
    for _, instance in ipairs(characterEffects) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
    table.clear(characterEffects)
end

local function clearShrink()
    shrinkBase = nil
    shrinkPoseFrame = nil
    shrinkPoseSize = nil
    shrinkLastAlpha = nil
    for _, instance in ipairs(shrinkParts) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
    table.clear(shrinkParts)
end

local function clearBlackout()
    blackoutBase = nil
    blackoutPoseFrame = nil
    blackoutPoseSize = nil
    blackoutLastTier = nil
    blackoutLastReduced = nil
    for _, instance in ipairs(blackoutParts) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
    table.clear(blackoutParts)
end

local function makeAttachment(parent, name, position)
    local attachment = Instance.new("Attachment")
    attachment.Name = name
    attachment.Position = position
    attachment.Parent = parent
    table.insert(characterEffects, attachment)
    return attachment
end

local function rebuildCharacterEffects()
    clearCharacterEffects()

    if currentPhase ~= "round"
        or player:GetAttribute("RoundParticipant") ~= true
        or player:GetAttribute("RoundEliminated") == true
    then
        return
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return
    end

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local reduced = player:GetAttribute("ReduceMotion") == true

    if has("LowGravity") and tier.Name ~= "Low" and not reduced then
        local top = makeAttachment(root, "MoonTrailTop", Vector3.new(0, 1.15, 0))
        local bottom = makeAttachment(root, "MoonTrailBottom", Vector3.new(0, -1.15, 0))

        local trail = Instance.new("Trail")
        trail.Name = "MoonGravityTrail"
        trail.Attachment0 = top
        trail.Attachment1 = bottom
        trail.Lifetime = 0.24 * tier.Scale
        trail.MinLength = 0.1
        trail.FaceCamera = true
        trail.LightEmission = 0.8
        trail.Color = ColorSequence.new(
            Color3.fromRGB(125, 155, 255),
            Color3.fromRGB(205, 220, 255)
        )
        trail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.42),
            NumberSequenceKeypoint.new(1, 1),
        })
        trail.WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.65),
            NumberSequenceKeypoint.new(1, 0),
        })
        trail.Parent = root
        table.insert(characterEffects, trail)

        if tier.Name == "High" then
            local motes = Instance.new("ParticleEmitter")
            motes.Name = "MoonMotes"
            motes.Rate = 5 * tier.ParticleScale
            motes.Lifetime = NumberRange.new(0.7, 1.2)
            motes.Speed = NumberRange.new(0.3, 1.1)
            motes.Acceleration = Vector3.new(0, 1.8, 0)
            motes.SpreadAngle = Vector2.new(180, 180)
            motes.LightEmission = 0.75
            motes.Color = ColorSequence.new(Color3.fromRGB(150, 180, 255), Color3.fromRGB(220, 230, 255))
            motes.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.16),
                NumberSequenceKeypoint.new(1, 0),
            })
            motes.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.25),
                NumberSequenceKeypoint.new(1, 1),
            })
            motes.Parent = top
        end
    end

end

local function arenaBase()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    return base and base:IsA("BasePart") and base or nil
end

local function ensureShrinkVisuals()
    if currentPhase ~= "round" or not has("ShrinkingArena") then
        if #shrinkParts > 0 then clearShrink() end
        return
    end
    local base = arenaBase()
    if not base then
        if #shrinkParts > 0 then clearShrink() end
        return
    end
    if not SceneRules.needsRebuild(shrinkBase, base, shrinkParts) then
        return
    end
    clearShrink()
    shrinkBase = base
    for i = 1, 4 do
        local p = Instance.new("Part")
        p.Name = "ShrinkPerimeterLocal" .. i
        p.Anchored = true
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.CastShadow = false
        p.Material = Enum.Material.Neon
        p.Color = i % 2 == 0 and Color3.fromRGB(220, 85, 255)
            or Color3.fromRGB(255, 110, 195)
        p.Transparency = 0.28
        p.Parent = worldEffects
        table.insert(shrinkParts, p)
    end
end

local function updateShrink()
    local base = shrinkBase
    if not base or not base.Parent or #shrinkParts ~= 4 then
        if #shrinkParts > 0 then clearShrink() end
        return
    end
    -- Size/CFrame are only written when the source deck actually changes.
    -- Ordinary frames touch transparency only, avoiding eight property
    -- writes and four geometry allocations per frame on Android.
    if SceneRules.geometryChanged(shrinkPoseFrame, shrinkPoseSize, base) then
        for i, part in ipairs(shrinkParts) do
            local frame, size = SceneRules.pose(base, "shrink", i)
            if frame then
                part.CFrame = frame
                part.Size = size
            end
        end
        shrinkPoseFrame, shrinkPoseSize = base.CFrame, base.Size
    end

    local reduced = player:GetAttribute("ReduceMotion") == true
    local pulse = reduced and 0.5 or ((math.sin(clock * 5.4) + 1) * 0.5)
    local alpha = 0.18 + pulse * 0.26
    if alpha ~= shrinkLastAlpha then
        for _, p in ipairs(shrinkParts) do
            p.Transparency = alpha
        end
        shrinkLastAlpha = alpha
    end
end

local function ensureBlackoutVisuals()
    if currentPhase ~= "round" or not has("Darkness") then
        if #blackoutParts > 0 then clearBlackout() end
        return
    end
    local base = arenaBase()
    if not base then
        if #blackoutParts > 0 then clearBlackout() end
        return
    end
    -- An old set of emergency beacons must never stay on a replaced map.
    if not SceneRules.needsRebuild(blackoutBase, base, blackoutParts) then
        return
    end
    clearBlackout()
    blackoutBase = base
    for i = 1, 4 do
        local beacon = Instance.new("Part")
        beacon.Name = "BlackoutEmergencyBeacon" .. i
        beacon.Anchored = true
        beacon.CanCollide = false
        beacon.CanTouch = false
        beacon.CanQuery = false
        beacon.CastShadow = false
        beacon.Material = Enum.Material.Neon
        beacon.Color = i % 2 == 0 and Color3.fromRGB(115, 90, 220)
            or Color3.fromRGB(75, 120, 220)
        beacon.Transparency = 0.38
        beacon.Parent = worldEffects
        table.insert(blackoutParts, beacon)
    end
end

local function updateBlackout(tier)
    local base = blackoutBase
    if not base or not base.Parent or #blackoutParts ~= 4 then
        if #blackoutParts > 0 then clearBlackout() end
        return
    end
    local geometryChanged = SceneRules.geometryChanged(
        blackoutPoseFrame, blackoutPoseSize, base)
    if geometryChanged then
        for i, part in ipairs(blackoutParts) do
            local frame, size = SceneRules.pose(base, "blackout", i)
            if frame then
                part.CFrame = frame
                part.Size = size
            end
        end
        blackoutPoseFrame, blackoutPoseSize = base.CFrame, base.Size
    end
    local reduced = player:GetAttribute("ReduceMotion") == true
    local still = tier.Name == "Low" or reduced
    local tierChanged = blackoutLastTier ~= tier.Name
        or blackoutLastReduced ~= reduced
    -- On Low/ReduceMotion, no cyclic property writes after the first pose.
    if still and not geometryChanged and not tierChanged then return end
    blackoutLastTier, blackoutLastReduced = tier.Name, reduced
    for i, beacon in ipairs(blackoutParts) do
        local pulse = SceneRules.beaconPulse(clock, i, tier.Name, reduced)
        beacon.Transparency = 0.34 + pulse * 0.30
        beacon.Color = i % 2 == 0
            and Color3.fromRGB(115, 90 + math.floor(pulse * 25), 220)
            or Color3.fromRGB(75, 115 + math.floor(pulse * 20), 220)
    end
end

local function applyState(state)
    local snapshot = type(state) == "table" and state or {}
    local nextPhase = tostring(snapshot.phase or "waiting")
    local nextIds = {}
    local ids = type(snapshot.disasterIds) == "table"
        and snapshot.disasterIds or {}
    for _, id in ipairs(ids) do
        table.insert(nextIds, tostring(id))
    end
    table.sort(nextIds)
    local nextSignature = nextPhase .. "|" .. table.concat(nextIds, ",")

    currentPhase = nextPhase
    table.clear(activeIds)
    for _, id in ipairs(nextIds) do
        activeIds[id] = true
    end

    if nextSignature ~= activeSignature then
        activeSignature = nextSignature
        rebuildCharacterEffects()
    end

    ensureShrinkVisuals()
    ensureBlackoutVisuals()

    if ensureRenderLoop then
        ensureRenderLoop()
    end
end

stateEvent.OnClientEvent:Connect(applyState)
player.CharacterAdded:Connect(function()
    task.wait(0.15)
    rebuildCharacterEffects()
end)
player:GetAttributeChangedSignal("RoundParticipant"):Connect(rebuildCharacterEffects)
player:GetAttributeChangedSignal("RoundEliminated"):Connect(rebuildCharacterEffects)
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(rebuildCharacterEffects)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(rebuildCharacterEffects)

ensureRenderLoop = function()
    if loopStarted then
        return
    end
    loopStarted = true

    task.spawn(function()
        while true do
            local shrinkActive = currentPhase == "round" and has("ShrinkingArena")
            local blackoutActive = currentPhase == "round" and has("Darkness")
            if not shrinkActive and not blackoutActive then
                -- No reason to poll the client every frame in the lobby.
                task.wait(0.16)
                continue
            end
            local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
            local dt = task.wait(VfxQuality.decorativeInterval(tier.Name,
                player:GetAttribute("ReduceMotion") == true))
            if currentPhase ~= "round" then continue end
            -- Events may arrive while waiting: use the current hazard set.
            shrinkActive = has("ShrinkingArena")
            blackoutActive = has("Darkness")
            clock += dt

    if shrinkActive then
        ensureShrinkVisuals()
        updateShrink()
    elseif #shrinkParts > 0 then
        clearShrink()
    end

    if blackoutActive then
        ensureBlackoutVisuals()
        updateBlackout(tier)
    elseif #blackoutParts > 0 then
        clearBlackout()
    end
        end
    end)
end

ensureRenderLoop()
