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
        if not pad.Parent or not state.attachment.Parent
            or not state.highlight.Parent then
            -- External streaming/cleanup can remove one owner first.
            -- Dispose both client-only instances rather than orphaning
            -- a highlight until the next complete arena replacement.
            visuals[pad] = nil
            if state.colorConnection then
                state.colorConnection:Disconnect()
            end
            if state.attachment.Parent then state.attachment:Destroy() end
            if state.highlight.Parent then state.highlight:Destroy() end
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
        if state.colorConnection then
            state.colorConnection:Disconnect()
        end
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

    local colorConnection = pad:GetPropertyChangedSignal("Color"):Connect(function()
        -- A Color property can also arrive after the marker attribute.
        -- Keep the particles and highlights aligned with the real pad.
        if visuals[pad] then
            emitter.Color = ColorSequence.new(pad.Color, Color3.new(1, 1, 1))
            refreshRates()
        end
    end)

    visuals[pad] = {
        attachment = attachment,
        emitter = emitter,
        highlight = highlight,
        colorConnection = colorConnection,
    }

    local light = pad:FindFirstChild("MobilityPadLight")
    if light and light:IsA("PointLight") then
        light.Enabled = profile().Name ~= "Low"
    end
end

-- Shared readiness watchers avoid a hard five-second Arena timeout.
-- The complete hierarchy can stream in independently on slow Android:
-- GeneratedMap -> Arena -> Mechanics -> Part -> ArenaMobilityPad flag.
local watchedMap = nil
local watchedArena = nil
local watchedMechanics = nil
local disconnectMapWatch = nil
local disconnectArenaAdded = nil
local disconnectArenaRemoved = nil
local disconnectPadAttributes = nil
local reconcilePending = false

local function clearAll()
    local pads = {}
    for pad in pairs(visuals) do
        table.insert(pads, pad)
    end
    for _, pad in ipairs(pads) do
        destroyVisual(pad)
    end
end

local function reconcileVisuals()
    local mechanics = watchedMechanics
    for pad in pairs(visuals) do
        if not mechanics or pad.Parent ~= mechanics
            or pad:GetAttribute("ArenaMobilityPad") ~= true then
            destroyVisual(pad)
        end
    end
    if mechanics then
        for _, pad in ipairs(mechanics:GetChildren()) do
            attach(pad)
        end
    end
    -- A pad can be attached while Overdrive or Low tier is already active.
    -- Apply the live phase/tier to new pads immediately.
    refreshRates()
end

local function scheduleReconcile()
    if reconcilePending then return end
    reconcilePending = true
    task.defer(function()
        reconcilePending = false
        reconcileVisuals()
    end)
end

local function bindMechanics(mechanics)
    if watchedMechanics == mechanics then return end
    if disconnectPadAttributes then
        disconnectPadAttributes()
        disconnectPadAttributes = nil
    end
    clearAll()
    watchedMechanics = mechanics
    if mechanics then
        disconnectPadAttributes = MapVisualReadiness.watchChildrenAttributes(
            mechanics, {"ArenaMobilityPad"}, scheduleReconcile
        )
    end
    scheduleReconcile()
end

local function bindArena(arena)
    if watchedArena == arena then return end
    if disconnectArenaAdded then
        disconnectArenaAdded:Disconnect()
        disconnectArenaAdded = nil
    end
    if disconnectArenaRemoved then
        disconnectArenaRemoved:Disconnect()
        disconnectArenaRemoved = nil
    end
    watchedArena = arena
    if arena then
        disconnectArenaAdded = arena.ChildAdded:Connect(function(child)
            if child.Name == "Mechanics" then
                bindMechanics(child)
            end
        end)
        disconnectArenaRemoved = arena.ChildRemoved:Connect(function(child)
            if child == watchedMechanics then
                bindMechanics(arena:FindFirstChild("Mechanics"))
            end
        end)
    end
    bindMechanics(arena and arena:FindFirstChild("Mechanics") or nil)
end

local function bindGeneratedMap(generated)
    if watchedMap == generated then return end
    if disconnectMapWatch then
        disconnectMapWatch()
        disconnectMapWatch = nil
    end
    watchedMap = generated
    bindArena(nil)
    if generated then
        -- The watcher emits when Arena arrives even before Base exists,
        -- then rebinds after removal; no busy waiting or timeout.
        disconnectMapWatch = MapVisualReadiness.watch(
            generated, "Arena", "Base", function()
                bindArena(generated:FindFirstChild("Arena"))
            end
        )
    end
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
