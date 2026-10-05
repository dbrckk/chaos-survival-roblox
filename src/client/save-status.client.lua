local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosSaveStatus"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 24
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "SaveStatusCard"
card.AnchorPoint = Vector2.new(0, 0)
card.Position = UDim2.fromOffset(12, 88)
card.Size = UDim2.fromOffset(360, 58)
card.BackgroundColor3 = UITheme.Colors.Panel
card.BackgroundTransparency = 0.05
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui
UITheme.addCorner(card, UITheme.Corners.Medium)
local stroke = UITheme.addStroke(card, UITheme.Colors.Orange, 1.2, 0.30)

local accent = Instance.new("Frame")
accent.Name = "Accent"
accent.Size = UDim2.new(0, 4, 0.72, 0)
accent.Position = UDim2.fromScale(0.025, 0.14)
accent.BackgroundColor3 = UITheme.Colors.Orange
accent.BorderSizePixel = 0
accent.Parent = card
UITheme.addCorner(accent, UITheme.Corners.Pill)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.new(0, 18, 0, 7)
title.Size = UDim2.new(1, -28, 0, 20)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextColor3 = UITheme.Colors.Text
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card
UITheme.addTextConstraint(title, 11, 16)

local body = Instance.new("TextLabel")
body.Name = "Body"
body.Position = UDim2.new(0, 18, 0, 29)
body.Size = UDim2.new(1, -28, 0, 20)
body.BackgroundTransparency = 1
body.Font = Enum.Font.GothamMedium
body.TextColor3 = UITheme.Colors.Muted
body.TextScaled = true
body.TextWrapped = true
body.TextXAlignment = Enum.TextXAlignment.Left
body.Parent = card
UITheme.addTextConstraint(body, 10, 14)

local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = card

local currentPhase = "waiting"
local viewportConnection = nil
local lastKey = nil

local function issue()
    if player:GetAttribute("DataLoaded") ~= true then
        return nil
    end

    if player:GetAttribute("DataSaveConflict") == true then
        return "conflict",
            CoreLocalization.text(localeId, "SAVE_CONFLICT_TITLE"),
            CoreLocalization.text(localeId, "SAVE_CONFLICT_BODY"),
            UITheme.Colors.Red
    end

    if player:GetAttribute("DataLoadFailed") == true
        or player:GetAttribute("DataPersistenceAvailable") ~= true
    then
        return "temporary",
            CoreLocalization.text(localeId, "TEMP_SESSION_TITLE"),
            CoreLocalization.text(localeId, "TEMP_SESSION_BODY"),
            UITheme.Colors.Orange
    end

    if player:GetAttribute("LastSaveFailed") == true then
        return "retry",
            CoreLocalization.text(localeId, "SAVE_FAILED_TITLE"),
            CoreLocalization.text(localeId, "SAVE_FAILED_BODY"),
            UITheme.Colors.Orange
    end

    return nil
end

local function applyResponsive()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local profile = UIResponsive.mobileProfile(viewport)
    local compact = currentPhase == "round" or currentPhase == "ready"

    if UserInputService.TouchEnabled then
        local width = profile.veryNarrow and 250 or (profile.wide and 300 or 330)
        card.Position = UDim2.new(0, 10, 0, profile.topHeight + 14)
        card.Size = UDim2.fromOffset(width, compact and 34 or 58)
    else
        card.Position = UDim2.fromOffset(12, 88)
        card.Size = UDim2.fromOffset(360, compact and 34 or 58)
    end

    body.Visible = not compact
    title.Position = compact
        and UDim2.new(0, 18, 0, 6)
        or UDim2.new(0, 18, 0, 7)
    title.Size = compact
        and UDim2.new(1, -28, 0, 22)
        or UDim2.new(1, -28, 0, 20)
end

local function refresh()
    local key, titleText, bodyText, color = issue()
    if not key then
        lastKey = nil
        card.Visible = false
        return
    end

    local compact = currentPhase == "round" or currentPhase == "ready"
    title.Text = compact
        and CoreLocalization.text(localeId, "SAVE_PAUSED_SHORT")
        or titleText
    body.Text = bodyText
    accent.BackgroundColor3 = color
    stroke.Color = color

    applyResponsive()

    if not card.Visible or lastKey ~= key then
        card.Visible = true
        scale.Scale = 0.94
        card.BackgroundTransparency = 0.18
        TweenService:Create(
            scale,
            TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1}
        ):Play()
        TweenService:Create(
            card,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.05}
        ):Play()
    end

    lastKey = key
end

local function bindCamera()
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end

    local camera = workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            applyResponsive()
        end)
    end
    applyResponsive()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()

for _, attribute in ipairs({
    "DataLoaded",
    "DataPersistenceAvailable",
    "DataLoadFailed",
    "DataSaveConflict",
    "LastSaveFailed",
}) do
    player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

stateEvent.OnClientEvent:Connect(function(state)
    currentPhase = tostring(state.phase or "waiting")
    refresh()
end)

refresh()
