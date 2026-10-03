local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local activeIds = {}
local characterEffects = {}
local shrinkParts = {}
local shrinkBase = nil
local blackoutParts = {}
local clock = 0
local updateClock = 0
local currentPhase = "waiting"
local activeSignature = ""
local renderConnection = nil
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
    for _, instance in ipairs(shrinkParts) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
    table.clear(shrinkParts)
end

local function clearBlackout()
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

    if has("LowGravity") then
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

        if tier.Name ~= "Low" then
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

    if has("SpeedSurge") then
        local left = makeAttachment(root, "SpeedTrailLeft", Vector3.new(-0.85, -0.7, 0.5))
        local right = makeAttachment(root, "SpeedTrailRight", Vector3.new(0.85, -0.7, 0.5))

        local trail = Instance.new("Trail")
        trail.Name = "SpeedSurgeRibbon"
        trail.Attachment0 = left
        trail.Attachment1 = right
        trail.Lifetime = 0.22 * tier.Scale
        trail.MinLength = 0.05
        trail.FaceCamera = true
        trail.LightEmission = 1
        trail.Color = ColorSequence.new(
            Color3.fromRGB(255, 82, 205),
            Color3.fromRGB(110, 155, 255)
        )
        trail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(1, 1),
        })
        trail.WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.48),
            NumberSequenceKeypoint.new(1, 0),
        })
        trail.Parent = root
        table.insert(characterEffects, trail)
    end
end

local function ensureShrinkVisuals()
    if currentPhase ~= "round" or not has("ShrinkingArena") then
        clearShrink()
        return
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") then
        clearShrink()
        return
    end

    if #shrinkParts == 4 and shrinkBase == base then
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
        p.Color = i % 2 == 0 and Color3.fromRGB(220, 85, 255) or Color3.fromRGB(255, 110, 195)
        p.Transparency = 0.28
        p.Parent = workspace
        table.insert(shrinkParts, p)
    end
end

local function updateShrink()
    if #shrinkParts ~= 4 then
        return
    end

    local base = shrinkBase
    if not base or not base.Parent then
        clearShrink()
        return
    end

    local halfX = base.Size.X * 0.5
    local halfZ = base.Size.Z * 0.5
    local thickness = 0.24
    local y = base.Position.Y + (base.Size.Y * 0.5) + 0.18
    local pulse = (math.sin(clock * 5.4) + 1) * 0.5

    local defs = {
        {size = Vector3.new(base.Size.X, thickness, 0.5), pos = Vector3.new(0, y - base.Position.Y, -halfZ)},
        {size = Vector3.new(base.Size.X, thickness, 0.5), pos = Vector3.new(0, y - base.Position.Y, halfZ)},
        {size = Vector3.new(0.5, thickness, base.Size.Z), pos = Vector3.new(-halfX, y - base.Position.Y, 0)},
        {size = Vector3.new(0.5, thickness, base.Size.Z), pos = Vector3.new(halfX, y - base.Position.Y, 0)},
    }

    for i, def in ipairs(defs) do
        local p = shrinkParts[i]
        if p and p.Parent then
            p.Size = def.size
            p.CFrame = base.CFrame * CFrame.new(def.pos)
            p.Transparency = 0.18 + pulse * 0.26
        end
    end
end


local function ensureBlackoutVisuals()
    if currentPhase ~= "round" or not has("Darkness") then
        clearBlackout()
        return
    end

    if #blackoutParts > 0 then
        return
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") then
        return
    end

    local halfX = base.Size.X * 0.5
    local halfZ = base.Size.Z * 0.5
    local offsets = {
        Vector3.new(-halfX + 4, 2.2, -halfZ + 4),
        Vector3.new(halfX - 4, 2.2, -halfZ + 4),
        Vector3.new(-halfX + 4, 2.2, halfZ - 4),
        Vector3.new(halfX - 4, 2.2, halfZ - 4),
    }

    for i, offset in ipairs(offsets) do
        local beacon = Instance.new("Part")
        beacon.Name = "BlackoutEmergencyBeacon" .. i
        beacon.Anchored = true
        beacon.CanCollide = false
        beacon.CanTouch = false
        beacon.CanQuery = false
        beacon.CastShadow = false
        beacon.Material = Enum.Material.Neon
        beacon.Color = i % 2 == 0 and Color3.fromRGB(115, 90, 220) or Color3.fromRGB(75, 120, 220)
        beacon.Size = Vector3.new(0.55, 3.2, 0.55)
        beacon.CFrame = base.CFrame * CFrame.new(offset)
        beacon.Transparency = 0.38
        beacon.Parent = workspace
        table.insert(blackoutParts, beacon)
    end
end

local function applyState(state)
    local nextPhase = tostring(state.phase or "waiting")
    local nextIds = {}
    for _, id in ipairs(state.disasterIds or {}) do
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

ensureRenderLoop = function()
    local shrinkActive = currentPhase == "round" and has("ShrinkingArena")
    local blackoutActive = currentPhase == "round" and has("Darkness")
    if renderConnection or (not shrinkActive and not blackoutActive) then
        return
    end

    renderConnection = RunService.RenderStepped:Connect(function(dt)
        shrinkActive = currentPhase == "round" and has("ShrinkingArena")
        blackoutActive = currentPhase == "round" and has("Darkness")
        if not shrinkActive and not blackoutActive then
            renderConnection:Disconnect()
            renderConnection = nil
            return
        end

    clock += dt
    updateClock += dt

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    if updateClock < math.max(1 / 30, tier.UpdateInterval) then
        return
    end
    updateClock = 0

    if shrinkActive then
        ensureShrinkVisuals()
        updateShrink()
    elseif #shrinkParts > 0 then
        clearShrink()
    end

    if blackoutActive then
        ensureBlackoutVisuals()
        local pulse = (math.sin(clock * 2.6) + 1) * 0.5
        for i, beacon in ipairs(blackoutParts) do
            if beacon.Parent then
                beacon.Transparency = 0.34 + pulse * 0.30
                beacon.Color = i % 2 == 0
                    and Color3.fromRGB(115, 90 + math.floor(pulse * 25), 220)
                    or Color3.fromRGB(75, 115 + math.floor(pulse * 20), 220)
            end
        end
    elseif #blackoutParts > 0 then
        clearBlackout()
    end
    end)
end

ensureRenderLoop()
