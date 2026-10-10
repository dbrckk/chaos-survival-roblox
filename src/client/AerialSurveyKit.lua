-- Authored, stylized rescue/survey drones: faceted wings, twin turbines,
-- cockpit glass, warning beacons, and animated rotor vanes.
-- All elements are client-local and have NO collision, touch or query.
local AerialSurveyRules = require(game:GetService("ReplicatedStorage").Shared.AerialSurveyRules)
local AerialSurveyKit = {}

local function piece(drone, name, size, localFrame, color, material, alpha, className, role)
    local p = Instance.new(className or "Part")
    p.Name = name
    p.Size = size
    p.CFrame = drone.root * localFrame
    p.Color = color
    p.Material = material
    p.Transparency = alpha or 0
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = drone.folder
    table.insert(drone.sections, {part = p, frame = localFrame, role = role, baseColor = color})
    return p
end

local function buildDrone(parent, base, variant, theme, tier, index, total)
    local folder = Instance.new("Folder")
    folder.Name = "SurveyDrone" .. index
    folder.Parent = parent
    local initial = AerialSurveyRules.flightFrame(base, variant, index, total, 0)
    local craft = {
        folder = folder, root = initial, sections = {},
        base = base, variant = variant, tier = tier, index = index,
        total = total, trail = nil, light = nil,
        accent = theme.Accent,
    }
    local armor = theme.Structure:Lerp(Color3.fromRGB(22, 33, 50), 0.32)
    local silver = theme.Detail:Lerp(Color3.fromRGB(167, 188, 204), 0.22)
    local glow = theme.Accent

    piece(craft, "SurveyArmoredHull", Vector3.new(2.6, 1.05, 4.4),
        CFrame.new(0, 0, 0), armor, Enum.Material.Metal, 0.02, "Part", "hull").Shape = Enum.PartType.Ball
    piece(craft, "SurveyCockpit", Vector3.new(1.85, 0.63, 2.2),
        CFrame.new(0, 0.43, -0.97), silver, Enum.Material.Glass, 0.28, "WedgePart", "cockpit")
    for side = -1, 1, 2 do
        piece(craft, "SurveyDeltaWing" .. side,
            Vector3.new(3.9, 0.24, 2.35),
            CFrame.new(side * 2.15, -0.03, 0.12)
                * CFrame.Angles(0, math.rad(side * 10), math.rad(side * -5)),
            armor, Enum.Material.DiamondPlate, 0.03, "WedgePart", "wing")
    end
    piece(craft, "SurveyDorsalSpine", Vector3.new(0.38, 0.28, 2.6),
        CFrame.new(0, 0.66, 0.5), silver, Enum.Material.Metal, 0.07)
    local beacon = piece(craft, "SurveyThreatBeacon", Vector3.new(0.72, 0.25, 0.92),
        CFrame.new(0, 0.82, -0.7), glow, Enum.Material.Neon, 0.22, "Part", "beacon")

    if tier ~= "Low" then
        for side = -1, 1, 2 do
            local enginePos = CFrame.new(side * 1.08, -0.35, 1.65)
            piece(craft, "SurveyTurbine" .. side, Vector3.new(0.88, 0.88, 1.75),
                enginePos, silver, Enum.Material.Metal, 0.07, "Part", "engine").Shape = Enum.PartType.Cylinder
            piece(craft, "SurveyExhaust" .. side, Vector3.new(0.60, 0.60, 0.16),
                enginePos * CFrame.new(0, 0, 0.90),
                glow, Enum.Material.Neon, 0.16, "Part", "exhaust").Shape = Enum.PartType.Cylinder
        end
        piece(craft, "SurveySplitTail", Vector3.new(1.4, 0.56, 1.0),
            CFrame.new(0, 0.37, 1.94), armor, Enum.Material.Metal, 0.04, "WedgePart", "tail")
    end

    if tier == "High" then
        for side = -1, 1, 2 do
            piece(craft, "SurveyVerticalStabilizer" .. side,
                Vector3.new(0.18, 1.03, 1.35),
                CFrame.new(side * 1.14, 0.58, 1.44)
                    * CFrame.Angles(0, 0, math.rad(side * 14)),
                silver, Enum.Material.Metal, 0.09, "WedgePart", "fin")
            piece(craft, "SurveyWingTipSignal" .. side,
                Vector3.new(0.28, 0.13, 0.76),
                CFrame.new(side * 3.86, -0.02, 0.0),
                side < 0 and theme.Secondary or glow,
                Enum.Material.Neon, 0.18, "Part", "navigation")
            piece(craft, "SurveyRotorBlade" .. side,
                Vector3.new(1.3, 0.07, 0.19),
                CFrame.new(side * 1.08, 0.28, 1.65),
                silver, Enum.Material.Metal, 0.20, "Part", "rotor")
        end
        local light = Instance.new("PointLight")
        light.Name = "SurveyThreatFill"
        light.Color = glow
        light.Brightness = 0.48
        light.Range = 11
        light.Shadows = false
        light.Enabled = false
        light.Parent = beacon
        craft.light = light
        local a0 = Instance.new("Attachment")
        a0.Position = Vector3.new(-0.20, 0, 0)
        a0.Parent = beacon
        local a1 = Instance.new("Attachment")
        a1.Position = Vector3.new(0.20, 0, 0)
        a1.Parent = beacon
        local trail = Instance.new("Trail")
        trail.Name = "SurveyEngineFilament"
        trail.Attachment0 = a0
        trail.Attachment1 = a1
        trail.Lifetime = 0.16
        trail.MinLength = 0.1
        trail.LightEmission = 0.75
        trail.FaceCamera = false
        trail.Color = ColorSequence.new(glow)
        trail.Transparency = NumberSequence.new(0.28, 1)
        trail.Enabled = false
        trail.Parent = beacon
        craft.trail = trail
    end
    return craft
end

function AerialSurveyKit.build(parent, arenaBase, variant, tier, theme)
    assert(parent and arenaBase and arenaBase:IsA("BasePart"),
        "AerialSurveyKit needs parent and physical arena base")
    assert(type(theme) == "table" and theme.Structure and theme.Accent,
        "AerialSurveyKit requires an arena theme")
    local profile = AerialSurveyRules.profile(tier)
    local set = Instance.new("Folder")
    set.Name = "AerialSurveyFleet"
    set.Parent = parent
    local fleet = {
        folder = set,
        base = arenaBase,
        variant = variant,
        tier = tier,
        drones = {},
        profile = profile,
        lastAlert = nil,
    }
    local totalParts = 0
    for i = 1, profile.Drones do
        local drone = buildDrone(set, arenaBase, variant, theme, tier, i, profile.Drones)
        table.insert(fleet.drones, drone)
        totalParts += #drone.sections
    end
    assert(totalParts == profile.MaxParts,
        "AerialSurveyFleet should match its exact mobile GPU part budget")
    return fleet
end

function AerialSurveyKit.update(fleet, now, phase, reduced, threatColor, finalRush)
    if not fleet or not fleet.folder.Parent or not fleet.base.Parent then return end
    local active = AerialSurveyRules.animated(phase, fleet.tier, reduced)
    local elapsed = active and (tonumber(now) or 0) or 0
    local alert = AerialSurveyRules.alert(phase, threatColor and {"Hazard"} or nil, finalRush)
    local tint = alert == "critical" and Color3.fromRGB(255, 195, 100)
        or (alert == "hazard" and threatColor or nil)
    for _, drone in ipairs(fleet.drones) do
        local frame = AerialSurveyRules.flightFrame(
            fleet.base, fleet.variant, drone.index, drone.total, elapsed)
        if frame then
            local wingBank = active and math.sin(elapsed * 1.7 + drone.index) * math.rad(2) or 0
            for _, item in ipairs(drone.sections) do
                if item.part.Parent then
                    local animation = CFrame.identity
                    if item.role == "rotor" and active then
                        animation = CFrame.Angles(0, elapsed * 8, 0)
                    elseif item.role == "wing" then
                        animation = CFrame.Angles(0, 0,
                            item.part.Name:find("-1", 1, true) and wingBank or -wingBank)
                    end
                    item.part.CFrame = frame * item.frame * animation
                    if item.role == "beacon" or item.role == "navigation"
                        or item.role == "exhaust"
                    then
                        item.part.Color = tint or item.baseColor
                        item.part.Transparency = alert == "critical" and 0.08 or 0.22
                    end
                end
            end
        end
        if drone.light then
            drone.light.Color = tint or drone.accent
            drone.light.Enabled = active and alert ~= "standby"
        end
        if drone.trail then
            drone.trail.Enabled = active and alert ~= "standby"
            drone.trail.Color = ColorSequence.new(tint or drone.accent)
        end
    end
end

return AerialSurveyKit
