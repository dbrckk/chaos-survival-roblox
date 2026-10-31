-- Authored native 3D silhouettes at the FOUR playable districts.
-- Unlike off-map skyline art these sit inside the 320-stud floor, close
-- enough to orient real players along the outer stair and branch routes.
-- Client-only, noncolliding, no runtime physics, sound, external assets,
-- RenderStepped, Heartbeat, lights or high-frequency update tasks.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)
local DistrictMaterialFinishKit = require(script.Parent.DistrictMaterialFinishKit)
local DistrictKineticKit = require(script.Parent.DistrictKineticKit)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local folder = Instance.new("Folder")
folder.Name = "DistrictSectorSetpiecesLocal"
folder.Parent = workspace

local watchedMap = nil
local disconnectReady = nil
local rebuildQueued = false
local liveTracks = {}

local function currentTier()
    local requested = player:GetAttribute("VfxQualityTier")
    return VfxQuality.Tiers[requested]
        and requested or VfxQuality.initialTier(UserInputService.TouchEnabled)
end

local function stopKinetics()
    DistrictKineticKit.stop(liveTracks)
end

-- Reconfigure only existing cosmetic tweens when reduced motion changes.
-- No geometry rebuild, remote traffic or frame-by-frame Lua animations.
local function syncKinetics()
    stopKinetics()
    local tier = currentTier()
    if tier == "Low" or player:GetAttribute("ReduceMotion") == true then
        return
    end
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then
            local sector = model:GetAttribute("DistrictSector")
            for _, entry in ipairs(DistrictKineticKit.start(model, sector, tier, false)) do
                liveTracks[#liveTracks + 1] = entry
            end
        end
    end
end

local signs = {
    {-1, -1, "OBSERVATORY", "01"},
    {1, -1, "CARGO DEPOT", "02"},
    {-1, 1, "POWER PLANT", "03"},
    {1, 1, "COMMS ARRAY", "04"},
}

local function part(parent, name, size, frame, color, material, alpha, shape)
    local piece = Instance.new("Part")
    piece.Name = name
    piece.Size = size
    piece.CFrame = frame
    piece.Anchored = true
    piece.CanCollide = false
    piece.CanQuery = false
    piece.CanTouch = false
    piece.CastShadow = false
    piece.Color = color
    piece.Material = material or Enum.Material.Metal
    piece.Transparency = alpha or 0
    if shape then piece.Shape = shape end
    piece.Parent = parent
    return piece
end

local function beam(parent, name, root, a, b, thick, color, alpha)
    local delta = b - a
    if delta.Magnitude < 0.1 then return end
    local at = (a + b) * 0.5
    return part(parent, name, Vector3.new(thick, delta.Magnitude, thick),
        root * CFrame.lookAt(at, b) * CFrame.Angles(math.pi * 0.5, 0, 0),
        color, Enum.Material.Metal, alpha)
end

local function sectorSign(model, anchor, copy, color)
    -- On real Android landscape screenshots the central survival HUD,
    -- signal navigation and objective progress already consume the upper
    -- view. Four more world-floating sector names obscure traversal and
    -- duplicate the physical district signage/coded buildings.
    -- Keep all four distinct 3D sector structures and their existing
    -- architectural sign plates, but reserve floating names for PC.
    if UserInputService.TouchEnabled then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "SectorWaypoint"
    gui.Adornee = anchor
    gui.Size = UDim2.fromOffset(156, 40)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 2.0, 0)
    gui.MaxDistance = 105
    gui.AlwaysOnTop = false
    gui.Parent = anchor

    local label = Instance.new("TextLabel")
    label.Name = "SectorName"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(14, 24, 36)
    label.BackgroundTransparency = 0.18
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.TextColor3 = color
    label.Text = copy
    label.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = label
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = 0.32
    stroke.Thickness = 1.2
    stroke.Parent = label
end

local function makeSector(base, theme, index, tier, variant)
    local high = tier == "High"
    local sx, sz, title, number = table.unpack(signs[index])
    local reachX = math.min(116, base.Size.X * 0.5 - 26)
    local reachZ = math.min(88, base.Size.Z * 0.5 - 38)
    local root = base.CFrame
        * CFrame.new(sx * reachX, base.Size.Y * 0.5, sz * reachZ)
        * CFrame.Angles(0, math.rad((index - 1) * 90 + 45), 0)

    local dark = theme.Structure:Lerp(Color3.fromRGB(14, 22, 31), 0.42)
    local alloy = theme.Detail:Lerp(theme.Structure, 0.36)
    local accent = index % 2 == 0 and theme.Secondary or theme.Accent
    local model = Instance.new("Model")
    model.Name = "Sector" .. number .. "_" .. title:gsub("%s+", "")
    model:SetAttribute("LocalOriginal3D", true)
    model:SetAttribute("CosmeticOnly", true)
    model:SetAttribute("DistrictSector", index)
    model.Parent = folder

    local function make(name, size, localCFrame, color, material, alpha, shape)
        return part(model, name, size, root * localCFrame,
            color or alloy, material, alpha, shape)
    end

    local foundation = make("GroundFoundation",
        Vector3.new(14, 0.55, 13),
        CFrame.new(0, 0.27, 0), dark, Enum.Material.Slate, 0.07)
    local face = make("SectorIdentityPlate", Vector3.new(9, 1.6, 0.55),
        CFrame.new(0, 5.4, -5.8), alloy, Enum.Material.Metal, 0.03)
    sectorSign(model, face, CoreLocalization.text(localeId,
        "DISTRICT_SECTOR_SIGN", number,
        CoreLocalization.text(localeId, "DISTRICT_SECTOR_" .. index)),
        accent)

    -- Android Low previously lost all four important in-arena landmarks.
    -- Keep four sharply differentiated five-part silhouettes using real
    -- native Roblox textured materials, but reserve fine PBR-like finish
    -- and extra decorative geometry for Medium/High.
    if tier == "Low" then
        if index == 1 then
            make("LowObservatoryMast", Vector3.new(2.5, 16, 2.5),
                CFrame.new(0, 8.3, 0), dark, Enum.Material.CorrodedMetal)
            make("LowRadarDish", Vector3.new(0.85, 8.4, 8.4),
                CFrame.new(0, 18.2, 0)
                    * CFrame.Angles(0, math.rad(21), math.rad(15)),
                alloy, Enum.Material.Metal, 0.04, Enum.PartType.Cylinder)
            make("LowRadarEye", Vector3.new(2.5, 2.5, 2.5),
                CFrame.new(0, 18.2, -0.45), accent,
                Enum.Material.Glass, 0.23, Enum.PartType.Ball)
        elseif index == 2 then
            make("LowCargoStack", Vector3.new(9.4, 7.0, 6.0),
                CFrame.new(0, 4.0, 0), dark, Enum.Material.CorrodedMetal)
            make("LowOverheadGantry", Vector3.new(15.8, 1.8, 3.4),
                CFrame.new(0, 13.2, 0), alloy, Enum.Material.DiamondPlate)
            make("LowCargoHoist", Vector3.new(0.9, 8, 0.9),
                CFrame.new(0, 9, -0.1), accent, Enum.Material.Metal)
        elseif index == 3 then
            make("LowReactorTower", Vector3.new(8.6, 16.0, 8.6),
                CFrame.new(0, 8.4, 0), dark, Enum.Material.Metal)
            make("LowEnergyCollar", Vector3.new(10.0, 2.2, 10.0),
                CFrame.new(0, 11.5, 0), accent, Enum.Material.Glass, 0.40)
            make("LowCoreSignal", Vector3.new(3.3, 3.3, 3.3),
                CFrame.new(0, 18, 0), accent,
                Enum.Material.Glass, 0.22, Enum.PartType.Ball)
        else
            make("LowCommunicationsMast", Vector3.new(3.2, 25, 3.2),
                CFrame.new(0, 13.0, 0), dark, Enum.Material.Metal)
            make("LowSignalArray", Vector3.new(10, 7.2, 1.1),
                CFrame.new(0, 20.2, 0) * CFrame.Angles(0, math.rad(22), 0),
                alloy, Enum.Material.DiamondPlate)
            make("LowBeacon", Vector3.new(2.6, 2.6, 2.6),
                CFrame.new(0, 28.1, 0), accent,
                Enum.Material.Glass, 0.2, Enum.PartType.Ball)
        end
        model:SetAttribute("Decorative3DParts", 5)
        model:SetAttribute("VariantArchitectureParts", 0)
        return model
    end

    if index == 1 then
        -- Observatory: tall angled receiver with a distinct disk antenna.
        make("ReceiverMast", Vector3.new(2.1, 17.0, 2.1),
            CFrame.new(0, 9.0, 0), dark)
        make("RadarDish", Vector3.new(0.62, 8.6, 8.6),
            CFrame.new(0, 18, 0) * CFrame.Angles(0, math.rad(22), math.rad(20)),
            alloy, Enum.Material.Metal, 0.02, Enum.PartType.Cylinder)
        local eye = make("RadarEye", Vector3.new(2.5, 2.5, 2.5),
            CFrame.new(-0.65, 18, -0.3), accent, Enum.Material.Glass, 0.24,
            Enum.PartType.Ball)
        if high then
            for side = -1, 1, 2 do
                beam(model, "ReceiverBrace" .. side, root,
                    Vector3.new(side * 6, 0.7, 3),
                    Vector3.new(0, 15.5, 0), 0.75, alloy, 0.04)
            end
            make("ScannerBalance", Vector3.new(8.2, 0.7, 0.7),
                CFrame.new(0, 17, 1.8) * CFrame.Angles(0, math.rad(30), 0),
                alloy)
            make("DishBacklight", Vector3.new(3.2, 0.2, 1.1),
                CFrame.new(0.3, 14.0, -1), accent, Enum.Material.Neon, 0.35)
        end
        eye:SetAttribute("OriginalLens", true)
    elseif index == 2 then
        -- Cargo depot: stacked freight pods, crane frame and suspended load.
        for side = -1, 1, 2 do
            make("CargoPod" .. side, Vector3.new(5.6, 5.4, 4.5),
                CFrame.new(side * 3.1, 3.25, 0), dark,
                Enum.Material.CorrodedMetal, 0.06)
            make("CargoStripe" .. side, Vector3.new(5.7, 0.46, 4.6),
                CFrame.new(side * 3.1, 5.65, 0), accent,
                Enum.Material.Neon, 0.32)
        end
        make("GantryBridge", Vector3.new(16.5, 1.6, 4),
            CFrame.new(0, 15, 0), alloy)
        if high then
            for side = -1, 1, 2 do
                make("GantryPylon" .. side, Vector3.new(1.35, 16, 1.45),
                    CFrame.new(side * 7.0, 8.5, 0), dark)
            end
            make("CargoHanger", Vector3.new(0.55, 6.4, 0.55),
                CFrame.new(0, 11.1, 0), alloy)
            make("RaisedSupplyPod", Vector3.new(4.8, 3.0, 3.4),
                CFrame.new(0, 7.4, 0), theme.Detail)
            make("CraneCap", Vector3.new(4.5, 0.6, 5),
                CFrame.new(0, 16, 0), accent, Enum.Material.Neon, 0.44)
        end
    elseif index == 3 then
        -- Power station: visual containment volume with axial fins.
        make("ReactorCoreHousing", Vector3.new(7, 12.5, 7),
            CFrame.new(0, 6.95, 0), dark)
        make("ContainmentGlass", Vector3.new(7.25, 2.5, 7.25),
            CFrame.new(0, 8.6, 0), accent,
            Enum.Material.Glass, 0.26)
        for side = -1, 1, 2 do
            make("ReactorFin" .. side, Vector3.new(2.3, 10, 4.5),
                CFrame.new(side * 5.4, 5.8, 0),
                alloy, Enum.Material.Metal, 0.07)
        end
        if high then
            for segment = 1, 8 do
                local angle = (segment - 1) * (math.pi * 2 / 8)
                make("MagneticCollar" .. segment, Vector3.new(3.8, 0.54, 0.74),
                    CFrame.new(math.cos(angle) * 5.0, 14.0,
                        math.sin(angle) * 5.0)
                        * CFrame.Angles(0, -angle, 0),
                    segment % 2 == 0 and accent or alloy,
                    segment % 2 == 0 and Enum.Material.Neon
                        or Enum.Material.Metal,
                    segment % 2 == 0 and 0.35 or 0.06)
            end
        end
    else
        -- Comms relay: tall scanner fin, side receivers and glass collar.
        make("CommsMast", Vector3.new(2.3, 21, 2.3),
            CFrame.new(0, 11.2, 0), dark)
        make("CommsSignalFin", Vector3.new(9.3, 7.4, 1.4),
            CFrame.new(0, 17.4, 0) * CFrame.Angles(0, math.rad(17), 0),
            alloy)
        make("ControlCabin", Vector3.new(5.2, 3.8, 5.2),
            CFrame.new(0, 12.1, 0), dark)
        make("ScannerWindow", Vector3.new(5.35, 1.6, 5.35),
            CFrame.new(0, 12.5, 0), accent, Enum.Material.Glass, 0.32)
        if high then
            for side = -1, 1, 2 do
                beam(model, "TransmitterSupport" .. side, root,
                    Vector3.new(side * 5, 0.6, 3),
                    Vector3.new(0, 17, 0), 0.67, alloy, 0.06)
            end
            make("CommsTopBeacon", Vector3.new(1.5, 1.5, 1.5),
                CFrame.new(0, 22.1, 0), accent, Enum.Material.Glass, 0.18,
                Enum.PartType.Ball)
            make("AntennaNeedle", Vector3.new(0.38, 5, 0.38),
                CFrame.new(0, 25.1, 0), alloy)
        end
    end

    local weathered = dark:Lerp(theme.Detail, 0.23)
    local brushed = alloy:Lerp(Color3.fromRGB(165, 178, 193), 0.14)

    -- A single variant-specific architecture vocabulary across the FOUR
    -- near-playable districts. Two structural volumes on Medium and three
    -- on High: no change to the exact five-Part Android Low silhouettes.
    -- They are not collision objects, ladders, platforms or route targets.
    -- The existing setpiece folder already owns lifetime, quality rebuild,
    -- distance LOD and VisualBudgetRules counters.
    local infrastructure = 0
    local mirrored = index % 2 == 0 and 1 or -1
    local function structure(name, size, at, tone, material, rotation)
        local item = make("District" .. variant .. name, size,
            CFrame.new(at) * (rotation or CFrame.identity),
            tone, material, 0.04)
        infrastructure += 1
        return item
    end
    if variant == "Classic" then
        -- Paired receiver foundations and an elevated scanner head are
        -- readable behind the path even with the neon pass disabled.
        structure("SurveySupport", Vector3.new(2.6, 10.2, 3.2),
            Vector3.new(mirrored * 6.2, 5.5, 3.0),
            weathered, Enum.Material.CorrodedMetal)
        structure("SurveyMast", Vector3.new(1.05, 11.8, 1.05),
            Vector3.new(mirrored * 6.2, 15.3, 3.0),
            brushed, Enum.Material.Metal,
            CFrame.Angles(0, 0, math.rad(mirrored * 6)))
        if high then
            local receiver = structure("SurveyHead",
                Vector3.new(3.0, 3.0, 3.0),
                Vector3.new(mirrored * 6.2, 21.5, 3.0),
                alloy, Enum.Material.Metal)
            receiver.Shape = Enum.PartType.Ball
        end
    elseif variant == "Towers" then
        -- Structural lift guides establish a vertical visual rhythm
        -- without pretending to be accessible ladders or rails.
        for side = -1, 1, 2 do
            structure("LiftGuide" .. tostring(side),
                Vector3.new(1.1, 16.5, 1.8),
                Vector3.new(side * 5.8, 8.8, 2.6),
                side < 0 and weathered or brushed,
                Enum.Material.DiamondPlate)
        end
        if high then
            structure("LiftMachineCrosshead", Vector3.new(14.2, 1.5, 3.0),
                Vector3.new(0, 17.45, 2.6),
                alloy, Enum.Material.Metal)
        end
    elseif variant == "Crossroads" then
        -- Two physically separate transit masses offset the repeated
        -- roofs, in weathered stone and matte steel, not glowing arrows.
        structure("SwitchConcourse",
            Vector3.new(15.8, 1.2, 4.0),
            Vector3.new(0, 12.2, 3.4),
            alloy, Enum.Material.CorrodedMetal)
        local pier = structure("TransitSwitchPier",
            Vector3.new(3.1, 10.8, 3.2),
            Vector3.new(mirrored * 5.8, 6.3, 3.4),
            weathered, Enum.Material.Concrete)
        pier:SetAttribute("PreserveNativeMaterial", true)
        if high then
            structure("TransitCrossbeam", Vector3.new(8.1, 1.4, 2.8),
                Vector3.new(-mirrored * 2.6, 15.1, 3.4),
                brushed, Enum.Material.Metal,
                CFrame.Angles(0, math.rad(mirrored * 12), 0))
        end
    elseif variant == "Orbital" then
        -- An opposed pair of ceramic containment fins, deliberately
        -- opaque and structural instead of full-bright neon billboards.
        for side = -1, 1, 2 do
            structure("ContainmentWing" .. tostring(side),
                Vector3.new(1.8, 13.5, 4.6),
                Vector3.new(side * 6.6, 8.0, 2.2),
                theme.Detail:Lerp(theme.Structure, 0.38),
                Enum.Material.CeramicTiles,
                CFrame.Angles(0, side * math.rad(17), 0))
        end
        if high then
            structure("ContainmentCrossbrace", Vector3.new(13.6, 0.85, 2.2),
                Vector3.new(0, 15.0, 2.2),
                brushed, Enum.Material.Metal)
        end
    elseif variant == "Harbor" then
        -- Real pier-head crane supports give every dockside sector a
        -- cargo-terminal mass, with no artificial jumpable bridge.
        for side = -1, 1, 2 do
            structure("DocksideLeg" .. tostring(side),
                Vector3.new(2.1, 12.6, 3.4),
                Vector3.new(side * 6.2, 6.7, 2.8),
                weathered, Enum.Material.CorrodedMetal)
        end
        if high then
            structure("DocksideHoistCrosshead", Vector3.new(15.0, 1.6, 3.4),
                Vector3.new(0, 13.75, 2.8),
                brushed, Enum.Material.DiamondPlate)
        end
    end
    model:SetAttribute("VariantArchitectureParts", infrastructure)
    if variant == "Classic" or variant == "Towers" or variant == "Crossroads"
        or variant == "Orbital" or variant == "Harbor" then
        assert(infrastructure == (high and 3 or 2),
            "Near-route district macro geometry exceeded its tier contract")
    end

    -- Profiled edge armour, real rivet bosses and procedural stamped
    -- markings provide depth/texture from multiple camera angles. These
    -- additions are purely client decoration: no collision or replication.
    for side = -1, 1, 2 do
        make("ChamferedBaseArmour" .. side, Vector3.new(1.8, 3.6, 3.5),
            CFrame.new(side * 5.6, 2.2, -2.1)
                * CFrame.Angles(0, side * math.rad(16), 0),
            weathered, Enum.Material.CorrodedMetal, 0.05)
        local boss = make("StampedAnchorBolt" .. side,
            Vector3.new(0.65, 0.65, 0.65),
            CFrame.new(side * 3.1, 5.55, -6.27),
            brushed, Enum.Material.Metal, 0.02, Enum.PartType.Ball)
        boss.Reflectance = 0.07
    end
    DistrictMaterialFinishKit.stencil(
        face, "CS-" .. number .. "  /  " .. variant,
        accent, tier,
        (index == 2 or index == 3) and "hazard" or "telemetry"
    )

    -- The four sector identities have different sculpting vocabularies.
    -- Medium retains the strong base massing above; High adds close-range
    -- instrument pieces/cables/sheathed pipes rather than extra neon sheets.
    if high then
        if index == 1 then
            make("RadarDishInnerLip", Vector3.new(0.24, 7.35, 7.35),
                CFrame.new(-0.47, 18, 0)
                    * CFrame.Angles(0, math.rad(22), math.rad(20)),
                brushed, Enum.Material.Metal, 0.06, Enum.PartType.Cylinder)
            make("SurveyApertureCollar", Vector3.new(1.8, 3.1, 3.1),
                CFrame.new(-1.1, 18, -0.3)
                    * CFrame.Angles(0, 0, math.pi / 2),
                dark, Enum.Material.CorrodedMetal, 0,
                Enum.PartType.Cylinder)
            for side = -1, 1, 2 do
                beam(model, "AntennaCounterbalance" .. side, root,
                    Vector3.new(side * 3.0, 12.0, 1.8),
                    Vector3.new(side * 3.4, 19.0, -0.3),
                    0.47, brushed, 0.09)
            end
            make("TelemetryCasing", Vector3.new(4.2, 2.2, 3.1),
                CFrame.new(0, 5.0, 2.2),
                weathered, Enum.Material.DiamondPlate)
        elseif index == 2 then
            for side = -1, 1, 2 do
                make("FreightDoorRib" .. side, Vector3.new(0.38, 4.1, 4.55),
                    CFrame.new(side * 3.1, 3.6, -2.30),
                    brushed, Enum.Material.DiamondPlate, 0.04)
                make("CargoDoorLatch" .. side,
                    Vector3.new(1.7, 0.32, 0.48),
                    CFrame.new(side * 3.1, 4.65, -2.64),
                    accent, Enum.Material.Metal, 0.18)
                beam(model, "CableLoom" .. side, root,
                    Vector3.new(side * 6.8, 14.0, 0),
                    Vector3.new(side * 2.1, 7.7, 0),
                    0.25, weathered, 0.02)
            end
            make("HoistCounterweight", Vector3.new(1.7, 2.6, 2.0),
                CFrame.new(0, 10.2, 0),
                dark, Enum.Material.CorrodedMetal)
        elseif index == 3 then
            for side = -1, 1, 2 do
                local pipe = make("CoolantManifold" .. side,
                    Vector3.new(0.8, 9.4, 0.8),
                    CFrame.new(side * 3.6, 5.6, -3.8),
                    brushed, Enum.Material.Metal, 0.03)
                pipe.Shape = Enum.PartType.Cylinder
                make("InsulatedPipeShield" .. side,
                    Vector3.new(1.45, 2.1, 1.9),
                    CFrame.new(side * 3.6, 10.4, -3.8),
                    weathered, Enum.Material.CorrodedMetal)
                make("ReactorServicePort" .. side,
                    Vector3.new(2.1, 2.1, 0.4),
                    CFrame.new(side * 2.2, 5.9, -3.67),
                    accent, Enum.Material.Glass, 0.42)
            end
            make("CorePressureCap", Vector3.new(6.2, 1.0, 6.2),
                CFrame.new(0, 13.8, 0),
                brushed, Enum.Material.DiamondPlate, 0.04)
        else
            for side = -1, 1, 2 do
                beam(model, "MicrowaveGuide" .. side, root,
                    Vector3.new(side * 4.7, 8, 1.4),
                    Vector3.new(side * 4.0, 19, 0.0),
                    0.51, brushed, 0.05)
                make("DirectionalReceiver" .. side,
                    Vector3.new(2.3, 2.3, 2.3),
                    CFrame.new(side * 4.0, 19, -0.45),
                    accent, Enum.Material.Glass, 0.34,
                    Enum.PartType.Ball)
            end
            make("SignalWaveguideRib", Vector3.new(7.6, 0.6, 1.5),
                CFrame.new(0, 14.8, -1.7),
                brushed, Enum.Material.DiamondPlate)
            make("ReceiverJunction", Vector3.new(3.6, 3.2, 3.6),
                CFrame.new(0, 23.6, 0),
                weathered, Enum.Material.CorrodedMetal)
        end

        local extraFace = index == 2 and model:FindFirstChild("CargoPod-1")
            or (index == 3 and model:FindFirstChild("ReactorCoreHousing")
                or (index == 4 and model:FindFirstChild("ControlCabin")
                    or model:FindFirstChild("TelemetryCasing")))
        if extraFace then
            DistrictMaterialFinishKit.stencil(
                extraFace, "UNIT " .. number .. " / 48V",
                accent, tier,
                (index == 2 or index == 3) and "hazard" or "telemetry"
            )
        end
    end

    -- A runtime budget check prevents future editorial additions silently
    -- multiplying geometry on phones. This does not mask a broken tier.
    local count = 0
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") then count += 1 end
    end
    model:SetAttribute("Decorative3DParts", count)
    assert(count <= (high and 35 or 16),
        "District sector setpiece exceeded verified tier part budget")
    return model
end

local function rebuild()
    stopKinetics()
    folder:ClearAllChildren()
    local tier = currentTier()
    -- Low-end phones now receive a recognizable five-Part variant instead
    -- of an empty district; it stays subject to the existing scenery LOD.
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = MapVisualReadiness.part(generated, "Arena", "Base")
    if not arena or not base or not base:IsA("BasePart") then return end
    if math.min(base.Size.X, base.Size.Z) < 280 then return end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local theme = VisualTheme.arena(variant)
    for index = 1, 4 do
        makeSector(base, theme, index, tier, variant)
    end
    syncKinetics()
end

local function scheduleRebuild()
    if rebuildQueued then return end
    rebuildQueued = true
    task.defer(function()
        rebuildQueued = false
        rebuild()
    end)
end

local function bindMap(generated)
    if disconnectReady then
        disconnectReady()
        disconnectReady = nil
    end
    watchedMap = generated
    if generated then
        disconnectReady = MapVisualReadiness.watch(
            generated, "Arena", "Base", scheduleRebuild
        )
    else
        stopKinetics()
        folder:ClearAllChildren()
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap"
        and child == workspace:FindFirstChild("GeneratedMap") then
        bindMap(child)
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child == watchedMap then
        bindMap(workspace:FindFirstChild("GeneratedMap"))
    end
end)
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(scheduleRebuild)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(syncKinetics)
bindMap(workspace:FindFirstChild("GeneratedMap"))
scheduleRebuild()
