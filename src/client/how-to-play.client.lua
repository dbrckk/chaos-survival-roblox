local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local UserInputService = game:GetService("UserInputService")

local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local FirstTimeExperience = require(ReplicatedStorage.Shared.FirstTimeExperience)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local UITheme = require(ReplicatedStorage.Shared.UITheme)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local touchDevice = UserInputService.TouchEnabled
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

-- A clear, replayable explanation for every player. The automatic introduction
-- only appears in a quiet first-time lobby and disappears before a vote starts.
-- No DataStore writes, client polling, remote messages or extra gameplay steps.
local gui = Instance.new("ScreenGui")
gui.Name = "ChaosHowToPlay"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 46
gui.Parent = player:WaitForChild("PlayerGui")

local help = Instance.new("TextButton")
help.Name = "HowToPlayButton"
help.AnchorPoint = Vector2.new(0, 0)
help.Size = UDim2.fromOffset(48, 48)
help.BackgroundColor3 = UITheme.Colors.Panel
help.BackgroundTransparency = 0.08
help.Text = "?"
help.Font = Enum.Font.GothamBlack
help.TextSize = 27
help.TextColor3 = UITheme.Colors.Cyan
help.BorderSizePixel = 0
help.AutoButtonColor = true
help.ZIndex = 30
help.Parent = gui
UITheme.addCorner(help, UITheme.Corners.Medium)
UITheme.addStroke(help, UITheme.Colors.Cyan, 1.25, 0.20)

local backdrop = Instance.new("Frame")
backdrop.Name = "HowToPlayOverlay"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(3, 8, 15)
backdrop.BackgroundTransparency = 0.30
backdrop.BorderSizePixel = 0
backdrop.Active = true
backdrop.Visible = false
backdrop.ZIndex = 40
backdrop.Parent = gui

local card = Instance.new("Frame")
card.Name = "ThreeStepGuide"
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.5)
card.BackgroundColor3 = UITheme.Colors.Panel
card.BorderSizePixel = 0
card.ZIndex = 41
card.Parent = backdrop
UITheme.addCorner(card, UITheme.Corners.Large)
UITheme.addStroke(card, UITheme.Colors.Cyan, 1.5, 0.17)
UITheme.addGradient(card, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local header = Instance.new("TextLabel")
header.Name = "Title"
header.Position = UDim2.new(0, 16, 0, 13)
header.Size = UDim2.new(1, -32, 0, 30)
header.BackgroundTransparency = 1
header.Text = CoreLocalization.text(localeId, "HELP_TITLE")
header.TextColor3 = UITheme.Colors.Text
header.TextXAlignment = Enum.TextXAlignment.Center
header.TextScaled = true
header.Font = Enum.Font.GothamBlack
header.ZIndex = 42
header.Parent = card
UITheme.addTextConstraint(header, 18, 28)

local contentFrame = Instance.new("Frame")
contentFrame.Name = "Instructions"
contentFrame.Position = UDim2.new(0, 18, 0, 51)
contentFrame.Size = UDim2.new(1, -36, 1, -112)
contentFrame.BackgroundTransparency = 1
contentFrame.ZIndex = 42
contentFrame.Parent = card

local accentColors = {
    UITheme.Colors.Cyan,
    UITheme.Colors.Green,
    UITheme.Colors.Orange,
    UITheme.Colors.Muted,
}
for index, key in ipairs({
    "HELP_STEP_ONE", "HELP_STEP_TWO", "HELP_STEP_THREE", "HELP_STEP_FOUR"
}) do
    local row = Instance.new("TextLabel")
    row.Name = "Step" .. tostring(index)
    row.Position = UDim2.new(0, 0, (index - 1) * 0.25, 0)
    row.Size = UDim2.new(1, 0, 0.25, -2)
    row.BackgroundTransparency = 1
    local instructionKey = key
    if index == 2 and not touchDevice then
        instructionKey = UserInputService.GamepadEnabled
            and "HELP_STEP_TWO_GAMEPAD" or "HELP_STEP_TWO_DESKTOP"
    end
    row.Text = CoreLocalization.text(localeId, instructionKey)
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextYAlignment = Enum.TextYAlignment.Center
    row.TextWrapped = true
    row.TextScaled = true
    row.Font = index == 4 and Enum.Font.GothamMedium or Enum.Font.GothamBold
    row.TextColor3 = accentColors[index]
    row.ZIndex = 42
    row.Parent = contentFrame
    UITheme.addTextConstraint(row, 11, index == 4 and 15 or 17)
end

local close = Instance.new("TextButton")
close.Name = "UnderstoodButton"
close.AnchorPoint = Vector2.new(0.5, 1)
close.Position = UDim2.new(0.5, 0, 1, -12)
close.Size = UDim2.new(0.66, 0, 0, 46)
close.BackgroundColor3 = UITheme.Colors.Cyan
close.TextColor3 = Color3.fromRGB(6, 16, 25)
close.Text = CoreLocalization.text(localeId, "HELP_OK")
close.Font = Enum.Font.GothamBlack
close.TextScaled = true
close.AutoButtonColor = true
close.BorderSizePixel = 0
close.ZIndex = 43
close.Parent = card
UITheme.addTextConstraint(close, 14, 20)
UITheme.addCorner(close, UITheme.Corners.Medium)

local currentState = nil
local introduced = false
local openedManually = false

local function showGuide(manual)
    openedManually = manual == true
    backdrop.Visible = true
end

local function hideGuide()
    openedManually = false
    backdrop.Visible = false
end

help.Activated:Connect(function()
    if backdrop.Visible then
        hideGuide()
    else
        showGuide(true)
    end
end)
close.Activated:Connect(hideGuide)

local function applyResponsive()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local topMargin
    if touchDevice then
        topMargin = UIResponsive.mobileProfile(viewport).topHeight + 10
    else
        topMargin = math.floor(viewport.Y * 0.19)
    end
    help.Position = UDim2.new(0, 6, 0, topMargin)
    local cardWidth = math.min(560, math.max(230, viewport.X - 32))
    local cardHeight = math.min(272, math.max(190, viewport.Y - 32))
    card.Size = UDim2.fromOffset(cardWidth, cardHeight)
end

local viewportConnection = nil
local function bindCamera()
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end
    local camera = workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(
            applyResponsive
        )
    end
    applyResponsive()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()

local function tryInitialGuide()
    if introduced or not currentState then return end
    local saved = player:GetAttribute("Games")
    local inSession = player:GetAttribute("SessionRoundsPlayed")
    if FirstTimeExperience.effectiveGames(saved, inSession) > 0 then
        introduced = true
        return
    end
    if FirstTimeExperience.shouldOfferIntro(
        player:GetAttribute("DataLoaded"),
        player:GetAttribute("DataLoadFailed"),
        saved, inSession, currentState
    ) then
        introduced = true
        showGuide(false)
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    local previousPhase = currentState and tostring(currentState.phase or "") or ""
    local hadVote = FirstTimeExperience.hasVoteOptions(currentState)
    currentState = state
    local phase = tostring(state.phase or "")
    local hasVote = FirstTimeExperience.hasVoteOptions(state)
    local busy = phase == "ready" or phase == "round" or phase == "result"
        or ((phase == "waiting" or phase == "intermission") and hasVote)
    -- An explicitly reopened guide remains readable during a stable phase.
    -- However, never leave it covering a new ballot or an entering round:
    -- these require immediate movement or a live UI decision.
    local enteredBusy = phase ~= previousPhase or (hasVote and not hadVote)
    if busy and backdrop.Visible and (not openedManually or enteredBusy) then
        hideGuide()
    end
    tryInitialGuide()
end)

player:GetAttributeChangedSignal("DataLoaded"):Connect(tryInitialGuide)
player:GetAttributeChangedSignal("DataLoadFailed"):Connect(tryInitialGuide)
player:GetAttributeChangedSignal("Games"):Connect(tryInitialGuide)
player:GetAttributeChangedSignal("SessionRoundsPlayed"):Connect(tryInitialGuide)
