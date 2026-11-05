-- Strictly client-visual ownership for the five already-authored outboard
-- native masses. This does not create 3D assets, colliders or render loops.
-- All source parts originate from ArenaMidgroundMassLocal, never the
-- authoritative Arena.Platforms / hazard parts on the server.
local Rules = {}

local PROFILES = {
    Classic = {
        prefix = "ClassicBroadcastMass",
        attribute = "OriginalMidgroundSkylineIndex",
        count = 4, hasVariant = true,
    },
    Towers = {
        prefix = "TowerCoolingMass",
        attribute = "OriginalTowerCoolingSpireIndex",
        count = 5,
    },
    Crossroads = {
        prefix = "CrossroadsTransitMass",
        attribute = "OriginalMidgroundSkylineIndex",
        count = 4, hasVariant = true,
    },
    Orbital = {
        prefix = "OrbitalStationMass",
        attribute = "OriginalOrbitalStationIndex",
        count = 6,
    },
    Harbor = {
        prefix = "HarborFreightBargeHull",
        attribute = "OriginalHarborMidgroundBargeIndex",
        count = 4,
    },
}

function Rules.index(part, variant)
    local profile = PROFILES[variant]
    if not profile or typeof(part) ~= "Instance"
        or not part:IsA("BasePart")
        or not part.Anchored or part.CanCollide
        or part.CanTouch or part.CanQuery
        or part:GetAttribute("CosmeticOnly") ~= true then
        return nil
    end
    local index = part:GetAttribute(profile.attribute)
    if type(index) ~= "number" or index ~= math.floor(index)
        or index < 1 or index > profile.count then
        return nil
    end
    if profile.hasVariant
        and part:GetAttribute("OriginalMidgroundSkylineVariant") ~= variant then
        return nil
    end
    return index
end

function Rules.anchors(folder, variant)
    local profile = PROFILES[variant]
    local owners = {}
    if not profile or typeof(folder) ~= "Instance"
        or not folder:IsA("Folder") then return owners end
    for i = 1, profile.count do
        local anchor = folder:FindFirstChild(profile.prefix .. i)
        if Rules.index(anchor, variant) == i
            and anchor.Parent == folder then
            owners[i] = anchor
        end
    end
    return owners
end

function Rules.distance(cameraPoint, arenaCenter, anchorPosition)
    if typeof(cameraPoint) ~= "Vector3"
        or typeof(arenaCenter) ~= "Vector3"
        or typeof(anchorPosition) ~= "Vector3" then
        return math.huge
    end
    -- Preserve the old near-CENTER skyline, but when moving toward a
    -- remote 320-stud rim choose each authentic outboard mass's REAL
    -- distance instead of hiding every tower because the center is far.
    -- No increased quality counts or LOD distance thresholds.
    return math.min((cameraPoint - arenaCenter).Magnitude,
        (cameraPoint - anchorPosition).Magnitude)
end

return Rules
