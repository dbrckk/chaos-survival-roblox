local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:FindFirstChild("Shared")
local boundsModule = shared and shared:FindFirstChild("SweepLaneBounds")
local SweepLaneBounds = if boundsModule then require(boundsModule)
    else require("../shared/SweepLaneBounds")
local RoundEquipmentArt = require("./RoundEquipmentArt")

local SweepBorderArt = {}

SweepBorderArt.halfExtents = SweepLaneBounds.halfExtents

function SweepBorderArt.profile(variant)
    return RoundEquipmentArt.profiles(variant).edge
end

local function borderGeometry(band, index)
    local halfX, halfZ = SweepLaneBounds.halfExtents(band)
    local side = index % 2 == 0 and 1 or -1
    local acrossX = index <= 2
    local width = 0.25
    local length = acrossX and halfZ * 2 or (halfX - width) * 2
    local frame = band.CFrame * CFrame.new(
        acrossX and side * (halfX - width * 0.5) or 0,
        band.Size.Y * 0.5 + 0.043,
        acrossX and 0 or side * (halfZ - width * 0.5))
    if not acrossX then frame *= CFrame.Angles(0, math.pi * 0.5, 0) end
    return Vector3.new(width, 0.072, length), frame
end

function SweepBorderArt.create(band, profile)
    local border = Instance.new("Folder")
    border.Name = "SweepBorder"
    local parts = {}
    for index = 1, 4 do
        local size, frame = borderGeometry(band, index)
        local part = RoundEquipmentArt.create(border, "SweepEdge" .. index, size, frame,
            band.Color, Enum.Material.Neon, 1, profile)
        parts[index] = {part = part, axisSwapped = part.Size.X > part.Size.Z}
    end
    border.Parent = band

    -- Let the same boundary follow the owner if the map repositions or
    -- resizes the lane. Its four cosmetics never become hazard owners.
    local function refit()
        for index, item in ipairs(parts) do
            if item.part.Parent == border then
                local size, frame = borderGeometry(band, index)
                if item.axisSwapped then
                    size = Vector3.new(size.Z, size.Y, size.X)
                    frame *= CFrame.Angles(0, math.pi * 0.5, 0)
                end
                item.part.Size = size
                item.part.CFrame = frame
            end
        end
    end
    band:GetPropertyChangedSignal("CFrame"):Connect(refit)
    band:GetPropertyChangedSignal("Size"):Connect(refit)
end

function SweepBorderArt.paint(band, phase)
    local border = band:FindFirstChild("SweepBorder")
    if border then
        local alpha = phase == "Warning" and 0.14 or (phase == "Pulse" and 0.06 or 1)
        for _, edge in ipairs(border:GetChildren()) do
            if edge:IsA("BasePart") then
                edge.Color = band.Color
                edge.Transparency = alpha
            end
        end
    end
end

return SweepBorderArt
