local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local UITheme = require(ReplicatedStorage.Shared.UITheme)
local PracticeVisualKit = require(script.Parent.LobbyPracticeVisualKit)

local player = Players.LocalPlayer
local tracked = {}

local gui = Instance.new("ScreenGui")
gui.Name = "LobbyPracticeFeedback"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.72)
label.Size = UDim2.fromOffset(250, 44)
label.BackgroundColor3 = UITheme.Colors.Panel
label.BackgroundTransparency = 1
label.BorderSizePixel = 0
label.Font = Enum.Font.GothamBlack
label.Text = "PRACTICE BOOST"
label.TextColor3 = UITheme.Colors.Cyan
label.TextScaled = true
label.TextTransparency = 1
label.Visible = false
label.Parent = gui
UITheme.addCorner(label, UITheme.Corners.Pill)
local labelStroke = UITheme.addStroke(label, UITheme.Colors.Cyan, 1.3, 1)

local scale = Instance.new("UIScale")
scale.Scale = 0.82
scale.Parent = label

local token = 0

local function tier()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function showFeedback(color)
    token += 1
    local current = token

    label.TextColor3 = color
    labelStroke.Color = color
    label.Visible = true
    label.TextTransparency = 1
    label.BackgroundTransparency = 1
    labelStroke.Transparency = 1
    scale.Scale = 0.82

    -- ReduceMotion keeps the success message readable without any pop,
    -- scaling, slide or opacity tween (the only timer hides a static label).
    if player:GetAttribute("ReduceMotion") == true then
        scale.Scale = 1
        label.TextTransparency = 0
        label.BackgroundTransparency = 0.12
        labelStroke.Transparency = 0.24
        task.delay(0.65, function()
            if current == token then label.Visible = false end
        end)
        return
    end

    TweenService:Create(label, TweenInfo.new(0.12), {
        TextTransparency = 0,
        BackgroundTransparency = 0.12,
    }):Play()
    TweenService:Create(labelStroke, TweenInfo.new(0.12), {Transparency = 0.24}):Play()
    TweenService:Create(
        scale,
        TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()

    task.delay(0.65, function()
        if current ~= token then
            return
        end

        TweenService:Create(label, TweenInfo.new(0.16), {
            TextTransparency = 1,
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(labelStroke, TweenInfo.new(0.16), {Transparency = 1}):Play()
        TweenService:Create(scale, TweenInfo.new(0.16), {Scale = 0.92}):Play()

        task.wait(0.18)
        if current == token then
            label.Visible = false
        end
    end)
end

local function remove(pad)
    local bundle = tracked[pad]
    if not bundle then
        return
    end
    tracked[pad] = nil

    PracticeVisualKit.destroy(bundle)
end

local function refreshBundle(pad, bundle)
    local quality = tier()
    local reduced = player:GetAttribute("ReduceMotion") == true
    bundle.emitter.Rate = PracticeVisualKit.rate(quality, reduced)
    bundle.highlight.FillTransparency = quality.Name == "Low" and 1 or 0.90
    bundle.highlight.OutlineTransparency = quality.Name == "Low" and 0.45 or 0.18

    local light = pad:FindFirstChild("PracticePadLight")
    if light and light:IsA("PointLight") then
        light.Enabled = quality.Name ~= "Low"
        light.Brightness = 0.50 + 0.18 * quality.Scale
    end
end

local function attach(pad)
    if tracked[pad]
        or not pad:IsA("BasePart")
        or pad:GetAttribute("LobbyPracticePad") ~= true
    then
        return
    end

    local bundle = PracticeVisualKit.create(pad)
    if not bundle then return end
    tracked[pad] = bundle
    refreshBundle(pad, bundle)
end

local function triggerNearestPractice()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return
    end

    local nearestPad = nil
    local nearestBundle = nil
    local nearestDistance = math.huge

    for pad, bundle in pairs(tracked) do
        if pad and pad.Parent and bundle and bundle.emitter then
            local distance = (root.Position - pad.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPad = pad
                nearestBundle = bundle
            end
        end
    end

    if not nearestPad or not nearestBundle or nearestDistance > 12 then
        return
    end

    showFeedback(nearestPad.Color:Lerp(Color3.new(1, 1, 1), 0.22))
    if player:GetAttribute("ReduceMotion") ~= true then
        nearestBundle.emitter:Emit(
            VfxQuality.particleCount(tier().Name, 16, 4)
        )
    end
end

local function scan(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant:GetAttribute("LobbyPracticePad") == true then
            attach(descendant)
        end
    end
end

workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("BasePart") and descendant:GetAttribute("LobbyPracticePad") == true then
        attach(descendant)
    end
end)

workspace.DescendantRemoving:Connect(function(descendant)
    if tracked[descendant] then
        remove(descendant)
    end
end)

local function refreshAll()
    for pad, bundle in pairs(tracked) do
        if pad.Parent then
            refreshBundle(pad, bundle)
        else
            remove(pad)
        end
    end
end

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(refreshAll)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(refreshAll)

-- Refreshing no longer recreates particle attachments or effects.
-- Existing tracked pads stay stable across graphics/accessibility changes.

scan(workspace)


local lastPracticeUses = math.max(
    0,
    math.floor(tonumber(player:GetAttribute("LobbyPracticeUses")) or 0)
)
player:GetAttributeChangedSignal("LobbyPracticeUses"):Connect(function()
    local nextUses = math.max(
        0,
        math.floor(tonumber(player:GetAttribute("LobbyPracticeUses")) or 0)
    )
    if nextUses > lastPracticeUses then
        triggerNearestPractice()
    end
    lastPracticeUses = nextUses
end)
