local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local visuals = {}
local overdriveActive = false

local function profile()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local currentRate = 6 * profile().ParticleScale

local function refreshRates()
    local tier = profile()
    currentRate = 6 * tier.ParticleScale * (overdriveActive and 1.75 or 1)
    if tier.Name == "Low" then
        currentRate = math.min(currentRate, 1.8)
    end

    for pad, state in pairs(visuals) do
        if not pad.Parent or not state.attachment.Parent then
            visuals[pad] = nil
        else
            state.emitter.Rate = currentRate
            state.highlight.FillColor = overdriveActive
                and Color3.fromRGB(255, 205, 92)
                or pad.Color
            state.highlight.OutlineColor = overdriveActive
                and Color3.fromRGB(255, 245, 190)
                or pad.Color:Lerp(Color3.new(1, 1, 1), 0.42)
            state.highlight.FillTransparency = tier.Name == "Low" and 1 or (overdriveActive and 0.74 or 0.86)
            state.highlight.OutlineTransparency = tier.Name == "Low" and 0.36 or (overdriveActive and 0.04 or 0.16)

            local light = pad:FindFirstChild("MobilityPadLight")
            if light and light:IsA("PointLight") then
                light.Enabled = tier.Name ~= "Low"
                light.Color = overdriveActive and Color3.fromRGB(255, 215, 105) or pad.Color
                light.Brightness = (0.55 + (0.20 * tier.Scale)) * (overdriveActive and 1.65 or 1)
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

local bindToken = 0
local arenaConnection = nil
local mechanicsAddedConnection = nil
local mechanicsRemovedConnection = nil

local function clearAll()
    local pads = {}
    for pad in pairs(visuals) do
        table.insert(pads, pad)
    end
    for _, pad in ipairs(pads) do
        destroyVisual(pad)
    end
end

local function bindMechanics(mechanics, token)
    if mechanicsAddedConnection then
        mechanicsAddedConnection:Disconnect()
        mechanicsAddedConnection = nil
    end
    if mechanicsRemovedConnection then
        mechanicsRemovedConnection:Disconnect()
        mechanicsRemovedConnection = nil
    end

    if not mechanics or token ~= bindToken then
        return
    end

    for _, child in ipairs(mechanics:GetChildren()) do
        attach(child)
    end

    mechanicsAddedConnection = mechanics.ChildAdded:Connect(function(child)
        if token == bindToken then
            attach(child)
        end
    end)

    mechanicsRemovedConnection = mechanics.ChildRemoved:Connect(function(child)
        if visuals[child] then
            destroyVisual(child)
        end
    end)
end

local function bindGeneratedMap(generated)
    bindToken += 1
    local token = bindToken

    if arenaConnection then
        arenaConnection:Disconnect()
        arenaConnection = nil
    end
    bindMechanics(nil, token)

    clearAll()

    if not generated then
        return
    end

    task.defer(function()
        local arena = generated:FindFirstChild("Arena") or generated:WaitForChild("Arena", 5)
        if token ~= bindToken or not arena then
            return
        end

        local mechanics = arena:FindFirstChild("Mechanics")
        if mechanics then
            bindMechanics(mechanics, token)
        end

        arenaConnection = arena.ChildAdded:Connect(function(child)
            if token == bindToken and child.Name == "Mechanics" then
                bindMechanics(child, token)
            end
        end)
    end)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindGeneratedMap(child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindGeneratedMap(nil)
    end
end)

local existing = workspace:FindFirstChild("GeneratedMap")
if existing then
    bindGeneratedMap(existing)
end

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(refreshRates)


stateEvent.OnClientEvent:Connect(function(state)
    local nextOverdrive = state.phase == "round" and state.overdrive == true
    if nextOverdrive ~= overdriveActive then
        overdriveActive = nextOverdrive
        refreshRates()
    end
end)
