-- Massive structural arches over ACTUAL collidable promenade decks.
-- Six original steel/ceramic/cargo gate ensembles per arena, each attached
-- to its exact platform index for ShrinkingArena size and CFrame updates.
-- Native decoration only: no blocking walls, lights, physics, loops or assets.
local PromenadeArchitecture = {}

local function make(decor, platform, index, name, size, offset, color,
    material, className)
    local p = Instance.new(className or "Part")
    p.Name = "Promenade" .. index .. "_" .. name
    p.Size = size
    p.CFrame = platform.CFrame * offset
    p.Color = color
    p.Material = material
    p.Transparency = 0.06
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    -- ShrinkingArena already captures deck-owned decor by this attribute,
    -- moving/scaling it together with the true physical walkway.
    p:SetAttribute("PerimeterPlatformIndex", index)
    p:SetAttribute("PromenadeVisualOnly", true)
    p.Parent = decor
    return p
end

local function piece(decor, platform, index, name, size, offset, color,
    material, className)
    return make(decor, platform, index, name, size, offset,
        color, material, className)
end

local function variantEquipment(decor, platform, index, variant, theme, top)
    local metal = theme.Structure:Lerp(theme.Detail, 0.35)
    local accent = theme.Accent:Lerp(theme.Structure, 0.55)
    local secondary = theme.Secondary:Lerp(theme.Detail, 0.32)
    local equipment = 0
    local function add(name, size, offset, color, material, className)
        piece(decor, platform, index, name, size,
            CFrame.new(0, top, 0) * offset,
            color, material, className)
        equipment += 1
    end

    if variant == "Classic" then
        add("SurveyDish", Vector3.new(5.5, 0.70, 5.5),
            CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(18)),
            secondary, Enum.Material.Metal)
        add("SurveyMast", Vector3.new(0.52, 5, 0.52),
            CFrame.new(0, 4.0, 0), metal, Enum.Material.Metal)
        add("SurveyTip", Vector3.new(1.8, 1.8, 1.8),
            CFrame.new(0, 6.3, 0), accent, Enum.Material.Glass)
    elseif variant == "Towers" then
        add("HoistMachine", Vector3.new(7.2, 3.5, 4.2),
            CFrame.new(0, 2.0, 0), metal, Enum.Material.DiamondPlate)
        add("HoistRail", Vector3.new(0.6, 5.0, 0.6),
            CFrame.new(4.2, 3.8, 0), secondary, Enum.Material.Metal)
        add("HoistBeacon", Vector3.new(2.2, 0.55, 2.0),
            CFrame.new(0, 4.2, 0), accent, Enum.Material.Glass)
    elseif variant == "Crossroads" then
        add("SignalConcourse", Vector3.new(10.8, 2.1, 3.0),
            CFrame.new(0, 1.45, 0), metal, Enum.Material.CorrodedMetal)
        for side = -1, 1, 2 do
            add("SwitchFin" .. tostring(side),
                Vector3.new(4.9, 1.4, 0.8),
                CFrame.new(side * 6.1, 3.0, 0)
                    * CFrame.Angles(0, 0, math.rad(side * 24)),
                side < 0 and accent or secondary, Enum.Material.Metal,
                "WedgePart")
        end
    elseif variant == "Orbital" then
        add("GyroCore", Vector3.new(4.2, 4.2, 4.2),
            CFrame.new(0, 3.3, 0), accent, Enum.Material.Glass)
        for side = -1, 1, 2 do
            add("ContainmentFin" .. tostring(side),
                Vector3.new(0.9, 5.5, 3.2),
                CFrame.new(side * 4.4, 2.8, 0)
                    * CFrame.Angles(0, 0, math.rad(side * 18)),
                secondary, Enum.Material.CeramicTiles, "WedgePart")
        end
    elseif variant == "Harbor" then
        add("FreightHoistArm", Vector3.new(16.8, 1.6, 2.3),
            CFrame.new(1.0, 1.9, 0), metal, Enum.Material.CorrodedMetal)
        add("SuspendedCrate", Vector3.new(4.2, 3.8, 4.2),
            CFrame.new(8.1, -2.3, -4.0),
            secondary, Enum.Material.WoodPlanks)
        add("CargoChain", Vector3.new(0.3, 3.2, 0.3),
            CFrame.new(8.1, 0.8, -4.0), accent, Enum.Material.Metal)
    end
    return equipment
end

function PromenadeArchitecture.decorate(decor, platform, index, definition,
    variant, theme)
    if not decor or not platform or not platform:IsA("BasePart")
        or type(definition) ~= "table" or type(theme) ~= "table" then
        return 0
    end
    local lane = definition.PromenadeLane
    local step = definition.PromenadeStep
    -- Monumental gateway rhythm: three obvious spans per lane, leaving
    -- unimpeded sightlines on the other five physical deck sections.
    if (lane ~= 1 and lane ~= 2)
        or (step ~= 2 and step ~= 4 and step ~= 7) then
        return 0
    end

    local count = 0
    local height = platform.Size.Y * 0.5
    local steel = theme.Structure:Lerp(theme.Surface, 0.18)
    local alloy = theme.Detail:Lerp(theme.Structure, 0.30)
    local material = variant == "Harbor" and Enum.Material.CorrodedMetal
        or (variant == "Orbital" and Enum.Material.CeramicTiles
            or Enum.Material.Metal)
    local function structure(name, size, offset, color, finish, className)
        piece(decor, platform, index, name, size,
            CFrame.new(0, height, 0) * offset,
            color, finish or material, className)
        count += 1
    end

    -- Two side rails outside the ACTUAL 12-stud-wide crossing. Arch
    -- interiors have >11 studs head clearance and no solid decoration,
    -- so running/jumping R6/R15 players never hit invisible beams.
    for side = -1, 1, 2 do
        structure("LoadPylon" .. side, Vector3.new(1.6, 13, 1.8),
            CFrame.new(0, 6.5, side * 7.6), steel)
        structure("DiagonalStay" .. side, Vector3.new(0.65, 7.3, 1.1),
            CFrame.new(0, 8.6, side * 8.3)
                * CFrame.Angles(math.rad(side * 16), 0, 0),
            alloy)
    end
    structure("MonumentalCrosshead", Vector3.new(4.0, 1.2, 18.4),
        CFrame.new(0, 13.25, 0), alloy)
    structure("UnderdeckTruss", Vector3.new(5.6, 1.7, 11.0),
        CFrame.new(0, -1.3, 0), steel, Enum.Material.Metal)
    -- The equipment is above the structural crosshead, or outside
    -- the deck edges. Nothing presents a fake playable upper surface.
    count += variantEquipment(decor, platform, index,
        variant, theme, height + 13.25)
    assert(count <= 9, "Monumental promenade arch exceeded part budget")
    return count
end

return PromenadeArchitecture
