--!strict
-- Scheduling and visibility gates for client-owned landmark animation.
-- No gameplay, physics, remote traffic or new scene instances.
local HeroMotionBudgetRules = {}

local MOTION = {Low = 0.18, Medium = 0.62, High = 1}
local INTERVAL = {Low = 0.16, Medium = 0.09, High = 0.055}

function HeroMotionBudgetRules.motionScale(tier, reduceMotion)
    if reduceMotion == true then
        return 0
    end
    return MOTION[tier] or MOTION.Low
end

function HeroMotionBudgetRules.interval(tier, reduceMotion, hasTracked)
    if hasTracked ~= true then
        -- New scenery is still picked up by ChildAdded and the scan timer.
        return 0.50
    end
    if reduceMotion == true then
        -- Static hazard tint can update slowly; all continuous motion stops.
        return 0.24
    end
    return INTERVAL[tier] or INTERVAL.Low
end

function HeroMotionBudgetRules.shouldUpdate(part)
    return part ~= nil and part.Parent ~= nil
        and part:GetAttribute("SceneryLodHidden") ~= true
end

return HeroMotionBudgetRules
