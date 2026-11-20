-- Massive original ascension landmarks on the REAL outer escape decks.
-- Twelve strategically placed monuments per 320-stud arena:
-- visual landmarks are NOT new platforms, physics barriers or fake safety.
-- The existing authoritative PerimeterPlatformIndex tracking makes them
-- follow shrinking decks and vanish with their owner's collapse.
local RouteSignalGeometry = require("./RouteSignalGeometry")
local SkyRouteMonuments = {}

SkyRouteMonuments.Steps = {[1] = "ACCESS", [4] = "TRANSFER", [8] = "SUMMIT"}
SkyRouteMonuments.MaxPartsPerMonument = 17

local function piece(decor, deck, index, role, name, size, offset,
        color, material, kind, transparency, navigation, mesh)
    local part = mesh or Instance.new(kind or "Part")
    part.Name = "SkyRouteMonument" .. index .. "_" .. name
    if not mesh then
        part.Size = size
        part.CFrame = deck.CFrame * offset
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
    end
    part.Color = color
    part.Material = material or Enum.Material.Metal
    part.Transparency = transparency or 0
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
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

local fallbackProfiles = {
    cast = {"bevel"},
    shaft = {"bevel"},
    beam = {"bevel"},
    underframe = {"beam", "bevel"},
    signal = {"bevel"},
    rotor = {"ring"},
}

local function fitSource(source, frame, size, inlaySide, alongX)
    if not source or not source.part or source.part.MeshId == "" then return nil end
    local mesh = RouteSignalGeometry.fit(source.part, frame, size, inlaySide, alongX)
    if mesh then mesh:SetAttribute("Original3DAssetId", source.assetId) end
    return mesh
end

local function fitProfile(profiles, profile, frame, size, inlaySide, alongX)
    if not profiles then return nil end
    local source = profiles[profile]
    local mesh = fitSource(source, frame, size, inlaySide, alongX)
    if mesh then return mesh, source end
    local fallbacks = fallbackProfiles[profile]
    if fallbacks then
        for _, fallback in ipairs(fallbacks) do
            source = profiles[fallback]
            mesh = fitSource(source, frame, size, inlaySide, alongX)
            if mesh then return mesh, source end
        end
    end
    return nil
end

function SkyRouteMonuments.cladRisers(decor, deck, index, definition, theme, profiles)
    local step = definition.PerimeterStep
    local branch = definition.BranchStep ~= nil
    local crossing = definition.CrosslinkRoute ~= nil
    if not branch and not crossing and (not step or step > 5) then return end

    local entry = step == 1
    local profile = (entry or crossing) and "cast" or "beam"

    -- Lateral steps rise by 3 studs. Keep their plates above the
    -- preceding landing and below the luminous rim of the current one.
    local height = if branch then 1.40 elseif entry then 1.20 else 2.00
    local depth = 0.40
    local size = deck.Size
    local y = size.Y * 0.5 - 1.45 - height * 0.5
    local color = theme.Surface:Lerp((branch or crossing) and theme.Secondary or theme.Detail, 0.48)
    local prefix = if crossing then "CrosslinkRiser" elseif branch then "BranchRiser" else "PerimeterRiser"

    local function mount(face, offset, dimensions, alongX)
        local mesh = fitProfile(profiles, profile, deck.CFrame * offset, dimensions, nil, alongX)
        if not mesh then return end
        mesh.Name = prefix .. index .. "_" .. face
        mesh.Color = color
        mesh.Material = deck.Material
        mesh.Transparency = 0
        mesh:SetAttribute("Original" .. prefix .. "3D", true)
        mesh:SetAttribute("PerimeterPlatformIndex", index)
        mesh.Parent = decor
    end

    -- The access portico already has castings on the inward X face.
    -- Center its flank plates between the corner feet, below the deck glow.
    local faceOffset = 0.12
    if crossing then
        -- The crossing aligns with ridge 6 on X and branch 2 on Z.
        -- Face both physical landings below the warning strips.
        local towardRidge = definition.offset.Z < 0 and 1 or -1
        local towardBranch = definition.offset.X < 0 and 1 or -1
        mount("Ridge", CFrame.new(0, y, towardRidge * (size.Z * 0.5 + faceOffset)),
            Vector3.new(size.X * 0.74, height, depth), true)
        mount("Branch", CFrame.new(towardBranch * (size.X * 0.5 + faceOffset), y, 0),
            Vector3.new(depth, height, size.Z * 0.74), false)
    elseif branch then
        local facing = definition.offset.Z < 0 and 1 or -1
        mount("Approach", CFrame.new(0, y, facing * (size.Z * 0.5 + faceOffset)),
            Vector3.new(size.X * 0.74, height, depth), true)
    elseif entry then
        local span = size.X * 0.64
        local z = size.Z * 0.5 + faceOffset
        local dimensions = Vector3.new(span, height, depth)
        mount("NegZ", CFrame.new(0, y, -z), dimensions, true)
        mount("PosZ", CFrame.new(0, y, z), dimensions, true)
    else
        -- The higher risers show their inward faces above the previous
        -- landing. A shallow embed keeps the plates seated during shrink.
        local facing = definition.offset.X < 0 and 1 or -1
        mount("Approach", CFrame.new(facing * (size.X * 0.5 + faceOffset), y, 0),
            Vector3.new(depth, height, size.Z * 0.74), false)
    end
end

function SkyRouteMonuments.decorate(decor, deck, index, definition, variant, theme, profiles, nextDefinition)
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
    local function add(name, size, offset, color, mat, kind, transparency, navigation, mesh)
        count += 1
        return piece(decor, deck, index, stage, name, size, offset,
            color, mat, kind, transparency, navigation, mesh)
    end
    local function fitMonument(profile, size, offset, turnUpright)
        -- The fitted mesh records its vertical axis for horizontal contraction.
        return fitProfile(profiles, profile, deck.CFrame * offset, size,
            if turnUpright then 1 else nil, if turnUpright then true else nil)
    end
    local function baseTrim(profile, name, size, offset, color, mat)
        local mesh, source = fitMonument(profile, size, offset)
        if mesh then
            local sourceSize = source.part.Size
            mesh.DoubleSided = true
            mesh:SetAttribute("SkyRouteBaseAxisSwap", (sourceSize.X > sourceSize.Z) ~= (size.X > size.Z))
        end
        add(name, size, offset, color, mat, nil, nil, false, mesh)
    end
    local function canopy(profile, name, size, offset, color, kind)
        local mesh = fitMonument(profile, size, offset)
        if mesh then mesh:SetAttribute("OriginalSkyRouteCanopy3D", true) end
        add(name, size, offset, color, material, kind, nil, false, mesh)
    end
    local function crown(profile, name, size, offset, color, mat, kind, transparency, shape)
        -- The annulus is Y-axial, while the fallback cylinder is X-axial.
        local mesh = fitMonument(profile, size, offset, shape == Enum.PartType.Cylinder)
        if mesh then mesh:SetAttribute("OriginalSkyRouteCrown3D", true) end
        local item = add(name, size, offset, color, mat, kind, transparency, false, mesh)
        if shape and item:IsA("Part") then item.Shape = shape end
    end
    local function signal(name, size, offset, transparency, upright)
        local mesh = fitMonument("signal", size, offset, upright)
        if mesh then
            mesh:SetAttribute("OriginalSkyRouteSignal3D", true)
        end
        add(name, size, offset, accent, Enum.Material.Neon, nil, transparency, true, mesh)
    end

    -- The overhead beam grows from ACCESS to SUMMIT. All load-bearing
    -- supports must physically meet its underside: late-stage crowns
    -- previously hovered as much as 1.45 studs above their pylons.
    -- Adjust existing parts only (no extra draw calls or mobile geometry).
    local overpassRise = stage == "SUMMIT" and 14.0
        or (stage == "TRANSFER" and 12.9 or 12.1)
    local overpassHeight = stage == "SUMMIT" and 1.9 or 1.3
    local overpassBottom = top + overpassRise - overpassHeight * 0.5
    local overpassTop = top + overpassRise + overpassHeight * 0.5
    local pylonHeight = overpassRise - overpassHeight * 0.5 + 0.42
    local powerRibHeight = math.max(6.4, pylonHeight - 4.4)

    -- Genuine architectural depth, not another neon-outline cube. Deep
    -- external paired abutments and bottom trusses read from ground level.
    for side = -1, 1, 2 do
        baseTrim("cast", "ExteriorAbutment" .. side,
            Vector3.new(2.4, 3.4, 2.8),
            CFrame.new(0, -top - 1.65, side * (half + 1.0)),
            roof, material)
        canopy("shaft", "VerticalBridgePylon" .. side,
            Vector3.new(1.3, pylonHeight, 1.6),
            CFrame.new(0, top + pylonHeight * 0.5,
                side * (half + 1.55)),
            metal)
        canopy("cast", "TaperedFin" .. side,
            Vector3.new(2.2, 4.1, 2.1),
            CFrame.new(0, top + pylonHeight - 1.8,
                side * (half + 1.55))
                * CFrame.Angles(0, 0, math.rad(side * 19)),
            roof, "WedgePart")
        -- Suspend the inlays from the crosshead inside both sets of pylons.
        -- The approved arch spreads its feet wider than the native frame.
        signal("DirectionalPowerRib" .. side,
            Vector3.new(0.29, powerRibHeight, 0.36),
            CFrame.new(0, overpassBottom + 0.12 - powerRibHeight * 0.5,
                side * (half + 0.36)), 0.44, true)
    end
    -- Reinforce the physical route silhouette without adding collision or
    -- dynamic effects. The underside truss makes tall platforms look
    -- engineered rather than like thin floating slabs.
    baseTrim("underframe", "LoadBearingKeel",
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
    canopy("beam", "MonumentalOverpass",
        Vector3.new(overpassWidth, overpassHeight,
            deck.Size.Z + (stage == "SUMMIT" and 9.0 or 6.6)),
        CFrame.new(0, top + overpassRise, 0),
        roof)
    -- The top joins the native beam and the lower face stays visible below
    -- the approved arch's I-beam from either side of the route.
    signal("RouteStageBeacon",
        Vector3.new(0.48, 1.08, math.max(3.0, deck.Size.Z * 0.55)),
        CFrame.new(0, overpassBottom - 0.42, 0), 0.28)
    baseTrim("underframe", "RecessedCentralGirder",
        Vector3.new(math.max(3.0, width - 1.2), 0.7, 1.15),
        CFrame.new(0, -top - 0.72, 0),
        metal, Enum.Material.Metal)

    -- Two embedded floor-wayfinding strips, pointing from this genuine
    -- safe deck to the next physical escape stage. No opaque arrows
    -- covering a disappearing-platform telegraph; all warning cosmetics
    -- share the deck index and are faded by Disaster/Collapse.
    if definition.PerimeterStep ~= 8 then
        local forward = Vector3.new(outward, 0, 0)
        if nextDefinition and nextDefinition.PerimeterRoute == definition.PerimeterRoute
            and nextDefinition.PerimeterStep == definition.PerimeterStep + 1 then
            local delta = (nextDefinition.offset - definition.offset) * Vector3.new(1, 0, 1)
            if delta.Magnitude > 0.01 then forward = delta.Unit end
        end
        local origin = deck.Position + Vector3.new(0, top + 0.19, 0)
        local arrowFrame = deck.CFrame:ToObjectSpace(CFrame.lookAt(origin, origin + forward))
        for side = -1, 1, 2 do
            local size = Vector3.new(0.34, 0.065, 2.35)
            local offset = arrowFrame * CFrame.new(side * 0.62, 0, 0)
                * CFrame.Angles(0, math.rad(side * 34), 0)
            local mesh = fitMonument("beam", size, offset)
            if mesh then mesh:SetAttribute("OriginalSkyRouteSignal3D", true) end
            local chevron = add("AscendChevron" .. side, size, offset,
                accent, Enum.Material.Neon, nil, 0.24, true, mesh)
            chevron:SetAttribute("SurvivalRouteArrow", true)
        end
    else
        -- The summit is not an arrow pointing off the world into void.
        -- A high-position luminous trophy silhouette marks successful
        -- vertical escape without faking a completed round.
        local size = Vector3.new(1.8, 2.0, 1.8)
        -- Seat the lens above the crosshead, away from its center equipment.
        local offset = CFrame.new(0, overpassTop + 0.86, definition.offset.Z < 0 and -3.8 or 3.8)
        local mesh = fitMonument("lens", size, offset)
        if mesh then mesh:SetAttribute("OriginalSkyRouteSignal3D", true) end
        local beacon = add("SummitSignal", size, offset,
            accent, Enum.Material.Glass, nil, 0.18, true, mesh)
        if beacon:IsA("Part") then beacon.Shape = Enum.PartType.Ball end
    end

    -- Variant-specific crowns are separate from the canopy and underdeck
    -- assemblies currently managed by the client.
    if variant == "Classic" then
        crown("shaft", "IndustrialSurveyAntenna",
            Vector3.new(1.6, 3.2, 3.4),
            CFrame.new(0, overpassTop + 1.08, 0)
                * CFrame.Angles(0, 0, math.rad(22)),
            metal, Enum.Material.DiamondPlate, "WedgePart")
    elseif variant == "Towers" then
        crown("cast", "RailwayTransitMonitor",
            Vector3.new(1.4, 3.8, 5.5),
            CFrame.new(0, overpassTop + 1.65, 0),
            accent, Enum.Material.Glass, nil, 0.32)
    elseif variant == "Crossroads" then
        crown("beam", "AngledRoadExchange",
            Vector3.new(2.2, 3.1, 5.0),
            CFrame.new(0, overpassTop + 1.05, 0)
                * CFrame.Angles(0, math.rad(20), math.rad(17)),
            metal, Enum.Material.CorrodedMetal, "WedgePart")
    elseif variant == "Orbital" then
        crown("lens", "SatelliteReactor",
            Vector3.new(3.8, 3.8, 3.8),
            CFrame.new(0, overpassTop + 1.55, 0),
            accent, Enum.Material.Glass, nil, 0.20, Enum.PartType.Ball)
        crown("rotor", "ContainmentRotor",
            Vector3.new(0.38, 5.0, 5.0),
            CFrame.new(0, overpassTop + 1.55, 0)
                * CFrame.Angles(0, 0, math.rad(35)),
            metal, Enum.Material.Metal, nil, nil, Enum.PartType.Cylinder)
    elseif variant == "Harbor" then
        crown("beam", "PortCargoTraverse",
            Vector3.new(5.5, 0.65, 1.8),
            CFrame.new(0, overpassTop + 0.22, 1.8),
            metal, Enum.Material.CorrodedMetal)
        crown("shaft", "SuspendedStormHook",
            Vector3.new(0.55, 3.8, 0.55),
            CFrame.new(0, overpassTop - 1.64, 2.15),
            accent, Enum.Material.Metal)
    end

    assert(count <= SkyRouteMonuments.MaxPartsPerMonument,
        "Route monument exceeded its Android mesh/part budget")
    return count
end

return SkyRouteMonuments
