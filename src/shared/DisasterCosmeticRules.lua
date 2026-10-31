-- Pure, client-only disaster decoration policy for Lua/Lest tests.
-- Does not affect server-authoritative hazards, collisions or damage.
local DisasterCosmeticRules = {}

-- Shared pressure for OPTIONAL ambient emitters. The physical warning
-- footprint, damage zones, player escape cues and server hazards are never
-- gated by this multiplier. Existing two-argument callers default to 1.
function DisasterCosmeticRules.pressureMultiplier(simultaneous)
    local count = tonumber(simultaneous) or 1
    if count ~= count or math.abs(count) == math.huge or count < 1 then
        count = 1
    end
    if count >= 3 then return 0.70 end
    if count >= 2 then return 0.85 end
    return 1
end

-- Tornado fragments are decorative and separate from the amber wind
-- boundary. Share the same Double Chaos pressure as optional particles,
-- but keep a recognizable minimum silhouette on weaker devices.
function DisasterCosmeticRules.tornadoDebrisCount(tier, reducedMotion, simultaneous)
    local base = tier == "High" and 12
        or (tier == "Medium" and 8 or (tier == "Low" and 5 or 0))
    if base == 0 then return 0 end
    if reducedMotion == true then base = math.min(base, 5) end
    local amount = math.floor(base
        * DisasterCosmeticRules.pressureMultiplier(simultaneous) + 0.5)
    return math.max(3, math.min(base, amount))
end

function DisasterCosmeticRules.lavaEmberRate(particleScale, reducedMotion, simultaneous)
    local scale = math.max(0, tonumber(particleScale) or 0)
    return 10 * scale * (reducedMotion == true and 0.35 or 1)
        * DisasterCosmeticRules.pressureMultiplier(simultaneous)
end

function DisasterCosmeticRules.freezeMistRate(particleScale, reducedMotion, simultaneous)
    if reducedMotion == true then return 0 end
    return 8 * math.max(0, tonumber(particleScale) or 0)
        * DisasterCosmeticRules.pressureMultiplier(simultaneous)
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
