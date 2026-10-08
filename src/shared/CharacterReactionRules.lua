-- Pure gating and device budgets for the short-lived character FX layer.
-- Visual-only; no ragdoll, health, physics impulse, camera or Animator edits.
local CharacterReactionRules = {}

local TIERS = {
    Low = {Dodge = 0, Shock = 0, Landing = 0, MaxReactors = 0, Range = 0},
    Medium = {Dodge = 2, Shock = 1, Landing = 1, MaxReactors = 2, Range = 64},
    High = {Dodge = 3, Shock = 2, Landing = 2, MaxReactors = 3, Range = 90},
}

function CharacterReactionRules.profile(tierName, reducedMotion)
    if reducedMotion == true then
        return TIERS.Low
    end
    return TIERS[tierName] or TIERS.Low
end

function CharacterReactionRules.isActive(phase, alive)
    return phase == "round" and (tonumber(alive) or 0) > 0
end

function CharacterReactionRules.cooldownReady(now, last, cooldown)
    local time = tonumber(now)
    if not time then
        return false
    end
    return time - (tonumber(last) or -math.huge)
        >= math.max(0, tonumber(cooldown) or 0)
end

function CharacterReactionRules.dodgeStrength(distance, radius)
    local r = tonumber(radius)
    local d = tonumber(distance)
    if not r or r <= 0 or not d or d < 0 then
        return 0
    end
    -- Replicates the existing near-miss HUD's intensity envelope.
    return math.clamp(1.35 - d / r, 0.25, 1)
end

function CharacterReactionRules.airShockStrength(distance, radius)
    local r = math.clamp(tonumber(radius) or 8, 1, 40)
    local d = tonumber(distance)
    if not d or d < r * 0.92 or d > r * 2.25 then
        return 0
    end
    return math.clamp(1 - (d - r * 0.92) / (r * 1.33), 0, 1)
end

function CharacterReactionRules.landingStrength(airtime)
    local t = tonumber(airtime)
    if not t or t < 0.68 then
        return 0
    end
    return math.clamp((t - 0.50) / 1.25, 0.16, 1)
end

return CharacterReactionRules
