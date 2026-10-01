local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local currentState = nil
local attachment = nil
local emitter = nil

local function tier()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function destroyEmitter()
    if attachment and attachment.Parent then
        attachment:Destroy()
    end
    attachment = nil
    emitter = nil
end

local function ensureEmitter()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        destroyEmitter()
        return
    end

    if attachment and attachment.Parent == root and emitter then
        return
    end

    destroyEmitter()

    attachment = Instance.new("Attachment")
    attachment.Name = "ChaosAmbientMotesLocal"
    attachment.Position = Vector3.new(0, 2.5, 0)
    attachment.Parent = root

    emitter = Instance.new("ParticleEmitter")
    emitter.Name = "AmbientMotes"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(1.4, 2.4)
    emitter.Speed = NumberRange.new(0.4, 1.2)
    emitter.Acceleration = Vector3.new(0, 0.35, 0)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-40, 40)
    emitter.LightEmission = 0.72
    emitter.LightInfluence = 0
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.12),
        NumberSequenceKeypoint.new(0.55, 0.18),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.42),
        NumberSequenceKeypoint.new(0.65, 0.62),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment
end

local function refresh()
    ensureEmitter()
    if not emitter then
        return
    end

    local state = currentState
    local quality = tier()

    if not state or (state.phase ~= "round" and state.phase ~= "ready") then
        emitter.Rate = 0
        return
    end

    local ids = state.disasterIds or {}
    local profile = DisasterVisuals.combine(ids)
    local secondary = ids[2] and DisasterVisuals.get(ids[2]) or nil

    local primaryColor = profile and profile.Accent or Color3.fromRGB(95, 185, 255)
    local secondaryColor = secondary and secondary.Accent or Color3.fromRGB(175, 115, 255)

    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, primaryColor),
        ColorSequenceKeypoint.new(1, secondaryColor),
    })

    local baseRate = state.phase == "round" and 8 or 4
    emitter.Rate = math.max(0, baseRate * quality.ParticleScale)

    if quality.Name == "Low" then
        emitter.Rate = math.min(emitter.Rate, 1.5)
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    currentState = state
    refresh()
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(refresh)

player.CharacterAdded:Connect(function()
    task.wait(0.1)
    refresh()
end)

if player.Character then
    task.defer(refresh)
end
