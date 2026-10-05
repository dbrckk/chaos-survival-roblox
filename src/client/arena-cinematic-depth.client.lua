local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "ArenaCinematicDepthLocal"
folder.Parent = workspace

local currentPhase = "waiting"
local currentAccent = nil
local motionToken = 0
local mapConnection = nil

local function clear()
    motionToken += 1
    folder:ClearAllChildren()
end

local function makePart(name, size, cframe, color, material, transparency, castShadow)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = castShadow == true
    part.Material = material or Enum.Material.Metal
    part.Color = color
    part.Transparency = transparency or 0
    part.Parent = folder
    return part
end

local function arenaContext()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not arena or not base or not base:IsA("BasePart") then
        return nil
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    return arena, base, variant, VisualTheme.arena(variant)
end

local function phaseTransparency(baseTransparency)
    if currentPhase == "round" then
        return math.clamp(baseTransparency + 0.10, 0, 0.95)
    elseif currentPhase == "ready" then
        return math.clamp(baseTransparency - 0.04, 0, 0.95)
    elseif currentPhase == "result" then
        return math.clamp(baseTransparency - 0.02, 0, 0.95)
    end
    return baseTransparency
end

local function addHorizonArchitecture(base, variant, theme, tier)
    local count = tier.Name == "Low" and 5 or (tier.Name == "Medium" and 8 or 11)
    local radius = variant == "Orbital" and 148 or (variant == "Towers" and 142 or 136)

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2 + math.rad(11)
        local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local tangent = angle + math.pi * 0.5

        local width
        local height
        local depth

        if variant == "Towers" then
            width = 7 + ((i * 3) % 6)
            height = 44 + ((i * 17) % 42)
            depth = width
        elseif variant == "Crossroads" then
            width = 18 + ((i * 5) % 12)
            height = 18 + ((i * 7) % 18)
            depth = 7 + ((i * 3) % 5)
        elseif variant == "Orbital" then
            width = 11 + ((i * 2) % 5)
            height = 12 + ((i * 5) % 15)
            depth = width
        else
            width = 10 + ((i * 4) % 8)
            height = 28 + ((i * 13) % 32)
            depth = 8 + ((i * 3) % 6)
        end

        local position = base.Position + radial * radius + Vector3.new(0, (height * 0.5) - 8, 0)
        local structure = makePart(
            "CinemaHorizonStructure" .. i,
            Vector3.new(width, height, depth),
            CFrame.new(position) * CFrame.Angles(0, -tangent, 0),
            VisualTheme.World.Deep:Lerp(theme.Structure, variant == "Towers" and 0.42 or 0.28),
            variant == "Crossroads" and Enum.Material.Concrete or Enum.Material.Metal,
            phaseTransparency(tier.Name == "Low" and 0.34 or 0.20),
            tier.Name == "High"
        )

        if variant == "Orbital" then
            structure.Shape = Enum.PartType.Cylinder
            structure.CFrame = structure.CFrame * CFrame.Angles(0, 0, math.rad(90))
        end

        local accent = i % 2 == 0 and theme.Accent or theme.Secondary
        local crownSize = variant == "Towers"
            and Vector3.new(width + 1.6, 0.44, depth + 1.6)
            or Vector3.new(math.max(5, width * 0.72), 0.36, math.max(3, depth * 0.72))
        local crown = makePart(
            "CinemaHorizonCrown" .. i,
            crownSize,
            CFrame.new(position + Vector3.new(0, (height * 0.5) + 0.28, 0))
                * CFrame.Angles(0, -tangent, 0),
            currentAccent or accent,
            Enum.Material.Neon,
            phaseTransparency(tier.Name == "Low" and 0.68 or 0.46),
            false
        )
        crown:SetAttribute("BaseAccentIndex", i)

        if tier.Name == "High" and i % 2 == 1 then
            local slit = makePart(
                "CinemaHorizonSlit" .. i,
                Vector3.new(0.34, math.max(7, height * 0.58), depth + 0.18),
                structure.CFrame * CFrame.new((width * 0.34), 0, 0),
                i % 3 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                phaseTransparency(0.58),
                false
            )
            slit:SetAttribute("BaseAccentIndex", i + 1)
        end
    end
end

local function addHeroSilhouette(base, variant, theme, tier)
    if tier.Name == "Low" then
        return
    end

    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5

    if variant == "Classic" then
        for side = -1, 1, 2 do
            local frame = base.CFrame * CFrame.new(side * (hx + 40), 26, -hz - 62)
            local mast = makePart(
                side < 0 and "CinemaClassicMastL" or "CinemaClassicMastR",
                Vector3.new(5.2, 58, 5.2),
                frame,
                VisualTheme.World.Metal,
                Enum.Material.Metal,
                phaseTransparency(0.18),
                tier.Name == "High"
            )
            makePart(
                side < 0 and "CinemaClassicCrownL" or "CinemaClassicCrownR",
                Vector3.new(24, 1.2, 6.0),
                mast.CFrame * CFrame.new(-side * 7.5, 18, 0),
                side < 0 and theme.Accent or theme.Secondary,
                Enum.Material.Neon,
                phaseTransparency(0.42),
                false
            )
        end
    elseif variant == "Towers" then
        for side = -1, 1, 2 do
            local pos = base.Position + Vector3.new(side * (hx + 52), 36, -hz - 50)
            local spine = makePart(
                side < 0 and "CinemaTowerMegaspineL" or "CinemaTowerMegaspineR",
                Vector3.new(9, 92, 9),
                CFrame.new(pos),
                VisualTheme.World.Deep:Lerp(theme.Structure, 0.56),
                Enum.Material.CorrodedMetal,
                phaseTransparency(0.14),
                tier.Name == "High"
            )
            makePart(
                side < 0 and "CinemaTowerRailL" or "CinemaTowerRailR",
                Vector3.new(0.7, 66, 9.4),
                spine.CFrame * CFrame.new(0, 5, 0),
                side < 0 and theme.Accent or theme.Secondary,
                Enum.Material.Neon,
                phaseTransparency(0.50),
                false
            )
        end
    elseif variant == "Crossroads" then
        local gates = {
            {offset = Vector3.new(0, 28, -hz - 72), size = Vector3.new(62, 4, 6)},
            {offset = Vector3.new(0, 28, hz + 72), size = Vector3.new(62, 4, 6)},
            {offset = Vector3.new(-hx - 72, 28, 0), size = Vector3.new(6, 4, 62)},
            {offset = Vector3.new(hx + 72, 28, 0), size = Vector3.new(6, 4, 62)},
        }
        for i, def in ipairs(gates) do
            local gate = makePart(
                "CinemaCrossroadsGate" .. i,
                def.size,
                CFrame.new(base.Position + def.offset),
                VisualTheme.World.Metal,
                Enum.Material.Metal,
                phaseTransparency(0.20),
                tier.Name == "High"
            )
            local signSize = def.size.X > def.size.Z
                and Vector3.new(38, 0.62, 6.4)
                or Vector3.new(6.4, 0.62, 38)
            makePart(
                "CinemaCrossroadsSignal" .. i,
                signSize,
                gate.CFrame * CFrame.new(0, 3.0, 0),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                phaseTransparency(0.40),
                false
            )
        end
    elseif variant == "Orbital" then
        local segments = tier.Name == "High" and 14 or 10
        local radius = math.max(hx, hz) + 78
        for i = 1, segments do
            local angle = ((i - 1) / segments) * math.pi * 2
            local tangent = angle + math.pi * 0.5
            local pos = base.Position + Vector3.new(
                math.cos(angle) * radius,
                34 + math.sin(angle * 2) * 5,
                math.sin(angle) * radius
            )
            makePart(
                "CinemaOrbitalHalo" .. i,
                Vector3.new(34, 1.5, 3.6),
                CFrame.new(pos) * CFrame.Angles(0, -tangent, math.rad(math.sin(angle) * 7)),
                i % 3 == 0 and theme.Secondary or theme.Accent,
                i % 2 == 0 and Enum.Material.Neon or Enum.Material.Metal,
                phaseTransparency(i % 2 == 0 and 0.48 or 0.22),
                false
            )
        end
    end
end

local function addAtmosphericBeacons(base, variant, theme, tier)
    if tier.Name == "Low" then
        return
    end

    local count = tier.Name == "High" and 6 or 4
    local radius = variant == "Orbital" and 100 or 94
    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2 + math.rad(22)
        local pos = base.Position + Vector3.new(math.cos(angle) * radius, 24, math.sin(angle) * radius)
        local beam = makePart(
            "CinemaBeacon" .. i,
            Vector3.new(0.34, tier.Name == "High" and 42 or 30, 0.34),
            CFrame.new(pos),
            i % 2 == 0 and theme.Secondary or theme.Accent,
            Enum.Material.Neon,
            phaseTransparency(tier.Name == "High" and 0.78 or 0.84),
            false
        )

        local light = Instance.new("PointLight")
        light.Name = "CinemaBeaconLight"
        light.Color = beam.Color
        light.Brightness = tier.Name == "High" and 0.42 or 0.24
        light.Range = tier.Name == "High" and 17 or 12
        light.Shadows = false
        light.Parent = beam
    end
end

local function addSkyTraffic(base, variant, theme, tier, token)
    if tier.Name == "Low" or player:GetAttribute("ReduceMotion") == true then
        return
    end

    local craftCount = tier.Name == "High" and 4 or 2
    local radius = variant == "Orbital" and 118 or 110

    for i = 1, craftCount do
        local startAngle = ((i - 1) / craftCount) * math.pi * 2
        local y = 28 + ((i * 7) % 18)
        local startPos = base.Position + Vector3.new(
            math.cos(startAngle) * radius,
            y,
            math.sin(startAngle) * radius
        )
        local endAngle = startAngle + math.rad(76 + i * 9)
        local endPos = base.Position + Vector3.new(
            math.cos(endAngle) * radius,
            y + ((i % 2 == 0) and 5 or -3),
            math.sin(endAngle) * radius
        )

        local craft = makePart(
            "CinemaTraffic" .. i,
            Vector3.new(5.6, 0.26, 0.46),
            CFrame.lookAt(startPos, endPos),
            i % 2 == 0 and theme.Secondary or theme.Accent,
            Enum.Material.Neon,
            phaseTransparency(0.36),
            false
        )

        local duration = 7.0 + i * 1.25
        task.spawn(function()
            local from = startPos
            local to = endPos

            while token == motionToken and craft.Parent do
                craft.CFrame = CFrame.lookAt(from, to)
                local tween = TweenService:Create(
                    craft,
                    TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                    {Position = to}
                )
                tween:Play()
                tween.Completed:Wait()

                if token ~= motionToken or not craft.Parent then
                    break
                end

                from, to = to, from
            end
        end)
    end
end

local function refreshAccent(theme)
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("BasePart") then
            local index = tonumber(child:GetAttribute("BaseAccentIndex"))
            if index then
                child.Color = currentAccent or (index % 2 == 0 and theme.Secondary or theme.Accent)
            end
        end
    end
end

local function rebuild()
    clear()

    local _, base, variant, theme = arenaContext()
    if not base then
        return
    end

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local token = motionToken

    addHorizonArchitecture(base, variant, theme, tier)
    addHeroSilhouette(base, variant, theme, tier)
    addAtmosphericBeacons(base, variant, theme, tier)
    addSkyTraffic(base, variant, theme, tier, token)
    refreshAccent(theme)
end

local function bindMap()
    if mapConnection then
        mapConnection:Disconnect()
        mapConnection = nil
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    if generated then
        mapConnection = generated.ChildAdded:Connect(function(child)
            if child.Name == "Arena" then
                task.delay(0.08, rebuild)
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

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(rebuild)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(rebuild)

stateEvent.OnClientEvent:Connect(function(state)
    local previousPhase = currentPhase
    currentPhase = tostring(state.phase or "waiting")

    local ids = state.disasterIds or {}
    if ids[1] then
        local shared = ReplicatedStorage:FindFirstChild("Shared")
        local disasterModule = shared and shared:FindFirstChild("DisasterVisuals")
        if disasterModule then
            local DisasterVisuals = require(disasterModule)
            local profile = DisasterVisuals.combine(ids)
            currentAccent = profile and profile.Accent or nil
        else
            currentAccent = nil
        end
    else
        currentAccent = nil
    end

    local _, _, _, theme = arenaContext()
    if theme then
        refreshAccent(theme)
    end

    if previousPhase ~= currentPhase then
        rebuild()
    end
end)

bindMap()
rebuild()
