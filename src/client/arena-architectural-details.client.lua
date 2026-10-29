-- Architectural setpieces live on each client. They never change gameplay,
-- physics, hazards, the server map or another player's performance budget.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)

local player = Players.LocalPlayer
local roundState = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local folder = Instance.new("Folder")
folder.Name = "ArenaArchitecturalDetailsLocal"
folder.Parent = workspace

local animated = {}
local activeBase = nil
local activeTier = "Low"
local roundActive = false
local mapDisconnect = nil
local boundMap = nil
local refreshQueued = false

local function part(name, size, frame, color, material, transparency, highShadow)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = frame
    p.Color = color
    p.Material = material
    p.Transparency = transparency or 0
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = highShadow == true
    p.Parent = folder
    return p
end

local function track(p, motion, amplitude, speed, phase)
    animated[#animated + 1] = {
        object = p,
        home = p.CFrame,
        transparency = p.Transparency,
        motion = motion,
        amplitude = amplitude,
        speed = speed,
        phase = phase or 0,
    }
end

local function baseFrame(base, x, z, yaw)
    return base.CFrame * CFrame.new(x, base.Size.Y * 0.5, z)
        * CFrame.Angles(0, math.rad(yaw), 0)
end

local function buildClassic(base, theme, tier)
    -- Broadcast archive: concrete fins, dark louvers and an active scanner.
    -- Its outboard placement keeps the player path and spawn area clear.
    local f = baseFrame(base, -base.Size.X * 0.5 - 19, -base.Size.Z * 0.19, 90)
    local dark = theme.Structure:Lerp(VisualTheme.World.Deep, 0.43)
    local high = tier == "High"
    local height = tier == "Low" and 14 or 18
    for side = -1, 1, 2 do
        part("ClassicArchivePier" .. side, Vector3.new(2.8, height, 3.2),
            f * CFrame.new(side * 8, height * 0.5, 0),
            dark, Enum.Material.Concrete, 0.02, high)
        if high then
            part("ClassicArchivePierInset" .. side, Vector3.new(0.35, 12, 3.28),
                f * CFrame.new(side * 8, 9, -0.03),
                theme.Detail, Enum.Material.CorrodedMetal, 0.12, false)
        end
    end
    part("ClassicArchiveBackplate", Vector3.new(13, height - 3, 1.25),
        f * CFrame.new(0, (height - 3) * 0.5 + 1, 1.7),
        VisualTheme.World.Surface, Enum.Material.Slate, 0.02, high)
    part("ClassicArchiveHeader", Vector3.new(20.5, 1.6, 4.0),
        f * CFrame.new(0, height + 0.35, 0),
        theme.Detail, Enum.Material.DiamondPlate, 0.06, high)

    if tier ~= "Low" then
        local rows = high and 5 or 3
        for i = 1, rows do
            part("ClassicArchiveLouver" .. i, Vector3.new(12, 0.65, 1.0),
                f * CFrame.new(0, 4 + i * 2.05, -0.65)
                    * CFrame.Angles(math.rad(-11), 0, 0),
                i % 2 == 0 and theme.Detail or dark,
                Enum.Material.CorrodedMetal, 0.05, high)
        end
        local scanner = part("ClassicArchiveScanner", Vector3.new(0.34, 9.4, 0.42),
            f * CFrame.new(0, 9.0, -1.35),
            theme.Accent, Enum.Material.Neon, 0.36, false)
        track(scanner, "scan", 4.8, 0.77)
        if high then
            for side = -1, 1, 2 do
                part("ClassicArchiveDiagonal" .. side, Vector3.new(8.2, 0.65, 0.95),
                    f * CFrame.new(side * 4.2, 16.4, -0.4)
                        * CFrame.Angles(0, 0, math.rad(side * 28)),
                    theme.Detail, Enum.Material.Metal, 0.06, true)
            end
        end
    end
end

local function buildTowers(base, theme, tier)
    -- Suspended engine deck and an independent, slow-moving counterweight.
    local f = baseFrame(base, base.Size.X * 0.5 + 19, -base.Size.Z * 0.48, -90)
    local high = tier == "High"
    local height = tier == "Low" and 20 or 28
    local dark = theme.Structure:Lerp(VisualTheme.World.Deep, 0.29)
    for side = -1, 1, 2 do
        part("TowersEngineButtress" .. side, Vector3.new(3.1, height, 3.6),
            f * CFrame.new(side * 6.1, height * 0.5, 0),
            dark, Enum.Material.CorrodedMetal, 0.04, high)
        if tier ~= "Low" then
            part("TowersEngineGuide" .. side, Vector3.new(0.45, height - 3, 1.2),
                f * CFrame.new(side * 6.1, height * 0.5, -2.05),
                theme.Detail, Enum.Material.DiamondPlate, 0.06, false)
        end
    end
    part("TowersEngineCrosshead", Vector3.new(15.4, 1.8, 4.4),
        f * CFrame.new(0, height + 0.15, 0),
        theme.Detail, Enum.Material.DiamondPlate, 0.05, high)
    part("TowersEngineDeck", Vector3.new(13.4, 1.2, 6.2),
        f * CFrame.new(0, 5.8, 0),
        theme.Structure, Enum.Material.Metal, 0.08, high)

    if tier ~= "Low" then
        local pod = part("TowersEngineCounterweight", Vector3.new(4.5, 6, 3.6),
            f * CFrame.new(0, 16.0, -0.8),
            theme.Detail:Lerp(dark, 0.24), Enum.Material.DiamondPlate, 0.04, high)
        track(pod, "lift", 2.3, 0.55)
        part("TowersEngineBeacon", Vector3.new(6.2, 0.3, 0.5),
            f * CFrame.new(0, height - 2.0, -2.28),
            theme.Accent, Enum.Material.Neon, 0.36, false)
        if high then
            for side = -1, 1, 2 do
                part("TowersEngineKneeBrace" .. side, Vector3.new(9.4, 0.85, 1.2),
                    f * CFrame.new(side * 5.4, height - 5.2, 0)
                        * CFrame.Angles(0, 0, math.rad(side * 38)),
                    dark, Enum.Material.Metal, 0.05, true)
            end
        end
    end
end

local function buildCrossroads(base, theme, tier)
    -- Raised transit concourse with layered canopy and sequenced lane signals.
    local f = baseFrame(base, base.Size.X * 0.5 + 21, base.Size.Z * 0.36, 90)
    local high = tier == "High"
    local height = tier == "Low" and 10 or 13
    for side = -1, 1, 2 do
        part("CrossroadsConcoursePier" .. side, Vector3.new(2.5, height, 3.4),
            f * CFrame.new(side * 9.0, height * 0.5, 0),
            theme.Structure, Enum.Material.Concrete, 0.02, high)
    end
    part("CrossroadsConcourseRoof", Vector3.new(23.5, 1.2, 8.0),
        f * CFrame.new(0, height + 0.7, 0),
        theme.Detail, Enum.Material.DiamondPlate, 0.05, high)
    part("CrossroadsConcoursePanel", Vector3.new(19, 4.0, 0.65),
        f * CFrame.new(0, height - 2.6, -2.0),
        VisualTheme.World.Surface, Enum.Material.Slate, 0.02, false)
    part("CrossroadsConcourseBlade", Vector3.new(19, 0.48, 1.1),
        f * CFrame.new(0, height - 0.3, -2.45),
        theme.Secondary, Enum.Material.Neon, 0.35, false)

    if tier ~= "Low" then
        part("CrossroadsConcourseGlazing", Vector3.new(18.0, 0.36, 5.8),
            f * CFrame.new(0, height + 1.46, -0.5),
            theme.Accent:Lerp(VisualTheme.World.Metal, 0.55),
            Enum.Material.Glass, 0.44, high)
        for i = 1, 3 do
            local lamp = part("CrossroadsConcourseLaneSignal" .. i,
                Vector3.new(3.7, 0.62, 0.58),
                f * CFrame.new(-6.5 + (i - 1) * 6.5, height - 3.3, -2.48),
                i == 2 and theme.Secondary or theme.Accent,
                Enum.Material.Neon, 0.42, false)
            track(lamp, "signal", 0.22, 1.35, (i - 1) * (math.pi * 2 / 3))
        end
        if high then
            for i = 1, 3 do
                part("CrossroadsConcourseCeilingRib" .. i,
                    Vector3.new(0.56, 0.50, 9.4),
                    f * CFrame.new((i - 2) * 7.0, height + 0.03, 0),
                    theme.Detail, Enum.Material.CorrodedMetal, 0.05, true)
            end
        end
    end
end

local function buildOrbital(base, theme, tier)
    -- Docking observation array: braced spine, static pressure ring, live collar.
    local f = baseFrame(base, base.Size.X * 0.5 + 19, base.Size.Z * 0.42, -90)
    local high = tier == "High"
    local height = tier == "Low" and 17 or 22
    part("OrbitalDockSpine", Vector3.new(3.5, height, 3.5),
        f * CFrame.new(0, height * 0.5, 0),
        theme.Structure, Enum.Material.Metal, 0.04, high)
    part("OrbitalDockFoot", Vector3.new(10, 1.6, 8),
        f * CFrame.new(0, 0.8, 0),
        VisualTheme.World.Surface, Enum.Material.Slate, 0.05, high)
    for side = -1, 1, 2 do
        part("OrbitalDockWing" .. side, Vector3.new(8.5, 0.95, 1.7),
            f * CFrame.new(side * 5.4, height - 4, 0),
            theme.Detail, Enum.Material.DiamondPlate, 0.08, high)
    end

    local segmentCount = tier == "Low" and 4 or (high and 12 or 8)
    local radius = tier == "Low" and 5.4 or 7.8
    local ringCenter = f * CFrame.new(0, height - 1.2, 0)
    local length = (2 * math.pi * radius / segmentCount) * 0.72
    for i = 1, segmentCount do
        local angle = (i - 1) * (math.pi * 2 / segmentCount)
        local segmentFrame = ringCenter
            * CFrame.Angles(0, 0, angle)
            * CFrame.new(radius, 0, 0)
            * CFrame.Angles(0, 0, math.pi * 0.5)
        part("OrbitalDockHaloSegment" .. i,
            Vector3.new(length, 0.75, 1.05), segmentFrame,
            i % 3 == 0 and theme.Accent or theme.Detail,
            i % 3 == 0 and Enum.Material.Neon or Enum.Material.Metal,
            i % 3 == 0 and 0.30 or 0.06, false)
    end
    if tier ~= "Low" then
        local collar = part("OrbitalDockSignalCollar", Vector3.new(10.0, 0.52, 2.0),
            f * CFrame.new(0, height - 2.3, -2.6),
            theme.Secondary, Enum.Material.Neon, 0.38, false)
        track(collar, "swing", 0.23, 0.62)
        local core = part("OrbitalDockCore", Vector3.new(3.0, 3.0, 3.0),
            f * CFrame.new(0, height - 1.2, 0),
            theme.Accent, Enum.Material.Glass, 0.21, false)
        core.Shape = Enum.PartType.Ball
    end
end

local function restoreMotion()
    for _, item in ipairs(animated) do
        local p = item.object
        if p and p.Parent then
            p.CFrame = item.home
            p.Transparency = item.transparency
        end
    end
end

local function clear()
    table.clear(animated)
    folder:ClearAllChildren()
    activeBase = nil
end

local function rebuild()
    clear()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = MapVisualReadiness.part(generated, "Arena", "Base")
    if not arena or not base then return end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local tier = VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled).Name
    local theme = VisualTheme.arena(variant)
    activeBase = base
    activeTier = tier

    if variant == "Towers" then
        buildTowers(base, theme, tier)
    elseif variant == "Crossroads" then
        buildCrossroads(base, theme, tier)
    elseif variant == "Orbital" then
        buildOrbital(base, theme, tier)
    else
        buildClassic(base, theme, tier)
    end
end

local function queueRebuild()
    if refreshQueued then return end
    refreshQueued = true
    task.defer(function()
        refreshQueued = false
        rebuild()
    end)
end

local function bindMap(generated)
    if mapDisconnect then
        mapDisconnect()
        mapDisconnect = nil
    end
    boundMap = generated
    if generated then
        mapDisconnect = MapVisualReadiness.watch(
            generated, "Arena", "Base", queueRebuild)
    else
        clear()
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindMap(child)
        queueRebuild()
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child == boundMap then
        bindMap(workspace:FindFirstChild("GeneratedMap"))
    end
end)
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(queueRebuild)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(restoreMotion)

roundState.OnClientEvent:Connect(function(state)
    if type(state) == "table" then
        roundActive = state.phase == "round"
    end
end)

bindMap(workspace:FindFirstChild("GeneratedMap"))
queueRebuild()

-- Bounded 5 Hz cosmetic tick; no Heartbeat/RenderStepped connections.
-- LOD owns LocalTransparencyModifier, so animations never reveal hidden art.
task.spawn(function()
    while true do
        if activeBase and activeBase.Parent and activeTier ~= "Low"
            and player:GetAttribute("ReduceMotion") ~= true then
            local camera = workspace.CurrentCamera
            if camera and (camera.CFrame.Position - activeBase.Position).Magnitude < 220 then
                local t = os.clock()
                local activity = roundActive and 1.15 or 1
                for _, item in ipairs(animated) do
                    local p = item.object
                    if p and p.Parent then
                        local phase = t * item.speed * activity + item.phase
                        local wave = math.sin(phase)
                        if item.motion == "scan" then
                            p.CFrame = item.home * CFrame.new(wave * item.amplitude, 0, 0)
                        elseif item.motion == "lift" then
                            p.CFrame = item.home * CFrame.new(0, wave * item.amplitude, 0)
                        elseif item.motion == "swing" then
                            p.CFrame = item.home * CFrame.Angles(0, wave * item.amplitude, 0)
                        elseif item.motion == "signal" then
                            p.Transparency = math.clamp(
                                item.transparency + (wave + 1) * 0.5 * item.amplitude, 0, 0.75)
                        end
                    end
                end
            end
        end
        task.wait(0.20)
    end
end)
