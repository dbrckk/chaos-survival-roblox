local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)
local PremiumMobilityPad3DKit = require(
    script.Parent.PremiumMobilityPad3DKit)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local visuals = {}
local overdriveActive = false
local roundActive = false

-- Only server-awarded, personal movement charges change the local
-- appearance of real pads. This never creates a client-side reward.
local function masteryState(pad)
    if not roundActive
        or player:GetAttribute("RoundParticipant") ~= true
        or player:GetAttribute("RoundEliminated") == true
    then return nil end
    local arena = pad.Parent and pad.Parent.Parent
    local variant = arena and arena:GetAttribute("VariantId")
    if variant == "Classic"
        and player:GetAttribute("RoundGridCircuitBoostReady") == true
    then return "CIRCUIT", "GRID" end
    if variant == "Towers"
        and player:GetAttribute("RoundSkyrailAceBoostReady") == true
    then return "SKYRAIL", "ACE" end
    if variant == "Crossroads"
        and player:GetAttribute("RoundFluxJunctionBoostReady") == true
    then return "FLUX", "MASTER" end
    if variant == "Orbital"
        and player:GetAttribute("RoundHelixMasterPulseReady") == true
    then return "ORBIT", "MASTER" end
    if variant == "Harbor"
        and player:GetAttribute("RoundHarborTransferReady") == true
    then return "SQUALL", "READY" end
    return nil
end

local function profile()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local currentRate = 6 * profile().ParticleScale
local french = string.sub(string.lower(
    LocalizationService.RobloxLocaleId), 1, 2) == "fr"

-- Premium readable top plate even when Low Android cannot afford any
-- optional original 3D meshes. All pieces are SurfaceGui 2D primitives
-- ON the REAL physical pad, not floating screen UI or extra world Parts.
local function topPlate(pad)
    local arena = pad.Parent and pad.Parent.Parent
    local variant = arena and arena:GetAttribute("VariantId") or "Classic"
    local word = ({
        Classic = french and "ÉVASION" or "ESCAPE",
        Towers = french and "ASCENSION" or "UPDRAFT",
        Crossroads = french and "VOIE" or "LANE",
        Orbital = french and "ORBITE" or "ORBIT",
        Harbor = french and "TRANSFERT" or "TRANSFER",
    })[variant] or "BOOST"

    local gui = Instance.new("SurfaceGui")
    gui.Name = "MobilityPadTopPlateLocal"
    gui.Adornee = pad
    gui.Face = Enum.NormalId.Top
    gui.CanvasSize = Vector2.new(256, 256)
    gui.AlwaysOnTop = false
    gui.LightInfluence = 0.25
    gui.MaxDistance = 115
    gui.Parent = pad

    local panel = Instance.new("Frame")
    panel.Name = "ForgedCautionFrame"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromScale(0.84, 0.84)
    panel.BackgroundColor3 = Color3.fromRGB(17, 27, 42)
    -- Keep the original bright pad visible even on dim Android devices.
    panel.BackgroundTransparency = 0.72
    panel.BorderSizePixel = 0
    panel.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.10, 0)
    corner.Parent = panel

    local outline = Instance.new("UIStroke")
    outline.Color = pad.Color:Lerp(Color3.new(1, 1, 1), 0.2)
    outline.Thickness = 3
    outline.Transparency = 0.10
    outline.Parent = panel

    local number = Instance.new("TextLabel")
    number.Name = "StationOrdinal"
    number.BackgroundTransparency = 1
    number.Position = UDim2.fromScale(0.10, 0.12)
    number.Size = UDim2.fromScale(0.30, 0.24)
    number.Font = Enum.Font.GothamBlack
    number.TextScaled = true
    number.TextXAlignment = Enum.TextXAlignment.Left
    number.Text = string.format("%02d", tonumber(
        pad:GetAttribute("ArenaMobilityPadIndex")) or 0)
    number.TextColor3 = pad.Color
    number.Parent = panel

    local label = Instance.new("TextLabel")
    label.Name = "MobilityFunction"
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromScale(0.08, 0.44)
    label.Size = UDim2.fromScale(0.84, 0.35)
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.Text = word
    label.TextColor3 = Color3.fromRGB(238, 246, 251)
    label.Parent = panel

    local bar = Instance.new("Frame")
    bar.Name = "CurrentChannel"
    bar.BorderSizePixel = 0
    bar.Position = UDim2.fromScale(0.50, 0.18)
    bar.Size = UDim2.fromScale(0.37, 0.035)
    bar.BackgroundColor3 = pad.Color
    bar.Parent = panel

    -- Reuse the existing pad SurfaceGui, not a floating BillboardGui or
    -- new world geometry. Its label only lights up after real mastery.
    local charge = Instance.new("TextLabel")
    charge.Name = "PersonalCharge"
    charge.BackgroundTransparency = 1
    charge.Position = UDim2.fromScale(0.08, 0.80)
    charge.Size = UDim2.fromScale(0.84, 0.15)
    charge.Font = Enum.Font.GothamBold
    charge.TextScaled = true
    charge.TextColor3 = Color3.fromRGB(255, 230, 155)
    charge.Text = ""
    charge.Visible = false
    charge.Parent = panel

    return gui, outline, number, bar, label, charge
end

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
            if state.surface and state.surface.Parent then
                state.surface:Destroy()
            end
        else
            local chargeKind, chargeLabel = masteryState(pad)
            local mastered = chargeKind ~= nil
            local personalColor = Color3.fromRGB(255, 227, 145)
            -- A private, subtle cyan-gold edge makes the charged *real*
            -- pads stand out. Overdrive and hazard orange always win.
            state.emitter.Rate = currentRate
            state.highlight.FillColor = overdriveActive
                and Color3.fromRGB(255, 205, 92)
                or pad.Color
            state.highlight.OutlineColor = overdriveActive
                and Color3.fromRGB(255, 245, 190)
                or (mastered and personalColor
                    or pad.Color:Lerp(Color3.new(1, 1, 1), 0.42))
            state.highlight.FillTransparency = tier.Name == "Low" and 1 or (overdriveActive and 0.74 or 0.86)
            state.highlight.OutlineTransparency = tier.Name == "Low" and 0.36 or (overdriveActive and 0.04 or 0.16)
            if state.surface and state.surface.Parent then
                local tint = overdriveActive and Color3.fromRGB(255, 217, 126)
                    or pad.Color
                state.surfaceOutline.Color = tint
                state.surfaceNumber.TextColor3 = tint
                state.surfaceBar.BackgroundColor3 =
                    mastered and not overdriveActive and personalColor or tint
                if state.surfaceCharge then
                    state.surfaceCharge.Visible = mastered
                    state.surfaceCharge.Text = mastered and (
                        french and "BONUS PRÊT" or "BONUS READY") or ""
                end
                if state.surfaceLabel then
                    state.surfaceLabel.TextColor3 = mastered
                        and not overdriveActive and Color3.fromRGB(255, 245, 209)
                        or Color3.fromRGB(238, 246, 251)
                end
                -- Critical hazard outlines are already owned elsewhere;
                -- a pad top-plate must not become a glowing false warning.
                state.surface.Enabled = true
            end

            local light = pad:FindFirstChild("MobilityPadLight")
            if light and light:IsA("PointLight") then
                light.Enabled = tier.Name ~= "Low"
                light.Color = overdriveActive and Color3.fromRGB(255, 215, 105) or pad.Color
                light.Brightness = (0.55 + (0.20 * tier.Scale)) * (overdriveActive and 1.65 or 1)
            end
        end
    end

    -- Only real source-authenticated MeshParts in the *existing*
    -- mobile visual census. No new polling loop; reuse event-driven
    -- pad/quality/pressure and late template readiness updates.
    local count = PremiumMobilityPad3DKit.sync(
        visuals, VfxQuality.deviceTier(
            player:GetAttribute("VfxQualityTier"),
            UserInputService.TouchEnabled).Name,
        player:GetAttribute("OptionalVfxPressure"),
        UserInputService.TouchEnabled)
    if player:GetAttribute("LocalOriginalMobilityPad3DCount") ~= count then
        player:SetAttribute("LocalOriginalMobilityPad3DCount", count)
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
        if state.surface and state.surface.Parent then
            state.surface:Destroy()
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

    local surface, surfaceOutline, surfaceNumber, surfaceBar,
        surfaceLabel, surfaceCharge = topPlate(pad)

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
        surface = surface,
        surfaceOutline = surfaceOutline,
        surfaceNumber = surfaceNumber,
        surfaceBar = surfaceBar,
        surfaceLabel = surfaceLabel,
        surfaceCharge = surfaceCharge,
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
    PremiumMobilityPad3DKit.clear()
    if player:GetAttribute("LocalOriginalMobilityPad3DCount") ~= 0 then
        player:SetAttribute("LocalOriginalMobilityPad3DCount", 0)
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
player:GetAttributeChangedSignal("OptionalVfxPressure"):Connect(refreshRates)

-- The existing visual owner already has all pads and budget information.
-- Repaint on server replication only, never on RenderStepped/Heartbeat.
for _, attribute in ipairs({
    "RoundParticipant", "RoundEliminated",
    "RoundGridCircuitBoostReady", "RoundFluxJunctionBoostReady",
    "RoundSkyrailAceBoostReady", "RoundHelixMasterPulseReady",
    "RoundHarborTransferReady",
}) do
    player:GetAttributeChangedSignal(attribute):Connect(refreshRates)
end

-- The approved 3D kit arrives after the server's serialized low-priority
-- import (about 34 seconds); do not lock visual quality to a startup
-- timeout. A late genuine template can fill existing pads immediately.
local watchedSourceHolder = nil
local sourceConnections = {}
local function bindSourceHolder(parent)
    if watchedSourceHolder == parent then return end
    for _, connection in ipairs(sourceConnections) do
        connection:Disconnect()
    end
    table.clear(sourceConnections)
    watchedSourceHolder = parent
    if parent and parent:IsA("Folder") then
        table.insert(sourceConnections, parent.ChildAdded:Connect(function(child)
            if child.Name == "CornerGuard" then scheduleReconcile() end
        end))
        table.insert(sourceConnections, parent.ChildRemoved:Connect(function(child)
            if child.Name == "CornerGuard" then scheduleReconcile() end
        end))
        table.insert(sourceConnections, parent:GetAttributeChangedSignal(
            "OwnerVerified"):Connect(scheduleReconcile))
    end
    scheduleReconcile()
end

ReplicatedStorage.ChildAdded:Connect(function(child)
    if child.Name == "ApprovedFloorReliefTemplates" then
        bindSourceHolder(child)
    end
end)
ReplicatedStorage.ChildRemoved:Connect(function(child)
    if child == watchedSourceHolder then
        bindSourceHolder(ReplicatedStorage:FindFirstChild(
            "ApprovedFloorReliefTemplates"))
    end
end)
bindSourceHolder(ReplicatedStorage:FindFirstChild(
    "ApprovedFloorReliefTemplates"))

stateEvent.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    local nextRound = state.phase == "round"
    local nextOverdrive = nextRound and state.overdrive == true
    if nextOverdrive ~= overdriveActive or nextRound ~= roundActive then
        roundActive = nextRound
        overdriveActive = nextOverdrive
        refreshRates()
    end
end)
