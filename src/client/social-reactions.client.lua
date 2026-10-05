local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local SocialExperienceRules = require(ReplicatedStorage.Shared.SocialExperienceRules)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local touchDevice = UserInputService.TouchEnabled
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("RoundState")
local reactionEvent = remotes:WaitForChild("SocialReaction")

local currentPhase = "waiting"
local sentThisResult = false
local viewportConnection = nil

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosSocialReactions"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 35
gui.Parent = player:WaitForChild("PlayerGui")

local dock = Instance.new("Frame")
dock.Name = "ResultReactionDock"
dock.AnchorPoint = Vector2.new(0.5, 1)
dock.Position = UDim2.new(0.5, 0, 1, -16)
dock.Size = UDim2.fromOffset(324, 52)
dock.BackgroundColor3 = UITheme.Colors.Panel
dock.BackgroundTransparency = 0.10
dock.BorderSizePixel = 0
dock.Visible = false
dock.Parent = gui
UITheme.addCorner(dock, UITheme.Corners.Large)
UITheme.addStroke(dock, UITheme.Colors.Cyan, 1, 0.62)

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 6)
padding.PaddingRight = UDim.new(0, 6)
padding.PaddingTop = UDim.new(0, 4)
padding.PaddingBottom = UDim.new(0, 4)
padding.Parent = dock

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 6)
layout.Parent = dock

local definitions = {
    {id = "gg", color = UITheme.Colors.Green},
    {id = "again", color = UITheme.Colors.Cyan},
    {id = "wow", color = UITheme.Colors.Gold},
}

local buttons = {}

for _, definition in ipairs(definitions) do
    local button = Instance.new("TextButton")
    button.Name = "Reaction_" .. definition.id
    button.Size = UDim2.new(0.32, -4, 1, 0)
    button.BackgroundColor3 = UITheme.Colors.PanelRaised
    button.BackgroundTransparency = 0.02
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBlack
    button.Text = CoreLocalization.text(
        localeId,
        SocialExperienceRules.reactionKey(definition.id)
    )
    button.TextColor3 = definition.color
    button.TextScaled = true
    button.AutoButtonColor = false
    button.Parent = dock
    UITheme.addCorner(button, UITheme.Corners.Medium)
    UITheme.addStroke(button, definition.color, 1.1, 0.34)
    UITheme.addPressFeedback(button, 0.94)
    UITheme.addTextConstraint(button, 11, 16)
    buttons[definition.id] = button
end

local function applyResponsive()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

    if touchDevice then
        local profile = UIResponsive.mobileProfile(viewport)
        dock.Position = UDim2.new(0.5, 0, 1, -(profile.tinyHeight and 8 or 12))
        dock.Size = UDim2.fromOffset(
            profile.veryNarrow and 286 or 316,
            profile.tinyHeight and 48 or 52
        )
    else
        dock.Position = UDim2.new(0.5, 0, 1, -16)
        dock.Size = UDim2.fromOffset(324, 52)
    end
end

local function bindCamera()
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end
    local camera = workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsive)
    end
    applyResponsive()
end

local function refresh()
    dock.Visible = not sentThisResult and SocialExperienceRules.canReact(
        currentPhase,
        #Players:GetPlayers(),
        player:GetAttribute("Games")
    )
end

local function reactionColor(reactionId)
    if reactionId == "again" then
        return UITheme.Colors.Cyan
    elseif reactionId == "wow" then
        return UITheme.Colors.Gold
    end
    return UITheme.Colors.Green
end

local function showReactionBubble(target, reactionId)
    local key = SocialExperienceRules.reactionKey(reactionId)
    if not key or not target then
        return
    end

    local character = target.Character
    local head = character and character:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return
    end

    local bubble = Instance.new("BillboardGui")
    bubble.Name = "SocialReactionBubble"
    bubble.Adornee = head
    bubble.AlwaysOnTop = true
    bubble.LightInfluence = 0
    bubble.Size = UDim2.fromOffset(138, 38)
    bubble.StudsOffsetWorldSpace = Vector3.new(0, 3.7, 0)
    bubble.MaxDistance = 120
    bubble.Parent = player:WaitForChild("PlayerGui")

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = UITheme.Colors.Panel
    label.BackgroundTransparency = 0.08
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBlack
    label.Text = CoreLocalization.text(localeId, key)
    label.TextColor3 = reactionColor(reactionId)
    label.TextScaled = true
    label.Parent = bubble
    UITheme.addCorner(label, UITheme.Corners.Pill)
    UITheme.addStroke(label, reactionColor(reactionId), 1.2, 0.25)
    UITheme.addTextConstraint(label, 12, 18)

    local scale = Instance.new("UIScale")
    scale.Scale = player:GetAttribute("ReduceMotion") == true and 1 or 0.78
    scale.Parent = label

    if player:GetAttribute("ReduceMotion") ~= true then
        TweenService:Create(
            scale,
            TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1}
        ):Play()
    end

    task.delay(1.75, function()
        if not label.Parent then
            return
        end
        TweenService:Create(
            label,
            TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {TextTransparency = 1, BackgroundTransparency = 1}
        ):Play()
    end)
    Debris:AddItem(bubble, 2.05)
end

for reactionId, button in pairs(buttons) do
    local id = reactionId
    button.Activated:Connect(function()
        if sentThisResult or not SocialExperienceRules.canReact(
            currentPhase,
            #Players:GetPlayers(),
            player:GetAttribute("Games")
        ) then
            return
        end

        sentThisResult = true
        dock.Visible = false
        reactionEvent:FireServer(id)
    end)
end

reactionEvent.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then
        return
    end

    local reactionId = tostring(payload.reactionId or "")
    if not SocialExperienceRules.reactionKey(reactionId) then
        return
    end

    local userId = tonumber(payload.userId)
    local target = userId and Players:GetPlayerByUserId(userId) or nil
    if target then
        showReactionBubble(target, reactionId)
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    local nextPhase = tostring(state.phase or "waiting")
    if nextPhase == "result" and currentPhase ~= "result" then
        sentThisResult = false
    elseif nextPhase ~= "result" then
        sentThisResult = false
    end
    currentPhase = nextPhase
    refresh()
end)

Players.PlayerAdded:Connect(refresh)
Players.PlayerRemoving:Connect(refresh)
player:GetAttributeChangedSignal("Games"):Connect(refresh)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()
refresh()
