-- Chaos Signal: minimal, recognizable platform detailing on moving geometry.
-- Decorative welds follow the authoritative platform without collisions.
-- No custom asset IDs, dynamic emitters, scripted physics or animation loops.
local PlatformFinishKit = {}

local NAMES = {
    Classic = {"ClassicCalibrationPlate", "ClassicDatumTick", "ClassicArmoredLip"},
    Towers = {"TowerHoistMount", "TowerGuideBracket", "TowerMaintenanceMark"},
    Crossroads = {"CrossroadsRouteChevron", "CrossroadsTrafficBranch", "CrossroadsDirectionStud"},
    Orbital = {"OrbitalFluxSpine", "OrbitalMagnetGuide", "OrbitalTelemetryEye"},
}

function PlatformFinishKit.names(variant)
    return NAMES[variant]
end

function PlatformFinishKit.count(tier)
    if tier == "Low" then return 1 end
    if tier == "High" then return 3 end
    return 2
end

local function add(parent, platform, name, localFrame, size, color, material, alpha, shape)
    local part = Instance.new(shape == "WedgePart" and "WedgePart" or "Part")
    part.Name = name
    part.Size = size
    part.CFrame = platform.CFrame * localFrame
    part.Color = color
    part.Material = material
    part.Transparency = alpha
    part:SetAttribute("ChaosBaseTransparency", alpha)
    if shape and shape ~= "WedgePart" then part.Shape = shape end
    part.Anchored = false
    part.Massless = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part:SetAttribute("ChaosPlatformTrim", true)
    part.Parent = parent

    local joint = Instance.new("WeldConstraint")
    joint.Name = "ChaosPlatformTrimWeld"
    joint.Part0 = part
    joint.Part1 = platform
    joint.Parent = part
    return part
end

-- StreamingEnabled does not guarantee the order in which platform Parts
-- enter a client's GetChildren() result. A consistent natural-name order
-- keeps each platform's cosmetic identity and Low-tier budget stable
-- between Android sessions, reconnects and late-replicated siblings.
function PlatformFinishKit.orderedPlatforms(container)
    if not container then return {} end
    local ordered = {}
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(ordered, child)
        end
    end
    table.sort(ordered, function(a, b)
        local aPrefix, aNumber = string.match(a.Name, "^(.-)(%d+)$")
        local bPrefix, bNumber = string.match(b.Name, "^(.-)(%d+)$")
        if aPrefix and aPrefix == bPrefix then
            local ai, bi = tonumber(aNumber), tonumber(bNumber)
            if ai and bi and ai ~= bi then
                return ai < bi
            end
        end
        if a.Name ~= b.Name then
            return a.Name < b.Name
        end
        -- Named duplicates are unusual but can occur in streamed or
        -- procedural content; use spatial ties for a stable visual order.
        local ap, bp = a.Position, b.Position
        if ap.X ~= bp.X then return ap.X < bp.X end
        if ap.Z ~= bp.Z then return ap.Z < bp.Z end
        if ap.Y ~= bp.Y then return ap.Y < bp.Y end
        return false
    end)
    return ordered
end

-- Procedural platforms are named PlatformN / SkybridgeN by MapBuilder.
-- Use that server-authored identity for alternate Low-tier decoration:
-- the selected subset must not flip when Platform1 streams in AFTER
-- Platform2 or when a skybridge arrives later.
function PlatformFinishKit.visualIndex(platform, fallbackIndex)
    local suffix = platform and string.match(platform.Name, "(%d+)$")
    local number = suffix and tonumber(suffix)
    if number and number >= 1 and number < 10000
        and number % 1 == 0 then
        return number
    end
    return math.max(1, math.floor(tonumber(fallbackIndex) or 1))
end

-- Chunky, angled corner armor changes the silhouette without touching
-- the physical collision deck. Earlier armor sat below the deck bottom:
-- invisible from the mobile third-person camera. Wedges now sit above
-- the panel near the corners but INSIDE the true collision footprint,
-- so decorative armor never suggests a safe overhanging walkway.
-- High gets all four corners, Medium an opposing diagonal, Low none.
-- New geometry is local-only, massless and welded to the actual platform.
function PlatformFinishKit.armorCount(tier)
    if tier == "High" then return 4 end
    if tier == "Medium" then return 2 end
    return 0
end

-- Server MapBuilder covers each deck with a 0.10-thick PlatformPanel
-- centered 0.055 above the physical surface. Earlier local markings
-- were centered at +0.055 and hidden *inside* that panel on device.
-- Keep a narrow clearance above its actual upper face, regardless
-- of which client module paints the surface.
function PlatformFinishKit.surfacePaintOffset(platform, thickness)
    if not platform or not platform:IsA("BasePart") then return nil end
    local halfThickness = math.max(0.005, (tonumber(thickness) or 0.05) * 0.5)
    -- Tower skybridges have physical deck + two elevated edge rails,
    -- but NO server PlatformPanel. Avoid floating paint above empty air.
    if platform:GetAttribute("ChaosSkybridge") == true then
        return platform.Size.Y * 0.5 + halfThickness + 0.012
    end
    return platform.Size.Y * 0.5 + 0.055 + 0.05 + halfThickness + 0.012
end

function PlatformFinishKit.buildArmor(parent, platform, variant, tier, theme)
    if not parent or not platform or not platform:IsA("BasePart")
        or not NAMES[variant] or not theme then
        return {}
    end
    local count = PlatformFinishKit.armorCount(tier)
    local sx, sy, sz = platform.Size.X, platform.Size.Y, platform.Size.Z
    if count == 0 or math.min(sx, sz) < 3.2 then
        return {}
    end

    local armorSize = math.clamp(math.min(sx, sz) * 0.13, 0.75, 1.50)
    local color = theme.Structure:Lerp(theme.Detail, 0.34)
    local corners = {
        {-1, -1, 0},
        {1, -1, 90},
        {1, 1, 180},
        {-1, 1, 270},
    }
    local built = {}
    for cornerIndex, def in ipairs(corners) do
        if count == 4 or cornerIndex == 1 or cornerIndex == 3 then
            local frame = CFrame.new(
                def[1] * (sx * 0.5 - armorSize * 0.53),
                sy * 0.5 + 0.05,
                def[2] * (sz * 0.5 - armorSize * 0.53)
            ) * CFrame.Angles(0, math.rad(def[3]), 0)
            local plate = add(parent, platform,
                variant .. "CornerArmor" .. cornerIndex,
                frame,
                Vector3.new(armorSize, 0.34, armorSize),
                color,
                Enum.Material.Metal,
                0.04,
                "WedgePart"
            )
            plate:SetAttribute("ChaosArmorCorner", cornerIndex)
            table.insert(built, plate)
        end
    end
    return built
end

-- Recessed side plating adds depth to otherwise flat floating decks.
-- It is welded, non-solid and placed BELOW the playable top face; the
-- per-platform budget stays fixed (Low 0, Medium 2, High 4).
function PlatformFinishKit.sideRailCount(tier)
    if tier == "High" then return 4 end
    if tier == "Medium" then return 2 end
    return 0
end

function PlatformFinishKit.buildSideRails(parent, platform, tier, theme)
    if not parent or not platform or not platform:IsA("BasePart")
        or not theme then
        return {}
    end
    local count = PlatformFinishKit.sideRailCount(tier)
    local sx, sy, sz = platform.Size.X, platform.Size.Y, platform.Size.Z
    if count == 0 or math.min(sx, sz) < 4 then return {} end

    local railHeight = math.min(0.30, math.max(0.12, sy * 0.18))
    -- The deck's opaque physical Part otherwise occludes an inset rail.
    -- Expose the narrow vertical side face just outside the deck footprint,
    -- below the top so it cannot be mistaken for a walkable ledge.
    local y = -sy * 0.5 + railHeight * 0.5
    local outside = 0.055
    local color = theme.Detail:Lerp(theme.Structure, 0.38)
    local segments = {
        {Vector3.new(0, y, -sz * 0.5 - outside), Vector3.new(sx * 0.72, railHeight, 0.13)},
        {Vector3.new(0, y, sz * 0.5 + outside), Vector3.new(sx * 0.72, railHeight, 0.13)},
        {Vector3.new(-sx * 0.5 - outside, y, 0), Vector3.new(0.13, railHeight, sz * 0.72)},
        {Vector3.new(sx * 0.5 + outside, y, 0), Vector3.new(0.13, railHeight, sz * 0.72)},
    }
    local built = {}
    for index, segment in ipairs(segments) do
        if count == 4 or index <= 2 then
            local piece = add(parent, platform, "PlatformRecessedSideRail" .. index,
                CFrame.new(segment[1]), segment[2], color,
                Enum.Material.Metal, 0.08)
            table.insert(built, piece)
        end
    end
    return built
end

-- Platform disappearance is gameplay, not an artistic overlay: any local
-- welded armor or painted glyph must also become completely invisible.
-- Saved base transparencies survive repeated Warning/Gone/Restore cycles.
function PlatformFinishKit.applyCollapseVisibility(parts, phase)
    for _, item in ipairs(parts or {}) do
        if item and item.Parent and item:IsA("BasePart") then
            local original = item:GetAttribute("ChaosBaseTransparency")
            if type(original) ~= "number" then
                original = item.Transparency
                item:SetAttribute("ChaosBaseTransparency", original)
            end
            -- Fade local decorative paint and armor during the authoritative
            -- amber warning. Otherwise opaque client trim can obscure the
            -- yellow deck cue on Android even though the server panel fades.
            -- Gone still hides everything; restoration is idempotent.
            if phase == "Gone" then
                item.Transparency = 1
            elseif phase == "Warning" then
                item.Transparency = math.max(original, 0.80)
            else
                item.Transparency = original
            end
        end
    end
end

function PlatformFinishKit.build(parent, platform, variant, tier, theme)
    local names = NAMES[variant]
    if not parent or not platform or not platform:IsA("BasePart")
        or not names or not theme
    then
        return {}
    end

    local sx, sy, sz = platform.Size.X, platform.Size.Y, platform.Size.Z
    local top = PlatformFinishKit.surfacePaintOffset(platform, 0.05)
    local count = PlatformFinishKit.count(tier)
    local built = {}
    local function piece(i, localFrame, size, color, material, alpha, shape)
        if i > count then return end
        table.insert(built, add(parent, platform, names[i], localFrame, size,
            color, material, alpha, shape))
    end

    if variant == "Classic" then
        -- Datum plate and instrument hashes communicate an engineered radar grid.
        piece(1, CFrame.new(-sx * 0.23, top, -sz * 0.26),
            Vector3.new(sx * 0.38, 0.026, 0.36),
            theme.Detail, Enum.Material.Metal, 0.24)
        piece(2, CFrame.new(-sx * 0.23, top + 0.015, -sz * 0.23),
            Vector3.new(0.12, 0.027, sz * 0.22),
            theme.Secondary, Enum.Material.Metal, 0.25)
        piece(3, CFrame.new(-sx * 0.43, -sy * 0.11, 0),
            Vector3.new(0.24, sy * 0.68, sz * 0.26),
            theme.Structure, Enum.Material.DiamondPlate, 0.08)

    elseif variant == "Towers" then
        -- Below-deck hoist cradle keeps the walking surface unobstructed.
        piece(1, CFrame.new(0, -sy * 0.5 - 0.16, 0),
            Vector3.new(sx * 0.58, 0.27, sz * 0.20),
            theme.Structure, Enum.Material.DiamondPlate, 0.10)
        piece(2, CFrame.new(sx * 0.36, -sy * 0.24, 0),
            Vector3.new(0.33, sy * 0.47, sz * 0.51),
            theme.Detail, Enum.Material.Metal, 0.11)
        piece(3, CFrame.new(0, -sy * 0.5 - 0.33, 0),
            Vector3.new(sx * 0.20, 0.10, sz * 0.23),
            theme.Accent, Enum.Material.Neon, 0.53)

    elseif variant == "Crossroads" then
        -- Routing chevrons, not free-floating light strips, direct the eye.
        piece(1, CFrame.new(-sx * 0.19, top, -sz * 0.13)
            * CFrame.Angles(0, math.rad(-34), 0),
            Vector3.new(sx * 0.40, 0.026, 0.29),
            theme.Detail, Enum.Material.Metal, 0.15)
        piece(2, CFrame.new(sx * 0.16, top + 0.005, sz * 0.13)
            * CFrame.Angles(0, math.rad(34), 0),
            Vector3.new(sx * 0.32, 0.027, 0.20),
            theme.Secondary, Enum.Material.Metal, 0.23)
        piece(3, CFrame.new(sx * 0.37, top + 0.015, sz * 0.33),
            Vector3.new(0.42, 0.028, 0.42),
            theme.Accent, Enum.Material.Glass, 0.48)

    elseif variant == "Orbital" then
        -- An arc-segment tangent to the route + a non-flashing telemetry lens.
        piece(1, CFrame.new(0, top, -sz * 0.29),
            Vector3.new(sx * 0.58, 0.028, 0.26),
            theme.Detail, Enum.Material.Metal, 0.12)
        piece(2, CFrame.new(0, top + 0.008, -sz * 0.21),
            Vector3.new(sx * 0.34, 0.027, 0.13),
            theme.Secondary, Enum.Material.Glass, 0.40)
        piece(3, CFrame.new(sx * 0.33, top + 0.017, -sz * 0.29),
            Vector3.new(0.39, 0.045, 0.39),
            theme.Accent, Enum.Material.Glass, 0.35, Enum.PartType.Ball)
    end

    return built
end

return PlatformFinishKit
