-- Massive original ascension landmarks on the REAL outer escape decks.
-- Eight to twelve strategically placed monuments per 320-stud arena:
-- visual landmarks are NOT new platforms, physics barriers or fake safety.
-- The existing authoritative PerimeterPlatformIndex tracking makes them
-- follow shrinking decks and vanish with their owner's collapse.
local SkyRouteMonuments = {}

SkyRouteMonuments.Steps = {[1] = "ACCESS", [4] = "TRANSFER", [8] = "SUMMIT"}
SkyRouteMonuments.MaxPartsPerMonument = 17

local function piece(decor, deck, index, role, name, size, offset,
        color, material, kind, transparency, navigation)
    local part = Instance.new(kind or "Part")
    part.Name = "SkyRouteMonument" .. index .. "_" .. name
    part.Size = size
    part.CFrame = deck.CFrame * offset
    part.Color = color
    part.Material = material or Enum.Material.Metal
    part.Transparency = transparency or 0
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part:SetAttribute("PerimeterPlatformIndex", index)
    part:SetAttribute("SkyRouteMonument", true)
    part:SetAttribute("SkyRouteStage", role)
    if navigation then
        -- Android readability excludes genuine navigation from the
        -- decorative-neon fading pass; unrelated metal still respects it.
        part:SetAttribute("ChaosWayfinding", true)
    end
    part.Parent = decor
    return part
end

function SkyRouteMonuments.decorate(decor, deck, index, definition, variant, theme)
    if not decor or not deck or not deck:IsA("BasePart")
        or type(definition) ~= "table" or type(theme) ~= "table"
        or type(variant) ~= "string" then return 0 end
    local stage = SkyRouteMonuments.Steps[definition.PerimeterStep]
    if not stage or not definition.PerimeterRoute then return 0 end

    -- None of these arches can obstruct R15 walking / jumping. The
    -- structural pylons stand beyond both edges of the REAL collision
    -- footprint, the cross-head is 12+ studs above the walking surface,
    -- and all subframes are well below the collider.
    local top = deck.Size.Y * 0.5
    local half = deck.Size.Z * 0.5
    local width = deck.Size.X
    local outward = definition.offset.X < 0 and -1 or 1
    local accent = stage == "ACCESS" and theme.Accent
        or (stage == "TRANSFER"
            and theme.Secondary:Lerp(theme.Detail, 0.32)
            or theme.Accent:Lerp(Color3.fromRGB(230, 240, 235), 0.46))
    local metal = theme.Structure:Lerp(theme.Detail, 0.36)
    local roof = theme.Surface:Lerp(theme.Structure, 0.24)
    local material = variant == "Harbor" and Enum.Material.CorrodedMetal
        or (variant == "Crossroads" and Enum.Material.DiamondPlate
            or (variant == "Orbital" and Enum.Material.CeramicTiles
                or (variant == "Towers" and Enum.Material.Foil
                    or Enum.Material.Metal)))
    local count = 0
    local function add(name, size, offset, color, mat, kind, transparency, navigation)
        count += 1
        return piece(decor, deck, index, stage, name, size, offset,
            color, mat, kind, transparency, navigation)
    end

    -- The overhead beam grows from ACCESS to SUMMIT. All load-bearing
    -- supports must physically meet its underside: late-stage crowns
    -- previously hovered as much as 1.45 studs above their pylons.
    -- Adjust existing parts only (no extra draw calls or mobile geometry).
    local overpassRise = stage == "SUMMIT" and 14.0
        or (stage == "TRANSFER" and 12.9 or 12.1)
    local overpassHeight = stage == "SUMMIT" and 1.9 or 1.3
    local pylonHeight = overpassRise - overpassHeight * 0.5 + 0.42
    local powerRibHeight = math.max(6.4, pylonHeight - 4.4)

    -- Genuine architectural depth, not another neon-outline cube. Deep
    -- external paired abutments and bottom trusses read from ground level.
    for side = -1, 1, 2 do
        add("ExteriorAbutment" .. side,
            Vector3.new(2.4, 3.4, 2.8),
            CFrame.new(0, -top - 1.65, side * (half + 1.0)),
            roof, material)
        add("VerticalBridgePylon" .. side,
            Vector3.new(1.3, pylonHeight, 1.6),
            CFrame.new(0, top + pylonHeight * 0.5,
                side * (half + 1.55)),
            metal, material)
        add("TaperedFin" .. side,
            Vector3.new(2.2, 4.1, 2.1),
            CFrame.new(0, top + pylonHeight - 1.8,
                side * (half + 1.55))
                * CFrame.Angles(0, 0, math.rad(side * 19)),
            roof, material, "WedgePart")
        add("DirectionalPowerRib" .. side,
            Vector3.new(0.29, powerRibHeight, 0.28),
            CFrame.new(outward * 0.76,
                top + pylonHeight - powerRibHeight * 0.5 - 0.4,
                side * (half + 1.57)),
            accent, Enum.Material.Neon, nil, 0.44, true)
    end
    -- Reinforce the physical route silhouette without adding collision or
    -- dynamic effects. The underside truss makes tall platforms look
    -- engineered rather than like thin floating slabs.
    add("LoadBearingKeel",
        Vector3.new(math.max(3, width - 1), 1.25, 0.9),
        CFrame.new(0, -top - 1.45, 0),
        metal, material)

    -- A continuous silhouette above the route, completely clear of the
    -- avatar's jump height. The 3D band means "this is a real route" from
    -- across a whole district without another huge floating text label.
    -- Three distinct gateway silhouettes make the route hierarchy visible
    -- from the arena floor without more text, neon or additional instances.
    local overpassWidth = stage == "SUMMIT" and 4.6
        or (stage == "TRANSFER" and 3.5 or 2.8)
    add("MonumentalOverpass",
        Vector3.new(overpassWidth, overpassHeight,
            deck.Size.Z + (stage == "SUMMIT" and 9.0 or 6.6)),
        CFrame.new(0, top + overpassRise, 0),
        roof, material)
    add("RouteStageBeacon",
        Vector3.new(0.48, 0.58, math.max(3.0, deck.Size.Z * 0.55)),
        CFrame.new(outward * 1.45,
            top + overpassRise - overpassHeight * 0.5 - 0.20, 0),
        accent, Enum.Material.Neon, nil, 0.28, true)
    add("RecessedCentralGirder",
        Vector3.new(math.max(3.0, width - 1.2), 0.7, 1.15),
        CFrame.new(0, -top - 0.72, 0),
        metal, Enum.Material.Metal)

    -- Two embedded floor-wayfinding strips, pointing from this genuine
    -- safe deck to the next physical escape stage. No opaque arrows
    -- covering a disappearing-platform telegraph; all warning cosmetics
    -- share the deck index and are faded by Disaster/Collapse.
    if definition.PerimeterStep ~= 8 then
        local arrowFrame = CFrame.lookAt(
            deck.Position + Vector3.new(0, top + 0.19, 0),
            deck.Position + Vector3.new(outward, top + 0.19, 0))
        for side = -1, 1, 2 do
            local chevron = add("AscendChevron" .. side,
                Vector3.new(0.34, 0.065, 2.35),
                deck.CFrame:ToObjectSpace(arrowFrame)
                    * CFrame.new(side * 0.62, 0, 0)
                    * CFrame.Angles(0, math.rad(side * 34), 0),
                accent, Enum.Material.Neon, nil, 0.24, true)
            chevron:SetAttribute("SurvivalRouteArrow", true)
        end
    else
        -- The summit is not an arrow pointing off the world into void.
        -- A high-position luminous trophy silhouette marks successful
        -- vertical escape without faking a completed round.
        local beacon = add("SummitSignal",
            Vector3.new(1.8, 2.0, 1.8),
            CFrame.new(0, top + 14.4, 0),
            accent, Enum.Material.Glass, nil, 0.18, true)
        beacon.Shape = Enum.PartType.Ball
    end

    -- Distinct original architectural crown for each of the five
    -- universes. Shapes are not just recolored stock platform cubes.
    if variant == "Classic" then
        add("IndustrialSurveyAntenna",
            Vector3.new(1.6, 3.2, 3.4),
            CFrame.new(0, top + 14.5, 0)
                * CFrame.Angles(0, 0, math.rad(22)),
            metal, Enum.Material.DiamondPlate, "WedgePart")
    elseif variant == "Towers" then
        add("RailwayTransitMonitor",
            Vector3.new(1.4, 3.8, 5.5),
            CFrame.new(0, top + 14.7, 0),
            accent, Enum.Material.Glass, nil, 0.32)
    elseif variant == "Crossroads" then
        add("AngledRoadExchange",
            Vector3.new(2.2, 3.1, 5.0),
            CFrame.new(0, top + 14.3, 0)
                * CFrame.Angles(0, math.rad(20), math.rad(17)),
            metal, Enum.Material.CorrodedMetal, "WedgePart")
    elseif variant == "Orbital" then
        local reactor = add("SatelliteReactor",
            Vector3.new(3.8, 3.8, 3.8),
            CFrame.new(0, top + 15.5, 0),
            accent, Enum.Material.Glass, nil, 0.20)
        reactor.Shape = Enum.PartType.Ball
        local ring = add("ContainmentRotor",
            Vector3.new(0.38, 5.0, 5.0),
            CFrame.new(0, top + 15.5, 0)
                * CFrame.Angles(0, 0, math.rad(35)),
            metal, Enum.Material.Metal)
        ring.Shape = Enum.PartType.Cylinder
    elseif variant == "Harbor" then
        add("PortCargoTraverse",
            Vector3.new(5.5, 0.65, 1.8),
            CFrame.new(0, top + 14.4, 1.8),
            metal, Enum.Material.CorrodedMetal)
        add("SuspendedStormHook",
            Vector3.new(0.55, 3.8, 0.55),
            CFrame.new(0, top + 12.3, 3.5),
            accent, Enum.Material.Metal)
    end

    assert(count <= SkyRouteMonuments.MaxPartsPerMonument,
        "Route monument exceeded its Android mesh/part budget")
    return count
end

return SkyRouteMonuments
