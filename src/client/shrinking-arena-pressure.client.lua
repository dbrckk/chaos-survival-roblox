local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local gui = Instance.new("ScreenGui")
gui.Name = "ShrinkPressure"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 17
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "EdgePressure"
frame.Size = UDim2.fromScale(1, 1)
frame.BackgroundColor3 = Color3.fromRGB(235, 95, 235)
frame.BackgroundTransparency = 1
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui

local gradient = Instance.new("UIGradient")
gradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.22),
    NumberSequenceKeypoint.new(0.12, 0.92),
    NumberSequenceKeypoint.new(0.88, 0.92),
    NumberSequenceKeypoint.new(1, 0.22),
})
gradient.Rotation = 90
gradient.Parent = frame

local active = false
local updateClock = 0
local smoothedPressure = 0

local function qualityScale()
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local scale = tier.Name == "Low" and 0.55 or (tier.Name == "Medium" and 0.78 or 1)
    if player:GetAttribute("ReduceMotion") == true then
        scale *= 0.35
    end
    return scale, tier
end

local function arenaBase()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    return base and base:IsA("BasePart") and base or nil
end

local function rootPart()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return root and root:IsA("BasePart") and root or nil
end

local function edgePressure(base, root)
    local localPosition = base.CFrame:PointToObjectSpace(root.Position)
    local halfX = math.max(0.1, base.Size.X * 0.5)
    local halfZ = math.max(0.1, base.Size.Z * 0.5)
    local remainingX = halfX - math.abs(localPosition.X)
    local remainingZ = halfZ - math.abs(localPosition.Z)
    local nearest = math.min(remainingX, remainingZ)

    if nearest <= 0 then
        return 1
    end

    local warningDistance = math.clamp(math.min(halfX, halfZ) * 0.24, 6, 11)
    return 1 - math.clamp(nearest / warningDistance, 0, 1)
end

stateEvent.OnClientEvent:Connect(function(state)
    active = state
        and state.phase == "round"
        and table.find(state.disasterIds or {}, "ShrinkingArena") ~= nil

    if not active then
        smoothedPressure = 0
        frame.Visible = false
        frame.BackgroundTransparency = 1
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not active then
        return
    end

    local scale, tier = qualityScale()
    updateClock += dt
    local cadence = tier.Name == "Low" and 0.12 or 0.075
    if updateClock < cadence then
        return
    end
    updateClock = 0

    local base = arenaBase()
    local root = rootPart()
    if not base or not root then
        frame.Visible = false
        return
    end

    local pressure = edgePressure(base, root)
    smoothedPressure += (pressure - smoothedPressure) * math.clamp(dt * 12, 0, 1)

    if smoothedPressure < 0.05 then
        frame.Visible = false
        return
    end

    frame.Visible = true
    local pulse = (math.sin(os.clock() * 6.2) + 1) * 0.5
    local alpha = smoothedPressure * scale
    frame.BackgroundTransparency = math.clamp(0.985 - alpha * (0.13 + pulse * 0.05), 0.78, 0.985)
end)
