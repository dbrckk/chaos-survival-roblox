local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local visuals = {}

local function profile()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local currentRate = 6 * profile().ParticleScale

local function refreshRates()
    local tier = profile()
    currentRate = 6 * tier.ParticleScale
    if tier.Name == "Low" then
        currentRate = math.min(currentRate, 1.8)
    end

    for pad, state in pairs(visuals) do
        if not pad.Parent or not state.attachment.Parent then
            visuals[pad] = nil
        else
            state.emitter.Rate = currentRate
            state.highlight.FillTransparency = tier.Name == "Low" and 1 or 0.86
            state.highlight.OutlineTransparency = tier.Name == "Low" and 0.36 or 0.16

            local light = pad:FindFirstChild("MobilityPadLight")
            if light and light:IsA("PointLight") then
                light.Enabled = tier.Name ~= "Low"
                light.Brightness = 0.55 + (0.20 * tier.Scale)
            end
        end
    end
end

local function destroyVisual(pad)
    local state = visuals[pad]
    if state then
        visuals[pad] = nil
        if state.attachment.Parent then
            state.attachment:Destroy()
        end
        if state.highlight.Parent then
            state.highlight:Destroy()
        end
    end
end

local function attach(pad)
    if not pad:IsA("BasePart") or pad:GetAttribute("ArenaMobilityPad") ~= true or visuals[pad] then
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

    local highlight = Instance.new("Highlight")
    highlight.Name = "MobilityPadHighlightLocal"
    highlight.Adornee = pad
    highlight.FillColor = pad.Color
    highlight.FillTransparency = profile().Name == "Low" and 1 or 0.86
    highlight.OutlineColor = pad.Color:Lerp(Color3.new(1, 1, 1), 0.42)
    highlight.OutlineTransparency = profile().Name == "Low" and 0.36 or 0.16
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = pad

    visuals[pad] = {
        attachment = attachment,
        emitter = emitter,
        highlight = highlight,
    }

    local light = pad:FindFirstChild("MobilityPadLight")
    if light and light:IsA("PointLight") then
        light.Enabled = profile().Name ~= "Low"
    end
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
    if visuals[descendant] then
        destroyVisual(descendant)
    end
end)

scan(workspace)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(refreshRates)
