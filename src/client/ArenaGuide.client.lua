local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalizationService = game:GetService("LocalizationService")
local UserInputService = game:GetService("UserInputService")

local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local touchDevice = UserInputService.TouchEnabled
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local arenaMetadata = ReplicatedStorage:WaitForChild("ArenaMetadata")

local gui = Instance.new("ScreenGui")
gui.Name = "ArenaGuide"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 4
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "StrategyCard"
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.fromScale(0.5, 0.165)
card.Size = UDim2.fromScale(0.76, 0.105)

local cardConstraint = Instance.new("UISizeConstraint")
cardConstraint.MinSize = Vector2.new(260, 58)
cardConstraint.MaxSize = Vector2.new(700, 92)
cardConstraint.Parent = card

card.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
card.BackgroundTransparency = 1
card.Visible = false
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(105, 175, 255)
stroke.Transparency = 0.45
stroke.Thickness = 1.5
stroke.Parent = card

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -24, 1, -12)
label.Position = UDim2.fromOffset(12, 6)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamMedium
label.TextColor3 = Color3.fromRGB(230, 237, 250)
label.TextScaled = true
label.TextWrapped = true
label.Text = ""
label.TextTransparency = 1
label.Parent = card

local textConstraint = Instance.new("UITextSizeConstraint")
textConstraint.MinTextSize = 10
textConstraint.MaxTextSize = 18
textConstraint.Parent = label

local viewportConnection = nil

local function applyResponsiveLayout()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

    if touchDevice then
        local profile = UIResponsive.mobileProfile(viewport)
        card.Position = UDim2.new(0.5, 0, 0, profile.topHeight + 12)
        card.Size = UDim2.new(profile.veryNarrow and 0.94 or 0.84, 0, 0, profile.tinyHeight and 62 or 74)
        cardConstraint.MinSize = Vector2.new(profile.veryNarrow and 240 or 280, profile.tinyHeight and 58 or 64)
        textConstraint.MinTextSize = profile.tinyHeight and 10 or 11
    else
        card.Position = UDim2.fromScale(0.5, 0.165)
        card.Size = UDim2.fromScale(0.76, 0.105)
        cardConstraint.MinSize = Vector2.new(260, 58)
        textConstraint.MinTextSize = 10
    end
end

local function bindCamera()
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end

    local camera = workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveLayout)
    end
    applyResponsiveLayout()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()

local token = 0

local function replicatedHints()
    local variantId = arenaMetadata:GetAttribute("VariantId")
    local strategy = arenaMetadata:GetAttribute("StrategyHint")
    local mechanicName = arenaMetadata:GetAttribute("MechanicName")
    local mechanicHint = arenaMetadata:GetAttribute("MechanicHint")

    if type(strategy) ~= "string" or strategy == "" then
        strategy = nil
    end
    if type(mechanicName) ~= "string" or mechanicName == "" then
        mechanicName = nil
    end
    if type(mechanicHint) ~= "string" or mechanicHint == "" then
        mechanicHint = nil
    end

    return variantId, strategy, mechanicName, mechanicHint
end

local function hide()
    token += 1
    local thisToken = token
    TweenService:Create(card, TweenInfo.new(0.16), {BackgroundTransparency = 1}):Play()
    TweenService:Create(label, TweenInfo.new(0.16), {TextTransparency = 1}):Play()
    task.delay(0.18, function()
        if token == thisToken then
            card.Visible = false
        end
    end)
end

local function reveal(arenaName, hint, mechanicName, mechanicHint)
    token += 1
    if mechanicName and mechanicHint then
        label.Text = string.format("%s  •  %s\n%s  •  %s", arenaName or "ARENA", hint, mechanicName, mechanicHint)
    else
        label.Text = string.format("%s  •  %s", arenaName or "ARENA", hint)
    end
    card.Visible = true
    card.BackgroundTransparency = 1
    label.TextTransparency = 1
    TweenService:Create(card, TweenInfo.new(0.18), {BackgroundTransparency = 0.10}):Play()
    TweenService:Create(label, TweenInfo.new(0.18), {TextTransparency = 0}):Play()
end

local function show(arenaName, stateHint)
    local variantId, replicatedStrategy, mechanicName, mechanicHint = replicatedHints()
    local fallbackStrategy = stateHint
    if type(fallbackStrategy) ~= "string" or fallbackStrategy == "" then
        fallbackStrategy = replicatedStrategy
    end

    local localizedArenaName = CoreLocalization.arenaName(
        localeId,
        variantId or arenaName,
        arenaName
    )
    local localizedStrategy = CoreLocalization.arenaStrategy(
        localeId,
        variantId or arenaName,
        fallbackStrategy
    )
    local localizedMechanicName = CoreLocalization.arenaMechanicName(
        localeId,
        variantId or arenaName,
        mechanicName
    )
    local localizedMechanicHint = CoreLocalization.arenaMechanicHint(
        localeId,
        variantId or arenaName,
        mechanicHint
    )

    if localizedStrategy then
        reveal(
            localizedArenaName,
            localizedStrategy,
            localizedMechanicName,
            localizedMechanicHint
        )
    else
        hide()
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    if state.phase == "ready" then
        show(state.arenaName, state.arenaStrategy)
    elseif state.phase == "round" or state.phase == "waiting" then
        hide()
    end
end)
