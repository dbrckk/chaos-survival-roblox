-- Deterministic disaster-reactive shading for existing arena floor details
-- and focal lights. Never creates geometry, post effects or flashes.
-- The authoritative platform colors, materials and collisions are untouched.
local DisasterVisuals = require(script.Parent.DisasterVisuals)
local ArenaCrisisSurfaceRules = {}

local INTENSITY = {
    RisingLava = 0.86,
    Meteors = 0.90,
    LowGravity = 0.50,
    DisappearingPlatforms = 0.92,
    Tornado = 0.70,
    Freeze = 0.73,
    Bombs = 0.92,
    SpeedSurge = 0.75,
    Darkness = 0.37,
    ShrinkingArena = 0.95,
    JumpShock = 0.92,
}
local SOUND_SHIFT = {
    RisingLava = 0.025, Meteors = 0.040, LowGravity = -0.035,
    DisappearingPlatforms = -0.015, Tornado = -0.025, Freeze = -0.045,
    Bombs = 0.032, SpeedSurge = 0.040, Darkness = -0.050,
    ShrinkingArena = -0.020, JumpShock = 0.025,
}

function ArenaCrisisSurfaceRules.profile(ids, phase, tier, reduced, finalRush)
    local out = {
        Active = false,
        Primary = nil,
        Secondary = nil,
        Energy = 0,
        Wave = 0,
        MaxTint = 0,
        LightTint = 0,
        LightScale = 1,
        PitchShift = 0,
        Static = reduced == true or tier == "Low",
    }
    if phase ~= "round" or type(ids) ~= "table" then return out end
    for _, id in ipairs(ids) do
        local visual = DisasterVisuals.get(id)
        local energy = INTENSITY[id]
        if visual and energy then
            if not out.Primary then
                out.Primary = visual.Accent
            elseif not out.Secondary then
                out.Secondary = visual.Accent
            end
            out.Energy = math.max(out.Energy, energy)
            out.PitchShift += SOUND_SHIFT[id] or 0
            if id == "Darkness" then out.LightScale = math.min(out.LightScale, 0.76) end
            if id == "Freeze" then out.LightScale = math.min(out.LightScale, 0.94) end
        end
        if out.Secondary then break end
    end
    if not out.Primary then return out end
    if out.Secondary then out.PitchShift *= 0.5 end
    out.Active = true
    local tierScale = tier == "High" and 1 or (tier == "Medium" and 0.72 or 0.45)
    out.MaxTint = math.min(0.28, (0.12 + out.Energy * 0.15) * tierScale)
    out.LightTint = math.min(0.20, out.MaxTint * 0.62)
    if reduced == true then
        out.MaxTint *= 0.60
        out.LightTint *= 0.56
    end
    if finalRush == true then
        -- Hazard telegraphs take precedence over decorative floor color.
        out.MaxTint = math.min(out.MaxTint, 0.11)
        out.LightTint = math.min(out.LightTint, 0.08)
        out.LightScale = math.min(out.LightScale, 0.94)
    end
    out.Wave = out.Static and 0 or 0.17 * out.Energy
    return out
end

function ArenaCrisisSurfaceRules.shade(baseColor, material, name, index, profile, clock)
    if typeof(baseColor) ~= "Color3" or not profile or not profile.Active then
        return baseColor
    end
    local neon = material == Enum.Material.Neon
    local textName = tostring(name or "")
    -- Panel seams and structural repairs should remain visually subordinate
    -- to actual shrinking-platform / bomb danger indicators.
    local role = string.find(textName, "Seam", 1, true)
        and 0.35 or (string.find(textName, "Repair", 1, true) and 0.46 or 1)
    local mix = profile.MaxTint * role * (neon and 1 or 0.54)
    local pulse = 1
    if not profile.Static then
        local t = (tonumber(clock) or 0) * 2.15 + (tonumber(index) or 1) * 0.45
        pulse += profile.Wave * math.sin(t)
    end
    local accent = profile.Secondary and (tonumber(index) or 1) % 2 == 0
        and profile.Secondary or profile.Primary
    return baseColor:Lerp(accent, math.clamp(mix * pulse, 0, 0.30))
end

function ArenaCrisisSurfaceRules.light(baseColor, baseBrightness, index, profile)
    if typeof(baseColor) ~= "Color3" then return baseColor, baseBrightness end
    local rawBrightness = math.max(0, tonumber(baseBrightness) or 0)
    if not profile or not profile.Active then return baseColor, rawBrightness end
    local color = profile.Secondary and (tonumber(index) or 1) % 2 == 0
        and profile.Secondary or profile.Primary
    return baseColor:Lerp(color, profile.LightTint),
        rawBrightness * profile.LightScale
end

-- Retunes existing distant spatial ambience by no more than five percent.
-- Does not play an extra sound or alter authoritative disaster cues.
function ArenaCrisisSurfaceRules.audio(basePitch, profile)
    local pitch = tonumber(basePitch) or 1
    if not profile or not profile.Active then return pitch end
    return math.clamp(pitch * (1 + profile.PitchShift), 0.35, 1.40)
end

return ArenaCrisisSurfaceRules
