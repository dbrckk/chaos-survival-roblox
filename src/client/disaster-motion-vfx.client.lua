local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local activeIds = {}
local characterEffects = {}
local shrinkParts = {}
local clock = 0
local currentPhase = "waiting"

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
    for _, instance in ipairs(shrinkParts) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
    table.clear(shrinkParts)
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

        for index, attachment in ipairs({left, right}) do
            local trail = Instance.new("Trail")
            trail.Name = "SpeedSurgeTrail" .. index
            trail.Attachment0 = attachment
            trail.Attachment1 = attachment
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

    if #shrinkParts == 4 then
        return
    end

    clearShrink()
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

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") then
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

local function applyState(state)
    currentPhase = tostring(state.phase or "waiting")
    table.clear(activeIds)
    for _, id in ipairs(state.disasterIds or {}) do
        activeIds[id] = true
    end

    rebuildCharacterEffects()
    ensureShrinkVisuals()
end

stateEvent.OnClientEvent:Connect(applyState)
player.CharacterAdded:Connect(function()
    task.wait(0.15)
    rebuildCharacterEffects()
end)
player:GetAttributeChangedSignal("RoundParticipant"):Connect(rebuildCharacterEffects)
player:GetAttributeChangedSignal("RoundEliminated"):Connect(rebuildCharacterEffects)
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(rebuildCharacterEffects)

RunService.RenderStepped:Connect(function(dt)
    clock += dt
    if currentPhase == "round" and has("ShrinkingArena") then
        ensureShrinkVisuals()
        updateShrink()
    elseif #shrinkParts > 0 then
        clearShrink()
    end
end)
