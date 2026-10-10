-- Deterministic aerial-survey patrol routes, separate from physical gameplay.
-- The small, tiered cosmetic fleet never grants collision or gameplay credit.
local AerialSurveyRules = {}

AerialSurveyRules.Profiles = {
    Low = {Drones = 1, PartsPerDrone = 6, MaxParts = 6, Interval = 0.60},
    Medium = {Drones = 2, PartsPerDrone = 11, MaxParts = 22, Interval = 0.22},
    High = {Drones = 3, PartsPerDrone = 17, MaxParts = 51, Interval = 0.10},
}

function AerialSurveyRules.profile(tier)
    return AerialSurveyRules.Profiles[tier] or AerialSurveyRules.Profiles.Medium
end

function AerialSurveyRules.animated(phase, tier, reduceMotion)
    return (phase == "ready" or phase == "round")
        and reduceMotion ~= true and tier ~= "Low"
end

function AerialSurveyRules.flightFrame(base, variant, index, count, t)
    if not base or not base:IsA("BasePart") then return nil end
    local drones = math.max(1, math.floor(tonumber(count) or 1))
    local slot = math.clamp(math.floor(tonumber(index) or 1), 1, drones)
    local time = tonumber(t) or 0
    local phase = ((slot - 1) / drones) * math.pi * 2
    local speed = variant == "Orbital" and 0.23
        or (variant == "Towers" and 0.13 or 0.17)
    local angle = phase + time * speed
    local rx = base.Size.X * 0.5 + 44
    local rz = base.Size.Z * 0.5 + 44
    local elevation = variant == "Towers" and 41
        or (variant == "Orbital" and 36
            or (variant == "Crossroads" and 30 or 32))
    local offset = Vector3.new(
        math.cos(angle) * rx,
        elevation + math.sin(time * 0.8 + slot) * math.min(2.5, time * 0.45),
        math.sin(angle) * rz
    )
    -- Fly outside the arena; there is never an apparent landing platform
    -- nor a moving collider over traversable decks.
    local direction = Vector3.new(
        -math.sin(angle) * rx, 0, math.cos(angle) * rz
    ).Unit
    local position = base.CFrame:PointToWorldSpace(offset)
    local bank = math.sin(angle * 1.4) * math.rad(7)
    return CFrame.lookAt(position, position + direction)
        * CFrame.Angles(0, 0, bank)
end

function AerialSurveyRules.alert(phase, disasterIds, finalRush)
    if phase ~= "round" then return "standby" end
    if finalRush == true then return "critical" end
    if type(disasterIds) == "table" and #disasterIds > 0 then
        return "hazard"
    end
    return "patrol"
end

return AerialSurveyRules
