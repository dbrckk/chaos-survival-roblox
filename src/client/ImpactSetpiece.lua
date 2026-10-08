-- Distinct cinematic impact accents. Does not spawn permanent geometry
-- or edit server-owned world parts; the entire local bundle auto-cleans.
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Rules resolve at first spawn in the live Rojo place; cloud engine specs
-- can inject the same shared rules module without requiring global scripts.

local ImpactSetpiece = {}

function ImpactSetpiece.spawn(parent, payload, qualityTier, reduceMotion, rulesOverride)
    if type(payload) ~= "table"
        or typeof(payload.position) ~= "Vector3"
        or typeof(payload.color) ~= "Color3"
    then
        return nil
    end

    local rules = rulesOverride or require(ReplicatedStorage.Shared.ImpactSetpieceRules)
    local recipe = rules.get(payload.kind, qualityTier, reduceMotion, payload.radius)
    if not recipe then
        return nil
    end

    local container = Instance.new("Folder")
    container.Name = "ImpactSignature_" .. recipe.Kind
    container.Parent = parent

    for index = 1, recipe.Count do
        local fragment = rules.fragment(recipe.Kind, index, recipe.Count, recipe.Radius)
        local direction = fragment.Direction
        local yaw = math.atan2(direction.X, direction.Z)
        local start = payload.position
            + direction * fragment.StartRadius
            + Vector3.new(0, 0.28, 0)
        local finish = payload.position
            + direction * fragment.EndRadius
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
        part.Material = recipe.Kind == "Meteor"
            and Enum.Material.Glass
            or Enum.Material.Neon
        part.Color = recipe.Kind == "Meteor"
            and payload.color:Lerp(Color3.fromRGB(255, 242, 176), recipe.ColorMix)
            or payload.color:Lerp(Color3.fromRGB(255, 246, 246), recipe.ColorMix)
        part.Transparency = recipe.Kind == "Meteor" and 0.12 or 0.22
        part.Size = recipe.Kind == "Meteor"
            and Vector3.new(fragment.Width, fragment.Length, fragment.Width * 1.8)
            or Vector3.new(fragment.Width, 0.08, fragment.Length * 0.50)
        local rotation = CFrame.Angles(0, yaw, recipe.Kind == "Meteor" and math.rad(24) or 0)
        part.CFrame = CFrame.new(start) * rotation
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
                CFrame = CFrame.new(finish) * rotation,
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
            and payload.color:Lerp(Color3.fromRGB(48, 40, 35), 0.70)
            or payload.color:Lerp(Color3.fromRGB(145, 139, 145), 0.56)
        piece.Transparency = meteor and 0.11 or 0.18
        piece.Size = meteor
            and Vector3.new(finish.Width, finish.Height, finish.Width * 0.75)
            or Vector3.new(finish.Width, 0.15, 0.25)
        local angle = finish.Angle
        local rotation = CFrame.Angles(0, -angle, meteor and math.rad(20) or 0)
        local start = payload.position + finish.Direction * finish.StartRadius
            + Vector3.new(0, meteor and finish.Height * 0.5 or 0.16, 0)
        local goal = payload.position + finish.Direction * finish.EndRadius
            + Vector3.new(0, finish.Lift, 0)
        piece.CFrame = CFrame.new(start) * rotation
        piece.Parent = container
        TweenService:Create(
            piece,
            TweenInfo.new(recipe.Lifetime * (meteor and 0.85 or 0.72),
                Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                CFrame = CFrame.new(goal) * rotation,
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
