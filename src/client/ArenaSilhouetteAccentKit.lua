-- Four readable, outboard skyline accents with strict mobile part caps.
-- These props are purely local art: they cannot collide, touch or be queried.
local ArenaSilhouetteAccentKit = {}

local LIMITS = { Low = 2, Medium = 3, High = 4 }

local NAMES = {
    Classic = {"SurveyCounterweight", "SurveyDiagonalBrace", "SurveyOpticDrum", "SurveySignalVane"},
    Towers = {"CoolingIntakeSpine", "CoolingBaffleA", "CoolingBaffleB", "CoolingExhaustCap"},
    Crossroads = {"TransitDirectionBeam", "TransitSplitArrow", "TransitUpperRoute", "TransitLowerRoute"},
    Orbital = {"DockFieldSpine", "DockFieldPetalA", "DockFieldPetalB", "DockFieldLens"},
}

function ArenaSilhouetteAccentKit.count(tierName)
    return LIMITS[tierName] or 0
end

function ArenaSilhouetteAccentKit.names(variant)
    return NAMES[variant] or {}
end

local function geometry(variant, base)
    local hx, hz = base.Size.X * 0.5, base.Size.Z * 0.5
    local top = base.Size.Y * 0.5
    if variant == "Classic" then
        -- Survey instrument: asymmetric counterweight, splayed calibrated brace, optic drum.
        local x, z = hx + 19, hz * 0.33
        return {
            {Vector3.new(2.6, 17, 2.6), CFrame.new(x, top + 8.5, z), "structure"},
            {Vector3.new(14, 0.9, 1.3), CFrame.new(x - 4.4, top + 14, z) * CFrame.Angles(0, 0, math.rad(28)), "detail", nil, "WedgePart"},
            {Vector3.new(5.2, 1.1, 5.2), CFrame.new(x - 10, top + 17.2, z) * CFrame.Angles(0, 0, math.rad(90)), "accent", Enum.PartType.Cylinder},
            {Vector3.new(0.8, 7.2, 2.7), CFrame.new(x + 1.5, top + 19.1, z), "detail"},
        }
    elseif variant == "Towers" then
        -- Industrial cooling intake with separated slanted heat baffles.
        local x, z = -hx - 17, -hz * 0.29
        return {
            {Vector3.new(3.3, 21, 3.3), CFrame.new(x, top + 10.5, z), "structure"},
            {Vector3.new(1.2, 12.5, 5.0), CFrame.new(x - 3, top + 13, z) * CFrame.Angles(0, 0, math.rad(-23)), "detail", nil, "WedgePart"},
            {Vector3.new(1.2, 10.5, 5.0), CFrame.new(x + 3.2, top + 10.5, z) * CFrame.Angles(0, 0, math.rad(23)), "detail", nil, "WedgePart"},
            {Vector3.new(9.5, 1.1, 5.8), CFrame.new(x, top + 22.0, z), "accent"},
        }
    elseif variant == "Crossroads" then
        -- Transit control: branching wayfinding silhouette, not a recycled cooling tower.
        local x, z = hx * 0.34, -hz - 18
        return {
            {Vector3.new(20, 1.6, 2.4), CFrame.new(x, top + 13, z) * CFrame.Angles(0, math.rad(-12), 0), "structure"},
            {Vector3.new(9, 1.2, 2.4), CFrame.new(x - 5.8, top + 15.6, z) * CFrame.Angles(0, 0, math.rad(30)), "detail", nil, "WedgePart"},
            {Vector3.new(10.5, 1.1, 2.4), CFrame.new(x + 5.8, top + 17.2, z) * CFrame.Angles(0, 0, math.rad(-29)), "accent", nil, "WedgePart"},
            {Vector3.new(11.5, 1.1, 2.2), CFrame.new(x + 6.0, top + 9.4, z) * CFrame.Angles(0, 0, math.rad(23)), "detail"},
        }
    else
        -- Orbital containment: separated radial petals around a muted optical node.
        local x, z = -hx * 0.36, hz + 18
        return {
            {Vector3.new(2.8, 19, 2.8), CFrame.new(x, top + 9.5, z) * CFrame.Angles(0, 0, math.rad(9)), "structure"},
            {Vector3.new(1.6, 13.5, 3.2), CFrame.new(x - 5.0, top + 13.0, z) * CFrame.Angles(0, 0, math.rad(-33)), "detail", nil, "WedgePart"},
            {Vector3.new(1.6, 13.5, 3.2), CFrame.new(x + 5.0, top + 13.0, z) * CFrame.Angles(0, 0, math.rad(33)), "detail", nil, "WedgePart"},
            {Vector3.new(4.8, 1.0, 4.8), CFrame.new(x, top + 21.5, z) * CFrame.Angles(0, 0, math.rad(90)), "accent", Enum.PartType.Cylinder},
        }
    end
end

function ArenaSilhouetteAccentKit.build(parent, base, variant, tierName, theme)
    local built = {}
    local count = ArenaSilhouetteAccentKit.count(tierName)
    if not parent or not base or not base:IsA("BasePart")
        or not NAMES[variant] or count == 0 or not theme then
        return built
    end

    local palette = {
        structure = theme.Structure:Lerp(Color3.fromRGB(9, 14, 23), 0.35),
        detail = theme.Detail:Lerp(theme.Structure, 0.32),
        accent = theme.Accent:Lerp(theme.Detail, 0.56),
    }
    local specs = geometry(variant, base)
    for index = 1, count do
        local entry = specs[index]
        local p = Instance.new(entry[5] or "Part")
        p.Name = NAMES[variant][index]
        p.Size = entry[1]
        p.CFrame = base.CFrame * entry[2]
        p.Color = palette[entry[3]]
        p.Material = (index == 1 and variant == "Towers" and Enum.Material.CorrodedMetal)
            or (index == 1 and variant == "Crossroads" and Enum.Material.Concrete)
            or (index == 4 and tierName == "High" and variant == "Orbital" and Enum.Material.Glass)
            or (index == 4 and tierName == "High" and Enum.Material.DiamondPlate)
            or Enum.Material.Metal
        p.Transparency = index == 4 and 0.27 or 0.08
        p.Anchored = true
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.CastShadow = false
        if entry[4] and p:IsA("Part") then
            p.Shape = entry[4]
        end
        p:SetAttribute("ChaosSilhouetteAccent", true)
        p:SetAttribute("ArenaVariant", variant)
        p.Parent = parent
        table.insert(built, p)
    end
    return built
end

return ArenaSilhouetteAccentKit
