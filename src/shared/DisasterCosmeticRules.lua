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
        and state.attachment ~= nil and state.attachment.Parent == lava
        and state.embers ~= nil and state.embers.Parent == state.attachment
        and state.light ~= nil and state.light.Parent == lava
end

-- Only reuse a warning while every cosmetic child is still correctly parented.
function DisasterCosmeticRules.reusableFreeze(state, warning)
    if state == nil or warning == nil or state.warning ~= warning
        or state.attachment == nil or state.attachment.Parent ~= warning
        or state.mist == nil or state.mist.Parent ~= state.attachment
        or type(state.segments) ~= "table" or #state.segments == 0 then
        return false
    end
    for _, part in ipairs(state.segments) do
        if not part:IsA("WedgePart") or part.Parent == nil then return false end
    end
    return true
end
return DisasterCosmeticRules
