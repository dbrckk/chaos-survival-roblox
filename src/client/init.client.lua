local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("RoundState")
local voteEvent = remotes:WaitForChild("VoteDisaster")

local dailyRewardEvent = remotes:WaitForChild("DailyReward")

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
