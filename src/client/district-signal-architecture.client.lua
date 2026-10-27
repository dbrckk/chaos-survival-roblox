-- Client-authored 3D signal scanner arches for the two live district
-- objectives. Existing server models/prompts remain fully authoritative.
-- 0 new parts on Low; max 36 Medium / 80 High decorative parts per arena.
-- No per-frame updates, server replication, new audio or blocking geometry.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "DistrictSignalArchitectureLocal"
folder.Parent = workspace

local connections = {}
local watchedSignals = nil
local stations = {}
local rebuildQueued = false

local function disconnectAll()
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)
end

local function clear()
    disconnectAll()
    table.clear(stations)
    watchedSignals = nil
    folder:ClearAllChildren()
end

local function quality()
    local current = player:GetAttribute("VfxQualityTier")
    if current == "High" or current == "Medium" then
        return current
    end
    return "Low"
end

local function part(parent, name, size, frame, color, material, alpha)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = frame
    p.Color = color
    p.Material = material or Enum.Material.Metal
    p.Transparency = alpha or 0
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = parent
    return p
end

local function beam(parent, name, a, b, width, tone, material, transparency)
    local delta = b - a
    if delta.Magnitude < 0.01 then return nil end
    local middle = (a + b) * 0.5
    return part(parent, name, Vector3.new(width, delta.Magnitude, width),
        CFrame.lookAt(middle, b) * CFrame.Angles(math.pi * 0.5, 0, 0),
        tone, material, transparency)
end

local function liveStyle(entry)
    if not entry.model.Parent then return end
    local folderOwner = watchedSignals
    local route = entry.route
    local active = entry.model:GetAttribute("SignalActive") == true
    local upcoming = folderOwner
        and tonumber(folderOwner:GetAttribute("UpcomingSignalRoute")) == route
    local claimed = entry.model:GetAttribute("SignalClaimed") == true
    local alpha = active and 0.16 or (upcoming and 0.48 or 0.90)
    local beamAlpha = active and 0.06 or (upcoming and 0.45 or 0.74)
    if claimed then
        alpha = 0.96
        beamAlpha = 0.90
    end
    for _, ring in ipairs(entry.rings) do
        if ring.Parent then ring.Transparency = alpha end
    end
    if entry.beacon and entry.beacon.Parent then
        entry.beacon.Transparency = beamAlpha
    end
end

local function addStation(model, theme, tier)
    if not model:IsA("Model")
        or model:GetAttribute("DistrictSignalStation") ~= true
        or stations[model] then
        return
    end
    local route = tonumber(model:GetAttribute("SignalRoute"))
    if not route or route < 1 or route > 4 then return end
    local core = model:FindFirstChild("PulseCore")
    if not core or not core:IsA("BasePart") then return end

    local stage = Instance.new("Folder")
    stage.Name = "ScannerArch" .. route
    stage.Parent = folder
    local origin = core.Position
    local frame = CFrame.new(origin)
    local dark = theme.Structure:Lerp(Color3.fromRGB(18, 24, 37), 0.32)
    local metal = theme.Detail:Lerp(theme.Structure, 0.25)
    local accent = route % 2 == 0 and theme.Secondary or theme.Accent
    local high = tier == "High"
    local rings = {}
    local segments = high and 8 or 4
    local radius = 5.5

    -- A vertical modular tracking arch: visible against the world
    -- skyline, not a flat decal that disappears when seen edge-on.
    for index = 1, segments do
        local a = (index - 1) * 2 * math.pi / segments
        local b = index * 2 * math.pi / segments
        local startPoint = origin + Vector3.new(
            math.cos(a) * radius, math.sin(a) * radius, 0)
        local endPoint = origin + Vector3.new(
            math.cos(b) * radius, math.sin(b) * radius, 0)
        local ring = beam(stage, "ScanningArc" .. index,
            startPoint, endPoint, high and 0.56 or 0.70,
            accent, Enum.Material.Neon, 0.90)
        rings[#rings + 1] = ring
    end

    local supports = high and 3 or 2
    for index = 1, supports do
        local sign = index == 1 and -1 or 1
        local x = sign * (radius + 1.25)
        part(stage, "AnchorPylon" .. index,
            Vector3.new(1.25, 7.8, 1.5),
            frame * CFrame.new(x, -4.5, 0),
            dark, Enum.Material.Metal, 0.20)
        part(stage, "PylonHighlight" .. index,
            Vector3.new(0.22, 5.4, 1.58),
            frame * CFrame.new(x + sign * 0.72, -4.15, 0),
            metal, Enum.Material.DiamondPlate, 0.24)
        if high then
            beam(stage, "PylonBrace" .. index,
                origin + Vector3.new(x, -7.5, 0),
                origin + Vector3.new(sign * 3.5, -2.4, 0),
                0.50, metal, Enum.Material.Metal, 0.18)
        end
    end
    if high then
        -- Upper crosshead and lens lend station silhouettes distinct
        -- large-scale mass without altering their collision or prompts.
        part(stage, "TrackingCrosshead",
            Vector3.new(11, 0.85, 1.7),
            frame * CFrame.new(0, 6.45, 0),
            metal, Enum.Material.Metal, 0.16)
        local window = part(stage, "TrackingLens",
            Vector3.new(2.2, 2.2, 2.2),
            frame * CFrame.new(0, 7.2, 0),
            accent, Enum.Material.Glass, 0.32)
        window.Shape = Enum.PartType.Ball
    end

    local beacon = part(stage, "LiveScanBeam",
        Vector3.new(0.42, 9, 0.42),
        frame * CFrame.new(0, 4.9, 0),
        accent, Enum.Material.Neon, 0.82)

    local entry = {model = model, rings = rings, beacon = beacon,
        owner = stage, route = route}
    stations[model] = entry
    connections[#connections + 1] = model:GetAttributeChangedSignal(
        "SignalActive"):Connect(function()
        liveStyle(entry)
    end)
    connections[#connections + 1] = model:GetAttributeChangedSignal(
        "SignalClaimed"):Connect(function()
        liveStyle(entry)
    end)
    liveStyle(entry)
end

local function rebuild()
    clear()
    local tier = quality()
    if tier == "Low" then return end

    local map = workspace:FindFirstChild("GeneratedMap")
    local arena = map and map:FindFirstChild("Arena")
    local folderOwner = arena and arena:FindFirstChild("DistrictSignalRush")
    if not folderOwner or not folderOwner:IsA("Folder") then return end
    watchedSignals = folderOwner
    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local theme = VisualTheme.arena(variant)

    local function register(model)
        addStation(model, theme, tier)
        -- Atomic streamed models can be delivered before PulseCore;
        -- detect its actual arrival rather than relying on fixed delays.
        if model:IsA("Model")
            and model:GetAttribute("DistrictSignalStation") == true
            and not stations[model] then
            connections[#connections + 1] = model.ChildAdded:Connect(function(c)
                if c.Name == "PulseCore" then
                    addStation(model, theme, tier)
                end
            end)
        end
    end
    for _, model in ipairs(folderOwner:GetChildren()) do register(model) end
    connections[#connections + 1] = folderOwner.ChildAdded:Connect(register)
    connections[#connections + 1] = folderOwner.ChildRemoved:Connect(
        function(model)
            local entry = stations[model]
            if entry then
                stations[model] = nil
                if entry.owner.Parent then entry.owner:Destroy() end
            end
        end)
    connections[#connections + 1] =
        folderOwner:GetAttributeChangedSignal("UpcomingSignalRoute"):Connect(
            function()
                for _, entry in pairs(stations) do liveStyle(entry) end
            end)
end

local function scheduleRebuild()
    if rebuildQueued then return end
    rebuildQueued = true
    task.defer(function()
        rebuildQueued = false
        rebuild()
    end)
end

workspace.DescendantAdded:Connect(function(child)
    if child.Name == "DistrictSignalRush" and child:IsA("Folder") then
        scheduleRebuild()
    end
end)
workspace.DescendantRemoving:Connect(function(child)
    if child == watchedSignals then
        clear()
    end
end)
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(scheduleRebuild)
scheduleRebuild()
