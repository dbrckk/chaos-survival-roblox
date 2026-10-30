--!strict
-- Sixteen creator-authored 3D district structures make the LARGE arena
-- readable at player height. Unlike a billboard facade, each has a
-- volumetric foundation, pitched metal, layered housing and a landmark top.
-- All pieces are inert scenery: no collisions, touch, queries, scripts,
-- physics ownership, particles or lights. Client LOD controls mobile cost.
local ArenaDistrictArchitecture = {}

-- Four navigable sectors need distinct silhouettes AND distinct color IDs.
-- Tint existing architecture only: zero added Parts, lights, particle emitters
-- or texture lookups, preserving Android LOD and author-owned PBR budgets.
-- These muted hues contrast with the predominantly cyan arena ornaments.
local SECTOR_COLOR = {
    North = Color3.fromRGB(242, 180, 90),  -- amber / industrial
    East = Color3.fromRGB(97, 216, 182),   -- teal / transit
    South = Color3.fromRGB(239, 132, 153), -- coral / power
    West = Color3.fromRGB(166, 150, 239),  -- indigo / communications
}

local function element(model, origin, name, kind, size, localFrame, color, material)
    local piece = Instance.new(kind or "Part")
    piece.Name = name
    piece.Size = size
    piece.CFrame = origin * localFrame
    piece.Color = color
    piece.Material = material or Enum.Material.Metal
    piece.Anchored = true
    piece.CanCollide = false
    piece.CanTouch = false
    piece.CanQuery = false
    piece.CastShadow = false
    piece.Parent = model
    return piece
end

local function fixture(folder, base, variantId, theme, side, slot, number)
    -- Four skyline profiles per side, alternating silhouettes.
    -- Keep the entire structure inside the 320-stud playable floor.
    local tangent = (slot - 2.5) * 72
    local outward = base.Size.X * 0.5 - 42
    local x, z, yaw
    if side == "North" then
        x, z, yaw = tangent, -outward, math.pi
    elseif side == "South" then
        x, z, yaw = tangent, outward, 0
    elseif side == "East" then
        x, z, yaw = outward, tangent, math.pi * 0.5
    else
        x, z, yaw = -outward, tangent, -math.pi * 0.5
    end

    local model = Instance.new("Model")
    model.Name = "District" .. side .. slot
    model:SetAttribute("ArenaDistrictArchitecture", true)
    model:SetAttribute("SourceIsOriginal", true)
    model:SetAttribute("CosmeticOnly", true)
    model:SetAttribute("DistrictIndex", number)
    model:SetAttribute("DistrictProfile", slot)
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    local surface = base.Position.Y + base.Size.Y * 0.5
    local origin = CFrame.new(base.Position.X + x, surface,
        base.Position.Z + z) * CFrame.Angles(0, yaw, 0)
    local sectorColor = SECTOR_COLOR[side] or theme.Accent
    -- Large facade masses keep their original materials; the small colored
    -- fraction on steel/alloy makes all 16 buildings read as one world.
    -- Window, lens and data-vane surfaces carry the stronger wayfinding hue.
    local steel = theme.Structure:Lerp(theme.Detail, 0.23)
        :Lerp(sectorColor, 0.09)
    local dark = theme.Structure:Lerp(Color3.fromRGB(11, 19, 30), 0.42)
    local alloy = theme.Detail:Lerp(theme.Secondary, 0.16)
        :Lerp(sectorColor, 0.17)
    local baseAccent = slot % 2 == 0 and theme.Secondary or theme.Accent
    local accent = baseAccent:Lerp(sectorColor, 0.72)
    model:SetAttribute("DistrictSide", side)
    model:SetAttribute("DistrictWayfindingColor", accent)

    local function make(name, kind, size, localFrame, color, material)
        return element(model, origin, name, kind, size, localFrame,
            color or steel, material)
    end

    -- Full 3D massing: recessed disc, four sculpted supports and an elevated
    -- roof. Narrow x/z footprint leaves generous escape and hazard lanes.
    local plinth = make("BasaltFoundation", "Part",
        Vector3.new(0.7, 15.5, 15.5),
        CFrame.new(0, 0.35, 0) * CFrame.Angles(0, 0, math.pi / 2),
        dark, Enum.Material.Slate)
    plinth.Shape = Enum.PartType.Cylinder
    local rim = make("FoundationRim", "Part",
        Vector3.new(0.22, 13.8, 13.8),
        CFrame.new(0, 0.77, 0) * CFrame.Angles(0, 0, math.pi / 2),
        alloy, Enum.Material.Metal)
    rim.Shape = Enum.PartType.Cylinder
    for _, direction in ipairs({-1, 1}) do
        local suffix = direction < 0 and "L" or "R"
        make("ArmoredSupport" .. suffix, "Part",
            Vector3.new(1.4, 12.6, 2.3),
            CFrame.new(direction * 4.4, 7.1, 1.8), steel)
        make("AngledRoof" .. suffix, "WedgePart",
            Vector3.new(4.3, 2.1, 6.0),
            CFrame.new(direction * 3.0, 13.3, -0.8)
                * CFrame.Angles(0, direction < 0 and math.pi or 0, 0), alloy)
        local vane = make("DataVane" .. suffix, "Part",
            Vector3.new(0.16, 4.7, 2.9),
            CFrame.new(direction * 5.25, 8.8, 1.5), accent,
            Enum.Material.Glass)
        vane.Transparency = 0.24
    end
    make("ServiceCore", "Part", Vector3.new(6.8, 7.3, 6.8),
        CFrame.new(0, 8.4, 0), dark)
    local window = make("RecessedSignal", "Part",
        Vector3.new(4.5, 2.8, 0.17), CFrame.new(0, 9.2, -3.5),
        accent, Enum.Material.Glass)
    window.Transparency = 0.32

    -- ONE architectural sign per sector, on the building already facing
    -- the playable center. The codes are language-independent and legible
    -- through a muted panel rather than a full-screen HUD/billboard.
    -- SurfaceGui is culled with its model by the existing scenery LOD.
    -- No additional Parts, lights, queries, particles or collision.
    if slot == 2 then
        local sectorNumber = ({North = 1, East = 2, South = 3, West = 4})[side]
        local sign = Instance.new("SurfaceGui")
        sign.Name = "DistrictWayfindingSign"
        sign.Face = Enum.NormalId.Front
        sign.Adornee = window
        sign.AlwaysOnTop = false
        sign.LightInfluence = 0
        sign.CanvasSize = Vector2.new(448, 240)
        sign.Parent = window

        local panel = Instance.new("Frame")
        panel.Name = "SignPlate"
        panel.Size = UDim2.fromScale(1, 1)
        panel.BackgroundColor3 = Color3.fromRGB(12, 20, 29)
        panel.BackgroundTransparency = 0.10
        panel.BorderSizePixel = 0
        panel.Parent = sign

        local stroke = Instance.new("UIStroke")
        stroke.Name = "SectorStroke"
        stroke.Color = accent
        stroke.Thickness = 5
        stroke.Transparency = 0.10
        stroke.Parent = panel

        local code = Instance.new("TextLabel")
        code.Name = "SectorCode"
        code.Position = UDim2.fromScale(0.04, 0.05)
        code.Size = UDim2.fromScale(0.92, 0.90)
        code.BackgroundTransparency = 1
        code.Font = Enum.Font.GothamBlack
        code.Text = side:sub(1, 1) .. "  /  " .. string.format("%02d", sectorNumber)
        code.TextScaled = true
        code.TextColor3 = accent:Lerp(Color3.new(1, 1, 1), 0.52)
        code.TextStrokeColor3 = Color3.fromRGB(6, 10, 15)
        code.TextStrokeTransparency = 0.24
        code.Parent = panel
    end

    -- Recessed metal/glass panels and roof rails give each structure
    -- meaningful depth without collisions, shadows or extra lights.
    for _, direction in ipairs({-1, 1}) do
        make("SideCassette" .. tostring(direction), "Part",
            Vector3.new(0.85, 4.8, 4.6),
            CFrame.new(direction * 3.68, 7.6, 0.48),
            steel:Lerp(dark, 0.21), Enum.Material.CorrodedMetal)
        local recess = make("SideGlass" .. tostring(direction), "Part",
            Vector3.new(0.18, 2.2, 3.6),
            CFrame.new(direction * 4.13, 8.3, 0.48),
            accent:Lerp(Color3.fromRGB(170, 220, 235), 0.15),
            Enum.Material.Glass)
        recess.Transparency = 0.36
        make("TopRail" .. tostring(direction), "Part",
            Vector3.new(0.34, 0.38, 8),
            CFrame.new(direction * 5.4, 14.3, 0.2),
            alloy, Enum.Material.Metal)
    end

    -- Four structural profiles x four different arena roof signatures:
    -- distinct real 3D volumes, rather than sixteen duplicated boxes.
    if slot == 1 then
        for _, direction in ipairs({-1, 1}) do
            make("ObservatoryFin" .. tostring(direction), "WedgePart",
                Vector3.new(3.3, 5.4, 1.6),
                CFrame.new(direction * 3, 18.2, 0.2)
                    * CFrame.Angles(0, direction * math.rad(18), 0),
                steel)
        end
        local ball = make("OrbitalSurveyLens", "Part",
            Vector3.new(3.6, 3.6, 3.6),
            CFrame.new(0, 22, -0.3), accent, Enum.Material.Glass)
        ball.Shape = Enum.PartType.Ball
        ball.Transparency = 0.18
    elseif slot == 2 then
        make("CrossGantry", "Part", Vector3.new(13.5, 1.2, 2),
            CFrame.new(0, 18.1, 0), alloy)
        make("CabShell", "Part", Vector3.new(5.6, 3, 4),
            CFrame.new(0, 15.9, 0), dark)
        local glass = make("CabGlass", "Part", Vector3.new(4.8, 1.45, 0.16),
            CFrame.new(0, 16.2, -2.1), accent, Enum.Material.Glass)
        glass.Transparency = 0.22
        for _, direction in ipairs({-1, 1}) do
            make("GantryBlade" .. tostring(direction), "WedgePart",
                Vector3.new(3, 2.8, 2.6),
                CFrame.new(direction * 6.8, 19.4, 0), steel)
        end
    elseif slot == 3 then
        for duct = -1, 1 do
            local tube = make("VentTurbine" .. tostring(duct), "Part",
                Vector3.new(5.6, 2.6, 2.6),
                CFrame.new(duct * 3.4, 17.2 + math.abs(duct), 0.1),
                duct == 0 and accent or alloy, Enum.Material.Metal)
            tube.Shape = Enum.PartType.Cylinder
            make("VentArmour" .. tostring(duct), "WedgePart",
                Vector3.new(2.5, 2.2, 3.2),
                CFrame.new(duct * 3.4, 19.4 + math.abs(duct), 0),
                steel)
        end
    else
        make("AerialMast", "Part", Vector3.new(0.7, 12.2, 0.7),
            CFrame.new(0, 22, 0), steel)
        for _, direction in ipairs({-1, 1}) do
            make("CrossAerial" .. tostring(direction), "Part",
                Vector3.new(9, 0.44, 0.6),
                CFrame.new(0, 21.2 + direction * 3.1, 0)
                    * CFrame.Angles(0, direction * math.rad(42), 0),
                alloy)
        end
        local prism = make("SignalCrystal", "WedgePart",
            Vector3.new(3.6, 4.7, 3.6),
            CFrame.new(0, 29, 0) * CFrame.Angles(0, math.rad(45), 0),
            accent, Enum.Material.Glass)
        prism.Transparency = 0.23
    end

    -- Every arena has a distinct real 3D skyline language. These details
    -- belong to the existing 16 atomic cosmetic building models, so the
    -- established per-model Android LOD and 2K PBR budgets still apply.
    -- Keep each signature compact to protect the survival routes and HUD.
    if variantId == "Towers" then
        -- Elevated cargo transfer, not a generic industrial antenna.
        make("GantryArch", "Part", Vector3.new(12.5, 1.15, 1.9),
            CFrame.new(0, 18.5, 0), alloy)
        make("TransitCab", "Part", Vector3.new(4.5, 3.1, 3.5),
            CFrame.new(0, 16.4, -1), steel)
        make("TransitGlazing", "Part", Vector3.new(3.5, 1.1, 0.18),
            CFrame.new(0, 16.6, -2.83), accent, Enum.Material.Glass)
        make("TransferRailHousing", "Part", Vector3.new(13.0, 0.8, 2.4),
            CFrame.new(0, 20.1, -2.0), alloy)
        for _, direction in ipairs({-1, 1}) do
            make("HoistDriveHousing" .. tostring(direction), "Part",
                Vector3.new(2.6, 2.5, 2.8),
                CFrame.new(direction * 5.25, 18.6, -2.0),
                dark, Enum.Material.CorrodedMetal)
        end
    elseif variantId == "Orbital" then
        -- Ceramic shroud around the actual raised, ring-shaped antenna.
        local ring = make("HaloReceiver", "Part", Vector3.new(0.7, 9, 9),
            CFrame.new(0, 19, 0) * CFrame.Angles(0, 0, math.pi / 2),
            alloy)
        ring.Shape = Enum.PartType.Cylinder
        local heart = make("ReactorSphere", "Part", Vector3.new(4.2, 4.2, 4.2),
            CFrame.new(0, 19.8, 0), accent)
        heart.Shape = Enum.PartType.Ball
        make("ReactorCap", "WedgePart", Vector3.new(5.4, 2, 4),
            CFrame.new(0, 23.0, 0), dark)
        for _, direction in ipairs({-1, 1}) do
            make("ContainmentShield" .. tostring(direction), "WedgePart",
                Vector3.new(3.2, 8.4, 4.2),
                CFrame.new(direction * 6.6, 19.0, 0)
                    * CFrame.Angles(0, direction * math.rad(22), 0),
                steel, Enum.Material.CeramicTiles)
        end
        make("ReactorCollectorHousing", "Part",
            Vector3.new(7.2, 0.8, 5.2),
            CFrame.new(0, 24.4, 0), alloy)
    elseif variantId == "Crossroads" then
        -- Paired switching arms and a front-facing physical route selector.
        make("SwitchArm", "Part", Vector3.new(13, 1.2, 2),
            CFrame.new(0, 18, 0) * CFrame.Angles(0, math.rad(18), 0), alloy)
        for _, direction in ipairs({-1, 1}) do
            make("SwitchPod" .. tostring(direction), "WedgePart",
                Vector3.new(3.1, 2.3, 3.8),
                CFrame.new(direction * 5, 19.5, 0)
                    * CFrame.Angles(0, direction < 0 and math.pi or 0, 0),
                accent)
            make("RouteRelayHousing" .. tostring(direction), "WedgePart",
                Vector3.new(3.0, 3.5, 3.1),
                CFrame.new(direction * 5.6, 22.5, -2.7)
                    * CFrame.Angles(0, direction * math.rad(27), 0),
                alloy)
        end
        make("SwitchboardPanel", "Part",
            Vector3.new(8.2, 2.7, 0.6),
            CFrame.new(0, 21.5, -4.1), dark)
    elseif variantId == "Classic" then
        -- A compact physical storm-observation dish and its receiver
        -- above the existing roof profile, visible across the grid.
        make("ObservatoryColumn", "Part", Vector3.new(2.6, 8, 2.6),
            CFrame.new(0, 18.7, 0), alloy)
        local lens = make("StormSensor", "Part", Vector3.new(5, 5, 5),
            CFrame.new(0, 23.9, 0), accent, Enum.Material.Glass)
        lens.Shape = Enum.PartType.Ball
        lens.Transparency = 0.18
        make("LightningTip", "Part", Vector3.new(0.45, 4.2, 0.45),
            CFrame.new(0, 28.3, 0), steel)
        local dish = make("WeatherRadarShell", "Part",
            Vector3.new(0.65, 5.3, 5.3),
            CFrame.new(2.6, 24.8, -2.3)
                * CFrame.Angles(0, math.rad(-28), math.rad(18)),
            alloy, Enum.Material.Metal)
        dish.Shape = Enum.PartType.Cylinder
        make("RadarFeedHousing", "Part", Vector3.new(1.2, 1.2, 1.2),
            CFrame.new(1.8, 25.1, -4.2), dark)
    else
        -- Storm Harbor is no longer reusing Classic's observatory.
        -- Small, distinct dockside hoists match its larger outer cranes.
        make("HarborHoistTower", "Part", Vector3.new(2.8, 12.2, 2.8),
            CFrame.new(0, 20.5, 0), steel)
        make("HarborLoadCrossarm", "Part", Vector3.new(12.5, 1.2, 2.0),
            CFrame.new(0, 26.5, 0), alloy)
        make("HarborHoistCabin", "Part", Vector3.new(4.5, 2.4, 3.3),
            CFrame.new(3.1, 23.5, -0.5), dark)
        make("HarborCargoCable", "Part", Vector3.new(0.3, 4.8, 0.3),
            CFrame.new(-4.4, 23.6, -1.5), dark)
        make("HarborCargoHousing", "Part", Vector3.new(4.8, 2.9, 3.7),
            CFrame.new(-4.4, 19.6, -1.5),
            steel, Enum.Material.CorrodedMetal)
    end

    model.Parent = folder
    return model
end

-- Four differently authored skyline silhouettes fill previously empty
-- corners, away from every hazard platform, branch and player spawn.
-- Unlike free-standing ServerScriptService Parts these models are housed
-- in the existing district folder and inherit PER-MODEL mobile LOD.
local function cornerFixture(folder, base, variantId, theme, index)
    local signs = {{-1,-1}, {1,-1}, {-1,1}, {1,1}}
    local sx, sz = signs[index][1], signs[index][2]
    local floorY = base.Position.Y + base.Size.Y * 0.5
    local reach = math.min(base.Size.X, base.Size.Z) * 0.5 - 17
    local origin = CFrame.new(
        base.Position.X + sx * reach,
        floorY,
        base.Position.Z + sz * reach
    ) * CFrame.Angles(0, math.rad(45 * index), 0)

    local model = Instance.new("Model")
    model.Name = "CornerLandmark" .. index
    model:SetAttribute("ArenaDistrictArchitecture", true)
    model:SetAttribute("SourceIsOriginal", true)
    model:SetAttribute("CosmeticOnly", true)
    model:SetAttribute("CornerLandmarkIndex", index)
    model:SetAttribute("SignatureVariant", variantId)
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

    local dark = theme.Structure:Lerp(Color3.fromRGB(12, 21, 31), 0.43)
    local steel = theme.Detail:Lerp(theme.Structure, 0.25)
    local light = theme.Accent:Lerp(theme.Secondary, (index - 1) / 3)
    local function make(name, kind, size, frame, color, material)
        return element(model, origin, name, kind, size, frame,
            color or steel, material or Enum.Material.Metal)
    end
    local function sphere(name, radius, location, color)
        local p = make(name, "Part",
            Vector3.new(radius, radius, radius),
            CFrame.new(location), color, Enum.Material.Glass)
        p.Shape = Enum.PartType.Ball
        p.Transparency = 0.20
        return p
    end
    local function beam(name, a, b, thickness, color)
        local delta = b - a
        return make(name, "Part",
            Vector3.new(thickness, delta.Magnitude, thickness),
            CFrame.lookAt((a + b) * 0.5, b)
                * CFrame.Angles(math.pi * 0.5, 0, 0),
            color)
    end
    local function hoop(prefix, centerY, radius, segments, tone)
        for section = 0, segments - 1 do
            local first = math.pi * 2 * section / segments
            local second = math.pi * 2 * (section + 1) / segments
            beam(prefix .. tostring(section + 1),
                Vector3.new(math.sin(first) * radius,
                    centerY + math.cos(first) * radius, 0),
                Vector3.new(math.sin(second) * radius,
                    centerY + math.cos(second) * radius, 0),
                0.68, tone)
        end
    end

    -- Each footprint stays below 28 studs and clear of the real
    -- perimeter route network. Everything is non-solid decorative art.
    make("GroundPlinth", "Part", Vector3.new(20, 1.4, 20),
        CFrame.new(0, 0.7, 0), dark, Enum.Material.Slate)
    make("PlinthRim", "Part", Vector3.new(17.8, 0.4, 17.8),
        CFrame.new(0, 1.6, 0), steel)
    if index == 1 then
        -- Weather observatory: a working-scale parabolic antenna skyline.
        make("WeatherMast", "Part", Vector3.new(3.6, 23, 3.6),
            CFrame.new(0, 13.0, 0), dark)
        for side = -1, 1, 2 do
            beam("StormTripod" .. tostring(side),
                Vector3.new(side * 7, 1.6, -4),
                Vector3.new(0, 22, 0), 1.0, steel)
        end
        hoop("ObservatoryDish", 29, 7.5, 10, steel)
        sphere("ScannerLens", 4.4, Vector3.new(0, 29, 0), light)
        make("LightningRod", "Part", Vector3.new(0.55, 7, 0.55),
            CFrame.new(0, 38, 0), steel)
    elseif index == 2 then
        -- Cargo gantry: two distinct towers and hanging transit modules.
        for side = -1, 1, 2 do
            make("SuspensionPylon" .. tostring(side), "Part",
                Vector3.new(3, 26, 4.5),
                CFrame.new(side * 7, 14.7, 0), dark)
            beam("DiagonalBrace" .. tostring(side),
                Vector3.new(side * 8, 2, 5),
                Vector3.new(side * 7, 27, 0), 0.75, steel)
            make("TransitPod" .. tostring(side), "Part",
                Vector3.new(5.2, 4.2, 4),
                CFrame.new(side * 6, 18, -3.0), light)
            make("PodGlazing" .. tostring(side), "Part",
                Vector3.new(3.7, 1.4, 0.16),
                CFrame.new(side * 6, 18.6, -5.10),
                steel, Enum.Material.Glass)
        end
        make("SkyGantry", "Part", Vector3.new(24, 2.4, 5),
            CFrame.new(0, 28, 0), steel)
        make("ControlCabin", "Part", Vector3.new(7, 4.5, 4.3),
            CFrame.new(0, 31, 0), dark)
        make("SignalFin", "WedgePart", Vector3.new(6, 5.5, 3),
            CFrame.new(0, 36, 0), light)
    elseif index == 3 then
        -- Contained energy core: concentric segmented halo, ceramic fins.
        make("ArmouredReactor", "Part", Vector3.new(8.4, 28, 8.4),
            CFrame.new(0, 16, 0), dark)
        make("CrownCollar", "Part", Vector3.new(11, 2.0, 11),
            CFrame.new(0, 30, 0), steel)
        hoop("MagneticRing", 33, 8, 10, light)
        sphere("ContainmentHeart", 5.2, Vector3.new(0, 33, 0), light)
        for side = -1, 1, 2 do
            make("CoreFin" .. tostring(side), "WedgePart",
                Vector3.new(4.1, 16, 5),
                CFrame.new(side * 6.8, 12, 0), steel)
        end
    else
        -- Communications lighthouse: narrow mast and three separate
        -- signal blades, so its contour remains recognizable on phones.
        make("LighthouseShaft", "Part", Vector3.new(4.8, 32, 4.8),
            CFrame.new(0, 17.7, 0), dark)
        make("ObservationCab", "Part", Vector3.new(9.8, 4.2, 9.8),
            CFrame.new(0, 31, 0), steel)
        local glassBelt = make("GlassBelt", "Part",
            Vector3.new(9.95, 1.9, 9.95),
            CFrame.new(0, 31.3, 0), light, Enum.Material.Glass)
        glassBelt.Transparency = 0.28
        make("Antenna", "Part", Vector3.new(0.8, 11, 0.8),
            CFrame.new(0, 39, 0), light)
        for blade = 0, 2 do
            local angle = blade * 2 * math.pi / 3
            make("SignalBlade" .. tostring(blade + 1), "WedgePart",
                Vector3.new(3.6, 8.2, 0.75),
                CFrame.new(math.sin(angle) * 5.3, 27,
                    math.cos(angle) * 5.3)
                    * CFrame.Angles(0, angle, 0), steel)
        end
        sphere("NavigationLens", 2.5, Vector3.new(0, 45, 0), light)
    end

    model:SetAttribute("Corner3DPartCount", #model:GetChildren())
    assert(#model:GetChildren() >= 9 and #model:GetChildren() <= 25,
        "Corner skyline landmark exceeds lightweight mobile part budget")
    model.Parent = folder
end

function ArenaDistrictArchitecture.build(decor, base, variantId, theme)
    if not decor or not base or not base:IsA("BasePart")
        or type(variantId) ~= "string" or type(theme) ~= "table" then
        return nil
    end
    local folder = Instance.new("Folder")
    folder.Name = "ArenaDistrictArchitecture3D"
    folder:SetAttribute("CosmeticOnly", true)
    folder.Parent = decor

    local count = 0
    for _, side in ipairs({"North", "East", "South", "West"}) do
        for slot = 1, 4 do
            count += 1
            fixture(folder, base, variantId, theme, side, slot, count)
        end
    end
    folder:SetAttribute("District3DCount", count)
    -- Keep the 16 original district models in their own audited collection.
    -- Corner landmarks are a separate model group, with the SAME existing
    -- per-model Android LOD applied by scenery-lod.client.lua.
    local corners = Instance.new("Folder")
    corners.Name = "ArenaCornerLandmarks3D"
    corners:SetAttribute("CosmeticOnly", true)
    corners.Parent = decor
    for cornerIndex = 1, 4 do
        cornerFixture(corners, base, variantId, theme, cornerIndex)
    end
    corners:SetAttribute("CornerLandmarkCount", 4)
    return folder
end

return ArenaDistrictArchitecture
