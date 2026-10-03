local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local CharacterPolishRules = require(ReplicatedStorage.Shared.CharacterPolishRules)

local localPlayer = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local watchedCharacters = setmetatable({}, {__mode = "k"})
local finalRush = false

local function profile()
    return VfxQuality.get(localPlayer:GetAttribute("VfxQualityTier"))
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

local function watchCharacter(character)
    if watchedCharacters[character] then
        return
    end
    watchedCharacters[character] = true

    applyCharacter(character)
    character.DescendantAdded:Connect(function(descendant)
        if descendant.Name == "ChaosAura"
            or descendant.Name == "ChaosAuraLight"
            or descendant.Name == "ChaosTrail"
            or descendant.Name == "AISurvivorCosmeticTrail"
            or descendant.Name == "ChaosAuraHighlight"
        then
            task.defer(applyObject, descendant)
        end
    end)
end

local function watchPlayer(player)
    player.CharacterAdded:Connect(watchCharacter)
    if player.Character then
        watchCharacter(player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    watchPlayer(player)
end
Players.PlayerAdded:Connect(watchPlayer)

local function refreshAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            applyCharacter(player.Character)
        end
    end

    local bots = workspace:FindFirstChild("AISurvivors")
    if bots then
        for _, model in ipairs(bots:GetChildren()) do
            if model:IsA("Model") then
                watchCharacter(model)
                applyCharacter(model)
            end
        end
    end
end

local function watchBotFolder(folder)
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then
            watchCharacter(model)
        end
    end
    folder.ChildAdded:Connect(function(model)
        if model:IsA("Model") then
            task.defer(watchCharacter, model)
        end
    end)
end

local bots = workspace:FindFirstChild("AISurvivors")
if bots then
    watchBotFolder(bots)
end
workspace.ChildAdded:Connect(function(child)
    if child.Name == "AISurvivors" then
        watchBotFolder(child)
    end
end)

localPlayer:GetAttributeChangedSignal("VfxQualityTier"):Connect(refreshAll)
localPlayer:GetAttributeChangedSignal("ReduceMotion"):Connect(refreshAll)

stateEvent.OnClientEvent:Connect(function(state)
    local nextFinalRush = state.phase == "round" and state.finalRush == true
    if nextFinalRush ~= finalRush then
        finalRush = nextFinalRush
        refreshAll()
    end
end)
