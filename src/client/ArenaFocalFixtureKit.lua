-- Architectural housings for the existing focal SpotLights. Cosmetic only.
-- Three graphic tiers: 0/1/2 parts per source; no new lights or particle emitters.
local ArenaFocalFixtureKit = {}
local COUNTS = {Low = 0, Medium = 1, High = 2}
local SCHEMES = {
    Classic = {
        {"SurveyVisor", "WedgePart", Vector3.new(1.80, 0.65, 1.65),
            Vector3.new(0, 0, 0.19), 0, Enum.Material.Metal, "Structure"},
        {"SurveyOpticDrum", "Part", Vector3.new(1.20, 0.42, 1.20),
            Vector3.new(0, 0.02, -0.72), 90, Enum.Material.Glass, "Detail", Enum.PartType.Cylinder},
    },
    Towers = {
        {"CoolingLampCage", "Part", Vector3.new(1.52, 0.92, 1.55),
            Vector3.new(0, 0, 0.20), 0, Enum.Material.CorrodedMetal, "Structure"},
        {"CoolingHeatBaffle", "WedgePart", Vector3.new(1.58, 0.38, 1.35),
            Vector3.new(0, -0.58, -0.42), -12, Enum.Material.Metal, "Detail"},
    },
    Crossroads = {
        {"TransitSignalHood", "WedgePart", Vector3.new(2.10, 0.62, 1.52),
            Vector3.new(0, 0.03, 0.23), 0, Enum.Material.Concrete, "Structure"},
        {"TransitLightBlade", "Part", Vector3.new(1.34, 0.16, 0.55),
            Vector3.new(0, -0.37, -0.46), 0, Enum.Material.Glass, "Secondary"},
    },
    Orbital = {
        {"IrisEmitterCollar", "Part", Vector3.new(1.38, 0.40, 1.38),
            Vector3.new(0, 0, 0.12), 90, Enum.Material.Metal, "Structure", Enum.PartType.Cylinder},
        {"IrisPrismShroud", "WedgePart", Vector3.new(1.32, 0.51, 1.23),
            Vector3.new(0, -0.32, -0.54), 26, Enum.Material.Glass, "Accent"},
    },
}
function ArenaFocalFixtureKit.count(tier)
    return COUNTS[tier] or 0
end
function ArenaFocalFixtureKit.names(variant)
    local result = {}
    for _, definition in ipairs(SCHEMES[variant] or {}) do
        table.insert(result, definition[1])
    end
    return result
end
function ArenaFocalFixtureKit.build(parent, anchor, variant, tier, theme, index)
    local result = {}
    local scheme, count = SCHEMES[variant], ArenaFocalFixtureKit.count(tier)
    if not parent or not anchor or not anchor:IsA("BasePart")
        or not scheme or not theme or count == 0
        or type(index) ~= "number" or index < 1 then
        return result
    end
    local colors = {
        Structure = theme.Structure:Lerp(theme.Detail, 0.16),
        Detail = theme.Detail:Lerp(theme.Structure, 0.22),
        Secondary = theme.Secondary:Lerp(theme.Detail, 0.62),
        Accent = theme.Accent:Lerp(theme.Detail, 0.64),
    }
    for i = 1, count do
        local spec = scheme[i]
        local part = Instance.new(spec[2])
        part.Name = spec[1] .. index
        part.Size = spec[3]
        part.CFrame = anchor.CFrame * CFrame.new(spec[4])
            * CFrame.Angles(0, 0, math.rad(spec[5]))
        part.Material = spec[6]
        part.Color = colors[spec[7]]
        part.Transparency = spec[6] == Enum.Material.Glass and 0.38 or 0.07
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        if spec[8] and part:IsA("Part") then part.Shape = spec[8] end
        part:SetAttribute("ChaosFocalFixture", true)
        part:SetAttribute("ArenaVariant", variant)
        part.Parent = parent
        table.insert(result, part)
    end
    return result
end
return ArenaFocalFixtureKit
