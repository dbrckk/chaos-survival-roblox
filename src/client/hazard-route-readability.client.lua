local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "HazardRouteReadabilityLocal"
folder.Parent = workspace

local currentPhase = "waiting"
local finalRush = false
local warningStates = {}
local updateClock = 0

local SUPPORTED = {
    Meteor = true,
    Bomb = true,
    Freeze = true,
}

local KIND_COLORS = {
    Meteor = Color3.fromRGB(255, 175, 70),
    Bomb = Color3.fromRGB(255, 75, 75),
    Freeze = Color3.fromRGB(110, 205, 255),
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
    if not instance:IsA("BasePart") then
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

    local spread = tier.Name == "Low" and 0.42 or 0.58
    state.left.CFrame = CFrame.new(origin - lateral * spread)
        * CFrame.Angles(0, yaw + math.rad(38), 0)
    state.right.CFrame = CFrame.new(origin + lateral * spread)
        * CFrame.Angles(0, yaw - math.rad(38), 0)
    state.left.Transparency = math.clamp(transparency, 0, 0.9)
    state.right.Transparency = math.clamp(transparency, 0, 0.9)

    local length = tier.Name == "High" and 2.1 or 1.7
    state.left.Size = Vector3.new(length, 0.06, 0.18)
    state.right.Size = Vector3.new(length, 0.06, 0.18)

    return distance - dangerRadius
end

workspace.DescendantAdded:Connect(maybeBind)
workspace.DescendantRemoving:Connect(function(instance)
    if warningStates[instance] then
        destroyState(instance)
    end
end)

for _, descendant in ipairs(workspace:GetDescendants()) do
    maybeBind(descendant)
end

stateEvent.OnClientEvent:Connect(function(state)
    currentPhase = tostring(state.phase or "waiting")
    finalRush = state.finalRush == true

    if currentPhase ~= "round" then
        for _, warningState in pairs(warningStates) do
            hideState(warningState)
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if currentPhase ~= "round" or next(warningStates) == nil then
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
    local nearestClearance = math.huge

    for warning, state in pairs(warningStates) do
        if warning.Parent then
            local clearance = updateState(warning, state, root, tier, now)
            if clearance < nearestClearance then
                nearestClearance = clearance
                nearestWarning = warning
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
end)
