-- Shared source-only light calibration for all five arena identities.
-- Rendering identity lives in arena-lighting; active disaster visuals are
-- owned by juice. This module only supplies bounded numbers, no Instances,
-- new loops, GPU lights, texture uploads or RemoteEvents.
local Rules = {}

local TIERS = {
    Low = {
        ambientScale = 0.84, exposureScale = 0.80,
        readyDiffuse = 0.56, roundDiffuse = 0.53,
        readySpecular = 0.56, roundSpecular = 0.54,
        darknessReady = 0.33, darknessRound = 0.26,
        darknessSpecular = 0.40,
    },
    Medium = {
        ambientScale = 0.94, exposureScale = 1.00,
        readyDiffuse = 0.54, roundDiffuse = 0.51,
        readySpecular = 0.65, roundSpecular = 0.63,
        darknessReady = 0.31, darknessRound = 0.25,
        darknessSpecular = 0.43,
    },
    High = {
        ambientScale = 1.00, exposureScale = 1.00,
        readyDiffuse = 0.52, roundDiffuse = 0.49,
        readySpecular = 0.72, roundSpecular = 0.70,
        darknessReady = 0.30, darknessRound = 0.24,
        darknessSpecular = 0.48,
    },
}
local function tier(name)
    return TIERS[name] or TIERS.Medium
end

function Rules.identityScale(qualityName)
    local config = tier(qualityName)
    return config.ambientScale, config.exposureScale
end

-- Darkness is an intentional low-visibility challenge. Do not brighten
-- ANY active Darkness, including when it is the SECOND disaster in a
-- Double Chaos round. Preserve the hazard-owned ColorCorrection brightness
-- and cinematic blackout transitions completely.
function Rules.hasDarkness(disasterIds)
    if type(disasterIds) ~= "table" then return false end
    for index = 1, 2 do
        if disasterIds[index] == "Darkness" then return true end
    end
    return false
end

-- The historical disaster controller forced EnvironmentDiffuseScale=0.34
-- for every active round regardless of mobile quality, undoing the five
-- authored daylight profiles while the player was actually trying to
-- navigate. This is a single shared Lighting property, not an extra lamp.
-- Returns nil outside ready/round so the identity controller owns rest.
function Rules.disasterLighting(phase, qualityName, doubleChaos, disasterIds)
    if phase ~= "ready" and phase ~= "round" then return nil end
    local config = tier(qualityName)
    local darkness = Rules.hasDarkness(disasterIds)
    local round = phase == "round"
    local diffuse, specular

    if darkness then
        diffuse = round and config.darknessRound or config.darknessReady
        specular = config.darknessSpecular
    else
        diffuse = round and config.roundDiffuse or config.readyDiffuse
        specular = round and config.roundSpecular or config.readySpecular
        if doubleChaos == true and round then
            -- Slightly darker two-hazard material response without
            -- forcing every steel face back to almost-black.
            diffuse -= 0.025
        end
    end

    local exposure = round and (doubleChaos == true and -0.04 or 0.02)
        or 0.04
    return exposure, diffuse, specular, darkness
end

return Rules
