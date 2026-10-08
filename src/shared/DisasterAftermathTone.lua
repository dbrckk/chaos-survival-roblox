-- Post-round color treatment, not active warning lighting. All profiles are
-- kept here so result tint is evaluated consistently for Double Chaos.
local DisasterAftermathTone = {}

DisasterAftermathTone.Profiles = {
    RisingLava = {
        Tint = Color3.fromRGB(255, 205, 170),
        Saturation = -0.04,
        Contrast = 0.035,
        Blur = 0,
    },
    Meteors = {
        Tint = Color3.fromRGB(255, 220, 190),
        Saturation = -0.07,
        Contrast = 0.045,
        Blur = 0.7,
    },
    LowGravity = {
        Tint = Color3.fromRGB(210, 220, 255),
        Saturation = -0.04,
        Contrast = 0.018,
        Blur = 0.35,
    },
    DisappearingPlatforms = {
        Tint = Color3.fromRGB(255, 235, 185),
        Saturation = -0.03,
        Contrast = 0.028,
        Blur = 0.20,
    },
    SpeedSurge = {
        Tint = Color3.fromRGB(255, 205, 245),
        Saturation = -0.02,
        Contrast = 0.035,
        Blur = 0.45,
    },
    Tornado = {
        Tint = Color3.fromRGB(210, 225, 235),
        Saturation = -0.18,
        Contrast = 0.02,
        Blur = 1.2,
    },
    Freeze = {
        Tint = Color3.fromRGB(195, 225, 255),
        Saturation = -0.10,
        Contrast = 0.02,
        Blur = 0.8,
    },
    Bombs = {
        Tint = Color3.fromRGB(255, 215, 185),
        Saturation = -0.08,
        Contrast = 0.05,
        Blur = 0.9,
    },
    Darkness = {
        Tint = Color3.fromRGB(205, 195, 235),
        Saturation = -0.16,
        Contrast = 0.055,
        Blur = 0.5,
    },
    ShrinkingArena = {
        Tint = Color3.fromRGB(255, 210, 225),
        Saturation = -0.06,
        Contrast = 0.035,
        Blur = 0,
    },
    JumpShock = {
        Tint = Color3.fromRGB(220, 210, 255),
        Saturation = -0.03,
        Contrast = 0.025,
        Blur = 0.6,
    },
}

local function blendColor(a, b)
    return Color3.new((a.R + b.R) * 0.5, (a.G + b.G) * 0.5, (a.B + b.B) * 0.5)
end

function DisasterAftermathTone.combine(ids)
    local first = nil
    local second = nil
    for _, id in ipairs(ids or {}) do
        local p = DisasterAftermathTone.Profiles[id]
        if p and not first then
            first = p
        elseif p and first and not second and id ~= ids[1] then
            second = p
            break
        end
    end
    if not first then return nil end
    if not second then
        return {
            Tint = first.Tint,
            Saturation = first.Saturation,
            Contrast = first.Contrast,
            Blur = first.Blur,
        }
    end
    -- Mix hue and exposure without simply doubling glow or blur. Blended
    -- screenshots should show both disaster identities without a white wash.
    return {
        Tint = blendColor(first.Tint, second.Tint),
        Saturation = math.clamp((first.Saturation + second.Saturation) * 0.5, -0.14, 0),
        Contrast = math.clamp((first.Contrast + second.Contrast) * 0.5, 0, 0.055),
        Blur = math.clamp((first.Blur + second.Blur) * 0.42, 0, 1.05),
    }
end

function DisasterAftermathTone.presentation(ids, tier, reduceMotion)
    local profile = DisasterAftermathTone.combine(ids)
    if not profile then return nil end
    local quality = tostring(tier or "Low")
    local scale = quality == "High" and 1
        or (quality == "Medium" and 0.68 or 0.36)
    if reduceMotion then
        scale *= 0.28
    end
    return {
        Tint = Color3.new(1, 1, 1):Lerp(profile.Tint, 0.28 * scale),
        Saturation = profile.Saturation * scale,
        Contrast = profile.Contrast * scale,
        Blur = reduceMotion and 0 or math.min(1.05, profile.Blur * scale),
        Hold = quality == "Low" and 0.45 or 0.85,
        Release = quality == "Low" and 0.45 or 0.9,
    }
end

return DisasterAftermathTone
