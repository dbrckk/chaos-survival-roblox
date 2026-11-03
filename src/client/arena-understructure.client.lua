local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)
local ArenaFloorFollowerKit = require(script.Parent.ArenaFloorFollowerKit)
local UnderstructureBeamMeshKit = require(script.Parent.UnderstructureBeamMeshKit)

local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "ArenaUnderstructureLocal"
folder.Parent = workspace

local stopFollowingBase = nil

local function clear()
    -- The approved beam models must restore their native fallbacks before
    -- this map's cosmetic parts are rebuilt for streaming or tier changes.
    UnderstructureBeamMeshKit.reset()
    if stopFollowingBase then
        stopFollowingBase()
        stopFollowingBase = nil
    end
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
    p.Material = material or Enum.Material.Metal
    p.Color = color
    p.Transparency = transparency or 0
    p.Parent = folder
    return p
end

local function rebuild()
    clear()

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not arena or not base or not base:IsA("BasePart") then
        return
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local theme = VisualTheme.arena(variant)
    local tier = VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled)
    local center = base.Position
    local bottomY = center.Y - base.Size.Y * 0.5
    local halfX = base.Size.X * 0.5
    local halfZ = base.Size.Z * 0.5

    local ribCount = tier.Name == "Low" and 4 or (tier.Name == "Medium" and 6 or 8)
    for i = 1, ribCount do
        local t = ribCount == 1 and 0 or ((i - 1) / (ribCount - 1)) * 2 - 1
        local horizontal = i % 2 == 0

        local size = horizontal
            and Vector3.new(base.Size.X * 0.82, 0.75, 1.15)
            or Vector3.new(1.15, 0.75, base.Size.Z * 0.82)
        local offset = horizontal
            and Vector3.new(0, -1.0 - ((i % 3) * 0.22), t * halfZ * 0.68)
            or Vector3.new(t * halfX * 0.68, -1.0 - ((i % 3) * 0.22), 0)

        makePart(
            "UnderRib" .. i,
            size,
            CFrame.new(Vector3.new(center.X, bottomY, center.Z) + offset),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.38),
            Enum.Material.Metal,
            tier.Name == "Low" and 0.24 or 0.12
        )
    end

    local cornerOffsets = {
        Vector3.new(-halfX * 0.72, 0, -halfZ * 0.72),
        Vector3.new(halfX * 0.72, 0, -halfZ * 0.72),
        Vector3.new(-halfX * 0.72, 0, halfZ * 0.72),
        Vector3.new(halfX * 0.72, 0, halfZ * 0.72),
    }

    for i, offset in ipairs(cornerOffsets) do
        local depth = variant == "Towers" and 12 or (variant == "Orbital" and 8 or 9)
        local support = makePart(
            "UnderSupport" .. i,
            Vector3.new(2.8, depth, 2.8),
            CFrame.new(center + Vector3.new(offset.X, -(base.Size.Y * 0.5) - depth * 0.5 + 0.4, offset.Z)),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.48),
            Enum.Material.Metal,
            tier.Name == "Low" and 0.28 or 0.14
        )

        local supportGlow = tier.Name == "High" and i % 2 == 1
            or tier.Name == "Medium" and i == 1
        if supportGlow then
            local glow = makePart(
                "UnderSupportGlow" .. i,
                Vector3.new(0.32, depth * 0.62, 2.95),
                support.CFrame,
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                tier.Name == "High" and 0.54 or 0.62
            )
            glow.CastShadow = false
        end
    end

    if variant == "Classic" then
        -- Replace two 198-stud monolithic slabs with 12 independently
        -- cullable mechanical bays, surrounding the approved central keel.
        -- Each 23.3-stud bay has its own safe native fallback; the nearby
        -- bays can be covered by genuine owner-approved imported 3D.
        local chassisY = bottomY - 4.4
        for _, axis in ipairs({"X", "Z"}) do
            local alongX = axis == "X"
            for index, offset in ipairs({-84, -60, -36, 36, 60, 84}) do
                local beam = makePart(
                    "UnderClassicBeam" .. axis .. index,
                    alongX and Vector3.new(23.3, 2.2, 6.0)
                        or Vector3.new(6.0, 2.2, 23.3),
                    CFrame.new(center + Vector3.new(
                        alongX and offset or 0,
                        (chassisY - center.Y) - (alongX and 0 or .35),
                        alongX and 0 or offset
                    )),
                    theme.Structure:Lerp(VisualTheme.World.Deep, .35),
                    Enum.Material.Metal,
                    tier.Name == "Low" and .30 or .16
                )
                beam:SetAttribute("OriginalUnderstructureBeam", true)
            end
        end

        if tier.Name ~= "Low" then
            for side = -1, 1, 2 do
                local bay = makePart(
                    side < 0 and "UnderClassicDataBayL" or "UnderClassicDataBayR",
                    Vector3.new(13, 4.2, 8.0),
                    CFrame.new(
                        center + Vector3.new(side * halfX * 0.30, -6.7, halfZ * 0.14)
                    ),
                    theme.Detail:Lerp(VisualTheme.World.Deep, 0.24),
                    Enum.Material.DiamondPlate,
                    0.16
                )
                if tier.Name == "High" or side < 0 then
                    makePart(
                        side < 0 and "UnderClassicDataGlowL" or "UnderClassicDataGlowR",
                        Vector3.new(8.5, 0.30, 8.12),
                        bay.CFrame * CFrame.new(0, 2.26, 0),
                        side < 0 and theme.Accent or theme.Secondary,
                        Enum.Material.Neon,
                        tier.Name == "High" and 0.58 or 0.66
                    )
                end
            end
        end
    elseif variant == "Crossroads" then
        local junction = makePart(
            "UnderCrossroadsJunction",
            Vector3.new(15, 4.5, 15),
            CFrame.new(center + Vector3.new(0, -6.0, 0)),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.26),
            Enum.Material.Concrete,
            tier.Name == "Low" and 0.28 or 0.12
        )
        junction.CastShadow = false

        -- The former four 134-stud untextured blocks are now sixteen
        -- individual beam bays. A real imported 3D chassis can replace each
        -- bay without hiding other spans when Android runs out of budget.
        -- Central space stays open for the independent Arena Keel mesh.
        for _, leg in ipairs({
            {name = "N", axis = "Z", sign = -1},
            {name = "E", axis = "X", sign = 1},
            {name = "W", axis = "X", sign = -1},
            {name = "S", axis = "Z", sign = 1},
        }) do
            local alongX = leg.axis == "X"
            for index, distance in ipairs({42, 66, 90, 114}) do
                local beam = makePart(
                    "UnderCrossroadsBeam" .. leg.name .. index,
                    alongX and Vector3.new(23.3, 2.0, 7.0)
                        or Vector3.new(7.0, 2.0, 23.3),
                    CFrame.new(center + Vector3.new(
                        alongX and distance * leg.sign or 0,
                        -4.9,
                        alongX and 0 or distance * leg.sign
                    )),
                    theme.Structure:Lerp(VisualTheme.World.Deep, .28),
                    Enum.Material.Metal,
                    tier.Name == "Low" and .34 or .18
                )
                beam:SetAttribute("OriginalUnderstructureBeam", true)
            end
        end
    end

    -- Towers and Harbor previously exposed only bare Roblox support blocks.
    -- Give both themes genuine source-authentic 3D beam bays, identical in
    -- size and safety envelope to the approved Classic/Crossroads chassis.
    -- The existing camera-ranked UnderstructureBeamMeshKit replaces only
    -- nearby bays; native collision-free fallback remains on every tier.
    if variant == "Towers" or variant == "Harbor" then
        local positions = {-108, -84, -60, 60, 84, 108}
        for _, axis in ipairs({"X", "Z"}) do
            local alongX = axis == "X"
            for index, offset in ipairs(positions) do
                local beam = makePart(
                    "Under" .. variant .. "Beam" .. axis .. index,
                    alongX and Vector3.new(23.3, 2.2, 6.0)
                        or Vector3.new(6.0, 2.2, 23.3),
                    base.CFrame * CFrame.new(
                        alongX and offset or 0,
                        -base.Size.Y * .5 - 4.4,
                        alongX and 0 or offset
                    ),
                    theme.Structure:Lerp(VisualTheme.World.Deep, .32),
                    Enum.Material.Metal,
                    tier.Name == "Low" and .30 or .16
                )
                beam:SetAttribute("OriginalUnderstructureBeam", true)
            end
        end
    end

    if variant == "Orbital" then
        local hub = makePart(
            "UnderOrbitalHub",
            Vector3.new(
                tier.Name == "Low" and 10 or 14,
                tier.Name == "Low" and 10 or 14,
                tier.Name == "Low" and 10 or 14
            ),
            CFrame.new(center + Vector3.new(0, -7.5, 0)),
            theme.Structure,
            Enum.Material.Metal,
            tier.Name == "Low" and 0.24 or 0.10
        )
        hub.Shape = Enum.PartType.Ball
        hub.CastShadow = false

        if tier.Name ~= "Low" then
            -- Split each long native spoke at the genuine sculpted keel's
            -- 28-stud boundary. The inner half is hidden ONLY while the
            -- verified central MeshPart module occupies that volume; the
            -- outer half stays visible and never loses its radial support.
            -- The old 90-degree tangent error made spokes miss the reactor.
            local spokeCount = tier.Name == "High" and 6 or 4
            local radius = math.min(halfX, halfZ) * 0.34
            for i = 1, spokeCount do
                local angle = ((i - 1) / spokeCount) * math.pi * 2
                local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
                local orientation = CFrame.Angles(0, -angle, 0)
                for _, half in ipairs({"Inner", "Outer"}) do
                    local segmentCenter = radius * (half == "Inner" and .25 or .75)
                    makePart(
                        "UnderOrbital" .. half .. "Spoke" .. i,
                        Vector3.new(radius * .5, .70, 1.30),
                        CFrame.new(center + radial * segmentCenter
                            + Vector3.new(0, -7.5, 0)) * orientation,
                        i % 3 == 0 and theme.Secondary or theme.Detail,
                        i % 3 == 0 and Enum.Material.Neon or Enum.Material.Metal,
                        i % 3 == 0 and .58 or .18
                    )
                end
            end
        end

        -- The original orbital ring was a chain of thin 0.45-stud Roblox
        -- strips. Each curved-ring station now has a source-authentic,
        -- 23.3-stud mechanical chassis bay as its near-camera 3D replacement.
        -- All native bays remain cosmetic-only and automatically reappear
        -- if the approved owner asset is unavailable or over mobile budget.
        -- Extra stations improve the ring silhouette without extra lights.
        local segments = tier.Name == "Low" and 10
            or (tier.Name == "Medium" and 12 or 16)
        local radius = math.min(halfX, halfZ) * 0.64
        for i = 1, segments do
            local angle = ((i - 1) / segments) * math.pi * 2
            local tangent = angle + math.pi * 0.5
            local beam = makePart(
                "UnderOrbitalBeam" .. i,
                Vector3.new(23.3, 2.2, 7.0),
                base.CFrame
                    * CFrame.new(
                        math.cos(angle) * radius,
                        -base.Size.Y * 0.5 - 4.4,
                        math.sin(angle) * radius
                    )
                    * CFrame.Angles(0, -tangent, 0),
                i % 3 == 0 and theme.Detail or theme.Structure,
                Enum.Material.Metal,
                tier.Name == "Low" and 0.30 or 0.16
            )
            beam:SetAttribute("OriginalUnderstructureBeam", true)
        end
    elseif variant == "Towers" then
        local coreDepth = tier.Name == "Low" and 12 or 18
        local core = makePart(
            "UnderTowerCore",
            Vector3.new(10, coreDepth, 10),
            CFrame.new(
                center + Vector3.new(
                    0,
                    -(base.Size.Y * 0.5) - coreDepth * 0.5 + 0.2,
                    0
                )
            ),
            theme.Structure:Lerp(VisualTheme.World.Deep, 0.30),
            Enum.Material.CorrodedMetal,
            tier.Name == "Low" and 0.26 or 0.10
        )
        core.CastShadow = false

        if tier.Name ~= "Low" then
            makePart(
                "UnderTowerCoreGlow",
                Vector3.new(0.42, coreDepth * 0.72, 10.15),
                core.CFrame,
                theme.Accent,
                Enum.Material.Neon,
                0.46
            )

            for i = 1, 4 do
            local angle = math.rad(45 + (i - 1) * 90)
            local pos = center + Vector3.new(
                math.cos(angle) * halfX * 0.90,
                -(base.Size.Y * 0.5) - 4.0,
                math.sin(angle) * halfZ * 0.90
            )
                makePart(
                    "UnderTowerBrace" .. i,
                Vector3.new(2.2, 10, 2.2),
                CFrame.new(pos) * CFrame.Angles(math.rad(22), 0, math.rad(22)),
                theme.Detail,
                Enum.Material.Metal,
                    0.22
                )
            end
        end
    end

    -- Shrinking Arena scales the real floor during play. Keep the floating
    -- undercarriage, support pylons and cosmetic reactor aligned to it so
    -- they never protrude beyond the smaller collision deck.
    -- One base Size listener; no per-frame polling or new scene parts.
    stopFollowingBase = ArenaFloorFollowerKit.bind(base, folder)
end

-- The arena Folder can replicate before Base and its VariantId.
-- Track all three readiness transitions with the shared engine-tested watcher,
-- and coalesce same-turn callbacks into one potentially expensive 3D build.
local disconnectMapWatch = nil
local watchedMap = nil
local rebuildPending = false

local function scheduleRebuild()
    if rebuildPending then return end
    rebuildPending = true
    task.defer(function()
        rebuildPending = false
        rebuild()
    end)
end

local function bindGeneratedMap(generated)
    if disconnectMapWatch then
        disconnectMapWatch()
        disconnectMapWatch = nil
    end
    watchedMap = generated
    if generated then
        disconnectMapWatch = MapVisualReadiness.watch(
            generated, "Arena", "Base", scheduleRebuild
        )
    else
        clear()
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap"
        and workspace:FindFirstChild("GeneratedMap") == child then
        bindGeneratedMap(child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child == watchedMap then
        bindGeneratedMap(workspace:FindFirstChild("GeneratedMap"))
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(scheduleRebuild)

bindGeneratedMap(workspace:FindFirstChild("GeneratedMap"))
scheduleRebuild()
