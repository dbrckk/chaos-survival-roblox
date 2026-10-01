local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local UITheme = require(ReplicatedStorage.Shared.UITheme)

local player = Players.LocalPlayer
local tracked = {}
local lastTriggeredAt = 0

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

local function playBoostSound()
    local sound = Instance.new("Sound")
    sound.Name = "PracticeBoostLocal"
    sound.SoundId = "rbxasset://sounds/swoosh.wav"
    sound.Volume = 0.24
    sound.PlaybackSpeed = 1.42
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
    task.delay(2, function()
        if sound.Parent then
            sound:Destroy()
        end
    end)
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

local function isLocalCharacterHit(hit)
    local character = player.Character
    return character ~= nil and hit:IsDescendantOf(character)
end

local function remove(pad)
    local bundle = tracked[pad]
    if not bundle then
        return
    end
    tracked[pad] = nil

    if bundle.touch then
        bundle.touch:Disconnect()
    end
    if bundle.folder and bundle.folder.Parent then
        bundle.folder:Destroy()
    end
end

local function refreshBundle(pad, bundle)
    local quality = tier()
    bundle.emitter.Rate = quality.Name == "Low" and 0.8 or (4 * quality.ParticleScale)
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

    local folder = Instance.new("Folder")
    folder.Name = "PracticePadPolishLocal"
    folder.Parent = pad

    local attachment = Instance.new("Attachment")
    attachment.Name = "PracticeMotesAttachment"
    attachment.Position = Vector3.new(0, 0.25, 0)
    attachment.Parent = folder

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "PracticeMotes"
    emitter.Rate = 4
    emitter.Lifetime = NumberRange.new(0.25, 0.45)
    emitter.Speed = NumberRange.new(1.2, 2.8)
    emitter.SpreadAngle = Vector2.new(35, 35)
    emitter.LightEmission = 0.9
    emitter.Color = ColorSequence.new(pad.Color, Color3.new(1, 1, 1))
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.25),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment

    local highlight = Instance.new("Highlight")
    highlight.Name = "PracticeHighlight"
    highlight.Adornee = pad
    highlight.FillColor = pad.Color
    highlight.FillTransparency = 0.90
    highlight.OutlineColor = pad.Color:Lerp(Color3.new(1, 1, 1), 0.42)
    highlight.OutlineTransparency = 0.18
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = folder

    local touch = pad.Touched:Connect(function(hit)
        if not isLocalCharacterHit(hit) then
            return
        end

        local now = os.clock()
        if now - lastTriggeredAt < 0.65 then
            return
        end
        lastTriggeredAt = now

        showFeedback(pad.Color:Lerp(Color3.new(1, 1, 1), 0.22))
        playBoostSound()
        emitter:Emit(VfxQuality.particleCount(tier().Name, 16, 4))
    end)

    local bundle = {
        folder = folder,
        emitter = emitter,
        highlight = highlight,
        touch = touch,
    }
    tracked[pad] = bundle
    refreshBundle(pad, bundle)
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

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    for pad, bundle in pairs(tracked) do
        if pad.Parent then
            refreshBundle(pad, bundle)
        else
            remove(pad)
        end
    end
end)

scan(workspace)
