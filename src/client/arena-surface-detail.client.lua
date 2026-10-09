local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)
local ArenaDeckFinishKit = require(script.Parent.ArenaDeckFinishKit)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local currentState = nil
local folder = Instance.new("Folder")
folder.Name = "ArenaSurfaceDetailLocal"
folder.Parent = workspace

local function clear()
    folder:ClearAllChildren()
end

local function makePart(name, size, cframe, color, material, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Material = material
    p.Color = color
    p:SetAttribute("SurfaceBaseColor", color)
    p.Transparency = transparency or 0
    p.Parent = folder
    return p
end

local function addPanelLanguage(base, theme, tier, variant)
    local top = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.042, 0)
    local halfX = base.Size.X * 0.5
    local halfZ = base.Size.Z * 0.5
    local seamAlpha = tier.Name == "Low" and 0.76 or (tier.Name == "Medium" and 0.64 or 0.56)

    local seamCount
    if variant == "Orbital" then
        seamCount = tier.Name == "High" and 2 or 0
    elseif variant == "Crossroads" then
        seamCount = tier.Name == "Low" and 2 or 4
    else
        seamCount = tier.Name == "Low" and 4 or (tier.Name == "Medium" and 6 or 8)
    end
    for i = 1, seamCount do
        local t = (i / (seamCount + 1)) * 2 - 1
        local horizontal = i % 2 == 0
        local size = horizontal
            and Vector3.new(base.Size.X * 0.86, 0.028, 0.08)
            or Vector3.new(0.08, 0.028, base.Size.Z * 0.86)
        local offset = horizontal
            and Vector3.new(0, 0, t * halfZ * 0.86)
            or Vector3.new(t * halfX * 0.86, 0, 0)

        makePart(
            "PanelSeam" .. i,
            size,
            top * CFrame.new(offset),
            VisualTheme.World.Deep:Lerp(theme.Structure, 0.35),
            Enum.Material.Metal,
            seamAlpha
        )
    end

    local patchCount
    if variant == "Orbital" then
        patchCount = tier.Name == "Low" and 1 or (tier.Name == "Medium" and 2 or 3)
    elseif variant == "Crossroads" then
        patchCount = tier.Name == "Low" and 2 or (tier.Name == "Medium" and 3 or 4)
    else
        patchCount = tier.Name == "Low" and 3 or (tier.Name == "Medium" and 5 or 7)
    end
    for i = 1, patchCount do
        local gridX = ((i * 37) % 9) / 8
        local gridZ = ((i * 53) % 11) / 10
        local x = (gridX * 2 - 1) * halfX * 0.68
        local z = (gridZ * 2 - 1) * halfZ * 0.68
        local long = i % 2 == 0

        local size = long
            and Vector3.new(4.8 + (i % 3) * 1.4, 0.035, 1.2)
            or Vector3.new(1.2, 0.035, 4.8 + (i % 3) * 1.4)
        local patch = makePart(
            "RepairPlate" .. i,
            size,
            top * CFrame.new(x, 0.012, z),
            theme.Surface:Lerp(theme.Structure, 0.46),
            i % 3 == 0 and Enum.Material.DiamondPlate or Enum.Material.Metal,
            tier.Name == "Low" and 0.34 or 0.18
        )
        patch:SetAttribute("SurfaceBaseColor", patch.Color)

        if tier.Name == "High" then
            local insetSize = long
                and Vector3.new(size.X * 0.74, 0.022, 0.08)
                or Vector3.new(0.08, 0.022, size.Z * 0.74)
            makePart(
                "RepairPlateInset" .. i,
                insetSize,
                patch.CFrame * CFrame.new(0, size.Y * 0.5 + 0.02, 0),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                0.72
            )
        end
    end

    if tier.Name ~= "Low" then
        local edgeDefs = {
            {Vector3.new(base.Size.X * 0.42, 0.032, 0.10), Vector3.new(0, 0, -halfZ * 0.90)},
            {Vector3.new(base.Size.X * 0.42, 0.032, 0.10), Vector3.new(0, 0, halfZ * 0.90)},
            {Vector3.new(0.10, 0.032, base.Size.Z * 0.42), Vector3.new(-halfX * 0.90, 0, 0)},
            {Vector3.new(0.10, 0.032, base.Size.Z * 0.42), Vector3.new(halfX * 0.90, 0, 0)},
        }

        for i, def in ipairs(edgeDefs) do
            local wearColor = variant == "Towers"
                and theme.Secondary
                or (variant == "Orbital" and theme.Accent or theme.Detail)
            makePart(
                "EdgeWear" .. i,
                def[1],
                top * CFrame.new(def[2]),
                wearColor,
                Enum.Material.Metal,
                0.72
            )
        end
    end
end

local function rebuild()
    clear()

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = MapVisualReadiness.part(generated, "Arena", "Base")
    if not arena or not base or not base:IsA("BasePart") then
        return
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local theme = VisualTheme.arena(variant)
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    -- The entire detail composition follows a rotated or tilted arena deck.
    local surfaceFrame = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.035, 0)
    local halfX = base.Size.X * 0.5
    local halfZ = base.Size.Z * 0.5
    local countScale = tier.Name == "Low" and 0.55 or (tier.Name == "Medium" and 0.78 or 1)

    addPanelLanguage(base, theme, tier, variant)
    ArenaDeckFinishKit.build(folder, base, variant, tier.Name, theme)

    if variant == "Classic" then
        local lanes = math.max(4, math.floor(8 * countScale))
        for i = 1, lanes do
            local t = (i / (lanes + 1)) * 2 - 1
            local horizontal = i % 2 == 0
            local size = horizontal
                and Vector3.new(base.Size.X * 0.76, 0.05, 0.20)
                or Vector3.new(0.20, 0.05, base.Size.Z * 0.76)
            local offset = horizontal
                and Vector3.new(0, 0, t * halfZ * 0.74)
                or Vector3.new(t * halfX * 0.74, 0, 0)
            makePart(
                "ClassicInset" .. i,
                size,
                surfaceFrame * CFrame.new(offset),
                i % 3 == 0 and theme.Secondary or theme.Detail,
                Enum.Material.Metal,
                0.52
            )
        end
    elseif variant == "Towers" then
        local rings = math.max(3, math.floor(5 * countScale))
        for i = 1, rings do
            local radius = math.min(halfX, halfZ) * (0.18 + i * 0.12)
            local segments = tier.Name == "Low" and 4 or 8
            for s = 1, segments do
                local angle = ((s - 1) / segments) * math.pi * 2
                local tangent = angle + math.pi * 0.5
                local pos = surfaceFrame * CFrame.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
                makePart(
                    "TowerRing" .. i .. "_" .. s,
                    Vector3.new(math.max(3.0, radius * 0.42), 0.05, 0.16),
                    pos * CFrame.Angles(0, -tangent, 0),
                    i % 2 == 0 and theme.Secondary or theme.Detail,
                    Enum.Material.Metal,
                    0.56
                )
            end
        end
    elseif variant == "Crossroads" then
        local laneWidth = math.max(5, math.min(10, base.Size.X * 0.07))
        local offsets = {
            Vector3.new(-halfX * 0.34, 0, 0),
            Vector3.new(halfX * 0.34, 0, 0),
            Vector3.new(0, 0, -halfZ * 0.34),
            Vector3.new(0, 0, halfZ * 0.34),
        }
        for i, offset in ipairs(offsets) do
            local horizontal = i >= 3
            makePart(
                "CrossroadLaneInset" .. i,
                horizontal and Vector3.new(base.Size.X * 0.70, 0.05, 0.24)
                    or Vector3.new(0.24, 0.05, base.Size.Z * 0.70),
                surfaceFrame * CFrame.new(offset),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                tier.Name == "Low" and 0.72 or 0.58
            )
        end

        if tier.Name ~= "Low" then
            for i = 1, 8 do
                local angle = ((i - 1) / 8) * math.pi * 2
                local pos = surfaceFrame * CFrame.new(math.cos(angle) * halfX * 0.48, 0, math.sin(angle) * halfZ * 0.48)
                makePart(
                    "CrossroadNode" .. i,
                    Vector3.new(2.2, 0.05, 2.2),
                    pos * CFrame.Angles(0, -angle, 0),
                    theme.Detail,
                    Enum.Material.DiamondPlate,
                    0.42
                )
            end
        end
    elseif variant == "Orbital" then
        local segments = tier.Name == "Low" and 8 or (tier.Name == "Medium" and 12 or 16)
        local radius = math.min(halfX, halfZ) * 0.57
        for i = 1, segments do
            local angle = ((i - 1) / segments) * math.pi * 2
            local tangent = angle + math.pi * 0.5
            local pos = surfaceFrame * CFrame.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
            makePart(
                "OrbitalSurfaceArc" .. i,
                Vector3.new(radius * 0.34, 0.05, 0.22),
                pos * CFrame.Angles(0, -tangent, 0),
                i % 3 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                tier.Name == "Low" and 0.74 or 0.56
            )
        end

        local core = makePart(
            "OrbitalSurfaceCore",
            Vector3.new(math.min(base.Size.X, base.Size.Z) * 0.22, 0.05, math.min(base.Size.X, base.Size.Z) * 0.22),
            surfaceFrame,
            theme.Structure,
            Enum.Material.Metal,
            0.48
        )
        core.Shape = Enum.PartType.Cylinder
        core.CFrame = core.CFrame * CFrame.Angles(0, 0, math.rad(90))

        local spokeCount = tier.Name == "Low" and 4 or (tier.Name == "Medium" and 6 or 8)
        for i = 1, spokeCount do
            local angle = ((i - 1) / spokeCount) * math.pi * 2
            local length = radius * 0.62
            local midpoint = surfaceFrame * CFrame.new(
                math.cos(angle) * radius * 0.31,
                0.01,
                math.sin(angle) * radius * 0.31
            )
            makePart(
                "OrbitalRadialSeam" .. i,
                Vector3.new(length, 0.028, 0.08),
                midpoint
                    * CFrame.Angles(0, -(angle + math.pi * 0.5), 0),
                VisualTheme.World.Deep:Lerp(theme.Structure, 0.28),
                Enum.Material.Metal,
                tier.Name == "Low" and 0.74 or 0.62
            )
        end
    end
end

local function refreshSurfaceAccent()
    local state = currentState
    local profile = state and DisasterVisuals.combine(state.disasterIds or {}) or nil
    local secondary = state and state.disasterIds and state.disasterIds[2]
        and DisasterVisuals.get(state.disasterIds[2]) or nil
    local critical = state and state.phase == "round" and state.finalRush == true

    for index, descendant in ipairs(folder:GetChildren()) do
        if descendant:IsA("BasePart") then
            local baseColor = descendant:GetAttribute("SurfaceBaseColor")
            if typeof(baseColor) ~= "Color3" then
                baseColor = descendant.Color
            end

            if state and state.phase == "round" and profile and not critical then
                local accent = profile.Accent
                if secondary and index % 2 == 0 then
                    accent = secondary.Accent
                end
                local amount = descendant.Material == Enum.Material.Neon and 0.30 or 0.12
                descendant.Color = baseColor:Lerp(accent, amount)
            else
                descendant.Color = baseColor
            end
        end
    end
end

local disconnectMapWatch = nil
local refreshPending = false

local function scheduleRefresh()
    if refreshPending then return end
    refreshPending = true
    task.defer(function()
        refreshPending = false
        rebuild()
        refreshSurfaceAccent()
    end)
end

local function bindGeneratedMap(generated)
    if disconnectMapWatch then
        disconnectMapWatch()
        disconnectMapWatch = nil
    end
    if generated then
        disconnectMapWatch = MapVisualReadiness.watch(
            generated, "Arena", "Base", scheduleRefresh
        )
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindGeneratedMap(child)
        scheduleRefresh()
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindGeneratedMap(nil)
        clear()
    end
end)

bindGeneratedMap(workspace:FindFirstChild("GeneratedMap"))

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(scheduleRefresh)

stateEvent.OnClientEvent:Connect(function(state)
    currentState = state
    refreshSurfaceAccent()
end)

rebuild()
refreshSurfaceAccent()
