-- CLASSIC GRID / CLOCKWORK CIRCUIT
-- Four authored waypoint sculptures. Only server sensors award a clear;
-- cosmetics are local, tier-scaled, noncolliding and streaming-aware.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local GridCircuitRules = require(ReplicatedStorage.Shared.GridCircuitRules)

local player = Players.LocalPlayer
local french = string.sub(string.lower(LocalizationService.RobloxLocaleId), 1, 2) == "fr"

local palette = {
    Metal = Color3.fromRGB(27, 38, 60),
    Edge = Color3.fromRGB(91, 117, 151),
    Standby = Color3.fromRGB(73, 174, 255),
    Active = Color3.fromRGB(255, 214, 103),
    Complete = Color3.fromRGB(123, 246, 192),
}

local art = Instance.new("Folder")
art.Name = "GridCircuitLocal"
art.Parent = workspace

local nodes = {}
local guides = {}
local guidesBuilt = false
local connections = {}
local currentFolder = nil
local tierName = nil
local reducedMotion = nil
local lastStyleKey = ""

local gui = Instance.new("ScreenGui")
gui.Name = "GridCircuitProgress"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 34
gui.Parent = player:WaitForChild("PlayerGui")

local banner = Instance.new("TextLabel")
banner.Name = "CircuitStatus"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.fromScale(0.5, 0.125)
banner.Size = UDim2.fromOffset(235, 31)
banner.BackgroundColor3 = Color3.fromRGB(13, 23, 40)
banner.BackgroundTransparency = 0.24
banner.BorderSizePixel = 0
banner.Font = Enum.Font.GothamBold
banner.TextColor3 = Color3.fromRGB(221, 236, 255)
banner.TextScaled = true
banner.Text = ""
banner.Visible = false
banner.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = banner
local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Color = palette.Edge
stroke.Transparency = 0.22
stroke.Parent = banner

-- A static four-segment mastery tracker that remains readable on touch.
local progressTrack = Instance.new("Frame")
progressTrack.Name = "CircuitProgressTrack"
progressTrack.Size = UDim2.new(1, 0, 0, 5)
progressTrack.Position = UDim2.new(0, 0, 1, 4)
progressTrack.BackgroundTransparency = 1
progressTrack.Visible = false
progressTrack.Parent = banner
local progressPips = {}
for index = 1, 4 do
    local pip = Instance.new("Frame")
    pip.Name = "CircuitProgress" .. index
    pip.Position = UDim2.new((index - 1) * 0.25, index == 1 and 0 or 2, 0, 0)
    pip.Size = UDim2.new(0.25, index == 1 and -5 or -7, 1, 0)
    pip.BorderSizePixel = 0
    pip.BackgroundColor3 = palette.Edge
    pip.Parent = progressTrack
    local rounded = Instance.new("UICorner")
    rounded.CornerRadius = UDim.new(1, 0)
    rounded.Parent = pip
    progressPips[index] = pip
end

local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local activeRound = false
stateEvent.OnClientEvent:Connect(function(data)
    activeRound = type(data) == "table" and data.phase == "round"
end)

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
end

local function makePart(name, size, cf, tint, material, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = tint
    p.Material = material
    p.Transparency = transparency or 0
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = art
    return p
end

local function clear()
    for _, c in ipairs(connections) do c:Disconnect() end
    table.clear(connections)
    table.clear(nodes)
    table.clear(guides)
    guidesBuilt = false
    art:ClearAllChildren()
    lastStyleKey = ""
end

local function cue(sensor, node)
    if player:GetAttribute("ReduceMotion") == true or quality() == "Low" then
        return
    end
    local camera = workspace.CurrentCamera
    if camera and (sensor.Position - camera.CFrame.Position).Magnitude > 95 then
        return
    end
    local high = quality() == "High"
    local count = high and 8 or 4
    local origin = sensor.Position - Vector3.new(0, 1.7, 0)
    local finish = sensor:GetAttribute("GridCircuitPulseStep") == 4
    local color = finish and palette.Complete or palette.Active
    for index = 1, count do
        local theta = index / count * math.pi * 2
        local outward = Vector3.new(math.cos(theta), 0, math.sin(theta))
        local tangent = Vector3.new(-outward.Z, 0, outward.X)
        local startAt = origin + outward * 1.6
        local endAt = origin + outward * 4.4
        local particle = makePart("CircuitPulseFacet",
            Vector3.new(0.16, 0.08, 0.75),
            CFrame.lookAt(startAt, startAt + tangent),
            color, Enum.Material.Neon, 0.10)
        TweenService:Create(particle,
            TweenInfo.new(0.43, Enum.EasingStyle.Cubic,
                Enum.EasingDirection.Out),
            {CFrame = CFrame.lookAt(endAt, endAt + tangent),
                Size = Vector3.new(0.08, 0.06, 1.25),
                Transparency = 1}
        ):Play()
        Debris:AddItem(particle, 0.53)
    end
end

local function install(sensor)
    local index = sensor:GetAttribute("GridCircuitIndex")
    if not sensor:IsA("BasePart") or type(index) ~= "number"
        or nodes[sensor] then
        return
    end

    local tier = quality()
    local center = sensor.Position - Vector3.new(0, 2.13, 0)
    local base = makePart("GridStationDeck" .. index,
        Vector3.new(6.15, 0.18, 6.15),
        CFrame.new(center), palette.Metal, Enum.Material.Metal, 0.04)

    local signal = {}
    local segments = tier == "High" and 12
        or (tier == "Medium" and 8 or 4)
    for n = 1, segments do
        local phi = n / segments * math.pi * 2
        local radial = Vector3.new(math.cos(phi), 0, math.sin(phi))
        local tangent = Vector3.new(-radial.Z, 0, radial.X)
        local at = center + Vector3.new(0, 0.16, 0) + radial * 2.48
        local segment = makePart("GridStationCircuitRail",
            Vector3.new(0.18, 0.07, (2 * math.pi * 2.48 / segments) * 0.78),
            CFrame.lookAt(at, at + tangent),
            palette.Standby, Enum.Material.Neon, 0.25)
        table.insert(signal, segment)
    end

    if tier ~= "Low" then
        for n = 1, 4 do
            local angle = math.pi * 0.5 * n
            local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
            local pylon = makePart("GridStationSignalPylon",
                Vector3.new(0.48, 2.65, 0.48),
                CFrame.new(center + radial * 2.75 + Vector3.new(0, 1.36, 0)),
                palette.Edge, Enum.Material.Metal, 0.12)
            local filament = makePart("GridStationSignalFilament",
                Vector3.new(0.16, 1.78, 0.16),
                pylon.CFrame * CFrame.new(0, 0.03, -0.25),
                palette.Standby, Enum.Material.Neon, 0.28)
            table.insert(signal, filament)
        end
    end

    if tier == "High" then
        for n = 1, 4 do
            local a = math.pi * 0.5 * n
            local radial = Vector3.new(math.cos(a), 0, math.sin(a))
            local brace = makePart("GridStationServiceCrown",
                Vector3.new(0.75, 0.22, 0.80),
                CFrame.new(center + radial * 2.75 + Vector3.new(0, 2.83, 0)),
                palette.Edge, Enum.Material.DiamondPlate, 0.08)
            brace.Reflectance = 0.1
        end
    end

    local nameplate = Instance.new("BillboardGui")
    nameplate.Name = "GridCircuitNameplate"
    nameplate.Adornee = sensor
    nameplate.Size = UDim2.fromOffset(156, 37)
    nameplate.StudsOffsetWorldSpace = Vector3.new(0, 3.3, 0)
    nameplate.MaxDistance = 65
    nameplate.AlwaysOnTop = false
    nameplate.Parent = art

    local text = Instance.new("TextLabel")
    text.Name = "NodeLabel"
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundColor3 = Color3.fromRGB(14, 26, 46)
    text.BackgroundTransparency = 0.19
    text.BorderSizePixel = 0
    text.Font = Enum.Font.GothamBlack
    text.TextScaled = true
    text.TextColor3 = palette.Standby
    text.Text = "GRID"
    text.Parent = nameplate
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(0, 8)
    round.Parent = text
    local outline = Instance.new("UIStroke")
    outline.Thickness = 1
    outline.Color = palette.Edge
    outline.Parent = text

    nodes[sensor] = {
        index = index,
        base = base,
        signal = signal,
        label = text,
        outline = outline,
    }
    table.insert(connections, sensor:GetAttributeChangedSignal(
        "GridCircuitPulseAt"
    ):Connect(function()
        if nodes[sensor] then cue(sensor, nodes[sensor]) end
    end))
end

local function findCircuit()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local mechanics = arena and arena:FindFirstChild("Mechanics")
    return mechanics and mechanics:FindFirstChild("GridCircuit")
end

-- Connect the four compass stations with shallow noncolliding
-- floor chevrons. Highlight only the player's next clockwise edge.
-- No moving parts/Heartbeat and no route glyphs on Low devices.
local function ensureGuides()
    if guidesBuilt then return end
    local byIndex = {}
    for _, node in pairs(nodes) do
        byIndex[node.index] = node
    end
    if not (byIndex[1] and byIndex[2] and byIndex[3] and byIndex[4]) then
        return
    end
    guidesBuilt = true
    local steps = GridCircuitRules.routeChevrons(quality())
    if steps == 0 then return end

    for index = 1, 4 do
        local nextIndex = GridCircuitRules.next(index)
        local origin = byIndex[index].base.Position
        local destination = byIndex[nextIndex].base.Position
        local direction = destination - origin
        local horizontal = Vector3.new(direction.X, 0, direction.Z).Unit
        for number = 1, steps do
            local center = origin:Lerp(destination, number / (steps + 1))
                + Vector3.new(0, 0.16, 0)
            for side = -1, 1, 2 do
                local glyph = makePart("GridRouteChevron",
                    Vector3.new(0.17, 0.055, 1.1),
                    CFrame.lookAt(center, center + horizontal)
                        * CFrame.Angles(0, math.rad(side * 32), 0),
                    palette.Standby, Enum.Material.Neon, 0.84)
                table.insert(guides, {from = index, part = glyph})
            end
        end
    end
end

local function bindCircuit(circuit)
    clear()
    currentFolder = circuit
    tierName = quality()
    reducedMotion = player:GetAttribute("ReduceMotion") == true
    if not circuit then return end
    for _, child in ipairs(circuit:GetChildren()) do install(child) end
    table.insert(connections, circuit.ChildAdded:Connect(install))
    table.insert(connections, circuit.ChildRemoved:Connect(function(child)
        if nodes[child] then
            -- A node disappearing during streaming invalidates its visual
            -- scaffold; rebuild to avoid an orphaned floating sign.
            bindCircuit(findCircuit())
        end
    end))
end

local function updateLook()
    ensureGuides()
    local stage = tonumber(player:GetAttribute("RoundGridCircuitStep")) or 0
    local destination = tonumber(player:GetAttribute("RoundGridCircuitNext")) or 0
    local complete = player:GetAttribute("RoundGridCircuitComplete") == true
    local participant = player:GetAttribute("RoundParticipant") == true
        and player:GetAttribute("RoundEliminated") ~= true
    -- The independent client controller must never show a Classic-only
    -- challenge while a different arena variant is being played.
    local phase = activeRound and participant and currentFolder ~= nil
    local deadline = tonumber(player:GetAttribute("RoundGridCircuitDeadline")) or 0
    local remain = math.max(0, math.ceil(deadline - workspace:GetServerTimeNow()))
    local key = tostring(stage) .. "/" .. tostring(destination) .. "/"
        .. tostring(complete) .. "/" .. tostring(phase)
        .. "/" .. tostring(remain)
    if key == lastStyleKey then return end
    lastStyleKey = key

    banner.Visible = phase and #GridCircuitRules.Offsets == 4
    progressTrack.Visible = banner.Visible
    local visibleProgress = (stage > 0 and not complete and remain <= 0)
        and 0 or stage
    for index, pip in ipairs(progressPips) do
        pip.BackgroundColor3 = index <= visibleProgress
            and (complete and palette.Complete or palette.Active)
            or palette.Edge
    end
    if phase then
        if complete then
            banner.Text = "GRID CIRCUIT  //  CLEAR"
        elseif stage == 0 then
            banner.Text = french and "CIRCUIT • TOUCHE UNE BORNE"
                or "GRID RUN • TOUCH ANY NODE"
        else
            local direction = GridCircuitRules.Names[destination] or "?"
            if remain == 0 then
                banner.Text = french and "CIRCUIT • RECOMMENCE"
                    or "GRID RUN • RESTART"
            else
                banner.Text = string.format("GRID %d/4  •  %s  •  %ds",
                    stage, direction, remain)
            end
        end
    end

    for sensor, node in pairs(nodes) do
        local chosen = phase and not complete
            and stage > 0 and remain > 0 and destination == node.index
        local success = phase and complete
        local color = success and palette.Complete
            or (chosen and palette.Active or palette.Standby)
        local dim = not phase or (stage > 0 and not chosen and not success)
        node.label.Text = (GridCircuitRules.Names[node.index] or "??")
            .. (chosen and (french and " • SUITE" or " • NEXT")
                or (success and " • CLEAR"
                    or (stage == 0 and (french and " • DÉPART" or " • START")
                        or " • GRID")))
        node.label.TextColor3 = color
        node.outline.Color = color
        node.base.Color = dim and palette.Metal
            or palette.Metal:Lerp(color, 0.22)
        for _, part in ipairs(node.signal) do
            part.Color = color
            part.Transparency = dim and 0.75 or 0.20
        end
    end
    local previous = GridCircuitRules.previous(destination)
    for _, guide in ipairs(guides) do
        local selected = phase and stage > 0 and remain > 0
            and not complete and previous == guide.from
        guide.part.Color = complete and palette.Complete
            or (selected and palette.Active or palette.Standby)
        guide.part.Transparency = selected and 0.22
            or (complete and 0.62 or 0.87)
    end
end

task.spawn(function()
    while art.Parent do
        local circuit = findCircuit()
        local changed = circuit ~= currentFolder
            or tierName ~= quality()
            or reducedMotion ~= (player:GetAttribute("ReduceMotion") == true)
        if not changed and circuit then
            local count = 0
            for sensor in pairs(nodes) do
                if sensor.Parent == circuit then count += 1 end
            end
            if count ~= #circuit:GetChildren() then changed = true end
        end
        if changed then bindCircuit(circuit) end
        updateLook()
        task.wait(circuit and 0.22 or 0.65)
    end
end)
