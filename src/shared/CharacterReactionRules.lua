-- Pure gating and device budgets for the short-lived character FX layer.
-- Visual-only; no ragdoll, health, physics impulse, camera or Animator edits.
local CharacterReactionRules = {}

local function finite(value)
    return type(value) == "number" and value == value
        and math.abs(value) ~= math.huge
end

-- Remote impact coordinates must not consume a cooldown or create FX
-- when malformed or implausibly far outside a playable Roblox world.
function CharacterReactionRules.validPosition(position)
    return typeof(position) == "Vector3"
        and finite(position.X) and finite(position.Y) and finite(position.Z)
        and math.abs(position.X) <= 1e7
        and math.abs(position.Y) <= 1e7
        and math.abs(position.Z) <= 1e7
end

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

-- Only living, active round entrants receive reaction VFX. Human
-- spectator/lobby avatars must not be treated as contestants after respawn.
function CharacterReactionRules.humanEligible(participant, eliminated)
    return participant == true and eliminated ~= true
end

function CharacterReactionRules.isLandingTransition(state)
    return state == Enum.HumanoidStateType.Landed
        or state == Enum.HumanoidStateType.Running
        or state == Enum.HumanoidStateType.RunningNoPhysics
end

function CharacterReactionRules.cooldownReady(now, last, cooldown)
    local time = tonumber(now)
    if not finite(time) then
        return false
    end
    local previous = tonumber(last)
    if not previous or previous ~= previous then
        previous = -math.huge
    end
    local delay = tonumber(cooldown)
    if not finite(delay) then
        delay = 0
    end
    return time - previous >= math.max(0, delay)
end

function CharacterReactionRules.dodgeStrength(distance, radius)
    local r = tonumber(radius)
    local d = tonumber(distance)
    if not finite(r) or r <= 0 or not finite(d) or d < 0 then
        return 0
    end
    -- Replicates the existing near-miss HUD's intensity envelope.
    return math.clamp(1.35 - d / r, 0.25, 1)
end

function CharacterReactionRules.airShockStrength(distance, radius)
    local requestedRadius = tonumber(radius)
    if radius ~= nil and not finite(requestedRadius) then
        return 0
    end
    local r = math.clamp(requestedRadius or 8, 1, 40)
    local d = tonumber(distance)
    if not finite(d) or d < r * 0.92 or d > r * 2.25 then
        return 0
    end
    return math.clamp(1 - (d - r * 0.92) / (r * 1.33), 0, 1)
end

function CharacterReactionRules.landingStrength(airtime)
    local t = tonumber(airtime)
    if not finite(t) or t < 0.68 then
        return 0
    end
    return math.clamp((t - 0.50) / 1.25, 0.16, 1)
end

return CharacterReactionRules
