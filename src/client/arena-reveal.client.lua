local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local revealToken = 0

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
