-- Colossal, distinctly authored aerial machines visible beyond the active
-- platform routes. This is presentation only: no physics, touch, query,
-- remotes, hazard interference, assets or artificial traversal surfaces.
-- Each scene is one disposable local bundle, not a replicated map mutation.
local Kit = {}

local PROFILES = {
    Low = {ships = 2, maxPerShip = 13, interval = 0.40, detailed = false, high = false},
    Medium = {ships = 3, maxPerShip = 18, interval = 0.18, detailed = true, high = false},
    High = {ships = 4, maxPerShip = 25, interval = 0.13, detailed = true, high = true},
}

-- Opposing corners are shown first, so even Low renders a balanced skyline.
local SLOTS = {
    {-1, -1}, {1, 1}, {1, -1}, {-1, 1},
}
local SUPPORTED = {
    Classic = true, Towers = true, Crossroads = true,
    Orbital = true, Harbor = true,
}

function Kit.profile(tier)
    return PROFILES[tier] or PROFILES.Medium
end

local function piece(ship, name, size, offset, color, material,
    transparency, shape, role, className)
    local part = Instance.new(className or "Part")
    part.Name = name
    part.Size = size
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = material or Enum.Material.Metal
    part.Color = color
    part.Transparency = transparency or 0
    if shape and part:IsA("Part") then
        part.Shape = shape
    end
    part.CFrame = ship.rest * offset
    part:SetAttribute("CosmeticOnly", true)
    part:SetAttribute("ChaosSkyFleet", true)
    part.Parent = ship.model
    ship.parts[#ship.parts + 1] = {
        part = part, offset = offset, role = role,
        baseTransparency = part.Transparency,
        baseColor = color,
    }
    return part
end

local function constructCommon(ship, theme, variant, profile)
    local steel = theme.Structure:Lerp(theme.Surface, 0.20)
    local armor = theme.Detail:Lerp(theme.Structure, 0.35)
    local hullMaterial = variant == "Harbor" and Enum.Material.CorrodedMetal
        or (variant == "Crossroads" and Enum.Material.DiamondPlate
            or Enum.Material.Metal)

    -- 42-stud native-mesh silhouette. A small 5-stud dashboard decoration
    -- cannot replace this striking physical scale from the ground camera.
    piece(ship, "ArmoredKeel", Vector3.new(13, 5.4, 30),
        CFrame.new(0, 0, 0), steel, hullMaterial, 0.05)
    piece(ship, "FacetedBow", Vector3.new(13, 4.8, 9),
        CFrame.new(0, -0.10, -18.8) * CFrame.Angles(0, math.pi, 0),
        armor, hullMaterial, 0.08, nil, nil, "WedgePart")
    piece(ship, "SternGuard", Vector3.new(10, 4.2, 7),
        CFrame.new(0, -0.10, 17.1),
        armor, hullMaterial, 0.09, nil, nil, "WedgePart")
    for side = -1, 1, 2 do
        piece(ship, side == -1 and "PortLiftWing" or "StarboardLiftWing",
            Vector3.new(10.5, 1.0, 11),
            CFrame.new(side * 10.0, -0.5, 1.5)
                * CFrame.Angles(0, 0, math.rad(side * 8)),
            armor, Enum.Material.Metal, 0.06)
        piece(ship, side == -1 and "PortThruster" or "StarboardThruster",
            Vector3.new(3.2, 2.9, 5.2),
            CFrame.new(side * 5.0, -2.6, 14.6),
            theme.Secondary:Lerp(steel, 0.40),
            Enum.Material.Metal, 0.10)
    end

    if profile.detailed then
        piece(ship, "PressureDeck", Vector3.new(8.4, 0.75, 19),
            CFrame.new(0, 3.0, -1.2), armor,
            Enum.Material.DiamondPlate, 0.12)
        piece(ship, "ForwardBridge", Vector3.new(8.2, 4.2, 6.0),
            CFrame.new(0, 5.25, -5.2), steel, Enum.Material.Metal, 0.04)
        piece(ship, "BridgeGlass", Vector3.new(7.0, 1.45, 0.25),
            CFrame.new(0, 5.8, -8.30), theme.Accent,
            Enum.Material.Glass, 0.38)
    end
end

local function addClassic(ship, theme, profile)
    piece(ship, "SurveyArrayMast", Vector3.new(1.2, 11.0, 1.2),
        CFrame.new(0, 8.6, 2), theme.Detail, Enum.Material.Metal)
    local hub = CFrame.new(0, 14.35, 2)
    piece(ship, "SurveyRotationBearing", Vector3.new(4.2, 1.2, 4.2),
        hub, theme.Structure, Enum.Material.Metal, 0.10,
        Enum.PartType.Cylinder, "scan")
    piece(ship, "ColossalRadarSweep", Vector3.new(27, 0.35, 1.0),
        hub * CFrame.new(0, 0.9, 0), theme.Accent,
        Enum.Material.Metal, 0.12, nil, "scan")
    if profile.detailed then
        piece(ship, "RearTelemetryLobe", Vector3.new(5, 5, 5),
            CFrame.new(0, 7.8, 11), theme.Secondary,
            Enum.Material.Glass, 0.32, Enum.PartType.Ball)
        piece(ship, "AntennaCompanion", Vector3.new(0.5, 7, 0.5),
            CFrame.new(3.8, 10.8, 9.0), theme.Detail,
            Enum.Material.Metal)
    end
    if profile.high then
        for side = -1, 1, 2 do
            piece(ship, "SideOptics" .. side, Vector3.new(3.4, 1.0, 4.0),
                CFrame.new(side * 8.2, 2.7, 2.0)
                    * CFrame.Angles(0, 0, math.rad(side * 25)),
                theme.Secondary, Enum.Material.Glass, 0.25)
        end
    end
end

local function addTowers(ship, theme, profile)
    for side = -1, 1, 2 do
        piece(ship, "FreightLiftRail" .. side, Vector3.new(1.5, 22, 1.7),
            CFrame.new(side * 5.0, 9.8, -1.5),
            theme.Structure, Enum.Material.DiamondPlate, 0.05)
    end
    piece(ship, "FreightLiftCrosshead", Vector3.new(13.6, 2.0, 5.0),
        CFrame.new(0, 20.2, -1.5), theme.Detail, Enum.Material.Metal)
    piece(ship, "MovingCargoCabin", Vector3.new(8.0, 6.0, 9.0),
        CFrame.new(0, 8.4, -1.5), theme.Secondary:Lerp(
            theme.Structure, 0.60), Enum.Material.CorrodedMetal, 0.06, nil, "lift")
    if profile.detailed then
        piece(ship, "LiftCounterweight", Vector3.new(3.0, 7, 2.5),
            CFrame.new(7.1, 10.5, -1.5),
            theme.Detail, Enum.Material.Metal, 0.08, nil, "counter")
        piece(ship, "LiftMachineRoom", Vector3.new(6.7, 3.3, 7),
            CFrame.new(0, 23.0, -1.5),
            theme.Structure, Enum.Material.CorrodedMetal, 0.10)
    end
    if profile.high then
        piece(ship, "LiftCabinWindow", Vector3.new(7.0, 2.2, 0.20),
            CFrame.new(0, 8.6, -6.10),
            theme.Accent, Enum.Material.Glass, 0.30, nil, "lift")
        for side = -1, 1, 2 do
            piece(ship, "HydraulicSupport" .. side,
                Vector3.new(1.1, 9, 1.1),
                CFrame.new(side * 7.6, 8, -1.7)
                    * CFrame.Angles(0, 0, math.rad(side * 14)),
                theme.Detail, Enum.Material.Metal)
        end
    end
end

local function addCrossroads(ship, theme, profile)
    piece(ship, "TransitCentralInterchange",
        Vector3.new(16, 1.7, 15), CFrame.new(0, 5.0, 1),
        theme.Structure, Enum.Material.DiamondPlate)
    for side = -1, 1, 2 do
        piece(ship, "MaglevSwitchFork" .. side,
            Vector3.new(2.6, 1.0, 22),
            CFrame.new(side * 7.0, 2.8, -1.6)
                * CFrame.Angles(0, math.rad(side * 20), 0),
            theme.Detail, Enum.Material.Metal, 0.06, nil, "switch")
    end
    piece(ship, "DispatchSignal", Vector3.new(1.0, 4.0, 15),
        CFrame.new(0, 9.0, -1), theme.Accent,
        Enum.Material.Metal, 0.12)
    if profile.detailed then
        piece(ship, "SwitchingControlRoom", Vector3.new(8, 4.5, 5),
            CFrame.new(0, 8.9, 5),
            theme.Structure, Enum.Material.Concrete, 0.06)
        piece(ship, "SwitchingGlass", Vector3.new(7.5, 1.3, 0.24),
            CFrame.new(0, 9.4, 2.4), theme.Secondary,
            Enum.Material.Glass, 0.30)
    end
    if profile.high then
        for side = -1, 1, 2 do
            piece(ship, "TransitLateralFin" .. side,
                Vector3.new(5.0, 7.0, 1.1),
                CFrame.new(side * 11, 6, 6.5)
                    * CFrame.Angles(0, math.rad(side * 16),
                        math.rad(side * 17)),
                theme.Detail, Enum.Material.Metal, 0.08)
        end
    end
end

local function addOrbital(ship, theme, profile)
    local pivot = CFrame.new(0, 11.2, 0)
    piece(ship, "ContainmentReactor", Vector3.new(7, 7, 7),
        pivot, theme.Accent, Enum.Material.Glass,
        0.25, Enum.PartType.Ball)
    for i = 1, 4 do
        local angle = math.pi * 0.5 * (i - 1)
        piece(ship, "CelestialArc" .. i,
            Vector3.new(11.0, 0.75, 1.2),
            pivot * CFrame.new(
                math.cos(angle) * 8.0,
                math.sin(angle) * 8.0, 0)
                * CFrame.Angles(0, 0, angle + math.pi * 0.5),
            i % 2 == 0 and theme.Secondary or theme.Detail,
            Enum.Material.Metal, 0.09, nil, "orbit")
    end
    if profile.detailed then
        piece(ship, "ContainmentCentralSpine",
            Vector3.new(2.2, 11.0, 2.2), CFrame.new(0, 6.0, 0),
            theme.Structure, Enum.Material.CeramicTiles, 0.10)
        for side = -1, 1, 2 do
            piece(ship, "ReactorFieldWing" .. side,
                Vector3.new(4.5, 7.0, 1.0),
                CFrame.new(side * 9.0, 5.6, 0)
                    * CFrame.Angles(0, 0, math.rad(side * 20)),
                theme.Secondary, Enum.Material.CeramicTiles, 0.11)
        end
    end
    if profile.high then
        for side = -1, 1, 2 do
            piece(ship, "FieldStabilizer" .. side,
                Vector3.new(2.2, 2.2, 7),
                CFrame.new(side * 11, 10, 0),
                theme.Accent, Enum.Material.Glass, 0.31)
        end
    end
end

local function addHarbor(ship, theme, profile)
    for side = -1, 1, 2 do
        piece(ship, "CargoCranePillar" .. side,
            Vector3.new(1.7, 13.0, 1.8),
            CFrame.new(side * 7.0, 8.0, 5.0),
            theme.Structure, Enum.Material.CorrodedMetal, 0.04)
    end
    piece(ship, "CargoCraneBoom", Vector3.new(24, 1.8, 2.4),
        CFrame.new(0, 14.5, 5.0),
        theme.Detail, Enum.Material.DiamondPlate, 0.07)
    piece(ship, "SuspendedCargo", Vector3.new(8.0, 5.0, 7.0),
        CFrame.new(2.0, 4.7, 5), theme.Structure:Lerp(
            theme.Secondary, 0.30), Enum.Material.CorrodedMetal, 0.06,
        nil, "hoist")
    if profile.detailed then
        piece(ship, "HoistCable", Vector3.new(0.34, 7.3, 0.34),
            CFrame.new(2.0, 10.1, 5), theme.Detail,
            Enum.Material.Metal, 0.12, nil, "cable")
        for side = -1, 1, 2 do
            piece(ship, "DockContainer" .. side, Vector3.new(5.6, 4.6, 8.2),
                CFrame.new(side * 4.0, 5.1, -6),
                side == -1 and theme.Secondary or theme.Detail,
                Enum.Material.CorrodedMetal, 0.08)
        end
    end
    if profile.high then
        piece(ship, "PortBridge", Vector3.new(9.2, 4.1, 4.4),
            CFrame.new(0, 7.6, -10.0), theme.Structure,
            Enum.Material.Metal, 0.07)
        piece(ship, "PortBridgeWindow", Vector3.new(8.1, 1.2, 0.2),
            CFrame.new(0, 8.1, -12.25), theme.Accent,
            Enum.Material.Glass, 0.34)
        piece(ship, "CraneCounterweight", Vector3.new(4.5, 4.3, 5.4),
            CFrame.new(-10.3, 13.0, 5), theme.Detail,
            Enum.Material.DiamondPlate, 0.06)
    end
end

local BUILD_VARIANT = {
    Classic = addClassic,
    Towers = addTowers,
    Crossroads = addCrossroads,
    Orbital = addOrbital,
    Harbor = addHarbor,
}

function Kit.matches(bundle, base, variant, tier, parent)
    return type(bundle) == "table" and bundle.base == base
        and bundle.variant == variant and bundle.tier == tier
        and bundle.folder and bundle.folder.Parent == parent
end

function Kit.build(parent, base, variant, theme, tier)
    if not base or not base:IsA("BasePart") or not base.Parent
        or not parent or not SUPPORTED[variant] or type(theme) ~= "table" then
        return nil
    end
    local profile = Kit.profile(tier)
    local folder = Instance.new("Folder")
    folder.Name = "SkyFleet_" .. variant
    folder:SetAttribute("CosmeticOnly", true)
    folder.Parent = parent
    local bundle = {
        base = base, variant = variant, tier = tier, folder = folder,
        ships = {}, totalParts = 0,
    }
    local halfX, halfZ = base.Size.X * 0.5, base.Size.Z * 0.5
    for i = 1, profile.ships do
        local signs = SLOTS[i]
        local position = (base.CFrame * CFrame.new(
            signs[1] * (halfX - 17),
            66 + (i % 2) * 10 + (variant == "Orbital" and 8 or 0),
            signs[2] * (halfZ - 17)
        )).Position
        -- Every craft faces the play centre, but remains high above its
        -- distant corner; it cannot obstruct a jump, warning or landing.
        local rest = CFrame.lookAt(position,
            Vector3.new(base.Position.X, position.Y, base.Position.Z))
        local model = Instance.new("Model")
        model.Name = variant .. "ColossalCarrier" .. tostring(i)
        model:SetAttribute("CosmeticOnly", true)
        model:SetAttribute("LocalOriginal3D", true)
        model:SetAttribute("FleetSlot", i)
        model.Parent = folder
        local ship = {model = model, rest = rest, parts = {}, index = i}
        constructCommon(ship, theme, variant, profile)
        BUILD_VARIANT[variant](ship, theme, profile)
        assert(#ship.parts <= profile.maxPerShip,
            "SkyFleet exceeded per-tier authored 3D geometry budget")
        bundle.totalParts += #ship.parts
        bundle.ships[#bundle.ships + 1] = ship
    end
    folder:SetAttribute("FleetPartCount", bundle.totalParts)
    folder:SetAttribute("FleetShipCount", #bundle.ships)
    return bundle
end

-- Preserve identical 3D pose with ReduceMotion. No incremental transforms:
-- each frame uses the originally authored relative pose, so streaming,
-- background app suspension and phase changes never accumulate drift.
function Kit.pose(bundle, elapsed, phase, reducedMotion, finalRush, disasterIds)
    if not bundle or not bundle.folder or not bundle.folder.Parent then
        return
    end
    local active = (phase == "ready" or phase == "round"
        or phase == "result") and reducedMotion ~= true
    local now = type(elapsed) == "number" and elapsed == elapsed
        and math.abs(elapsed) < 1e7 and elapsed >= 0 and elapsed or 0

    -- One coherent weather response for the *entire* far-field air traffic.
    -- These are genuine known round disaster identifiers, not invented
    -- hazards or client-authoritative gameplay state. Freeze slows engines;
    -- lava raises evacuation traffic; tornado induces a broad stable bank.
    local pace, bob, bank, emergencyLift = 1, 1.8, 0.028, 0
    if phase == "round" and type(disasterIds) == "table" then
        for _, id in ipairs(disasterIds) do
            if id == "Tornado" then
                pace, bob, bank = 1.55, 4.5, 0.095
            elseif id == "RisingLava" then
                emergencyLift = math.max(emergencyLift, 9)
                bob = math.max(bob, 2.8)
            elseif id == "LowGravity" then
                emergencyLift = math.max(emergencyLift, 6.5)
                bob = math.max(bob, 3.3)
            elseif id == "Meteors" or id == "Bombs" then
                bob = math.max(bob, 3.7)
                bank = math.max(bank, 0.060)
            elseif id == "Freeze" then
                pace = math.min(pace, 0.63)
                bob = math.min(bob, 1.5)
            end
        end
    end
    if finalRush == true and phase == "round" then
        pace *= 1.24
    end
    for _, ship in ipairs(bundle.ships) do
        -- The existing shared scenery-LOD owner writes visibility masks
        -- per real craft. Avoid CFrame work on a ship it has fully hidden.
        local hull = ship.parts[1] and ship.parts[1].part
        if not hull or (active
            and hull:GetAttribute("SceneryLodHidden") == true) then
            continue
        end
        local originPhase = ship.index * 0.82
        local time = now * pace + originPhase
        -- Zero displacement at t=0, including after ReduceMotion toggles:
        -- no one-frame jumps when READY or RESULT starts.
        local lift = active and
            (math.sin(time * 0.55) - math.sin(originPhase * 0.55))
                * bob or 0
        local roll = active and (
            math.sin(time * 0.36) - math.sin(originPhase * 0.36)
        ) * bank or 0
        local heading = active and (
            math.sin(time * 0.23) - math.sin(originPhase * 0.23)
        ) * 0.044 or 0
        local ascent = active and emergencyLift
            * math.clamp(now / 4.5, 0, 1) or 0
        local root = ship.rest * CFrame.new(0, lift + ascent, 0)
            * CFrame.Angles(0, heading, roll)
        for _, entry in ipairs(ship.parts) do
            local part = entry.part
            if not part.Parent then continue end
            local offset = entry.offset
            if active then
                local hoistWave = math.sin(time * 0.68)
                    - math.sin(originPhase * 0.68)
                if entry.role == "scan" then
                    offset = offset * CFrame.Angles(0, now * 0.48, 0)
                elseif entry.role == "lift" then
                    offset = offset * CFrame.new(0, hoistWave * 3.6, 0)
                elseif entry.role == "counter" then
                    offset = offset * CFrame.new(0, -hoistWave * 3.0, 0)
                elseif entry.role == "switch" then
                    offset = offset * CFrame.Angles(0,
                        (math.sin(time * 0.5)
                            - math.sin(originPhase * 0.5)) * 0.18, 0)
                elseif entry.role == "orbit" then
                    local pivot = CFrame.new(0, 11.2, 0)
                    offset = pivot * CFrame.Angles(0, now * 0.28, 0)
                        * pivot:Inverse() * offset
                elseif entry.role == "hoist" then
                    offset = offset * CFrame.new(0, hoistWave * 2, 0)
                elseif entry.role == "cable" then
                    -- Cable follows the suspended freight at half its
                    -- distance. Original part remains noncolliding.
                    offset = offset * CFrame.new(0, hoistWave, 0)
                end
            end
            part.CFrame = root * offset
        end
    end
end

return Kit
