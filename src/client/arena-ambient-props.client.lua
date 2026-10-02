local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "ArenaAmbientPropsLocal"
folder.Parent = workspace

local tracked = {}
local currentArena = nil
local currentVariant = "Classic"
local center = Vector3.zero
local halfX = 50
local halfZ = 50

local function clear()
    for _, item in ipairs(tracked) do
        if item.part and item.part.Parent then
            item.part:Destroy()
        end
    end
    table.clear(tracked)
    folder:ClearAllChildren()
end

local function makeProp(name, size, color, position, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = material or Enum.Material.Neon
    part.Color = color
    part.Transparency = 0.18
    part.Parent = folder
    return part
end

local function tierLimits()
    local profile = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    if profile.Name == "Low" then
        return 2, 0.42
    elseif profile.Name == "Medium" then
        return 4, 0.72
    end
    return 6, 1
end

local function arenaTheme()
    if currentVariant == "Towers" then
        return Color3.fromRGB(65, 220, 255), Color3.fromRGB(78, 135, 255)
    elseif currentVariant == "Crossroads" then
        return Color3.fromRGB(235, 105, 220), Color3.fromRGB(213, 86, 255)
    elseif currentVariant == "Orbital" then
        return Color3.fromRGB(65, 255, 205), Color3.fromRGB(74, 188, 255)
    end
    return Color3.fromRGB(90, 185, 255), Color3.fromRGB(120, 100, 255)
end

local function rebuild()
    clear()

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not arena or not base or not base:IsA("BasePart") then
        currentArena = nil
        return
    end

    currentArena = arena
    currentVariant = tostring(arena:GetAttribute("VariantId") or "Classic")
    center = base.Position
    halfX = base.Size.X * 0.5
    halfZ = base.Size.Z * 0.5

    local limit = tierLimits()
    local accent, secondary = arenaTheme()

    if currentVariant == "Classic" then
        local offsets = {
            Vector3.new(-halfX - 9, 10, -halfZ * 0.55),
            Vector3.new(halfX + 9, 12, halfZ * 0.50),
            Vector3.new(-halfX * 0.55, 11, halfZ + 9),
            Vector3.new(halfX * 0.52, 13, -halfZ - 9),
            Vector3.new(-halfX - 11, 15, halfZ * 0.15),
            Vector3.new(halfX + 11, 9, -halfZ * 0.12),
        }
        for i = 1, math.min(limit, #offsets) do
            local p = makeProp(
                "BroadcastDrone" .. i,
                Vector3.new(3.2, 0.7, 1.7),
                i % 2 == 0 and secondary or accent,
                center + offsets[i],
                Enum.Material.Metal
            )
            local eye = makeProp(
                "BroadcastDroneGlow" .. i,
                Vector3.new(1.4, 0.22, 1.8),
                i % 2 == 0 and accent or secondary,
                p.Position + Vector3.new(0, 0, -0.2),
                Enum.Material.Neon
            )
            tracked[#tracked + 1] = {part = p, glow = eye, base = p.Position, index = i}
        end
    elseif currentVariant == "Towers" then
        for i = 1, limit do
            local angle = ((i - 1) / math.max(1, limit)) * math.pi * 2
            local p = makeProp(
                "LiftPod" .. i,
                Vector3.new(2.4, 5.2, 2.4),
                i % 2 == 0 and secondary or accent,
                center + Vector3.new(
                    math.cos(angle) * (halfX + 9),
                    8 + i * 1.4,
                    math.sin(angle) * (halfZ + 9)
                ),
                Enum.Material.Metal
            )
            tracked[#tracked + 1] = {part = p, base = p.Position, index = i}
        end
    elseif currentVariant == "Crossroads" then
        local laneOffsets = {
            Vector3.new(-halfX - 8, 5.5, -22),
            Vector3.new(halfX + 8, 5.5, 22),
            Vector3.new(-22, 5.5, halfZ + 8),
            Vector3.new(22, 5.5, -halfZ - 8),
            Vector3.new(-halfX - 8, 8.5, 22),
            Vector3.new(halfX + 8, 8.5, -22),
        }
        for i = 1, math.min(limit, #laneOffsets) do
            local p = makeProp(
                "TransitMarker" .. i,
                Vector3.new(i <= 2 and 0.8 or 3.5, 0.8, i <= 2 and 3.5 or 0.8),
                i % 2 == 0 and secondary or accent,
                center + laneOffsets[i],
                Enum.Material.Neon
            )
            tracked[#tracked + 1] = {part = p, base = p.Position, index = i}
        end
    elseif currentVariant == "Orbital" then
        for i = 1, limit do
            local angle = ((i - 1) / math.max(1, limit)) * math.pi * 2
            local p = makeProp(
                "SatelliteNode" .. i,
                Vector3.new(1.8, 1.8, 1.8),
                i % 2 == 0 and secondary or accent,
                center + Vector3.new(
                    math.cos(angle) * (math.max(halfX, halfZ) + 11),
                    13 + math.sin(angle * 2) * 2,
                    math.sin(angle) * (math.max(halfX, halfZ) + 11)
                ),
                Enum.Material.Neon
            )
            p.Shape = Enum.PartType.Ball
            tracked[#tracked + 1] = {
                part = p,
                base = p.Position,
                index = i,
                angle = angle,
                radius = math.max(halfX, halfZ) + 11,
            }
        end
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(rebuild)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clear()
        currentArena = nil
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    task.defer(rebuild)
end)

task.defer(rebuild)

task.spawn(function()
    while true do
        if currentArena and currentArena.Parent then
            local _, qualityScale = tierLimits()
            local motionScale = player:GetAttribute("ReduceMotion") == true and 0.25 or 1
            local now = os.clock()

            for _, item in ipairs(tracked) do
                local p = item.part
                if p and p.Parent then
                    if currentVariant == "Classic" then
                        local hover = math.sin(now * 1.15 + item.index) * 0.55 * qualityScale * motionScale
                        p.Position = item.base + Vector3.new(0, hover, 0)
                        if item.glow and item.glow.Parent then
                            item.glow.Position = p.Position + Vector3.new(0, 0, -0.2)
                            item.glow.Transparency = 0.14 + ((math.sin(now * 2 + item.index) + 1) * 0.5) * 0.22
                        end
                    elseif currentVariant == "Towers" then
                        local travel = math.sin(now * 0.72 + item.index * 0.85) * 3.6 * qualityScale * motionScale
                        p.Position = item.base + Vector3.new(0, travel, 0)
                    elseif currentVariant == "Crossroads" then
                        local pulse = (math.sin(now * 2.2 + item.index * 0.9) + 1) * 0.5
                        p.Transparency = 0.14 + pulse * 0.30
                    elseif currentVariant == "Orbital" then
                        local angle = item.angle + now * 0.15 * motionScale
                        local lift = math.sin(now * 0.9 + item.index) * 1.1 * qualityScale * motionScale
                        p.Position = center + Vector3.new(
                            math.cos(angle) * item.radius,
                            13 + lift,
                            math.sin(angle) * item.radius
                        )
                    end
                end
            end
        end

        task.wait(0.10)
    end
end)
