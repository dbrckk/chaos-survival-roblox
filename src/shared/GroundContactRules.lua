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
        or material == Enum.Material.Foil
    then
        return "Mechanical"
    elseif material == Enum.Material.CeramicTiles
        or material == Enum.Material.Brick
    then
        return "Mineral"
    end
    return "Neutral"
end

local function finite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

-- A quiet, short, deliberately non-repeating takeoff signature. The
-- default Roblox avatar already has a Jump sound, so this is a
-- material-independent accent, NOT a second full-volume jump track.
-- Physics remains exclusively the native Humanoid's responsibility.
function GroundContactRules.takeoffAudio(now, lastPlayed, tierName, reducedMotion)
    if not finite(now) or now < 0 then return nil end
    if finite(lastPlayed) and (now < lastPlayed
        or now - lastPlayed < 0.28) then
        return nil
    end
    local profile = tierName == "Low" and 0.72
        or (tierName == "Medium" and 0.88 or 1)
    if reducedMotion == true then profile *= 0.8 end
    return {
        VolumeScale = 0.48 * profile,
        PitchOffset = -0.06,
    }
end

function GroundContactRules.landingAudio(material, airtime, tierName, reducedMotion)
    local t = tonumber(airtime)
    if not finite(t) or t < 0.40 or t > 8 then return nil end
    -- This is played only after real Freefall -> Landed/Running. The
    -- native avatar's own landing track remains audible; additional
    -- weight is small, transient and surface-dependent, never a
    -- fabricated jump force or looping footstep.
    local style = GroundContactRules.materialStyle(material)
    local accents = {
        Mechanical = -0.24,
        Mineral = -0.41,
        Crystal = 0.08,
        Neutral = -0.12,
    }
    local volume = math.clamp(0.29 + (t - 0.4) * 0.16, 0.29, 0.63)
    if tierName == "Low" then volume *= 0.78
    elseif tierName == "Medium" then volume *= 0.91 end
    if reducedMotion == true then volume *= 0.82 end
    return {
        VolumeScale = volume,
        PitchOffset = accents[style],
        Style = style,
    }
end

-- A spectator must use the actual camera rather than the eliminated
-- avatar left elsewhere in the map. Active third-person players keep the
-- avatar-centered visual range only while the camera follows that avatar.
function GroundContactRules.observerPosition(rootPosition, cameraPosition,
        participantActive, cameraFollowsAvatar)
    if participantActive == true and cameraFollowsAvatar == true
        and typeof(rootPosition) == "Vector3" then
        return rootPosition
    end
    if typeof(cameraPosition) == "Vector3" then
        return cameraPosition
    end
    return nil
end

function GroundContactRules.concurrentLimit(tier)
    if tier == "High" then return 30 end
    if tier == "Medium" then return 18 end
    return 6
end

return GroundContactRules
