-- Eleven hazard glyphs translated from HUD recipes into physical 3D signs.
-- Purely cosmetic and short-lived: no damage, collision, input or camera effects.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DisasterIntroGlyphKit = {}

local STROKES = {Low = 3, Medium = 5, High = 8}

function DisasterIntroGlyphKit.strokeCount(tier, total)
    return math.min(STROKES[tier] or STROKES.Medium,
        math.max(0, math.floor(tonumber(total) or 0)))
end

local function newPart(parent, name, size, frame, color, material, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = frame
    p.Color = color
    p.Material = material
    p.Transparency = transparency
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p:SetAttribute("ChaosIntroSymbol", true)
    p.Parent = parent
    return p
end

function DisasterIntroGlyphKit.build(parent, base, id, tier, slot, glyphOverride, visualOverride)
    if not parent or not base or not base:IsA("BasePart")
        or type(id) ~= "string" or (slot ~= 1 and slot ~= 2)
    then
        return nil
    end
    local glyphs = glyphOverride or require(ReplicatedStorage.Shared.HazardGlyphs)
    local visuals = visualOverride or require(ReplicatedStorage.Shared.DisasterVisuals)
    local segments = glyphs.get(id)
    local palette = visuals.get(id)
    if not segments or not palette or #segments < 3 then return nil end

    -- Side-by-side for Double Chaos. The signs sit beyond the playable edge
    -- and follow the arena's rotated coordinate frame.
    local x = (slot == 1 and -1 or 1) * base.Size.X * 0.28
    local surfaceY = base.Size.Y * 0.5
    local position = base.CFrame:PointToWorldSpace(
        Vector3.new(x, surfaceY + 6.3, -base.Size.Z * 0.5 - 4.2))
    local target = base.CFrame:PointToWorldSpace(
        Vector3.new(x, surfaceY + 4.6, 0))
    local frame = CFrame.lookAt(position, target)
    local folder = Instance.new("Folder")
    folder.Name = "ChaosDisasterIntro_" .. id
    folder.Parent = parent
    local parts = {}

    table.insert(parts, newPart(folder, "ChaosSignalBackplate",
        Vector3.new(5.7, 5.7, 0.22), frame,
        Color3.fromRGB(20, 29, 43), Enum.Material.Metal, 0.08))

    local count = DisasterIntroGlyphKit.strokeCount(tier, #segments)
    for i = 1, count do
        -- Sample the entire recipe to preserve important opposed strokes in Low.
        local index = math.floor((i - 1) * #segments / count) + 1
        local seg = segments[index]
        local offset = CFrame.new((seg.X - 0.5) * 4.45,
            (0.5 - seg.Y) * 4.45, -0.20)
            * CFrame.Angles(0, 0, math.rad(-(seg.Rotation or 0)))
        table.insert(parts, newPart(folder, "ChaosSignalStroke" .. i,
            Vector3.new(math.max(0.13, seg.Width * 4.45),
                math.max(0.13, seg.Height * 4.45), 0.075),
            frame * offset,
            i % 3 == 0 and palette.Tint or palette.Accent,
            tier == "Low" and Enum.Material.SmoothPlastic or Enum.Material.Neon,
            tier == "Low" and 0.08 or 0.20))
    end

    if tier == "High" then
        -- Non-emissive registration notches give the sign an engineered frame.
        for side = -1, 1, 2 do
            table.insert(parts, newPart(folder, "ChaosSignalRetainer" .. side,
                Vector3.new(0.24, 1.55, 0.28),
                frame * CFrame.new(side * 2.71, 0, 0.03),
                palette.Tint, Enum.Material.Metal, 0.13))
        end
    end
    return {folder = folder, parts = parts, frame = frame, id = id}
end

return DisasterIntroGlyphKit
