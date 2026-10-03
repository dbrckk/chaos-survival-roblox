local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FirstTimeExperience = require(ReplicatedStorage.Shared.FirstTimeExperience)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local currentState = {
    phase = "waiting",
    voteOptions = nil,
}

local markerFolder = Instance.new("Folder")
markerFolder.Name = "RookieWorldGuideLocal"
markerFolder.Parent = workspace

local currentTarget = nil
local highlight = nil
local billboard = nil

local function clearMarker()
    if highlight then
        highlight:Destroy()
        highlight = nil
    end
    if billboard then
        billboard:Destroy()
        billboard = nil
    end
    currentTarget = nil
end

local function characterRoot()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return root and root:IsA("BasePart") and root or nil
end

local function nearestPart(parts)
    local root = characterRoot()
    if not root then
        return nil
    end

    local nearest = nil
    local nearestDistance = math.huge
    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            local distance = (part.Position - root.Position).Magnitude
            if distance < nearestDistance then
                nearest = part
                nearestDistance = distance
            end
        end
    end
    return nearest
end

local function practicePads()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    local activities = lobby and lobby:FindFirstChild("Activities")
    if not activities then
        return {}
    end

    local result = {}
    for _, child in ipairs(activities:GetChildren()) do
        if child:IsA("BasePart") and child:GetAttribute("LobbyPracticePad") == true then
            table.insert(result, child)
        end
    end
    return result
end

local function arenaPads()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local mechanics = arena and arena:FindFirstChild("Mechanics")
    if not mechanics then
        return {}
    end

    local result = {}
    for _, child in ipairs(mechanics:GetChildren()) do
        if child:IsA("BasePart") and child:GetAttribute("ArenaMobilityPad") == true then
            table.insert(result, child)
        end
    end
    return result
end

local function mark(part, text, color)
    if currentTarget == part and highlight and billboard then
        return
    end

    clearMarker()
    if not part or not part.Parent then
        return
    end

    currentTarget = part

    highlight = Instance.new("Highlight")
    highlight.Name = "RookieGuideHighlight"
    highlight.Adornee = part
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = color
    highlight.FillTransparency = 0.76
    highlight.OutlineColor = color:Lerp(Color3.new(1, 1, 1), 0.35)
    highlight.OutlineTransparency = 0.05
    highlight.Parent = markerFolder

    billboard = Instance.new("BillboardGui")
    billboard.Name = "RookieGuideLabel"
    billboard.Adornee = part
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(150, 36)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
    billboard.MaxDistance = 60
    billboard.Parent = markerFolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
    label.BackgroundTransparency = 0.16
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBlack
    label.Text = text
    label.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.42)
    label.TextScaled = true
    label.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = label
end

local function refresh()
    if player:GetAttribute("DataLoaded") ~= true then
        clearMarker()
        return
    end

    local games = math.max(0, math.floor(tonumber(player:GetAttribute("Games")) or 0))
    if not FirstTimeExperience.isFirstRound(games) then
        clearMarker()
        return
    end

    if currentState.phase == "intermission"
        and currentState.voteOptions
    then
        clearMarker()
        return
    end

    if games == 0
        and (tonumber(player:GetAttribute("LobbyPracticeUses")) or 0) <= 0
        and (currentState.phase == "waiting" or currentState.phase == "intermission")
    then
        mark(
            nearestPart(practicePads()),
            "TRY BOOST",
            Color3.fromRGB(80, 220, 255)
        )
        return
    end

    if currentState.phase == "ready" then
        mark(
            nearestPart(arenaPads()),
            "ESCAPE PAD",
            Color3.fromRGB(120, 225, 255)
        )
        return
    end

    clearMarker()
end

stateEvent.OnClientEvent:Connect(function(state)
    currentState = state or currentState
    refresh()
end)

player:GetAttributeChangedSignal("DataLoaded"):Connect(refresh)
player:GetAttributeChangedSignal("Games"):Connect(refresh)
player:GetAttributeChangedSignal("LobbyPracticeUses"):Connect(refresh)
player:GetAttributeChangedSignal("RoundParticipant"):Connect(refresh)
player.CharacterAdded:Connect(function()
    task.delay(0.35, refresh)
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.delay(0.35, refresh)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clearMarker()
    end
end)

task.defer(refresh)
