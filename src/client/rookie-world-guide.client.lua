local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local TweenService = game:GetService("TweenService")

local FirstTimeExperience = require(ReplicatedStorage.Shared.FirstTimeExperience)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local currentState = {
    phase = "waiting",
    voteOptions = nil,
}

local markerFolder = Instance.new("Folder")
markerFolder.Name = "RookieWorldGuideLocal"
markerFolder.Parent = workspace

local currentTarget = nil
local highlight = nil
local billboard = nil
local worldAssets = {}

local function clearMarker()
    if highlight then
        highlight:Destroy()
        highlight = nil
    end
    if billboard then
        billboard:Destroy()
        billboard = nil
    end
    for _, instance in ipairs(worldAssets) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
    table.clear(worldAssets)
    currentTarget = nil
end

local function characterRoot()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return root and root:IsA("BasePart") and root or nil
end

local function nearestPart(parts)
    local root = characterRoot()
    if not root then
        return nil
    end

    local nearest = nil
    local nearestDistance = math.huge
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            local distance = (part.Position - root.Position).Magnitude
            if distance < nearestDistance then
                nearest = part
                nearestDistance = distance
            end
        end
    end
    return nearest
end

local function practicePads()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    local activities = lobby and lobby:FindFirstChild("Activities")
    if not activities then
        return {}
    end

    local result = {}
    for _, child in ipairs(activities:GetChildren()) do
        if child:IsA("BasePart") and child:GetAttribute("LobbyPracticePad") == true then
            table.insert(result, child)
        end
    end
    return result
end

local function arenaRunway()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    local decor = lobby and lobby:FindFirstChild("Decor")
    local runway = decor and decor:FindFirstChild("ArenaRunway")
    return runway and runway:IsA("BasePart") and runway or nil
end

local function arenaPads()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local mechanics = arena and arena:FindFirstChild("Mechanics")
    if not mechanics then
        return {}
    end

    local result = {}
    for _, child in ipairs(mechanics:GetChildren()) do
        if child:IsA("BasePart") and child:GetAttribute("ArenaMobilityPad") == true then
            table.insert(result, child)
        end
    end
    return result
end

local function addWorldGuideAsset(instance)
    table.insert(worldAssets, instance)
    return instance
end

local function buildWorldBeacon(part, color)
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    if tier.Name == "Low" then
        return
    end

    local reducedMotion = player:GetAttribute("ReduceMotion") == true
    local radius = math.clamp(math.max(part.Size.X, part.Size.Z) + 2.2, 4.8, 11.5)
    local y = part.Position.Y + part.Size.Y * 0.5 + 0.10

    local ring = Instance.new("Part")
    ring.Name = "RookieGuideAnchorRing"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.055, radius, radius)
    ring.CFrame = CFrame.new(part.Position.X, y, part.Position.Z)
        * CFrame.Angles(0, 0, math.rad(90))
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.CastShadow = false
    ring.Material = Enum.Material.Neon
    ring.Color = color
    ring.Transparency = reducedMotion and 0.66 or 0.42
    ring.Parent = markerFolder
    addWorldGuideAsset(ring)

    if not reducedMotion then
        local targetSize = ring.Size
        ring.Size = Vector3.new(0.055, radius * 0.56, radius * 0.56)
        TweenService:Create(
            ring,
            TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {
                Size = targetSize,
                Transparency = 0.64,
            }
        ):Play()
    end

    local beacon = Instance.new("Part")
    beacon.Name = "RookieGuideBeacon"
    beacon.Size = Vector3.new(
        tier.Name == "High" and 0.22 or 0.16,
        tier.Name == "High" and 4.8 or 3.6,
        tier.Name == "High" and 0.22 or 0.16
    )
    beacon.CFrame = CFrame.new(
        part.Position.X,
        y + beacon.Size.Y * 0.5,
        part.Position.Z
    )
    beacon.Anchored = true
    beacon.CanCollide = false
    beacon.CanTouch = false
    beacon.CanQuery = false
    beacon.CastShadow = false
    beacon.Material = Enum.Material.Glass
    beacon.Color = VisualTheme.World.MetalLight:Lerp(color, 0.38)
    beacon.Transparency = tier.Name == "High" and 0.42 or 0.58
    beacon.Parent = markerFolder
    addWorldGuideAsset(beacon)

    if tier.Name == "High" then
        local cap = Instance.new("Part")
        cap.Name = "RookieGuideBeaconCap"
        cap.Shape = Enum.PartType.Ball
        cap.Size = Vector3.new(0.62, 0.62, 0.62)
        cap.CFrame = CFrame.new(
            part.Position.X,
            y + beacon.Size.Y + 0.24,
            part.Position.Z
        )
        cap.Anchored = true
        cap.CanCollide = false
        cap.CanTouch = false
        cap.CanQuery = false
        cap.CastShadow = false
        cap.Material = Enum.Material.Neon
        cap.Color = color:Lerp(Color3.new(1, 1, 1), 0.12)
        cap.Transparency = reducedMotion and 0.50 or 0.28
        cap.Parent = markerFolder
        addWorldGuideAsset(cap)
    end
end

local function mark(part, text, color)
    if currentTarget == part and highlight and billboard then
        return
    end

    clearMarker()
    if not part or not part.Parent then
        return
    end

    currentTarget = part

    highlight = Instance.new("Highlight")
    highlight.Name = "RookieGuideHighlight"
    highlight.Adornee = part
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = color
    highlight.FillTransparency = 0.76
    highlight.OutlineColor = color:Lerp(Color3.new(1, 1, 1), 0.35)
    highlight.OutlineTransparency = 0.05
    highlight.Parent = markerFolder

    buildWorldBeacon(part, color)

    billboard = Instance.new("BillboardGui")
    billboard.Name = "RookieGuideLabel"
    billboard.Adornee = part
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(178, 52)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.15, 0)
    billboard.MaxDistance = 76
    billboard.Parent = player:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromScale(1, 1)
    panel.BackgroundColor3 = Color3.fromRGB(10, 16, 27)
    panel.BackgroundTransparency = 0.10
    panel.BorderSizePixel = 0
    panel.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1.2
    stroke.Transparency = 0.26
    stroke.Parent = panel

    local rail = Instance.new("Frame")
    rail.Name = "GuideAccentRail"
    rail.Position = UDim2.fromScale(0.07, 0.14)
    rail.Size = UDim2.fromScale(0.86, 0.08)
    rail.BackgroundColor3 = color
    rail.BorderSizePixel = 0
    rail.Parent = panel

    local railCorner = Instance.new("UICorner")
    railCorner.CornerRadius = UDim.new(1, 0)
    railCorner.Parent = rail

    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromScale(0.07, 0.28)
    label.Size = UDim2.fromScale(0.86, 0.56)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBlack
    label.Text = text
    label.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.48)
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = panel

    local textConstraint = Instance.new("UITextSizeConstraint")
    textConstraint.MinTextSize = 11
    textConstraint.MaxTextSize = 18
    textConstraint.Parent = label
end

local function refresh()
    if player:GetAttribute("DataLoaded") ~= true then
        clearMarker()
        return
    end

    local games = math.max(0, math.floor(tonumber(player:GetAttribute("Games")) or 0))
    if not FirstTimeExperience.isFirstRound(games) then
        clearMarker()
        return
    end

    if currentState.phase == "intermission"
        and currentState.voteOptions
    then
        clearMarker()
        return
    end

    if games == 0
        and (tonumber(player:GetAttribute("LobbyPracticeUses")) or 0) <= 0
        and (currentState.phase == "waiting" or currentState.phase == "intermission")
    then
        mark(
            nearestPart(practicePads()),
            CoreLocalization.text(localeId, "PRACTICE_BOOST"),
            Color3.fromRGB(80, 220, 255)
        )
        return
    end

    if games == 0
        and (tonumber(player:GetAttribute("LobbyPracticeUses")) or 0) > 0
        and (currentState.phase == "waiting" or currentState.phase == "intermission")
        and not currentState.voteOptions
    then
        mark(
            arenaRunway(),
            CoreLocalization.text(localeId, "ENTER_ARENA"),
            Color3.fromRGB(95, 215, 255)
        )
        return
    end

    if currentState.phase == "ready" then
        mark(
            nearestPart(arenaPads()),
            CoreLocalization.text(localeId, "ESCAPE_PAD"),
            Color3.fromRGB(120, 225, 255)
        )
        return
    end

    clearMarker()
end

stateEvent.OnClientEvent:Connect(function(state)
    currentState = state or currentState
    refresh()
end)

player:GetAttributeChangedSignal("DataLoaded"):Connect(refresh)
player:GetAttributeChangedSignal("Games"):Connect(refresh)
player:GetAttributeChangedSignal("LobbyPracticeUses"):Connect(refresh)
player:GetAttributeChangedSignal("RoundParticipant"):Connect(refresh)
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    clearMarker()
    refresh()
end)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    clearMarker()
    refresh()
end)

player.CharacterAdded:Connect(function()
    task.delay(0.35, refresh)
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.delay(0.35, refresh)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clearMarker()
    end
end)

task.defer(refresh)
