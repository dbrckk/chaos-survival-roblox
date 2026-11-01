-- Sync a short, client-only debris cascade to the same server-owned
-- StructuralFracturePhase replication as the real landmark collapse.
-- No extra remote, client damage, camera flash or permanent particle loop.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local RuinKit = require(script.Parent.ArenaRuinBurstKit)

local player = Players.LocalPlayer
local visuals = Instance.new("Folder")
visuals.Name = "ArenaCataclysmDebrisLocal"
visuals.Parent = workspace

local watchedMap = nil
local watchedArena = nil
local watchedPlatforms = nil
local mapSignals = {}
local arenaSignals = {}
local containerSignals = {}
local partSignals = {}
local seen = {}

local function disconnectAll(list)
    for _, connection in ipairs(list) do connection:Disconnect() end
    table.clear(list)
end

local function clearParts()
    for part, connection in pairs(partSignals) do
        connection:Disconnect()
        partSignals[part] = nil
    end
    table.clear(seen)
    disconnectAll(containerSignals)
    watchedPlatforms = nil
end

local function onFracture(platform)
    if not platform or not platform.Parent then return end
    local phase = platform:GetAttribute("StructuralFracturePhase")
    if phase ~= "Broken" then
        seen[platform] = nil
        return
    end
    if seen[platform] then return end
    seen[platform] = true

    -- A late-streaming instance already displays the server-authored
    -- ruined pose. Do not replay its old explosion several seconds later.
    local started = platform:GetAttribute("StructuralFractureStartedAt")
    if type(started) ~= "number"
        or math.abs(workspace:GetServerTimeNow() - started) > 2.5
        or player:GetAttribute("ReduceMotion") == true then
        return
    end

    local arena = watchedArena
    if not arena or not arena.Parent then return end
    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local tier = VfxQuality.deviceTier(
        player:GetAttribute("VfxQualityTier"),
        UserInputService.TouchEnabled).Name
    RuinKit.burst(visuals, platform, tier, VisualTheme.arena(variant))
end

local function trackPart(platform)
    if not platform:IsA("BasePart") or partSignals[platform] then return end
    partSignals[platform] = platform:GetAttributeChangedSignal(
        "StructuralFracturePhase"):Connect(function()
        onFracture(platform)
    end)
    -- On a fresh client with a replicated broken gateway we keep the
    -- real ruined geometry, not a second debris effect.
    if platform:GetAttribute("StructuralFracturePhase") == "Broken" then
        seen[platform] = true
    end
end

local function bindPlatforms(container)
    if watchedPlatforms == container then return end
    clearParts()
    watchedPlatforms = container
    if not container then return end
    containerSignals[#containerSignals + 1] =
        container.ChildAdded:Connect(trackPart)
    containerSignals[#containerSignals + 1] =
        container.ChildRemoved:Connect(function(part)
            if partSignals[part] then
                partSignals[part]:Disconnect()
                partSignals[part] = nil
            end
            seen[part] = nil
        end)
    for _, platform in ipairs(container:GetChildren()) do
        trackPart(platform)
    end
end

local function bindArena(arena)
    if watchedArena == arena then return end
    disconnectAll(arenaSignals)
    bindPlatforms(nil)
    watchedArena = arena
    visuals:ClearAllChildren()
    if not arena then return end
    arenaSignals[#arenaSignals + 1] =
        arena.ChildAdded:Connect(function(child)
            if child.Name == "Platforms" then
                bindPlatforms(arena:FindFirstChild("Platforms"))
            end
        end)
    arenaSignals[#arenaSignals + 1] =
        arena.ChildRemoved:Connect(function(child)
            if child == watchedPlatforms then
                bindPlatforms(arena:FindFirstChild("Platforms"))
            end
        end)
    bindPlatforms(arena:FindFirstChild("Platforms"))
end

local function bindMap(generated)
    if watchedMap == generated then return end
    disconnectAll(mapSignals)
    bindArena(nil)
    watchedMap = generated
    if not generated then return end
    mapSignals[#mapSignals + 1] =
        generated.ChildAdded:Connect(function(child)
            if child.Name == "Arena" then
                bindArena(generated:FindFirstChild("Arena"))
            end
        end)
    mapSignals[#mapSignals + 1] =
        generated.ChildRemoved:Connect(function(child)
            if child == watchedArena then
                bindArena(generated:FindFirstChild("Arena"))
            end
        end)
    bindArena(generated:FindFirstChild("Arena"))
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap"
        and child == workspace:FindFirstChild("GeneratedMap") then
        bindMap(child)
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child == watchedMap then
        bindMap(workspace:FindFirstChild("GeneratedMap"))
    end
end)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    if player:GetAttribute("ReduceMotion") == true then
        visuals:ClearAllChildren()
    end
end)

bindMap(workspace:FindFirstChild("GeneratedMap"))
