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
local decorRemovingConnection = nil
local lodReturnConnections = {}
local disconnectMap = nil
local currentDecor = nil
local lightBrightness = setmetatable({}, {__mode = "k"})

local function tierName()
    return VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), true).Name
end

local function applyDecor()
    local decor = currentDecor
    if not decor or not decor.Parent then
        return
    end
    MobileReadabilityKit.applyTree(decor, tierName(), lightBrightness)
end

-- One attribute listener per tracked Neon part (not per frame).
-- All listeners are released when parts stream out or maps change.
local function stopWatching(root)
    local function disconnect(part)
        local connection = lodReturnConnections[part]
        if connection then
            connection:Disconnect()
            lodReturnConnections[part] = nil
        end
    end
    disconnect(root)
    for _, part in ipairs(root:GetDescendants()) do
        disconnect(part)
    end
end

local function watchNeon(root, decor)
    local function register(part)
        if not part:IsA("BasePart")
            or part.Material ~= Enum.Material.Neon
            or lodReturnConnections[part] then
            return
        end
        lodReturnConnections[part] = MobileReadabilityKit.watchLodReturn(
            part, function(revealed)
                if currentDecor == decor and revealed:IsDescendantOf(decor) then
                    MobileReadabilityKit.applyInstance(
                        revealed, tierName(), lightBrightness)
                end
            end)
    end
    register(root)
    for _, part in ipairs(root:GetDescendants()) do
        register(part)
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
    if decorRemovingConnection then
        decorRemovingConnection:Disconnect()
        decorRemovingConnection = nil
    end
    for part, connection in pairs(lodReturnConnections) do
        connection:Disconnect()
        lodReturnConnections[part] = nil
    end
    currentDecor = decor
    if not decor then
        return
    end
    watchNeon(decor, decor)
    decorRemovingConnection = decor.DescendantRemoving:Connect(stopWatching)
    decorConnection = decor.DescendantAdded:Connect(function(descendant)
        watchNeon(descendant, decor)
        task.defer(function()
            -- Discard stale deferred callbacks from a previous arena.
            if currentDecor == decor and descendant:IsDescendantOf(decor) then
                MobileReadabilityKit.applyTree(
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
