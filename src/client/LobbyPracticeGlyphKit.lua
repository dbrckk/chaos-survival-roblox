-- Authored vector-chevron contact motifs for the four lobby boost pads.
-- Three tier-aware silhouettes: 2/4/6 static Parts per pad, no animation,
-- lights, particles, physics or server authority.
local Kit = {}

function Kit.count(tier)
    if tier == "Low" then return 1 end
    if tier == "Medium" then return 2 end
    if tier == "High" then return 3 end
    return 0
end

local function finite(v)
    return type(v) == "number" and v == v and math.abs(v) < math.huge
end

local function finiteVector(v)
    return typeof(v) == "Vector3"
        and finite(v.X) and finite(v.Y) and finite(v.Z)
end

-- The painted vector always points toward the hub from the current pad,
-- matching the inward impulses on all four symmetric server boost pads.
function Kit.direction(pad, center)
    if typeof(pad) ~= "Instance" or not pad:IsA("BasePart")
        or not finiteVector(center) or not finiteVector(pad.Position) then
        return nil
    end
    local up = pad.CFrame.UpVector
    local candidate = center - pad.Position
    local planar = candidate - up * candidate:Dot(up)
    if planar.Magnitude < 0.10 then
        local fallback = pad.CFrame.LookVector
        planar = fallback - up * fallback:Dot(up)
    end
    if planar.Magnitude < 0.10 then return nil end
    return planar.Unit
end

function Kit.build(parent, pad, tier, center)
    local arrowCount = Kit.count(tier)
    if arrowCount == 0
        or typeof(parent) ~= "Instance"
        or typeof(pad) ~= "Instance" or not pad:IsA("BasePart")
        or pad:GetAttribute("LobbyPracticePad") ~= true
        or not pad.Parent or not parent.Parent then
        return nil
    end
    local forward = Kit.direction(pad, center)
    if not forward or not finiteVector(pad.Size)
        or pad.Size.X < 3 or pad.Size.Z < 3 or pad.Size.Y <= 0 then
        return nil
    end

    local up = pad.CFrame.UpVector
    local right = forward:Cross(up).Unit
    local origin = pad.Position + up * (pad.Size.Y * 0.5 + 0.065)
    local model = Instance.new("Folder")
    model.Name = "PracticeVectorGlyphLocal"

    for i = 1, arrowCount do
        -- Three offset arrows read as acceleration, not generic neon bars.
        local longitudinal = (i - (arrowCount + 1) * 0.5) * 1.37
        local tip = origin + forward * longitudinal
        local reach = 0.90 + (i % 2) * 0.10
        local spread = 0.80 + (i % 2) * 0.09
        for side = -1, 1, 2 do
            local shoulder = tip - forward * reach + right * (spread * side)
            local midpoint = (tip + shoulder) * 0.5
            local length = (tip - shoulder).Magnitude
            local stroke = Instance.new("Part")
            stroke.Name = side < 0 and "VectorChevronLeft" or "VectorChevronRight"
            stroke.Size = Vector3.new(
                tier == "Low" and 0.15 or 0.19, 0.065, length
            )
            stroke.CFrame = CFrame.lookAt(midpoint, tip, up)
            stroke.Anchored = true
            stroke.CanCollide = false
            stroke.CanTouch = false
            stroke.CanQuery = false
            stroke.CastShadow = false
            stroke.Material = Enum.Material.Neon
            stroke.Color = pad.Color:Lerp(Color3.new(1, 1, 1),
                side < 0 and 0.18 or 0.38)
            stroke.Transparency = tier == "Low" and 0.28 or 0.18
            stroke.Parent = model
        end
    end
    model.Parent = parent
    return model
end

return Kit
