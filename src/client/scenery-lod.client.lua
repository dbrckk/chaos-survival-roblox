local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer

local FOLDERS = {
    ChaosEnvironmentDepthLocal = {
        LowDistance = 150,
        MediumDistance = 220,
    },
    ArenaAmbientPropsLocal = {
        LowDistance = 125,
        MediumDistance = 185,
    },
    ArenaSurfaceDetailLocal = {
        LowDistance = 115,
        MediumDistance = 170,
    },
    ArenaUnderstructureLocal = {
        LowDistance = 120,
        MediumDistance = 190,
    },
    ArenaEdgeProfileLocal = {
        LowDistance = 120,
        MediumDistance = 190,
    },
    ArenaNavigationLanguageLocal = {
        LowDistance = 110,
        MediumDistance = 175,
    },
    ArenaHeroSceneryLocal = {
        LowDistance = 130,
        MediumDistance = 205,
    },
    ArenaPlatformIdentityLocal = {
        LowDistance = 105,
        MediumDistance = 165,
    },
}

local function cameraPosition()
    local camera = workspace.CurrentCamera
    return camera and camera.CFrame.Position or Vector3.zero
end

local folderCaches = {}

local function classifyDescendant(descendant)
    if descendant:IsA("BasePart")
        or descendant:IsA("ParticleEmitter")
        or descendant:IsA("Light")
    then
        return descendant
    end
    return nil
end

local function ensureCache(folder)
    local cache = folderCaches[folder]
    if cache then
        return cache
    end

    cache = {
        entries = {},
        dirty = true,
    }
    folderCaches[folder] = cache

    folder.DescendantAdded:Connect(function(descendant)
        if classifyDescendant(descendant) then
            cache.dirty = true
        end
    end)
    folder.DescendantRemoving:Connect(function(descendant)
        if classifyDescendant(descendant) then
            cache.dirty = true
        end
    end)

    return cache
end

local function refreshCache(folder, cache)
    table.clear(cache.entries)
    for _, descendant in ipairs(folder:GetDescendants()) do
        if classifyDescendant(descendant) then
            table.insert(cache.entries, descendant)
        end
    end
    cache.dirty = false
end

local function applyFolder(folder, limits, profile, origin)
    local maxDistance = profile.Name == "Low" and limits.LowDistance
        or (profile.Name == "Medium" and limits.MediumDistance or math.huge)

    local distance = (cameraPosition() - origin).Magnitude
    local visible = distance <= maxDistance
    local cache = ensureCache(folder)
    if cache.dirty then
        refreshCache(folder, cache)
    end

    for _, descendant in ipairs(cache.entries) do
        if not descendant.Parent then
            cache.dirty = true
            continue
        end

        if descendant:IsA("BasePart") then
            descendant.LocalTransparencyModifier = visible and 0 or 1
        elseif descendant:IsA("ParticleEmitter") then
            local baseEnabled = descendant:GetAttribute("LodBaseEnabled")
            if baseEnabled == nil then
                descendant:SetAttribute("LodBaseEnabled", descendant.Enabled)
                baseEnabled = descendant.Enabled
            end
            descendant.Enabled = visible and baseEnabled == true
        elseif descendant:IsA("Light") then
            local baseEnabled = descendant:GetAttribute("LodBaseEnabled")
            if baseEnabled == nil then
                descendant:SetAttribute("LodBaseEnabled", descendant.Enabled)
                baseEnabled = descendant.Enabled
            end
            descendant.Enabled = visible and baseEnabled == true
        end
    end
end

local function currentArenaOrigin()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if base and base:IsA("BasePart") then
        return base.Position
    end
    return Vector3.zero
end

task.spawn(function()
    while true do
        local profile = VfxQuality.get(player:GetAttribute("VfxQualityTier"))

        local origin = currentArenaOrigin()
        for folderName, limits in pairs(FOLDERS) do
            local folder = workspace:FindFirstChild(folderName)
            if folder then
                applyFolder(folder, limits, profile, origin)
            end
        end

        task.wait(profile.Name == "Low" and 0.65 or 0.90)
    end
end)
