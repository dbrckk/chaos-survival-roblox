local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local UITheme = require(ReplicatedStorage.Shared.UITheme)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "HazardRouteReadabilityLocal"
folder.Parent = workspace

local cueGui = Instance.new("ScreenGui")
cueGui.Name = "HazardReadabilityCue"
cueGui.ResetOnSpawn = false
cueGui.IgnoreGuiInset = true
cueGui.DisplayOrder = 19
cueGui.Parent = player:WaitForChild("PlayerGui")

local cue = Instance.new("Frame")
cue.Name = "NearestHazardCue"
cue.AnchorPoint = Vector2.new(0.5, 0)
cue.Position = UDim2.fromScale(0.5, 0.20)
cue.Size = UDim2.fromOffset(230, 42)
cue.BackgroundColor3 = UITheme.Colors.Panel
cue.BackgroundTransparency = 0.05
cue.BorderSizePixel = 0
cue.Visible = false
cue.Parent = cueGui
UITheme.addCorner(cue, UITheme.Corners.Pill)
local cueStroke = UITheme.addStroke(cue, UITheme.Colors.Red, 2, 0.12)

local cueBadge = Instance.new("TextLabel")
cueBadge.Size = UDim2.fromOffset(38, 34)
cueBadge.Position = UDim2.fromOffset(4, 4)
cueBadge.BackgroundColor3 = UITheme.Colors.Red
cueBadge.BackgroundTransparency = 0.02
cueBadge.BorderSizePixel = 0
cueBadge.Font = Enum.Font.GothamBlack
cueBadge.TextColor3 = UITheme.Colors.Text
cueBadge.TextScaled = true
cueBadge.Text = "!"
cueBadge.Parent = cue
UITheme.addCorner(cueBadge, UITheme.Corners.Pill)
UITheme.addTextConstraint(cueBadge, 15, 23)

local cueText = Instance.new("TextLabel")
cueText.Position = UDim2.fromOffset(48, 4)
cueText.Size = UDim2.new(1, -54, 1, -8)
cueText.BackgroundTransparency = 1
cueText.Font = Enum.Font.GothamBlack
cueText.TextColor3 = UITheme.Colors.Text
cueText.TextScaled = true
cueText.TextXAlignment = Enum.TextXAlignment.Left
cueText.Text = "MOVE OUT"
cueText.Parent = cue
UITheme.addTextConstraint(cueText, 14, 21)

local currentPhase = "waiting"
local finalRush = false
local warningStates = {}
local updateClock = 0

local SUPPORTED = {
    Meteor = true,
    Bomb = true,
}

local WARNING_NAMES = {
    MeteorWarning = true,
    BombWarning = true,
}

local KIND_COLORS = {
    Meteor = Color3.fromRGB(255, 175, 70),
    Bomb = Color3.fromRGB(255, 75, 75),
}

local KIND_LABELS = {
    Meteor = "METEOR  •  MOVE OUT",
    Bomb = "BOMB  •  MOVE OUT",
}

local KIND_BADGES = {
    Meteor = "M",
    Bomb = "B",
}

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function rootPart()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end
    return nil
end

local function destroyState(warning)
    local state = warningStates[warning]
    if not state then
        return
    end
    warningStates[warning] = nil
    for _, instance in ipairs(state.instances) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
end

local function makeArrowPart(name, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = 1
    part.Size = Vector3.new(1.5, 0.06, 0.18)
    part.Parent = folder
    return part
end

local function createState(warning, kind)
    if warningStates[warning] or not warning:IsA("BasePart") then
        return
    end

    local color = KIND_COLORS[kind] or warning.Color
    local left = makeArrowPart("HazardEscapeL_" .. kind, color)
    local right = makeArrowPart("HazardEscapeR_" .. kind, color)

    warningStates[warning] = {
        kind = kind,
        instances = {left, right},
        left = left,
        right = right,
    }
end

local function maybeBind(instance)
    if not instance:IsA("BasePart") or not WARNING_NAMES[instance.Name] then
        return
    end

    local kind = instance:GetAttribute("WarningKind")
    if type(kind) == "string" and SUPPORTED[kind] then
        createState(instance, kind)
        return
    end

    instance:GetAttributeChangedSignal("WarningKind"):Connect(function()
        local nextKind = instance:GetAttribute("WarningKind")
        if type(nextKind) == "string" and SUPPORTED[nextKind] then
            createState(instance, nextKind)
        end
    end)
end

local function hideState(state)
    for _, part in ipairs(state.instances) do
        if part and part.Parent then
            part.Transparency = 1
        end
    end
end

local function updateState(warning, state, root, tier, now)
    if not warning.Parent or not root then
        hideState(state)
        return math.huge
    end

    local startSize = tonumber(warning:GetAttribute("WarningStartSize")) or math.max(warning.Size.X, warning.Size.Z)
    local endSize = tonumber(warning:GetAttribute("WarningEndSize")) or startSize
    local duration = math.max(0.05, tonumber(warning:GetAttribute("WarningDuration")) or 0.5)
    local startedAt = tonumber(warning:GetAttribute("WarningStartedAt")) or workspace:GetServerTimeNow()
    local alpha = math.clamp((workspace:GetServerTimeNow() - startedAt) / duration, 0, 1)
    local dangerRadius = math.max(1, (startSize + (endSize - startSize) * alpha) * 0.5)

    local playerPosition = root.Position
    local delta = Vector3.new(
        playerPosition.X - warning.Position.X,
        0,
        playerPosition.Z - warning.Position.Z
    )
    local distance = delta.Magnitude
    local proximity = dangerRadius + (tier.Name == "High" and 7 or 5)

    if distance > proximity or distance < 0.15 then
        hideState(state)
        return distance - dangerRadius
    end

    local direction = delta.Unit
    local lateral = Vector3.new(direction.Z, 0, -direction.X)
    local origin = playerPosition + Vector3.new(0, -2.65, 0) + direction * 3.1
    local yaw = math.atan2(-direction.X, -direction.Z)
    local pulse = (math.sin(now * 7.5) + 1) * 0.5
    local transparency = (tier.Name == "Low" and 0.42 or 0.28) + pulse * 0.20
    if finalRush then
        transparency += 0.10
    end

    local isBomb = state.kind == "Bomb"
    local spread = isBomb
        and (tier.Name == "Low" and 0.52 or 0.70)
        or (tier.Name == "Low" and 0.42 or 0.58)
    local arrowAngle = isBomb and 56 or 38
    state.left.CFrame = CFrame.new(origin - lateral * spread)
        * CFrame.Angles(0, yaw + math.rad(arrowAngle), 0)
    state.right.CFrame = CFrame.new(origin + lateral * spread)
        * CFrame.Angles(0, yaw - math.rad(arrowAngle), 0)
    state.left.Transparency = math.clamp(transparency, 0, 0.9)
    state.right.Transparency = math.clamp(transparency, 0, 0.9)

    local length = isBomb
        and (tier.Name == "High" and 1.75 or 1.45)
        or (tier.Name == "High" and 2.1 or 1.7)
    local width = isBomb and 0.28 or 0.18
    state.left.Size = Vector3.new(length, 0.06, width)
    state.right.Size = Vector3.new(length, 0.06, width)

    return distance - dangerRadius
end

workspace.ChildAdded:Connect(maybeBind)
workspace.ChildRemoved:Connect(function(instance)
    if warningStates[instance] then
        destroyState(instance)
    end
end)

for _, child in ipairs(workspace:GetChildren()) do
    maybeBind(child)
end

stateEvent.OnClientEvent:Connect(function(state)
    currentPhase = tostring(state.phase or "waiting")
    finalRush = state.finalRush == true

    if currentPhase ~= "round" then
        cue.Visible = false
        for _, warningState in pairs(warningStates) do
            hideState(warningState)
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if currentPhase ~= "round"
        or player:GetAttribute("RoundParticipant") ~= true
        or player:GetAttribute("RoundEliminated") == true
        or next(warningStates) == nil
    then
        cue.Visible = false
        return
    end

    updateClock += dt
    local tier = quality()
    local cadence = tier.Name == "Low" and 0.12 or 0.075
    if updateClock < cadence then
        return
    end
    updateClock = 0

    local root = rootPart()
    if not root then
        return
    end

    local now = os.clock()
    local nearestWarning = nil
    local nearestState = nil
    local nearestClearance = math.huge

    for warning, state in pairs(warningStates) do
        if warning.Parent then
            local clearance = updateState(warning, state, root, tier, now)
            if clearance < nearestClearance then
                nearestClearance = clearance
                nearestWarning = warning
                nearestState = state
            end
        else
            destroyState(warning)
        end
    end

    if finalRush or tier.Name == "Low" then
        for warning, state in pairs(warningStates) do
            if warning ~= nearestWarning then
                hideState(state)
            end
        end
    end

    local showCue = nearestState ~= nil and nearestClearance <= 5
    cue.Visible = showCue
    if showCue then
        local kind = nearestState.kind
        local color = KIND_COLORS[kind] or UITheme.Colors.Red
        cueStroke.Color = color
        cueBadge.BackgroundColor3 = color
        cueBadge.Text = KIND_BADGES[kind] or "!"
        cueText.Text = KIND_LABELS[kind] or "DANGER  •  MOVE OUT"
    end
end)
