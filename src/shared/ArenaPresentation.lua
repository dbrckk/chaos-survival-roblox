local ArenaPresentation = {}

local function planar(vector)
    return Vector3.new(vector.X, 0, vector.Z)
end

function ArenaPresentation.lookTarget(variantId, spawnPosition, arenaCenter)
    local variant = tostring(variantId or "Classic")
    local center = typeof(arenaCenter) == "Vector3" and arenaCenter or Vector3.zero
    local spawn = typeof(spawnPosition) == "Vector3" and spawnPosition or center
    local radial = planar(spawn - center)

    if radial.Magnitude < 0.001 then
        radial = Vector3.new(0, 0, 1)
    else
        radial = radial.Unit
    end

    if variant == "Towers" then
        return center + Vector3.new(0, 12, 0) - radial * 5
    elseif variant == "Crossroads" then
        local axis
        if math.abs(radial.X) > math.abs(radial.Z) then
            axis = Vector3.new(-math.sign(radial.X), 0, 0)
        else
            axis = Vector3.new(0, 0, -math.sign(radial.Z))
        end
        return spawn + axis * 34 + Vector3.new(0, 5, 0)
    elseif variant == "Orbital" then
        local tangent = Vector3.new(-radial.Z, 0, radial.X)
        local inward = -radial
        return spawn + tangent * 26 + inward * 11 + Vector3.new(0, 6, 0)
    end

    return center + Vector3.new(0, 6, 0)
end

-- MapBuilder authors the opaque ArenaDeckInset with its center 0.08
-- studs above the physical top and thickness 0.14 studs. Markings
-- underneath its upper face never render (especially on mobile).
-- The small extra clearance prevents z-fighting without collision.
-- This rule is shared by the navigation hub and Low-tier surface plates.
function ArenaPresentation.deckArtOffset(base, thickness)
    if not base or not base:IsA("BasePart") then return nil end
    local halfThickness = math.max(0.005, (tonumber(thickness) or 0.05) * 0.5)
    return base.Size.Y * 0.5 + 0.08 + 0.07 + halfThickness + 0.012
end

function ArenaPresentation.spawnCFrame(variantId, spawnPosition, arenaCenter)
    local spawn = typeof(spawnPosition) == "Vector3" and spawnPosition or Vector3.zero
    local target = ArenaPresentation.lookTarget(variantId, spawn, arenaCenter)
    local flatTarget = Vector3.new(target.X, spawn.Y, target.Z)

    if (flatTarget - spawn).Magnitude < 0.001 then
        flatTarget = spawn + Vector3.new(0, 0, -1)
    end

    return CFrame.lookAt(spawn, flatTarget)
end

return ArenaPresentation
