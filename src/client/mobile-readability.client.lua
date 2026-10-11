-- Touch-only tint and light balancing for streamed arena decoration.
-- Does not change hazard warnings, physics, light source count or controls.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not UserInputService.TouchEnabled then
    return
end

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local MobileReadabilityKit = require(script.Parent.MobileReadabilityKit)

local player = Players.LocalPlayer
local decorConnection = nil
local disconnectMap = nil
local currentDecor = nil
local lightBrightness = setmetatable({}, {__mode = "k"})

local function tierName()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
end

local function applyDecor()
    local decor = currentDecor
    if not decor or not decor.Parent then
        return
    end
    local tier = tierName()
    for _, descendant in ipairs(decor:GetDescendants()) do
        MobileReadabilityKit.applyInstance(descendant, tier, lightBrightness)
    end
end

local function bindDecor(decor)
    if currentDecor == decor then
        return
    end
    if decorConnection then
        decorConnection:Disconnect()
        decorConnection = nil
    end
    currentDecor = decor
    if not decor then
        return
    end
    decorConnection = decor.DescendantAdded:Connect(function(descendant)
        task.defer(function()
            -- Discard stale deferred callbacks from a previous arena.
            if currentDecor == decor and descendant:IsDescendantOf(decor) then
                MobileReadabilityKit.applyInstance(
                    descendant, tierName(), lightBrightness)
            end
        end)
    end)
    applyDecor()
end

local function bindMap()
    if disconnectMap then
        disconnectMap()
        disconnectMap = nil
    end
    bindDecor(nil)
    local generated = workspace:FindFirstChild("GeneratedMap")
    if generated then
        disconnectMap = MobileReadabilityKit.watch(generated, bindDecor)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(bindMap)
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(bindMap)
    end
end)
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(applyDecor)
bindMap()
