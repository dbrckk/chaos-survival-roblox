local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("RoundState")
local voteEvent = remotes:WaitForChild("VoteDisaster")

local dailyRewardEvent = remotes:WaitForChild("DailyReward")
local questEvent = remotes:WaitForChild("QuestUpdate")
local cosmeticStateEvent = remotes:WaitForChild("CosmeticState")
local cosmeticActionEvent = remotes:WaitForChild("CosmeticAction")
local achievementEvent = remotes:WaitForChild("AchievementState")
local roundFeedbackEvent = remotes:WaitForChild("RoundFeedback")

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
top.AnchorPoint = Vector2.new(0.5, 0)
top.Position = UDim2.fromScale(0.5, 0.025)
top.Size = UDim2.fromScale(0.88, 0.13)
top.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
top.BackgroundTransparency = 0.12
top.Parent = root
Instance.new("UICorner", top).CornerRadius = UDim.new(0, 18)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 0.58, 0)
title.Position = UDim2.fromOffset(18, 6)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "CHAOS SURVIVAL"
title.Parent = top

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -100, 0.32, 0)
hint.Position = UDim2.new(0, 18, 0.62, 0)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.GothamMedium
hint.TextColor3 = Color3.fromRGB(210,215,230)
hint.TextScaled = true
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Text = ""
hint.Parent = top

local timer = Instance.new("TextLabel")
timer.AnchorPoint = Vector2.new(1, 0.5)
timer.Position = UDim2.new(1, -14, 0.5, 0)
timer.Size = UDim2.fromOffset(70, 70)
timer.BackgroundColor3 = Color3.fromRGB(255,90,55)
timer.Font = Enum.Font.GothamBlack
timer.TextColor3 = Color3.new(1,1,1)
timer.TextScaled = true
timer.Text = "0"
timer.Parent = top
Instance.new("UICorner", timer).CornerRadius = UDim.new(1, 0)

local stats = Instance.new("TextLabel")
stats.AnchorPoint = Vector2.new(0.5, 1)
stats.Position = UDim2.fromScale(0.5, 0.975)
stats.Size = UDim2.fromScale(0.65, 0.07)
stats.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
stats.BackgroundTransparency = 0.15
stats.Font = Enum.Font.GothamBold
stats.TextColor3 = Color3.new(1,1,1)
stats.TextScaled = true
stats.Text = ""
stats.Parent = root
Instance.new("UICorner", stats).CornerRadius = UDim.new(0, 16)


local xpTrack = Instance.new("Frame")
xpTrack.AnchorPoint = Vector2.new(0.5, 1)
xpTrack.Position = UDim2.fromScale(0.5, 0.94)
xpTrack.Size = UDim2.fromScale(0.62, 0.012)
xpTrack.BackgroundColor3 = Color3.fromRGB(42, 47, 62)
xpTrack.BackgroundTransparency = 0.08
xpTrack.BorderSizePixel = 0
xpTrack.Parent = root
Instance.new("UICorner", xpTrack).CornerRadius = UDim.new(1, 0)

local xpFill = Instance.new("Frame")
xpFill.Size = UDim2.fromScale(0, 1)
xpFill.BackgroundColor3 = Color3.fromRGB(105, 165, 255)
xpFill.BorderSizePixel = 0
xpFill.Parent = xpTrack
Instance.new("UICorner", xpFill).CornerRadius = UDim.new(1, 0)

local levelToast = Instance.new("Frame")
levelToast.AnchorPoint = Vector2.new(0.5, 0.5)
levelToast.Position = UDim2.fromScale(0.5, 0.30)
levelToast.Size = UDim2.fromScale(0.50, 0.11)
levelToast.BackgroundColor3 = Color3.fromRGB(40, 67, 115)
levelToast.BackgroundTransparency = 1
levelToast.Visible = false
levelToast.ZIndex = 30
levelToast.Parent = root
Instance.new("UICorner", levelToast).CornerRadius = UDim.new(0, 18)

local levelToastScale = Instance.new("UIScale")
levelToastScale.Scale = 0.8
levelToastScale.Parent = levelToast

local levelToastText = Instance.new("TextLabel")
levelToastText.Size = UDim2.fromScale(1, 1)
levelToastText.BackgroundTransparency = 1
levelToastText.Font = Enum.Font.GothamBlack
levelToastText.TextColor3 = Color3.fromRGB(245, 250, 255)
levelToastText.TextScaled = true
levelToastText.Text = "LEVEL UP!"
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
    levelToastText.Text = "LEVEL " .. tostring(level) .. "!"
    levelToast.Visible = true
    levelToast.BackgroundTransparency = 1
    levelToastScale.Scale = 0.78

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

    task.delay(2.1, function()
        TweenService:Create(levelToast, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        TweenService:Create(levelToastScale, TweenInfo.new(0.2), {Scale = 0.88}):Play()
        task.wait(0.22)
        levelToast.Visible = false
    end)
end


local votes = Instance.new("Frame")
votes.AnchorPoint = Vector2.new(0.5, 0.5)
votes.Position = UDim2.fromScale(0.5, 0.58)
votes.Size = UDim2.fromScale(0.88, 0.24)
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

local dailyToast = Instance.new("Frame")
dailyToast.AnchorPoint = Vector2.new(0.5, 0.5)
dailyToast.Position = UDim2.fromScale(0.5, 0.32)
dailyToast.Size = UDim2.fromScale(0.72, 0.16)
dailyToast.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
dailyToast.BackgroundTransparency = 0.05
dailyToast.Visible = false
dailyToast.Parent = root
Instance.new("UICorner", dailyToast).CornerRadius = UDim.new(0, 18)

local dailyTitle = Instance.new("TextLabel")
dailyTitle.Size = UDim2.new(1, -24, 0.48, 0)
dailyTitle.Position = UDim2.fromOffset(12, 8)
dailyTitle.BackgroundTransparency = 1
dailyTitle.Font = Enum.Font.GothamBlack
dailyTitle.TextColor3 = Color3.new(1, 1, 1)
dailyTitle.TextScaled = true
dailyTitle.Text = "DAILY REWARD"
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
questButton.AnchorPoint = Vector2.new(0, 1)
questButton.Position = UDim2.fromScale(0.025, 0.90)
questButton.Size = UDim2.fromScale(0.22, 0.065)
questButton.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
questButton.TextColor3 = Color3.new(1, 1, 1)
questButton.Font = Enum.Font.GothamBold
questButton.TextScaled = true
questButton.Text = "QUESTS"
questButton.Parent = root
Instance.new("UICorner", questButton).CornerRadius = UDim.new(0, 14)

local questPanel = Instance.new("Frame")
questPanel.AnchorPoint = Vector2.new(0, 1)
questPanel.Position = UDim2.fromScale(0.025, 0.82)
questPanel.Size = UDim2.fromScale(0.72, 0.34)
questPanel.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
questPanel.BackgroundTransparency = 0.04
questPanel.Visible = false
questPanel.Parent = root
Instance.new("UICorner", questPanel).CornerRadius = UDim.new(0, 18)

local questHeader = Instance.new("TextLabel")
questHeader.Size = UDim2.new(1, -24, 0.18, 0)
questHeader.Position = UDim2.fromOffset(12, 6)
questHeader.BackgroundTransparency = 1
questHeader.Font = Enum.Font.GothamBlack
questHeader.TextColor3 = Color3.new(1, 1, 1)
questHeader.TextScaled = true
questHeader.TextXAlignment = Enum.TextXAlignment.Left
questHeader.Text = "DAILY QUESTS"
questHeader.Parent = questPanel

local questRows = {}
for i = 1, 3 do
    local row = Instance.new("TextLabel")
    row.Size = UDim2.new(1, -24, 0.22, 0)
    row.Position = UDim2.new(0, 12, 0.20 + ((i - 1) * 0.25), 0)
    row.BackgroundColor3 = Color3.fromRGB(34, 38, 52)
    row.TextColor3 = Color3.fromRGB(235, 238, 245)
    row.Font = Enum.Font.GothamMedium
    row.TextScaled = true
    row.TextWrapped = true
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.Text = "Loading..."
    row.Parent = questPanel
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    questRows[i] = row
end

local questToast = Instance.new("Frame")
questToast.AnchorPoint = Vector2.new(0.5, 0.5)
questToast.Position = UDim2.fromScale(0.5, 0.50)
questToast.Size = UDim2.fromScale(0.76, 0.15)
questToast.BackgroundColor3 = Color3.fromRGB(32, 75, 50)
questToast.BackgroundTransparency = 0.04
questToast.Visible = false
questToast.Parent = root
Instance.new("UICorner", questToast).CornerRadius = UDim.new(0, 18)

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
            local marker = quest.claimed and "DONE" or string.format("%d/%d", quest.progress or 0, quest.target or 0)
            questRows[i].Text = string.format("  %s  •  %s  •  +%d coins", quest.title or "Quest", marker, quest.coins or 0)
        else
            questRows[i].Text = "  No quest"
        end
    end
end



local cosmeticsButton = Instance.new("TextButton")
cosmeticsButton.AnchorPoint = Vector2.new(1, 1)
cosmeticsButton.Position = UDim2.fromScale(0.975, 0.90)
cosmeticsButton.Size = UDim2.fromScale(0.26, 0.065)
cosmeticsButton.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
cosmeticsButton.TextColor3 = Color3.new(1, 1, 1)
cosmeticsButton.Font = Enum.Font.GothamBold
cosmeticsButton.TextScaled = true
cosmeticsButton.Text = "COSMETICS"
cosmeticsButton.Parent = root
Instance.new("UICorner", cosmeticsButton).CornerRadius = UDim.new(0, 14)

local cosmeticsPanel = Instance.new("Frame")
cosmeticsPanel.AnchorPoint = Vector2.new(1, 1)
cosmeticsPanel.Position = UDim2.fromScale(0.975, 0.82)
cosmeticsPanel.Size = UDim2.fromScale(0.72, 0.36)
cosmeticsPanel.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
cosmeticsPanel.BackgroundTransparency = 0.04
cosmeticsPanel.Visible = false
cosmeticsPanel.Parent = root
Instance.new("UICorner", cosmeticsPanel).CornerRadius = UDim.new(0, 18)

local cosmeticsHeader = Instance.new("TextLabel")
cosmeticsHeader.Size = UDim2.new(1, -24, 0.16, 0)
cosmeticsHeader.Position = UDim2.fromOffset(12, 6)
cosmeticsHeader.BackgroundTransparency = 1
cosmeticsHeader.Font = Enum.Font.GothamBlack
cosmeticsHeader.TextColor3 = Color3.new(1, 1, 1)
cosmeticsHeader.TextScaled = true
cosmeticsHeader.TextXAlignment = Enum.TextXAlignment.Left
cosmeticsHeader.Text = "COSMETICS"
cosmeticsHeader.Parent = cosmeticsPanel

local cosmeticsList = Instance.new("Frame")
cosmeticsList.Size = UDim2.new(1, -24, 0.74, 0)
cosmeticsList.Position = UDim2.new(0, 12, 0.20, 0)
cosmeticsList.BackgroundTransparency = 1
cosmeticsList.Parent = cosmeticsPanel

local cosmeticsLayout = Instance.new("UIListLayout")
cosmeticsLayout.Padding = UDim.new(0, 8)
cosmeticsLayout.Parent = cosmeticsList

local currentCosmeticState = nil

local function renderCosmetics(state)
    currentCosmeticState = state

    for _, child in ipairs(cosmeticsList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local catalog = state and state.catalog or {}
    local owned = state and state.owned or {}
    local equipped = state and state.equipped or ""

    for _, item in ipairs(catalog) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 56)
        button.BackgroundColor3 = Color3.fromRGB(34, 38, 52)
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Font = Enum.Font.GothamBold
        button.TextScaled = true
        button.TextWrapped = true

        local isOwned = owned[item.id] == true
        if equipped == item.id then
            button.Text = item.name .. "   •   EQUIPPED"
            button.BackgroundColor3 = Color3.fromRGB(55, 110, 85)
        elseif isOwned then
            button.Text = item.name .. "   •   EQUIP"
        else
            button.Text = item.name .. "   •   LVL " .. tostring(item.unlockLevel)
            button.BackgroundColor3 = Color3.fromRGB(48, 49, 58)
        end

        button.Parent = cosmeticsList
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)

        button.Activated:Connect(function()
            if isOwned then
                cosmeticActionEvent:FireServer("equip", item.id)
            end
        end)
    end
end

-- cosmetics navigation is wired after all three panels are created


local achievementButton = Instance.new("TextButton")
achievementButton.AnchorPoint = Vector2.new(0.5, 1)
achievementButton.Position = UDim2.fromScale(0.5, 0.90)
achievementButton.Size = UDim2.fromScale(0.30, 0.065)
achievementButton.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
achievementButton.TextColor3 = Color3.new(1, 1, 1)
achievementButton.Font = Enum.Font.GothamBold
achievementButton.TextScaled = true
achievementButton.Text = "ACHIEVEMENTS"
achievementButton.Parent = root
Instance.new("UICorner", achievementButton).CornerRadius = UDim.new(0, 14)

local achievementPanel = Instance.new("Frame")
achievementPanel.AnchorPoint = Vector2.new(0.5, 1)
achievementPanel.Position = UDim2.fromScale(0.5, 0.82)
achievementPanel.Size = UDim2.fromScale(0.82, 0.46)
achievementPanel.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
achievementPanel.BackgroundTransparency = 0.04
achievementPanel.Visible = false
achievementPanel.Parent = root
Instance.new("UICorner", achievementPanel).CornerRadius = UDim.new(0, 18)

local achievementHeader = Instance.new("TextLabel")
achievementHeader.Size = UDim2.new(1, -24, 0, 42)
achievementHeader.Position = UDim2.fromOffset(12, 6)
achievementHeader.BackgroundTransparency = 1
achievementHeader.Font = Enum.Font.GothamBlack
achievementHeader.TextColor3 = Color3.new(1, 1, 1)
achievementHeader.TextScaled = true
achievementHeader.TextXAlignment = Enum.TextXAlignment.Left
achievementHeader.Text = "ACHIEVEMENTS"
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
achievementToast.BackgroundColor3 = Color3.fromRGB(80, 65, 28)
achievementToast.BackgroundTransparency = 0.03
achievementToast.Visible = false
achievementToast.Parent = root
Instance.new("UICorner", achievementToast).CornerRadius = UDim.new(0, 18)

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
        row.Size = UDim2.new(1, -6, 0, 72)
        row.BackgroundColor3 = item.unlocked and Color3.fromRGB(55, 85, 65) or Color3.fromRGB(34, 38, 52)
        row.Parent = achievementList
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

        local rowTitle = Instance.new("TextLabel")
        rowTitle.Size = UDim2.new(1, -20, 0.42, 0)
        rowTitle.Position = UDim2.fromOffset(10, 5)
        rowTitle.BackgroundTransparency = 1
        rowTitle.Font = Enum.Font.GothamBold
        rowTitle.TextColor3 = Color3.new(1, 1, 1)
        rowTitle.TextScaled = true
        rowTitle.TextXAlignment = Enum.TextXAlignment.Left
        rowTitle.Text = item.title or "Achievement"
        rowTitle.Parent = row

        local rowBody = Instance.new("TextLabel")
        rowBody.Size = UDim2.new(1, -20, 0.40, 0)
        rowBody.Position = UDim2.new(0, 10, 0.50, 0)
        rowBody.BackgroundTransparency = 1
        rowBody.Font = Enum.Font.GothamMedium
        rowBody.TextColor3 = Color3.fromRGB(220, 225, 235)
        rowBody.TextScaled = true
        rowBody.TextXAlignment = Enum.TextXAlignment.Left

        local status = item.unlocked and "DONE" or string.format("%d/%d", item.progress or 0, item.target or 0)
        rowBody.Text = string.format("%s  •  %s  •  +%d coins", item.description or "", status, item.coins or 0)
        rowBody.Parent = row
    end
end

local panelScales = {}
for _, panel in ipairs({questPanel, cosmeticsPanel, achievementPanel}) do
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = panel
    panelScales[panel] = scale
end

local function closeAllPanels()
    questPanel.Visible = false
    cosmeticsPanel.Visible = false
    achievementPanel.Visible = false
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
            TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
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
Instance.new("UICorner", dataWarning).CornerRadius = UDim.new(0, 12)

local function refreshDataStatus()
    if player:GetAttribute("DataLoaded") ~= true then
        dataWarning.Visible = false
        return
    end

    if player:GetAttribute("DataPersistenceAvailable") ~= true then
        dataWarning.Text = "TEMPORARY SESSION • PROGRESS WILL NOT SAVE • REJOIN LATER"
        dataWarning.Visible = true
    elseif player:GetAttribute("LastSaveFailed") == true then
        dataWarning.Text = "SAVE DELAYED • ROBLOX DATASTORE RETRYING"
        dataWarning.Visible = true
    else
        dataWarning.Visible = false
    end
end

for _, attr in ipairs({"DataLoaded", "DataPersistenceAvailable", "LastSaveFailed"}) do
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
resultCard.AnchorPoint = Vector2.new(0.5, 0.5)
resultCard.Position = UDim2.fromScale(0.5, 0.54)
resultCard.Size = UDim2.fromScale(0.80, 0.24)
resultCard.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
resultCard.BackgroundTransparency = 1
resultCard.Visible = false
resultCard.ZIndex = 21
resultCard.Parent = root
Instance.new("UICorner", resultCard).CornerRadius = UDim.new(0, 22)

local resultScale = Instance.new("UIScale")
resultScale.Scale = 0.82
resultScale.Parent = resultCard

local resultTitle = Instance.new("TextLabel")
resultTitle.Size = UDim2.new(1, -28, 0.34, 0)
resultTitle.Position = UDim2.fromOffset(14, 10)
resultTitle.BackgroundTransparency = 1
resultTitle.Font = Enum.Font.GothamBlack
resultTitle.TextColor3 = Color3.new(1, 1, 1)
resultTitle.TextScaled = true
resultTitle.ZIndex = 22
resultTitle.Text = "ROUND COMPLETE"
resultTitle.Parent = resultCard

local resultReward = Instance.new("TextLabel")
resultReward.Size = UDim2.new(1, -28, 0.24, 0)
resultReward.Position = UDim2.new(0, 14, 0.40, 0)
resultReward.BackgroundTransparency = 1
resultReward.Font = Enum.Font.GothamBold
resultReward.TextColor3 = Color3.fromRGB(240, 225, 145)
resultReward.TextScaled = true
resultReward.ZIndex = 22
resultReward.Text = ""
resultReward.Parent = resultCard

local resultMeta = Instance.new("TextLabel")
resultMeta.Size = UDim2.new(1, -28, 0.22, 0)
resultMeta.Position = UDim2.new(0, 14, 0.68, 0)
resultMeta.BackgroundTransparency = 1
resultMeta.Font = Enum.Font.GothamMedium
resultMeta.TextColor3 = Color3.fromRGB(220, 225, 235)
resultMeta.TextScaled = true
resultMeta.ZIndex = 22
resultMeta.Text = ""
resultMeta.Parent = resultCard

local resultToken = 0

local function showRoundFeedback(feedback)
    resultToken += 1
    local token = resultToken

    local survived = feedback.survived == true
    resultTitle.Text = survived and "SURVIVED!" or "ELIMINATED"

    local streakBonus = tonumber(feedback.streakBonusCoins) or 0
    if streakBonus > 0 then
        resultReward.Text = string.format(
            "+%d COINS   +%d XP   •   STREAK +%d",
            feedback.coins or 0,
            feedback.xp or 0,
            streakBonus
        )
    else
        resultReward.Text = string.format("+%d COINS   +%d XP", feedback.coins or 0, feedback.xp or 0)
    end

    local tags = {}
    table.insert(tags, tostring(feedback.arenaName or "ARENA"))
    table.insert(tags, tostring(feedback.disasterName or "CHAOS"))
    if feedback.doubleChaos then table.insert(tags, "DOUBLE CHAOS") end
    if feedback.soloMode then table.insert(tags, "SOLO RUSH") end
    table.insert(tags, tostring(feedback.elapsedSeconds or 0) .. "s")
    resultMeta.Text = table.concat(tags, "  •  ")

    resultCard.BackgroundColor3 = survived and Color3.fromRGB(28, 74, 53) or Color3.fromRGB(88, 35, 40)
    resultFlash.BackgroundColor3 = survived and Color3.fromRGB(120, 255, 175) or Color3.fromRGB(255, 95, 95)

    resultCard.Visible = true
    resultCard.BackgroundTransparency = 1
    resultScale.Scale = 0.82
    resultFlash.BackgroundTransparency = 1

    TweenService:Create(resultFlash, TweenInfo.new(0.12), {BackgroundTransparency = 0.72}):Play()
    TweenService:Create(resultCard, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.04}):Play()
    TweenService:Create(resultScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

    task.delay(0.14, function()
        TweenService:Create(resultFlash, TweenInfo.new(0.28), {BackgroundTransparency = 1}):Play()
    end)

    task.delay(3.4, function()
        if token ~= resultToken then return end
        TweenService:Create(resultCard, TweenInfo.new(0.22), {BackgroundTransparency = 1}):Play()
        TweenService:Create(resultScale, TweenInfo.new(0.22), {Scale = 0.90}):Play()
        task.wait(0.24)
        if token == resultToken then
            resultCard.Visible = false
        end
    end)
end

local function refreshStats()
    local level = player:GetAttribute("Level") or 1
    local xp = player:GetAttribute("XP") or 0
    local progress, nextXP = xpProgressForLevel(level, xp)

    stats.Text = string.format(
        "LVL %d    🪙 %d    🏆 %d    XP %d/%d",
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

    local maxVotes = 0
    for _, option in ipairs(options) do
        maxVotes = math.max(maxVotes, tonumber(option.votes) or 0)
    end

    for _, option in ipairs(options) do
        local optionVotes = tonumber(option.votes) or 0
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.31, 0, 0.92, 0)
        button.BackgroundColor3 = selectedVote == option.id
            and Color3.fromRGB(70, 145, 255)
            or Color3.fromRGB(38, 42, 58)
        button.TextColor3 = Color3.new(1,1,1)
        button.Font = Enum.Font.GothamBold
        button.TextWrapped = true
        button.TextScaled = true
        button.Text = string.format(
            "%s\n\n%s\n\n%d VOTE%s",
            option.name,
            option.hint,
            optionVotes,
            optionVotes == 1 and "" or "S"
        )
        button.Parent = votes
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 18)

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = (maxVotes > 0 and optionVotes == maxVotes) and 3 or 1
        stroke.Transparency = (maxVotes > 0 and optionVotes == maxVotes) and 0.12 or 0.65
        stroke.Color = (maxVotes > 0 and optionVotes == maxVotes)
            and Color3.fromRGB(255, 220, 95)
            or Color3.fromRGB(120, 130, 155)
        stroke.Parent = button

        button.Activated:Connect(function()
            selectedVote = option.id
            voteEvent:FireServer(option.id)

            for _, sibling in ipairs(votes:GetChildren()) do
                if sibling:IsA("TextButton") then
                    sibling.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
                end
            end

            button.BackgroundColor3 = Color3.fromRGB(70, 145, 255)
        end)
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
                achievementToastTitle.Text = "ACHIEVEMENT UNLOCKED"
                achievementToastBody.Text = string.format("%s   +%d coins   +%d XP", item.title or "Achievement", item.coins or 0, item.xp or 0)
                achievementToast.Visible = true
                task.delay(4, function()
                    achievementToast.Visible = false
                end)
                break
            end
        end
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
end)

questEvent.OnClientEvent:Connect(function(payload)
    if payload.state then
        renderQuestState(payload.state)
    end

    local completed = payload.completed or {}
    if #completed > 0 then
        local quest = completed[1]
        questToastTitle.Text = "QUEST COMPLETE"
        questToastBody.Text = string.format("%s   +%d coins   +%d XP", quest.title or "Daily quest", quest.coins or 0, quest.xp or 0)
        questToast.Visible = true

        task.delay(4, function()
            questToast.Visible = false
        end)
    end
end)

dailyRewardEvent.OnClientEvent:Connect(function(reward)
    local streak = tonumber(reward.streak) or 1
    local coins = tonumber(reward.coins) or 0
    local xp = tonumber(reward.xp) or 0

    dailyTitle.Text = "DAY " .. streak .. " STREAK"
    dailyBody.Text = string.format("+%d coins   +%d XP", coins, xp)
    dailyToast.Visible = true

    task.delay(4, function()
        dailyToast.Visible = false
    end)
end)

stateEvent.OnClientEvent:Connect(function(state)
    if state.phase == "round" then
        closeAllPanels()
    end

    title.Text = state.title or "CHAOS SURVIVAL"
    hint.Text = state.hint or ""
    timer.Text = tostring(state.seconds or 0)

    if state.phase == "round" and (state.seconds or 0) <= 5 then
        timer.BackgroundColor3 = Color3.fromRGB(225, 55, 55)
        timer.Rotation = ((state.seconds or 0) % 2 == 0) and -4 or 4
    else
        timer.BackgroundColor3 = Color3.fromRGB(255, 90, 55)
        timer.Rotation = 0
    end

    if state.doubleChaos then
        top.BackgroundColor3 = Color3.fromRGB(90, 20, 120)
    else
        top.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
    end

    if state.voteOptions then
        showVotes(state.voteOptions)
    elseif state.phase ~= "intermission" then
        selectedVote = nil
        showVotes(nil)
    end
end)
