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

-- Reintroduce original landmark movement from its authored rest pose
-- after accessibility toggles, map streaming or scenery LOD changes.
-- No TweenService objects or additional update loop are needed.
function HeroMotionBudgetRules.resumeEnvelope(elapsed)
    if type(elapsed) ~= "number" or elapsed ~= elapsed
        or math.abs(elapsed) == math.huge or elapsed <= 0 then
        return 0
    end
    local t = math.clamp(elapsed / 0.48, 0, 1)
    return t * t * (3 - 2 * t)
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

-- Static, non-animated hazard accent for ReduceMotion. Keeping it bounded
-- avoids both pulse flicker and loss of disaster identity.
function HeroMotionBudgetRules.staticTint(reaction, reduceMotion)
    if reduceMotion ~= true or type(reaction) ~= "table"
        or reaction.Active ~= true then
        return 0
    end
    local alpha = tonumber(reaction.Tint) or 0
    if alpha ~= alpha or alpha == math.huge or alpha == -math.huge then
        return 0
    end
    return math.clamp(alpha, 0, 0.13)
end

-- Restore a captured client-only monument baseline in one deterministic
-- operation. Invalid or detached instances are never mutated.
function HeroMotionBudgetRules.applyStillPose(part, state, reaction)
    if not part or not part:IsA("BasePart") or not part.Parent
        or type(state) ~= "table"
        or typeof(state.baseCFrame) ~= "CFrame"
        or typeof(state.baseSize) ~= "Vector3"
        or typeof(state.baseColor) ~= "Color3"
        or type(state.baseTransparency) ~= "number" then
        return false
    end
    part.CFrame = state.baseCFrame
    part.Size = state.baseSize
    part.Transparency = state.baseTransparency
    local tint = HeroMotionBudgetRules.staticTint(reaction, true)
    local accent = reaction and typeof(reaction.Accent) == "Color3"
        and reaction.Accent or state.baseColor
    part.Color = state.baseColor:Lerp(accent, tint)
    return true
end

function HeroMotionBudgetRules.reactiveFrame(baseFrame, shift, yaw, bank)
    return baseFrame * CFrame.new(shift) * CFrame.Angles(0, yaw, bank)
end

function HeroMotionBudgetRules.shouldUpdate(part)
    return part ~= nil and part.Parent ~= nil
        and part:GetAttribute("SceneryLodHidden") ~= true
end

return HeroMotionBudgetRules
