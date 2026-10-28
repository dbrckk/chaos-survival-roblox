local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local CharacterPolishRules = require(ReplicatedStorage.Shared.CharacterPolishRules)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local CharacterPolishRegistry = require(script.Parent.CharacterPolishRegistry)
local CharacterPolishLightKit = require(script.Parent.CharacterPolishLightKit)

local localPlayer = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local phase = "waiting"
local finalRush = false
local botFolder = nil
local botFolderConnection = nil
local botFolderRemovedConnection = nil
local playerConnections = setmetatable({}, {__mode = "k"})

local function accentFor(model, isLocal, isAI)
    local accent = model:GetAttribute("ChaosAccent")
    if typeof(accent) == "Color3" then
        return accent
    end
    if isLocal then
        return Color3.fromRGB(70, 205, 255)
    elseif isAI then
        return Color3.fromRGB(105, 220, 185)
    end
    return Color3.fromRGB(145, 175, 215)
end

local function ensureHighlight(model)
    local highlight = model:FindFirstChild("ChaosCharacterPolishHighlight")
    if highlight and highlight:IsA("Highlight") then
        return highlight
    end

    highlight = Instance.new("Highlight")
    highlight.Name = "ChaosCharacterPolishHighlight"
    highlight.Adornee = model
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 1
    highlight.Parent = model
    return highlight
end

local function applyModel(model)
    if not model or not model.Parent then
        return
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        local highlight = model:FindFirstChild("ChaosCharacterPolishHighlight")
        if highlight and highlight:IsA("Highlight") then
            highlight.Enabled = false
        end
        CharacterPolishLightKit.apply(model, 0, nil, false)
        return
    end

    local player = Players:GetPlayerFromCharacter(model)
    local isLocal = player == localPlayer
    local isAI = model:GetAttribute("AISurvivor") == true
    local quality = VfxQuality.get(localPlayer:GetAttribute("VfxQualityTier"))
    local accent = accentFor(model, isLocal, isAI)

    local activeParticipant = true
    if player then
        activeParticipant = player:GetAttribute("RoundParticipant") == true
            and player:GetAttribute("RoundEliminated") ~= true
    elseif isAI then
        local hum = model:FindFirstChildOfClass("Humanoid")
        activeParticipant = hum ~= nil and hum.Health > 0
    end

    local highlight = ensureHighlight(model)
    highlight.Enabled = true
    local auraHighlight = model:FindFirstChild("ChaosAuraHighlight")
    local hasAuraHighlight = auraHighlight and auraHighlight:IsA("Highlight")

    highlight.FillColor = accent:Lerp(Color3.new(1, 1, 1), 0.08)
    highlight.OutlineColor = accent:Lerp(Color3.new(1, 1, 1), 0.28)

    local fillTransparency = CharacterPolishRules.fillTransparency(
        quality.Name,
        phase,
        isLocal,
        finalRush
    )
    local outlineTransparency = CharacterPolishRules.outlineTransparency(
        quality.Name,
        phase,
        isLocal,
        isAI,
        finalRush,
        activeParticipant
    )

    if hasAuraHighlight then
        fillTransparency = 1
        outlineTransparency = math.min(1, outlineTransparency + 0.18)
    end

    -- Third-person mobile cameras are frequently blocked by raised decks,
    -- pylons and overhead structures. Only the LOCAL player gets a subtle
    -- outline through scenery during a live round; bots and other players
    -- retain occluded outlines. Never reveal enemies or remote positions.
    local localMobileRound = isLocal and UserInputService.TouchEnabled
        and activeParticipant and (phase == "ready" or phase == "round")
    highlight.DepthMode = localMobileRound
        and Enum.HighlightDepthMode.AlwaysOnTop
        or Enum.HighlightDepthMode.Occluded
    highlight.FillTransparency = localMobileRound and 1 or fillTransparency
    highlight.OutlineTransparency = localMobileRound
        and math.min(outlineTransparency, 0.52) or outlineTransparency

    local brightness = CharacterPolishRules.lightBrightness(
        quality.Name, phase, isLocal, finalRush, activeParticipant,
        localPlayer:GetAttribute("ReduceMotion") == true,
        localMobileRound
    )
    -- A neutral, tightly ranged fill lifts the player's silhouette from
    -- night arenas without saturating their skin or the surrounding neon.
    -- Remote players and bots retain the original accent-lit material.
    local fillColor = localMobileRound
        and Color3.fromRGB(231, 240, 255) or accent
    -- Keep the active light enabled during routine phase/rig refreshes.
    -- Zero brightness allocates nothing and disables old lights immediately.
    CharacterPolishLightKit.apply(model, brightness, fillColor, isLocal)
end

local function removePolish(model)
    local highlight = model:FindFirstChild("ChaosCharacterPolishHighlight")
    if highlight and highlight:IsA("Highlight") then
        highlight:Destroy()
    end
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") then
            local light = child:FindFirstChild("ChaosCharacterPolishLight")
            if light and light:IsA("PointLight") then
                light:Destroy()
            end
        end
    end
end

local registry = CharacterPolishRegistry.new(applyModel, removePolish)
local function watchModel(model)
    registry.watch(model)
end

local function watchPlayer(player)
    if playerConnections[player] then return end
    local connections = {}
    playerConnections[player] = connections
    table.insert(connections, player.CharacterAdded:Connect(watchModel))
    table.insert(connections, player.CharacterRemoving:Connect(registry.stop))
    table.insert(connections,
        player:GetAttributeChangedSignal("RoundParticipant"):Connect(function()
            if player.Character then registry.refresh(player.Character) end
        end))
    table.insert(connections,
        player:GetAttributeChangedSignal("RoundEliminated"):Connect(function()
            if player.Character then registry.refresh(player.Character) end
        end))
    if player.Character then watchModel(player.Character) end
end

for _, player in ipairs(Players:GetPlayers()) do
    watchPlayer(player)
end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(player)
    if player.Character then registry.stop(player.Character) end
    local connections = playerConnections[player]
    if connections then
        for _, connection in ipairs(connections) do connection:Disconnect() end
        playerConnections[player] = nil
    end
end)

local function watchBotFolder(nextFolder)
    if botFolderConnection then
        botFolderConnection:Disconnect()
        botFolderConnection = nil
    end
    if botFolderRemovedConnection then
        botFolderRemovedConnection:Disconnect()
        botFolderRemovedConnection = nil
    end
    if botFolder and botFolder ~= nextFolder then
        for _, model in ipairs(botFolder:GetChildren()) do
            if model:IsA("Model") then registry.stop(model) end
        end
    end
    botFolder = nextFolder
    if not nextFolder then return end
    for _, model in ipairs(nextFolder:GetChildren()) do
        if model:IsA("Model") then watchModel(model) end
    end
    botFolderConnection = nextFolder.ChildAdded:Connect(function(model)
        if model:IsA("Model") then watchModel(model) end
    end)
    botFolderRemovedConnection = nextFolder.ChildRemoved:Connect(function(model)
        if model:IsA("Model") then registry.stop(model) end
    end)
end

watchBotFolder(workspace:FindFirstChild("AISurvivors"))
workspace.ChildAdded:Connect(function(child)
    if child.Name == "AISurvivors" and child ~= botFolder then
        watchBotFolder(child)
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child == botFolder then watchBotFolder(nil) end
end)

local function refreshAll()
    registry.refreshAll()
end

localPlayer:GetAttributeChangedSignal("VfxQualityTier"):Connect(refreshAll)
localPlayer:GetAttributeChangedSignal("ReduceMotion"):Connect(refreshAll)

stateEvent.OnClientEvent:Connect(function(state)
    local snapshot = type(state) == "table" and state or {}
    phase = tostring(snapshot.phase or "waiting")
    finalRush = phase == "round" and snapshot.finalRush == true
    refreshAll()
end)
