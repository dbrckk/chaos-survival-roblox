-- PHASE DASH: one-tap/touch movement ability with a client-only visual signature.
-- Server validates all requests; no client-supplied direction, power or cooldown.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local PhaseDashRules = require(ReplicatedStorage.Shared.PhaseDashRules)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("RoundState")
local dashEvent = remotes:WaitForChild("PhaseDash")
local phase = "waiting"
local nextSendAt = -math.huge
local otherConnections = {}

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosPhaseDash"
gui.ResetOnSpawn = false
gui.DisplayOrder = 32
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Name = "PhaseDash"
button.AnchorPoint = Vector2.new(1, 1)
button.Position = UDim2.new(1, -18, 1, -208)
button.Size = UDim2.fromOffset(106, 57)
button.Font = Enum.Font.GothamBlack
button.TextScaled = true
button.Text = "Q  •  DASH"
button.BackgroundColor3 = Color3.fromRGB(19, 45, 61)
button.TextColor3 = Color3.fromRGB(117, 251, 233)
button.AutoButtonColor = false
button.BorderSizePixel = 0
button.Visible = false
button.Parent = gui
UITheme.addCorner(button, UITheme.Corners.Medium)
UITheme.addStroke(button, Color3.fromRGB(97, 226, 239), 1.7, 0.15)
UITheme.addPressFeedback(button, 0.94)
UITheme.addTextConstraint(button, 12, 20)

local timerRail = Instance.new("Frame")
timerRail.Name = "ChargeRail"
timerRail.Size = UDim2.new(1, -14, 0, 4)
timerRail.Position = UDim2.new(0, 7, 1, -7)
timerRail.BackgroundColor3 = Color3.fromRGB(12, 19, 38)
timerRail.BorderSizePixel = 0
timerRail.Parent = button
UITheme.addCorner(timerRail, UITheme.Corners.Pill)

local charge = Instance.new("Frame")
charge.Name = "Charge"
charge.Size = UDim2.fromScale(1, 1)
charge.BackgroundColor3 = Color3.fromRGB(91, 245, 222)
charge.BorderSizePixel = 0
charge.Parent = timerRail
UITheme.addCorner(charge, UITheme.Corners.Pill)

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
end

-- An actual hollow ring of short bevel-like facets, never a solid
-- neon cylinder. Each facet is noncolliding, and Tween/Debris own its
-- complete lifetime. Budget: High 10 facets/ring, Medium 7, Low 5.
local function cosmeticRing(position, color, growth, age)
    local tier = quality()
    local count = tier == "High" and 10 or (tier == "Medium" and 7 or 5)
    local fromRadius = 1.45
    local toRadius = growth * 0.5
    for index = 1, count do
        local angle = (index - 1) * 2 * math.pi / count
        local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
        local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local chord = 2 * fromRadius * math.sin(math.pi / count) * 0.92
        local facet = Instance.new("Part")
        facet.Name = "PhaseDashRingFacet"
        facet.Size = Vector3.new(0.17, 0.09, chord)
        facet.CFrame = CFrame.lookAt(position + radial * fromRadius,
            position + radial * fromRadius + tangent)
        facet.Material = Enum.Material.Neon
        facet.Color = color
        facet.Transparency = 0.30
        facet.Anchored = true
        facet.CastShadow = false
        facet.CanCollide = false
        facet.CanTouch = false
        facet.CanQuery = false
        facet.Parent = workspace
        TweenService:Create(facet,
            TweenInfo.new(age, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
            {
                Size = Vector3.new(0.12, 0.06,
                    2 * toRadius * math.sin(math.pi / count) * 0.96),
                CFrame = CFrame.lookAt(position + radial * toRadius,
                    position + radial * toRadius + tangent),
                Transparency = 1,
            }
        ):Play()
        Debris:AddItem(facet, age + 0.12)
    end
end

local function dashTrail(root, secondary)
    local a = Instance.new("Attachment")
    a.Name = "PhaseDashTrailLeft"
    a.Position = Vector3.new(-0.70, -1.1, 0)
    a.Parent = root
    local b = Instance.new("Attachment")
    b.Name = "PhaseDashTrailRight"
    b.Position = Vector3.new(0.70, -1.1, 0)
    b.Parent = root

    local trail = Instance.new("Trail")
    trail.Name = "PhaseDashRibbon"
    trail.Attachment0 = a
    trail.Attachment1 = b
    trail.Lifetime = 0.22
    trail.MinLength = 0.10
    trail.FaceCamera = true
    trail.LightEmission = 1
    trail.Color = ColorSequence.new(
        secondary and Color3.fromRGB(189, 106, 255) or Color3.fromRGB(91, 245, 222),
        Color3.fromRGB(61, 130, 255)
    )
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.98),
        NumberSequenceKeypoint.new(1, 0),
    })
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.16),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.Parent = root
    task.delay(0.24, function()
        if trail.Parent then
            trail.Enabled = false
        end
    end)
    Debris:AddItem(trail, 0.50)
    Debris:AddItem(a, 0.50)
    Debris:AddItem(b, 0.50)
end

local function playDashEffect(character)
    if not character or not character.Parent then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then return end
    local camera = workspace.CurrentCamera
    local viewer = camera and camera.CFrame.Position
    if viewer and (root.Position - viewer).Magnitude > 110 then return end
    local reduced = player:GetAttribute("ReduceMotion") == true
    local tier = quality()
    local position = root.Position - Vector3.new(0, 2.45, 0)
    cosmeticRing(position, Color3.fromRGB(85, 233, 235), reduced and 4.4 or 9.5, reduced and 0.16 or 0.42)
    if not reduced and tier == "High" then
        cosmeticRing(position + Vector3.new(0, 0.08, 0),
            Color3.fromRGB(178, 101, 253), 6.7, 0.34)
    end
    if not reduced and tier ~= "Low" then
        dashTrail(root, tier == "High")
    end
    if character == player.Character and player:GetAttribute("AudioMuted") ~= true then
        local sound = Instance.new("Sound")
        sound.Name = "PhaseDashWhoosh"
        sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
        sound.PlaybackSpeed = 0.73
        sound.Volume = 0.16
        sound.RollOffMaxDistance = 40
        sound.SoundGroup = SoundService:FindFirstChild("ChaosSFX")
        sound.Parent = root
        sound:Play()
        Debris:AddItem(sound, 2)
    end
end

local function unbindPerson(other)
    local connections = otherConnections[other]
    if connections then
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
    end
    otherConnections[other] = nil
end

local function observeCharacter(other, character)
    unbindPerson(other)
    local connection = character:GetAttributeChangedSignal("PhaseDashPulse"):Connect(function()
        if other.Character == character then
            playDashEffect(character)
        end
    end)
    otherConnections[other] = {connection}
end

local playerConnections = {}
local function observePlayer(other)
    table.insert(playerConnections, other.CharacterAdded:Connect(function(character)
        observeCharacter(other, character)
    end))
    if other.Character then observeCharacter(other, other.Character) end
end
for _, other in ipairs(Players:GetPlayers()) do observePlayer(other) end
Players.PlayerAdded:Connect(observePlayer)
Players.PlayerRemoving:Connect(unbindPerson)

local function canUse()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return phase == "round"
        and player:GetAttribute("RoundParticipant") == true
        and player:GetAttribute("RoundEliminated") ~= true
        and humanoid ~= nil and humanoid.Health > 0
end

local function remaining()
    return math.max(0, (tonumber(player:GetAttribute("PhaseDashReadyAt")) or 0)
        - workspace:GetServerTimeNow())
end

local function requestDash()
    if not canUse() or remaining() > 0 or os.clock() < nextSendAt then
        return
    end
    -- Local throttle only helps UI; authoritative server cooldown is mandatory.
    nextSendAt = os.clock() + 0.4
    dashEvent:FireServer()
end
button.Activated:Connect(requestDash)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.Q then requestDash() end
end)
stateEvent.OnClientEvent:Connect(function(state)
    phase = type(state) == "table" and tostring(state.phase or "waiting") or "waiting"
end)

task.spawn(function()
    while gui.Parent do
        local active = canUse()
        button.Visible = active
        if active then
            local remainingSeconds = remaining()
            button.Size = UserInputService.TouchEnabled
                and UDim2.fromOffset(91, 61) or UDim2.fromOffset(106, 57)
            button.Position = UserInputService.TouchEnabled
                and UDim2.new(1, -15, 1, -215)
                or UDim2.new(1, -18, 1, -165)
            if remainingSeconds > 0 then
                button.Text = string.format("%.1fs", remainingSeconds)
                button.TextColor3 = Color3.fromRGB(155, 177, 194)
                charge.Size = UDim2.fromScale(
                    1 - math.clamp(remainingSeconds / PhaseDashRules.Cooldown, 0, 1), 1
                )
            else
                button.Text = UserInputService.TouchEnabled and "DASH" or "Q • DASH"
                button.TextColor3 = Color3.fromRGB(117, 251, 233)
                charge.Size = UDim2.fromScale(1, 1)
            end
        end
        task.wait(0.12)
    end
end)
