local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)
local WorldDepthRules = require(ReplicatedStorage.Shared.WorldDepthRules)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "ChaosEnvironmentDepthLocal"
folder.Parent = workspace

local structures = {}
local glows = {}
local transitGlows = {}
local currentAccent = VisualTheme.Accents.Cyan
local secondaryAccent = VisualTheme.Accents.Violet

local function clear()
    for _, instance in ipairs(structures) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
    table.clear(structures)
    table.clear(glows)
    table.clear(transitGlows)
end

local function makePart(name, size, cframe, color, material, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Size = size
    p.CFrame = cframe
    p.Color = color
    p.Material = material
    p.Transparency = transparency or 0
    p.Parent = folder
    table.insert(structures, p)
    return p
end

local function arenaVariant()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    return tostring(arena and arena:GetAttribute("VariantId") or "Classic")
end

local function linePart(name, from, to, thickness, color, material, transparency)
    local delta = to - from
    local length = math.max(0.1, delta.Magnitude)
    local midpoint = from + delta * 0.5
    return makePart(
        name,
        Vector3.new(thickness, thickness, length),
        CFrame.lookAt(midpoint, to),
        color,
        material,
        transparency
    )
end

local function addTransitDepth(tier)
    local budget = WorldDepthRules.budgets(tier.Name)
    local direction = Config.ArenaCenter - Config.LobbyCenter
    local horizontal = Vector3.new(direction.X, 0, direction.Z)
    if horizontal.Magnitude < 0.01 then
        return
    end

    local forward = horizontal.Unit
    local right = Vector3.new(forward.Z, 0, -forward.X)
    local sideDistance = 17.5
    local firstPosition = nil
    local lastPosition = nil

    for i = 1, budget.TransitRibs do
        local position, alpha = WorldDepthRules.transitionSample(
            Config.LobbyCenter,
            Config.ArenaCenter,
            i,
            budget.TransitRibs
        )
        firstPosition = firstPosition or position
        lastPosition = position

        local height = 10 + math.sin(alpha * math.pi) * 6
        local left = position + right * sideDistance + Vector3.new(0, height * 0.5 - 2.5, 0)
        local rightPos = position - right * sideDistance + Vector3.new(0, height * 0.5 - 2.5, 0)

        local leftSupport = makePart(
            "TransitSupportL" .. i,
            Vector3.new(1.2, height, 1.2),
            CFrame.new(left),
            VisualTheme.World.Deep:Lerp(VisualTheme.World.Metal, 0.46),
            VisualTheme.Materials.Structure,
            tier.Name == "Low" and 0.30 or 0.16
        )
        leftSupport.CastShadow = false

        local rightSupport = makePart(
            "TransitSupportR" .. i,
            Vector3.new(1.2, height, 1.2),
            CFrame.new(rightPos),
            VisualTheme.World.Deep:Lerp(VisualTheme.World.Metal, 0.46),
            VisualTheme.Materials.Structure,
            tier.Name == "Low" and 0.30 or 0.16
        )
        rightSupport.CastShadow = false

        local topCenter = position + Vector3.new(0, height - 2.5, 0)
        local cross = linePart(
            "TransitCrossbeam" .. i,
            topCenter + right * sideDistance,
            topCenter - right * sideDistance,
            tier.Name == "Low" and 0.55 or 0.70,
            i % 2 == 0 and currentAccent or secondaryAccent,
            VisualTheme.Materials.Glow,
            tier.Name == "Low" and 0.66 or 0.42
        )
        cross.CastShadow = false
        table.insert(glows, cross)
        table.insert(transitGlows, cross)

        if tier.Name ~= "Low" then
            local lower = linePart(
                "TransitLowerBrace" .. i,
                position + right * (sideDistance - 1.2) + Vector3.new(0, -5.8, 0),
                position - right * (sideDistance - 1.2) + Vector3.new(0, -5.8, 0),
                0.42,
                VisualTheme.World.MetalLight,
                VisualTheme.Materials.Structure,
                0.38
            )
            lower.CastShadow = false
        end
    end

    if firstPosition and lastPosition then
        for side = -1, 1, 2 do
            local offset = right * sideDistance * side
            local from = firstPosition + offset + Vector3.new(0, -6.2, 0)
            local to = lastPosition + offset + Vector3.new(0, -6.2, 0)
            local rail = linePart(
                side < 0 and "TransitRailLeft" or "TransitRailRight",
                from,
                to,
                0.68,
                side < 0 and currentAccent or secondaryAccent,
                VisualTheme.Materials.Glow,
                tier.Name == "Low" and 0.72 or 0.48
            )
            rail.CastShadow = false
            table.insert(glows, rail)
            table.insert(transitGlows, rail)
        end
    end

    for i = 1, budget.UnderworldStruts do
        local position = Config.LobbyCenter:Lerp(
            Config.ArenaCenter,
            0.20 + (i / (budget.UnderworldStruts + 1)) * 0.58
        )
        local width = 22 + (i % 2) * 10
        local under = makePart(
            "UnderworldStrut" .. i,
            Vector3.new(width, 1.6, 7.5),
            CFrame.new(position + Vector3.new(0, -13 - (i % 2) * 3, 0))
                * CFrame.Angles(0, math.rad((i % 2 == 0) and 12 or -12), 0),
            VisualTheme.World.Void:Lerp(VisualTheme.World.Metal, 0.30),
            VisualTheme.Materials.Structure,
            tier.Name == "Low" and 0.42 or 0.26
        )
        under.CastShadow = false
    end
end

local function addHorizonDepth(tier)
    local budget = WorldDepthRules.budgets(tier.Name)
    local center = WorldDepthRules.worldCenter(
        Config.LobbyCenter,
        Config.ArenaCenter
    )
    local radius = WorldDepthRules.horizonRadius(tier.Name)

    for i = 1, budget.HorizonStructures do
        local angle = ((i - 1) / budget.HorizonStructures) * math.pi * 2
            + math.rad(7)
        local radialOffset = radius + ((i * 23) % 31) - 15
        local height = WorldDepthRules.horizonHeight(i)
        local width = 10 + ((i * 7) % 13)
        local depth = 7 + ((i * 5) % 8)
        local position = center + Vector3.new(
            math.cos(angle) * radialOffset,
            (height * 0.5) - 12,
            math.sin(angle) * radialOffset
        )

        local body = makePart(
            "HorizonMonolith" .. i,
            Vector3.new(width, height, depth),
            CFrame.new(position) * CFrame.Angles(0, -angle + math.rad((i % 3 - 1) * 7), 0),
            VisualTheme.World.Void:Lerp(VisualTheme.World.Metal, 0.24 + (i % 3) * 0.07),
            VisualTheme.Materials.Structure,
            tier.Name == "Low" and 0.42 or 0.30
        )
        body.CastShadow = false

        if i <= budget.HorizonAccents or i % 3 == 0 then
            local accentHeight = math.max(8, height * 0.56)
            local slit = makePart(
                "HorizonSlit" .. i,
                Vector3.new(0.38, accentHeight, depth + 0.12),
                body.CFrame + Vector3.new(0, height * 0.06, 0),
                i % 2 == 0 and currentAccent or secondaryAccent,
                VisualTheme.Materials.Glow,
                tier.Name == "Low" and 0.76 or 0.58
            )
            slit.CastShadow = false
            table.insert(glows, slit)
        end

        if tier.Name == "High" and i % 4 == 0 then
            local crown = makePart(
                "HorizonCrown" .. i,
                Vector3.new(width + 7, 0.55, depth + 4),
                body.CFrame + Vector3.new(0, height * 0.5 + 0.8, 0),
                i % 2 == 0 and secondaryAccent or currentAccent,
                VisualTheme.Materials.Glow,
                0.62
            )
            crown.CastShadow = false
            table.insert(glows, crown)
        end
    end

    local floor = makePart(
        "WorldDepthFloor",
        Vector3.new(radius * 1.55, 1.2, radius * 1.55),
        CFrame.new(center + Vector3.new(0, -30, 0)),
        VisualTheme.World.Void,
        Enum.Material.SmoothPlastic,
        tier.Name == "Low" and 0.32 or 0.18
    )
    floor.CastShadow = false
end

local function rebuild()
applyTransitPhase(currentPhase)
    clear()

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    addTransitDepth(tier)
    addHorizonDepth(tier)
    local variant = arenaVariant()
    local count = tier.Name == "Low" and 6 or (tier.Name == "Medium" and 8 or 10)
    local radius = variant == "Orbital" and 142
        or (variant == "Towers" and 136 or 128)

    local lobbyCount = tier.Name == "Low" and 4 or (tier.Name == "Medium" and 6 or 8)
    local lobbyRadius = 72
    for i = 1, lobbyCount do
        local angle = ((i - 1) / lobbyCount) * math.pi * 2 + math.rad(22.5)
        local height = 18 + ((i * 9) % 18)
        local width = 5 + ((i * 3) % 5)
        local position = Config.LobbyCenter + Vector3.new(
            math.cos(angle) * lobbyRadius,
            (height * 0.5) - 2,
            math.sin(angle) * lobbyRadius
        )

        local tower = makePart(
            "LobbyDistantTower" .. i,
            Vector3.new(width, height, width),
            CFrame.new(position) * CFrame.Angles(0, -angle, 0),
            VisualTheme.World.Deep:Lerp(VisualTheme.World.Metal, 0.34),
            VisualTheme.Materials.Structure,
            tier.Name == "Low" and 0.28 or 0.18
        )

        local cap = makePart(
            "LobbyDistantGlow" .. i,
            Vector3.new(width + 1.2, 0.42, width + 1.2),
            tower.CFrame + Vector3.new(0, (height * 0.5) + 0.25, 0),
            i % 2 == 0 and VisualTheme.Accents.Cyan or VisualTheme.Accents.Violet,
            VisualTheme.Materials.Glow,
            tier.Name == "Low" and 0.58 or 0.38
        )
        table.insert(glows, cap)

        if tier.Name == "High" and i % 2 == 0 then
            local fin = makePart(
                "LobbyDistantFin" .. i,
                Vector3.new(0.32, 5.5, width + 2.2),
                tower.CFrame + Vector3.new(0, (height * 0.5) - 3.0, 0),
                i % 4 == 0 and VisualTheme.Accents.Violet or VisualTheme.Accents.Cyan,
                VisualTheme.Materials.Glow,
                0.46
            )
            fin.CastShadow = false
        end
    end

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2
        local height
        local width
        if variant == "Towers" then
            height = 50 + ((i * 13) % 34)
            width = 4 + ((i * 3) % 4)
        elseif variant == "Crossroads" then
            height = 18 + ((i * 7) % 15)
            width = 11 + ((i * 5) % 7)
        elseif variant == "Orbital" then
            height = 16 + ((i * 5) % 11)
            width = 6 + ((i * 3) % 4)
        else
            height = 28 + ((i * 11) % 24)
            width = 7 + ((i * 5) % 5)
        end
        local position = Config.ArenaCenter + Vector3.new(
            math.cos(angle) * radius,
            (height * 0.5) - 5,
            math.sin(angle) * radius
        )

        local body = makePart(
            "DistantSpire" .. i,
            Vector3.new(width, height, width),
            CFrame.new(position) * CFrame.Angles(0, -angle, 0),
            VisualTheme.World.Deep:Lerp(VisualTheme.World.Metal, variant == "Towers" and 0.42 or 0.28),
            VisualTheme.Materials.Structure,
            variant == "Orbital" and 0.24 or 0.16
        )
        if variant == "Orbital" then
            body.Shape = Enum.PartType.Ball
            body.Size = Vector3.new(width, width, width)
        end

        local capHeight = variant == "Orbital" and 0 or ((height * 0.5) + 0.4)
        local cap = makePart(
            "DistantSpireGlow" .. i,
            variant == "Orbital"
                and Vector3.new(width + 2.2, width + 2.2, width + 2.2)
                or Vector3.new(width + 1.6, 0.5, width + 1.6),
            body.CFrame + Vector3.new(0, capHeight, 0),
            i % 2 == 0 and currentAccent or secondaryAccent,
            VisualTheme.Materials.Glow,
            tier.Name == "Low" and 0.48 or 0.32
        )
        if variant == "Orbital" then
            cap.Shape = Enum.PartType.Ball
            cap.Transparency = tier.Name == "Low" and 0.72 or 0.58
        end
        table.insert(glows, cap)

        if tier.Name ~= "Low" and i % 2 == 1 then
            local bridgeAngle = angle + (math.pi / count)
            local bridgePosition = Config.ArenaCenter + Vector3.new(
                math.cos(bridgeAngle) * (radius - 10),
                24 + ((i * 3) % 10),
                math.sin(bridgeAngle) * (radius - 10)
            )
            local bridge = makePart(
                "DistantBridge" .. i,
                variant == "Crossroads"
                    and Vector3.new(28, 0.7, 3.0)
                    or (variant == "Orbital" and Vector3.new(22, 0.45, 1.4) or Vector3.new(18, 0.6, 2.2)),
                CFrame.new(bridgePosition) * CFrame.Angles(0, -bridgeAngle, math.rad((i % 3) - 1)),
                VisualTheme.World.Metal,
                VisualTheme.Materials.Structure,
                0.24
            )
            bridge.CastShadow = false
        end
    end

    -- Midground architectural belt. This fills the visual gap between the playable
    -- arena and the far skyline without adding collision or route clutter.
    local midCount = tier.Name == "Low" and 6 or (tier.Name == "Medium" and 8 or 10)
    local midRadius = variant == "Orbital" and 86 or (variant == "Towers" and 92 or 88)
    for i = 1, midCount do
        local angle = ((i - 1) / midCount) * math.pi * 2 + math.rad(9)
        local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local tangent = angle + math.pi * 0.5
        local width = variant == "Crossroads" and 14 or (variant == "Towers" and 7 or 10)
        local height = variant == "Towers" and (22 + ((i * 7) % 18))
            or (variant == "Orbital" and 12 or (16 + ((i * 5) % 10)))
        local position = Config.ArenaCenter + radial * midRadius + Vector3.new(0, (height * 0.5) - 4, 0)

        local support = makePart(
            "MidgroundSupport" .. i,
            Vector3.new(width, height, width),
            CFrame.new(position) * CFrame.Angles(0, -tangent, 0),
            VisualTheme.World.Deep:Lerp(VisualTheme.World.Metal, 0.40),
            VisualTheme.Materials.Structure,
            tier.Name == "Low" and 0.30 or 0.18
        )

        if variant == "Orbital" then
            support.Shape = Enum.PartType.Cylinder
            support.CFrame = support.CFrame * CFrame.Angles(0, 0, math.rad(90))
        end

        local capSize = variant == "Towers"
            and Vector3.new(width + 2, 0.40, width + 2)
            or Vector3.new(width + 3, 0.34, width + 3)
        local cap = makePart(
            "MidgroundAccent" .. i,
            capSize,
            CFrame.new(position + Vector3.new(0, (height * 0.5) + 0.25, 0))
                * CFrame.Angles(0, -tangent, 0),
            i % 2 == 0 and currentAccent or secondaryAccent,
            VisualTheme.Materials.Glow,
            tier.Name == "Low" and 0.62 or 0.38
        )
        table.insert(glows, cap)

        if tier.Name ~= "Low" and i % 2 == 0 then
            local spanLength = variant == "Crossroads" and 24 or 18
            local span = makePart(
                "MidgroundSpan" .. i,
                Vector3.new(spanLength, 0.42, 1.15),
                CFrame.new(
                    Config.ArenaCenter
                        + radial * (midRadius - 7)
                        + Vector3.new(0, 8 + ((i * 2) % 5), 0)
                ) * CFrame.Angles(0, -tangent, 0),
                VisualTheme.World.MetalLight,
                VisualTheme.Materials.Structure,
                0.28
            )
            span.CastShadow = false
        end
    end

    -- A faint outer floor/readability halo visually grounds the arena in its environment.
    -- It is intentionally non-collidable and mostly transparent.
    local haloSize = variant == "Orbital" and 180 or 168
    local halo = makePart(
        "ArenaGroundHalo",
        Vector3.new(haloSize, 0.18, haloSize),
        CFrame.new(Config.ArenaCenter + Vector3.new(0, -6.2, 0)),
        VisualTheme.World.Deep:Lerp(VisualTheme.World.Surface, 0.28),
        Enum.Material.SmoothPlastic,
        tier.Name == "Low" and 0.78 or 0.70
    )
    halo.CastShadow = false

    -- Near-skyline framing language unique to each arena.
    if variant == "Classic" then
        for side = -1, 1, 2 do
            local frameX = side * 78
            local frame = makePart(
                "ClassicFrameColumn" .. tostring(side),
                Vector3.new(5, 30, 5),
                CFrame.new(Config.ArenaCenter + Vector3.new(frameX, 10, 0)),
                VisualTheme.World.Metal,
                VisualTheme.Materials.Structure,
                0.18
            )
            local cross = makePart(
                "ClassicFrameCross" .. tostring(side),
                Vector3.new(18, 2.2, 4.2),
                frame.CFrame + Vector3.new(-side * 6.5, 10, 0),
                side < 0 and currentAccent or secondaryAccent,
                VisualTheme.Materials.Glow,
                tier.Name == "Low" and 0.58 or 0.34
            )
            cross.CastShadow = false
        end
    elseif variant == "Towers" then
        for i = 0, 3 do
            local angle = math.rad(i * 90 + 45)
            local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
            local position = Config.ArenaCenter + radial * 82 + Vector3.new(0, 22, 0)
            local spine = makePart(
                "TowerFrameSpine" .. i,
                Vector3.new(4.5, 48, 4.5),
                CFrame.new(position),
                VisualTheme.World.Deep:Lerp(VisualTheme.World.Metal, 0.52),
                VisualTheme.Materials.Structure,
                0.14
            )
            if tier.Name ~= "Low" then
                makePart(
                    "TowerFrameArm" .. i,
                    Vector3.new(18, 1.1, 2.2),
                    spine.CFrame
                        * CFrame.new(radial.X * -6, 10, radial.Z * -6)
                        * CFrame.Angles(0, -angle + math.pi * 0.5, 0),
                    i % 2 == 0 and currentAccent or secondaryAccent,
                    VisualTheme.Materials.Glow,
                    0.42
                )
            end
        end
    elseif variant == "Crossroads" then
        local offsets = {
            Vector3.new(0, 11, -82),
            Vector3.new(0, 11, 82),
            Vector3.new(-82, 11, 0),
            Vector3.new(82, 11, 0),
        }
        for i, offset in ipairs(offsets) do
            local horizontal = i <= 2
            local gate = makePart(
                "CrossroadsFrameGate" .. i,
                horizontal and Vector3.new(38, 2.5, 4) or Vector3.new(4, 2.5, 38),
                CFrame.new(Config.ArenaCenter + offset),
                VisualTheme.World.Metal,
                VisualTheme.Materials.Structure,
                0.16
            )
            local sign = makePart(
                "CrossroadsFrameSign" .. i,
                horizontal and Vector3.new(23, 0.7, 4.3) or Vector3.new(4.3, 0.7, 23),
                gate.CFrame + Vector3.new(0, 2.2, 0),
                i % 2 == 0 and secondaryAccent or currentAccent,
                VisualTheme.Materials.Glow,
                tier.Name == "Low" and 0.58 or 0.30
            )
            sign.CastShadow = false
        end
    elseif variant == "Orbital" then
        local segments = tier.Name == "Low" and 6 or 10
        local radius = 78
        for i = 1, segments do
            local angle = ((i - 1) / segments) * math.pi * 2
            local tangent = angle + math.pi * 0.5
            local position = Config.ArenaCenter + Vector3.new(
                math.cos(angle) * radius,
                13 + math.sin(angle * 2) * 2,
                math.sin(angle) * radius
            )
            local arc = makePart(
                "OrbitalInnerArc" .. i,
                Vector3.new(22, 1.0, 2.6),
                CFrame.new(position) * CFrame.Angles(0, -tangent, math.rad(math.sin(angle) * 5)),
                i % 2 == 0 and currentAccent or VisualTheme.World.MetalLight,
                i % 2 == 0 and VisualTheme.Materials.Glow or VisualTheme.Materials.Structure,
                i % 2 == 0 and (tier.Name == "Low" and 0.62 or 0.36) or 0.20
            )
            arc.CastShadow = false
        end
    end

    -- Variant-specific skyline landmarks. These stay outside the playable arena
    -- so they improve silhouette/readability without affecting collision or routes.
    if variant == "Classic" then
        for side = -1, 1, 2 do
            local x = side * 104
            local mast = makePart(
                "ClassicBroadcastMast" .. tostring(side),
                Vector3.new(4.2, 54, 4.2),
                CFrame.new(Config.ArenaCenter + Vector3.new(x, 22, -78)),
                VisualTheme.World.Metal,
                VisualTheme.Materials.Structure,
                0.10
            )
            makePart(
                "ClassicBroadcastCrown" .. tostring(side),
                Vector3.new(18, 1.1, 5),
                mast.CFrame + Vector3.new(0, 21, 0),
                side < 0 and currentAccent or secondaryAccent,
                VisualTheme.Materials.Glow,
                tier.Name == "Low" and 0.56 or 0.30
            )
        end
    elseif variant == "Towers" then
        local skylineOffsets = {
            Vector3.new(-92, 28, -78),
            Vector3.new(92, 34, -78),
            Vector3.new(-92, 40, 78),
            Vector3.new(92, 31, 78),
        }
        for i, offset in ipairs(skylineOffsets) do
            local body = makePart(
                "TowerMegastructure" .. i,
                Vector3.new(13, 72 + (i % 2) * 18, 13),
                CFrame.new(Config.ArenaCenter + offset),
                VisualTheme.World.Deep:Lerp(VisualTheme.World.Metal, 0.48),
                VisualTheme.Materials.Structure,
                0.10
            )
            if tier.Name ~= "Low" then
                makePart(
                    "TowerVerticalRail" .. i,
                    Vector3.new(0.7, body.Size.Y * 0.72, 14.0),
                    body.CFrame + Vector3.new(0, 4, 0),
                    i % 2 == 0 and currentAccent or secondaryAccent,
                    VisualTheme.Materials.Glow,
                    0.42
                )
            end
        end
    elseif variant == "Crossroads" then
        for i = 0, 3 do
            local angle = math.rad(i * 90)
            local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
            local position = Config.ArenaCenter + radial * 105 + Vector3.new(0, 18, 0)
            local gantry = makePart(
                "CrossroadsSkyGantry" .. i,
                Vector3.new(i % 2 == 0 and 34 or 5, 4.2, i % 2 == 0 and 5 or 34),
                CFrame.new(position),
                VisualTheme.World.Metal,
                VisualTheme.Materials.Structure,
                0.12
            )
            makePart(
                "CrossroadsSkySignal" .. i,
                Vector3.new(i % 2 == 0 and 25 or 1.1, 0.75, i % 2 == 0 and 1.1 or 25),
                gantry.CFrame + Vector3.new(0, 3.0, 0),
                i % 2 == 0 and currentAccent or secondaryAccent,
                VisualTheme.Materials.Glow,
                tier.Name == "Low" and 0.54 or 0.28
            )
        end
    elseif variant == "Orbital" then
        local ringRadius = 112
        local segments = tier.Name == "Low" and 8 or 12
        for i = 1, segments do
            local angle = ((i - 1) / segments) * math.pi * 2
            local tangent = angle + math.pi * 0.5
            local position = Config.ArenaCenter + Vector3.new(
                math.cos(angle) * ringRadius,
                24 + math.sin(angle * 2) * 4,
                math.sin(angle) * ringRadius
            )
            makePart(
                "OrbitalSkyRing" .. i,
                Vector3.new(30, 1.2, 3.2),
                CFrame.new(position) * CFrame.Angles(0, -tangent, math.rad(math.sin(angle) * 7)),
                i % 3 == 0 and secondaryAccent or currentAccent,
                i % 2 == 0 and VisualTheme.Materials.Glow or VisualTheme.Materials.Structure,
                i % 2 == 0 and (tier.Name == "Low" and 0.58 or 0.34) or 0.18
            )
        end
    end
end

local transitionToken = 0
local currentPhase = "waiting"

local function applyTransitPhase(phase)
    currentPhase = tostring(phase or "waiting")
    transitionToken += 1
    local token = transitionToken
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local reduced = player:GetAttribute("ReduceMotion") == true

    if currentPhase == "ready" then
        for index, part in ipairs(transitGlows) do
            if part and part.Parent then
                local delaySeconds = reduced and 0 or ((index - 1) * 0.045)
                task.delay(delaySeconds, function()
                    if token ~= transitionToken or not part.Parent then
                        return
                    end

                    TweenService:Create(
                        part,
                        TweenInfo.new(
                            reduced and 0.08 or 0.16,
                            Enum.EasingStyle.Quad,
                            Enum.EasingDirection.Out
                        ),
                        {Transparency = tier.Name == "Low" and 0.48 or 0.20}
                    ):Play()

                    task.delay(reduced and 0.10 or 0.20, function()
                        if token == transitionToken and part.Parent then
                            TweenService:Create(
                                part,
                                TweenInfo.new(
                                    reduced and 0.10 or 0.28,
                                    Enum.EasingStyle.Quad,
                                    Enum.EasingDirection.Out
                                ),
                                {Transparency = tier.Name == "Low" and 0.68 or 0.44}
                            ):Play()
                        end
                    end)
                end)
            end
        end
        return
    end

    local targetTransparency
    if currentPhase == "round" then
        targetTransparency = tier.Name == "Low" and 0.88 or 0.76
    elseif currentPhase == "result" then
        targetTransparency = tier.Name == "Low" and 0.74 or 0.56
    else
        targetTransparency = tier.Name == "Low" and 0.72 or 0.50
    end

    for _, part in ipairs(transitGlows) do
        if part and part.Parent then
            TweenService:Create(
                part,
                TweenInfo.new(
                    reduced and 0.08 or 0.24,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                ),
                {Transparency = targetTransparency}
            ):Play()
        end
    end
end

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    rebuild()
    applyTransitPhase(currentPhase)
end)

player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    applyTransitPhase(currentPhase)
end)

local mapConnection = nil

local function bindMap()
    if mapConnection then
        mapConnection:Disconnect()
        mapConnection = nil
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    if generated then
        mapConnection = generated.ChildAdded:Connect(function(child)
            if child.Name == "Arena" then
                task.defer(rebuild)
            end
        end)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(function()
            bindMap()
            rebuild()
        end)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clear()
        bindMap()
    end
end)

bindMap()

stateEvent.OnClientEvent:Connect(function(state)
    applyTransitPhase(state.phase)

    local ids = state.disasterIds or {}
    local profile = DisasterVisuals.combine(ids)
    local secondary = ids[2] and DisasterVisuals.get(ids[2]) or nil

    if profile then
        currentAccent = profile.Accent
        secondaryAccent = secondary and secondary.Accent or VisualTheme.Accents.Violet
    else
        currentAccent = VisualTheme.Accents.Cyan
        secondaryAccent = VisualTheme.Accents.Violet
    end

    for i, glow in ipairs(glows) do
        if glow.Parent then
            glow.Color = i % 2 == 0 and currentAccent or secondaryAccent
        end
    end
end)

rebuild()
