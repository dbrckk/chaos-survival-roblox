local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not UserInputService.TouchEnabled then
    return
end

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local decorConnection = nil
local mapConnection = nil
local currentDecor = nil
local lightBrightness = setmetatable({}, {__mode = "k"})

local function qualityProfile()
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    if tier.Name == "Low" then
        return 0.18, 0.62
    elseif tier.Name == "Medium" then
        return 0.12, 0.72
    end
    return 0.08, 0.80
end

local function isGameplayEdge(part)
    local name = part.Name
    return string.sub(name, 1, 4) == "Edge"
        or string.find(name, "PlatformGlow", 1, true) ~= nil
        or string.find(name, "SpawnGlow", 1, true) ~= nil
end

local function applyInstance(instance)
    local decorTransparency, lightScale = qualityProfile()

    if instance:IsA("BasePart") and instance.Material == Enum.Material.Neon then
        if isGameplayEdge(instance) then
            instance.LocalTransparencyModifier = math.min(0.07, decorTransparency * 0.45)
        else
            instance.LocalTransparencyModifier = decorTransparency
        end
    elseif instance:IsA("PointLight")
        or instance:IsA("SpotLight")
        or instance:IsA("SurfaceLight")
    then
        local original = lightBrightness[instance]
        if original == nil then
            original = instance.Brightness
            lightBrightness[instance] = original
        end
        instance.Brightness = original * lightScale
    end
end

local function applyDecor()
    if not currentDecor or not currentDecor.Parent then
        return
    end

    for _, descendant in ipairs(currentDecor:GetDescendants()) do
        applyInstance(descendant)
    end
end

local function bind()
    if decorConnection then
        decorConnection:Disconnect()
        decorConnection = nil
    end
    if mapConnection then
        mapConnection:Disconnect()
        mapConnection = nil
    end
    currentDecor = nil

    local generated = workspace:FindFirstChild("GeneratedMap")
    if not generated then
        return
    end

    mapConnection = generated.ChildAdded:Connect(function(child)
        if child.Name == "Arena" then
            task.defer(bind)
        end
    end)

    local arena = generated:FindFirstChild("Arena")
    local decor = arena and arena:FindFirstChild("Decor")
    if not decor then
        return
    end

    currentDecor = decor
    decorConnection = decor.DescendantAdded:Connect(function(descendant)
        task.defer(applyInstance, descendant)
    end)
    applyDecor()
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(bind)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(bind)
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(applyDecor)

bind()
