-- Orbital Helix / directional luminous runners on all eight ramps.
-- Completely cosmetic: no server loop, no interactive collisions, no lights.
-- Streaming-safe and 0 parts on Low/ReduceMotion hardware.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "OrbitalHelixLocal"
folder.Parent = workspace

local currentCircuit = nil
local currentTier = nil
local currentReduced = nil
local runners = {}
local orderedRamps = {}
local flowFolder = nil
local flowConnections = {}

local function resolveCircuit()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    return arena and arena:FindFirstChild("HelixCircuit")
end

local function readRamps(circuit)
    if not circuit then return {} end
    local ramps = {}
    for _, part in ipairs(circuit:GetChildren()) do
        if part:IsA("BasePart") and part:GetAttribute("OrbitalHelixRamp") == true then
            table.insert(ramps, part)
        end
    end
    table.sort(ramps, function(a, b)
        return (a:GetAttribute("HelixLane") or 0)
            < (b:GetAttribute("HelixLane") or 0)
    end)
    return ramps
end

local function flowBurst(sensor)
    if not sensor or not sensor.Parent or player:GetAttribute("ReduceMotion") == true then
        return
    end
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
    if tier == "Low" then return end
    local camera = workspace.CurrentCamera
    if camera and (sensor.Position - camera.CFrame.Position).Magnitude > 100 then
        return
    end

    local mastery = math.clamp(tonumber(sensor:GetAttribute("HelixFlowTier")) or 1, 1, 3)
    local count = tier == "High" and (mastery == 3 and 12 or 8)
        or (mastery == 3 and 7 or 5)
    local origin = sensor.Position - Vector3.new(0, 1.6, 0)
    for index = 1, count do
        local angle = (index - 1) * math.pi * 2 / count
        local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local tangent = Vector3.new(-radial.Z, 0, radial.X)
        local inner = origin + radial * 1.5
        local outer = origin + radial * 3.5
        local piece = Instance.new("Part")
        piece.Name = "HelixFlowCelebrationFacet"
        piece.Size = Vector3.new(0.13, 0.075, 1.1)
        piece.CFrame = CFrame.lookAt(inner, inner + tangent)
        piece.Color = mastery == 3
            and (index % 2 == 0 and Color3.fromRGB(255, 210, 112)
                or Color3.fromRGB(166, 252, 230))
            or (index % 2 == 0 and Color3.fromRGB(115, 255, 187)
                or Color3.fromRGB(77, 201, 252))
        piece.Material = Enum.Material.Neon
        piece.Transparency = 0.24
        piece.Anchored = true
        piece.CanCollide = false
        piece.CanTouch = false
        piece.CanQuery = false
        piece.CastShadow = false
        piece.Parent = folder
        TweenService:Create(piece,
            TweenInfo.new(0.42, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
            {
                CFrame = CFrame.lookAt(outer, outer + tangent),
                Size = Vector3.new(0.10, 0.06, 1.65),
                Transparency = 1,
            }
        ):Play()
        Debris:AddItem(piece, 0.52)
    end

    if mastery >= 2 then
        -- Tiny 3D-world celebration, not a HUD obstruction; spectators can
        -- recognize the skill chain even if they aren't the scoring player.
        local banner = Instance.new("BillboardGui")
        banner.Name = "HelixMasteryBanner"
        banner.Adornee = sensor
        banner.StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0)
        banner.Size = UDim2.fromOffset(175, 34)
        banner.MaxDistance = 75
        banner.AlwaysOnTop = false
        banner.Parent = folder

        local title = Instance.new("TextLabel")
        title.Name = "MasteryTitle"
        title.Size = UDim2.fromScale(1, 1)
        title.BackgroundColor3 = Color3.fromRGB(11, 24, 36)
        title.BackgroundTransparency = 0.18
        title.BorderSizePixel = 0
        title.Font = Enum.Font.GothamBlack
        title.TextScaled = true
        title.TextColor3 = mastery == 3 and Color3.fromRGB(255, 225, 133)
            or Color3.fromRGB(154, 255, 213)
        title.Text = mastery == 3 and "ORBIT MASTER ×3" or "HELIX CHAIN ×2"
        title.Parent = banner
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = title
        Debris:AddItem(banner, 1.15)
    end
end

local function bindFlowCircuit()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local mechanics = arena and arena:FindFirstChild("Mechanics")
    local current = mechanics and mechanics:FindFirstChild("HelixFlow")
    if flowFolder == current then return end
    for _, connection in ipairs(flowConnections) do
        connection:Disconnect()
    end
    table.clear(flowConnections)
    flowFolder = current
    if current then
        local observedSensors = {}
        local function observeSensor(sensor)
            if not sensor:IsA("BasePart") or observedSensors[sensor] then
                return
            end
            observedSensors[sensor] = true
            table.insert(flowConnections, sensor:GetAttributeChangedSignal(
                "HelixFlowAt"
            ):Connect(function()
                if sensor.Parent == flowFolder then
                    flowBurst(sensor)
                end
            end))
        end
        -- An arena folder may replicate before its eight child sensors.
        -- Subscribe to late additions as well as sensors already present.
        table.insert(flowConnections, current.ChildAdded:Connect(observeSensor))
        for _, sensor in ipairs(current:GetChildren()) do
            observeSensor(sensor)
        end
    end
end

local function reset()
    folder:ClearAllChildren()
    table.clear(runners)
    table.clear(orderedRamps)
end

local function createRunner(ramp, index, lane, tier)
    local part = Instance.new("Part")
    part.Name = "HelixMotionGlyph"
    part.Size = tier == "High"
        and Vector3.new(1.05, 0.075, 0.27)
        or Vector3.new(0.72, 0.07, 0.24)
    part.Material = Enum.Material.Neon
    part.Color = lane % 2 == 0
        and Color3.fromRGB(121, 253, 209)
        or Color3.fromRGB(95, 201, 255)
    part.Transparency = tier == "High" and 0.24 or 0.40
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Parent = folder
    table.insert(runners, {
        Part = part, Ramp = ramp, Lane = lane,
        Index = index, Count = tier == "High" and 3 or 1,
    })
end

local function rebuild(circuit, tier, reduced, ramps)
    reset()
    currentCircuit = circuit
    currentTier = tier
    currentReduced = reduced
    orderedRamps = ramps
    -- Still track the actual eight ramp identities on Low/reduced motion.
    -- Otherwise the controller rebuilds empty visual arrays every poll.
    if reduced or tier == "Low" then return end
    for index, ramp in ipairs(ramps) do
        local n = tier == "High" and 3 or 1
        for lane = 1, n do
            createRunner(ramp, index, lane, tier)
        end
    end
end

local function draw(time)
    for _, runner in ipairs(runners) do
        local ramp = runner.Ramp
        if ramp and ramp.Parent then
            local count = runner.Count
            local t = (time * 0.44 + ((runner.Lane - 1) / count)
                + runner.Index * 0.037) % 1
            -- Local -Z is the inner-ring direction of each inclined ramp.
            local z = (0.5 - t) * (ramp.Size.Z - 1.8)
            local x = count == 1 and 0
                or (runner.Lane - 2) * (ramp.Size.X * 0.26)
            runner.Part.CFrame = ramp.CFrame * CFrame.new(
                x, ramp.Size.Y * 0.5 + 0.13, z
            )
        end
    end
end

task.spawn(function()
    while folder.Parent do
        local circuit = resolveCircuit()
        local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
        local reduced = player:GetAttribute("ReduceMotion") == true
        local ramps = readRamps(circuit)
        local stale = circuit ~= currentCircuit or tier ~= currentTier
            or reduced ~= currentReduced or #ramps ~= #orderedRamps
        if not stale then
            for index, ramp in ipairs(ramps) do
                if ramp ~= orderedRamps[index] then
                    -- Handle StreamingEnabled replacing ramp instances while
                    -- the parent HelixCircuit folder remains unchanged.
                    stale = true
                    break
                end
            end
        end
        if stale then
            rebuild(circuit, tier, reduced, ramps)
        end
        bindFlowCircuit()

        if #runners > 0 then
            draw(os.clock())
            -- At most 24 client-only glowing glyphs; 8 on Medium.
            task.wait(tier == "High" and 0.075 or 0.14)
        else
            -- Zero GPU parts and minimal CPU usage outside Orbital,
            -- on Low tier, or with reduced motion enabled.
            task.wait(0.60)
        end
    end
end)
