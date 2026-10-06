local DisasterVisuals = {}

DisasterVisuals.Profiles = {
    RisingLava = {
        Tint = Color3.fromRGB(255, 184, 125),
        Accent = Color3.fromRGB(255, 85, 0),
        Atmosphere = Color3.fromRGB(255, 170, 105),
        Bloom = 0.72,
        Contrast = 0.15,
        Saturation = 0.24,
        Density = 0.21,
        Haze = 1.05,
        Fov = 77,
    },
    Meteors = {
        Tint = Color3.fromRGB(255, 205, 170),
        Accent = Color3.fromRGB(255, 145, 30),
        Atmosphere = Color3.fromRGB(225, 150, 115),
        Bloom = 0.78,
        Contrast = 0.17,
        Saturation = 0.20,
        Density = 0.20,
        Haze = 1.10,
        Fov = 79,
    },
    LowGravity = {
        Tint = Color3.fromRGB(205, 215, 255),
        Accent = Color3.fromRGB(105, 125, 255),
        Atmosphere = Color3.fromRGB(150, 170, 235),
        Bloom = 0.60,
        Contrast = 0.10,
        Saturation = 0.18,
        Density = 0.18,
        Haze = 0.90,
        Fov = 78,
    },
    DisappearingPlatforms = {
        Tint = Color3.fromRGB(255, 238, 175),
        Accent = Color3.fromRGB(255, 205, 70),
        Atmosphere = Color3.fromRGB(225, 205, 135),
        Bloom = 0.58,
        Contrast = 0.12,
        Saturation = 0.20,
        Density = 0.17,
        Haze = 0.72,
        Fov = 76,
    },
    Tornado = {
        Tint = Color3.fromRGB(190, 235, 235),
        Accent = Color3.fromRGB(80, 210, 215),
        Atmosphere = Color3.fromRGB(135, 185, 190),
        Bloom = 0.55,
        Contrast = 0.13,
        Saturation = 0.10,
        Density = 0.24,
        Haze = 1.35,
        Fov = 80,
    },
    Freeze = {
        Tint = Color3.fromRGB(195, 235, 255),
        Accent = Color3.fromRGB(80, 195, 255),
        Atmosphere = Color3.fromRGB(155, 205, 230),
        Bloom = 0.66,
        Contrast = 0.12,
        Saturation = 0.06,
        Density = 0.19,
        Haze = 0.95,
        Fov = 75,
    },
    Bombs = {
        Tint = Color3.fromRGB(255, 195, 195),
        Accent = Color3.fromRGB(255, 55, 55),
        Atmosphere = Color3.fromRGB(215, 140, 140),
        Bloom = 0.72,
        Contrast = 0.18,
        Saturation = 0.18,
        Density = 0.19,
        Haze = 0.95,
        Fov = 78,
    },
    SpeedSurge = {
        Tint = Color3.fromRGB(255, 195, 245),
        Accent = Color3.fromRGB(255, 75, 205),
        Atmosphere = Color3.fromRGB(215, 130, 205),
        Bloom = 0.70,
        Contrast = 0.15,
        Saturation = 0.26,
        Density = 0.16,
        Haze = 0.72,
        Fov = 83,
    },
    Darkness = {
        Tint = Color3.fromRGB(180, 185, 225),
        Accent = Color3.fromRGB(90, 85, 180),
        Atmosphere = Color3.fromRGB(75, 80, 125),
        Bloom = 0.35,
        Brightness = -0.28,
        Contrast = 0.20,
        Saturation = -0.05,
        Density = 0.25,
        Haze = 1.25,
        Fov = 74,
    },
    ShrinkingArena = {
        Tint = Color3.fromRGB(235, 185, 255),
        Accent = Color3.fromRGB(175, 75, 235),
        Atmosphere = Color3.fromRGB(175, 125, 200),
        Bloom = 0.65,
        Contrast = 0.15,
        Saturation = 0.20,
        Density = 0.19,
        Haze = 0.92,
        Fov = 77,
    },
    JumpShock = {
        Tint = Color3.fromRGB(190, 220, 255),
        Accent = Color3.fromRGB(55, 225, 255),
        Atmosphere = Color3.fromRGB(135, 175, 225),
        Bloom = 0.68,
        Contrast = 0.14,
        Saturation = 0.18,
        Density = 0.17,
        Haze = 0.82,
        Fov = 79,
    },
}

local function mixColor(a, b)
    return Color3.new(
        (a.R + b.R) * 0.5,
        (a.G + b.G) * 0.5,
        (a.B + b.B) * 0.5
    )
end

function DisasterVisuals.get(id)
    return DisasterVisuals.Profiles[id]
end

function DisasterVisuals.combine(ids)
    local first = ids and DisasterVisuals.Profiles[ids[1]]
    if not first then
        return nil
    end

    local second = ids[2] and DisasterVisuals.Profiles[ids[2]]
    if not second then
        return {
            Tint = first.Tint,
            Accent = first.Accent,
            Atmosphere = first.Atmosphere,
            Bloom = first.Bloom,
            Brightness = first.Brightness or 0,
            Contrast = first.Contrast,
            Saturation = first.Saturation,
            Density = first.Density,
            Haze = first.Haze,
            Fov = first.Fov,
        }
    end

    return {
        Tint = mixColor(first.Tint, second.Tint),
        Accent = mixColor(first.Accent, second.Accent),
        Atmosphere = mixColor(first.Atmosphere, second.Atmosphere),
        Bloom = math.min(0.9, (first.Bloom + second.Bloom) * 0.58),
        Brightness = ((first.Brightness or 0) + (second.Brightness or 0)) * 0.5,
        Contrast = math.min(0.22, (first.Contrast + second.Contrast) * 0.62),
        Saturation = math.clamp((first.Saturation + second.Saturation) * 0.58, -0.1, 0.32),
        Density = math.min(0.28, (first.Density + second.Density) * 0.58),
        Haze = math.min(1.5, (first.Haze + second.Haze) * 0.58),
        Fov = math.min(84, math.max(first.Fov, second.Fov) + 2),
    }
end

return DisasterVisuals
