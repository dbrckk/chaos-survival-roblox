-- Layered hologram costume detail kit (props, not editable player clothing).
-- Medium: visor/chest. High: +2 cuffs. No collision, shadows, lights or emitters.
local ShowtimeHologramDetails = {}
local COUNTS = {Low = 0, Medium = 2, High = 4}
local PARTS = {
    {"Visor", Vector3.new(0.71, 0.19, 0.12), Enum.Material.Glass, 0.16},
    {"ChestCore", Vector3.new(0.48, 0.57, 0.11), Enum.Material.Metal, 0.24},
    {"WristL", Vector3.new(0.38, 0.19, 0.43), Enum.Material.Glass, 0.24},
    {"WristR", Vector3.new(0.38, 0.19, 0.43), Enum.Material.Glass, 0.24},
}

function ShowtimeHologramDetails.count(tier)
    return COUNTS[tier] or 0
end

function ShowtimeHologramDetails.build(parent, tier, index, color)
    local result = {}
    if not parent or typeof(color) ~= "Color3"
        or type(index) ~= "number" or index < 1 then
        return result
    end
    for i = 1, ShowtimeHologramDetails.count(tier) do
        local definition = PARTS[i]
        local part = Instance.new("Part")
        part.Name = "HoloDancer" .. definition[1] .. index
        part.Size = definition[2]
        part.Material = definition[3]
        part.Color = i == 2 and color:Lerp(Color3.fromRGB(15, 25, 46), 0.34)
            or color:Lerp(Color3.new(1, 1, 1), 0.24)
        part.Transparency = 1
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part:SetAttribute("ChaosHologramDetail", true)
        part:SetAttribute("ShowtimeDefaultTransparency", definition[4])
        part.Parent = parent
        table.insert(result, part)
    end
    return result
end

function ShowtimeHologramDetails.pose(parts, torso, head, left, right, enabled)
    if type(parts) ~= "table" then return end
    local frames = {
        head * CFrame.new(0, 0.04, -0.45),
        torso * CFrame.new(0, 0.12, -0.40),
        left * CFrame.new(0, -0.43, 0),
        right * CFrame.new(0, -0.43, 0),
    }
    for i, part in ipairs(parts) do
        if part.Parent then
            part.CFrame = frames[i]
            part.Transparency = enabled
                and (part:GetAttribute("ShowtimeDefaultTransparency") or 0.20)
                or 1
        end
    end
end

return ShowtimeHologramDetails
