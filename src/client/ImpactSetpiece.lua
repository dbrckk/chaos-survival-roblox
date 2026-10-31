-- Distinct cinematic impact accents. Does not spawn permanent geometry
-- or edit server-owned world parts; the entire local bundle auto-cleans.
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Rules resolve at first spawn in the live Rojo place; cloud engine specs
-- can inject the same shared rules module without requiring global scripts.

local ImpactSetpiece = {}

function ImpactSetpiece.spawn(parent, payload, qualityTier, reduceMotion, rulesOverride)
    -- Reject incomplete event data *before* resolving Shared modules. Lest
    -- engine shards intentionally load this file outside its live Rojo tree.
    -- This cheap guard also avoids module lookups for corrupt network events.
    if typeof(parent) ~= "Instance" or type(payload) ~= "table"
        or typeof(payload.position) ~= "Vector3"
        or typeof(payload.color) ~= "Color3" then
        return nil
    end
    local rules = rulesOverride or require(ReplicatedStorage.Shared.ImpactSetpieceRules)
    if not rules.validPayload(payload) then return nil end
    local recipe = rules.get(payload.kind, qualityTier, reduceMotion, payload.radius)
    if not recipe then
        return nil
    end

    -- The impact-feedback owner has already raycast the true collision
    -- surface. Use its surface-aligned frame for shrapnel and crater lips
    -- on tilted, rotated or sloping platforms. The optional fields retain
    -- compatibility with existing callers and engine specs.
    local groundFrame = typeof(payload.surfaceFrame) == "CFrame"
        and payload.surfaceFrame or CFrame.new(payload.position)
    local groundColor = typeof(payload.surfaceColor) == "Color3"
        and payload.surfaceColor or Color3.fromRGB(106, 101, 95)
    local groundMaterial = typeof(payload.surfaceMaterial) == "EnumItem"
        and payload.surfaceMaterial.EnumType == Enum.Material
        and payload.surfaceMaterial or Enum.Material.Metal

    local container = Instance.new("Folder")
    container.Name = "ImpactSignature_" .. recipe.Kind
    container.Parent = parent

    for index = 1, recipe.Count do
        local fragment = rules.fragment(recipe.Kind, index, recipe.Count, recipe.Radius)
        local direction = fragment.Direction
        local yaw = math.atan2(direction.X, direction.Z)
        local start = direction * fragment.StartRadius
            + Vector3.new(0, 0.28, 0)
        local finish = direction * fragment.EndRadius
            + Vector3.new(0, fragment.Lift, 0)

        local part = recipe.Kind == "Meteor"
            and Instance.new("WedgePart")
            or Instance.new("Part")
        part.Name = recipe.Prefix .. index
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        -- Shrapnel must read as solid matter, not glowing glass/plastic.
        -- Preserve color-coded impacts; emission belongs to the existing
        -- warning/flash effects rather than collisionless fragments.
        part.Material = recipe.Kind == "Meteor"
            and Enum.Material.Basalt or groundMaterial
        -- Bright impact flash is handled by the existing short-lived
        -- burst/light. Physical shrapnel is dark ejecta or actual chipped
        -- ground, never the same glowing orange-yellow as the explosion.
        part.Color = recipe.Kind == "Meteor"
            and groundColor:Lerp(Color3.fromRGB(58, 49, 44), 0.72)
                :Lerp(payload.color, 0.08)
            or groundColor:Lerp(payload.color, 0.12)
        part.Transparency = recipe.Kind == "Meteor" and 0.06 or 0.16
        part.Size = recipe.Kind == "Meteor"
            and Vector3.new(fragment.Width, fragment.Length, fragment.Width * 1.8)
            or Vector3.new(fragment.Width, 0.08, fragment.Length * 0.50)
        -- Compose authored trajectory, oblique yaw and silhouette bank.
        -- Geometry is still one wedge/part per existing budget slot.
        local rotation = CFrame.Angles(0, yaw + fragment.YawSkew, fragment.Bank)
        part.CFrame = groundFrame * CFrame.new(start) * rotation
        part.Parent = container

        local goalSize = recipe.Kind == "Meteor"
            and Vector3.new(fragment.Width * 0.20, fragment.Length * 0.38, fragment.Width * 0.20)
            or Vector3.new(fragment.Width * 0.50, 0.05, fragment.Length)
        TweenService:Create(
            part,
            TweenInfo.new(
                recipe.Lifetime * 0.84,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            ),
            {
                CFrame = groundFrame * CFrame.new(finish) * rotation,
                Size = goalSize,
                Transparency = 1,
            }
        ):Play()
    end
    -- Faceted crater rubble and tangent pressure-arc hardware deliberately
    -- replace a second generic neon ring. The shapes differ even in grayscale.
    local finishCount = rules.finishCount(recipe.Kind, qualityTier, reduceMotion)
    for index = 1, finishCount do
        local finish = rules.finish(recipe.Kind, index, finishCount, recipe.Radius)
        local meteor = recipe.Kind == "Meteor"
        local piece = meteor and Instance.new("WedgePart") or Instance.new("Part")
        piece.Name = meteor and ("MeteorCraterRim" .. index)
            or ("BombPressureArc" .. index)
        piece.Anchored = true
        piece.CanCollide = false
        piece.CanTouch = false
        piece.CanQuery = false
        piece.CastShadow = false
        piece.Material = meteor and Enum.Material.Slate or Enum.Material.Metal
        piece.Color = meteor
            and groundColor:Lerp(Color3.fromRGB(48, 40, 35), 0.74)
                :Lerp(payload.color, 0.06)
            or groundColor:Lerp(Color3.fromRGB(125, 122, 122), 0.46)
                :Lerp(payload.color, 0.10)
        piece.Transparency = meteor and 0.11 or 0.18
        piece.Size = meteor
            and Vector3.new(finish.Width, finish.Height, finish.Width * 0.75)
            or Vector3.new(finish.Width, 0.15, 0.25)
        local angle = finish.Angle
        local rotation = CFrame.Angles(0, -angle + finish.YawSkew, finish.Bank)
        local start = finish.Direction * finish.StartRadius
            + Vector3.new(0, meteor and finish.Height * 0.5 or 0.16, 0)
        local goal = finish.Direction * finish.EndRadius
            + Vector3.new(0, finish.Lift, 0)
        piece.CFrame = groundFrame * CFrame.new(start) * rotation
        piece.Parent = container
        TweenService:Create(
            piece,
            TweenInfo.new(recipe.Lifetime * (meteor and 0.85 or 0.72),
                Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                CFrame = groundFrame * CFrame.new(goal) * rotation,
                Size = meteor
                    and Vector3.new(finish.Width * 0.62,
                        finish.Height * 0.43, finish.Width * 0.32)
                    or Vector3.new(finish.Width * 1.4, 0.05, 0.18),
                Transparency = 1,
            }
        ):Play()
    end
    Debris:AddItem(container, recipe.Lifetime + 0.12)
    return container
end

return ImpactSetpiece
