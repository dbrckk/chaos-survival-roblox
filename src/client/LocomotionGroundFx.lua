-- Tiny ground-level animation accents, triggered only by actual motion
-- impulses from the existing R15 body feel owner.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local GroundFx = {}

-- Register every transient foot-contact piece with the live visual-budget
-- collector rather than parenting the effects directly to workspace.
local effectRoot = Instance.new("Folder")
effectRoot.Name = "LocomotionContactLocal"
effectRoot.Parent = workspace

local COLORS = {
    Launch = Color3.fromRGB(83, 222, 255),
    Skid = Color3.fromRGB(255, 156, 83),
    Pivot = Color3.fromRGB(187, 105, 255),
}

function GroundFx.build(parent, basis, kind, strength, tier)
    if not parent or typeof(basis) ~= "CFrame"
        or COLORS[kind] == nil or (tier ~= "High" and tier ~= "Medium")
    then
        return nil
    end

    local intensity = math.clamp(tonumber(strength) or 0, 0, 1)
    local count = tier == "High" and 4 or 2
    local folder = Instance.new("Folder")
    folder.Name = "Chaos" .. kind .. "Contact"
    folder.Parent = parent

    for i = 1, count do
        local side = i % 2 == 0 and 1 or -1
        local pair = math.floor((i - 1) / 2)
        local width = kind == "Skid" and 0.13 or 0.10
        local length = kind == "Skid" and 2.4
            or (kind == "Pivot" and 1.55 or 1.25)
        local z = kind == "Skid" and (1.05 + pair * 0.29)
            or (kind == "Pivot" and 0.18 or 0.86)
        local x = side * (0.40 + pair * 0.28)
        local twist = kind == "Pivot" and side * math.rad(33)
            or (kind == "Launch" and side * math.rad(16) or 0)
        local mark = Instance.new("Part")
        mark.Name = kind .. "FootTrace" .. i
        mark.Size = Vector3.new(width, 0.035, length * (0.64 + 0.28 * intensity))
        mark.CFrame = basis * CFrame.new(x, 0.065, z)
            * CFrame.Angles(0, twist, 0)
        mark.Anchored = true
        mark.CanCollide = false
        mark.CanTouch = false
        mark.CanQuery = false
        mark.CastShadow = false
        mark.Color = COLORS[kind]
        mark.Material = Enum.Material.Neon
        mark.Transparency = 0.25 + pair * 0.15
        mark.Parent = folder
        TweenService:Create(
            mark,
            TweenInfo.new(0.46, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Transparency = 1,
                Size = Vector3.new(width * 0.35, 0.02, length * 1.25),
                CFrame = mark.CFrame * CFrame.new(0, 0, side * 0.24),
            }
        ):Play()
    end
    Debris:AddItem(folder, 0.56)
    return folder
end

function GroundFx.emit(root, kind, strength, tier)
    if not root or not root:IsA("BasePart") or not root.Parent then
        return nil
    end
    local map = workspace:FindFirstChild("GeneratedMap")
    if not map then
        return nil
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {map}
    params.IgnoreWater = true

    local hit = workspace:Raycast(
        root.Position + Vector3.new(0, 1.4, 0),
        Vector3.new(0, -7.0, 0),
        params
    )
    if not hit or hit.Normal.Y < 0.72 then
        return nil
    end

    local facing = root.CFrame.LookVector
    local flat = Vector3.new(facing.X, 0, facing.Z)
    if flat.Magnitude < 0.1 then
        return nil
    end
    local basis = CFrame.lookAt(hit.Position, hit.Position + flat.Unit)
    return GroundFx.build(effectRoot, basis, kind, strength, tier)
end

return GroundFx
