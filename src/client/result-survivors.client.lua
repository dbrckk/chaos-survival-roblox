local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "ResultSurvivorSpotlightsLocal"
folder.Parent = workspace

local active = {}

local function clear()
    for _, bundle in pairs(active) do
        for _, instance in ipairs(bundle) do
            if instance and instance.Parent then
                instance:Destroy()
            end
        end
    end
    table.clear(active)
end

local function spotlight(target)
    if active[target.UserId] then
        return
    end

    local character = target.Character
    local head = character and character:FindFirstChild("Head")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not head or not head:IsA("BasePart") or not root or not root:IsA("BasePart") then
        return
    end

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local bundle = {}

    local highlight = Instance.new("Highlight")
    highlight.Name = "ResultSurvivorHighlight"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(85, 235, 165)
    highlight.FillTransparency = 0.88
    highlight.OutlineColor = Color3.fromRGB(210, 255, 225)
    highlight.OutlineTransparency = 0.08
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = character
    table.insert(bundle, highlight)

    local gui = Instance.new("BillboardGui")
    gui.Name = "ResultSurvivorBadge"
    gui.Adornee = head
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.Size = UDim2.fromOffset(150, 38)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 3.3, 0)
    gui.MaxDistance = 160
    gui.Parent = folder
    table.insert(bundle, gui)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(14, 40, 30)
    label.BackgroundTransparency = 0.12
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBlack
    label.Text = "SURVIVOR"
    label.TextColor3 = Color3.fromRGB(175, 255, 205)
    label.TextScaled = true
    label.TextTransparency = 1
    label.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = label

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(90, 235, 165)
    stroke.Thickness = 1.2
    stroke.Transparency = 0.28
    stroke.Parent = label

    TweenService:Create(label, TweenInfo.new(0.18), {TextTransparency = 0}):Play()

    if tier.Name ~= "Low" then
        local sparkles = Instance.new("Sparkles")
        sparkles.Name = "ResultSurvivorSparkles"
        sparkles.SparkleColor = Color3.fromRGB(120, 255, 190)
        sparkles.Parent = root
        table.insert(bundle, sparkles)

        local light = Instance.new("PointLight")
        light.Name = "ResultSurvivorGlow"
        light.Color = Color3.fromRGB(100, 245, 175)
        light.Brightness = 1.2 * tier.Scale
        light.Range = 10 + 4 * tier.Scale
        light.Shadows = false
        light.Parent = root
        table.insert(bundle, light)
    end

    active[target.UserId] = bundle
end

stateEvent.OnClientEvent:Connect(function(state)
    if state.phase ~= "result" then
        clear()
        return
    end

    clear()

    local ids = type(state.survivorUserIds) == "table" and state.survivorUserIds or {}
    for _, userId in ipairs(ids) do
        local target = Players:GetPlayerByUserId(tonumber(userId) or -1)
        if target then
            spotlight(target)
        end
    end
end)

Players.PlayerRemoving:Connect(function(target)
    local bundle = active[target.UserId]
    if bundle then
        for _, instance in ipairs(bundle) do
            if instance and instance.Parent then
                instance:Destroy()
            end
        end
        active[target.UserId] = nil
    end
end)
