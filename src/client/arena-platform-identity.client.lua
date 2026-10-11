local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)
local PlatformFinishKit = require(script.Parent.PlatformFinishKit)

local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "ArenaPlatformIdentityLocal"
folder.Parent = workspace

local function clear()
    folder:ClearAllChildren()
end

local function makePart(name, size, cframe, color, material, transparency, anchorPart)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = anchorPart == nil
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = material or Enum.Material.Metal
    part.Color = color
    part.Transparency = transparency or 0
    part.Parent = folder

    if anchorPart and anchorPart:IsA("BasePart") then
        part.Massless = true
        local weld = Instance.new("WeldConstraint")
        weld.Name = "PlatformIdentityWeld"
        weld.Part0 = part
        weld.Part1 = anchorPart
        weld.Parent = part
    end

    return part
end

local function decorateClassic(platform, index, theme, tier)
    local top = platform.CFrame * CFrame.new(0, platform.Size.Y * 0.5 + 0.075, 0)
    local length = math.max(2.6, math.min(platform.Size.X, platform.Size.Z) * 0.56)
    local transparency = tier.Name == "Low" and 0.68 or 0.46

    makePart(
        "ClassicPlatformAxisA" .. index,
        Vector3.new(length, 0.045, 0.16),
        top,
        index % 2 == 0 and theme.Secondary or theme.Accent,
        Enum.Material.Neon,
        transparency,
        platform
    )

    if tier.Name == "High" then
        makePart(
            "ClassicPlatformAxisB" .. index,
            Vector3.new(0.16, 0.045, length),
            top,
            theme.Detail,
            Enum.Material.Metal,
            0.28,
            platform
        )
    end
end

local function decorateTowers(platform, index, theme, tier)
    local bottom = platform.CFrame * CFrame.new(0, -platform.Size.Y * 0.5 - 0.18, 0)
    local radius = math.max(2.0, math.min(platform.Size.X, platform.Size.Z) * 0.28)

    local core = makePart(
        "TowerPlatformLiftCore" .. index,
        Vector3.new(radius, 0.24, radius),
        bottom,
        index % 2 == 0 and theme.Secondary or theme.Accent,
        tier.Name == "High" and index % 3 == 1 and Enum.Material.Neon or Enum.Material.Metal,
        tier.Name == "High" and index % 3 == 1 and 0.48 or (tier.Name == "Low" and 0.36 or 0.22),
        platform
    )
    core.Shape = Enum.PartType.Cylinder
    core.CFrame = bottom * CFrame.Angles(0, 0, math.rad(90))

    if tier.Name == "High" and platform.Position.Y >= 10 then
        makePart(
            "TowerPlatformBrace" .. index,
            Vector3.new(
                math.max(3.2, platform.Size.X * 0.58),
                0.32,
                math.max(0.7, platform.Size.Z * 0.12)
            ),
            platform.CFrame * CFrame.new(0, -platform.Size.Y * 0.5 - 0.42, 0),
            theme.Structure:Lerp(theme.Detail, 0.20),
            Enum.Material.DiamondPlate,
            0.18,
            platform
        )
    end
end

local function decorateCrossroads(platform, index, theme, tier, arenaCenter)
    local center = platform.CFrame * CFrame.new(0, platform.Size.Y * 0.5 + 0.075, 0)
    local arenaDelta = Vector3.new(
        platform.Position.X - arenaCenter.X,
        0,
        platform.Position.Z - arenaCenter.Z
    )
    local alongX = math.abs(arenaDelta.X) >= math.abs(arenaDelta.Z)
    local length = alongX and platform.Size.X or platform.Size.Z
    local size = alongX
        and Vector3.new(math.max(2.5, length * 0.64), 0.05, 0.24)
        or Vector3.new(0.24, 0.05, math.max(2.5, length * 0.64))

    makePart(
        "CrossroadPlatformLane" .. index,
        size,
        center,
        index % 2 == 0 and theme.Secondary or theme.Accent,
        Enum.Material.Neon,
        tier.Name == "Low" and 0.70 or 0.48,
        platform
    )

    if tier.Name == "High" then
        local capOffset = alongX
            and Vector3.new(0, 0, platform.Size.Z * 0.30)
            or Vector3.new(platform.Size.X * 0.30, 0, 0)
        local capSize = alongX
            and Vector3.new(math.max(2.0, platform.Size.X * 0.34), 0.045, 0.13)
            or Vector3.new(0.13, 0.045, math.max(2.0, platform.Size.Z * 0.34))

        for side = -1, 1, 2 do
            makePart(
                "CrossroadPlatformBranch" .. index .. "_" .. tostring(side),
                capSize,
                center * CFrame.new(
                    capOffset.X * side,
                    0,
                    capOffset.Z * side
                ),
                theme.Detail,
                Enum.Material.Metal,
                0.30,
                platform
            )
        end
    end
end

local function decorateOrbital(platform, index, theme, tier, arenaCenter)
    local radial = Vector3.new(
        platform.Position.X - arenaCenter.X,
        0,
        platform.Position.Z - arenaCenter.Z
    )
    if radial.Magnitude < 0.1 then
        radial = Vector3.new(1, 0, 0)
    else
        radial = radial.Unit
    end

    local tangent = Vector3.new(-radial.Z, 0, radial.X)
    local yaw = math.atan2(-tangent.Z, tangent.X)
    local center = CFrame.new(
        platform.Position + Vector3.new(0, platform.Size.Y * 0.5 + 0.075, 0)
    ) * CFrame.Angles(0, yaw, 0)

    local length = math.max(2.6, math.min(platform.Size.X, platform.Size.Z) * 0.70)
    makePart(
        "OrbitalPlatformTangent" .. index,
        Vector3.new(length, 0.05, 0.22),
        center,
        index % 3 == 0 and theme.Secondary or (index % 2 == 0 and theme.Accent or theme.Detail),
        index % 3 == 0 and Enum.Material.Neon or Enum.Material.Metal,
        index % 3 == 0 and (tier.Name == "Low" and 0.72 or 0.54) or 0.24,
        platform
    )

    if tier.Name ~= "Low" then
        local innerOffset = radial * -math.min(platform.Size.X, platform.Size.Z) * 0.22
        makePart(
            "OrbitalPlatformInnerRail" .. index,
            Vector3.new(length * 0.56, 0.045, 0.12),
            center + innerOffset,
            theme.Detail,
            Enum.Material.Glass,
            tier.Name == "High" and 0.40 or 0.52,
            platform
        )
    end
end

local function rebuild()
    clear()

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local platforms = arena and arena:FindFirstChild("Platforms")
    local base = arena and arena:FindFirstChild("Base")
    if not arena or not platforms or not base or not base:IsA("BasePart") then
        return
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local theme = VisualTheme.arena(variant)
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local index = 0

    for _, platform in ipairs(platforms:GetChildren()) do
        if platform:IsA("BasePart") then
            index += 1
            if tier.Name == "Low" and index % 2 == 0 then
                continue
            end

            PlatformFinishKit.build(folder, platform, variant, tier.Name, theme)

            if variant == "Towers" then
                decorateTowers(platform, index, theme, tier)
            elseif variant == "Crossroads" then
                decorateCrossroads(platform, index, theme, tier, base.Position)
            elseif variant == "Orbital" then
                decorateOrbital(platform, index, theme, tier, base.Position)
            else
                decorateClassic(platform, index, theme, tier)
            end
        end
    end
end

local disconnectBaseWatch = nil
local disconnectPlatformsWatch = nil
local platformsConnection = nil
local platformsRemoveConnection = nil
local watchedPlatforms = nil
local rebuildPending = false

local function scheduleRebuild()
    if rebuildPending then return end
    rebuildPending = true
    task.defer(function()
        rebuildPending = false
        rebuild()
    end)
end

local function watchPlatforms(generated)
    local arena = generated and generated:FindFirstChild("Arena")
    local platforms = arena and arena:FindFirstChild("Platforms")
    if platforms == watchedPlatforms then return end
    if platformsConnection then platformsConnection:Disconnect() end
    if platformsRemoveConnection then platformsRemoveConnection:Disconnect() end
    platformsConnection = nil
    platformsRemoveConnection = nil
    watchedPlatforms = platforms
    if platforms then
        platformsConnection = platforms.ChildAdded:Connect(function(child)
            if child:IsA("BasePart") then scheduleRebuild() end
        end)
        platformsRemoveConnection = platforms.ChildRemoved:Connect(function(child)
            if child:IsA("BasePart") then scheduleRebuild() end
        end)
    end
end

local function bindGeneratedMap(generated)
    if disconnectBaseWatch then disconnectBaseWatch() end
    if disconnectPlatformsWatch then disconnectPlatformsWatch() end
    disconnectBaseWatch = nil
    disconnectPlatformsWatch = nil
    watchPlatforms(nil)
    if generated then
        disconnectBaseWatch = MapVisualReadiness.watch(
            generated, "Arena", "Base", function()
                watchPlatforms(generated)
                scheduleRebuild()
            end
        )
        -- The Platforms folder is not a BasePart. This second watch is used
        -- solely for its ChildAdded/Removed notifications and variant signal.
        disconnectPlatformsWatch = MapVisualReadiness.watch(
            generated, "Arena", "Platforms", function()
                watchPlatforms(generated)
                scheduleRebuild()
            end
        )
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindGeneratedMap(child)
        scheduleRebuild()
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindGeneratedMap(nil)
        clear()
    end
end)

bindGeneratedMap(workspace:FindFirstChild("GeneratedMap"))

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(scheduleRebuild)

rebuild()
