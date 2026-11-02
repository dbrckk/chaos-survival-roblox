-- Bounded cosmetic crane motion for the existing four creator-owned
-- Harbor gantries. The real playable platforms and hazards never move.
local HarborGantryMotionRules = {}

function HarborGantryMotionRules.profile(tier, reduceMotion)
    if reduceMotion == true or tier == "Low" then
        return {Interval = 0.65, Count = 0, Range = 0}
    end
    if tier == "Medium" then
        -- Maximum two nearby cranes, no new models or light sources.
        return {Interval = 0.24, Count = 2, Range = 330}
    end
    -- High: all four cranes; at most one additional ship radar part.
    return {Interval = 0.12, Count = 4, Range = 420}
end

function HarborGantryMotionRules.role(name, vessel)
    if type(name) ~= "string" then return nil end
    if vessel then
        return name == "RadarBoom" and "radar" or nil
    end
    if name == "TrolleyCabin" or name == "CabinWindow"
        or name == "TrolleyDriveHousing" then
        return "trolley"
    end
    if name == "HoistCable" then return "cable" end
    if name == "CargoSpreader" or name:sub(1, 10) == "CargoSling"
        or name:sub(1, 9) == "Container"
        or name == "CableDrum"
        or name:sub(1, 14) == "DrumArmorPlate" then
        return "load"
    end
    return nil
end

-- Crane drive translates the cabin and suspended cargo along the ACTUAL
-- track. Hoist lift shortens the cable from its bottom, keeping the
-- attachment point fixed under the moving trolley.
function HarborGantryMotionRules.pose(clock, slot, fade)
    local time = tonumber(clock) or 0
    local index = math.clamp(math.floor(tonumber(slot) or 1), 1, 4)
    local blend = math.clamp(tonumber(fade) or 0, 0, 1)
    if time ~= time or math.abs(time) == math.huge then time = 0 end
    local drive = math.sin(time * 0.24 + index * 1.36) * 4.7 * blend
    local hoist = (1 + math.sin(time * 0.46 + index * 1.53))
        * 1.35 * blend
    return drive, hoist
end

function HarborGantryMotionRules.radarAngle(clock, fade)
    local time = tonumber(clock) or 0
    if time ~= time or math.abs(time) == math.huge then return 0 end
    return math.sin(time * 0.30)
        * math.rad(58) * math.clamp(tonumber(fade) or 0, 0, 1)
end

return HarborGantryMotionRules
