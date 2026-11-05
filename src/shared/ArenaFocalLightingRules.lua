local ArenaFocalLightingRules = {}

ArenaFocalLightingRules.Definitions = {
    Classic = {
        {Offset = Vector3.new(0, 15, -1.15), Role = "Accent", Range = 54, Angle = 58, Intensity = 1.00},
        {Offset = Vector3.new(-0.92, 9, 0.25), Role = "Secondary", Range = 44, Angle = 50, Intensity = 0.64},
        {Offset = Vector3.new(0.78, 11, 0.78), Role = "Detail", Range = 42, Angle = 48, Intensity = 0.46},
    },
    Towers = {
        {Offset = Vector3.new(1.18, 24, 0.0), Role = "Accent", Range = 58, Angle = 46, Intensity = 1.00},
        {Offset = Vector3.new(-0.82, 18, 0.74), Role = "Secondary", Range = 48, Angle = 42, Intensity = 0.58},
        {Offset = Vector3.new(0.34, 28, -0.92), Role = "Detail", Range = 52, Angle = 44, Intensity = 0.40},
    },
    Crossroads = {
        {Offset = Vector3.new(0, 12, 1.18), Role = "Accent", Range = 56, Angle = 62, Intensity = 1.00},
        {Offset = Vector3.new(-1.10, 8, -0.18), Role = "Secondary", Range = 50, Angle = 56, Intensity = 0.62},
        {Offset = Vector3.new(0.92, 9, -0.72), Role = "Detail", Range = 46, Angle = 52, Intensity = 0.44},
    },
    Orbital = {
        {Offset = Vector3.new(-1.18, 14, 0), Role = "Accent", Range = 54, Angle = 56, Intensity = 1.00},
        {Offset = Vector3.new(0.62, 16, -0.92), Role = "Secondary", Range = 48, Angle = 48, Intensity = 0.60},
        {Offset = Vector3.new(0.82, 11, 0.74), Role = "Detail", Range = 46, Angle = 50, Intensity = 0.42},
    },
    -- Storm Harbor floodlamps illuminate its actual storm-signal gantry,
    -- cargo-yard edges and docks; never reuse Classic's broadcast pylons.
    -- Same two Medium / three High source budget as the other arenas.
    Harbor = {
        {Offset = Vector3.new(0, 19, 1.14), Role = "Detail", Range = 58, Angle = 52, Intensity = 0.78},
        {Offset = Vector3.new(-0.93, 12, -0.48), Role = "Secondary", Range = 49, Angle = 48, Intensity = 0.56},
        {Offset = Vector3.new(0.94, 15, 0.28), Role = "Accent", Range = 49, Angle = 46, Intensity = 0.42},
    },
}

-- One exact local-space spotlight transform shared by initial build and
-- an existing floor shrinking/tilting. Return nil for malformed inputs.
-- No hidden server movement, raycasts, or separate animation scheduler.
function ArenaFocalLightingRules.anchorFrame(baseFrame, baseSize, definition)
    if typeof(baseFrame) ~= "CFrame" or typeof(baseSize) ~= "Vector3"
        or type(definition) ~= "table"
        or typeof(definition.Offset) ~= "Vector3"
        or baseSize.X <= 0 or baseSize.Z <= 0 then
        return nil
    end
    local offset = definition.Offset
    local halfX, halfZ = baseSize.X * 0.5, baseSize.Z * 0.5
    -- Legacy positions placed fixtures beyond the 320-stud arena edge
    -- (normalized offsets up to +/-1.18), while their 42-58-stud lights
    -- aimed more than 100 studs toward the centre: the cone ended before
    -- reaching the target. Keep housings IN the authored arena and aim
    -- directly at illuminated routes, without allocating extra lights.
    local clampedX = math.clamp(offset.X, -1, 1)
    local clampedZ = math.clamp(offset.Z, -1, 1)
    local destinationLocal = Vector3.new(
        clampedX * halfX * 0.42, 4.0,
        clampedZ * halfZ * 0.42
    )
    local proposed = Vector3.new(
        clampedX * halfX * 0.62, offset.Y,
        clampedZ * halfZ * 0.62
    )
    -- Huge arenas must not break the beam: reserve 28% of the physical
    -- SpotLight.Range for the cone's ground coverage, not merely the
    -- distance from fixture to the aimed point. Preserve vertical height.
    local range = math.clamp(tonumber(definition.Range) or 48, 8, 80)
    local vertical = proposed.Y - destinationLocal.Y
    local maxHorizontal = math.sqrt(math.max(
        0, (range * 0.72)^2 - vertical^2
    ))
    local horizontal = Vector3.new(
        proposed.X - destinationLocal.X, 0,
        proposed.Z - destinationLocal.Z
    )
    local horizontalLength = horizontal.Magnitude
    if horizontalLength > maxHorizontal and horizontalLength > 0 then
        local factor = maxHorizontal / horizontalLength
        proposed = Vector3.new(
            destinationLocal.X + horizontal.X * factor,
            proposed.Y,
            destinationLocal.Z + horizontal.Z * factor
        )
    end
    local position = baseFrame:PointToWorldSpace(proposed)
    local destination = baseFrame:PointToWorldSpace(destinationLocal)
    if (destination - position).Magnitude < 0.01 then return nil end
    return CFrame.lookAt(position, destination, baseFrame.UpVector)
end

function ArenaFocalLightingRules.sourceCount(tierName)
    local tier = tostring(tierName or "Medium")
    if tier == "Low" then
        return 0
    elseif tier == "High" then
        return 3
    end
    return 2
end

-- Visually ground every focal spotlight in real architectural hardware.
-- The Low tier disables the spotlight and housing together.
function ArenaFocalLightingRules.fixtureParts(tierName)
    if tierName == "Low" then return 0 end
    if tierName == "High" then return 2 end
    return 1
end

function ArenaFocalLightingRules.phaseScale(phase, finalRush, disasters)
    local state = tostring(phase or "waiting")
    if state == "ready" then
        -- The original two/three architectural beams act as a soft
        -- approach light over the safe route, not a white flood.
        return 0.78
    elseif state == "round" then
        -- Final rush is NOT itself a blackout. Preserve enough physical
        -- route light to read a 3D bridge and its landing while moving.
        -- Actual Darkness remains deliberately dim, including when it is
        -- the secondary disaster in Double Chaos.
        if finalRush == true then
            if type(disasters) == "table" then
                for _, id in ipairs(disasters) do
                    if id == "Darkness" then return 0.08 end
                end
            end
            return 0.24
        end
        return 0.40
    elseif state == "result" then
        return 0.42
    end
    return 0
end

-- The RoundState transport updates seconds every tick; no focal light
-- properties depend on seconds. Ignore identical visual snapshots instead
-- of allocating overlapping SpotLight tweens on every timer update.
function ArenaFocalLightingRules.visualStateChanged(
    previousPhase, previousFinalRush, previousDisasters,
    nextPhase, nextFinalRush, nextDisasters
)
    if previousPhase ~= nextPhase or previousFinalRush ~= nextFinalRush then
        return true
    end
    local oldIds = type(previousDisasters) == "table" and previousDisasters or {}
    local newIds = type(nextDisasters) == "table" and nextDisasters or {}
    if #oldIds ~= #newIds then
        return true
    end
    for index = 1, #newIds do
        if oldIds[index] ~= newIds[index] then
            return true
        end
    end
    return false
end

function ArenaFocalLightingRules.definitions(variant)
    return ArenaFocalLightingRules.Definitions[tostring(variant or "Classic")]
        or ArenaFocalLightingRules.Definitions.Classic
end

return ArenaFocalLightingRules
