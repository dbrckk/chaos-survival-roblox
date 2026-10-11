-- Material-aware landing imprints without a solid floor-covering cylinder.
-- Count-limited to the existing GroundContactRules budget, including Low=1.
-- Cosmetic only: no collision, raycasts, animations, sounds, lights or forces.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local LandingImprintKit = {}

local MAX_PIECES = 6

function LandingImprintKit.signature(style, index, total, strength)
    if type(index) ~= "number" or type(total) ~= "number"
        or index < 1 or total < 1 or index > total or total > MAX_PIECES then
        return nil
    end
    local t = math.clamp(tonumber(strength) or 0, 0, 1)
    local mineral = style == "Mineral" or style == "Crystal"
    local mechanical = style == "Mechanical"
    local angle = ((index - 1) / total) * math.pi * 2
        + (mineral and 0.20 or (mechanical and 0.04 or 0.11))
    local radius = index == 1 and 0.20 or 0.36 + 0.10 * t
    local width = index == 1 and 0.11
        or (mechanical and 0.16 or (mineral and 0.12 or 0.10))
    local length = index == 1 and 0.78
        or ((mechanical and 0.58 or (mineral and 0.52 or 0.65))
            * (0.72 + 0.28 * t))
    return {
        Wedge = mineral and index > 1,
        Offset = Vector3.new(math.cos(angle) * radius, 0.045,
            math.sin(angle) * radius),
        Angle = angle,
        Size = Vector3.new(width, 0.045, length),
        Travel = Vector3.new(math.cos(angle) * (0.40 + 0.50 * t),
            0.05 + 0.09 * t, math.sin(angle) * (0.40 + 0.50 * t)),
        Transparency = mechanical and 0.30 or (mineral and 0.28 or 0.46),
        Duration = 0.23 + (index % 3) * 0.04,
    }
end

function LandingImprintKit.build(parent, surfaceFrame, color,
        style, material, count, strength, reduced)
    local pieces = {}
    if not parent or typeof(surfaceFrame) ~= "CFrame"
        or typeof(color) ~= "Color3" or typeof(material) ~= "EnumItem"
        or type(count) ~= "number" or count < 1 or count > MAX_PIECES
        or count % 1 ~= 0 then
        return pieces
    end
    local durationScale = reduced and 0.5 or 1
    for i = 1, count do
        local design = LandingImprintKit.signature(style, i, count, strength)
        local part = Instance.new(design.Wedge and "WedgePart" or "Part")
        part.Name = "CharacterLanding" .. tostring(style or "Neutral")
            .. (i == 1 and "Contact" or "Shard") .. i
        part.Size = design.Size
        part.CFrame = surfaceFrame * CFrame.new(design.Offset)
            * CFrame.Angles(0, design.Angle, 0)
        part.Material = style == "Crystal" and Enum.Material.Glass
            or (style == "Mechanical" and Enum.Material.Metal or material)
        part.Color = color
        part.Transparency = design.Transparency
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part:SetAttribute("ChaosLandingImprint", true)
        part:SetAttribute("LandingSurfaceStyle", tostring(style or "Neutral"))
        part.Parent = parent
        table.insert(pieces, part)

        local duration = design.Duration * durationScale
        TweenService:Create(
            part,
            TweenInfo.new(duration, Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out),
            {
                CFrame = surfaceFrame * CFrame.new(design.Offset + design.Travel)
                    * CFrame.Angles(0, design.Angle, 0),
                Size = Vector3.new(design.Size.X * 0.54, 0.025,
                    design.Size.Z * 1.30),
                Transparency = 1,
            }
        ):Play()
        Debris:AddItem(part, duration + 0.06)
    end
    return pieces
end

return LandingImprintKit
