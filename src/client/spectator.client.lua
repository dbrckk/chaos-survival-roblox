local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosSpectator"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 45
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5, 1)
card.Position = UDim2.fromScale(0.5, 0.88)
card.Size = UDim2.fromScale(0.58, 0.105)
card.BackgroundColor3 = UITheme.Colors.Panel
card.BackgroundTransparency = 0.05
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui
UITheme.addCorner(card, UITheme.Corners.Large)
local cardStroke = UITheme.addStroke(card, UITheme.Colors.Blue, 1.3, 0.28)
UITheme.addGradient(card, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local accentRail = Instance.new("Frame")
accentRail.Size = UDim2.new(0.90, 0, 0, 4)
accentRail.Position = UDim2.fromScale(0.05, 0.06)
accentRail.BackgroundColor3 = UITheme.Colors.Blue
accentRail.BorderSizePixel = 0
accentRail.Parent = card
UITheme.addCorner(accentRail, UITheme.Corners.Pill)

local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = card

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.68, -14, 0.64, -4)
label.Position = UDim2.fromOffset(12, 7)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextColor3 = UITheme.Colors.Text
label.TextScaled = true
label.TextWrapped = true
label.TextXAlignment = Enum.TextXAlignment.Left
label.Text = "SPECTATING"
label.Parent = card

local nextButton = Instance.new("TextButton")
nextButton.AnchorPoint = Vector2.new(1, 0.5)
nextButton.Position = UDim2.new(1, -8, 0.5, 0)
nextButton.Size = UDim2.new(0.28, 0, 0.72, 0)
nextButton.BackgroundColor3 = UITheme.Colors.Blue
nextButton.Font = Enum.Font.GothamBlack
nextButton.TextColor3 = UITheme.Colors.Text
nextButton.TextScaled = true
nextButton.Text = "NEXT"
nextButton.Parent = card
UITheme.addCorner(nextButton, UITheme.Corners.Medium)
UITheme.addStroke(nextButton, UITheme.Colors.Cyan, 1.1, 0.35)
UITheme.addGradient(nextButton, UITheme.Colors.Blue, UITheme.Colors.Violet, 25)
UITheme.addPressFeedback(nextButton, 0.94)

local healthTrack = Instance.new("Frame")
healthTrack.Name = "TargetHealthTrack"
healthTrack.Position = UDim2.fromScale(0.04, 0.79)
healthTrack.Size = UDim2.fromScale(0.62, 0.10)
healthTrack.BackgroundColor3 = UITheme.Colors.PanelSoft
healthTrack.BackgroundTransparency = 0.05
healthTrack.BorderSizePixel = 0
healthTrack.Parent = card
UITheme.addCorner(healthTrack, UITheme.Corners.Pill)

local healthFill = Instance.new("Frame")
healthFill.Name = "TargetHealthFill"
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = UITheme.Colors.Green
healthFill.BorderSizePixel = 0
healthFill.Parent = healthTrack
UITheme.addCorner(healthFill, UITheme.Corners.Pill)

local roundActive = false
local latestState = nil
local targets = {}
local targetIndex = 0
local targetHealthConnection = nil


local function clearTargetHealth()
    if targetHealthConnection then
        targetHealthConnection:Disconnect()
        targetHealthConnection = nil
    end
    healthFill.Size = UDim2.fromScale(0, 1)
end

local function bindTargetHealth(humanoid)
    clearTargetHealth()
    if not humanoid then
        return
    end

    local function update()
        local ratio = humanoid.MaxHealth > 0
            and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            or 0
        healthFill.BackgroundColor3 = ratio > 0.55
            and UITheme.Colors.Green
            or (ratio > 0.25 and UITheme.Colors.Gold or UITheme.Colors.Red)
        TweenService:Create(
            healthFill,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.fromScale(ratio, 1)}
        ):Play()
    end

    update()
    targetHealthConnection = humanoid.HealthChanged:Connect(update)
end

local function localHumanoid()
    local character = player.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function validTarget(other)
    if other == player then return false end
    if other:GetAttribute("RoundParticipant") ~= true then return false end
    if other:GetAttribute("RoundEliminated") == true then return false end

    local character = other.Character
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function rebuildTargets()
    targets = {}
    for _, other in ipairs(Players:GetPlayers()) do
        if validTarget(other) then
            table.insert(targets, other)
        end
    end
    table.sort(targets, function(a, b)
        return a.UserId < b.UserId
    end)
end

local function restoreCamera()
    local camera = workspace.CurrentCamera
    local hum = localHumanoid()
    if camera and hum then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = hum
    end
end

local function roundSummary()
    local state = latestState
    if not state then
        return ""
    end

    local alive = tonumber(state.survivorsAlive)
    local seconds = tonumber(state.seconds)
    local pieces = {}

    if alive then
        table.insert(pieces, tostring(math.max(0, math.floor(alive))) .. " ALIVE")
    end
    if seconds then
        table.insert(pieces, tostring(math.max(0, math.floor(seconds))) .. "s")
    end

    return table.concat(pieces, "  •  ")
end

local function spectateIndex(index)
    rebuildTargets()

    if #targets == 0 then
        local summary = roundSummary()
        if player:GetAttribute("RoundParticipant") == true then
            label.Text = "ELIMINATED • WAITING FOR NEXT ROUND"
        else
            label.Text = "JOINING NEXT ROUND • WAITING FOR SURVIVORS"
        end
        if summary ~= "" then
            label.Text ..= "\n" .. summary
        end
        nextButton.Visible = false
        clearTargetHealth()
        restoreCamera()
        return
    end

    targetIndex = ((index - 1) % #targets) + 1
    local target = targets[targetIndex]
    local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")

    if hum and workspace.CurrentCamera then
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        workspace.CurrentCamera.CameraSubject = hum
        local summary = roundSummary()
        if player:GetAttribute("RoundParticipant") == true then
            label.Text = "SPECTATING  " .. target.DisplayName
        else
            label.Text = "JOINING NEXT ROUND  •  " .. target.DisplayName
        end
        if summary ~= "" then
            label.Text ..= "\n" .. summary
        end
        nextButton.Visible = #targets > 1
        bindTargetHealth(hum)
    end
end

local function refresh()
    local eliminated = player:GetAttribute("RoundEliminated") == true
    local participant = player:GetAttribute("RoundParticipant") == true
    local shouldSpectate = roundActive and (eliminated or not participant)

    if shouldSpectate then
        if not card.Visible then
            card.Visible = true
            scale.Scale = 0.88
            TweenService:Create(
                scale,
                TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Scale = 1}
            ):Play()
        end
        spectateIndex(math.max(1, targetIndex))
    else
        card.Visible = false
        targetIndex = 0
        clearTargetHealth()
        restoreCamera()
    end
end

nextButton.Activated:Connect(function()
    spectateIndex(targetIndex + 1)
end)

player:GetAttributeChangedSignal("RoundEliminated"):Connect(refresh)
player:GetAttributeChangedSignal("RoundParticipant"):Connect(refresh)
player.CharacterAdded:Connect(function()
    task.wait(0.1)
    local eliminated = player:GetAttribute("RoundEliminated") == true
    local participant = player:GetAttribute("RoundParticipant") == true

    if roundActive and (eliminated or not participant) then
        spectateIndex(math.max(1, targetIndex))
    else
        restoreCamera()
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    latestState = state
    roundActive = state.phase == "round"
    refresh()
end)
