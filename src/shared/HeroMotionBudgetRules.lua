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

-- Authored local-space micro-kinetics for the noncolliding Classic antenna
-- vanes and Crossroads transit signal shutters. Never animate hazard geometry.
function HeroMotionBudgetRules.signatureOffset(role, index, now, scale)
    if role ~= "antenna" and role ~= "signal" then return nil end
    if type(index) ~= "number" or index ~= index
        or index % 1 ~= 0 or index < 1
        or index > (role == "antenna" and 2 or 3)
        or type(now) ~= "number" or now ~= now or math.abs(now) > 1e7
        or type(scale) ~= "number" or scale ~= scale
        or math.abs(scale) == math.huge or scale < 0 then
        return nil
    end
    local strength = math.clamp(scale, 0, 1)
    local cycle = now + index * 0.79
    if role == "antenna" then
        -- Paired left/right broadcast masts counter-sway around their bases.
        local side = index == 1 and -1 or 1
        return CFrame.Angles(0, 0,
            math.sin(cycle * 0.74) * math.rad(1.8) * strength * side)
    end
    -- Small offset/roll evokes an indexed mechanical shutter without
    -- moving the fixed gantry or introducing physical collision.
    local sweep = math.sin(cycle * 1.28)
    return CFrame.new(0, sweep * 0.085 * strength, 0)
        * CFrame.Angles(0, 0, sweep * math.rad(1.1) * strength)
end

-- Two additional original service gestures for existing noncolliding art:
-- the Classic broadcast tally surveys laterally, while Crossroads closure
-- strips perform a phase-staggered mechanical stroke. High and Medium only;
-- Low/ReduceMotion return the exact authored pose. No new Instances.
function HeroMotionBudgetRules.serviceDetailOffset(role, index, now, scale)
    if role ~= "scan" and role ~= "closureBar" then
        return CFrame.identity
    end
    local limit = role == "scan" and 1 or 3
    if type(index) ~= "number" or index ~= index or index % 1 ~= 0
        or index < 1 or index > limit
        or type(now) ~= "number" or now ~= now or now < 0 or now > 1e7
        or type(scale) ~= "number" or scale ~= scale
        or scale < 0 or scale > 1 then
        return CFrame.identity
    end
    local strength = math.clamp(
        (scale - MOTION.Low) / (MOTION.High - MOTION.Low), 0, 1
    )
    if strength == 0 then return CFrame.identity end
    if role == "scan" then
        local sweep = math.sin(now * 0.88 + 0.5) * strength
        local yaw = math.sin(now * 0.51) * math.rad(0.7) * strength
        return CFrame.new(sweep * 0.18, 0, 0) * CFrame.Angles(0, yaw, 0)
    end
    local cycle = now * 1.35 + (index - 1) * (2 * math.pi / 3)
    local stroke = math.sin(cycle) * strength
    return CFrame.new(0, stroke * 0.10, 0)
        * CFrame.Angles(0, 0, stroke * math.rad(0.45))
end

-- Opposing micro-travel for the existing Towers crane counterweight.
-- Same 0.72 Hz-phase as its cable; authored base pose prevents drift.
-- The scene piece is anchored, client-only and never a gameplay collider.
function HeroMotionBudgetRules.craneCounterweightOffset(now, scale)
    if type(now) ~= "number" or now ~= now or now < 0
        or math.abs(now) > 1e7 or type(scale) ~= "number"
        or scale ~= scale or math.abs(scale) == math.huge then
        return CFrame.identity
    end
    local amplitude = math.clamp(scale, 0, 1)
    local wave = math.sin(now * 0.72) * amplitude
    return CFrame.new(-wave * 0.28, 0, 0)
        * CFrame.Angles(0, 0, -wave * math.rad(0.8))
end

-- Slow 3D precession of the existing anchored Orbital reactor sculpture.
-- Low uses the authored static core (no extra CFrame writes); Medium/High
-- move within 0.10 studs and 1.6 degrees. The effective tier amplitude
-- already includes the 480ms stream/LOD/ReduceMotion resume envelope.
function HeroMotionBudgetRules.reactorCoreOffset(now, scale)
    if type(now) ~= "number" or now ~= now or now < 0
        or math.abs(now) > 1e7 or type(scale) ~= "number"
        or scale ~= scale or math.abs(scale) > 1e7 then
        -- Malformed amplitudes must return to rest, never clamp into motion.
        return CFrame.identity
    end
    -- Low=0.18 stays static, and Medium=0.62 and High=1 grow gradually
    -- without exceeding the existing overall tier and accessibility gates.
    local strength = math.clamp((scale - MOTION.Low) / (MOTION.High - MOTION.Low), 0, 1)
    if strength == 0 then return CFrame.identity end
    local rise = math.sin(now * 0.86) * 0.10 * strength
    local pitch = math.sin(now * 0.57 + 0.6) * math.rad(1.6) * strength
    return CFrame.new(0, rise, 0) * CFrame.Angles(pitch, 0, 0)
end

-- Existing asymmetric service silhouettes (Medium/High scenery only).
-- Keep the base of the surveillance antenna fixed; only its slender rod
-- gets a subtle local yaw, composed from its captured CFrame.
function HeroMotionBudgetRules.serviceAntennaOffset(now, scale)
    if type(now) ~= "number" or now ~= now or now < 0
        or math.abs(now) > 1e7 or type(scale) ~= "number"
        or scale ~= scale or math.abs(scale) == math.huge then
        return CFrame.identity
    end
    local amplitude = math.clamp(scale, 0, 1)
    return CFrame.Angles(0,
        math.sin(now * 0.64 + 0.35) * math.rad(1.15) * amplitude, 0)
end

-- Orbital's existing anchored docking pod softly stabilizes against
-- the static service arm. No new part or render loop; Low has no pod.
function HeroMotionBudgetRules.dockingPodOffset(now, scale)
    if type(now) ~= "number" or now ~= now or now < 0
        or now > 1e7 or type(scale) ~= "number" or scale ~= scale
        or scale < 0 or scale > 1 then
        return CFrame.identity
    end
    local lift = math.sin(now * 0.77 + 0.4) * 0.12 * scale
    local bank = math.sin(now * 0.52) * math.rad(1.25) * scale
    return CFrame.new(0, lift, 0) * CFrame.Angles(0, 0, bank)
end

-- Restrained independent light rhythms: Orbital docking rail and three
-- Crossroads closure bars. The "closed" signal remains constantly visible.
-- These are decorative Neon transparencies, not danger telegraphs.
function HeroMotionBudgetRules.servicePulse(role, index, now)
    if role ~= "dockGlow" and role ~= "closureBar" then return 0 end
    if type(index) ~= "number" or index ~= index or index % 1 ~= 0
        or index < 1 or index > (role == "dockGlow" and 1 or 3)
        or type(now) ~= "number" or now ~= now or now < 0
        or math.abs(now) > 1e7 then
        return 0
    end
    local frequency = role == "dockGlow" and 1.15 or 1.35
    return (1 + math.cos(now * frequency
        + (index - 1) * (2 * math.pi / 3))) * 0.5
end

-- Continuous three-phase signal chase, avoiding the former hard on/off
-- jump every 0.42s. Decorative light only; no gameplay telegraph is altered.
function HeroMotionBudgetRules.signalPulse(now, index)
    if type(now) ~= "number" or now ~= now or math.abs(now) > 1e7
        or type(index) ~= "number" or index ~= index
        or index % 1 ~= 0 or index < 1 or index > 3 then
        return 0
    end
    return (1 + math.cos(now * (1.6 * math.pi)
        + (index - 1) * (2 * math.pi / 3))) * 0.5
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

-- Restore hazard tint only on the first quiet frame. Reactor core and
-- transit signal already author a fresh animated Color each update.
-- This avoids continuous no-op property writes on static landmarks.
function HeroMotionBudgetRules.shouldRestoreBaseColor(role, hadReaction)
    return hadReaction == true
        and role ~= "reactorCore" and role ~= "signal"
end

function HeroMotionBudgetRules.shouldUpdate(part)
    return part ~= nil and part.Parent ~= nil
        and part:GetAttribute("SceneryLodHidden") ~= true
end

return HeroMotionBudgetRules
