local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterPolishRules = require(ReplicatedStorage.Shared.CharacterPolishRules)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local localPlayer = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local phase = "waiting"
local finalRush = false
local watched = setmetatable({}, {__mode = "k"})

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

local function ensureLight(model)
    local torso = model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("HumanoidRootPart")
    if not torso or not torso:IsA("BasePart") then
        return nil
    end

    local light = torso:FindFirstChild("ChaosCharacterPolishLight")
    if light and light:IsA("PointLight") then
        return light
    end

    light = Instance.new("PointLight")
    light.Name = "ChaosCharacterPolishLight"
    light.Brightness = 0
    light.Range = 7
    light.Shadows = false
    light.Enabled = false
    light.Parent = torso
    return light
end

local function applyModel(model)
    if not model or not model.Parent then
        return
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local player = Players:GetPlayerFromCharacter(model)
    local isLocal = player == localPlayer
    local isAI = model:GetAttribute("AISurvivor") == true
    local quality = VfxQuality.get(localPlayer:GetAttribute("VfxQualityTier"))
    local accent = accentFor(model, isLocal, isAI)

    local highlight = ensureHighlight(model)
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
        finalRush
    )

    if hasAuraHighlight then
        fillTransparency = 1
        outlineTransparency = math.min(1, outlineTransparency + 0.18)
    end

    highlight.FillTransparency = fillTransparency
    highlight.OutlineTransparency = outlineTransparency

    local light = ensureLight(model)
    if light then
        local brightness = CharacterPolishRules.lightBrightness(
            quality.Name,
            phase,
            isLocal,
            finalRush
        )
        light.Color = accent
        light.Brightness = brightness
        light.Range = isLocal and 8 or 6
        light.Enabled = brightness > 0
    end
end

local function watchModel(model)
    if watched[model] then
        applyModel(model)
        return
    end
    watched[model] = true

    applyModel(model)

    model:GetAttributeChangedSignal("ChaosAccent"):Connect(function()
        applyModel(model)
    end)

    model:GetAttributeChangedSignal("AISurvivor"):Connect(function()
        applyModel(model)
    end)

    model.ChildAdded:Connect(function(child)
        if child:IsA("Humanoid")
            or child.Name == "UpperTorso"
            or child.Name == "Torso"
            or child.Name == "HumanoidRootPart"
        then
            task.defer(applyModel, model)
        end
    end)
end

local function watchPlayer(player)
    player.CharacterAdded:Connect(watchModel)
    if player.Character then
        watchModel(player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    watchPlayer(player)
end
Players.PlayerAdded:Connect(watchPlayer)

local function watchBotFolder(folder)
    if not folder then
        return
    end

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            watchModel(child)
        end
    end

    folder.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            task.defer(watchModel, child)
        end
    end)
end

local existingBots = workspace:FindFirstChild("AISurvivors")
if existingBots then
    watchBotFolder(existingBots)
end
workspace.ChildAdded:Connect(function(child)
    if child.Name == "AISurvivors" then
        watchBotFolder(child)
    end
end)

local function refreshAll()
    for model in pairs(watched) do
        if model and model.Parent then
            applyModel(model)
        end
    end
end

localPlayer:GetAttributeChangedSignal("VfxQualityTier"):Connect(refreshAll)
localPlayer:GetAttributeChangedSignal("ReduceMotion"):Connect(refreshAll)

stateEvent.OnClientEvent:Connect(function(state)
    phase = tostring(state.phase or "waiting")
    finalRush = phase == "round" and state.finalRush == true
    refreshAll()
end)
