-- CROSSROADS FLUX RELAY
-- Authored modular signal architecture, tier-scaled. Server triggers provide
-- all gameplay; this layer creates only anchored noncolliding art + status.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local LocalizationService = game:GetService("LocalizationService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local FluxRelayRules = require(ReplicatedStorage.Shared.FluxRelayRules)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local MobileHudNotices = require(ReplicatedStorage.Shared.MobileHudNotices)
local CelebrationMeshes = require(script.Parent.LobbyCelebrationMeshes)
local PremiumJunctionHardware3DKit = require(
    script.Parent.PremiumJunctionHardware3DKit)

local player = Players.LocalPlayer
local french = string.sub(string.lower(LocalizationService.RobloxLocaleId), 1, 2) == "fr"

local style = {
    Frame = Color3.fromRGB(28, 36, 54),
    Edge = Color3.fromRGB(83, 102, 133),
    Charged = Color3.fromRGB(88, 250, 229),
    Idle = Color3.fromRGB(118, 95, 164),
    Signal = Color3.fromRGB(251, 176, 100),
}

local folder = Instance.new("Folder")
folder.Name = "FluxRelayLocal"
folder.Parent = workspace

local gates = {}
local connections = {}
local source = nil
local sourceToken = 0
local activeRound = false
local lastHudKey = ""
local meshPressure = tonumber(player:GetAttribute("OptionalVfxPressure")) or 0
local gateProfiles = {}
local profileRoles = {"pylon", "casting", "runway", "fragment"}
local nextProfileCheck = 0

-- Reuse the existing local render cadence, without any extra polling.
local hud = Instance.new("ScreenGui")
hud.Name = "FluxWeaveProgress"
hud.ResetOnSpawn = false
hud.IgnoreGuiInset = true
hud.DisplayOrder = 34
hud.Parent = player:WaitForChild("PlayerGui")
local hudPanel = Instance.new("Frame")
hudPanel.Name = "FluxWeaveStatus"
hudPanel.AnchorPoint = Vector2.new(0.5, 0)
hudPanel.Position = UDim2.fromScale(0.5, 0.125)
hudPanel.Size = UDim2.fromOffset(254, 34)
hudPanel.BackgroundColor3 = Color3.fromRGB(13, 23, 40)
hudPanel.BackgroundTransparency = 0.18
hudPanel.BorderSizePixel = 0
hudPanel.Visible = false
hudPanel.Parent = hud
local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 8)
hudCorner.Parent = hudPanel
local hudOutline = Instance.new("UIStroke")
hudOutline.Color = style.Edge
hudOutline.Transparency = 0.20
hudOutline.Parent = hudPanel
local hudTitle = Instance.new("TextLabel")
hudTitle.Name = "FluxWeaveText"
hudTitle.Size = UDim2.fromScale(1, 1)
hudTitle.BackgroundTransparency = 1
hudTitle.Font = Enum.Font.GothamBold
hudTitle.TextScaled = true
hudTitle.TextColor3 = Color3.fromRGB(222, 236, 255)
hudTitle.Text = ""
hudTitle.Parent = hudPanel
local hudTrack = Instance.new("Frame")
hudTrack.Name = "FluxWeaveTrack"
hudTrack.Size = UDim2.new(1, 0, 0, 5)
hudTrack.Position = UDim2.new(0, 0, 1, 4)
hudTrack.BackgroundTransparency = 1
hudTrack.Parent = hudPanel
local hudPips = {}
for index = 1, FluxRelayRules.WeaveCap do
    local pip = Instance.new("Frame")
    pip.Name = "FluxWeaveStep" .. index
    pip.Position = UDim2.new((index - 1) / FluxRelayRules.WeaveCap,
        index == 1 and 0 or 2, 0, 0)
    pip.Size = UDim2.new(1 / FluxRelayRules.WeaveCap,
        index == 1 and -5 or -7, 1, 0)
    pip.BackgroundColor3 = style.Edge
    pip.BorderSizePixel = 0
    pip.Parent = hudTrack
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = pip
    hudPips[index] = pip
end
-- A sustained tracker is allowed only when it clears the native Roblox
-- inset, authoritative hazard/alive header and bottom survival meter.
local touchDevice = UserInputService.TouchEnabled
local trackerFits = true
local hudEligible = false
local function refreshProgressVisibility()
    hudPanel.Visible = hudEligible and (not touchDevice
        or (trackerFits and MobileHudNotices.current() == nil))
end

local viewportConnection = nil
local function layoutProgress()
    if not touchDevice then
        hudPanel.Position = UDim2.fromScale(0.5, 0.125)
        hudPanel.Size = UDim2.fromOffset(254, 34)
        trackerFits = true
    else
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
        local inset = GuiService:GetGuiInset()
        local layout = UIResponsive.mobileMechanicTracker(viewport, inset.Y)
        hudPanel.Position = UDim2.new(layout.centerXScale, 0, 0, layout.topOffset)
        hudPanel.Size = UDim2.fromOffset(layout.width, layout.height)
        trackerFits = layout.fits
    end
    refreshProgressVisibility()
end

local function bindProgressCamera()
    if viewportConnection then viewportConnection:Disconnect() end
    local camera = workspace.CurrentCamera
    viewportConnection = camera and camera:GetPropertyChangedSignal("ViewportSize")
        :Connect(layoutProgress) or nil
    layoutProgress()
end

if touchDevice then
    MobileHudNotices.Changed:Connect(refreshProgressVisibility)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindProgressCamera)
bindProgressCamera()

local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
stateEvent.OnClientEvent:Connect(function(data)
    activeRound = type(data) == "table" and data.phase == "round"
end)

local function quality()
    return VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), touchDevice).Name
end

local function refreshGateProfiles()
    local nextProfiles = {}
    local changed = false
    for _, role in ipairs(profileRoles) do
        local profile = CelebrationMeshes.readyProfile(role, meshPressure)
        local id = profile and profile.MeshId
        nextProfiles[role] = profile
        nextProfiles[role .. "Id"] = id
        if profile ~= gateProfiles[role] or id ~= gateProfiles[role .. "Id"] then changed = true end
    end
    gateProfiles = nextProfiles
    nextProfileCheck = os.clock() + 1
    return changed
end

local function newPart(name, size, cf, tint, material, transparency, meshSource, alignProfile)
    local mesh = CelebrationMeshes.cloneProfile(meshSource)
    local p = mesh or Instance.new("Part")
    if mesh then
        p.MaterialVariant = ""
        if alignProfile and (meshSource.Size.X > meshSource.Size.Z) ~= (size.X > size.Z) then
            size = Vector3.new(size.Z, size.Y, size.X)
            cf *= CFrame.Angles(0, math.pi * 0.5, 0)
        end
    end
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Material = material
    p.Color = tint
    p.Transparency = transparency or 0
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = folder
    return p
end

local function clear()
    for _, c in ipairs(connections) do
        c:Disconnect()
    end
    table.clear(connections)
    PremiumJunctionHardware3DKit.clear()
    folder:ClearAllChildren()
    table.clear(gates)
    if player:GetAttribute("LocalApprovedJunctionHousing3DCount") ~= 0 then
        player:SetAttribute("LocalApprovedJunctionHousing3DCount", 0)
    end
    hudEligible = false
    refreshProgressVisibility()
    lastHudKey = ""
end

local function banner(trigger)
    local display = Instance.new("BillboardGui")
    display.Name = "FluxRelaySignal"
    display.Adornee = trigger
    display.Size = UDim2.fromOffset(132, 35)
    display.StudsOffsetWorldSpace = Vector3.new(0, 3.65, 0)
    display.AlwaysOnTop = false
    display.MaxDistance = 62
    display.Parent = folder

    local label = Instance.new("TextLabel")
    label.Name = "FluxStatus"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(12, 20, 35)
    label.BackgroundTransparency = 0.18
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.TextColor3 = style.Idle
    label.Text = "FLUX // STANDBY"
    label.Parent = display
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = label
    local stroke = Instance.new("UIStroke")
    stroke.Color = style.Edge
    stroke.Thickness = 1
    stroke.Transparency = 0.24
    stroke.Parent = label
    return label, stroke
end

local function makeGate(trigger)
    if gates[trigger] or not trigger:IsA("BasePart") then return end
    local index = trigger:GetAttribute("FluxRelayIndex")
    local outward = FluxRelayRules.Offsets[index]
    if not outward then return end

    -- The live relay sends the runner toward the hub on all four lanes.
    local forward = trigger.CFrame:VectorToWorldSpace(-outward.Unit)
    local basis = CFrame.lookAt(trigger.Position, trigger.Position + forward)
    local tier = quality()
    local detail = tier == "High" and 2 or (tier == "Medium" and 1 or 0)
    local shaft, casting, swept = gateProfiles.pylon, gateProfiles.casting, gateProfiles.runway
    local statusPieces, pieces = {}, {}
    local triggerFrame = trigger.CFrame
    local function fitting(name, size, cf, color, material, alpha, profile)
        local part = newPart(name, size, cf, color, material, alpha, profile, true)
        pieces[#pieces + 1] = {part = part, localCFrame = triggerFrame:ToObjectSpace(part.CFrame)}
        return part
    end

    fitting("FluxBridgeCap", Vector3.new(9.12, 0.66, 1.05),
        basis * CFrame.new(0, 2.95, 0), style.Frame, Enum.Material.Metal, 0, swept or casting)
    for side = -1, 1, 2 do
        local x = side * 4.24
        fitting("FluxFooting", Vector3.new(1.36, 0.30, 1.38),
            basis * CFrame.new(x, -1.97, 0), style.Edge, Enum.Material.DiamondPlate, 0.04, casting)
        fitting(side < 0 and "FluxFrameLeft" or "FluxFrameRight", Vector3.new(0.76, 4.98, 0.80),
            basis * CFrame.new(x, 0.46, 0), style.Frame, Enum.Material.DiamondPlate, 0, shaft)
        statusPieces[#statusPieces + 1] = fitting("FluxVerticalSignal", Vector3.new(0.16, 4.30, 0.19),
            basis * CFrame.new(side * 3.82, 0.39, -0.27),
            style.Idle, Enum.Material.Neon, 0.48, shaft)

        local tip = basis * Vector3.new(0, -1.93, -2.4)
        local tail = basis * Vector3.new(side * 0.70, -1.93, -1.37)
        statusPieces[#statusPieces + 1] = fitting("FluxChevron",
            Vector3.new(0.23, 0.065, (tip - tail).Magnitude),
            CFrame.lookAt((tip + tail) * 0.5, tip),
            style.Idle, Enum.Material.Neon, 0.38, swept or casting)
        if detail >= 1 then
            fitting("FluxArmorFin", Vector3.new(0.95, 0.45, 1.24),
                basis * CFrame.new(x, 1.9, 0), style.Edge, Enum.Material.Metal, 0.08, casting)
        end
    end
    statusPieces[#statusPieces + 1] = fitting("FluxCrest", Vector3.new(4.3, 0.15, 0.22),
        basis * CFrame.new(0, 2.5, -0.5), style.Idle, Enum.Material.Neon, 0.4, swept or casting)

    if detail == 2 then
        for segment = -1, 1 do
            local prism = fitting("FluxCrownPrism", Vector3.new(0.72, 0.32, 0.50),
                basis * CFrame.new(segment * 1.9, 3.4, 0)
                    * CFrame.Angles(0, 0, math.rad(segment * 26)),
                style.Edge, Enum.Material.Glass, 0.08, gateProfiles.fragment)
            prism.Reflectance = 0.12
        end
    end

    local label, stroke = banner(trigger)
    local entry = {
        trigger = trigger,
        statusPieces = statusPieces,
        label = label,
        stroke = stroke,
        lastStatus = nil,
        blinkUntil = -math.huge,
        sourceCFrame = trigger.CFrame,
        parts = pieces,
    }
    gates[trigger] = entry

    table.insert(connections, trigger:GetAttributeChangedSignal("FluxTriggeredAt"):Connect(function()
        if not gates[trigger] then return end
        entry.blinkUntil = os.clock() + 0.3
        local camera = workspace.CurrentCamera
        local withinEarshot = camera
            and (camera.CFrame.Position - trigger.Position).Magnitude <= 95
        if withinEarshot and player:GetAttribute("AudioMuted") ~= true then
            local tone = Instance.new("Sound")
            tone.Name = "FluxRelayChargeWhoosh"
            tone.SoundId = "rbxasset://sounds/electronicpingshort.wav"
            tone.Volume = 0.15
            tone.PlaybackSpeed = 0.68
                + (tonumber(trigger:GetAttribute("FluxRelayIndex")) or 1) * 0.055
            tone.RollOffMaxDistance = 50
            tone.RollOffMinDistance = 5
            tone.SoundGroup = SoundService:FindFirstChild("ChaosSFX")
            tone.Parent = trigger
            tone:Play()
            Debris:AddItem(tone, 2)
        end
        if player:GetAttribute("ReduceMotion") == true
            or quality() == "Low"
        then
            return
        end
        local rank = math.clamp(
            tonumber(trigger:GetAttribute("FluxWeaveTier")) or 1, 1, 3
        )
        local center = trigger.Position + Vector3.new(0, -2.75, 0)
        local color = rank == 3 and style.Signal or style.Charged
        local burstSource = CelebrationMeshes.readyProfile("fragment", meshPressure)
        local flash = newPart("FluxCompletionGlyph",
            Vector3.new(2.5, 0.1, 0.18),
            CFrame.new(center), color, Enum.Material.Neon, 0.08, burstSource)
        TweenService:Create(flash, TweenInfo.new(0.4), {
            Size = Vector3.new(rank == 3 and 8.4 or 6.8, 0.1, 0.12),
            Transparency = 1,
        }):Play()
        Debris:AddItem(flash, 0.48)

        if rank >= 2 then
            local count = tier == "High" and (rank == 3 and 8 or 6)
                or (rank == 3 and 5 or 3)
            for n = 1, count do
                local radians = n * math.pi * 2 / count
                local radial = Vector3.new(math.cos(radians), 0, math.sin(radians))
                local start = center + Vector3.new(0, 2.5, 0) + radial * 1.7
                local finish = start + radial * 3.2 + Vector3.new(0, 1.4, 0)
                local facet = newPart("FluxWeaveFacet",
                    Vector3.new(0.18, 0.11, 0.75),
                    CFrame.lookAt(start, finish), color, Enum.Material.Neon, 0.14, burstSource)
                TweenService:Create(facet, TweenInfo.new(0.42), {
                    CFrame = CFrame.lookAt(finish, finish + radial),
                    Transparency = 1,
                }):Play()
                Debris:AddItem(facet, 0.48)
            end

            -- This temporary badge is close to the actual scored gate,
            -- useful to observers without occupying the player's mobile UI.
            local badge = Instance.new("BillboardGui")
            badge.Name = "FluxWeaveBadge"
            badge.Adornee = trigger
            badge.Size = UDim2.fromOffset(172, 35)
            badge.StudsOffsetWorldSpace = Vector3.new(0, 4.2, 0)
            badge.MaxDistance = 75
            badge.AlwaysOnTop = false
            badge.Parent = folder
            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundColor3 = Color3.fromRGB(19, 26, 45)
            label.BackgroundTransparency = 0.18
            label.BorderSizePixel = 0
            label.Font = Enum.Font.GothamBlack
            label.TextScaled = true
            label.TextColor3 = color
            label.Text = rank == 3 and "FLUX MASTER ×3" or "FLUX WEAVE ×2"
            label.Parent = badge
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = label
            Debris:AddItem(badge, 1.1)
        end
    end))
end

local function renderHUD(serverTime)
    local participant = player:GetAttribute("RoundParticipant") == true
        and player:GetAttribute("RoundEliminated") ~= true
    local visible = activeRound and participant and next(gates) ~= nil
    if not visible then
        hudEligible = false
        refreshProgressVisibility()
        lastHudKey = ""
        return -1
    end
    local stage, remaining = FluxRelayRules.displayProgress(
        player:GetAttribute("RoundFluxWeaveCombo"),
        player:GetAttribute("RoundFluxWeaveDeadline"), serverTime
    )
    -- On a touch device the unstarted 'TRAVERSE UNE ARCHE' box was
    -- permanently centered over the character in real Android captures.
    -- Only show its initial instruction near a real gate; after the first
    -- crossing, keep the timed 1/3..3/3 progress visible. The existing
    -- gate sculptures and server-side triggers still guide players.
    local nearGate = false
    if touchDevice and stage == 0 then
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then
            for trigger in pairs(gates) do
                if trigger.Parent
                    and (trigger.Position - root.Position).Magnitude <= 26 then
                    nearGate = true
                    break
                end
            end
        end
    end
    hudEligible = UIResponsive.showMobileMechanicProgress(
        touchDevice, visible, stage, nearGate
    )
    refreshProgressVisibility()
    local nextParity = stage > 0 and stage < FluxRelayRules.WeaveCap
        and (tonumber(player:GetAttribute("RoundFluxWeaveNextParity")) or -1)
        or -1
    local boostReady =
        player:GetAttribute("RoundFluxJunctionBoostReady") == true
    local boostEarned =
        player:GetAttribute("RoundFluxJunctionBoostEarned") == true
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local mechanics = arena and arena:FindFirstChild("Mechanics")
    local junctionLive = mechanics
        and mechanics:FindFirstChild("JunctionSwitchyard") ~= nil
    local key = tostring(stage) .. "/" .. tostring(remaining)
        .. "/" .. tostring(nextParity) .. "/" .. tostring(boostReady)
        .. "/" .. tostring(boostEarned) .. "/" .. tostring(junctionLive)
    if key ~= lastHudKey then
        lastHudKey = key
        if boostReady and junctionLive then
            -- Show the actual GOLD destination, not an abstract reward.
            -- No second HUD: reuse the existing mobile-safe progress chip.
            hudTitle.Text = french and "BOOST • AIGUILLAGE OR"
                or "BOOST • GOLD JUNCTION"
            hudTitle.TextColor3 = style.Signal
        elseif stage == FluxRelayRules.WeaveCap then
            hudTitle.Text = boostEarned and junctionLive
                and (french and "FLUX MASTER • CUT UTILISÉ"
                    or "FLUX MASTER • CUT USED")
                or "FLUX MASTER  //  3/3"
            hudTitle.TextColor3 = style.Signal
        elseif stage == 0 then
            hudTitle.Text = if touchDevice
                then (french and "FLUX • PASSE L'ARCHE" or "FLUX • CROSS GATE")
                else (french and "FLUX • TRAVERSE UNE ARCHE"
                    or "FLUX • ENTER A CHARGED GATE")
            hudTitle.TextColor3 = Color3.fromRGB(222, 236, 255)
        else
            hudTitle.Text = string.format("FLUX %d/3  •  %s  •  %ds",
                stage, french and "AUTRE PAIRE" or "SWITCH PAIR", remaining)
            hudTitle.TextColor3 = remaining <= 3 and style.Signal or style.Charged
        end
        hudOutline.Color = stage == FluxRelayRules.WeaveCap and style.Signal or style.Edge
        for index, pip in ipairs(hudPips) do
            pip.BackgroundColor3 = index <= stage
                and (stage == FluxRelayRules.WeaveCap and style.Signal or style.Charged)
                or style.Edge
        end
    end
    return nextParity
end

local junctionDirections = {A = 1, AOuter = 1, B = -1, BOuter = -1}

-- Repaint the server-owned arrows and signs using the actual charged
-- pair, personal mastery and the direction of the latest accepted cut.
local function renderJunctions(serverTime, reduced)
    local arena = source and source:FindFirstChild("Arena")
    local mechanics = arena and arena:FindFirstChild("Mechanics")
    local yard = mechanics and mechanics:FindFirstChild("JunctionSwitchyard")
    local count = PremiumJunctionHardware3DKit.sync(
        yard, folder, quality(), player:GetAttribute("OptionalVfxPressure"),
        touchDevice, activeRound)
    if player:GetAttribute("LocalApprovedJunctionHousing3DCount") ~= count then
        player:SetAttribute("LocalApprovedJunctionHousing3DCount", count)
    end
    if not yard then return end
    local ready = player:GetAttribute("RoundFluxJunctionBoostReady") == true
        and player:GetAttribute("RoundParticipant") == true
        and player:GetAttribute("RoundEliminated") ~= true
        and activeRound
    for index = 1, 4 do
        local pad = yard:FindFirstChild("JunctionSwitch" .. index)
        local active = pad and pad:GetAttribute("JunctionActive") == true
        local personal = ready and active
        local board = yard:FindFirstChild("JunctionRouteSign" .. index)
        local label = board and board:FindFirstChild("JunctionRouteText")
        if label and label:IsA("TextLabel") then
            local caption = personal
                and (french and "COUPE MAÎTRE" or "MASTER CUT")
                or (french and "↔ COUPE LATÉRALE"
                    or "↔ TURN TO BOOST")
            if label.Text ~= caption then label.Text = caption end
            local desired = personal and Color3.fromRGB(255, 247, 167)
                or Color3.fromRGB(255, 203, 99)
            if label.TextColor3 ~= desired then
                label.TextColor3 = desired
            end
        end
        -- A short direction cue confirms the cut without changing which
        -- lane is charged or introducing a separate animation loop.
        local tint = personal and Color3.fromRGB(255, 245, 172)
            or (active and Color3.fromRGB(255, 203, 99)
                or Color3.fromRGB(122, 104, 174))
        local triggered = active and not reduced and pad:GetAttribute("JunctionTriggeredAt")
        local latest = if type(triggered) == "number"
            and serverTime >= triggered and serverTime - triggered < 0.42
            then pad:GetAttribute("JunctionTravelSign") else nil
        for suffix, travelSign in pairs(junctionDirections) do
            local chevron = yard:FindFirstChild("JunctionChevron" .. index .. suffix)
            local usedDirection = latest == travelSign
            local desired = usedDirection and Color3.fromRGB(255, 252, 214) or tint
            if chevron and chevron:IsA("BasePart") and chevron.Color ~= desired then
                chevron.Color = desired
            end
        end
    end
end

local function render(now)
    local serverTime = workspace:GetServerTimeNow()
    local reduced = player:GetAttribute("ReduceMotion") == true
    renderJunctions(serverTime, reduced)
    local nextParity = renderHUD(serverTime)
    for trigger, entry in pairs(gates) do
        if not trigger.Parent then
            -- Source rebinding owns the lifetime of all visual components.
            continue
        end
        if trigger.CFrame ~= entry.sourceCFrame then
            -- Shrinking Arena moves the server checkpoint; move the whole
            -- bespoke light sculpture to exactly the same physical gate.
            for _, piece in ipairs(entry.parts) do
                if piece.part.Parent then
                    piece.part.CFrame = trigger.CFrame * piece.localCFrame
                end
            end
            entry.sourceCFrame = trigger.CFrame
        end
        local epoch = trigger:GetAttribute("FluxCycleEpoch")
        local offset = trigger:GetAttribute("FluxPhaseOffset")
        local charged = epoch ~= nil and FluxRelayRules.charged(
            serverTime, epoch, offset
        )
        local index = tonumber(trigger:GetAttribute("FluxRelayIndex"))
        local nextGate = charged
            and (nextParity == 0 or nextParity == 1)
            and index ~= nil and index % 2 == nextParity
        local textStatus = nextGate
            and (french and "WEAVE // SUITE" or "WEAVE // NEXT")
            or (charged and (french and "FLUX // PRÊT" or "FLUX // READY")
                or (french and "FLUX // RECHARGE" or "FLUX // CHARGING"))
        if textStatus ~= entry.lastStatus then
            entry.lastStatus = textStatus
            entry.label.Text = textStatus
            entry.label.TextColor3 = nextGate and style.Signal
                or (charged and style.Charged or style.Idle)
            entry.stroke.Color = nextGate and style.Signal
                or (charged and style.Charged or style.Edge)
        end
        local pulse = reduced and 0.48 or (0.5 + 0.5 * math.sin(now * 4.0))
        local fresh = now < entry.blinkUntil
        local tint = (fresh or nextGate) and style.Signal
            or (charged and style.Charged or style.Idle)
        local alpha = charged and (0.10 + 0.18 * pulse) or 0.67
        if reduced then alpha = charged and 0.24 or 0.7 end
        for _, piece in ipairs(entry.statusPieces) do
            piece.Color = tint
            piece.Transparency = alpha
        end
    end
end

local function connect(event, callback)
    table.insert(connections, event:Connect(callback))
end

local function bind(generated)
    sourceToken += 1
    local token = sourceToken
    source = generated
    clear()
    if not generated then return end

    local function install()
        if token ~= sourceToken or not generated.Parent then return end
        clear()
        local arena = generated:FindFirstChild("Arena")
        local mechanics = arena and arena:FindFirstChild("Mechanics")
        local relays = mechanics and mechanics:FindFirstChild("FluxRelays")

        if relays then
            refreshGateProfiles()
            local function trackRelay(obj)
                if not obj:IsA("BasePart") then return end
                if obj:GetAttribute("FluxRelayIndex") ~= nil then
                    makeGate(obj)
                else
                    connect(obj:GetAttributeChangedSignal("FluxRelayIndex"), function()
                        if obj.Parent == relays then makeGate(obj) end
                    end)
                end
            end
            for _, obj in ipairs(relays:GetChildren()) do trackRelay(obj) end
            connect(relays.ChildAdded, trackRelay)
            connect(relays.ChildRemoved, function(obj)
                if gates[obj] then task.defer(install) end
            end)
        end
        connect(generated.ChildAdded, function(obj)
            if obj.Name == "Arena" then task.defer(install) end
        end)
        connect(generated.ChildRemoved, function(obj)
            if obj == arena then task.defer(install) end
        end)
        if arena then
            connect(arena.ChildAdded, function(obj)
                if obj.Name == "Mechanics" then task.defer(install) end
            end)
            connect(arena.ChildRemoved, function(obj)
                if obj == mechanics then task.defer(install) end
            end)
            if mechanics then
                connect(mechanics.ChildAdded, function(obj)
                    if obj.Name == "FluxRelays" then task.defer(install) end
                end)
                connect(mechanics.ChildRemoved, function(obj)
                    if obj == relays then task.defer(install) end
                end)
            end
        end
    end

    install()
end

workspace.ChildAdded:Connect(function(obj)
    if obj.Name == "GeneratedMap" then bind(obj) end
end)
workspace.ChildRemoved:Connect(function(obj)
    if obj == source then bind(workspace:FindFirstChild("GeneratedMap")) end
end)
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    bind(workspace:FindFirstChild("GeneratedMap"))
end)
player:GetAttributeChangedSignal("OptionalVfxPressure"):Connect(function()
    local wasEligible = meshPressure < 1
    meshPressure = tonumber(player:GetAttribute("OptionalVfxPressure")) or 0
    if wasEligible ~= (meshPressure < 1) and next(gates) then
        bind(workspace:FindFirstChild("GeneratedMap"))
    end
end)
bind(workspace:FindFirstChild("GeneratedMap"))

task.spawn(function()
    while folder.Parent do
        if next(gates) == nil then
            -- Almost every player is outside Crossroads most of the time.
            -- No update work or time polling while the mechanic is absent.
            task.wait(0.60)
        else
            local now = os.clock()
            if now >= nextProfileCheck and refreshGateProfiles() then
                bind(workspace:FindFirstChild("GeneratedMap"))
            end
            render(now)
            local tier = quality()
            task.wait(tier == "Low" and 0.28
                or (UserInputService.TouchEnabled and 0.20 or 0.12))
        end
    end
end)
