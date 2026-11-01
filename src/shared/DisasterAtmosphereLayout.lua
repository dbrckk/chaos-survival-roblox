-- Pure transform/layout rules for client-only event atmosphere.
-- Every position is authored in the arena's local deck coordinates.
local DisasterAtmosphereLayout = {}
-- In the published Roblox place this is a sibling ModuleScript. Lest
-- loads source modules by path and does not provide their script Instance.
local DisasterCosmeticRules = if script and script.Parent
    then require(script.Parent.DisasterCosmeticRules)
    else require("./DisasterCosmeticRules")

function DisasterAtmosphereLayout.point(baseFrame, baseSize, angle, radius, height)
    if typeof(baseFrame) ~= "CFrame" or typeof(baseSize) ~= "Vector3"
        or type(angle) ~= "number" or type(radius) ~= "number"
        or type(height) ~= "number" then
        return nil
    end
    local localHeight = baseSize.Y * 0.5 + height
    return baseFrame:PointToWorldSpace(Vector3.new(
        math.cos(angle) * radius, localHeight, math.sin(angle) * radius
    ))
end

-- These authored perimeter accents must follow the *current* collision
-- footprint. ShrinkingArena changes Base.Size continuously during a round.
-- A static radius causes visible beacons and shafts to float outside the
-- playable floor once Double Chaos contracts the arena.
function DisasterAtmosphereLayout.perimeterRadius(baseSize, multiple)
    if typeof(baseSize) ~= "Vector3" then return nil end
    local factor = multiple == nil and 0.52 or multiple
    if type(factor) ~= "number" or factor <= 0
        or factor ~= factor or factor == math.huge then
        return nil
    end
    return math.max(baseSize.X, baseSize.Z) * factor
end

-- A global radius based on max(X, Z) cuts through the short edges on
-- rectangular floors and points at the interior on diagonal bearings.
-- Intersect the ray with the CURRENT rectangular Base footprint instead.
-- The default 0.52 leaves a tiny 4% buffer beyond the collision edge,
-- preserving the original cardinal placement on a square arena.
function DisasterAtmosphereLayout.edgeRadius(baseSize, angle, multiple)
    if typeof(baseSize) ~= "Vector3"
        or type(angle) ~= "number" or angle ~= angle
        or math.abs(angle) == math.huge
        or baseSize.X <= 0 or baseSize.Z <= 0 then
        return nil
    end
    local factor = multiple == nil and 0.52 or multiple
    if type(factor) ~= "number" or factor <= 0
        or factor ~= factor or math.abs(factor) == math.huge then
        return nil
    end
    local cosA, sinA = math.abs(math.cos(angle)), math.abs(math.sin(angle))
    local xLimit = cosA > 1e-6 and baseSize.X * factor / cosA or math.huge
    local zLimit = sinA > 1e-6 and baseSize.Z * factor / sinA or math.huge
    return math.min(xLimit, zLimit)
end

function DisasterAtmosphereLayout.beaconFrame(baseFrame, baseSize, angle)
    local radius = DisasterAtmosphereLayout.edgeRadius(baseSize, angle)
    if not radius then return nil end
    local position = DisasterAtmosphereLayout.point(
        baseFrame, baseSize, angle, radius, 0.8
    )
    if not position then return nil end
    return CFrame.fromMatrix(
        position, baseFrame.RightVector, baseFrame.UpVector,
        -baseFrame.LookVector
    )
end

function DisasterAtmosphereLayout.orbitalCoreFrame(baseFrame)
    if typeof(baseFrame) ~= "CFrame" then return nil end
    -- Keep the reactor aura aligned to the deck normal when tilted.
    return baseFrame * CFrame.new(0, 13, 0)
end

function DisasterAtmosphereLayout.beamFrame(baseFrame, baseSize, angle, radius, height)
    local position = DisasterAtmosphereLayout.point(
        baseFrame, baseSize, angle, radius, height * 0.5 + 4
    )
    if not position then return nil end
    return CFrame.fromMatrix(position,
        baseFrame.RightVector, baseFrame.UpVector, -baseFrame.LookVector)
end

-- No GPU objects exist in the lobby or between catastrophe phases.
-- Dormant polling is deliberately slower, while active High/Medium/Low
-- retains the original exact per-tier animation cadence.
function DisasterAtmosphereLayout.updateCadence(active, interval)
    if active ~= true then return 0.50 end
    if type(interval) == "number" and interval > 0
        and interval == interval and interval < math.huge then
        return interval
    end
    return 1 / 30
end

-- Scenery LOD owns visibility on weaker devices. Its hidden attributes
-- are authoritative for the local cosmetic scene; physics and server
-- telegraphs never call this function.
function DisasterAtmosphereLayout.shouldAnimate(part)
    return typeof(part) == "Instance" and part:IsA("BasePart")
        and part.Parent ~= nil
        and part:GetAttribute("SceneryLodHidden") ~= true
end

-- This is optional *arena atmosphere*, not an authoritative
-- Meteor/Bomb warning or a damage zone. A crowded Double Chaos phase
-- should not stack a full single-disaster ambience on top of every
-- other cosmetic controller. A missing count preserves old callers.
function DisasterAtmosphereLayout.beaconCount(tier, active, simultaneous)
    if active ~= true then return 0 end
    local count = tonumber(simultaneous) or 1
    if count ~= count or count < 0 or count == math.huge then count = 1 end
    if tier == "Low" then return 4 end
    if tier == "Medium" then return count >= 2 and 4 or 6 end
    if tier == "High" then
        return count >= 3 and 4 or (count >= 2 and 6 or 8)
    end
    return 0
end

-- Keep final-rush contrast while preventing the full 1.45x emitter spike
-- from multiplying across several simultaneous hazard identities. Other
-- owners (actual warning rings, impact decals, route cues) are untouched.
function DisasterAtmosphereLayout.particleMultiplier(simultaneous, finalRush)
    local count = tonumber(simultaneous) or 1
    if count ~= count or count < 0 or count == math.huge then count = 1 end
    if finalRush == true then
        -- Preserve the existing authored final-rush contrast ratios.
        if count >= 3 then return 0.80 end
        if count >= 2 then return 1.00 end
        return 1.45
    end
    -- A single shared pressure table now constrains this ambient renderer
    -- and the Lava/Freeze optional emitters simultaneously.
    return DisasterCosmeticRules.pressureMultiplier(count)
end

return DisasterAtmosphereLayout
