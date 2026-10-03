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
}

local function cameraPosition()
    local camera = workspace.CurrentCamera
    return camera and camera.CFrame.Position or Vector3.zero
end

local function applyFolder(folder, limits, profile, origin)
    local maxDistance = profile.Name == "Low" and limits.LowDistance
        or (profile.Name == "Medium" and limits.MediumDistance or math.huge)

    local distance = (cameraPosition() - origin).Magnitude
    local visible = distance <= maxDistance

    for _, descendant in ipairs(folder:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local baseTransparency = descendant:GetAttribute("LodBaseTransparency")
            if baseTransparency == nil then
                baseTransparency = descendant.Transparency
                descendant:SetAttribute("LodBaseTransparency", baseTransparency)
            end
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

local function originFor(folderName)
    local generated = workspace:FindFirstChild("GeneratedMap")
    if folderName == "ChaosEnvironmentDepthLocal" then
        local arena = generated and generated:FindFirstChild("Arena")
        local base = arena and arena:FindFirstChild("Base")
        if base and base:IsA("BasePart") then
            return base.Position
        end
    end

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

        for folderName, limits in pairs(FOLDERS) do
            local folder = workspace:FindFirstChild(folderName)
            if folder then
                applyFolder(folder, limits, profile, originFor(folderName))
            end
        end

        task.wait(profile.Name == "Low" and 0.65 or 0.90)
    end
end)
