local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "SpeedFeel"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 18
gui.Parent = player:WaitForChild("PlayerGui")

local streaks = {}

local function makeStreak(name, position, size, rotation)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = position
    frame.Size = size
    frame.Rotation = rotation
    frame.BackgroundColor3 = Color3.fromRGB(195, 230, 255)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame

    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.28, 0.42),
        NumberSequenceKeypoint.new(0.72, 0.42),
        NumberSequenceKeypoint.new(1, 1),
    })
    gradient.Parent = frame

    streaks[#streaks + 1] = frame
end

makeStreak("LeftUpper", UDim2.fromScale(0.08, 0.26), UDim2.fromScale(0.15, 0.006), -18)
makeStreak("LeftMid", UDim2.fromScale(0.06, 0.44), UDim2.fromScale(0.18, 0.006), -8)
makeStreak("LeftLow", UDim2.fromScale(0.08, 0.66), UDim2.fromScale(0.15, 0.006), 18)
makeStreak("LeftBottom", UDim2.fromScale(0.12, 0.80), UDim2.fromScale(0.12, 0.005), 28)

makeStreak("RightUpper", UDim2.fromScale(0.92, 0.26), UDim2.fromScale(0.15, 0.006), 18)
makeStreak("RightMid", UDim2.fromScale(0.94, 0.44), UDim2.fromScale(0.18, 0.006), 8)
makeStreak("RightLow", UDim2.fromScale(0.92, 0.66), UDim2.fromScale(0.15, 0.006), -18)
makeStreak("RightBottom", UDim2.fromScale(0.88, 0.80), UDim2.fromScale(0.12, 0.005), -28)

local function qualityScale()
    local profile = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local scale = profile.Name == "Low" and 0.35 or (profile.Name == "Medium" and 0.68 or 1)
    if player:GetAttribute("ReduceMotion") == true then
        scale *= 0.16
    end
    return scale
end

local phaseOffset = 0
local anyVisible = false

local function hideStreaks()
    if not anyVisible then
        return
    end

    anyVisible = false
    for _, streak in ipairs(streaks) do
        streak.Visible = false
        streak.BackgroundTransparency = 1
    end
end

task.spawn(function()
    while true do
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local active = player:GetAttribute("RoundParticipant") == true
            and player:GetAttribute("RoundEliminated") ~= true
            and root ~= nil

        if not active or not root then
            hideStreaks()
            task.wait(0.40)
            continue
        end

        local velocity = root.AssemblyLinearVelocity
        local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
        local intensity = math.clamp((speed - 19) / 17, 0, 1) * qualityScale()

        if intensity <= 0.035 then
            hideStreaks()
            task.wait(0.12)
            continue
        end

        anyVisible = true
        phaseOffset = (phaseOffset + 1) % 6

        for index, streak in ipairs(streaks) do
            local localIntensity = intensity
                * (0.72 + (((index + phaseOffset) % 3) * 0.11))
            streak.Visible = localIntensity > 0.035
            if streak.Visible then
                streak.BackgroundTransparency = math.clamp(
                    0.94 - localIntensity * 0.55,
                    0.38,
                    0.94
                )
                streak.Position = UDim2.new(
                    streak.Position.X.Scale,
                    ((index + phaseOffset) % 2 == 0) and 2 or -2,
                    streak.Position.Y.Scale,
                    0
                )
            else
                streak.BackgroundTransparency = 1
            end
        end

        task.wait(0.08)
    end
end)
