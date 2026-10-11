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

-- Each cue has its own 3D silhouette rather than recolored flat strips.
-- This rule is deterministic and retains the existing 2/4-piece budget.
function GroundFx.signature(kind, index, strength, tier)
    if COLORS[kind] == nil or (tier ~= "High" and tier ~= "Medium")
        or type(index) ~= "number" or index % 1 ~= 0 or index < 1
        or index > (tier == "High" and 4 or 2)
    then
        return nil
    end

    local side = index % 2 == 0 and 1 or -1
    local pair = math.floor((index - 1) / 2)
    local intensity = math.clamp(tonumber(strength) or 0, 0, 1)
    local scale = 0.64 + 0.28 * intensity
    if kind == "Skid" then
        -- Industrial brake abrasion: low, paired metallic grooves.
        return {
            Class = "Part",
            Material = Enum.Material.Metal,
            Size = Vector3.new(0.13, 0.045, (2.30 + pair * 0.30) * scale),
            Offset = Vector3.new(side * (0.40 + pair * 0.26), 0.065,
                1.04 + pair * 0.14),
            Yaw = side * math.rad(3),
            Travel = Vector3.new(side * 0.08, 0, side * 0.24),
            Transparency = 0.29 + pair * 0.14,
        }
    elseif kind == "Pivot" then
        -- Radial counter-steer fins: two opposite swept wedges.
        return {
            Class = "WedgePart",
            Material = tier == "High" and pair == 0
                and Enum.Material.Neon or Enum.Material.SmoothPlastic,
            Size = Vector3.new(0.17, 0.085, (1.40 + pair * 0.14) * scale),
            Offset = Vector3.new(side * (0.49 + pair * 0.22), 0.085,
                0.12 + pair * 0.10),
            Yaw = side * math.rad(58),
            Travel = Vector3.new(side * 0.16, 0.01, -side * 0.08),
            Transparency = 0.30 + pair * 0.12,
        }
    end
    -- Acceleration: paired, forward-swept thrust chevrons.
    return {
        Class = "WedgePart",
        Material = tier == "High" and pair == 0
            and Enum.Material.Neon or Enum.Material.SmoothPlastic,
        Size = Vector3.new(0.16, 0.085, (1.24 + pair * 0.20) * scale),
        Offset = Vector3.new(side * (0.38 + pair * 0.23), 0.085,
            0.86 - pair * 0.08),
        Yaw = side * math.rad(24),
        Travel = Vector3.new(side * 0.12, 0.02, side * 0.18),
        Transparency = 0.26 + pair * 0.14,
    }
end

function GroundFx.build(parent, basis, kind, strength, tier)
    if not parent or typeof(basis) ~= "CFrame"
        or COLORS[kind] == nil or (tier ~= "High" and tier ~= "Medium")
    then
        return nil
    end

    local count = tier == "High" and 4 or 2
    local folder = Instance.new("Folder")
    folder.Name = "Chaos" .. kind .. "Contact"
    folder.Parent = parent

    for i = 1, count do
        local design = GroundFx.signature(kind, i, strength, tier)
        local mark = Instance.new(design.Class)
        mark.Name = kind .. (kind == "Skid" and "BrakeScuff"
            or (kind == "Pivot" and "TurnFin" or "ThrustFin")) .. i
        mark.Size = design.Size
        mark.CFrame = basis * CFrame.new(design.Offset)
            * CFrame.Angles(0, design.Yaw, 0)
        mark.Anchored = true
        mark.CanCollide = false
        mark.CanTouch = false
        mark.CanQuery = false
        mark.CastShadow = false
        mark.Color = COLORS[kind]
        mark.Material = design.Material
        mark.Transparency = design.Transparency
        mark.Parent = folder
        TweenService:Create(
            mark,
            TweenInfo.new(0.46, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Transparency = 1,
                Size = Vector3.new(design.Size.X * 0.38, 0.025,
                    design.Size.Z * 1.25),
                CFrame = mark.CFrame * CFrame.new(design.Travel),
            }
        ):Play()
    end
    Debris:AddItem(folder, 0.56)
    return folder
end

-- Slope-safe placement: follow the actual hit normal and project the
-- avatar's heading onto the surface. Only cosmetic basis changes; no force.
function GroundFx.surfaceBasis(position, normal, facing)
    if typeof(position) ~= "Vector3" or typeof(normal) ~= "Vector3"
        or typeof(facing) ~= "Vector3" or normal.Magnitude < 0.01
    then
        return nil
    end
    local up = normal.Unit
    if up.Y < 0.72 then return nil end
    local tangent = facing - up * facing:Dot(up)
    if tangent.Magnitude < 0.1 then return nil end
    return CFrame.lookAt(position, position + tangent.Unit, up)
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
    if not hit then return nil end
    local basis = GroundFx.surfaceBasis(hit.Position, hit.Normal,
        root.CFrame.LookVector)
    if not basis then return nil end
    return GroundFx.build(effectRoot, basis, kind, strength, tier)
end

return GroundFx
