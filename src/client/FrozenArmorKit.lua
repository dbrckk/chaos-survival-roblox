-- One-shot client-side frost armor when the local contestant is frozen.
-- Cosmetic wedges are welded to an existing torso; no physics, damage,
-- particles, lights, heartbeat/render loop or replicated instances.
local FrozenArmorKit = {}

local COUNTS = {Low = 1, Medium = 3, High = 5}

function FrozenArmorKit.count(tier, reducedMotion)
    local count = COUNTS[tostring(tier or "")] or 0
    return reducedMotion == true and math.min(count, 1) or count
end

-- Sculpted patches on the FRONT and SIDES of an avatar torso.
-- Coordinates are normalized to the actual R6/R15 torso dimensions.
local PATCHES = {
    {x = 0, y = 0.03, z = -1, pitch = 18, yaw = -14, roll = -24},
    {x = -0.36, y = 0.24, z = -0.9, pitch = -9, yaw = -38, roll = 24},
    {x = 0.37, y = 0.22, z = -0.9, pitch = 14, yaw = 37, roll = -27},
    {x = -0.50, y = -0.22, z = 0.25, pitch = 28, yaw = -67, roll = 15},
    {x = 0.48, y = -0.20, z = 0.37, pitch = -26, yaw = 65, roll = -12},
}

local COLORS = {
    Color3.fromRGB(169, 229, 245),
    Color3.fromRGB(121, 205, 244),
    Color3.fromRGB(210, 247, 255),
    Color3.fromRGB(83, 178, 221),
    Color3.fromRGB(149, 217, 246),
}

function FrozenArmorKit.build(character, tier, reducedMotion)
    local pieces = {}
    if typeof(character) ~= "Instance" or not character:IsA("Model")
        or not character.Parent then
        return pieces
    end
    local torso = character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
    if not torso or not torso:IsA("BasePart") then return pieces end

    local count = FrozenArmorKit.count(tier, reducedMotion)
    local size = torso.Size
    for index = 1, count do
        local patch = PATCHES[index]
        local width = size.X * (index == 1 and 0.31 or 0.23)
        local height = size.Y * (index == 1 and 0.45 or 0.36)
        local depth = math.max(0.11, size.Z * 0.16)
        local transform = CFrame.new(
            size.X * patch.x,
            size.Y * patch.y,
            size.Z * patch.z * 0.53
        ) * CFrame.Angles(
            math.rad(patch.pitch), math.rad(patch.yaw), math.rad(patch.roll)
        )

        local shard = Instance.new("WedgePart")
        shard.Name = "LocalFreezeArmorFacet" .. index
        shard.Size = Vector3.new(width, height, depth)
        shard.CFrame = torso.CFrame * transform
        shard.Material = index == 3 and Enum.Material.Glass
            or Enum.Material.Ice
        shard.Color = COLORS[index]
        shard.Transparency = index == 3 and 0.26 or 0.12
        shard.Anchored = false
        shard.Massless = true
        shard.CanCollide = false
        shard.CanTouch = false
        shard.CanQuery = false
        shard.CastShadow = false
        shard.Parent = torso

        local weld = Instance.new("WeldConstraint")
        weld.Name = "LocalFreezeArmorWeld"
        weld.Part0 = torso
        weld.Part1 = shard
        weld.Parent = shard
        pieces[#pieces + 1] = shard
    end
    return pieces
end

function FrozenArmorKit.clear(pieces)
    if type(pieces) ~= "table" then return end
    for _, piece in ipairs(pieces) do
        if piece then piece:Destroy() end
    end
end

return FrozenArmorKit
