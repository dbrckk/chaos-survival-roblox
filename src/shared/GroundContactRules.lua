-- Pure rules for grounded character landing VFX. Built-in Roblox landing
-- and material-adjusted audio remain authoritative; these add no sounds.
local GroundContactRules = {}

function GroundContactRules.eligible(phase, human, participant, eliminated, ai)
    if phase ~= "round" then return false end
    if human then
        return participant == true and eliminated ~= true
    end
    return ai == true
end

function GroundContactRules.pieceBudget(tier, reduced, finalRush, localCharacter)
    if not localCharacter and finalRush then return 0 end
    if tier == "Low" or reduced == true then
        return localCharacter and 1 or 0
    end
    if tier == "Medium" then
        return localCharacter and 4 or 3
    elseif tier == "High" then
        return localCharacter and 6 or 4
    end
    return 0
end

function GroundContactRules.maxDistance(tier)
    if tier == "High" then return 90 end
    if tier == "Medium" then return 58 end
    return 24
end

function GroundContactRules.minAirtime(tier)
    return tier == "Low" and 0.65 or 0.34
end

function GroundContactRules.cooldownReady(now, previous)
    return type(now) == "number" and now - (tonumber(previous) or -math.huge) >= 0.64
end

function GroundContactRules.materialStyle(material)
    if material == Enum.Material.Ice or material == Enum.Material.Glass then
        return "Crystal"
    elseif material == Enum.Material.Slate or material == Enum.Material.Concrete
        or material == Enum.Material.CorrodedMetal
    then
        return "Mineral"
    elseif material == Enum.Material.Metal
        or material == Enum.Material.DiamondPlate
    then
        return "Mechanical"
    end
    return "Neutral"
end

function GroundContactRules.landingAudio(material, airtime, tierName, reducedMotion)
    local t = tonumber(airtime)
    if not t or t < 0.55 then return nil end
    -- The default Roblox Landing sound is already present, so this is
    -- deliberately a faint low-frequency impact rather than a second footstep.
    local style = GroundContactRules.materialStyle(material)
    local accents = {
        Mechanical = -0.32,
        Mineral = -0.45,
        Crystal = 0.11,
        Neutral = -0.18,
    }
    local volume = math.clamp(0.075 + (t - 0.55) * 0.075, 0.075, 0.18)
    if tierName == "Low" or reducedMotion == true then
        volume *= 0.75
    end
    return {
        VolumeScale = volume,
        PitchOffset = accents[style],
        Style = style,
    }
end

function GroundContactRules.concurrentLimit(tier)
    if tier == "High" then return 30 end
    if tier == "Medium" then return 18 end
    return 6
end

return GroundContactRules
