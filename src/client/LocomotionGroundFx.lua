-- Tiny ground-level animation accents, triggered only by actual motion
-- impulses from the existing R15 body feel owner.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local GroundFx = {}

local function finite(n)
    return type(n) == "number" and n == n and math.abs(n) < math.huge
end

local function finiteVector(v)
    return typeof(v) == "Vector3" and finite(v.X) and finite(v.Y)
        and finite(v.Z)
end

local function finiteFrame(cf)
    return typeof(cf) == "CFrame"
        and finiteVector(cf.Position) and finiteVector(cf.RightVector)
        and finiteVector(cf.UpVector) and finiteVector(cf.LookVector)
end

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

-- Ground tint is computed once per event after the existing raycast. Keep
-- action colors readable; different floor materials leave different tones.
local GROUND_TINTS = {
    [Enum.Material.Ice] = Color3.fromRGB(173, 230, 249),
    [Enum.Material.Snow] = Color3.fromRGB(173, 230, 249),
    [Enum.Material.Glacier] = Color3.fromRGB(173, 230, 249),
    [Enum.Material.Metal] = Color3.fromRGB(198, 217, 228),
    [Enum.Material.DiamondPlate] = Color3.fromRGB(198, 217, 228),
    [Enum.Material.CorrodedMetal] = Color3.fromRGB(175, 171, 161),
    [Enum.Material.Slate] = Color3.fromRGB(124, 128, 147),
    [Enum.Material.Concrete] = Color3.fromRGB(124, 128, 147),
    [Enum.Material.Ground] = Color3.fromRGB(180, 147, 105),
    [Enum.Material.Sand] = Color3.fromRGB(180, 147, 105),
    [Enum.Material.Mud] = Color3.fromRGB(180, 147, 105),
    [Enum.Material.Grass] = Color3.fromRGB(150, 174, 120),
}

function GroundFx.materialAccent(kind, material, floorColor, tier)
    local base = COLORS[kind]
    if not base then return nil end
    local tint = GROUND_TINTS[material]
    if not tint then return base end
    local blend = tier == "High" and 0.32 or 0.22
    local color = base:Lerp(tint, blend)
    if typeof(floorColor) == "Color3"
        and finite(floorColor.R) and finite(floorColor.G)
        and finite(floorColor.B) then
        color = color:Lerp(floorColor, 0.06)
    end
    return color
end

-- Each cue has its own 3D silhouette rather than recolored flat strips.
-- This rule is deterministic and retains the existing 2/4-piece budget.
function GroundFx.signature(kind, index, strength, tier)
    if COLORS[kind] == nil or (tier ~= "High" and tier ~= "Medium")
        or not finite(index) or index % 1 ~= 0 or index < 1
        or index > (tier == "High" and 4 or 2)
        or not finite(strength)
    then
        return nil
    end

    local side = index % 2 == 0 and 1 or -1
    local pair = math.floor((index - 1) / 2)
    local intensity = math.clamp(strength, 0, 1)
    local scale = 0.64 + 0.28 * intensity
    if kind == "Skid" then
        -- Industrial brake abrasion: low, paired metallic grooves.
        return {
            Class = "Part",
            Material = Enum.Material.Metal,
            Size = Vector3.new(0.13, 0.045, (2.30 + pair * 0.30) * scale),
            Offset = Vector3.new(side * (0.40 + pair * 0.26), 0.065,
                1.04 + pair * 0.14),
            Yaw = side * math.rad(3 + pair * 5),
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

-- A single local owner is shared by the human R15 and every AI bot.
-- A scene-wide cap prevents crowded turns from stacking contact geometry.
local MAX_LIVE = {Medium = 8, High = 16}

function GroundFx.livePieceBudget(tier)
    return MAX_LIVE[tier] or 0
end

function GroundFx.evictionCount(existing, arriving, tier)
    local cap = GroundFx.livePieceBudget(tier)
    if cap == 0 then return 0 end
    -- Counters are local but can be malformed during device teardown.
    -- Bound inputs before integer conversion or budget arithmetic.
    local active = tonumber(existing)
    local incoming = tonumber(arriving)
    if not finite(active) then active = 0 end
    if not finite(incoming) then incoming = 0 end
    return math.max(0, math.floor(math.clamp(active, 0, cap * 2))
        + math.floor(math.clamp(incoming, 0, cap * 2)) - cap)
end

local function isOwnedContact(instance)
    if not instance:IsA("Folder") then return false end
    return instance.Name == "ChaosLaunchContact"
        or instance.Name == "ChaosSkidContact"
        or instance.Name == "ChaosPivotContact"
end

local function trimContactBudget(parent, arriving, tier)
    local owned = {}
    local total = 0
    for _, child in ipairs(parent:GetChildren()) do
        if isOwnedContact(child) then
            local count = 0
            for _, part in ipairs(child:GetChildren()) do
                if part:IsA("BasePart") then count += 1 end
            end
            table.insert(owned, {folder = child, count = count})
            total += count
        end
    end

    local excess = GroundFx.evictionCount(total, arriving, tier)
    -- Whole bursts are evicted oldest first. Do not truncate a half-pair,
    -- leaving one-sided pivot/acceleration symbols on the floor.
    for _, entry in ipairs(owned) do
        if excess <= 0 then break end
        entry.folder:Destroy()
        excess -= entry.count
    end
end

function GroundFx.clear()
    effectRoot:ClearAllChildren()
end

function GroundFx.build(parent, basis, kind, strength, tier, material, floorColor)
    if typeof(parent) ~= "Instance" or not finiteFrame(basis)
        or COLORS[kind] == nil or (tier ~= "High" and tier ~= "Medium")
        or not finite(strength)
    then
        return nil
    end

    local count = tier == "High" and 4 or 2
    local accent = GroundFx.materialAccent(kind, material, floorColor, tier)
    trimContactBudget(parent, count, tier)
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
        mark.Color = accent:Lerp(Color3.new(1, 1, 1), i % 2 == 0 and 0.08 or 0)
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
    if not finiteVector(position) or not finiteVector(normal)
        or not finiteVector(facing) or normal.Magnitude < 0.01
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
    local floorColor = hit.Instance:IsA("BasePart")
        and hit.Instance.Color or nil
    return GroundFx.build(effectRoot, basis, kind, strength, tier,
        hit.Material, floorColor)
end

return GroundFx
