local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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
card.BackgroundColor3 = Color3.fromRGB(18, 21, 30)
card.BackgroundTransparency = 0.08
card.Visible = false
card.Parent = gui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)

local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = card

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.68, -14, 1, -12)
label.Position = UDim2.fromOffset(12, 6)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextColor3 = Color3.fromRGB(235, 240, 250)
label.TextScaled = true
label.TextWrapped = true
label.TextXAlignment = Enum.TextXAlignment.Left
label.Text = "SPECTATING"
label.Parent = card

local nextButton = Instance.new("TextButton")
nextButton.AnchorPoint = Vector2.new(1, 0.5)
nextButton.Position = UDim2.new(1, -8, 0.5, 0)
nextButton.Size = UDim2.new(0.28, 0, 0.72, 0)
nextButton.BackgroundColor3 = Color3.fromRGB(65, 120, 220)
nextButton.Font = Enum.Font.GothamBlack
nextButton.TextColor3 = Color3.new(1, 1, 1)
nextButton.TextScaled = true
nextButton.Text = "NEXT"
nextButton.Parent = card
Instance.new("UICorner", nextButton).CornerRadius = UDim.new(0, 12)

local roundActive = false
local targets = {}
local targetIndex = 0

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

local function spectateIndex(index)
    rebuildTargets()

    if #targets == 0 then
        if player:GetAttribute("RoundParticipant") == true then
            label.Text = "ELIMINATED • WAITING FOR NEXT ROUND"
        else
            label.Text = "JOINING NEXT ROUND • WAITING FOR SURVIVORS"
        end
        nextButton.Visible = false
        restoreCamera()
        return
    end

    targetIndex = ((index - 1) % #targets) + 1
    local target = targets[targetIndex]
    local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")

    if hum and workspace.CurrentCamera then
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        workspace.CurrentCamera.CameraSubject = hum
        if player:GetAttribute("RoundParticipant") == true then
            label.Text = "SPECTATING  " .. target.DisplayName
        else
            label.Text = "JOINING NEXT ROUND  •  SPECTATING  " .. target.DisplayName
        end
        nextButton.Visible = #targets > 1
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
    roundActive = state.phase == "round"
    refresh()
end)
