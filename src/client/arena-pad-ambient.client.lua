local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)

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
local watchedMap = nil
local watchedArena = nil
local rootAddedConnection = nil
local rootRemovedConnection = nil
local arenaAddedConnection = nil
local arenaRemovedConnection = nil
local disconnectPadAttributes = nil

local function clearAll()
    local pads = {}
    for pad in pairs(visuals) do
        table.insert(pads, pad)
    end
    for _, pad in ipairs(pads) do
        destroyVisual(pad)
    end
end

local function releasePadWatch()
    if disconnectPadAttributes then
        disconnectPadAttributes()
        disconnectPadAttributes = nil
    end
    clearAll()
end

local function bindMechanics(mechanics, token)
    releasePadWatch()
    if not mechanics or token ~= bindToken then return end

    -- Queue ownership belongs to THIS mechanics folder, not a global flag:
    -- an old deferred scan must never suppress the new map's first scan.
    local padScanQueued = false
    local function schedulePadScan()
        if padScanQueued then return end
        padScanQueued = true
        task.defer(function()
            padScanQueued = false
            -- A stale deferred signal cannot attach pads to a newer map.
            if token ~= bindToken or mechanics.Parent ~= watchedArena then
                return
            end

            local eligible = {}
            for _, pad in ipairs(mechanics:GetChildren()) do
                if pad:IsA("BasePart")
                    and pad:GetAttribute("ArenaMobilityPad") == true then
                    eligible[pad] = true
                    attach(pad)
                end
            end
            local removed = {}
            for pad in pairs(visuals) do
                if not eligible[pad] then
                    table.insert(removed, pad)
                end
            end
            for _, pad in ipairs(removed) do
                destroyVisual(pad)
            end
            -- A newly marked pad inherits current tier / overdrive state.
            refreshRates()
        end)
    end

    disconnectPadAttributes = MapVisualReadiness.watchChildrenAttributes(
        mechanics, {"ArenaMobilityPad"}, schedulePadScan
    )
end

local function bindArena(arena, token)
    if arenaAddedConnection then
        arenaAddedConnection:Disconnect()
        arenaAddedConnection = nil
    end
    if arenaRemovedConnection then
        arenaRemovedConnection:Disconnect()
        arenaRemovedConnection = nil
    end
    releasePadWatch()
    watchedArena = arena
    if not arena or token ~= bindToken then return end

    arenaAddedConnection = arena.ChildAdded:Connect(function(child)
        if token == bindToken and child.Name == "Mechanics" then
            bindMechanics(child, token)
        end
    end)
    arenaRemovedConnection = arena.ChildRemoved:Connect(function(child)
        if token == bindToken and child.Name == "Mechanics" then
            bindMechanics(arena:FindFirstChild("Mechanics"), token)
        end
    end)
    bindMechanics(arena:FindFirstChild("Mechanics"), token)
end

local function bindGeneratedMap(generated)
    bindToken += 1
    local token = bindToken

    if rootAddedConnection then
        rootAddedConnection:Disconnect()
        rootAddedConnection = nil
    end
    if rootRemovedConnection then
        rootRemovedConnection:Disconnect()
        rootRemovedConnection = nil
    end
    bindArena(nil, token)
    watchedMap = generated

    if not generated then return end

    -- Do not time out after 5 seconds. Under slow mobile streaming the Arena,
    -- Mechanics folder and its pad marker attributes may all arrive later.
    rootAddedConnection = generated.ChildAdded:Connect(function(child)
        if token == bindToken and child.Name == "Arena" then
            bindArena(child, token)
        end
    end)
    rootRemovedConnection = generated.ChildRemoved:Connect(function(child)
        if token == bindToken and child == watchedArena then
            bindArena(generated:FindFirstChild("Arena"), token)
        end
    end)
    bindArena(generated:FindFirstChild("Arena"), token)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap"
        and workspace:FindFirstChild("GeneratedMap") == child then
        bindGeneratedMap(child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child == watchedMap then
        bindGeneratedMap(workspace:FindFirstChild("GeneratedMap"))
    end
end)

bindGeneratedMap(workspace:FindFirstChild("GeneratedMap"))

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(refreshRates)


stateEvent.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    local nextOverdrive = state.phase == "round" and state.overdrive == true
    if nextOverdrive ~= overdriveActive then
        overdriveActive = nextOverdrive
        refreshRates()
    end
end)
