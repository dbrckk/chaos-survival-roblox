local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("RoundState")
local voteEvent = remotes:WaitForChild("VoteDisaster")

local dailyRewardEvent = remotes:WaitForChild("DailyReward")
local questEvent = remotes:WaitForChild("QuestUpdate")
local cosmeticStateEvent = remotes:WaitForChild("CosmeticState")
local cosmeticActionEvent = remotes:WaitForChild("CosmeticAction")

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

questButton.Activated:Connect(function()
    questPanel.Visible = not questPanel.Visible
end)

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

cosmeticsButton.Activated:Connect(function()
    cosmeticsPanel.Visible = not cosmeticsPanel.Visible
    if cosmeticsPanel.Visible then
        cosmeticActionEvent:FireServer("sync")
    end
end)

local function refreshStats()
    stats.Text = string.format(
        "LVL %d    🪙 %d    🏆 %d",
        player:GetAttribute("Level") or 1,
        player:GetAttribute("Coins") or 0,
        player:GetAttribute("Wins") or 0
    )
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

    for _, option in ipairs(options) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.31, 0, 0.92, 0)
        button.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
        button.TextColor3 = Color3.new(1,1,1)
        button.Font = Enum.Font.GothamBold
        button.TextWrapped = true
        button.TextScaled = true
        button.Text = option.name .. "\n\n" .. option.hint
        button.Parent = votes
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 18)

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
    title.Text = state.title or "CHAOS SURVIVAL"
    hint.Text = state.hint or ""
    timer.Text = tostring(state.seconds or 0)

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
