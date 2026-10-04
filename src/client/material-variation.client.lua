local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArenaMaterialRules = require(ReplicatedStorage.Shared.ArenaMaterialRules)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer

local tracked = {}

local function hashName(name)
    local value = 17
    for i = 1, #name do
        value = (value * 31 + string.byte(name, i)) % 9973
    end
    return value
end

local function eligible(part)
    if not part:IsA("BasePart") then
        return false
    end

    if part.Material == Enum.Material.Neon then
        return false
    end

    if part:GetAttribute("ArenaMobilityPad") == true
        or part:GetAttribute("CollapsePhase") ~= nil
    then
        return false
    end

    local name = part.Name
    if string.find(name, "Glow")
        or string.find(name, "Warning")
        or string.find(name, "Hazard")
        or string.find(name, "KillPlane")
        or string.find(name, "Spawn")
    then
        return false
    end

    return part.Material == Enum.Material.Metal
        or part.Material == Enum.Material.DiamondPlate
        or part.Material == Enum.Material.SmoothPlastic
end

local function applyPart(part, profile, variant, allowMaterialSwap)
    if not eligible(part) then
        return
    end

    local base = part:GetAttribute("MaterialPassBaseColor")
    if typeof(base) ~= "Color3" then
        base = part.Color
        part:SetAttribute("MaterialPassBaseColor", base)
    end

    local baseMaterial = part:GetAttribute("MaterialPassBaseMaterial")
    if typeof(baseMaterial) ~= "EnumItem" then
        baseMaterial = part.Material
        part:SetAttribute("MaterialPassBaseMaterial", baseMaterial)
    end

    local hash = hashName(part:GetFullName())
    local centered = ((hash % 101) / 100) * 2 - 1
    local maxShift = profile.Name == "Low" and 0.018
        or (profile.Name == "Medium" and 0.032 or 0.045)
    local shift = centered * maxShift

    if allowMaterialSwap == true then
        local bucket = hash % 100
        part.Material = ArenaMaterialRules.targetMaterial(
            variant,
            baseMaterial,
            bucket,
            profile.Name
        )
    else
        part.Material = baseMaterial
    end

    if shift >= 0 then
        part.Color = base:Lerp(Color3.new(1, 1, 1), shift)
    else
        part.Color = base:Lerp(Color3.new(0, 0, 0), -shift)
    end
end

local function restore()
    for part in pairs(tracked) do
        if part and part.Parent then
            local base = part:GetAttribute("MaterialPassBaseColor")
            if typeof(base) == "Color3" then
                part.Color = base
            end

            local baseMaterial = part:GetAttribute("MaterialPassBaseMaterial")
            if typeof(baseMaterial) == "EnumItem" then
                part.Material = baseMaterial
            end
        end
    end
    table.clear(tracked)
end

local function applyFolder(folder, profile, variant, allowMaterialSwap)
    if not folder then
        return
    end

    for _, descendant in ipairs(folder:GetDescendants()) do
        if eligible(descendant) then
            tracked[descendant] = true
            applyPart(descendant, profile, variant, allowMaterialSwap)
        end
    end
end

local function rebuild()
    restore()

    local generated = workspace:FindFirstChild("GeneratedMap")
    if not generated then
        return
    end

    local profile = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local arena = generated:FindFirstChild("Arena")
    local lobby = generated:FindFirstChild("Lobby")
    local variant = tostring(arena and arena:GetAttribute("VariantId") or "Classic")

    applyFolder(arena and arena:FindFirstChild("Decor"), profile, variant, true)
    applyFolder(lobby and lobby:FindFirstChild("Decor"), profile, nil, false)
end

local mapConnection = nil

local function bindGeneratedMap(generated)
    if mapConnection then
        mapConnection:Disconnect()
        mapConnection = nil
    end

    if generated then
        mapConnection = generated.ChildAdded:Connect(function(child)
            if child.Name == "Arena" then
                task.delay(0.10, rebuild)
            end
        end)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindGeneratedMap(child)
        task.delay(0.12, rebuild)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindGeneratedMap(nil)
        restore()
    end
end)

bindGeneratedMap(workspace:FindFirstChild("GeneratedMap"))

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    task.defer(rebuild)
end)

rebuild()
