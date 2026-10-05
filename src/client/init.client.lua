local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local FirstTimeExperience = require(ReplicatedStorage.Shared.FirstTimeExperience)
local ResultPresentation = require(ReplicatedStorage.Shared.ResultPresentation)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)

local player = Players.LocalPlayer
local touchDevice = UserInputService.TouchEnabled
local localeId = LocalizationService.RobloxLocaleId
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("RoundState")
local voteEvent = remotes:WaitForChild("VoteDisaster")

local dailyRewardEvent = remotes:WaitForChild("DailyReward")
local questEvent = remotes:WaitForChild("QuestUpdate")
local cosmeticStateEvent = remotes:WaitForChild("CosmeticState")
local cosmeticActionEvent = remotes:WaitForChild("CosmeticAction")
local monetizationStateEvent = remotes:WaitForChild("MonetizationState")
local monetizationActionEvent = remotes:WaitForChild("MonetizationAction")
local achievementEvent = remotes:WaitForChild("AchievementState")
local roundFeedbackEvent = remotes:WaitForChild("RoundFeedback")
local clientReadyEvent = remotes:WaitForChild("ClientReady")

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local top = Instance.new("Frame")
top.Name = "TopHUD"
top.AnchorPoint = Vector2.new(0.5, 0)
top.Position = UDim2.fromScale(0.5, 0.025)
top.Size = UDim2.fromScale(0.88, 0.13)
top.BackgroundColor3 = UITheme.Colors.Panel
top.BackgroundTransparency = 0.06
top.BorderSizePixel = 0
top.Parent = root
UITheme.addCorner(top, UITheme.Corners.Large)
local topStroke = UITheme.addStroke(top, UITheme.Colors.Border, 1.2, 0.32)
local topGradient = UITheme.addGradient(top, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local topAccent = Instance.new("Frame")
topAccent.Name = "PhaseAccent"
topAccent.AnchorPoint = Vector2.new(0.5, 1)
topAccent.Position = UDim2.fromScale(0.5, 1)
topAccent.Size = UDim2.new(0.92, 0, 0, 4)
topAccent.BackgroundColor3 = UITheme.Colors.Cyan
topAccent.BorderSizePixel = 0
topAccent.Parent = top
UITheme.addCorner(topAccent, UITheme.Corners.Pill)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 0.58, 0)
title.Position = UDim2.fromOffset(18, 6)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextColor3 = UITheme.Colors.Text
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "CHAOS SURVIVAL"
title.Parent = top
UITheme.addTextConstraint(title, 14, 30)

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -100, 0.32, 0)
hint.Position = UDim2.new(0, 18, 0.62, 0)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.GothamMedium
hint.TextColor3 = UITheme.Colors.Muted
hint.TextScaled = true
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Text = ""
hint.Parent = top
UITheme.addTextConstraint(hint, 12, 20)

local timer = Instance.new("TextLabel")
timer.AnchorPoint = Vector2.new(1, 0.5)
timer.Position = UDim2.new(1, -14, 0.5, 0)
timer.Size = UDim2.fromOffset(70, 70)
timer.BackgroundColor3 = UITheme.Colors.Orange
timer.Font = Enum.Font.GothamBlack
timer.TextColor3 = UITheme.Colors.Text
timer.TextScaled = true
timer.Text = "0"
timer.BorderSizePixel = 0
timer.Parent = top
UITheme.addTextConstraint(timer, 20, 38)
UITheme.addCorner(timer, UITheme.Corners.Pill)
UITheme.addStroke(timer, Color3.fromRGB(255, 215, 170), 1.4, 0.28)
local timerGradient = UITheme.addGradient(
    timer,
    UITheme.Colors.Orange,
    Color3.fromRGB(220, 70, 55),
    90
)

local function setTimerPalette(first, second)
    timer.BackgroundColor3 = first
    timerGradient.Color = ColorSequence.new(first, second)
end

local aliveCounter = Instance.new("TextLabel")
aliveCounter.Name = "AliveCounter"
aliveCounter.AnchorPoint = Vector2.new(1, 0)
aliveCounter.Position = UDim2.new(1, -14, 1, 8)
aliveCounter.Size = UDim2.fromOffset(126, 30)
aliveCounter.BackgroundColor3 = UITheme.Colors.PanelRaised
aliveCounter.BackgroundTransparency = 0.04
aliveCounter.Font = Enum.Font.GothamBold
aliveCounter.TextColor3 = UITheme.Colors.Text
aliveCounter.TextScaled = true
aliveCounter.Text = ""
aliveCounter.Visible = false
aliveCounter.BorderSizePixel = 0
aliveCounter.Parent = top
UITheme.addTextConstraint(aliveCounter, 12, 18)
UITheme.addCorner(aliveCounter, UITheme.Corners.Pill)
UITheme.addStroke(aliveCounter, UITheme.Colors.Border, 1, 0.45)

local stats = Instance.new("TextLabel")
stats.Name = "StatsHUD"
stats.AnchorPoint = Vector2.new(0.5, 1)
stats.Position = UDim2.fromScale(0.5, 0.975)
stats.Size = UDim2.fromScale(0.65, 0.07)
stats.BackgroundColor3 = UITheme.Colors.Panel
stats.BackgroundTransparency = 0.05
stats.BorderSizePixel = 0
stats.Font = Enum.Font.GothamBold
stats.TextColor3 = UITheme.Colors.Text
stats.TextScaled = true
stats.Text = ""
stats.Visible = not touchDevice
stats.Parent = root
UITheme.addTextConstraint(stats, 12, 20)
UITheme.addCorner(stats, UITheme.Corners.Large)
UITheme.addStroke(stats, UITheme.Colors.Border, 1, 0.45)
UITheme.addGradient(stats, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)


local xpTrack = Instance.new("Frame")
xpTrack.Name = "XPTrack"
xpTrack.AnchorPoint = Vector2.new(0.5, 1)
xpTrack.Position = UDim2.fromScale(0.5, 0.94)
xpTrack.Size = UDim2.fromScale(0.62, 0.012)
xpTrack.BackgroundColor3 = UITheme.Colors.PanelSoft
xpTrack.BackgroundTransparency = 0.08
xpTrack.BorderSizePixel = 0
xpTrack.Visible = not touchDevice
xpTrack.Parent = root
Instance.new("UICorner", xpTrack).CornerRadius = UDim.new(1, 0)

local xpFill = Instance.new("Frame")
xpFill.Size = UDim2.fromScale(0, 1)
xpFill.BackgroundColor3 = UITheme.Colors.Blue
xpFill.BorderSizePixel = 0
xpFill.Parent = xpTrack
Instance.new("UICorner", xpFill).CornerRadius = UDim.new(1, 0)
UITheme.addGradient(xpFill, UITheme.Colors.Cyan, UITheme.Colors.Violet, 0)

local levelToast = Instance.new("Frame")
levelToast.AnchorPoint = Vector2.new(0.5, 0.5)
levelToast.Position = UDim2.fromScale(0.5, 0.30)
levelToast.Size = UDim2.fromScale(0.50, 0.11)
levelToast.BackgroundColor3 = UITheme.Colors.PanelRaised
levelToast.BackgroundTransparency = 1
levelToast.Visible = false
levelToast.ZIndex = 30
levelToast.Parent = root
UITheme.addCorner(levelToast, UITheme.Corners.Large)
UITheme.addStroke(levelToast, UITheme.Colors.Cyan, 1.4, 0.28)
UITheme.addGradient(levelToast, UITheme.Colors.Blue, UITheme.Colors.Violet, 15)

local levelAccent = Instance.new("Frame")
levelAccent.AnchorPoint = Vector2.new(0.5, 0)
levelAccent.Position = UDim2.fromScale(0.5, 0.08)
levelAccent.Size = UDim2.new(0, 0, 0, 4)
levelAccent.BackgroundColor3 = UITheme.Colors.Cyan
levelAccent.BorderSizePixel = 0
levelAccent.ZIndex = 31
levelAccent.Parent = levelToast
UITheme.addCorner(levelAccent, UITheme.Corners.Pill)

local levelToastScale = Instance.new("UIScale")
levelToastScale.Scale = 0.8
levelToastScale.Parent = levelToast

local levelToastText = Instance.new("TextLabel")
levelToastText.Size = UDim2.fromScale(1, 1)
levelToastText.BackgroundTransparency = 1
levelToastText.Font = Enum.Font.GothamBlack
levelToastText.TextColor3 = Color3.fromRGB(245, 250, 255)
levelToastText.TextScaled = true
levelToastText.Text = CoreLocalization.text(localeId, "LEVEL_REACHED", 1)
levelToastText.ZIndex = 31
levelToastText.Parent = levelToast

local lastKnownLevel = player:GetAttribute("Level") or 1

local function xpProgressForLevel(level, xp)
    local currentLevel = math.max(1, tonumber(level) or 1)
    local currentXP = math.max(0, tonumber(xp) or 0)
    local startXP = ((currentLevel - 1) ^ 2) * 100
    local nextXP = (currentLevel ^ 2) * 100
    local span = math.max(1, nextXP - startXP)
    return math.clamp((currentXP - startXP) / span, 0, 1), nextXP
end

local function showLevelUp(level)
    levelToastText.Text = CoreLocalization.text(localeId, "LEVEL_REACHED", level)
    levelToast.Visible = true
    levelToast.BackgroundTransparency = 1
    levelToastScale.Scale = 0.78
    levelAccent.Size = UDim2.new(0, 0, 0, 4)

    TweenService:Create(
        levelToast,
        TweenInfo.new(0.18),
        {BackgroundTransparency = 0.05}
    ):Play()

    TweenService:Create(
        levelToastScale,
        TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()
    TweenService:Create(
        levelAccent,
        TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(0.86, 0, 0, 4)}
    ):Play()

    task.delay(2.1, function()
        TweenService:Create(levelToast, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        TweenService:Create(levelToastScale, TweenInfo.new(0.2), {Scale = 0.88}):Play()
        task.wait(0.22)
        levelToast.Visible = false
    end)
end


local votes = Instance.new("Frame")
votes.Name = "VotePanel"
votes.AnchorPoint = Vector2.new(0.5, 0.5)
votes.Position = UDim2.fromScale(0.5, 0.58)
votes.Size = UDim2.fromScale(touchDevice and 0.92 or 0.88, touchDevice and 0.27 or 0.24)
votes.BackgroundTransparency = 1
votes.Visible = false
votes.Parent = root

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0.018, 0)
layout.Parent = votes

local selectedVote = nil
local compactRoundTop = false

local rookieCoach = Instance.new("TextLabel")
rookieCoach.Name = "RookieCoach"
rookieCoach.AnchorPoint = Vector2.new(0.5, 1)
rookieCoach.Position = UDim2.fromScale(0.5, touchDevice and 0.70 or 0.94)
rookieCoach.Size = UDim2.fromScale(touchDevice and 0.68 or 0.88, touchDevice and 0.042 or 0.055)
rookieCoach.BackgroundColor3 = UITheme.Colors.Panel
rookieCoach.BackgroundTransparency = 0.05
rookieCoach.BorderSizePixel = 0
rookieCoach.Font = Enum.Font.GothamBold
rookieCoach.TextColor3 = Color3.fromRGB(235, 240, 250)
rookieCoach.TextScaled = true
rookieCoach.TextWrapped = true
rookieCoach.Text = "SURVIVE UNTIL 0  •  AVOID WARNING COLORS  •  GLOWING PADS = ESCAPE"
rookieCoach.Visible = false
rookieCoach.ZIndex = 12
rookieCoach.Parent = root
UITheme.addTextConstraint(rookieCoach, 13, 18)
UITheme.addCorner(rookieCoach, UITheme.Corners.Medium)
UITheme.addStroke(rookieCoach, UITheme.Colors.Blue, 1, 0.48)

local countdownCard = Instance.new("Frame")
countdownCard.Name = "RoundCountdown"
countdownCard.AnchorPoint = Vector2.new(0.5, 0.5)
countdownCard.Position = UDim2.fromScale(0.5, 0.46)
countdownCard.Size = touchDevice
    and UDim2.new(0.50, 0, 0, 122)
    or UDim2.new(0.34, 0, 0, 136)
countdownCard.BackgroundColor3 = UITheme.Colors.Panel
countdownCard.BackgroundTransparency = 0.04
countdownCard.BorderSizePixel = 0
countdownCard.Visible = false
countdownCard.ZIndex = 40
countdownCard.Parent = root
UITheme.addCorner(countdownCard, UDim.new(0, 22))
local countdownStroke = UITheme.addStroke(countdownCard, UITheme.Colors.Cyan, 1.8, 0.20)
UITheme.addGradient(countdownCard, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local countdownScale = Instance.new("UIScale")
countdownScale.Scale = 1
countdownScale.Parent = countdownCard

local countdownKicker = Instance.new("TextLabel")
countdownKicker.Size = UDim2.new(1, -28, 0.22, 0)
countdownKicker.Position = UDim2.new(0, 14, 0.08, 0)
countdownKicker.BackgroundTransparency = 1
countdownKicker.Font = Enum.Font.GothamBold
countdownKicker.TextColor3 = UITheme.Colors.Cyan
countdownKicker.TextScaled = true
countdownKicker.Text = "CHAOS SELECTED"
countdownKicker.ZIndex = 41
countdownKicker.Parent = countdownCard
UITheme.addTextConstraint(countdownKicker, 12, 18)

local countdownMain = Instance.new("TextLabel")
countdownMain.Size = UDim2.new(1, -28, 0.43, 0)
countdownMain.Position = UDim2.new(0, 14, 0.29, 0)
countdownMain.BackgroundTransparency = 1
countdownMain.Font = Enum.Font.GothamBlack
countdownMain.TextColor3 = UITheme.Colors.Text
countdownMain.TextScaled = true
countdownMain.TextWrapped = true
countdownMain.Text = "3"
countdownMain.ZIndex = 41
countdownMain.Parent = countdownCard
UITheme.addTextConstraint(countdownMain, 22, 44)

local countdownSub = Instance.new("TextLabel")
countdownSub.Size = UDim2.new(1, -28, 0.18, 0)
countdownSub.Position = UDim2.new(0, 14, 0.75, 0)
countdownSub.BackgroundTransparency = 1
countdownSub.Font = Enum.Font.GothamMedium
countdownSub.TextColor3 = UITheme.Colors.Muted
countdownSub.TextScaled = true
countdownSub.TextWrapped = true
countdownSub.Text = "SURVIVE UNTIL 0"
countdownSub.ZIndex = 41
countdownSub.Parent = countdownCard
UITheme.addTextConstraint(countdownSub, 11, 17)

local countdownToken = 0
local previousRoundPhase = nil
local revealedPlayerChoice = nil

local function cleanReadyTitle(value)
    local text = tostring(value or "CHAOS")
    text = string.gsub(text, "^READY:%s*", "")
    text = string.gsub(text, "^SOLO RUSH:%s*", "")
    text = string.gsub(text, "^QUICK RUSH:%s*", "")
    return text
end

local function hazardGuidance(state, compact)
    local disasterIds = type(state.disasterIds) == "table" and state.disasterIds or {}
    local guidance = {}

    for index, disasterId in ipairs(disasterIds) do
        if index > 2 then
            break
        end

        local action = CoreLocalization.hazardAction(localeId, disasterId)
        local hazardHint = CoreLocalization.hazardHint(localeId, disasterId)
        local copy = nil

        if compact then
            copy = action or hazardHint
        elseif action and hazardHint then
            copy = action .. "  •  " .. hazardHint
        else
            copy = action or hazardHint
        end

        if copy and copy ~= "" then
            table.insert(guidance, copy)
        end
    end

    if #guidance == 0 then
        return nil
    end

    return table.concat(guidance, state.doubleChaos and "   +   " or "   •   ")
end

local function presentCountdown(state)
    local phase = tostring(state.phase or "")
    local seconds = math.max(0, math.floor(tonumber(state.seconds) or 0))

    if phase == "ready" then
        if previousRoundPhase ~= "ready" then
            revealedPlayerChoice = selectedVote
        end

        countdownToken += 1
        countdownCard.Visible = true
        countdownCard.BackgroundTransparency = 0.04
        countdownScale.Scale = 0.90

        local accent = UITheme.disasterAccent(
            state.disasterIds and state.disasterIds[1],
            UITheme.Colors.Cyan
        )
        countdownStroke.Color = state.doubleChaos and UITheme.Colors.Violet or accent
        countdownKicker.TextColor3 = accent

        local survivorCount = math.max(
            1,
            math.floor(tonumber(state.contestantCount) or 1)
        )

        if seconds > 3 then
            local primaryDisasterId = state.disasterIds and state.disasterIds[1]
            local playerChoiceWon = revealedPlayerChoice ~= nil
                and tostring(revealedPlayerChoice) == tostring(primaryDisasterId)
            countdownKicker.Text = playerChoiceWon
                and CoreLocalization.text(localeId, "YOUR_CHOICE_WON")
                or CoreLocalization.text(localeId, "CHAOS_SELECTED")
            countdownMain.Text = CoreLocalization.hazardTitle(
                localeId,
                state.disasterIds,
                cleanReadyTitle(state.title)
            )
            countdownSub.Text = hazardGuidance(state, false)
                or (survivorCount > 1
                    and CoreLocalization.text(localeId, "SURVIVORS_READY", survivorCount)
                    or CoreLocalization.text(localeId, "SURVIVE_ZERO"))
        else
            countdownKicker.Text = CoreLocalization.text(localeId, "GET_READY")
            countdownMain.Text = tostring(math.max(1, seconds))
            countdownSub.Text = hazardGuidance(state, true)
                or (survivorCount > 1
                    and CoreLocalization.text(localeId, "SURVIVORS", survivorCount)
                    or CoreLocalization.text(localeId, "SURVIVE_ZERO"))
        end

        TweenService:Create(
            countdownScale,
            TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1}
        ):Play()
        return
    end

    if previousRoundPhase == "ready" and phase == "round" then
        countdownToken += 1
        local token = countdownToken
        countdownCard.Visible = true
        countdownCard.BackgroundTransparency = 0.02
        countdownKicker.Text = CoreLocalization.text(localeId, "SURVIVE")
        countdownKicker.TextColor3 = UITheme.Colors.Green
        countdownMain.Text = "GO!"
        countdownSub.Text = CoreLocalization.text(localeId, "GO_SUB")
        countdownScale.Scale = 0.82
        TweenService:Create(
            countdownScale,
            TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1.08}
        ):Play()

        task.delay(0.58, function()
            if token ~= countdownToken then
                return
            end
            TweenService:Create(
                countdownCard,
                TweenInfo.new(0.18),
                {BackgroundTransparency = 1}
            ):Play()
            TweenService:Create(
                countdownScale,
                TweenInfo.new(0.18),
                {Scale = 0.92}
            ):Play()
            task.delay(0.20, function()
                if token == countdownToken then
                    countdownCard.Visible = false
                    countdownCard.BackgroundTransparency = 0.04
                end
            end)
        end)
        return
    end

    countdownToken += 1
    countdownCard.Visible = false
end

local dailyToast = Instance.new("Frame")
dailyToast.AnchorPoint = Vector2.new(0.5, 0.5)
dailyToast.Position = UDim2.fromScale(0.5, 0.32)
dailyToast.Size = UDim2.fromScale(0.72, 0.16)
dailyToast.BackgroundColor3 = UITheme.Colors.Panel
dailyToast.BackgroundTransparency = 0.02
dailyToast.BorderSizePixel = 0
dailyToast.Visible = false
dailyToast.Parent = root
UITheme.addCorner(dailyToast, UITheme.Corners.Large)
UITheme.addStroke(dailyToast, UITheme.Colors.Blue, 1.2, 0.34)
UITheme.addGradient(dailyToast, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local dailyTitle = Instance.new("TextLabel")
dailyTitle.Size = UDim2.new(1, -24, 0.48, 0)
dailyTitle.Position = UDim2.fromOffset(12, 8)
dailyTitle.BackgroundTransparency = 1
dailyTitle.Font = Enum.Font.GothamBlack
dailyTitle.TextColor3 = Color3.new(1, 1, 1)
dailyTitle.TextScaled = true
dailyTitle.Text = CoreLocalization.text(localeId, "DAILY_REWARD")
dailyTitle.Parent = dailyToast

local dailyBody = Instance.new("TextLabel")
dailyBody.Size = UDim2.new(1, -24, 0.36, 0)
dailyBody.Position = UDim2.new(0, 12, 0.54, 0)
dailyBody.BackgroundTransparency = 1
dailyBody.Font = Enum.Font.GothamMedium
dailyBody.TextColor3 = Color3.fromRGB(220, 225, 235)
dailyBody.TextScaled = true
dailyBody.Text = ""
dailyBody.Parent = dailyToast



local questButton = Instance.new("TextButton")
questButton.Name = "QuestButton"
questButton.AnchorPoint = Vector2.new(0, 1)
questButton.Position = UDim2.fromScale(0.025, touchDevice and 0.88 or 0.90)
questButton.Size = UDim2.fromScale(touchDevice and 0.20 or 0.22, touchDevice and 0.055 or 0.065)
questButton.BackgroundColor3 = UITheme.Colors.PanelRaised
questButton.BackgroundTransparency = 0.04
questButton.BorderSizePixel = 0
questButton.TextColor3 = UITheme.Colors.Text
questButton.Font = Enum.Font.GothamBold
questButton.TextScaled = true
questButton.Text = CoreLocalization.text(localeId, "QUESTS")
questButton.Parent = root
UITheme.addCorner(questButton, UITheme.Corners.Medium)
UITheme.addStroke(questButton, UITheme.Colors.Cyan, 1.2, 0.38)
UITheme.addGradient(questButton, UITheme.Colors.PanelRaised, UITheme.Colors.PanelSoft, 90)
UITheme.addPressFeedback(questButton, 0.95)

local questPanel = Instance.new("Frame")
questPanel.Name = "QuestPanel"
questPanel.AnchorPoint = Vector2.new(0, 1)
questPanel.Position = UDim2.fromScale(0.025, 0.82)
questPanel.Size = UDim2.fromScale(0.72, 0.46)
questPanel.BackgroundColor3 = UITheme.Colors.Panel
questPanel.BackgroundTransparency = 0.02
questPanel.BorderSizePixel = 0
questPanel.Visible = false
questPanel.Parent = root
UITheme.addCorner(questPanel, UITheme.Corners.Large)
UITheme.addStroke(questPanel, UITheme.Colors.Cyan, 1.2, 0.38)
UITheme.addGradient(questPanel, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local questPanelConstraint = Instance.new("UISizeConstraint")
questPanelConstraint.MinSize = Vector2.new(260, 250)
questPanelConstraint.MaxSize = Vector2.new(620, 430)
questPanelConstraint.Parent = questPanel

local questHeader = Instance.new("TextLabel")
questHeader.Size = UDim2.new(1, -24, 0.10, 0)
questHeader.Position = UDim2.fromOffset(12, 6)
questHeader.BackgroundTransparency = 1
questHeader.Font = Enum.Font.GothamBlack
questHeader.TextColor3 = Color3.new(1, 1, 1)
questHeader.TextScaled = true
questHeader.TextXAlignment = Enum.TextXAlignment.Left
questHeader.Text = CoreLocalization.text(localeId, "DAILY_QUESTS")
questHeader.Parent = questPanel

local questRows = {}
for i = 1, 3 do
    local row = Instance.new("TextLabel")
    row.Size = UDim2.new(1, -24, 0.12, 0)
    row.Position = UDim2.new(0, 12, 0.12 + ((i - 1) * 0.14), 0)
    row.BackgroundColor3 = UITheme.Colors.PanelSoft
    row.BackgroundTransparency = 0.10
    row.BorderSizePixel = 0
    row.TextColor3 = UITheme.Colors.Text
    row.Font = Enum.Font.GothamMedium
    row.TextScaled = true
    row.TextWrapped = true
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.Text = "Loading..."
    row.Parent = questPanel
    UITheme.addCorner(row, UITheme.Corners.Small)
    UITheme.addStroke(row, UITheme.Colors.Cyan, 1, 0.74)
    questRows[i] = row
end

local weeklyHeader = Instance.new("TextLabel")
weeklyHeader.Size = UDim2.new(1, -24, 0.09, 0)
weeklyHeader.Position = UDim2.new(0, 12, 0.54, 0)
weeklyHeader.BackgroundTransparency = 1
weeklyHeader.Font = Enum.Font.GothamBlack
weeklyHeader.TextColor3 = UITheme.Colors.Gold
weeklyHeader.TextScaled = true
weeklyHeader.TextXAlignment = Enum.TextXAlignment.Left
weeklyHeader.Text = CoreLocalization.text(localeId, "WEEKLY_CHALLENGES")
weeklyHeader.Parent = questPanel

local weeklyRows = {}
for i = 1, 2 do
    local row = Instance.new("TextLabel")
    row.Size = UDim2.new(1, -24, 0.13, 0)
    row.Position = UDim2.new(0, 12, 0.65 + ((i - 1) * 0.15), 0)
    row.BackgroundColor3 = UITheme.Colors.Gold:Lerp(UITheme.Colors.PanelSoft, 0.88)
    row.BackgroundTransparency = 0.08
    row.BorderSizePixel = 0
    row.TextColor3 = UITheme.Colors.Text
    row.Font = Enum.Font.GothamMedium
    row.TextScaled = true
    row.TextWrapped = true
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.Text = "Loading..."
    row.Parent = questPanel
    UITheme.addCorner(row, UITheme.Corners.Small)
    UITheme.addStroke(row, UITheme.Colors.Gold, 1, 0.60)
    weeklyRows[i] = row
end

local questToast = Instance.new("Frame")
questToast.AnchorPoint = Vector2.new(0.5, 0.5)
questToast.Position = UDim2.fromScale(0.5, 0.50)
questToast.Size = UDim2.fromScale(0.76, 0.15)
questToast.BackgroundColor3 = UITheme.Colors.Panel
questToast.BackgroundTransparency = 0.02
questToast.BorderSizePixel = 0
questToast.Visible = false
questToast.Parent = root
UITheme.addCorner(questToast, UITheme.Corners.Large)
UITheme.addStroke(questToast, UITheme.Colors.Green, 1.3, 0.28)
UITheme.addGradient(questToast, Color3.fromRGB(26, 70, 52), UITheme.Colors.Panel, 90)

local questToastTitle = Instance.new("TextLabel")
questToastTitle.Size = UDim2.new(1, -24, 0.48, 0)
questToastTitle.Position = UDim2.fromOffset(12, 8)
questToastTitle.BackgroundTransparency = 1
questToastTitle.Font = Enum.Font.GothamBlack
questToastTitle.TextColor3 = Color3.new(1, 1, 1)
questToastTitle.TextScaled = true
questToastTitle.Text = "QUEST COMPLETE"
questToastTitle.Parent = questToast

local questToastBody = Instance.new("TextLabel")
questToastBody.Size = UDim2.new(1, -24, 0.34, 0)
questToastBody.Position = UDim2.new(0, 12, 0.56, 0)
questToastBody.BackgroundTransparency = 1
questToastBody.Font = Enum.Font.GothamMedium
questToastBody.TextColor3 = Color3.fromRGB(230, 240, 232)
questToastBody.TextScaled = true
questToastBody.Text = ""
questToastBody.Parent = questToast

-- panel navigation is wired after all three panels are created

local function renderQuestState(state)
    local quests = state and state.quests or {}
    for i = 1, 3 do
        local quest = quests[i]
        if quest then
            local marker = quest.claimed
                and CoreLocalization.text(localeId, "DONE")
                or string.format("%d/%d", quest.progress or 0, quest.target or 0)
            local questTitle = CoreLocalization.questTitle(
                localeId,
                quest.id,
                quest.title or CoreLocalization.text(localeId, "QUESTS")
            )
            questRows[i].Text = CoreLocalization.text(
                localeId,
                "QUEST_ROW",
                questTitle,
                marker,
                quest.coins or 0
            )
        else
            questRows[i].Text = "  " .. CoreLocalization.text(localeId, "NO_DAILY_QUEST")
        end
    end

    local weekly = state and state.weekly or {}
    for i = 1, 2 do
        local challenge = weekly[i]
        if challenge then
            local marker = challenge.claimed
                and CoreLocalization.text(localeId, "DONE")
                or string.format("%d/%d", challenge.progress or 0, challenge.target or 0)
            local challengeTitle = CoreLocalization.questTitle(
                localeId,
                challenge.id,
                challenge.title or CoreLocalization.text(localeId, "WEEKLY_CHALLENGES")
            )
            weeklyRows[i].Text = CoreLocalization.text(
                localeId,
                "WEEKLY_ROW",
                challengeTitle,
                marker,
                challenge.coins or 0,
                challenge.xp or 0
            )
            weeklyRows[i].TextColor3 = challenge.claimed and UITheme.Colors.Green or UITheme.Colors.Text
        else
            weeklyRows[i].Text = "  " .. CoreLocalization.text(localeId, "NO_WEEKLY_CHALLENGE")
            weeklyRows[i].TextColor3 = UITheme.Colors.Muted
        end
    end
end



local cosmeticsButton = Instance.new("TextButton")
cosmeticsButton.Name = "CosmeticsButton"
cosmeticsButton.AnchorPoint = Vector2.new(1, 1)
cosmeticsButton.Position = UDim2.fromScale(0.975, touchDevice and 0.88 or 0.90)
cosmeticsButton.Size = UDim2.fromScale(touchDevice and 0.23 or 0.26, touchDevice and 0.055 or 0.065)
cosmeticsButton.BackgroundColor3 = UITheme.Colors.PanelRaised
cosmeticsButton.BackgroundTransparency = 0.04
cosmeticsButton.BorderSizePixel = 0
cosmeticsButton.TextColor3 = UITheme.Colors.Text
cosmeticsButton.Font = Enum.Font.GothamBold
cosmeticsButton.TextScaled = true
cosmeticsButton.Text = CoreLocalization.text(localeId, "COSMETICS")
cosmeticsButton.Parent = root
UITheme.addCorner(cosmeticsButton, UITheme.Corners.Medium)
UITheme.addStroke(cosmeticsButton, UITheme.Colors.Magenta, 1.2, 0.38)
UITheme.addGradient(cosmeticsButton, UITheme.Colors.PanelRaised, UITheme.Colors.PanelSoft, 90)
UITheme.addPressFeedback(cosmeticsButton, 0.95)

local cosmeticsPanel = Instance.new("Frame")
cosmeticsPanel.Name = "CosmeticsPanel"
cosmeticsPanel.AnchorPoint = Vector2.new(1, 1)
cosmeticsPanel.Position = UDim2.fromScale(0.975, 0.82)
cosmeticsPanel.Size = UDim2.fromScale(0.72, 0.36)
cosmeticsPanel.BackgroundColor3 = UITheme.Colors.Panel
cosmeticsPanel.BackgroundTransparency = 0.02
cosmeticsPanel.BorderSizePixel = 0
cosmeticsPanel.Visible = false
cosmeticsPanel.Parent = root
UITheme.addCorner(cosmeticsPanel, UITheme.Corners.Large)
UITheme.addStroke(cosmeticsPanel, UITheme.Colors.Magenta, 1.2, 0.38)
UITheme.addGradient(cosmeticsPanel, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local cosmeticsPanelConstraint = Instance.new("UISizeConstraint")
cosmeticsPanelConstraint.MinSize = Vector2.new(270, 220)
cosmeticsPanelConstraint.MaxSize = Vector2.new(620, 390)
cosmeticsPanelConstraint.Parent = cosmeticsPanel

local cosmeticsHeader = Instance.new("TextLabel")
cosmeticsHeader.Size = UDim2.new(1, -24, 0.16, 0)
cosmeticsHeader.Position = UDim2.fromOffset(12, 6)
cosmeticsHeader.BackgroundTransparency = 1
cosmeticsHeader.Font = Enum.Font.GothamBlack
cosmeticsHeader.TextColor3 = Color3.new(1, 1, 1)
cosmeticsHeader.TextScaled = true
cosmeticsHeader.TextXAlignment = Enum.TextXAlignment.Left
cosmeticsHeader.Text = CoreLocalization.text(localeId, "LOADOUT_TRAIL_AURA")
cosmeticsHeader.Parent = cosmeticsPanel

local cosmeticsList = Instance.new("ScrollingFrame")
cosmeticsList.Size = UDim2.new(1, -24, 0.74, 0)
cosmeticsList.Position = UDim2.new(0, 12, 0.20, 0)
cosmeticsList.BackgroundTransparency = 1
cosmeticsList.BorderSizePixel = 0
cosmeticsList.ScrollBarThickness = 5
cosmeticsList.CanvasSize = UDim2.fromOffset(0, 0)
cosmeticsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
cosmeticsList.Parent = cosmeticsPanel

local cosmeticsLayout = Instance.new("UIListLayout")
cosmeticsLayout.Padding = UDim.new(0, 8)
cosmeticsLayout.Parent = cosmeticsList

local currentCosmeticState = nil
local previousCosmeticOwnedCount = nil
local pendingCollectorMilestone = nil

local COLLECTOR_MILESTONES = {
    [3] = "COLLECTOR_I",
    [6] = "COLLECTOR_II",
    [9] = "COLLECTOR_III",
    [11] = "COLLECTOR_COMPLETE",
}

local RARITY_COLORS = {
    Common = UITheme.Colors.Muted,
    Rare = UITheme.Colors.Cyan,
    Epic = UITheme.Colors.Violet,
    Legendary = UITheme.Colors.Gold,
    Premium = UITheme.Colors.Magenta,
}

local function renderCosmetics(state)
    currentCosmeticState = state

    local collectionLog = state and state.collectionLog or nil
    if type(collectionLog) == "table" then
        local ownedNow = math.max(0, math.floor(tonumber(collectionLog.owned) or 0))
        if previousCosmeticOwnedCount ~= nil and ownedNow > previousCosmeticOwnedCount then
            for threshold, label in pairs(COLLECTOR_MILESTONES) do
                if previousCosmeticOwnedCount < threshold and ownedNow >= threshold then
                    pendingCollectorMilestone = {
                        threshold = threshold,
                        labelKey = label,
                    }
                end
            end
        end
        previousCosmeticOwnedCount = ownedNow
    end
    if type(collectionLog) == "table" then
        local owned = math.max(0, math.floor(tonumber(collectionLog.owned) or 0))
        local total = math.max(0, math.floor(tonumber(collectionLog.total) or 0))
        local completedSets = math.max(0, math.floor(tonumber(collectionLog.completedCollections) or 0))
        local totalSets = math.max(0, math.floor(tonumber(collectionLog.totalCollections) or 0))
        if collectionLog.maxed == true then
            cosmeticsHeader.Text = CoreLocalization.text(
                localeId,
                "COLLECTION_COMPLETE_SETS",
                owned,
                total,
                completedSets,
                totalSets
            )
        else
            local nextMilestone = math.max(owned, math.floor(tonumber(collectionLog.nextMilestone) or owned))
            cosmeticsHeader.Text = CoreLocalization.text(
                localeId,
                "LOADOUT_COLLECTION_NEXT",
                owned,
                total,
                completedSets,
                totalSets,
                nextMilestone
            )
        end
    else
        cosmeticsHeader.Text = CoreLocalization.text(localeId, "LOADOUT_TRAIL_AURA")
    end

    for _, child in ipairs(cosmeticsList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local catalog = state and state.catalog or {}
    local owned = state and state.owned or {}
    local equipped = state and state.equipped or {}
    local equippedTrail = type(equipped) == "table" and equipped.trail or ""
    local equippedAura = type(equipped) == "table" and equipped.aura or ""

    for _, item in ipairs(catalog) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 58)
        button.BackgroundColor3 = UITheme.Colors.PanelSoft
        button.BackgroundTransparency = 0.06
        button.BorderSizePixel = 0
        button.TextColor3 = UITheme.Colors.Text
        button.Font = Enum.Font.GothamBold
        button.TextScaled = true
        button.TextWrapped = true
        button.AutoButtonColor = false

        local isOwned = owned[item.id] == true
        local coinPrice = tonumber(item.coinPrice)
        local unlockLevel = tonumber(item.unlockLevel)
        local arenaMasteryId = item.arenaMasteryId and tostring(item.arenaMasteryId) or nil
        local arenaMasteryPoints = tonumber(item.arenaMasteryPoints)
        local kindLabel = string.upper(tostring(item.kind or "cosmetic"))
        local rarity = tostring(item.rarity or "Common")
        local rarityLabel = string.upper(rarity)
        local collection = tostring(item.collection or "")
        local kindAccent = item.kind == "trail" and UITheme.Colors.Cyan or UITheme.Colors.Magenta
        local rarityAccent = RARITY_COLORS[rarity] or kindAccent

        local isEquipped = (item.kind == "trail" and equippedTrail == item.id)
            or (item.kind == "aura" and equippedAura == item.id)

        if isEquipped then
            button.Text = string.format(
                "%s   •   %s   •   %s   •   %s",
                item.name,
                rarityLabel,
                kindLabel,
                CoreLocalization.text(localeId, "EQUIPPED")
            )
            button.BackgroundColor3 = UITheme.Colors.Green:Lerp(UITheme.Colors.Panel, 0.58)
        elseif isOwned then
            button.Text = string.format(
                "%s   •   %s   •   %s   •   %s",
                item.name,
                rarityLabel,
                kindLabel,
                CoreLocalization.text(localeId, "EQUIP")
            )
        elseif coinPrice and coinPrice > 0 then
            button.Text = string.format(
                "%s   •   %s   •   %s   •   %s",
                item.name,
                rarityLabel,
                kindLabel,
                CoreLocalization.text(localeId, "COSMETIC_PRICE_COINS", coinPrice)
            )
            button.BackgroundColor3 = UITheme.Colors.Gold:Lerp(UITheme.Colors.Panel, 0.72)
        elseif unlockLevel then
            button.Text = string.format(
                "%s   •   %s   •   %s   •   %s",
                item.name,
                rarityLabel,
                kindLabel,
                CoreLocalization.text(localeId, "COSMETIC_UNLOCK_LEVEL", unlockLevel)
            )
            button.BackgroundColor3 = UITheme.Colors.PanelSoft
        elseif arenaMasteryId and arenaMasteryPoints then
            button.Text = string.format(
                "%s   •   %s   •   %s   •   %s",
                item.name,
                rarityLabel,
                kindLabel,
                CoreLocalization.text(
                    localeId,
                    "COSMETIC_MASTERY_GOLD",
                    string.upper(arenaMasteryId)
                )
            )
            button.BackgroundColor3 = UITheme.Colors.Violet:Lerp(UITheme.Colors.Panel, 0.74)
        else
            button.Text = string.format("%s   •   %s   •   %s", item.name, rarityLabel, kindLabel)
            button.BackgroundColor3 = Color3.fromRGB(48, 49, 58)
        end

        button.Parent = cosmeticsList
        UITheme.addCorner(button, UITheme.Corners.Small)
        UITheme.addStroke(
            button,
            isEquipped and UITheme.Colors.Green or rarityAccent,
            isEquipped and 1.8 or 1.0,
            isEquipped and 0.18 or 0.55
        )
        UITheme.addGradient(
            button,
            button.BackgroundColor3:Lerp(rarityAccent, isEquipped and 0.10 or 0.08),
            UITheme.Colors.Panel,
            90
        )
        UITheme.addPressFeedback(button, 0.975)

        if typeof(item.colorA) == "Color3" and typeof(item.colorB) == "Color3" then
            local preview = Instance.new("Frame")
            preview.Name = "CosmeticColorPreview"
            preview.AnchorPoint = Vector2.new(0.5, 1)
            preview.Position = UDim2.new(0.5, 0, 1, -3)
            preview.Size = UDim2.new(0.86, 0, 0, 5)
            preview.BackgroundColor3 = item.colorA
            preview.BorderSizePixel = 0
            preview.ZIndex = button.ZIndex + 1
            preview.Parent = button
            UITheme.addCorner(preview, UITheme.Corners.Pill)

            local previewGradient = Instance.new("UIGradient")
            previewGradient.Color = ColorSequence.new(item.colorA, item.colorB)
            previewGradient.Parent = preview
        end

        button:SetAttribute("CosmeticCollection", collection)
        button:SetAttribute("CosmeticRarity", rarity)

        button.Activated:Connect(function()
            if isOwned then
                cosmeticActionEvent:FireServer("equip", item.id)
            elseif coinPrice and coinPrice > 0 then
                cosmeticActionEvent:FireServer("buy", item.id)
            end
        end)
    end
end

-- cosmetics navigation is wired after all panels are created

local metaControlsSuppressed = true

local supportButton = Instance.new("TextButton")
supportButton.Name = "SupportButton"
supportButton.AnchorPoint = Vector2.new(1, 1)
supportButton.Position = UDim2.fromScale(0.975, 0.825)
supportButton.Size = UDim2.fromScale(0.26, 0.055)
supportButton.BackgroundColor3 = UITheme.Colors.PanelRaised
supportButton.BackgroundTransparency = 0.04
supportButton.BorderSizePixel = 0
supportButton.TextColor3 = UITheme.Colors.Text
supportButton.Font = Enum.Font.GothamBold
supportButton.TextScaled = true
supportButton.Text = CoreLocalization.text(localeId, "SUPPORT")
supportButton.Visible = false
supportButton.Parent = root
UITheme.addCorner(supportButton, UITheme.Corners.Medium)
UITheme.addStroke(supportButton, UITheme.Colors.Violet, 1.2, 0.34)
UITheme.addGradient(supportButton, UITheme.Colors.PanelRaised, UITheme.Colors.PanelSoft, 90)
UITheme.addPressFeedback(supportButton, 0.95)

local supportPanel = Instance.new("Frame")
supportPanel.Name = "SupportPanel"
supportPanel.AnchorPoint = Vector2.new(1, 1)
supportPanel.Position = UDim2.fromScale(0.975, 0.75)
supportPanel.Size = UDim2.fromScale(0.72, 0.30)
supportPanel.BackgroundColor3 = UITheme.Colors.Panel
supportPanel.BackgroundTransparency = 0.02
supportPanel.BorderSizePixel = 0
supportPanel.Visible = false
supportPanel.Parent = root
UITheme.addCorner(supportPanel, UITheme.Corners.Large)
UITheme.addStroke(supportPanel, UITheme.Colors.Violet, 1.2, 0.34)
UITheme.addGradient(supportPanel, Color3.fromRGB(52, 34, 72), UITheme.Colors.Panel, 90)

local supportPanelConstraint = Instance.new("UISizeConstraint")
supportPanelConstraint.MinSize = Vector2.new(270, 190)
supportPanelConstraint.MaxSize = Vector2.new(620, 330)
supportPanelConstraint.Parent = supportPanel

local supportHeader = Instance.new("TextLabel")
supportHeader.Size = UDim2.new(1, -24, 0.20, 0)
supportHeader.Position = UDim2.fromOffset(12, 6)
supportHeader.BackgroundTransparency = 1
supportHeader.Font = Enum.Font.GothamBlack
supportHeader.TextColor3 = Color3.new(1, 1, 1)
supportHeader.TextScaled = true
supportHeader.TextXAlignment = Enum.TextXAlignment.Left
supportHeader.Text = CoreLocalization.text(localeId, "SUPPORT_GAME")
supportHeader.Parent = supportPanel

local supportFairPlay = Instance.new("TextLabel")
supportFairPlay.Size = UDim2.new(1, -24, 0.14, 0)
supportFairPlay.Position = UDim2.new(0, 12, 0.20, 0)
supportFairPlay.BackgroundTransparency = 1
supportFairPlay.Font = Enum.Font.GothamBold
supportFairPlay.TextColor3 = Color3.fromRGB(175, 235, 195)
supportFairPlay.TextScaled = true
supportFairPlay.TextXAlignment = Enum.TextXAlignment.Left
supportFairPlay.Text = CoreLocalization.text(localeId, "FAIR_PLAY")
supportFairPlay.Parent = supportPanel

local supportList = Instance.new("Frame")
supportList.Size = UDim2.new(1, -24, 0.56, 0)
supportList.Position = UDim2.new(0, 12, 0.38, 0)
supportList.BackgroundTransparency = 1
supportList.Parent = supportPanel

local supportLayout = Instance.new("UIListLayout")
supportLayout.Padding = UDim.new(0, 8)
supportLayout.Parent = supportList

local function renderMonetization(state)
    for _, child in ipairs(supportList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local enabled = state and state.enabled == true
    supportButton:SetAttribute("MonetizationEnabled", enabled)
    supportButton.Visible = enabled
        and player:GetAttribute("DataPersistenceAvailable") == true
        and not metaControlsSuppressed
    if not enabled then
        supportPanel.Visible = false
        return
    end

    supportFairPlay.Text = CoreLocalization.text(localeId, "FAIR_PLAY")

    for _, offer in ipairs(state.offers or {}) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 62)
        button.BackgroundColor3 = offer.owned
            and UITheme.Colors.Green:Lerp(UITheme.Colors.Panel, 0.60)
            or UITheme.Colors.Violet:Lerp(UITheme.Colors.Panel, 0.62)
        button.BackgroundTransparency = 0.04
        button.BorderSizePixel = 0
        button.TextColor3 = UITheme.Colors.Text
        button.Font = Enum.Font.GothamBold
        button.TextScaled = true
        button.TextWrapped = true
        local itemCount = math.max(1, math.floor(tonumber(offer.itemCount) or 1))
        local tagline = tostring(
            offer.tagline
                or CoreLocalization.text(localeId, "COSMETICS_PERMANENT", itemCount)
        )
        button.Text = offer.owned
            and string.format(
                "%s\n%s • %s",
                offer.name or CoreLocalization.text(localeId, "SUPPORT_PACK"),
                tagline,
                CoreLocalization.text(localeId, "OWNED")
            )
            or string.format(
                "%s\n%s • %d ROBUX",
                offer.name or CoreLocalization.text(localeId, "SUPPORT_PACK"),
                tagline,
                offer.price or 0
            )
        button.Parent = supportList
        UITheme.addCorner(button, UITheme.Corners.Small)
        UITheme.addStroke(
            button,
            offer.owned and UITheme.Colors.Green or UITheme.Colors.Violet,
            1.1,
            0.40
        )
        UITheme.addPressFeedback(button, 0.975)

        button.Activated:Connect(function()
            if not offer.owned then
                monetizationActionEvent:FireServer("buy_pass", offer.key)
            end
        end)
    end
end


local achievementButton = Instance.new("TextButton")
achievementButton.Name = "AchievementButton"
achievementButton.AnchorPoint = Vector2.new(0.5, 1)
achievementButton.Position = UDim2.fromScale(0.5, touchDevice and 0.88 or 0.90)
achievementButton.Size = UDim2.fromScale(touchDevice and 0.27 or 0.30, touchDevice and 0.055 or 0.065)
achievementButton.BackgroundColor3 = UITheme.Colors.PanelRaised
achievementButton.BackgroundTransparency = 0.04
achievementButton.BorderSizePixel = 0
achievementButton.TextColor3 = UITheme.Colors.Text
achievementButton.Font = Enum.Font.GothamBold
achievementButton.TextScaled = true
achievementButton.Text = CoreLocalization.text(localeId, "ACHIEVEMENTS")
achievementButton.Parent = root
UITheme.addCorner(achievementButton, UITheme.Corners.Medium)
UITheme.addStroke(achievementButton, UITheme.Colors.Gold, 1.2, 0.38)
UITheme.addGradient(achievementButton, UITheme.Colors.PanelRaised, UITheme.Colors.PanelSoft, 90)
UITheme.addPressFeedback(achievementButton, 0.95)



local achievementPanel = Instance.new("Frame")
achievementPanel.Name = "AchievementPanel"
achievementPanel.AnchorPoint = Vector2.new(0.5, 1)
achievementPanel.Position = UDim2.fromScale(0.5, 0.82)
achievementPanel.Size = UDim2.fromScale(0.82, 0.46)
achievementPanel.BackgroundColor3 = UITheme.Colors.Panel
achievementPanel.BackgroundTransparency = 0.02
achievementPanel.BorderSizePixel = 0
achievementPanel.Visible = false
achievementPanel.Parent = root
UITheme.addCorner(achievementPanel, UITheme.Corners.Large)
UITheme.addStroke(achievementPanel, UITheme.Colors.Gold, 1.2, 0.38)
UITheme.addGradient(achievementPanel, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local achievementPanelConstraint = Instance.new("UISizeConstraint")
achievementPanelConstraint.MinSize = Vector2.new(280, 250)
achievementPanelConstraint.MaxSize = Vector2.new(700, 430)
achievementPanelConstraint.Parent = achievementPanel

local achievementHeader = Instance.new("TextLabel")
achievementHeader.Size = UDim2.new(1, -24, 0, 42)
achievementHeader.Position = UDim2.fromOffset(12, 6)
achievementHeader.BackgroundTransparency = 1
achievementHeader.Font = Enum.Font.GothamBlack
achievementHeader.TextColor3 = Color3.new(1, 1, 1)
achievementHeader.TextScaled = true
achievementHeader.TextXAlignment = Enum.TextXAlignment.Left
achievementHeader.Text = CoreLocalization.text(localeId, "ACHIEVEMENTS")
achievementHeader.Parent = achievementPanel

local achievementList = Instance.new("ScrollingFrame")
achievementList.Size = UDim2.new(1, -24, 1, -58)
achievementList.Position = UDim2.fromOffset(12, 50)
achievementList.BackgroundTransparency = 1
achievementList.BorderSizePixel = 0
achievementList.ScrollBarThickness = 5
achievementList.CanvasSize = UDim2.fromOffset(0, 0)
achievementList.AutomaticCanvasSize = Enum.AutomaticSize.Y
achievementList.Parent = achievementPanel

local achievementLayout = Instance.new("UIListLayout")
achievementLayout.Padding = UDim.new(0, 8)
achievementLayout.Parent = achievementList

local achievementToast = Instance.new("Frame")
achievementToast.AnchorPoint = Vector2.new(0.5, 0.5)
achievementToast.Position = UDim2.fromScale(0.5, 0.50)
achievementToast.Size = UDim2.fromScale(0.78, 0.16)
achievementToast.BackgroundColor3 = UITheme.Colors.Panel
achievementToast.BackgroundTransparency = 0.02
achievementToast.BorderSizePixel = 0
achievementToast.Visible = false
achievementToast.Parent = root
UITheme.addCorner(achievementToast, UITheme.Corners.Large)
UITheme.addStroke(achievementToast, UITheme.Colors.Gold, 1.4, 0.24)
UITheme.addGradient(achievementToast, Color3.fromRGB(74, 58, 24), UITheme.Colors.Panel, 90)

local achievementToastTitle = Instance.new("TextLabel")
achievementToastTitle.Size = UDim2.new(1, -24, 0.48, 0)
achievementToastTitle.Position = UDim2.fromOffset(12, 8)
achievementToastTitle.BackgroundTransparency = 1
achievementToastTitle.Font = Enum.Font.GothamBlack
achievementToastTitle.TextColor3 = Color3.new(1, 1, 1)
achievementToastTitle.TextScaled = true
achievementToastTitle.Text = "ACHIEVEMENT UNLOCKED"
achievementToastTitle.Parent = achievementToast

local achievementToastBody = Instance.new("TextLabel")
achievementToastBody.Size = UDim2.new(1, -24, 0.34, 0)
achievementToastBody.Position = UDim2.new(0, 12, 0.56, 0)
achievementToastBody.BackgroundTransparency = 1
achievementToastBody.Font = Enum.Font.GothamMedium
achievementToastBody.TextColor3 = Color3.fromRGB(245, 235, 205)
achievementToastBody.TextScaled = true
achievementToastBody.Text = ""
achievementToastBody.Parent = achievementToast

local function renderAchievements(state)
    for _, child in ipairs(achievementList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local items = state and state.achievements or {}
    for _, item in ipairs(items) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 0, 76)
        row.BackgroundColor3 = item.unlocked
            and UITheme.Colors.Green:Lerp(UITheme.Colors.Panel, 0.68)
            or UITheme.Colors.PanelSoft
        row.BackgroundTransparency = 0.06
        row.BorderSizePixel = 0
        row.Parent = achievementList
        UITheme.addCorner(row, UITheme.Corners.Small)
        UITheme.addStroke(
            row,
            item.unlocked and UITheme.Colors.Gold or UITheme.Colors.Border,
            item.unlocked and 1.5 or 1,
            item.unlocked and 0.30 or 0.62
        )
        UITheme.addGradient(
            row,
            item.unlocked and UITheme.Colors.Green:Lerp(UITheme.Colors.Panel, 0.58) or UITheme.Colors.PanelSoft,
            UITheme.Colors.Panel,
            90
        )

        local unlockRail = Instance.new("Frame")
        unlockRail.Size = UDim2.new(0, 4, 0.72, 0)
        unlockRail.Position = UDim2.fromScale(0.015, 0.14)
        unlockRail.BackgroundColor3 = item.unlocked and UITheme.Colors.Gold or UITheme.Colors.Border
        unlockRail.BorderSizePixel = 0
        unlockRail.Parent = row
        UITheme.addCorner(unlockRail, UITheme.Corners.Pill)

        local rowTitle = Instance.new("TextLabel")
        rowTitle.Size = UDim2.new(1, -32, 0.42, 0)
        rowTitle.Position = UDim2.fromOffset(20, 5)
        rowTitle.BackgroundTransparency = 1
        rowTitle.Font = Enum.Font.GothamBold
        rowTitle.TextColor3 = UITheme.Colors.Text
        rowTitle.TextScaled = true
        rowTitle.TextXAlignment = Enum.TextXAlignment.Left
        rowTitle.Text = CoreLocalization.achievementTitle(
            localeId,
            item.id,
            item.title or CoreLocalization.text(localeId, "ACHIEVEMENTS")
        )
        rowTitle.Parent = row

        local rowBody = Instance.new("TextLabel")
        rowBody.Size = UDim2.new(1, -32, 0.40, 0)
        rowBody.Position = UDim2.new(0, 20, 0.50, 0)
        rowBody.BackgroundTransparency = 1
        rowBody.Font = Enum.Font.GothamMedium
        rowBody.TextColor3 = item.unlocked and Color3.fromRGB(220, 245, 225) or UITheme.Colors.Muted
        rowBody.TextScaled = true
        rowBody.TextXAlignment = Enum.TextXAlignment.Left

        local status = item.unlocked
            and CoreLocalization.text(localeId, "DONE")
            or string.format("%d/%d", item.progress or 0, item.target or 0)
        local description = CoreLocalization.achievementDescription(
            localeId,
            item.id,
            item.description or ""
        )
        rowBody.Text = CoreLocalization.text(
            localeId,
            "ACHIEVEMENT_ROW",
            description,
            status,
            item.coins or 0
        )
        rowBody.Parent = row
    end
end

local metaDock = nil
if touchDevice then
    metaDock = Instance.new("Frame")
    metaDock.Name = "MetaDock"
    metaDock.AnchorPoint = Vector2.new(0.5, 1)
    metaDock.Position = UDim2.fromScale(0.5, 0.965)
    metaDock.Size = UDim2.fromScale(0.94, 0.060)
    metaDock.BackgroundColor3 = UITheme.Colors.Panel
    metaDock.BackgroundTransparency = 0.12
    metaDock.BorderSizePixel = 0
    metaDock.Visible = false
    metaDock.Parent = root
    UITheme.addCorner(metaDock, UITheme.Corners.Large)
    UITheme.addStroke(metaDock, UITheme.Colors.Cyan, 1, 0.72)

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0.012, 0)
    layout.Parent = metaDock

    questButton.AnchorPoint = Vector2.zero
    achievementButton.AnchorPoint = Vector2.zero
    cosmeticsButton.AnchorPoint = Vector2.zero
    supportButton.AnchorPoint = Vector2.zero

    questButton.Position = UDim2.fromScale(0, 0)
    achievementButton.Position = UDim2.fromScale(0, 0)
    cosmeticsButton.Position = UDim2.fromScale(0, 0)
    supportButton.Position = UDim2.fromScale(0, 0)

    questButton.Size = UDim2.new(0.225, 0, 0.82, 0)
    achievementButton.Size = UDim2.new(0.225, 0, 0.82, 0)
    cosmeticsButton.Size = UDim2.new(0.225, 0, 0.82, 0)
    supportButton.Size = UDim2.new(0.225, 0, 0.82, 0)

    questButton.Text = CoreLocalization.text(localeId, "QUESTS")
    achievementButton.Text = CoreLocalization.text(localeId, "AWARDS")
    cosmeticsButton.Text = CoreLocalization.text(localeId, "STYLE")
    supportButton.Text = CoreLocalization.text(localeId, "SUPPORT")

    questButton.Parent = metaDock
    achievementButton.Parent = metaDock
    cosmeticsButton.Parent = metaDock
    supportButton.Parent = metaDock
end

local panelScales = {}
for _, panel in ipairs({questPanel, cosmeticsPanel, achievementPanel, supportPanel}) do
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = panel
    panelScales[panel] = scale
end

local cameraViewportConnection = nil

local function applyResponsivePanelConstraints()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local class = UIResponsive.classify(viewport, touchDevice)

    if class.touch and class.tinyHeight then
        questPanelConstraint.MinSize = Vector2.new(220, 172)
        cosmeticsPanelConstraint.MinSize = Vector2.new(220, 160)
        achievementPanelConstraint.MinSize = Vector2.new(225, 172)
        supportPanelConstraint.MinSize = Vector2.new(220, 150)
    elseif class.touch and class.compactHeight then
        questPanelConstraint.MinSize = Vector2.new(220, 195)
        cosmeticsPanelConstraint.MinSize = Vector2.new(220, 180)
        achievementPanelConstraint.MinSize = Vector2.new(225, 195)
        supportPanelConstraint.MinSize = Vector2.new(220, 165)
    else
        questPanelConstraint.MinSize = Vector2.new(260, 250)
        cosmeticsPanelConstraint.MinSize = Vector2.new(270, 220)
        achievementPanelConstraint.MinSize = Vector2.new(280, 250)
        supportPanelConstraint.MinSize = Vector2.new(270, 190)
    end
end

local function bindViewportSizing()
    if cameraViewportConnection then
        cameraViewportConnection:Disconnect()
        cameraViewportConnection = nil
    end

    local camera = workspace.CurrentCamera
    if camera then
        cameraViewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsivePanelConstraints)
    end
    applyResponsivePanelConstraints()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewportSizing)
bindViewportSizing()

local function closeAllPanels()
    questPanel.Visible = false
    cosmeticsPanel.Visible = false
    achievementPanel.Visible = false
    supportPanel.Visible = false
end

local function openExclusive(panel)
    local opening = not panel.Visible
    closeAllPanels()

    if opening then
        local scale = panelScales[panel]
        panel.Visible = true
        scale.Scale = 0.92
        TweenService:Create(
            scale,
            UITheme.Motion.PanelIn,
            {Scale = 1}
        ):Play()
    end

    return opening
end

questButton.Activated:Connect(function()
    openExclusive(questPanel)
end)

cosmeticsButton.Activated:Connect(function()
    if openExclusive(cosmeticsPanel) then
        cosmeticActionEvent:FireServer("sync")
    end
end)

achievementButton.Activated:Connect(function()
    openExclusive(achievementPanel)
end)

supportButton.Activated:Connect(function()
    if openExclusive(supportPanel) then
        monetizationActionEvent:FireServer("sync")
    end
end)



local dataWarning = Instance.new("TextLabel")
dataWarning.AnchorPoint = Vector2.new(0.5, 0)
dataWarning.Position = UDim2.fromScale(0.5, 0.17)
dataWarning.Size = UDim2.fromScale(0.78, 0.055)
dataWarning.BackgroundColor3 = Color3.fromRGB(115, 50, 35)
dataWarning.BackgroundTransparency = 0.08
dataWarning.Font = Enum.Font.GothamBold
dataWarning.TextColor3 = Color3.new(1, 1, 1)
dataWarning.TextScaled = true
dataWarning.TextWrapped = true
dataWarning.Visible = false
dataWarning.Text = ""
dataWarning.ZIndex = 15
dataWarning.Parent = root
UITheme.addTextConstraint(dataWarning, 12, 18)
Instance.new("UICorner", dataWarning).CornerRadius = UDim.new(0, 12)

local function refreshDataStatus()
    if player:GetAttribute("DataLoaded") ~= true then
        dataWarning.Visible = false
        return
    end

    if player:GetAttribute("DataSaveConflict") == true then
        dataWarning.Text = CoreLocalization.text(localeId, "DATA_CONFLICT_WARNING")
        dataWarning.Visible = true
    elseif player:GetAttribute("DataPersistenceAvailable") ~= true then
        dataWarning.Text = CoreLocalization.text(localeId, "DATA_TEMPORARY_WARNING")
        dataWarning.Visible = true
    elseif player:GetAttribute("LastSaveFailed") == true then
        dataWarning.Text = CoreLocalization.text(localeId, "DATA_SAVE_DELAYED_WARNING")
        dataWarning.Visible = true
    else
        dataWarning.Visible = false
    end
end

for _, attr in ipairs({"DataLoaded", "DataPersistenceAvailable", "DataSaveConflict", "LastSaveFailed"}) do
    player:GetAttributeChangedSignal(attr):Connect(refreshDataStatus)
end
refreshDataStatus()

local resultFlash = Instance.new("Frame")
resultFlash.Size = UDim2.fromScale(1, 1)
resultFlash.BackgroundColor3 = Color3.new(1, 1, 1)
resultFlash.BackgroundTransparency = 1
resultFlash.BorderSizePixel = 0
resultFlash.ZIndex = 20
resultFlash.Parent = root

local resultCard = Instance.new("Frame")
resultCard.Name = "ResultCard"
resultCard.AnchorPoint = Vector2.new(0.5, 0.5)
resultCard.Position = UDim2.fromScale(0.5, 0.54)
resultCard.Size = UDim2.fromScale(0.80, 0.29)
resultCard.BackgroundColor3 = UITheme.Colors.Panel
resultCard.BackgroundTransparency = 1
resultCard.BorderSizePixel = 0
resultCard.Visible = false
resultCard.ZIndex = 21
resultCard.Parent = root
UITheme.addCorner(resultCard, UDim.new(0, 22))
local resultStroke = UITheme.addStroke(resultCard, UITheme.Colors.Blue, 1.6, 0.24)
local resultGradient = UITheme.addGradient(resultCard, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local resultAccent = Instance.new("Frame")
resultAccent.AnchorPoint = Vector2.new(0.5, 0)
resultAccent.Position = UDim2.fromScale(0.5, 0.035)
resultAccent.Size = UDim2.new(0.88, 0, 0, 5)
resultAccent.BackgroundColor3 = UITheme.Colors.Blue
resultAccent.BorderSizePixel = 0
resultAccent.ZIndex = 22
resultAccent.Parent = resultCard
UITheme.addCorner(resultAccent, UITheme.Corners.Pill)

local resultScale = Instance.new("UIScale")
resultScale.Scale = 0.82
resultScale.Parent = resultCard

local resultTitle = Instance.new("TextLabel")
resultTitle.Size = UDim2.new(1, -28, 0.34, 0)
resultTitle.Position = UDim2.fromOffset(14, 10)
resultTitle.BackgroundTransparency = 1
resultTitle.Font = Enum.Font.GothamBlack
resultTitle.TextColor3 = UITheme.Colors.Text
resultTitle.TextScaled = true
resultTitle.ZIndex = 22
resultTitle.Text = "ROUND COMPLETE"
resultTitle.Parent = resultCard

local resultReward = Instance.new("TextLabel")
resultReward.Size = UDim2.new(1, -28, 0.24, 0)
resultReward.Position = UDim2.new(0, 14, 0.40, 0)
resultReward.BackgroundTransparency = 1
resultReward.Font = Enum.Font.GothamBold
resultReward.TextColor3 = UITheme.Colors.Gold
resultReward.TextScaled = true
resultReward.TextWrapped = true
resultReward.ZIndex = 22
resultReward.Text = ""
resultReward.Parent = resultCard

local resultMeta = Instance.new("TextLabel")
resultMeta.Size = UDim2.new(1, -28, 0.20, 0)
resultMeta.Position = UDim2.new(0, 14, 0.62, 0)
resultMeta.BackgroundTransparency = 1
resultMeta.Font = Enum.Font.GothamMedium
resultMeta.TextColor3 = UITheme.Colors.Muted
resultMeta.TextScaled = true
resultMeta.TextWrapped = true
resultMeta.ZIndex = 22
resultMeta.Text = ""
resultMeta.Parent = resultCard

local resultTip = Instance.new("TextLabel")
resultTip.Size = UDim2.new(1, -28, 0.10, 0)
resultTip.Position = UDim2.new(0, 14, 0.78, 0)
resultTip.BackgroundTransparency = 1
resultTip.Font = Enum.Font.GothamMedium
resultTip.TextColor3 = UITheme.Colors.Muted
resultTip.TextScaled = true
resultTip.TextWrapped = true
resultTip.ZIndex = 22
resultTip.Text = ""
resultTip.Parent = resultCard

local resultNext = Instance.new("TextLabel")
resultNext.Name = "NextRoundCountdown"
resultNext.Size = UDim2.new(1, -28, 0.075, 0)
resultNext.Position = UDim2.new(0, 14, 0.90, 0)
resultNext.BackgroundTransparency = 1
resultNext.Font = Enum.Font.GothamBold
resultNext.TextColor3 = UITheme.Colors.Cyan
resultNext.TextScaled = true
resultNext.Text = ""
resultNext.ZIndex = 22
resultNext.Parent = resultCard
UITheme.addTextConstraint(resultNext, 10, 15)

local function applyResponsiveLayout()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

    if not touchDevice then
        top.Position = UDim2.fromScale(0.5, 0.025)
        top.Size = UDim2.fromScale(0.88, 0.13)
        timer.Size = UDim2.fromOffset(70, 70)
        votes.Position = UDim2.fromScale(0.5, 0.58)
        votes.Size = UDim2.fromScale(0.88, 0.24)
        stats.Position = UDim2.fromScale(0.5, 0.975)
        stats.Size = UDim2.fromScale(0.65, 0.07)
        xpTrack.Position = UDim2.fromScale(0.5, 0.94)
        xpTrack.Size = UDim2.fromScale(0.62, 0.012)
        resultCard.Size = UDim2.fromScale(0.80, 0.31)
        dataWarning.Position = UDim2.fromScale(0.5, 0.17)
        dataWarning.Size = UDim2.fromScale(0.78, 0.055)
        questPanel.Size = UDim2.fromScale(0.72, 0.46)
        cosmeticsPanel.Size = UDim2.fromScale(0.72, 0.36)
        achievementPanel.Size = UDim2.fromScale(0.82, 0.46)
        supportPanel.Size = UDim2.fromScale(0.72, 0.30)
        return
    end

    local profile = UIResponsive.mobileProfile(viewport)
    local panelHeight = math.max(
        170,
        math.min(
            320,
            viewport.Y - profile.topHeight - profile.dockHeight - 38
        )
    )

    top.Position = UDim2.new(0.5, 0, 0, 7)
    top.Size = UDim2.new(profile.topWidthScale, 0, 0, profile.topHeight)
    timer.Size = UDim2.fromOffset(profile.timerSize, profile.timerSize)
    timer.Position = UDim2.new(1, -8, 0.5, 0)
    aliveCounter.Size = UDim2.fromOffset(math.max(88, profile.timerSize + 36), 24)
    aliveCounter.Position = UDim2.new(1, -8, 1, 5)

    if compactRoundTop then
        title.Position = UDim2.new(0, 14, 0.14, 0)
        title.Size = UDim2.new(1, -(profile.timerSize + 32), 0.70, 0)
        hint.Visible = false
    else
        title.Position = UDim2.fromOffset(14, 4)
        title.Size = UDim2.new(1, -(profile.timerSize + 32), 0.56, 0)
        hint.Position = UDim2.new(0, 14, 0.60, 0)
        hint.Size = UDim2.new(1, -(profile.timerSize + 40), 0.32, 0)
        hint.Visible = true
    end

    votes.Position = UDim2.fromScale(0.5, profile.voteHeight <= 140 and 0.49 or 0.54)
    votes.Size = UDim2.new(profile.voteWidthScale, 0, 0, profile.voteHeight)

    rookieCoach.Size = UDim2.new(profile.coachWidthScale, 0, 0, profile.coachHeight)
    countdownCard.Size = UDim2.new(
        profile.wide and 0.44 or (profile.veryNarrow and 0.72 or 0.56),
        0,
        0,
        profile.tinyHeight and 104 or 122
    )
    countdownCard.Position = UDim2.fromScale(0.5, profile.tinyHeight and 0.46 or 0.44)

    if metaDock then
        metaDock.Position = UDim2.new(0.5, 0, 1, -8)
        metaDock.Size = UDim2.new(profile.dockWidthScale, 0, 0, profile.dockHeight)

        questButton.Size = UDim2.new(0.225, 0, 0, profile.dockButtonHeight)
        achievementButton.Size = UDim2.new(0.225, 0, 0, profile.dockButtonHeight)
        cosmeticsButton.Size = UDim2.new(0.225, 0, 0, profile.dockButtonHeight)
        supportButton.Size = UDim2.new(0.225, 0, 0, profile.dockButtonHeight)
    end

    local dockVisible = metaDock and metaDock.Visible
    local statsBottom = dockVisible and (profile.dockHeight + 18) or 10
    stats.Position = UDim2.new(0.5, 0, 1, -statsBottom)
    stats.Size = UDim2.new(profile.narrowWidth and 0.82 or 0.72, 0, 0, 34)
    xpTrack.Position = UDim2.new(0.5, 0, 1, -(statsBottom + 39))
    xpTrack.Size = UDim2.new(profile.narrowWidth and 0.78 or 0.68, 0, 0, 5)

    resultCard.Size = UDim2.new(
        profile.resultWidthScale,
        0,
        0,
        profile.resultHeight
    )

    dailyToast.Size = UDim2.new(profile.toastWidthScale, 0, 0, 92)
    questToast.Size = UDim2.new(profile.toastWidthScale, 0, 0, 88)
    achievementToast.Size = UDim2.new(profile.toastWidthScale, 0, 0, 92)

    dataWarning.Position = UDim2.new(0.5, 0, 0, profile.topHeight + 52)
    dataWarning.Size = UDim2.new(profile.toastWidthScale, 0, 0, 34)

    local panelBottom = profile.panelBottomOffset
    questPanel.Position = UDim2.new(0.025, 0, 1, -panelBottom)
    questPanel.Size = UDim2.new(profile.panelWidthScale, 0, 0, panelHeight)

    cosmeticsPanel.Position = UDim2.new(0.975, 0, 1, -panelBottom)
    cosmeticsPanel.Size = UDim2.new(
        profile.panelWidthScale,
        0,
        0,
        math.max(160, panelHeight - 26)
    )

    achievementPanel.Position = UDim2.new(0.5, 0, 1, -panelBottom)
    achievementPanel.Size = UDim2.new(profile.panelWidthScale, 0, 0, panelHeight)

    supportPanel.Position = UDim2.new(0.975, 0, 1, -panelBottom)
    supportPanel.Size = UDim2.new(
        profile.panelWidthScale,
        0,
        0,
        math.max(150, math.min(220, panelHeight - 36))
    )
end
applyResponsiveLayout()

local responsiveCamera = workspace.CurrentCamera
local responsiveViewportConnection = nil

local function bindResponsiveCamera()
    if responsiveViewportConnection then
        responsiveViewportConnection:Disconnect()
        responsiveViewportConnection = nil
    end

    responsiveCamera = workspace.CurrentCamera
    if responsiveCamera then
        responsiveViewportConnection = responsiveCamera
            :GetPropertyChangedSignal("ViewportSize")
            :Connect(applyResponsiveLayout)
    end
    applyResponsiveLayout()
end

bindResponsiveCamera()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindResponsiveCamera)

local resultToken = 0
local lastRoundHint = ""

local function dismissResultCard()
    if not resultCard.Visible then
        return
    end

    resultToken += 1
    local token = resultToken
    TweenService:Create(
        resultCard,
        UITheme.Motion.StandardFade,
        {BackgroundTransparency = 1}
    ):Play()
    TweenService:Create(
        resultScale,
        UITheme.Motion.StandardFade,
        {Scale = 0.90}
    ):Play()

    task.delay(0.25, function()
        if token == resultToken then
            resultCard.Visible = false
        end
    end)
end

local function masteryProgressText(state, name)
    if type(state) ~= "table" or not name then
        return nil
    end

    local tier = tostring(state.tier or "ROOKIE")
    if state.maxed == true then
        return string.format("%s %s MAX", tostring(name), tier)
    end

    local nextTier = tostring(state.nextTier or "NEXT")
    local points = math.max(0, math.floor(tonumber(state.points) or 0))
    local nextPoints = math.max(points, math.floor(tonumber(state.nextPoints) or points))
    return string.format(
        "%s %s %d/%d",
        tostring(name),
        nextTier,
        points,
        nextPoints
    )
end

local function masteryGoalText(feedback)
    local arenaName = feedback and CoreLocalization.arenaName(
        localeId,
        feedback.arenaId or feedback.arenaMasteryName,
        feedback.arenaMasteryName
    )
    local primaryDisasterId = feedback
        and type(feedback.disasterIds) == "table"
        and feedback.disasterIds[1]
        or nil
    local disasterName = feedback and (
        CoreLocalization.hazardName(localeId, primaryDisasterId)
        or feedback.disasterMasteryName
    )

    local arenaText = masteryProgressText(
        feedback and feedback.arenaMastery,
        arenaName
    )
    local disasterText = masteryProgressText(
        feedback and feedback.disasterMastery,
        disasterName
    )
    local masteryLabel = CoreLocalization.text(localeId, "RESULT_MASTERY")

    if arenaText and disasterText then
        return masteryLabel .. " • " .. arenaText .. " • " .. disasterText
    elseif arenaText or disasterText then
        return masteryLabel .. " • " .. tostring(arenaText or disasterText)
    end
    return nil
end

local function nextLevelGoalText()
    local level = math.max(1, math.floor(tonumber(player:GetAttribute("Level")) or 1))
    local xp = math.max(0, math.floor(tonumber(player:GetAttribute("XP")) or 0))
    local _, nextXP = xpProgressForLevel(level, xp)
    local remaining = math.max(0, math.floor(nextXP - xp))

    if remaining <= 0 then
        return CoreLocalization.text(localeId, "RESULT_NEXT_GOAL_READY", level + 1)
    end

    return CoreLocalization.text(
        localeId,
        "RESULT_NEXT_GOAL",
        level + 1,
        remaining
    )
end

local function showRoundFeedback(feedback)
    resultToken += 1
    local token = resultToken

    local survived = feedback.survived == true
    local momentumBest = math.max(0, math.floor(tonumber(feedback.momentumBest) or 0))
    local masterRound = survived and feedback.challengeCompleted == true and momentumBest >= 4

    local resultKind = ResultPresentation.kind(feedback)
    resultTitle.Text = ResultPresentation.title(feedback, localeId)
    resultStroke.Color = resultKind == "master"
        and UITheme.Colors.Gold
        or (resultKind == "clutch"
            and UITheme.Colors.Cyan
            or (survived and UITheme.Colors.Green or UITheme.Colors.Red))
    resultAccent.BackgroundColor3 = resultKind == "master"
        and UITheme.Colors.Cyan
        or (resultKind == "clutch"
            and UITheme.Colors.Blue
            or (survived and UITheme.Colors.Green or UITheme.Colors.Red))
    resultGradient.Color = resultKind == "master"
        and ColorSequence.new(Color3.fromRGB(35, 73, 82), Color3.fromRGB(45, 34, 18))
        or (resultKind == "clutch"
            and ColorSequence.new(Color3.fromRGB(24, 60, 78), Color3.fromRGB(18, 38, 48))
            or (survived
                and ColorSequence.new(Color3.fromRGB(24, 67, 50), UITheme.Colors.Panel)
                or ColorSequence.new(Color3.fromRGB(76, 31, 36), UITheme.Colors.Panel)))

    local streakBonus = tonumber(feedback.streakBonusCoins) or 0
    local shardCoins = tonumber(feedback.shardCoins) or 0
    local challengeCoins = tonumber(feedback.challengeCoins) or 0
    local challengeXP = tonumber(feedback.challengeXP) or 0
    local flowCoins = tonumber(feedback.flowCoins) or 0
    local fusionBonusCoins = tonumber(feedback.fusionBonusCoins) or 0
    local shownCoins = (tonumber(feedback.coins) or 0) + shardCoins + challengeCoins + flowCoins
    local shownXP = (tonumber(feedback.xp) or 0) + challengeXP

    local extras = {}
    if streakBonus > 0 then
        table.insert(extras, CoreLocalization.text(localeId, "RESULT_EXTRA_STREAK", streakBonus))
    end
    if shardCoins > 0 then
        table.insert(extras, CoreLocalization.text(localeId, "RESULT_EXTRA_SHARDS", shardCoins))
    end
    if feedback.challengeCompleted then
        table.insert(extras, CoreLocalization.text(localeId, "RESULT_EXTRA_CHALLENGE", challengeCoins))
    end
    if flowCoins > 0 then
        table.insert(extras, CoreLocalization.text(localeId, "RESULT_EXTRA_FLOW", flowCoins))
    end
    if fusionBonusCoins > 0 then
        table.insert(extras, CoreLocalization.text(localeId, "RESULT_EXTRA_FUSION", fusionBonusCoins))
    end

    resultReward.Text = CoreLocalization.text(localeId, "COINS_XP", shownCoins, shownXP)
    resultNext.Text = CoreLocalization.text(localeId, "NEXT_CHAOS_SOON")
    if #extras > 0 and not touchDevice then
        resultReward.Text ..= "   •   " .. table.concat(extras, "   •   ")
    end

    local tags = {}
    table.insert(
        tags,
        tostring(
            CoreLocalization.arenaName(
                localeId,
                feedback.arenaName,
                feedback.arenaName or "ARENA"
            )
        )
    )
    local localizedDisasterName = CoreLocalization.hazardTitle(
        localeId,
        feedback.disasterIds,
        feedback.disasterName or "CHAOS"
    )
    table.insert(tags, tostring(localizedDisasterName))
    if feedback.doubleChaos then
        table.insert(
            tags,
            feedback.fusionName
                and (CoreLocalization.text(localeId, "CHAOS_FUSION") .. ": " .. tostring(feedback.fusionName))
                or CoreLocalization.text(localeId, "CHAOS_FUSION")
        )
    end
    if feedback.soloMode then table.insert(tags, CoreLocalization.text(localeId, "RESULT_RUSH_BONUS")) end
    if feedback.criticalSurvival then
        table.insert(tags, CoreLocalization.text(localeId, "RESULT_CLUTCH_TAG"))
    end
    if feedback.challengeCompleted then
        table.insert(tags, CoreLocalization.text(localeId, "RESULT_CHALLENGE_TAG"))
    elseif feedback.challengeTitle then
        table.insert(
            tags,
            string.format(
                "%s %d/%d",
                tostring(
                    CoreLocalization.challengeShort(
                        localeId,
                        feedback.challengeId,
                        feedback.challengeTitle
                    )
                ),
                tonumber(feedback.challengeProgress) or 0,
                tonumber(feedback.challengeTarget) or 1
            )
        )
    end
    local shardCount = math.max(0, math.floor(tonumber(feedback.shardCount) or 0))
    if shardCount > 0 then
        table.insert(tags, CoreLocalization.text(localeId, "RESULT_SHARDS_TAG", shardCount))
    end
    local nearMissCount = math.max(0, math.floor(tonumber(feedback.nearMissCount) or 0))
    if nearMissCount > 0 then
        table.insert(tags, CoreLocalization.text(localeId, "RESULT_CLOSE_CALLS_TAG", nearMissCount))
    end
    if momentumBest >= 2 then
        table.insert(tags, CoreLocalization.text(localeId, "RESULT_MOMENTUM_TAG", momentumBest))
    end

    local medals = type(feedback.medals) == "table" and feedback.medals or {}
    local localizedMedals = {}
    for _, medal in ipairs(medals) do
        table.insert(localizedMedals, CoreLocalization.medal(localeId, medal))
    end
    if #medals > 0 then
        table.insert(tags, CoreLocalization.text(localeId, "RESULT_MEDALS_TAG", #medals))
    end

    local streakCount = tonumber(feedback.streak) or 0
    if survived and streakCount >= 2 then
        table.insert(tags, CoreLocalization.text(localeId, "RESULT_STREAK_TAG", streakCount))
    end

    local crewRounds = math.max(0, math.floor(tonumber(feedback.crewRounds) or 0))
    if crewRounds >= 1 then
        table.insert(tags, CoreLocalization.text(localeId, "RESULT_CREW_ROUNDS", crewRounds))
    end
    local arenaMastery = feedback.arenaMastery
    if type(arenaMastery) == "table" and feedback.arenaMasteryName then
        table.insert(
            tags,
            string.upper(tostring(CoreLocalization.arenaName(
                localeId,
                feedback.arenaId or feedback.arenaMasteryName,
                feedback.arenaMasteryName
            )))
                .. " "
                .. tostring(arenaMastery.tier or "ROOKIE")
        )
    end
    local disasterMastery = feedback.disasterMastery
    if type(disasterMastery) == "table" and feedback.disasterMasteryName then
        table.insert(
            tags,
            string.upper(tostring(
                CoreLocalization.hazardName(
                    localeId,
                    type(feedback.disasterIds) == "table" and feedback.disasterIds[1] or nil
                ) or feedback.disasterMasteryName
            ))
                .. " "
                .. tostring(disasterMastery.tier or "ROOKIE")
        )
    end
    table.insert(tags, tostring(feedback.elapsedSeconds or 0) .. "s")

    if touchDevice then
        local compactTags = {
            tostring(CoreLocalization.arenaName(
                localeId,
                feedback.arenaId or feedback.arenaName,
                feedback.arenaName or "ARENA"
            )),
            tostring(localizedDisasterName),
        }

        if feedback.challengeCompleted then
            table.insert(compactTags, CoreLocalization.text(localeId, "RESULT_CHALLENGE_TAG"))
        elseif feedback.criticalSurvival then
            table.insert(compactTags, CoreLocalization.text(localeId, "RESULT_CLUTCH_TAG"))
        elseif survived and streakCount >= 2 then
            table.insert(compactTags, CoreLocalization.text(localeId, "RESULT_STREAK_TAG", streakCount))
        elseif crewRounds >= 1 then
            table.insert(compactTags, CoreLocalization.text(localeId, "RESULT_CREW_ROUNDS", crewRounds))
        elseif shardCount > 0 then
            table.insert(compactTags, CoreLocalization.text(localeId, "RESULT_SHARDS_TAG", shardCount))
        end

        table.insert(compactTags, tostring(feedback.elapsedSeconds or 0) .. "s")
        tags = compactTags
    end

    resultMeta.Text = table.concat(tags, "  •  ")

    local firstChaos = false
    for _, medal in ipairs(medals) do
        if medal == "FIRST CHAOS" then
            firstChaos = true
            break
        end
    end

    if not survived then
        local _, eliminationTip = ResultPresentation.eliminationCopy(feedback, localeId)
        resultTip.Text = CoreLocalization.text(localeId, "RESULT_NEXT_TRY", eliminationTip)
    elseif firstChaos then
        resultTip.Text = CoreLocalization.text(localeId, "RESULT_FIRST_CHAOS")
    elseif masterRound then
        resultTip.Text = CoreLocalization.text(localeId, "RESULT_MASTER", momentumBest)
    elseif fusionBonusCoins > 0 and feedback.fusionName then
        resultTip.Text = CoreLocalization.text(
            localeId,
            "RESULT_FUSION_SURVIVED",
            tostring(feedback.fusionName),
            fusionBonusCoins
        )
    elseif flowCoins > 0 and feedback.challengeCompleted then
        resultTip.Text = CoreLocalization.text(localeId, "RESULT_FLOW_CHALLENGE", flowCoins)
    elseif flowCoins > 0 then
        resultTip.Text = CoreLocalization.text(localeId, "RESULT_FLOW")
    elseif feedback.challengeCompleted then
        if #medals > 0 then
            resultTip.Text = CoreLocalization.text(
                localeId,
                "RESULT_CHALLENGE_MEDALS",
                table.concat(localizedMedals, " • ")
            )
        else
            resultTip.Text = CoreLocalization.text(localeId, "RESULT_CHALLENGE")
        end
    elseif #medals > 0 then
        resultTip.Text = CoreLocalization.text(
            localeId,
            "RESULT_MEDALS",
            table.concat(localizedMedals, " • ")
        )
    elseif survived then
        if feedback.criticalSurvival then
            resultTip.Text = CoreLocalization.text(localeId, "RESULT_CLUTCH")
        elseif streakCount >= 2 then
            local nextStreakBonus = math.min(10, streakCount * 2)
            resultTip.Text = CoreLocalization.text(
                localeId,
                "RESULT_STREAK",
                streakCount,
                nextStreakBonus
            )
        else
            resultTip.Text = masteryGoalText(feedback) or nextLevelGoalText()
        end
    elseif lastRoundHint ~= "" then
        resultTip.Text = CoreLocalization.text(localeId, "RESULT_TIP", lastRoundHint)
    else
        resultTip.Text = CoreLocalization.text(localeId, "RESULT_DEFAULT_TIP")
    end

    resultCard.BackgroundColor3 = resultKind == "master"
        and Color3.fromRGB(30, 64, 69)
        or (resultKind == "clutch"
            and Color3.fromRGB(24, 58, 76)
            or (survived and Color3.fromRGB(28, 74, 53) or Color3.fromRGB(88, 35, 40)))
    resultFlash.BackgroundColor3 = resultKind == "master"
        and Color3.fromRGB(255, 220, 95)
        or (resultKind == "clutch"
            and Color3.fromRGB(85, 205, 255)
            or (survived and Color3.fromRGB(120, 255, 175) or Color3.fromRGB(255, 95, 95)))

    resultCard.Visible = true
    resultCard.BackgroundTransparency = 1
    resultScale.Scale = 0.82
    resultFlash.BackgroundTransparency = 1

    TweenService:Create(
        resultFlash,
        UITheme.Motion.FastFade,
        {BackgroundTransparency = survived and 0.78 or 0.82}
    ):Play()
    TweenService:Create(resultCard, UITheme.Motion.EmphasisIn, {BackgroundTransparency = 0.04}):Play()
    TweenService:Create(resultScale, UITheme.Motion.EmphasisIn, {Scale = 1}):Play()

    task.delay(0.14, function()
        TweenService:Create(resultFlash, UITheme.Motion.StandardFade, {BackgroundTransparency = 1}):Play()
    end)

    -- Phase transitions own the normal dismissal so the result never
    -- disappears early on longer multiplayer post-round screens. Keep only a
    -- generous fallback in case a state update is lost.
    task.delay(10, function()
        if token == resultToken then
            dismissResultCard()
        end
    end)
end

local function refreshStats()
    local level = player:GetAttribute("Level") or 1
    local xp = player:GetAttribute("XP") or 0
    local progress, nextXP = xpProgressForLevel(level, xp)

    stats.Text = CoreLocalization.text(
        localeId,
        "STATS_LINE",
        level,
        player:GetAttribute("Coins") or 0,
        player:GetAttribute("Wins") or 0,
        xp,
        nextXP
    )

    TweenService:Create(
        xpFill,
        TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.fromScale(progress, 1)}
    ):Play()

    if level > lastKnownLevel then
        showLevelUp(level)
    end
    lastKnownLevel = level
end

for _, attr in ipairs({"Level","Coins","Wins","XP"}) do
    player:GetAttributeChangedSignal(attr):Connect(refreshStats)
end
refreshStats()

local function clearVotes()
    for _, child in ipairs(votes:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
end

local function showVotes(options)
    clearVotes()
    votes.Visible = options ~= nil and #options > 0
    if not votes.Visible then return end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local voteClass = UIResponsive.classify(viewport, touchDevice)
    local compactVote = touchDevice and voteClass.tinyHeight

    local maxVotes = 0
    for _, option in ipairs(options) do
        maxVotes = math.max(maxVotes, tonumber(option.votes) or 0)
    end

    for index, option in ipairs(options) do
        local optionVotes = tonumber(option.votes) or 0
        local selected = selectedVote == option.id
        local leading = maxVotes > 0 and optionVotes == maxVotes
        local accentColor = UITheme.disasterAccent(option.id, UITheme.Colors.Cyan)

        local button = Instance.new("TextButton")
        button.Name = "VoteCard_" .. tostring(option.id)
        button.Size = UDim2.new(0.31, 0, 0.94, 0)
        button.BackgroundColor3 = UITheme.Colors.PanelRaised
        button.BackgroundTransparency = selected and 0.01 or 0.035
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Text = ""
        button.ClipsDescendants = false
        button.Parent = votes
        UITheme.addCorner(button, UITheme.Corners.Large)
        local cardScale = UITheme.addPressFeedback(button, 0.955)

        local stroke = UITheme.addStroke(
            button,
            leading and UITheme.Colors.Gold or accentColor,
            leading and 2.4 or (selected and 2.0 or 1.2),
            leading and 0.10 or (selected and 0.14 or 0.38)
        )

        local backgroundGradient = UITheme.addGradient(
            button,
            selected and accentColor:Lerp(UITheme.Colors.PanelRaised, 0.62) or UITheme.Colors.PanelRaised,
            UITheme.Colors.Panel,
            90
        )

        local accent = Instance.new("Frame")
        accent.Name = "AccentRail"
        accent.Size = UDim2.new(1, 0, 0, selected and 8 or 5)
        accent.BackgroundColor3 = accentColor
        accent.BorderSizePixel = 0
        accent.Parent = button
        UITheme.addCorner(accent, UITheme.Corners.Pill)

        local indexBadge = Instance.new("TextLabel")
        indexBadge.Position = UDim2.fromScale(0.06, compactVote and 0.08 or 0.10)
        indexBadge.Size = UDim2.fromScale(
            compactVote and 0.18 or 0.22,
            compactVote and 0.17 or 0.20
        )
        indexBadge.BackgroundColor3 = accentColor
        indexBadge.BackgroundTransparency = 0.12
        indexBadge.BorderSizePixel = 0
        indexBadge.Font = Enum.Font.GothamBlack
        indexBadge.Text = string.format("%02d", index)
        indexBadge.TextColor3 = UITheme.Colors.Text
        indexBadge.TextScaled = true
        indexBadge.Parent = button
        UITheme.addTextConstraint(indexBadge, 12, 20)
        UITheme.addCorner(indexBadge, UITheme.Corners.Pill)

        local statusBadge = Instance.new("TextLabel")
        statusBadge.AnchorPoint = Vector2.new(1, 0)
        statusBadge.Position = UDim2.fromScale(0.94, compactVote and 0.08 or 0.10)
        statusBadge.Size = UDim2.fromScale(
            compactVote and 0.34 or 0.42,
            compactVote and 0.17 or 0.20
        )
        statusBadge.BackgroundColor3 = selected
            and UITheme.Colors.Green
            or (leading and UITheme.Colors.Gold or UITheme.Colors.PanelSoft)
        statusBadge.BackgroundTransparency = selected and 0.04 or 0.12
        statusBadge.BorderSizePixel = 0
        statusBadge.Font = Enum.Font.GothamBold
        statusBadge.Text = compactVote
            and (
                selected and CoreLocalization.text(localeId, "VOTED")
                or (
                    leading and CoreLocalization.text(localeId, "TOP")
                    or CoreLocalization.text(localeId, "TAP")
                )
            )
            or (
                selected and CoreLocalization.text(localeId, "YOUR_VOTE")
                or (
                    leading and CoreLocalization.text(localeId, "LEADING")
                    or CoreLocalization.text(localeId, "CHOOSE")
                )
            )
        statusBadge.TextColor3 = selected and UITheme.Colors.Panel or UITheme.Colors.Text
        statusBadge.TextScaled = true
        statusBadge.Parent = button
        UITheme.addTextConstraint(statusBadge, compactVote and 10 or 11, 18)
        UITheme.addCorner(statusBadge, UITheme.Corners.Pill)

        local name = Instance.new("TextLabel")
        name.Position = UDim2.fromScale(0.07, compactVote and 0.27 or 0.34)
        name.Size = UDim2.fromScale(0.86, compactVote and 0.25 or 0.23)
        name.BackgroundTransparency = 1
        name.Font = Enum.Font.GothamBlack
        name.Text = CoreLocalization.hazardName(localeId, option.id)
            or string.upper(tostring(option.name or "CHAOS"))
        name.TextColor3 = UITheme.Colors.Text
        name.TextScaled = true
        name.TextWrapped = true
        name.Parent = button
        UITheme.addTextConstraint(name, compactVote and 12 or 13, 24)

        local hintLabel = Instance.new("TextLabel")
        hintLabel.Position = UDim2.fromScale(0.08, compactVote and 0.52 or 0.58)
        hintLabel.Size = UDim2.fromScale(0.84, compactVote and 0.20 or 0.17)
        hintLabel.BackgroundTransparency = 1
        hintLabel.Font = Enum.Font.GothamMedium
        local action = CoreLocalization.hazardAction(localeId, option.id)
        local localizedHint = CoreLocalization.hazardHint(localeId, option.id)
            or tostring(option.hint or "")
        if compactVote and action then
            hintLabel.Text = action
        else
            hintLabel.Text = action and (action .. "  •  " .. localizedHint) or localizedHint
        end
        hintLabel.TextColor3 = UITheme.Colors.Muted
        hintLabel.TextScaled = true
        hintLabel.TextWrapped = true
        hintLabel.Visible = true
        hintLabel.Parent = button
        UITheme.addTextConstraint(hintLabel, compactVote and 9 or 11, compactVote and 13 or 17)

        local votePill = Instance.new("TextLabel")
        votePill.AnchorPoint = Vector2.new(0.5, 1)
        votePill.Position = UDim2.fromScale(0.5, compactVote and 0.92 or 0.94)
        votePill.Size = UDim2.fromScale(
            compactVote and 0.62 or 0.70,
            compactVote and 0.16 or 0.15
        )
        votePill.BackgroundColor3 = selected and accentColor or UITheme.Colors.PanelSoft
        votePill.BackgroundTransparency = selected and 0.02 or 0.08
        votePill.BorderSizePixel = 0
        votePill.Font = Enum.Font.GothamBold
        votePill.Text = selected
            and CoreLocalization.text(localeId, "VOTE_SAVED")
            or CoreLocalization.text(
                localeId,
                optionVotes == 1 and "VOTE_ONE" or "VOTE_MANY",
                optionVotes
            )
        votePill.TextColor3 = UITheme.Colors.Text
        votePill.TextScaled = true
        votePill.Parent = button
        UITheme.addTextConstraint(votePill, 11, 18)
        UITheme.addCorner(votePill, UITheme.Corners.Pill)

        button.Activated:Connect(function()
            cardScale.Scale = 0.94
            TweenService:Create(
                cardScale,
                TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Scale = 1}
            ):Play()

            selectedVote = option.id
            voteEvent:FireServer(option.id)
            showVotes(options)
        end)
    end
end





local currentHudPhase = "waiting"
local currentVoteActive = false
local pendingQuestCompletion = nil
local pendingAchievement = nil
local pendingDailyReward = nil
local metaNotificationShownThisIntermission = false

local function shouldDeferMetaNotification()
    return currentHudPhase == "ready"
        or currentHudPhase == "round"
        or currentHudPhase == "result"
        or currentVoteActive
        or (tonumber(player:GetAttribute("Games")) or 0) <= 0
end

local function showQuestCompletion(quest)
    if not quest then
        return
    end

    local weekly = quest.scope == "weekly"
    questToastTitle.Text = CoreLocalization.text(
        localeId,
        weekly and "WEEKLY_COMPLETE" or "QUEST_COMPLETE"
    )
    local questTitle = CoreLocalization.questTitle(
        localeId,
        quest.id,
        quest.title or CoreLocalization.text(
            localeId,
            weekly and "WEEKLY_CHALLENGES" or "DAILY_QUESTS"
        )
    )
    questToastBody.Text = CoreLocalization.text(
        localeId,
        "REWARD_LINE",
        questTitle,
        quest.coins or 0,
        quest.xp or 0
    )
    questToast.Visible = true

    task.delay(weekly and 4.6 or 4, function()
        questToast.Visible = false
    end)
end

local function showAchievement(item)
    if not item then
        return
    end

    achievementToastTitle.Text = CoreLocalization.text(localeId, "ACHIEVEMENT_UNLOCKED")
    local achievementTitle = CoreLocalization.achievementTitle(
        localeId,
        item.id,
        item.title or CoreLocalization.text(localeId, "ACHIEVEMENTS")
    )
    achievementToastBody.Text = CoreLocalization.text(
        localeId,
        "REWARD_LINE",
        achievementTitle,
        item.coins or 0,
        item.xp or 0
    )
    achievementToast.Visible = true
    task.delay(4, function()
        achievementToast.Visible = false
    end)
end

local function showDailyReward(reward)
    if not reward then
        return
    end

    local streak = tonumber(reward.streak) or 1
    local coins = tonumber(reward.coins) or 0
    local xp = tonumber(reward.xp) or 0
    dailyTitle.Text = CoreLocalization.text(localeId, "DAY_STREAK", streak)
    dailyBody.Text = CoreLocalization.text(localeId, "COINS_XP", coins, xp)
    dailyToast.Visible = true

    task.delay(4, function()
        dailyToast.Visible = false
    end)
end

local function showOnePendingMetaNotification()
    if currentHudPhase ~= "intermission"
        or currentVoteActive
        or metaNotificationShownThisIntermission
        or (tonumber(player:GetAttribute("Games")) or 0) <= 0
    then
        return
    end

    if pendingAchievement then
        metaNotificationShownThisIntermission = true
        local item = pendingAchievement
        pendingAchievement = nil
        showAchievement(item)
    elseif pendingQuestCompletion then
        metaNotificationShownThisIntermission = true
        local quest = pendingQuestCompletion
        pendingQuestCompletion = nil
        showQuestCompletion(quest)
    elseif pendingDailyReward then
        metaNotificationShownThisIntermission = true
        local reward = pendingDailyReward
        pendingDailyReward = nil
        showDailyReward(reward)
    end
end

roundFeedbackEvent.OnClientEvent:Connect(function(feedback)
    showRoundFeedback(feedback)
end)

achievementEvent.OnClientEvent:Connect(function(payload)
    if payload.state then
        renderAchievements(payload.state)
    end

    local unlockedNow = payload.unlockedNow or {}
    if #unlockedNow > 0 and payload.state and payload.state.achievements then
        local unlockedId = unlockedNow[1]
        for _, item in ipairs(payload.state.achievements) do
            if item.id == unlockedId then
                if shouldDeferMetaNotification() then
                    pendingAchievement = item
                else
                    showAchievement(item)
                end
                break
            end
        end
    end
end)

player:GetAttributeChangedSignal("DataPersistenceAvailable"):Connect(function()
    local available = player:GetAttribute("DataPersistenceAvailable") == true
    if not available then
        supportPanel.Visible = false
    end
    supportButton.Visible = available
        and not metaControlsSuppressed
        and supportButton:GetAttribute("MonetizationEnabled") == true
end)

monetizationStateEvent.OnClientEvent:Connect(function(payload)
    if payload.state then
        renderMonetization(payload.state)
    end

    if payload.notice == "purchase_complete" then
        questToastTitle.Text = CoreLocalization.text(localeId, "THANK_YOU")
        questToastBody.Text = CoreLocalization.text(localeId, "PREMIUM_COSMETIC_UNLOCKED")
        questToast.Visible = true
        task.delay(3.4, function()
            questToast.Visible = false
        end)
    elseif payload.notice == "data_unavailable" then
        questToastTitle.Text = CoreLocalization.text(localeId, "PURCHASE_PAUSED")
        questToastBody.Text = CoreLocalization.text(localeId, "PURCHASE_PAUSED_BODY")
        questToast.Visible = true
        task.delay(3.4, function()
            questToast.Visible = false
        end)
    end
end)

cosmeticStateEvent.OnClientEvent:Connect(function(payload)
    if payload.state then
        renderCosmetics(payload.state)
    end

    local unlocked = payload.unlocked or {}
    if #unlocked > 0 and currentCosmeticState then
        renderCosmetics(payload.state)
    end

    if payload.notice == "purchased" then
        if pendingCollectorMilestone then
            questToastTitle.Text = CoreLocalization.text(
                localeId,
                pendingCollectorMilestone.labelKey
            )
            questToastBody.Text = CoreLocalization.text(
                localeId,
                "COLLECTOR_MILESTONE",
                pendingCollectorMilestone.threshold
            )
            pendingCollectorMilestone = nil
        else
            questToastTitle.Text = CoreLocalization.text(localeId, "COSMETIC_UNLOCKED")
            questToastBody.Text = CoreLocalization.text(localeId, "COSMETIC_UNLOCKED_BODY")
        end
        questToast.Visible = true
        task.delay(3.4, function()
            questToast.Visible = false
        end)
    elseif payload.notice == "insufficient_coins" then
        questToastTitle.Text = CoreLocalization.text(localeId, "MORE_COINS_NEEDED")
        questToastBody.Text = CoreLocalization.text(localeId, "MORE_COINS_BODY")
        questToast.Visible = true
        task.delay(2.6, function()
            questToast.Visible = false
        end)
    elseif payload.notice == "data_unavailable" then
        questToastTitle.Text = CoreLocalization.text(localeId, "SHOP_PAUSED")
        questToastBody.Text = CoreLocalization.text(localeId, "SHOP_PAUSED_BODY")
        questToast.Visible = true
        task.delay(3.2, function()
            questToast.Visible = false
        end)
    end
end)

questEvent.OnClientEvent:Connect(function(payload)
    if payload.state then
        renderQuestState(payload.state)
    end

    local completed = payload.completed or {}
    if #completed > 0 then
        local quest = completed[1]
        if shouldDeferMetaNotification() then
            pendingQuestCompletion = quest
        else
            showQuestCompletion(quest)
        end
    end
end)

dailyRewardEvent.OnClientEvent:Connect(function(reward)
    if shouldDeferMetaNotification() then
        pendingDailyReward = reward
    else
        showDailyReward(reward)
    end
end)

local function localizedStateCopy(state)
    local displayTitle = state.title or "CHAOS SURVIVAL"
    local displayHint = state.hint or ""
    local phase = tostring(state.phase or "")

    if phase == "intermission" and state.voteOptions then
        displayTitle = CoreLocalization.text(localeId, "VOTE_TITLE")
        displayHint = CoreLocalization.text(
            localeId,
            state.soloMode == true and "VOTE_SOLO" or "VOTE_MULTI"
        )
    elseif phase == "ready" or phase == "round" then
        displayTitle = CoreLocalization.hazardTitle(
            localeId,
            state.disasterIds,
            displayTitle
        )
        local primary = state.disasterIds and state.disasterIds[1]
        if state.doubleChaos then
            displayHint = hazardGuidance(state, true) or displayHint
        else
            displayHint = CoreLocalization.hazardHint(localeId, primary) or displayHint
        end
    end

    return displayTitle, displayHint
end

stateEvent.OnClientEvent:Connect(function(state)
    presentCountdown(state)

    local previousHudPhase = currentHudPhase
    currentHudPhase = tostring(state.phase or "waiting")
    currentVoteActive = currentHudPhase == "intermission"
        and type(state.voteOptions) == "table"
        and #state.voteOptions > 0
    compactRoundTop = touchDevice and currentHudPhase == "round"
    top.Visible = currentHudPhase ~= "result"

    if previousHudPhase == "result" and currentHudPhase ~= "result" then
        dismissResultCard()
    end
    if currentHudPhase ~= "intermission" and previousHudPhase == "intermission" then
        metaNotificationShownThisIntermission = false
    elseif currentHudPhase == "intermission" and previousHudPhase ~= "intermission" then
        metaNotificationShownThisIntermission = false
    end

    local firstLobby = (tonumber(player:GetAttribute("Games")) or 0) <= 0
    local activeGameplay = state.phase == "round" or state.phase == "ready"
    metaControlsSuppressed = activeGameplay
        or state.phase == "result"
        or firstLobby
    if metaDock then
        metaDock.Visible = not metaControlsSuppressed
    end
    questButton.Visible = not metaControlsSuppressed
    cosmeticsButton.Visible = not metaControlsSuppressed
    achievementButton.Visible = not metaControlsSuppressed
    supportButton.Visible = (not metaControlsSuppressed)
        and player:GetAttribute("DataPersistenceAvailable") == true
        and supportButton:GetAttribute("MonetizationEnabled") == true

    if touchDevice then
        stats.Visible = not metaControlsSuppressed
        xpTrack.Visible = not metaControlsSuppressed
        applyResponsiveLayout()
    end

    if metaControlsSuppressed then
        closeAllPanels()
    end

    if activeGameplay or firstLobby then
        if resultCard.Visible then
            dismissResultCard()
        else
            resultToken += 1
        end
        resultFlash.BackgroundTransparency = 1
    end

    if state.phase == "intermission" then
        task.defer(showOnePendingMetaNotification)
    end

    local displayTitle, displayHint = localizedStateCopy(state)
    if state.phase == "round" and displayHint ~= "" then
        lastRoundHint = displayHint
    end

    title.Text = displayTitle
    hint.Text = displayHint
    timer.Text = tostring(state.seconds or 0)

    if state.phase == "result" and resultCard.Visible then
        local nextSeconds = math.max(0, math.floor(tonumber(state.seconds) or 0))
        resultNext.Text = CoreLocalization.text(localeId, "NEXT_CHAOS_IN", nextSeconds)
    elseif state.phase ~= "result" then
        resultNext.Text = ""
    end

    local alive = tonumber(state.survivorsAlive)
    local total = tonumber(state.contestantCount)
    if (state.phase == "round" or state.phase == "ready") and alive and total and total > 0 then
        aliveCounter.Visible = true
        if total == 1 then
            if state.phase == "ready" and state.soloMode == true then
                aliveCounter.Text = CoreLocalization.text(localeId, "SURVIVORS_JOINING")
            else
                aliveCounter.Text = "SOLO"
            end
        elseif state.phase == "ready" and (tonumber(state.aiSurvivors) or 0) > 0 then
            aliveCounter.Text = CoreLocalization.text(localeId, "SURVIVOR_COUNT", total)
        else
            aliveCounter.Text = CoreLocalization.text(localeId, "ALIVE_COUNT", alive, total)
        end
    else
        aliveCounter.Visible = false
    end

    local coachText = FirstTimeExperience.coachText(state, {
        games = player:GetAttribute("Games"),
        practiceUses = player:GetAttribute("LobbyPracticeUses"),
        mechanicUses = player:GetAttribute("RoundMechanicUses"),
        shards = player:GetAttribute("RoundChaosShards"),
    })
    if firstLobby
        and state.phase == "intermission"
        and not state.voteOptions
    then
        local controlsKey = touchDevice and "TOUCH_CONTROLS"
            or (UserInputService.GamepadEnabled and "GAMEPAD_CONTROLS" or "KEYBOARD_CONTROLS")
        coachText = CoreLocalization.text(localeId, controlsKey)
    elseif touchDevice
        and state.phase == "intermission"
        and state.voteOptions
    then
        -- The top HUD already says exactly what to tap. Hiding the rookie
        -- coach prevents it from colliding with vote cards on short phones.
        coachText = nil
    end
    coachText = CoreLocalization.coach(localeId, coachText)
    rookieCoach.Visible = coachText ~= nil
    if coachText then
        rookieCoach.Text = coachText
        if touchDevice then
            rookieCoach.Position = UDim2.fromScale(0.5, 0.70)
        else
            rookieCoach.Position = UDim2.fromScale(0.5, 0.94)
        end
    end

    if state.phase == "ready" then
        setTimerPalette(UITheme.Colors.Blue, UITheme.Colors.Cyan)
        timer.Rotation = 0
    elseif state.phase == "round" and (state.seconds or 0) <= 5 then
        setTimerPalette(UITheme.Colors.Red, UITheme.Colors.Orange)
        timer.Rotation = ((state.seconds or 0) % 2 == 0) and -4 or 4
    else
        setTimerPalette(UITheme.Colors.Orange, Color3.fromRGB(220, 70, 55))
        timer.Rotation = 0
    end

    local primaryDisasterId = state.disasterIds and state.disasterIds[1]
    local activeUiAccent = UITheme.disasterAccent(primaryDisasterId, UITheme.Colors.Cyan)
    topAccent.BackgroundColor3 = activeUiAccent
    topStroke.Color = state.doubleChaos and UITheme.Colors.Violet or activeUiAccent

    if state.doubleChaos then
        top.BackgroundColor3 = Color3.fromRGB(63, 28, 88)
        topGradient.Color = ColorSequence.new(
            Color3.fromRGB(86, 38, 118),
            UITheme.Colors.Panel
        )
    else
        top.BackgroundColor3 = UITheme.Colors.Panel
        topGradient.Color = ColorSequence.new(
            UITheme.Colors.PanelRaised,
            UITheme.Colors.Panel
        )
    end

    if state.voteOptions then
        showVotes(state.voteOptions)
    elseif state.phase ~= "intermission" then
        selectedVote = nil
        showVotes(nil)
    end

    previousRoundPhase = tostring(state.phase or "")
end)


-- Signal only after this HUD has connected every initial-state listener.
clientReadyEvent:FireServer()
monetizationActionEvent:FireServer("sync")
