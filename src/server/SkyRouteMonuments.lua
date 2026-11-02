-- Massive original ascension landmarks on the REAL outer escape decks.
-- Eight to twelve strategically placed monuments per 320-stud arena:
-- visual landmarks are NOT new platforms, physics barriers or fake safety.
-- The existing authoritative PerimeterPlatformIndex tracking makes them
-- follow shrinking decks and vanish with their owner's collapse.
local SkyRouteMonuments = {}

SkyRouteMonuments.Steps = {[1] = "ACCESS", [4] = "TRANSFER", [8] = "SUMMIT"}
SkyRouteMonuments.MaxPartsPerMonument = 14

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

    -- Genuine architectural depth, not another neon-outline cube. Deep
    -- external paired abutments and bottom trusses read from ground level.
    for side = -1, 1, 2 do
        add("ExteriorAbutment" .. side,
            Vector3.new(2.4, 3.4, 2.8),
            CFrame.new(0, -top - 1.65, side * (half + 1.0)),
            roof, material)
        add("VerticalBridgePylon" .. side,
            Vector3.new(1.3, 11.6, 1.6),
            CFrame.new(0, top + 5.8, side * (half + 1.55)),
            metal, material)
        add("TaperedFin" .. side,
            Vector3.new(2.2, 4.1, 2.1),
            CFrame.new(0, top + 9.8, side * (half + 1.55))
                * CFrame.Angles(0, 0, math.rad(side * 19)),
            roof, material, "WedgePart")
        add("DirectionalPowerRib" .. side,
            Vector3.new(0.29, 7.1, 0.28),
            CFrame.new(outward * 0.76, top + 6.2,
                side * (half + 1.57)),
            accent, Enum.Material.Neon, nil, 0.44, true)
    end
    -- A continuous silhouette above the route, completely clear of the
    -- avatar's jump height. The 3D band means "this is a real route" from
    -- across a whole district without another huge floating text label.
    add("MonumentalOverpass",
        Vector3.new(2.8, 1.3, deck.Size.Z + 6.6),
        CFrame.new(0, top + 12.1, 0),
        roof, material)
    add("RouteStageBeacon",
        Vector3.new(0.48, 0.58, math.max(3.0, deck.Size.Z * 0.55)),
        CFrame.new(outward * 1.45, top + 11.75, 0),
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

    assert(count <= SkyRouteMonuments.MaxPartsPerMonument,
        "Route monument exceeded its Android mesh/part budget")
    return count
end

return SkyRouteMonuments
