local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local touchDevice = UserInputService.TouchEnabled

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosSurvivorFeed"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.Name = "EliminationFeed"
card.AnchorPoint = Vector2.new(0, 0)
card.Position = UDim2.fromScale(0.025, touchDevice and 0.18 or 0.17)
card.Size = touchDevice
    and UDim2.new(0.34, 0, 0, 38)
    or UDim2.new(0.25, 0, 0, 38)
card.BackgroundColor3 = UITheme.Colors.Panel
card.BackgroundTransparency = 1
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(180, 36)
sizeConstraint.MaxSize = Vector2.new(330, 42)
sizeConstraint.Parent = card

UITheme.addCorner(card, UITheme.Corners.Pill)
local stroke = UITheme.addStroke(card, UITheme.Colors.Red, 1, 0.42)

local accent = Instance.new("Frame")
accent.Name = "Accent"
accent.Size = UDim2.new(0, 4, 0.64, 0)
accent.Position = UDim2.fromScale(0.035, 0.18)
accent.BackgroundColor3 = UITheme.Colors.Red
accent.BorderSizePixel = 0
accent.Parent = card
UITheme.addCorner(accent, UITheme.Corners.Pill)

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -26, 1, 0)
label.Position = UDim2.fromOffset(20, 0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextColor3 = UITheme.Colors.Text
label.TextScaled = true
label.TextXAlignment = Enum.TextXAlignment.Left
label.Text = ""
label.Parent = card
UITheme.addTextConstraint(label, 11, 16)

local scale = Instance.new("UIScale")
scale.Scale = 0.92
scale.Parent = card

local phase = "waiting"
local token = 0
local watchedHumanoids = setmetatable({}, {__mode = "k"})
local playerCharacterConnections = {}
local botFolderConnection = nil

local function showElimination(displayName)
    if phase ~= "round" then
        return
    end

    local safeName = tostring(displayName or CoreLocalization.text(localeId, "SURVIVOR_LABEL"))
    if safeName == "" then
        safeName = CoreLocalization.text(localeId, "SURVIVOR_LABEL")
    end

    token += 1
    local current = token
    label.Text = CoreLocalization.text(localeId, "ELIMINATED_FEED", safeName)
    card.Visible = true
    card.BackgroundTransparency = 1
    scale.Scale = 0.90

    TweenService:Create(
        card,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.08}
    ):Play()
    TweenService:Create(
        scale,
        TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()

    task.delay(1.35, function()
        if current ~= token then
            return
        end

        TweenService:Create(
            card,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}
        ):Play()
        TweenService:Create(
            scale,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Scale = 0.92}
        ):Play()

        task.delay(0.19, function()
            if current == token then
                card.Visible = false
            end
        end)
    end)
end

local function watchHumanoid(humanoid, displayName, shouldReport)
    if not humanoid or watchedHumanoids[humanoid] then
        return
    end
    watchedHumanoids[humanoid] = true

    humanoid.Died:Connect(function()
        watchedHumanoids[humanoid] = nil
        if shouldReport() then
            showElimination(displayName())
        end
    end)
end

local function watchPlayer(other)
    if other == player or playerCharacterConnections[other] then
        return
    end

    local function bindCharacter(character)
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            watchHumanoid(
                humanoid,
                function()
                    return other.DisplayName
                end,
                function()
                    return other.Parent == Players
                        and other:GetAttribute("RoundParticipant") == true
                end
            )
        end
    end

    playerCharacterConnections[other] = other.CharacterAdded:Connect(function(character)
        task.defer(bindCharacter, character)
    end)

    if other.Character then
        bindCharacter(other.Character)
    end
end

local function watchBot(model)
    if not model:IsA("Model") or model:GetAttribute("AISurvivor") ~= true then
        return
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    watchHumanoid(
        humanoid,
        function()
            return humanoid.DisplayName ~= "" and humanoid.DisplayName or model.Name
        end,
        function()
            return model.Parent ~= nil and model:GetAttribute("AISurvivor") == true
        end
    )
end

local function bindBotFolder(folder)
    if botFolderConnection then
        botFolderConnection:Disconnect()
        botFolderConnection = nil
    end

    if not folder then
        return
    end

    for _, child in ipairs(folder:GetChildren()) do
        watchBot(child)
    end

    botFolderConnection = folder.ChildAdded:Connect(function(child)
        task.defer(watchBot, child)
    end)
end

for _, other in ipairs(Players:GetPlayers()) do
    watchPlayer(other)
end

Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(other)
    local connection = playerCharacterConnections[other]
    if connection then
        connection:Disconnect()
        playerCharacterConnections[other] = nil
    end
end)

bindBotFolder(workspace:FindFirstChild("AISurvivors"))

workspace.ChildAdded:Connect(function(child)
    if child.Name == "AISurvivors" then
        bindBotFolder(child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "AISurvivors" then
        bindBotFolder(nil)
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    phase = tostring(state.phase or "waiting")
    if phase ~= "round" then
        token += 1
        card.Visible = false
    end
end)
