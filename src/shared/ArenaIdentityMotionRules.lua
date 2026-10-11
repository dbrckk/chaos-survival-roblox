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

return ArenaIdentityMotionRules
