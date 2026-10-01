local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local emitters = {}
local currentRate = 6 * VfxQuality.get(player:GetAttribute("VfxQualityTier")).ParticleScale

local function refreshRates()
    currentRate = 6 * VfxQuality.get(player:GetAttribute("VfxQualityTier")).ParticleScale
    for pad, emitter in pairs(emitters) do
        if not pad.Parent or not emitter.Parent then
            emitters[pad] = nil
        else
            emitter.Rate = currentRate
        end
    end
end

local function destroyEmitter(pad)
    local emitter = emitters[pad]
    if emitter then
        emitters[pad] = nil
        if emitter.Parent then
            emitter.Parent:Destroy()
        end
    end
end

local function attach(pad)
    if not pad:IsA("BasePart") or pad:GetAttribute("ArenaMobilityPad") ~= true or emitters[pad] then
        return
    end

    local attachment = Instance.new("Attachment")
    attachment.Name = "LocalMobilityVfx"
    attachment.Position = Vector3.new(0, 0.25, 0)
    attachment.Parent = pad

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "MobilityPulseLocal"
    emitter.Lifetime = NumberRange.new(0.25, 0.45)
    emitter.Speed = NumberRange.new(1.5, 3)
    emitter.SpreadAngle = Vector2.new(18, 18)
    emitter.LightEmission = 0.8
    emitter.Color = ColorSequence.new(pad.Color, Color3.new(1, 1, 1))
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.22),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Rate = currentRate
    emitter.Parent = attachment

    emitters[pad] = emitter
end

local function scan(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant:GetAttribute("ArenaMobilityPad") == true then
            attach(descendant)
        end
    end
end

workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("BasePart") and descendant:GetAttribute("ArenaMobilityPad") == true then
        attach(descendant)
    end
end)

workspace.DescendantRemoving:Connect(function(descendant)
    if emitters[descendant] then
        destroyEmitter(descendant)
    end
end)

scan(workspace)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(refreshRates)
