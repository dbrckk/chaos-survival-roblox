-- Authored vector-chevron contact motifs for the four lobby boost pads.
-- Three tier-aware silhouettes: 2/4/6 static pieces per pad, no animation,
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

function Kit.build(parent, pad, tier, center, source)
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
    if source and (not source:IsA("MeshPart") or not source.Archivable) then
        source = nil
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
            local mesh = source and source:Clone()
            local stroke = mesh or Instance.new("Part")
            if mesh then
                mesh:ClearAllChildren()
                mesh.TextureID = ""
            end
            stroke.Name = side < 0 and "VectorChevronLeft" or "VectorChevronRight"
            local width = tier == "Low" and 0.15 or 0.19
            local frame = CFrame.lookAt(midpoint, tip, up)
            local rotate = mesh and source.Size.X > source.Size.Z
            stroke.Size = rotate and Vector3.new(length, 0.065, width)
                or Vector3.new(width, 0.065, length)
            stroke.CFrame = rotate and frame * CFrame.Angles(0, math.pi * 0.5, 0) or frame
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

-- The motif is painted on the pad: keep the six-or-fewer anchored visual
-- strokes registered to its transform when a streamed/rebuilt arena moves.
-- This listens for pad CFrame changes only; no RenderStepped or physics.
function Kit.follow(glyph, pad)
    if typeof(glyph) ~= "Instance" or not glyph:IsA("Folder")
        or glyph.Name ~= "PracticeVectorGlyphLocal" or not glyph.Parent
        or typeof(pad) ~= "Instance" or not pad:IsA("BasePart")
        or not pad.Parent then
        return nil
    end

    local relativeParts = {}
    local padFrame = pad.CFrame
    for _, part in ipairs(glyph:GetChildren()) do
        if part:IsA("BasePart") then
            relativeParts[#relativeParts + 1] = {
                part = part,
                localFrame = padFrame:ToObjectSpace(part.CFrame),
            }
        end
    end
    if #relativeParts == 0 then return nil end

    return pad:GetPropertyChangedSignal("CFrame"):Connect(function()
        if not glyph.Parent or not pad.Parent then return end
        local nextFrame = pad.CFrame
        for _, record in ipairs(relativeParts) do
            if record.part.Parent == glyph then
                record.part.CFrame = nextFrame * record.localFrame
            end
        end
    end)
end

return Kit
