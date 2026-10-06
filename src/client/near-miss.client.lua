local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local event = remotes:WaitForChild("HazardNearMiss")
local stateEvent = remotes:WaitForChild("RoundState")

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosNearMiss"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 28
gui.Parent = player:WaitForChild("PlayerGui")

local flash = Instance.new("Frame")
flash.Name = "EdgeFlash"
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = UITheme.Colors.Orange
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Visible = false
flash.Parent = gui

local gradient = Instance.new("UIGradient")
gradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.35),
    NumberSequenceKeypoint.new(0.18, 0.92),
    NumberSequenceKeypoint.new(0.82, 0.92),
    NumberSequenceKeypoint.new(1, 0.35),
})
gradient.Rotation = 90
gradient.Parent = flash

local card = Instance.new("Frame")
card.Name = "NearMissCard"
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.34)
card.Size = UDim2.new(0.48, 0, 0, 62)
card.BackgroundColor3 = UITheme.Colors.Panel
card.BackgroundTransparency = 1
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(220, 54)
sizeConstraint.MaxSize = Vector2.new(420, 72)
sizeConstraint.Parent = card

local viewportConnection = nil

local function applyResponsiveLayout()
    if not UserInputService.TouchEnabled then
        card.Position = UDim2.fromScale(0.5, 0.34)
        card.Size = UDim2.new(0.48, 0, 0, 62)
        sizeConstraint.MinSize = Vector2.new(220, 54)
        sizeConstraint.MaxSize = Vector2.new(420, 72)
        return
    end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local profile = UIResponsive.mobileProfile(viewport)

    local y = profile.tinyHeight and 0.56
        or (profile.compactHeight and 0.50 or 0.44)
    card.Position = UDim2.fromScale(0.5, y)
    card.Size = UDim2.new(profile.veryNarrow and 0.84 or 0.70, 0, 0, profile.tinyHeight and 54 or 60)
    sizeConstraint.MinSize = Vector2.new(profile.veryNarrow and 210 or 220, profile.tinyHeight and 50 or 54)
    sizeConstraint.MaxSize = Vector2.new(440, 68)
end

local function bindResponsiveCamera()
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end

    local camera = workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveLayout)
    end
    applyResponsiveLayout()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindResponsiveCamera)
bindResponsiveCamera()

local corner = Instance.new("UICorner")
corner.CornerRadius = UITheme.Corners.Large
corner.Parent = card

local stroke = Instance.new("UIStroke")
stroke.Color = UITheme.Colors.Orange
stroke.Thickness = 1.5
stroke.Transparency = 0.35
stroke.Parent = card

local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(1, -20, 0, 4)
accentLine.Position = UDim2.fromOffset(10, 7)
accentLine.BackgroundColor3 = UITheme.Colors.Orange
accentLine.BorderSizePixel = 0
accentLine.Parent = card
UITheme.addCorner(accentLine, UITheme.Corners.Pill)

local scale = Instance.new("UIScale")
scale.Scale = 0.82
scale.Parent = card

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0.55, 0)
title.Position = UDim2.fromOffset(12, 5)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = CoreLocalization.text(localeId, "NEAR_MISS_TITLE")
title.TextColor3 = UITheme.Colors.Gold
title.TextScaled = true
title.Parent = card

local detail = Instance.new("TextLabel")
detail.Size = UDim2.new(1, -24, 0.30, 0)
detail.Position = UDim2.new(0, 12, 0.62, 0)
detail.BackgroundTransparency = 1
detail.Font = Enum.Font.GothamBold
detail.Text = ""
detail.TextColor3 = UITheme.Colors.Muted
detail.TextScaled = true
detail.Parent = card

local combo = 0
local lastNearMissAt = 0
local token = 0
local finalRushActive = false

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function pulseWorld(color, severity)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return
    end

    local profile = quality()
    local reduced = player:GetAttribute("ReduceMotion") == true
    local strength = math.clamp(tonumber(severity) or 0.5, 0.2, 1)

    local ring = Instance.new("Part")
    ring.Name = "NearMissWorldPulse"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.05, 2.6, 2.6)
    ring.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.65, 0))
        * CFrame.Angles(0, 0, math.rad(90))
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.CastShadow = false
    ring.Material = Enum.Material.Neon
    ring.Color = color
    ring.Transparency = 0.62
    ring.Parent = workspace

    TweenService:Create(
        ring,
        TweenInfo.new(
            reduced and 0.12 or (profile.Name == "Low" and 0.16 or 0.24),
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        {
            Size = Vector3.new(
                0.05,
                4.8 + 4.0 * strength,
                4.8 + 4.0 * strength
            ),
            Transparency = 1,
        }
    ):Play()

    task.delay(0.34, function()
        if ring.Parent then
            ring:Destroy()
        end
    end)

    if profile.Name == "High" and not reduced then
        local light = Instance.new("PointLight")
        light.Name = "NearMissPulseLight"
        light.Color = color
        light.Brightness = 0.65 + 0.75 * strength
        light.Range = 10 + 6 * strength
        light.Shadows = false
        light.Parent = root

        TweenService:Create(
            light,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Brightness = 0}
        ):Play()

        task.delay(0.22, function()
            if light.Parent then
                light:Destroy()
            end
        end)
    end
end

local function readableKind(kind)
    local value = tostring(kind or "HAZARD")
    local hazardId = ({
        Meteor = "Meteors",
        Bomb = "Bombs",
    })[value]

    if hazardId then
        return CoreLocalization.hazardTitle(localeId, {hazardId}, value)
    end

    value = value:gsub("([a-z])([A-Z])", "%1 %2")
    return string.upper(value)
end

local function show(payload)
    local now = os.clock()
    if now - lastNearMissAt <= 5 then
        combo += 1
    else
        combo = 1
    end
    lastNearMissAt = now

    token += 1
    local current = token

    local distance = tonumber(payload.distance)
    local radius = tonumber(payload.radius)
    local dangerRatio = nil
    if distance and radius and radius > 0 then
        dangerRatio = math.clamp(distance / radius, 0, 2)
    end

    local accent = UITheme.disasterAccent(payload.kind, UITheme.Colors.Orange)
    if payload.kind == "Meteor" then
        accent = UITheme.DisasterAccents.Meteors
    elseif payload.kind == "Bomb" then
        accent = UITheme.DisasterAccents.Bombs
    end

    title.Text = combo >= 2
        and CoreLocalization.text(localeId, "NEAR_MISS_COMBO", combo)
        or CoreLocalization.text(localeId, "NEAR_MISS_TITLE")
    title.TextColor3 = accent:Lerp(UITheme.Colors.Text, 0.18)
    stroke.Color = accent
    accentLine.BackgroundColor3 = accent
    flash.BackgroundColor3 = accent
    detail.Text = readableKind(payload.kind)
    local severity = 0.55
    if dangerRatio then
        detail.Text ..= "  •  " .. CoreLocalization.text(
            localeId,
            "NEAR_MISS_EDGE",
            dangerRatio
        )
        severity = math.clamp(1.35 - dangerRatio, 0.25, 1)
    end

    pulseWorld(accent, severity)

    if finalRushActive then
        return
    end

    card.Visible = true
    card.BackgroundTransparency = 1
    scale.Scale = 0.82
    flash.Visible = true
    flash.BackgroundTransparency = 0.88

    TweenService:Create(
        card,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.08}
    ):Play()
    TweenService:Create(
        scale,
        TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()
    TweenService:Create(
        flash,
        TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1}
    ):Play()

    task.delay(0.85, function()
        if current ~= token then
            return
        end

        TweenService:Create(
            card,
            TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}
        ):Play()
        TweenService:Create(
            scale,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Scale = 0.90}
        ):Play()

        task.wait(0.21)
        if current == token then
            card.Visible = false
            flash.Visible = false
        end
    end)
end

event.OnClientEvent:Connect(show)

stateEvent.OnClientEvent:Connect(function(state)
    local nextFinalRush = state.phase == "round" and state.finalRush == true
    if nextFinalRush ~= finalRushActive then
        finalRushActive = nextFinalRush
        if finalRushActive then
            token += 1
            card.Visible = false
            flash.Visible = false
        end
    end
end)
