local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local revealToken = 0

local function makeNeonPart(name, size, cframe, color, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = transparency
    part.Parent = workspace
    return part
end

local function tweenAndCleanup(part, duration, goal)
    TweenService:Create(
        part,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        goal
    ):Play()
    Debris:AddItem(part, duration + 0.25)
end

local function spawnClassicSignature(center, base, theme, tier)
    local laneCount = tier.Name == "High" and 4 or 2
    local span = math.max(base.Size.X, base.Size.Z) * 0.62

    for i = 1, laneCount do
        local alpha = laneCount == 1 and 0.5 or (i - 1) / (laneCount - 1)
        local offset = (alpha - 0.5) * span
        local delayTime = (i - 1) * 0.045

        task.delay(delayTime, function()
            local xLine = makeNeonPart(
                "LocalArenaRevealClassic",
                Vector3.new(0.16, 0.05, 1.5),
                CFrame.new(center + Vector3.new(offset, 0.04, 0)),
                theme.Accent,
                0.38
            )
            tweenAndCleanup(xLine, 0.44, {
                Size = Vector3.new(0.16, 0.05, base.Size.Z * 0.78),
                Transparency = 1,
            })

            local zLine = makeNeonPart(
                "LocalArenaRevealClassic",
                Vector3.new(1.5, 0.05, 0.16),
                CFrame.new(center + Vector3.new(0, 0.045, offset)),
                theme.Secondary,
                0.44
            )
            tweenAndCleanup(zLine, 0.44, {
                Size = Vector3.new(base.Size.X * 0.78, 0.05, 0.16),
                Transparency = 1,
            })
        end)
    end
end

local function spawnTowersSignature(center, base, theme, tier)
    local count = tier.Name == "High" and 4 or 2
    local radiusX = base.Size.X * 0.34
    local radiusZ = base.Size.Z * 0.34

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2 + math.rad(45)
        local position = center + Vector3.new(math.cos(angle) * radiusX, 0.2, math.sin(angle) * radiusZ)
        local column = makeNeonPart(
            "LocalArenaRevealTower",
            Vector3.new(0.34, 0.5, 0.34),
            CFrame.new(position),
            i % 2 == 0 and theme.Secondary or theme.Accent,
            0.42
        )
        tweenAndCleanup(column, 0.52, {
            Size = Vector3.new(0.18, 10 + (i % 2) * 5, 0.18),
            CFrame = CFrame.new(position + Vector3.new(0, 5.2 + (i % 2) * 2.5, 0)),
            Transparency = 1,
        })
    end
end

local function spawnCrossroadsSignature(center, base, theme, tier)
    local length = math.max(base.Size.X, base.Size.Z) * 0.76
    local width = tier.Name == "High" and 0.42 or 0.30

    local xBar = makeNeonPart(
        "LocalArenaRevealCrossroads",
        Vector3.new(1.5, 0.06, width),
        CFrame.new(center + Vector3.new(0, 0.05, 0)),
        theme.Accent,
        0.34
    )
    tweenAndCleanup(xBar, 0.48, {
        Size = Vector3.new(length, 0.06, width),
        Transparency = 1,
    })

    task.delay(0.07, function()
        local zBar = makeNeonPart(
            "LocalArenaRevealCrossroads",
            Vector3.new(width, 0.06, 1.5),
            CFrame.new(center + Vector3.new(0, 0.055, 0)),
            theme.Secondary,
            0.38
        )
        tweenAndCleanup(zBar, 0.48, {
            Size = Vector3.new(width, 0.06, length),
            Transparency = 1,
        })
    end)
end

local function spawnOrbitalSignature(center, base, theme, tier)
    local count = tier.Name == "High" and 3 or 2
    local radius = math.max(base.Size.X, base.Size.Z) * 0.30

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2
        local plate = makeNeonPart(
            "LocalArenaRevealOrbital",
            Vector3.new(2.4, 0.05, 0.18),
            CFrame.new(center + Vector3.new(math.cos(angle) * radius, 0.07, math.sin(angle) * radius))
                * CFrame.Angles(0, -angle, 0),
            i % 2 == 0 and theme.Secondary or theme.Accent,
            0.34
        )

        local endAngle = angle + math.rad(tier.Name == "High" and 105 or 82)
        local endPosition = center
            + Vector3.new(math.cos(endAngle) * radius * 1.08, 0.07, math.sin(endAngle) * radius * 1.08)

        tweenAndCleanup(plate, 0.56, {
            CFrame = CFrame.new(endPosition) * CFrame.Angles(0, -endAngle, 0),
            Size = Vector3.new(4.2, 0.05, 0.10),
            Transparency = 1,
        })
    end
end

local function spawnVariantSignature(variant, center, base, theme, tier, reducedMotion)
    if reducedMotion or tier.Name == "Low" then
        return
    end

    if variant == "Towers" then
        spawnTowersSignature(center, base, theme, tier)
    elseif variant == "Crossroads" then
        spawnCrossroadsSignature(center, base, theme, tier)
    elseif variant == "Orbital" then
        spawnOrbitalSignature(center, base, theme, tier)
    else
        spawnClassicSignature(center, base, theme, tier)
    end
end

local function revealArena(arena)
    if not arena or not arena.Parent then
        return
    end

    local base = arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") then
        return
    end

    revealToken += 1
    local token = revealToken
    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local theme = VisualTheme.arena(variant)
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local reducedMotion = player:GetAttribute("ReduceMotion") == true

    local center = base.Position + Vector3.new(0, base.Size.Y * 0.5 + 0.12, 0)
    local maxRadius = math.max(base.Size.X, base.Size.Z) * 0.78

    local ringCount = tier.Name == "Low" and 1 or (tier.Name == "Medium" and 2 or 3)
    for i = 1, ringCount do
        task.delay((i - 1) * 0.10, function()
            if token ~= revealToken or not arena.Parent then
                return
            end

            local ring = Instance.new("Part")
            ring.Name = "LocalArenaRevealRing"
            ring.Shape = Enum.PartType.Cylinder
            ring.Size = Vector3.new(0.06, reducedMotion and maxRadius * 0.72 or 2.0, reducedMotion and maxRadius * 0.72 or 2.0)
            ring.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
            ring.Anchored = true
            ring.CanCollide = false
            ring.CanTouch = false
            ring.CanQuery = false
            ring.CastShadow = false
            ring.Material = Enum.Material.Neon
            ring.Color = i % 2 == 0 and theme.Secondary or theme.Accent
            ring.Transparency = reducedMotion and 0.72 or 0.30
            ring.Parent = workspace

            local targetSize = reducedMotion
                and ring.Size
                or Vector3.new(0.06, maxRadius * (0.78 + i * 0.08), maxRadius * (0.78 + i * 0.08))
            TweenService:Create(
                ring,
                TweenInfo.new(reducedMotion and 0.35 or 0.62, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Size = targetSize,
                    Transparency = 1,
                }
            ):Play()
            Debris:AddItem(ring, 0.9)
        end)
    end

    if tier.Name ~= "Low" then
        local flash = Instance.new("Part")
        flash.Name = "LocalArenaRevealCore"
        flash.Shape = Enum.PartType.Cylinder
        flash.Size = Vector3.new(0.04, maxRadius * 0.28, maxRadius * 0.28)
        flash.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
        flash.Anchored = true
        flash.CanCollide = false
        flash.CanTouch = false
        flash.CanQuery = false
        flash.CastShadow = false
        flash.Material = Enum.Material.Neon
        flash.Color = theme.Accent
        flash.Transparency = 0.66
        flash.Parent = workspace

        TweenService:Create(
            flash,
            TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = Vector3.new(0.04, maxRadius * 0.48, maxRadius * 0.48),
                Transparency = 1,
            }
        ):Play()
        Debris:AddItem(flash, 0.6)
    end

    spawnVariantSignature(variant, center, base, theme, tier, reducedMotion)
end

local function bindGeneratedMap(root)
    local arena = root:FindFirstChild("Arena")
    if arena then
        task.delay(0.12, revealArena, arena)
    end

    root.ChildAdded:Connect(function(child)
        if child.Name == "Arena" then
            task.delay(0.12, revealArena, child)
        end
    end)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(bindGeneratedMap, child)
    end
end)

local existing = workspace:FindFirstChild("GeneratedMap")
if existing then
    task.defer(bindGeneratedMap, existing)
end
