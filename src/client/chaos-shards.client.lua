local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChaosShardCollected")

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosShardFeedback"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 24
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Name = "Reward"
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.66)
label.Size = UDim2.fromOffset(260, 54)
label.BackgroundColor3 = Color3.fromRGB(17, 30, 48)
label.BackgroundTransparency = 1
label.BorderSizePixel = 0
label.Font = Enum.Font.GothamBlack
label.Text = ""
label.TextColor3 = Color3.fromRGB(120, 225, 255)
label.TextStrokeTransparency = 0.65
label.TextScaled = true
label.TextTransparency = 1
label.Visible = false
label.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = label

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(126, 107, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.35
stroke.Parent = label

local scale = Instance.new("UIScale")
scale.Scale = 0.78
scale.Parent = label

local token = 0

local function show(reward, total)
    token += 1
    local current = token

    label.Text = "+" .. tostring(reward) .. " COIN  •  CHAOS SHARD " .. tostring(total)
    label.Visible = true
    label.TextTransparency = 1
    label.BackgroundTransparency = 1
    scale.Scale = 0.78

    TweenService:Create(
        label,
        TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0, BackgroundTransparency = 0.12}
    ):Play()
    TweenService:Create(
        scale,
        TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()

    task.delay(1.05, function()
        if current ~= token then
            return
        end

        TweenService:Create(
            label,
            TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {TextTransparency = 1, BackgroundTransparency = 1}
        ):Play()
        TweenService:Create(
            scale,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Scale = 0.9}
        ):Play()

        task.wait(0.23)
        if current == token then
            label.Visible = false
        end
    end)
end

event.OnClientEvent:Connect(function(payload)
    show(tonumber(payload.reward) or 1, tonumber(payload.total) or 1)
end)


local shardVisuals = {}
local pulseClock = 0
local updateClock = 0

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function removeVisual(shardPart)
    local visual = shardVisuals[shardPart]
    if visual then
        shardVisuals[shardPart] = nil
        if visual.Parent then
            visual:Destroy()
        end
    end
end

local function attachVisual(shardPart)
    if not shardPart:IsA("BasePart")
        or shardPart:GetAttribute("ChaosShard") ~= true
        or shardVisuals[shardPart]
    then
        return
    end

    local folder = Instance.new("Folder")
    folder.Name = "LocalShardPolish"
    folder.Parent = shardPart

    local highlight = Instance.new("Highlight")
    highlight.Name = "ShardHighlight"
    highlight.Adornee = shardPart
    highlight.FillColor = Color3.fromRGB(90, 210, 255)
    highlight.FillTransparency = 0.68
    highlight.OutlineColor = Color3.fromRGB(210, 160, 255)
    highlight.OutlineTransparency = 0.18
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = folder

    local ring = Instance.new("SelectionSphere")
    ring.Name = "ShardRing"
    ring.Adornee = shardPart
    ring.Color3 = Color3.fromRGB(130, 225, 255)
    ring.SurfaceColor3 = Color3.fromRGB(145, 105, 255)
    ring.Transparency = 0.72
    ring.SurfaceTransparency = 1
    ring.Parent = folder

    shardVisuals[shardPart] = folder
end

local function scanShards(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant:GetAttribute("ChaosShard") == true then
            attachVisual(descendant)
        end
    end
end

workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("BasePart") and descendant:GetAttribute("ChaosShard") == true then
        attachVisual(descendant)
    end
end)

workspace.DescendantRemoving:Connect(function(descendant)
    if shardVisuals[descendant] then
        removeVisual(descendant)
    end
end)

scanShards(workspace)

RunService.RenderStepped:Connect(function(dt)
    if next(shardVisuals) == nil then
        return
    end

    pulseClock += dt
    updateClock += dt

    local tier = quality()
    if updateClock < math.max(1 / 30, tier.UpdateInterval) then
        return
    end
    updateClock = 0

    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    for shardPart, folder in pairs(shardVisuals) do
        if not shardPart.Parent or not folder.Parent then
            removeVisual(shardPart)
        else
            local distance = rootPart and (rootPart.Position - shardPart.Position).Magnitude or 999
            local closeDistance = 24 * tier.Scale
            local close = distance <= closeDistance
            local pulse = (math.sin(pulseClock * (close and 6.5 or 3.8)) + 1) * 0.5

            local highlight = folder:FindFirstChild("ShardHighlight")
            if highlight and highlight:IsA("Highlight") then
                local detailScale = tier.Scale
                highlight.FillTransparency = math.clamp(
                    (close and 0.42 or 0.66) + pulse * 0.08 + ((1 - detailScale) * 0.12),
                    0,
                    1
                )
                highlight.OutlineTransparency = math.clamp(
                    (close and 0.04 or 0.18) + ((1 - detailScale) * 0.22),
                    0,
                    1
                )
            end

            local ring = folder:FindFirstChild("ShardRing")
            if ring and ring:IsA("SelectionSphere") then
                ring.Transparency = (close and 0.46 or 0.68) + pulse * 0.12
            end
        end
    end
end)
