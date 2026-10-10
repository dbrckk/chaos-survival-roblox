-- Pure, client-only disaster decoration policy for Lua/Lest tests.
-- Does not affect server-authoritative hazards, collisions or damage.
local DisasterCosmeticRules = {}

function DisasterCosmeticRules.lavaEmberRate(particleScale, reducedMotion)
    local scale = math.max(0, tonumber(particleScale) or 0)
    return 10 * scale * (reducedMotion == true and 0.35 or 1)
end

function DisasterCosmeticRules.freezeMistRate(particleScale, reducedMotion)
    if reducedMotion == true then return 0 end
    return 8 * math.max(0, tonumber(particleScale) or 0)
end

-- Quality switches reuse the same cosmetic lava instances. A destroyed
-- child forces a rebuild, including when a new server lava host appears.
function DisasterCosmeticRules.reusableLava(state, lava)
    return state ~= nil and lava ~= nil and state.lava == lava
        and state.surface ~= nil and state.surface.Parent ~= nil
        and state.embers ~= nil and state.embers.Parent ~= nil
        and state.light ~= nil and state.light.Parent ~= nil
end

return DisasterCosmeticRules
