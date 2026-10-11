-- Restrained, map-specific ground detail: no decals, external assets, lighting or collision.
-- Macro-forms occupy peripheral deck space; warnings and gameplay pads retain priority.
local ArenaDeckFinishKit = {}

local COUNTS = {Low = 2, Medium = 4, High = 6}
local NAMES = {
    Classic = {
        "ClassicSurveyDatumWest", "ClassicSurveyDatumEast",
        "ClassicGaugeToothNorth", "ClassicGaugeToothSouth",
        "ClassicCalibrationInsetWest", "ClassicCalibrationInsetEast",
    },
    Towers = {
        "TowerLoadSpreaderNorth", "TowerLoadSpreaderSouth",
        "TowerHoistAnchorWest", "TowerHoistAnchorEast",
        "TowerSteelKneeNorth", "TowerSteelKneeSouth",
    },
    Crossroads = {
        "CrossroadsLaneArrowWest", "CrossroadsLaneArrowEast",
        "CrossroadsBranchArrowNorth", "CrossroadsBranchArrowSouth",
        "CrossroadsTransferInsetWest", "CrossroadsTransferInsetEast",
    },
    Orbital = {
        "OrbitalIrisPetalNorth", "OrbitalIrisPetalSouth",
        "OrbitalIrisPetalWest", "OrbitalIrisPetalEast",
        "OrbitalContainmentLensNorth", "OrbitalContainmentLensSouth",
    },
}

function ArenaDeckFinishKit.count(tierName)
    return COUNTS[tierName] or 0
end

function ArenaDeckFinishKit.names(variant)
    return NAMES[variant] or {}
end

local function recipes(variant, hx, hz)
    local edgeX = hx * 0.77
    local edgeZ = hz * 0.77
    if variant == "Classic" then
        return {
            {Vector3.new(1.2, 0.09, 12), Vector3.new(-edgeX, 0, -hz * 0.20), 0, "Metal", "Detail"},
            {Vector3.new(1.2, 0.09, 12), Vector3.new(edgeX, 0, hz * 0.20), 0, "Metal", "Detail"},
            {Vector3.new(4.1, 0.10, 0.7), Vector3.new(-hx * 0.25, 0, -edgeZ), 0, "DiamondPlate", "Structure"},
            {Vector3.new(4.1, 0.10, 0.7), Vector3.new(hx * 0.25, 0, edgeZ), 0, "DiamondPlate", "Structure"},
            {Vector3.new(2.8, 0.10, 1.0), Vector3.new(-edgeX + 2.2, 0, -hz * 0.20), 24, "Metal", "Accent", "WedgePart"},
            {Vector3.new(2.8, 0.10, 1.0), Vector3.new(edgeX - 2.2, 0, hz * 0.20), -24, "Metal", "Accent", "WedgePart"},
        }
    elseif variant == "Towers" then
        return {
            {Vector3.new(11, 0.12, 1.8), Vector3.new(-hx * 0.22, 0, -edgeZ), 0, "CorrodedMetal", "Structure"},
            {Vector3.new(11, 0.12, 1.8), Vector3.new(hx * 0.22, 0, edgeZ), 0, "CorrodedMetal", "Structure"},
            {Vector3.new(1.8, 0.14, 5.2), Vector3.new(-edgeX, 0, hz * 0.18), 0, "DiamondPlate", "Detail"},
            {Vector3.new(1.8, 0.14, 5.2), Vector3.new(edgeX, 0, -hz * 0.18), 0, "DiamondPlate", "Detail"},
            {Vector3.new(4.4, 0.12, 1.4), Vector3.new(-hx * 0.22 + 5.4, 0, -edgeZ), -18, "Metal", "Accent", "WedgePart"},
            {Vector3.new(4.4, 0.12, 1.4), Vector3.new(hx * 0.22 - 5.4, 0, edgeZ), 18, "Metal", "Accent", "WedgePart"},
        }
    elseif variant == "Crossroads" then
        return {
            {Vector3.new(4.4, 0.09, 2.6), Vector3.new(-edgeX, 0, -hz * 0.27), -90, "Concrete", "Detail", "WedgePart"},
            {Vector3.new(4.4, 0.09, 2.6), Vector3.new(edgeX, 0, hz * 0.27), 90, "Concrete", "Detail", "WedgePart"},
            {Vector3.new(4.4, 0.09, 2.6), Vector3.new(-hx * 0.27, 0, -edgeZ), 0, "Slate", "Accent", "WedgePart"},
            {Vector3.new(4.4, 0.09, 2.6), Vector3.new(hx * 0.27, 0, edgeZ), 180, "Slate", "Accent", "WedgePart"},
            {Vector3.new(6.5, 0.08, 0.55), Vector3.new(-edgeX, 0, -hz * 0.27 + 4), 0, "Metal", "Structure"},
            {Vector3.new(6.5, 0.08, 0.55), Vector3.new(edgeX, 0, hz * 0.27 - 4), 0, "Metal", "Structure"},
        }
    end

    local radius = math.min(hx, hz) * 0.74
    return {
        {Vector3.new(4.2, 0.09, 2.2), Vector3.new(0, 0, -radius), -90, "Metal", "Detail", "WedgePart"},
        {Vector3.new(4.2, 0.09, 2.2), Vector3.new(0, 0, radius), 90, "Metal", "Detail", "WedgePart"},
        {Vector3.new(4.2, 0.09, 2.2), Vector3.new(-radius, 0, 0), 0, "Metal", "Detail", "WedgePart"},
        {Vector3.new(4.2, 0.09, 2.2), Vector3.new(radius, 0, 0), 180, "Metal", "Detail", "WedgePart"},
        {Vector3.new(3.2, 0.06, 0.7), Vector3.new(-radius * 0.70, 0, -radius * 0.70), -45, "Glass", "Accent"},
        {Vector3.new(3.2, 0.06, 0.7), Vector3.new(radius * 0.70, 0, radius * 0.70), -45, "Glass", "Accent"},
    }
end

function ArenaDeckFinishKit.build(parent, base, variant, tierName, theme)
    local result = {}
    local count = ArenaDeckFinishKit.count(tierName)
    if not parent or not base or not base:IsA("BasePart")
        or not NAMES[variant] or not theme or count == 0 then
        return result
    end

    local palette = {
        Structure = theme.Structure:Lerp(theme.Surface, 0.30),
        Detail = theme.Detail:Lerp(theme.Structure, 0.40),
        Accent = theme.Accent:Lerp(theme.Detail, 0.76),
    }
    local specs = recipes(variant, base.Size.X * 0.5, base.Size.Z * 0.5)
    -- Slightly above the top face, small enough not to hide route / hazard cues.
    local surface = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.18, 0)
    for i = 1, count do
        local recipe = specs[i]
        local piece = Instance.new(recipe[7] or "Part")
        piece.Name = NAMES[variant][i]
        piece.Size = recipe[1]
        piece.CFrame = surface * CFrame.new(recipe[2]) * CFrame.Angles(0, math.rad(recipe[3]), 0)
        piece.Material = Enum.Material[recipe[4]]
        piece.Color = palette[recipe[5]]
        piece.Transparency = recipe[4] == "Glass" and 0.48
            or (tierName == "Low" and 0.36 or 0.20)
        piece.Anchored = true
        piece.CanCollide = false
        piece.CanTouch = false
        piece.CanQuery = false
        piece.CastShadow = false
        piece:SetAttribute("ChaosDeckFinish", true)
        piece:SetAttribute("ArenaVariant", variant)
        piece:SetAttribute("SurfaceBaseColor", piece.Color)
        piece.Parent = parent
        table.insert(result, piece)
    end
    return result
end

return ArenaDeckFinishKit
