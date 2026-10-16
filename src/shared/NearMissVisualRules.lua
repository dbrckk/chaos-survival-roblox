-- Pure cosmetic presentation decisions. No gameplay or damage changes.
local NearMissVisualRules = {}

local NORMAL = {Animate = true, WorldPulse = true, EdgeFlash = true}
local REDUCED = {Animate = false, WorldPulse = false, EdgeFlash = false}

function NearMissVisualRules.profile(reducedMotion)
    return reducedMotion == true and REDUCED or NORMAL
end

return NearMissVisualRules
