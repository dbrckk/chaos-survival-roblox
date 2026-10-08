-- Chaos Showtime: procedural, non-colliding lobby dance floor and native avatar emotes.
-- Entirely cosmetic. Local visuals never change movement, health or rewards.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")
local Debris = game:GetService("Debris")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local Showtime = require(ReplicatedStorage.Shared.LobbyShowtimeRules)

local player = Players.LocalPlayer
local french = string.sub(string.lower(LocalizationService.RobloxLocaleId), 1, 2) == "fr"
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local phase = "waiting"
local voteOptions = nil
local open = false
local currentEmote = nil
local boundHumanoid = nil
local motionConnections = {}
local loaded = {}
local viewportConnection = nil
local tiles = {}
local fixedPieces = {}
local dancers = {}
local lights = {}
local beams = {}
local particles = nil
local titleBillboard = nil
local profile = Showtime.profile("Low")
local stageCenter = nil
local stageBase = nil
local refreshUI

local folder = Instance.new("Folder")
folder.Name = "LobbyShowtimeLocal"
folder.Parent = workspace

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosShowtime"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 28
gui.Parent = player:WaitForChild("PlayerGui")

local toggle = Instance.new("TextButton")
toggle.Name = "ShowtimeToggle"
toggle.AnchorPoint = Vector2.new(1, 0)
toggle.Size = UDim2.fromOffset(98, 46)
toggle.BackgroundColor3 = UITheme.Colors.PanelRaised
toggle.TextColor3 = UITheme.Colors.Cyan
toggle.Font = Enum.Font.GothamBlack
toggle.TextScaled = true
toggle.Text = french and "EMOTES" or "EMOTES"
toggle.AutoButtonColor = false
toggle.BorderSizePixel = 0
toggle.Visible = false
toggle.Parent = gui
UITheme.addCorner(toggle, UITheme.Corners.Medium)
UITheme.addStroke(toggle, UITheme.Colors.Cyan, 1.2, 0.30)
UITheme.addPressFeedback(toggle, 0.96)
UITheme.addTextConstraint(toggle, 12, 18)

local panel = Instance.new("Frame")
panel.Name = "ShowtimePanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Size = UDim2.fromOffset(232, 161)
panel.BackgroundColor3 = UITheme.Colors.Panel
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
UITheme.addCorner(panel, UITheme.Corners.Large)
UITheme.addStroke(panel, UITheme.Colors.Violet, 1.4, 0.18)
UITheme.addGradient(panel, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local caption = Instance.new("TextLabel")
caption.Size = UDim2.new(1, -16, 0, 28)
caption.Position = UDim2.fromOffset(8, 5)
caption.BackgroundTransparency = 1
caption.Text = french and "CHAOS SHOWTIME" or "CHAOS SHOWTIME"
caption.TextColor3 = UITheme.Colors.Cyan
caption.Font = Enum.Font.GothamBlack
caption.TextScaled = true
caption.Parent = panel
UITheme.addTextConstraint(caption, 12, 18)

local buttons = {}
for index, id in ipairs(Showtime.Order) do
    local definition = Showtime.Emotes[id]
    local button = Instance.new("TextButton")
    button.Name = "Emote_" .. id
    button.Position = UDim2.fromOffset(9 + ((index - 1) % 2) * 111, 35 + math.floor((index - 1) / 2) * 54)
    button.Size = UDim2.fromOffset(103, 46)
    button.BackgroundColor3 = UITheme.Colors.PanelSoft
    button.Font = Enum.Font.GothamBlack
    button.TextScaled = true
    button.Text = french and definition.LabelFR or definition.LabelEN
    button.TextColor3 = index % 2 == 0 and UITheme.Colors.Violet or UITheme.Colors.Cyan
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Parent = panel
    UITheme.addCorner(button, UITheme.Corners.Medium)
    UITheme.addStroke(button, UITheme.Colors.Border, 1, 0.45)
    UITheme.addPressFeedback(button, 0.94)
    UITheme.addTextConstraint(button, 12, 17)
    buttons[id] = button
end

local function humanoid()
    local character = player.Character
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        return hum
    end
    return nil
end

local function activePhase()
    return Showtime.enabled(phase, voteOptions)
end

local function available()
    local hum = humanoid()
    return hum ~= nil and Showtime.canEmote(phase, voteOptions, hum.Health)
end

local function stopEmote()
    local active = currentEmote
    currentEmote = nil
    if active and active.track then
        active.track:Stop(0.17)
    end
end

local function clearMotionConnections()
    for _, connection in ipairs(motionConnections) do
        connection:Disconnect()
    end
    table.clear(motionConnections)
end

local function clearLoaded()
    stopEmote()
    clearMotionConnections()
    for _, entry in pairs(loaded) do
        entry.track:Destroy()
        entry.animation:Destroy()
    end
    table.clear(loaded)
    boundHumanoid = nil
end

local function bindHumanoid(character)
    clearLoaded()
    local hum = character:FindFirstChildOfClass("Humanoid")
        or character:WaitForChild("Humanoid", 8)
    if not hum or character ~= player.Character then
        return
    end
    boundHumanoid = hum
    if refreshUI then
        refreshUI()
    end

    table.insert(motionConnections, hum.Running:Connect(function(speed)
        if speed > 2 then
            stopEmote()
        end
    end))
    table.insert(motionConnections, hum.StateChanged:Connect(function(_, nextState)
        if nextState == Enum.HumanoidStateType.Jumping
            or nextState == Enum.HumanoidStateType.Freefall
            or nextState == Enum.HumanoidStateType.Swimming
            or nextState == Enum.HumanoidStateType.Climbing
            or nextState == Enum.HumanoidStateType.Dead
        then
            stopEmote()
        end
    end))
    table.insert(motionConnections, hum.Died:Connect(stopEmote))
end

player.CharacterAdded:Connect(function(character)
    task.spawn(bindHumanoid, character)
end)
player.CharacterRemoving:Connect(clearLoaded)
if player.Character then
    task.spawn(bindHumanoid, player.Character)
end

local function personalConfetti()
    if player:GetAttribute("ReduceMotion") == true then
        return
    end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return
    end
    local attachment = Instance.new("Attachment")
    attachment.Name = "ShowtimePersonalBurst"
    attachment.Position = Vector3.new(0, -1.5, 0)
    attachment.Parent = root
    local emitter = Instance.new("ParticleEmitter")
    emitter.Enabled = false
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(0.35, 0.65)
    emitter.Speed = NumberRange.new(3, 5)
    emitter.SpreadAngle = Vector2.new(75, 75)
    emitter.LightEmission = 0.9
    emitter.Color = ColorSequence.new(UITheme.Colors.Cyan, UITheme.Colors.Magenta)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.23),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment
    emitter:Emit(VfxQuality.particleCount(
        VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name, 12, 3
    ))
    Debris:AddItem(attachment, 1.4)
end

local function playEmote(id)
    if not available() then
        return
    end
    if currentEmote and currentEmote.id == id then
        stopEmote()
        return
    end
    local hum = humanoid()
    if not hum or hum.MoveDirection.Magnitude > 0.06 then
        return
    end
    local rigType = hum.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15"
    local definition = Showtime.get(id, rigType)
    local animator = hum:FindFirstChildOfClass("Animator")
    if not definition or not animator then
        return
    end

    stopEmote()
    local entry = loaded[id]
    if not entry then
        local animation = Instance.new("Animation")
        animation.Name = "Showtime_" .. id
        animation.AnimationId = "rbxassetid://" .. tostring(definition.AnimationId)
        local success, track = pcall(function()
            return animator:LoadAnimation(animation)
        end)
        if not success or not track then
            animation:Destroy()
            caption.Text = french and "ANIMATION INDISPONIBLE" or "ANIMATION UNAVAILABLE"
            task.delay(2, function()
                caption.Text = "CHAOS SHOWTIME"
            end)
            return
        end
        track.Priority = Enum.AnimationPriority.Action
        track.Looped = definition.Loop
        entry = {track = track, animation = animation}
        loaded[id] = entry
        track.Stopped:Connect(function()
            if currentEmote and currentEmote.track == track then
                currentEmote = nil
            end
        end)
    end

    local ok = pcall(function()
        entry.track:Play(0.18, 1, 1)
    end)
    if not ok then
        return
    end
    currentEmote = {id = id, track = entry.track}
    personalConfetti()
    open = false
    panel.Visible = false
    if particles and particles.Parent then
        particles:Emit(profile.Bursts)
    end
end

for id, button in pairs(buttons) do
    button.Activated:Connect(function()
        playEmote(id)
    end)
end

refreshUI = function()
    local enabled = available()
    toggle.Visible = enabled
    if not enabled then
        open = false
        stopEmote()
    end
    panel.Visible = enabled and open
end

toggle.Activated:Connect(function()
    open = not open
    refreshUI()
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then
        return
    end
    if input.KeyCode == Enum.KeyCode.G and available() then
        open = not open
        refreshUI()
    end
end)

local function applyLayout()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local touch = UserInputService.TouchEnabled
    local mobile = UIResponsive.mobileProfile(viewport)
    local top = touch and mobile.topHeight or 68
    local rightInset = Showtime.dockRightInset(viewport.X, touch, mobile.veryNarrow)
    toggle.Position = UDim2.new(1, -rightInset, 0, top + 16)
    panel.Position = UDim2.new(1, -rightInset, 0, top + 70)
    local width = math.max(1, viewport.X)
    panel.Size = UDim2.fromOffset(math.min(232, width - 24), 161)
end

local function bindCamera()
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end
    local camera = workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
    end
    applyLayout()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()

local function makePart(name, size, cf, color, material, transparency)
    local obj = Instance.new("Part")
    obj.Name = name
    obj.Size = size
    obj.CFrame = cf
    obj.Color = color
    obj.Material = material or Enum.Material.Metal
    obj.Transparency = transparency or 0
    obj.Anchored = true
    obj.CanCollide = false
    obj.CanTouch = false
    obj.CanQuery = false
    obj.CastShadow = false
    obj.Parent = folder
    return obj
end

local function clearStage()
    folder:ClearAllChildren()
    table.clear(tiles)
    table.clear(fixedPieces)
    table.clear(dancers)
    table.clear(lights)
    table.clear(beams)
    particles = nil
    stageCenter = nil
    stageBase = nil
    titleBillboard = nil
end

local function makeHoloDancer(index, center)
    local offset = index == 1 and -4.8 or 4.8
    local base = center + Vector3.new(offset, 0, 3.1)
    local color = index == 1 and UITheme.Colors.Cyan or UITheme.Colors.Magenta
    local body = makePart("HoloDancerBody" .. index, Vector3.new(1.05, 1.70, 0.65),
        CFrame.new(base + Vector3.new(0, 2.05, 0)), color, Enum.Material.Glass, 0.20)
    local head = makePart("HoloDancerHead" .. index, Vector3.new(0.86, 0.83, 0.82),
        body.CFrame * CFrame.new(0, 1.35, 0), color, Enum.Material.Neon, 0.17)
    local left = makePart("HoloDancerArmL" .. index, Vector3.new(0.33, 1.25, 0.38),
        body.CFrame * CFrame.new(-0.81, 0.25, 0), color, Enum.Material.Glass, 0.18)
    local right = makePart("HoloDancerArmR" .. index, Vector3.new(0.33, 1.25, 0.38),
        body.CFrame * CFrame.new(0.81, 0.25, 0), color, Enum.Material.Glass, 0.18)
    local footL = makePart("HoloDancerLegL" .. index, Vector3.new(0.36, 1.1, 0.40),
        body.CFrame * CFrame.new(-0.30, -1.4, 0), color, Enum.Material.Glass, 0.30)
    local footR = makePart("HoloDancerLegR" .. index, Vector3.new(0.36, 1.1, 0.40),
        body.CFrame * CFrame.new(0.30, -1.4, 0), color, Enum.Material.Glass, 0.30)
    table.insert(dancers, {
        base = base, body = body, head = head, left = left, right = right,
        footL = footL, footR = footR, phase = index * math.pi,
        parts = {body, head, left, right, footL, footR},
    })
end

local function buildStage()
    clearStage()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    local floor = lobby and lobby:FindFirstChild("Floor")
    if not floor or not floor:IsA("BasePart") then
        return
    end

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    profile = Showtime.profile(tier.Name)
    local baseCF = floor.CFrame * CFrame.new(22, floor.Size.Y * 0.5 + 0.24, 19)
    stageCenter = baseCF.Position

    stageBase = makePart("ShowtimeDeck", Vector3.new(13.8, 0.16, 13.8),
        baseCF, UITheme.Colors.Panel, Enum.Material.Metal, 0.09)
    local size = 11.6 / profile.Grid
    for row = 1, profile.Grid do
        for column = 1, profile.Grid do
            local x = (column - (profile.Grid + 1) * 0.5) * size
            local z = (row - (profile.Grid + 1) * 0.5) * size
            local accent = (row + column) % 3 == 0 and UITheme.Colors.Magenta
                or ((row + column) % 2 == 0 and UITheme.Colors.Cyan or UITheme.Colors.Violet)
            local tile = makePart("ShowtimeTile_" .. row .. "_" .. column,
                Vector3.new(size - 0.13, 0.045, size - 0.13),
                baseCF * CFrame.new(x, 0.11, z), accent, Enum.Material.Neon, 0.70)
            table.insert(tiles, {part = tile, color = accent, offset = row * 0.68 + column * 1.13})
        end
    end

    for i = 1, 4 do
        local northSouth = i < 3
        local side = i % 2 == 0 and 1 or -1
        local cf = baseCF * CFrame.new(
            northSouth and side * 6.55 or 0, 0.15,
            northSouth and 0 or side * 6.55
        )
        local edge = makePart("ShowtimeEdge_" .. i,
            northSouth and Vector3.new(0.18, 0.22, 13.1)
                or Vector3.new(13.1, 0.22, 0.18),
            cf, i % 2 == 0 and UITheme.Colors.Cyan or UITheme.Colors.Violet,
            Enum.Material.Neon, 0.21)
        table.insert(fixedPieces, {part = edge, transparency = 0.21})
    end

    for i = 1, 4 do
        local sx = i % 2 == 0 and 1 or -1
        local sz = i <= 2 and 1 or -1
        local crystal = makePart("ShowtimePylon_" .. i, Vector3.new(0.45, 2.1, 0.45),
            baseCF * CFrame.new(sx * 6.3, 1.15, sz * 6.3),
            i % 2 == 0 and UITheme.Colors.Cyan or UITheme.Colors.Magenta,
            Enum.Material.Glass, 0.18)
        table.insert(fixedPieces, {part = crystal, transparency = 0.18})
        if #lights < profile.Lights then
            local light = Instance.new("PointLight")
            light.Name = "ShowtimePulseLight"
            light.Brightness = 0.56
            light.Range = 12
            light.Color = crystal.Color
            light.Shadows = false
            light.Parent = crystal
            table.insert(lights, light)
        end
    end

    -- Thin, sweeping holographic light ribbons. These are not gameplay hazards.
    local beamCount = tier.Name == "High" and 2 or (tier.Name == "Medium" and 1 or 0)
    for i = 1, beamCount do
        local sx = i == 1 and -1 or 1
        local source = makePart("ShowtimeLaserSource" .. i,
            Vector3.new(0.15, 0.15, 0.15),
            baseCF * CFrame.new(sx * 6.1, 3.0, -5.6),
            UITheme.Colors.Cyan, Enum.Material.Glass, 1)
        local target = makePart("ShowtimeLaserTarget" .. i,
            Vector3.new(0.15, 0.15, 0.15),
            baseCF * CFrame.new(0, 1.9, 0),
            UITheme.Colors.Violet, Enum.Material.Glass, 1)
        local from = Instance.new("Attachment")
        from.Parent = source
        local to = Instance.new("Attachment")
        to.Parent = target
        local beam = Instance.new("Beam")
        beam.Name = "ShowtimeLightRibbon" .. i
        beam.Attachment0 = from
        beam.Attachment1 = to
        beam.FaceCamera = true
        beam.Segments = 8
        beam.Width0 = 0.14
        beam.Width1 = 0.035
        beam.Color = ColorSequence.new(
            i == 1 and UITheme.Colors.Cyan or UITheme.Colors.Magenta,
            UITheme.Colors.Violet
        )
        beam.Transparency = NumberSequence.new(0.30)
        beam.LightEmission = 0.85
        beam.Enabled = false
        beam.Parent = source
        table.insert(beams, {target = target, beam = beam, phase = i * math.pi})
    end

    local sign = makePart("ShowtimeMarquee", Vector3.new(0.3, 0.3, 0.3),
        baseCF * CFrame.new(0, 6.6, 5.4), UITheme.Colors.Cyan, Enum.Material.Glass, 1)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ShowtimeTitle"
    billboard.AlwaysOnTop = false
    billboard.MaxDistance = 75
    billboard.Size = UDim2.fromOffset(220, 54)
    billboard.Adornee = sign
    billboard.Parent = sign
    titleBillboard = billboard

    local banner = Instance.new("TextLabel")
    banner.Size = UDim2.fromScale(1, 1)
    banner.BackgroundColor3 = UITheme.Colors.Panel
    banner.BackgroundTransparency = 0.19
    banner.BorderSizePixel = 0
    banner.Font = Enum.Font.GothamBlack
    banner.Text = french and "PISTE DE DANSE" or "CHAOS SHOWTIME"
    banner.TextScaled = true
    banner.TextColor3 = UITheme.Colors.Cyan
    banner.Parent = billboard
    UITheme.addCorner(banner, UITheme.Corners.Medium)
    UITheme.addStroke(banner, UITheme.Colors.Violet, 1.7, 0.13)
    UITheme.addTextConstraint(banner, 12, 23)

    for index = 1, profile.Dancers do
        makeHoloDancer(index, stageCenter)
    end

    if tier.Name ~= "Low" then
        local attachment = Instance.new("Attachment")
        attachment.Name = "ShowtimeMotesOrigin"
        attachment.Parent = stageBase
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "ShowtimeConfetti"
        emitter.Enabled = false
        emitter.Rate = 0
        emitter.Lifetime = NumberRange.new(0.4, 0.85)
        emitter.Speed = NumberRange.new(3, 6)
        emitter.SpreadAngle = Vector2.new(70, 70)
        emitter.LightEmission = 0.9
        emitter.Color = ColorSequence.new(UITheme.Colors.Cyan, UITheme.Colors.Magenta)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.30),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(1, 1),
        })
        emitter.Parent = attachment
        particles = emitter
    end
end

local function peopleOnStage()
    if not stageCenter then
        return 0
    end
    local count = 0
    for _, person in ipairs(Players:GetPlayers()) do
        local character = person.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            local delta = root.Position - stageCenter
            if math.abs(delta.Y) < 8
                and math.abs(delta.X) < 7
                and math.abs(delta.Z) < 7
            then
                count += 1
            end
        end
    end
    return math.min(4, count)
end

local function updateStage(now)
    if not stageBase or not stageBase.Parent then
        return
    end
    local enabled = activePhase()
    local reduced = player:GetAttribute("ReduceMotion") == true
    local crowd = enabled and peopleOnStage() or 0
    stageBase.Transparency = enabled and 0.09 or 1
    if titleBillboard then
        titleBillboard.Enabled = enabled
    end
    for _, entry in ipairs(fixedPieces) do
        entry.part.Transparency = enabled and entry.transparency or 1
    end
    for _, light in ipairs(lights) do
        light.Enabled = enabled and not reduced
        light.Brightness = 0.50 + crowd * 0.10
    end
    for _, ribbon in ipairs(beams) do
        ribbon.beam.Enabled = enabled and not reduced
        if enabled and not reduced and stageCenter then
            ribbon.target.CFrame = CFrame.new(
                stageCenter + Vector3.new(
                    math.cos(now * 0.82 + ribbon.phase) * 4.0,
                    1.75 + math.sin(now * 1.3 + ribbon.phase) * 0.65,
                    math.sin(now * 0.82 + ribbon.phase) * 4.0
                )
            )
        end
    end

    for _, entry in ipairs(tiles) do
        if enabled then
            local beat = reduced and 0.5
                or (0.5 + 0.5 * math.sin(now * 3.4 + entry.offset))
            local intensity = (currentEmote and 0.12 or 0) + crowd * 0.045
            entry.part.Transparency = math.clamp(0.76 - beat * 0.26 - intensity, 0.26, 0.76)
        else
            entry.part.Transparency = 1
        end
    end

    if not enabled then
        for _, dancer in ipairs(dancers) do
            for _, part in ipairs(dancer.parts) do
                part.Transparency = 1
            end
        end
        return
    end

    for _, dancer in ipairs(dancers) do
        local t = reduced and 0 or now
        local shift = t * 2.6 + dancer.phase
        local bob = reduced and 0 or math.sin(shift) * 0.20
        local sway = reduced and 0 or math.sin(shift) * 0.62
        local bodyCF = CFrame.new(dancer.base + Vector3.new(0, 2.05 + bob, 0))
            * CFrame.Angles(0, sway * 0.35, sway * 0.16)
        dancer.body.CFrame = bodyCF
        dancer.head.CFrame = bodyCF * CFrame.new(0, 1.35, 0)
        dancer.left.CFrame = bodyCF * CFrame.new(-0.78, 0.28, 0)
            * CFrame.Angles(0, 0, -0.36 - sway)
        dancer.right.CFrame = bodyCF * CFrame.new(0.78, 0.28, 0)
            * CFrame.Angles(0, 0, 0.36 + sway)
        dancer.footL.CFrame = bodyCF * CFrame.new(-0.3, -1.4, 0)
        dancer.footR.CFrame = bodyCF * CFrame.new(0.3, -1.4, 0)
        for _, part in ipairs(dancer.parts) do
            part.Transparency = 0.28
        end
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    phase = tostring(state.phase or "waiting")
    voteOptions = state.voteOptions
    refreshUI()
    updateStage(os.clock())
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    buildStage()
    updateStage(os.clock())
end)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    updateStage(os.clock())
end)
player.CharacterAdded:Connect(function()
    task.defer(refreshUI)
end)
workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(function()
            buildStage()
            updateStage(os.clock())
        end)
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clearStage()
    end
end)

task.defer(function()
    buildStage()
    refreshUI()
    updateStage(os.clock())
end)

task.spawn(function()
    while true do
        task.wait(activePhase() and profile.Interval or 0.65)
        if activePhase() and stageBase then
            updateStage(os.clock())
        end
    end
end)
