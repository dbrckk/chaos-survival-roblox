-- Server-authoritative, collision-checked human spawn placement.
-- Teleports are only resolved at the beginning of each round. This cannot
-- be invoked by clients and does not give mid-round movement advantages.
local SpawnSafety = {}

local AVATAR_FOOTPRINT = Vector3.new(5.6, 8.4, 5.6)
local CLEARANCE_ABOVE_FLOOR = 0.25
local EDGE_MARGIN = 4.5

local function validArena(arena)
    if typeof(arena) ~= "Instance" or not arena:IsA("Folder") then return nil end
    local base = arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") or not base.CanCollide then
        return nil
    end
    return base
end

local function withinFloor(base, x, z)
    return math.abs(x - base.Position.X) <= base.Size.X * 0.5 - EDGE_MARGIN
        and math.abs(z - base.Position.Z) <= base.Size.Z * 0.5 - EDGE_MARGIN
end

local function isFree(arena, base, x, z, overlap)
    if not withinFloor(base, x, z) then return false end

    local floorTop = base.Position.Y + base.Size.Y * 0.5
    local center = Vector3.new(
        x, floorTop + AVATAR_FOOTPRINT.Y * 0.5 + CLEARANCE_ABOVE_FLOOR, z
    )
    local hits = workspace:GetPartBoundsInBox(
        CFrame.new(center), AVATAR_FOOTPRINT, overlap
    )
    for _, part in ipairs(hits) do
        -- Floor contact is intended. Spawn pads are visual markers, not
        -- platforms; all overhead decks, bridges and future solid props
        -- must be rejected even if they are invisible to the camera.
        if part ~= base and part:IsA("BasePart") and part.CanCollide then
            return false
        end
    end
    return true
end

function SpawnSafety.resolve(arena, marker, humanoid, root)
    local base = validArena(arena)
    if not base or typeof(marker) ~= "Instance"
        or not marker:IsA("BasePart")
        or not humanoid or not humanoid:IsA("Humanoid")
        or not root or not root:IsA("BasePart") then
        return nil, "invalid arena, spawn or character"
    end

    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Include
    overlap.FilterDescendantsInstances = {arena}
    overlap.MaxParts = 0

    local center = base.Position
    local source = marker.Position
    local flat = Vector3.new(source.X - center.X, 0, source.Z - center.Z)
    local radial = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(1, 0, 0)
    local tangent = Vector3.new(-radial.Z, 0, radial.X)

    local candidates = {Vector3.zero}
    -- Bias to the OUTSIDE of overhead corner decks and Orbital platforms.
    -- All points remain inside the walkable base, not on high scaffolding.
    for _, distance in ipairs({8, 13, 19}) do
        table.insert(candidates, radial * distance)
        table.insert(candidates, radial * distance + tangent * 5)
        table.insert(candidates, radial * distance - tangent * 5)
    end
    for _, distance in ipairs({7, 12, 18}) do
        table.insert(candidates, tangent * distance)
        table.insert(candidates, -tangent * distance)
        table.insert(candidates, -radial * distance)
    end
    -- Final bounded grid fallback for future arenas with obstructed markers.
    for radius = 10, 40, 10 do
        for step = 0, 7 do
            local angle = step * (math.pi / 4)
            table.insert(candidates, Vector3.new(
                math.cos(angle) * radius, 0, math.sin(angle) * radius
            ) + center - source)
        end
    end

    local floorTop = base.Position.Y + base.Size.Y * 0.5
    local height = math.max(3.4, humanoid.HipHeight + root.Size.Y * 0.5 + 0.7)
    for index, offset in ipairs(candidates) do
        local x = source.X + offset.X
        local z = source.Z + offset.Z
        if isFree(arena, base, x, z, overlap) then
            local cf = CFrame.new(x, floorTop + height, z) * marker.CFrame.Rotation
            return cf, index
        end
    end
    return nil, "no unobstructed floor-level entry found"
end

function SpawnSafety.clearAt(arena, position)
    local base = validArena(arena)
    if not base or typeof(position) ~= "Vector3" then return false end
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Include
    overlap.FilterDescendantsInstances = {arena}
    overlap.MaxParts = 0
    return isFree(arena, base, position.X, position.Z, overlap)
end

return SpawnSafety
