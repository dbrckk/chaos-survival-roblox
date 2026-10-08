-- Distinct cinematic impact accents. Does not spawn permanent geometry
-- or edit server-owned world parts; the entire local bundle auto-cleans.
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Rules = require(ReplicatedStorage.Shared.ImpactSetpieceRules)

local ImpactSetpiece = {}

function ImpactSetpiece.spawn(parent, payload, qualityTier, reduceMotion)
    if type(payload) ~= "table"
        or typeof(payload.position) ~= "Vector3"
        or typeof(payload.color) ~= "Color3"
    then
        return nil
    end

    local recipe = Rules.get(payload.kind, qualityTier, reduceMotion, payload.radius)
    if not recipe then
        return nil
    end

    local container = Instance.new("Folder")
    container.Name = "ImpactSignature_" .. recipe.Kind
    container.Parent = parent

    for index = 1, recipe.Count do
        local fragment = Rules.fragment(recipe.Kind, index, recipe.Count, recipe.Radius)
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
    Debris:AddItem(container, recipe.Lifetime + 0.12)
    return container
end

return ImpactSetpiece
