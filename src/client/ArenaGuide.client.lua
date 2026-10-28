local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalizationService = game:GetService("LocalizationService")
local UserInputService = game:GetService("UserInputService")

local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local FirstTimeExperience = require(ReplicatedStorage.Shared.FirstTimeExperience)

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
        local layout = UIResponsive.mobileArenaGuideLayout(viewport)
        card.Position = UDim2.new(layout.centerXScale, 0, 0, layout.topOffset)
        card.Size = UDim2.new(layout.widthScale, 0, 0, layout.height)
        cardConstraint.MinSize = Vector2.new(layout.minWidth, layout.minHeight)
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
local readyState = nil
local isHiding = false
local cardTween = nil
local labelTween = nil

local function stopTransitions()
    if cardTween then
        cardTween:Cancel()
        cardTween = nil
    end
    if labelTween then
        labelTween:Cancel()
        labelTween = nil
    end
end

local function transition(background, text, seconds)
    stopTransitions()
    if player:GetAttribute("ReduceMotion") == true then
        card.BackgroundTransparency = background
        label.TextTransparency = text
        return
    end
    local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    cardTween = TweenService:Create(card, info, {BackgroundTransparency = background})
    labelTween = TweenService:Create(label, info, {TextTransparency = text})
    cardTween:Play()
    labelTween:Play()
end

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
    if not card.Visible or isHiding then
        return
    end
    token += 1
    local thisToken = token
    isHiding = true
    transition(1, 1, 0.16)
    if player:GetAttribute("ReduceMotion") == true then
        card.Visible = false
        isHiding = false
        return
    end
    task.delay(0.18, function()
        if token == thisToken and isHiding then
            card.Visible = false
            isHiding = false
        end
    end)
end

local function reveal(arenaName, hint, mechanicName, mechanicHint)
    local copy
    if mechanicName and mechanicHint then
        copy = string.format(
            "%s  •  %s\n%s  •  %s",
            arenaName or "ARENA", hint, mechanicName, mechanicHint
        )
    else
        copy = string.format("%s  •  %s", arenaName or "ARENA", hint)
    end

    -- The ready countdown broadcasts every second. Repeating the same
    -- reveal would flash the panel and allocate new Tweens each time.
    if card.Visible and not isHiding then
        if label.Text ~= copy then
            label.Text = copy
        end
        return
    end

    token += 1
    isHiding = false
    stopTransitions()
    label.Text = copy
    card.Visible = true
    card.BackgroundTransparency = 1
    label.TextTransparency = 1
    transition(0.10, 0, 0.18)
end

local function show(state)
    local publishedId, strategy, mechanicName, mechanicHint = replicatedHints()
    local arenaId, metadataMatches = FirstTimeExperience.arenaGuideIdentity(
        state, publishedId
    )
    if not metadataMatches then
        strategy, mechanicName, mechanicHint = nil, nil, nil
    end
    local fallbackStrategy = state.arenaStrategy
    if type(fallbackStrategy) ~= "string" or fallbackStrategy == "" then
        fallbackStrategy = strategy
    end

    local localizedArenaName = CoreLocalization.arenaName(
        localeId, arenaId, state.arenaName
    )
    local localizedStrategy = CoreLocalization.arenaStrategy(
        localeId, arenaId, fallbackStrategy
    )
    local localizedMechanicName = CoreLocalization.arenaMechanicName(
        localeId, arenaId, mechanicName
    )
    local localizedMechanicHint = CoreLocalization.arenaMechanicHint(
        localeId, arenaId, mechanicHint
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
    -- A malformed payload cannot replace the current briefing.
    if type(state) ~= "table" then return end
    -- Preserve the same guided HUD in all three entered rounds (including
    -- the third READY phase) instead of displaying overlapping strategy
    -- cards before the beginner progression is complete.
    -- The first three rounds have one phase-by-phase coach instead of
    -- multiple overlapping briefings. Touch players already see the
    -- hazard instruction in the top HUD, so never obscure the world.
    local games = FirstTimeExperience.effectiveGames(
        player:GetAttribute("Games"),
        player:GetAttribute("SessionRoundsPlayed")
    )
    if touchDevice or FirstTimeExperience.isGuidedPhase(games, state.phase) then
        readyState = nil
        hide()
    elseif state.phase == "ready" then
        readyState = state
        show(state)
    else
        readyState = nil
        hide()
    end
end)

-- Strategy and mechanic attributes can replicate after the ready event.
-- Refresh only a still-active briefing and only when its text changes.
for _, attribute in ipairs({
    "VariantId", "StrategyHint", "MechanicName", "MechanicHint",
}) do
    arenaMetadata:GetAttributeChangedSignal(attribute):Connect(function()
        if readyState then
            show(readyState)
        end
    end)
end

player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    stopTransitions()
    if isHiding then
        token += 1
        card.Visible = false
        isHiding = false
    end
    if card.Visible then
        card.BackgroundTransparency = 0.10
        label.TextTransparency = 0
    end
end)
