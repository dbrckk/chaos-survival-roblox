--!strict
-- Client-only arena ornament animation policy. Keeps static readability when
-- accessibility is enabled and avoids work for scenery hidden by distance LOD.
local ArenaIdentityMotionRules = {}

local SCALE = {Low = 0.38, Medium = 0.68, High = 1}

function ArenaIdentityMotionRules.motionScale(tier, reduceMotion)
    if reduceMotion == true then
        return 0
    end
    return SCALE[tier] or SCALE.Low
end

-- Ornamental motion eases in on state changes rather than snapping to a
-- full-scale pose on the first client frame. Hazard telegraphs are unrelated.
-- Ready sets visual anticipation; round reaches full scale; result calms down.
function ArenaIdentityMotionRules.phaseEnvelope(phase, elapsed, previousIntensity)
    local target = if phase == "round" then 1
        elseif phase == "ready" then 0.68
        elseif phase == "result" then 0.46
        else 0
    if target == 0 or type(elapsed) ~= "number"
        or elapsed ~= elapsed or elapsed < 0 then
        return 0
    end
    local previous = if type(previousIntensity) == "number"
        and previousIntensity == previousIntensity
        then math.clamp(previousIntensity, 0, 1) else 0
    local progress = math.clamp(elapsed / 0.34, 0, 1)
    local ease = progress * progress * (3 - 2 * progress)
    return previous + (target - previous) * ease
end

function ArenaIdentityMotionRules.interval(tier, reduceMotion, active, hasTracked)
    if active ~= true or hasTracked ~= true or reduceMotion == true then
        return 0.60
    end
    return tier == "Low" and 0.16 or 0.09
end

function ArenaIdentityMotionRules.shouldUpdate(part)
    return part ~= nil and part.Parent ~= nil
        and part:GetAttribute("SceneryLodHidden") ~= true
end

-- Only identity pieces should wake the tracking pass when streamed in.
-- The client tracks direct children of Arena.Decor (never hazard hitboxes).
function ArenaIdentityMotionRules.isIdentityPart(variant, name)
    if type(name) ~= "string" then return false end

    if variant == "Classic" then
        return name:match("^GridMarkerGlow[1-4]$") ~= nil
            or name:match("^ClassicBroadcastGlow[1-4]$") ~= nil
    elseif variant == "Towers" then
        return name:match("^TowerBand[1-4]_[1-3]$") ~= nil
            or name:match("^TowerMachineryCap[1-4]$") ~= nil
            or name:match("^TowerAntenna[1-4]$") ~= nil
    elseif variant == "Crossroads" then
        return name:match("^CrossroadGate[1-4]$") ~= nil
            or name:match("^CrossroadSignal[1-4]$") ~= nil
    elseif variant == "Orbital" then
        local crown = name:match("^OrbitalCrown(%d+)$")
        local node = name:match("^OrbitalReactorNode(%d+)$")
        return (crown ~= nil and tonumber(crown) >= 1 and tonumber(crown) <= 12)
            or (node ~= nil and tonumber(node) >= 1 and tonumber(node) <= 8)
    end

    return false
end


-- Small, named, local-space articulation of existing noncolliding decor.
-- Nil means this ornament has no moving joint. All valid offsets are based
-- on the ORIGINAL CFrame, never on the previous animation frame.
function ArenaIdentityMotionRules.ornamentOffset(variant, name, now, index, scale)
    if type(now) ~= "number" or type(index) ~= "number"
        or type(scale) ~= "number" or now ~= now or index ~= index
        or scale ~= scale or math.abs(now) > 1e7
        or math.abs(index) == math.huge or math.abs(scale) == math.huge
        or index < 1 or index > 64 or index % 1 ~= 0 or scale <= 0
        or not ArenaIdentityMotionRules.isIdentityPart(variant, name)
    then return nil end

    local amplitude = math.clamp(scale, 0, 1)
    local cycle = now + index * 0.73
    if variant == "Classic" then
        if name:match("^GridMarkerGlow[1-4]$") then
            return CFrame.new(0, math.sin(cycle * 1.15) * 0.16 * amplitude, 0)
        elseif name:match("^ClassicBroadcastGlow[1-4]$") then
            return CFrame.Angles(0,
                math.sin(cycle * 0.68) * math.rad(4) * amplitude, 0)
        end
    elseif variant == "Towers" then
        if name:match("^TowerBand[1-4]_[1-3]$") then
            return CFrame.Angles(0,
                math.sin(cycle * 0.54) * math.rad(2.6) * amplitude, 0)
        elseif name:match("^TowerMachineryCap[1-4]$") then
            return CFrame.new(0, math.sin(cycle * 0.92) * 0.18 * amplitude, 0)
        elseif name:match("^TowerAntenna[1-4]$") then
            return CFrame.Angles(0, 0,
                math.sin(cycle * 0.73) * math.rad(1.5) * amplitude)
        end
    elseif variant == "Crossroads" then
        if name:match("^CrossroadGate[1-4]$") then
            return CFrame.new(math.sin(cycle * 1.1) * 0.10 * amplitude, 0, 0)
        elseif name:match("^CrossroadSignal[1-4]$") then
            return CFrame.Angles(0, 0,
                math.sin(cycle * 0.90) * math.rad(2.2) * amplitude)
        end
    elseif variant == "Orbital" then
        if name:match("^OrbitalReactorNode%d+$") then
            return CFrame.new(0, math.sin(cycle * 0.81) * 0.12 * amplitude, 0)
        end
    end
    -- Orbital crowns retain their existing motion.
    return nil
end

return ArenaIdentityMotionRules
