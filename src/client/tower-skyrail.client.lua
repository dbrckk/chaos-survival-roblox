-- Tower Run / Skyrail Conductor.
-- A small original industrial skyline signal kit floating above permanent
-- bridges. The server owns every collision deck. This client layer creates
-- local visuals only: no touching, querying, shadow casting or server loops.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local player = Players.LocalPlayer

local art = Instance.new("Folder")
art.Name = "TowerSkyrailLocal"
art.Parent = workspace

local currentPlatforms = nil
local currentTier = nil
local currentReduced = nil
local bridges = {}
local canopy = {}
local signalConnections = {}
local activeSurges = {}

local colors = {
    Armor = Color3.fromRGB(28, 42, 63),
    Spine = Color3.fromRGB(78, 107, 132),
    Cyan = Color3.fromRGB(90, 229, 250),
    Gold = Color3.fromRGB(255, 203, 122),
}

local function findPlatforms()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    if not arena or arena:GetAttribute("VariantId") ~= "Towers" then
        return nil
    end
    return arena:FindFirstChild("Platforms")
end

local function readBridges(platforms)
    local result = {}
    if platforms then
        for _, part in ipairs(platforms:GetChildren()) do
            if part:IsA("BasePart")
                and part:GetAttribute("ChaosSkybridge") == true
            then
                table.insert(result, part)
            end
        end
    end
    table.sort(result, function(a, b)
        return a.Name < b.Name
    end)
    return result
end

local function createPart(parts, name, size, bridge, localCf, color, material, opacity)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = bridge.CFrame * localCf
    p.Color = color
    p.Material = material
    p.Transparency = opacity
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = art
    table.insert(parts, {Part = p, LocalCf = localCf})
    return p
end

local function routeTransform(alongX, longitudinal, up, lateral)
    -- Bridge X is the longitudinal axis on north/south links; bridge Z
    -- becomes longitudinal on east/west links, keeping the same silhouette.
    return CFrame.new(
        alongX and longitudinal or lateral,
        up,
        alongX and lateral or longitudinal
    )
end

local function buildCanopy(bridge, tier, reduced)
    local alongX = bridge.Size.X > bridge.Size.Z
    local parts = {}
    local animate = {}
    local n = #canopy + 1

    if tier == "Low" then
        for side = -1, 1, 2 do
            createPart(parts, "SkyrailGroundMarker" .. n,
                Vector3.new(0.62, 0.10, 0.40),
                bridge, routeTransform(alongX, 0, bridge.Size.Y * 0.5 + 0.09,
                    side * (math.min(bridge.Size.X, bridge.Size.Z) * 0.5 - 0.3)),
                colors.Cyan, Enum.Material.Metal, 0.47)
        end
    else
        -- Two cantilever supports never project into the 4.5-stud central
        -- walkway. Crossbeam hangs high above the avatars' jump envelope.
        local deck = bridge.Size.Y * 0.5
        local sideways = math.min(bridge.Size.X, bridge.Size.Z) * 0.5 + 0.35
        for side = -1, 1, 2 do
            createPart(parts, "SkyrailPillar" .. n,
                Vector3.new(0.58, 4.5, 0.72),
                bridge, routeTransform(alongX, 0, deck + 2.45, side * sideways),
                colors.Armor, Enum.Material.DiamondPlate, 0.04)

            createPart(parts, "SkyrailInsetFiber" .. n,
                Vector3.new(0.14, 3.65, 0.13),
                bridge, routeTransform(alongX, 0, deck + 2.52,
                    side * (sideways - 0.22)),
                side < 0 and colors.Cyan or colors.Gold,
                Enum.Material.Neon, 0.20)

            if tier == "High" then
                createPart(parts, "SkyrailCounterweight" .. n,
                    Vector3.new(1.10, 0.28, 1.03),
                    bridge, routeTransform(alongX, 0, deck + 4.45,
                        side * sideways),
                    colors.Spine, Enum.Material.Metal, 0.12)
            end
        end

        createPart(parts, "SkyrailHeader" .. n,
            alongX and Vector3.new(0.88, 0.62, sideways * 2 + 0.6)
                or Vector3.new(sideways * 2 + 0.6, 0.62, 0.88),
            bridge, routeTransform(alongX, 0, deck + 4.89, 0),
            colors.Armor, Enum.Material.Metal, 0.04)
        createPart(parts, "SkyrailCrownBeam" .. n,
            alongX and Vector3.new(0.28, 0.15, sideways * 1.5)
                or Vector3.new(sideways * 1.5, 0.15, 0.28),
            bridge, routeTransform(alongX, 0, deck + 5.26, 0),
            colors.Cyan, Enum.Material.Neon, 0.23)

        if tier == "High" then
            -- Two asymmetric upper wing fins echo an aerospace rail signal.
            for side = -1, 1, 2 do
                createPart(parts, "SkyrailSignalWing" .. n,
                    alongX and Vector3.new(1.9, 0.20, 0.47)
                        or Vector3.new(0.47, 0.20, 1.9),
                    bridge, routeTransform(alongX, side * 0.45,
                        deck + 5.18, side * 1.2),
                    side < 0 and colors.Cyan or colors.Gold,
                    Enum.Material.Neon, 0.24)
            end
        end

        if not reduced then
            for index = 1, tier == "High" and 2 or 1 do
                local runner = createPart(parts, "SkyrailPulseCourier" .. n,
                    Vector3.new(0.65, 0.10, 0.35),
                    bridge, routeTransform(alongX, 0, deck + 5.50, 0),
                    index == 1 and colors.Cyan or colors.Gold,
                    Enum.Material.Neon, 0.25)
                table.insert(animate, {
                    Part = runner,
                    Offset = (index - 1) * 0.5,
                })
            end
        end
    end

    return {Bridge = bridge, Parts = parts, Runners = animate, AlongX = alongX}
end

-- One-shot courier flare. It uses existing bridge transforms, with
-- a bounded local part count and no per-frame server replication.
local function surgeBurst(bridge, tier, reduced)
    if reduced or tier == "Low" or not bridge or not bridge.Parent then
        return
    end
    local camera = workspace.CurrentCamera
    if camera and (camera.CFrame.Position - bridge.Position).Magnitude > 120 then
        return
    end
    local alongX = bridge.Size.X > bridge.Size.Z
    local axis = alongX and bridge.CFrame.RightVector or bridge.CFrame.LookVector
    local travelSign = bridge:GetAttribute("SkyrailRunDirection") == -1 and -1 or 1
    local direction = axis * travelSign
    local rank = math.clamp(tonumber(bridge:GetAttribute("SkyrailFlowTier")) or 1, 1, 3)
    local pieces = tier == "High" and (rank == 3 and 10 or 8)
        or (rank == 3 and 6 or 4)
    local top = bridge.Size.Y * 0.5 + 0.13
    for index = 1, pieces do
        local side = (index % 2 == 0) and 1 or -1
        local offset = (index - (pieces + 1) * 0.5) / pieces
        local start = bridge.CFrame * CFrame.new(
            alongX and offset * 3 or side * 1.4,
            top,
            alongX and side * 1.4 or offset * 3
        )
        local p = Instance.new("Part")
        p.Name = "SkyrailImpulseFacet"
        p.Size = Vector3.new(0.19, 0.09, 0.65)
        p.CFrame = CFrame.lookAt(start.Position, start.Position + direction)
        p.Material = Enum.Material.Neon
        p.Color = rank == 3 and (side == 1 and colors.Gold or colors.Cyan)
            or (side == 1 and colors.Cyan or colors.Gold)
        p.Transparency = 0.18
        p.Anchored = true
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.CastShadow = false
        p.Parent = art
        local finish = start.Position + direction * 5.4
        TweenService:Create(p,
            TweenInfo.new(0.40, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
            {CFrame = CFrame.lookAt(finish, finish + direction),
                Size = Vector3.new(0.10, 0.055, 1.35),
                Transparency = 1}
        ):Play()
        Debris:AddItem(p, 0.48)
    end

    if rank >= 2 then
        -- Spectator-readable but short-lived world cue, without HUD clutter.
        local display = Instance.new("BillboardGui")
        display.Name = "SkyrailMasteryFlash"
        display.Adornee = bridge
        display.Size = UDim2.fromOffset(178, 36)
        display.StudsOffsetWorldSpace = Vector3.new(0, 6.6, 0)
        display.AlwaysOnTop = false
        display.MaxDistance = 78
        display.Parent = art
        local label = Instance.new("TextLabel")
        label.Name = "SkyrailMasteryTitle"
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundColor3 = Color3.fromRGB(13, 28, 43)
        label.BackgroundTransparency = 0.18
        label.BorderSizePixel = 0
        label.Font = Enum.Font.GothamBlack
        label.TextScaled = true
        label.TextColor3 = rank == 3 and colors.Gold or colors.Cyan
        label.Text = rank == 3 and "SKYRAIL ACE ×3" or "SKYRAIL CHAIN ×2"
        label.Parent = display
        local rounded = Instance.new("UICorner")
        rounded.CornerRadius = UDim.new(0, 7)
        rounded.Parent = label
        Debris:AddItem(display, 1.1)
    end
end

local function rebuild(platforms, tier, reduced, ordered)
    for _, connection in ipairs(signalConnections) do
        connection:Disconnect()
    end
    table.clear(signalConnections)
    table.clear(activeSurges)
    art:ClearAllChildren()
    table.clear(canopy)
    currentPlatforms = platforms
    currentTier = tier
    currentReduced = reduced
    bridges = ordered
    for _, bridge in ipairs(bridges) do
        table.insert(canopy, buildCanopy(bridge, tier, reduced))
        table.insert(signalConnections, bridge:GetAttributeChangedSignal(
            "SkyrailUsedAt"
        ):Connect(function()
            if bridge.Parent == currentPlatforms then
                activeSurges[bridge] = os.clock() + 0.8
                surgeBurst(bridge, tier, reduced)
            end
        end))
    end
end

local function draw(timestamp)
    for _, structure in ipairs(canopy) do
        local bridge = structure.Bridge
        if bridge.Parent then
            local surging = (activeSurges[bridge] or 0) > timestamp
            for _, item in ipairs(structure.Parts) do
                if item.Part.Parent then
                    item.Part.CFrame = bridge.CFrame * item.LocalCf
                    if item.Part.Name:find("SkyrailInsetFiber") or
                        item.Part.Name:find("SkyrailCrownBeam")
                    then
                        item.Part.Transparency = surging and 0.03 or 0.23
                    end
                end
            end

            for _, runner in ipairs(structure.Runners) do
                local progress = (timestamp * 0.27 + runner.Offset) % 1
                local span = math.max(2, math.max(bridge.Size.X, bridge.Size.Z) - 5)
                local distance = (progress - 0.5) * span * 0.77
                local cf = routeTransform(structure.AlongX, distance,
                    bridge.Size.Y * 0.5 + 5.50, 0)
                runner.Part.CFrame = bridge.CFrame * cf
                runner.Part.Transparency = 0.34 + 0.28
                    * math.abs(2 * progress - 1)
            end
        end
    end
end

task.spawn(function()
    while art.Parent do
        local platforms = findPlatforms()
        local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
        local reduced = player:GetAttribute("ReduceMotion") == true
        local ordered = readBridges(platforms)
        local changed = platforms ~= currentPlatforms or tier ~= currentTier
            or reduced ~= currentReduced or #ordered ~= #bridges
        if not changed then
            for index, bridge in ipairs(ordered) do
                if bridge ~= bridges[index] then
                    changed = true
                    break
                end
            end
        end
        if changed then rebuild(platforms, tier, reduced, ordered) end
        if #canopy > 0 then
            draw(os.clock())
            task.wait(reduced and 0.35
                or (tier == "High" and 0.10
                    or (tier == "Medium" and 0.22 or 0.65)))
        else
            task.wait(0.75)
        end
    end
end)
