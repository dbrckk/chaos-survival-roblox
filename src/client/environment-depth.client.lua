local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "ChaosEnvironmentDepthLocal"
folder.Parent = workspace

local structures = {}
local glows = {}
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

local function rebuild()
    clear()

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
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

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(rebuild)

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
