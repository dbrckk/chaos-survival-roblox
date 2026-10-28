local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local CharacterPolishRules = require(ReplicatedStorage.Shared.CharacterPolishRules)
local CosmeticQualityRegistry = require(script.Parent.CosmeticQualityRegistry)

local localPlayer = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local finalRush = false
local botFolder = nil
local botFolderConnection = nil
local botFolderRemovedConnection = nil
local playerConnections = {}

local function profile()
    return VfxQuality.deviceTier(localPlayer:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled)
end

local function applyObject(instance)
    local tier = profile()
    local reducedMotion = localPlayer:GetAttribute("ReduceMotion") == true

    if instance.Name == "ChaosAura" and instance:IsA("ParticleEmitter") then
        local rate
        if tier.Name == "Low" then
            rate = 5
        elseif tier.Name == "Medium" then
            rate = 11
        else
            rate = 18
        end
        if reducedMotion then
            rate = math.max(3, math.floor(rate * 0.72))
        end
        if finalRush then
            rate = 0
        end
        instance.Rate = rate
    elseif instance.Name == "ChaosAuraLight" and instance:IsA("PointLight") then
        if finalRush or tier.Name == "Low" then
            instance.Enabled = false
        else
            instance.Enabled = true
            instance.Brightness = tier.Name == "Medium" and 0.46 or 0.85
            instance.Range = tier.Name == "Medium" and 7 or 9
        end
    elseif (instance.Name == "ChaosTrail"
        or instance.Name == "AISurvivorCosmeticTrail")
        and instance:IsA("Trail")
    then
        local lifetime = CharacterPolishRules.trailLifetime(
            tier.Name,
            reducedMotion,
            finalRush
        )
        local emission = tier.Name == "Low" and 0.52
            or (tier.Name == "Medium" and 0.66 or 0.76)

        if finalRush then
            emission *= 0.52
        elseif reducedMotion then
            emission *= 0.78
        end

        instance.Lifetime = lifetime
        instance.LightEmission = emission
        instance.LightInfluence = tier.Name == "High" and 0.12 or 0
    elseif instance.Name == "ChaosAuraHighlight" and instance:IsA("Highlight") then
        if finalRush then
            instance.FillTransparency = 0.98
            instance.OutlineTransparency = 0.72
        elseif tier.Name == "Low" then
            instance.FillTransparency = 0.94
            instance.OutlineTransparency = 0.42
        elseif tier.Name == "Medium" then
            instance.FillTransparency = 0.88
            instance.OutlineTransparency = 0.30
        else
            instance.FillTransparency = 0.82
            instance.OutlineTransparency = 0.22
        end
    end
end

local function applyCharacter(character)
    for _, descendant in ipairs(character:GetDescendants()) do
        applyObject(descendant)
    end
end

local observers = CosmeticQualityRegistry.new(applyCharacter, applyObject)

local function watchPlayer(player)
    if playerConnections[player] then return end
    local connections = {}
    playerConnections[player] = connections
    table.insert(connections, player.CharacterAdded:Connect(observers.watch))
    table.insert(connections, player.CharacterRemoving:Connect(observers.stop))
    if player.Character then observers.watch(player.Character) end
end

for _, player in ipairs(Players:GetPlayers()) do
    watchPlayer(player)
end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(player)
    if player.Character then observers.stop(player.Character) end
    local connections = playerConnections[player]
    if connections then
        for _, connection in ipairs(connections) do connection:Disconnect() end
        playerConnections[player] = nil
    end
end)

-- Models are registered on spawn/stream-in; changing quality traverses
-- each watched rig once, without rescanning Players and all bot children.
local function refreshAll()
    observers.refreshAll()
end

local function watchBotFolder(folder)
    if botFolderConnection then
        botFolderConnection:Disconnect()
        botFolderConnection = nil
    end
    if botFolderRemovedConnection then
        botFolderRemovedConnection:Disconnect()
        botFolderRemovedConnection = nil
    end
    if botFolder and botFolder ~= folder then
        for _, model in ipairs(botFolder:GetChildren()) do
            if model:IsA("Model") then observers.stop(model) end
        end
    end
    botFolder = folder
    if not folder then return end

    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then observers.watch(model) end
    end
    botFolderConnection = folder.ChildAdded:Connect(function(model)
        if not model:IsA("Model") then return end
        task.defer(function()
            if botFolder == folder and model.Parent == folder then
                observers.watch(model)
            end
        end)
    end)
    botFolderRemovedConnection = folder.ChildRemoved:Connect(function(model)
        if model:IsA("Model") then observers.stop(model) end
    end)
end

watchBotFolder(workspace:FindFirstChild("AISurvivors"))

workspace.ChildAdded:Connect(function(child)
    if child.Name == "AISurvivors" and child ~= botFolder then
        watchBotFolder(child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child == botFolder then
        watchBotFolder(nil)
    end
end)

localPlayer:GetAttributeChangedSignal("VfxQualityTier"):Connect(refreshAll)
localPlayer:GetAttributeChangedSignal("ReduceMotion"):Connect(refreshAll)

stateEvent.OnClientEvent:Connect(function(state)
    -- RoundState can briefly be malformed during streaming or reconnect.
    -- A bad payload must not crash the client cosmetic-quality controller.
    local nextFinalRush = type(state) == "table"
        and state.phase == "round" and state.finalRush == true
    if nextFinalRush ~= finalRush then
        finalRush = nextFinalRush
        refreshAll()
    end
end)
