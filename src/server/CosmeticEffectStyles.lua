--!strict
-- Original cosmetic silhouettes with one Trail or one ParticleEmitter per
-- equipped item. No accessory meshes, render loops, gameplay buffs or
-- paywalled advantage. All particle rates stay capped for shared Android play.
local CosmeticEffectStyles = {}

local defaultTrailWidth = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.76),
    NumberSequenceKeypoint.new(0.58, 0.46),
    NumberSequenceKeypoint.new(1, 0),
})
local defaultTrailFade = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.16),
    NumberSequenceKeypoint.new(0.58, 0.36),
    NumberSequenceKeypoint.new(1, 1),
})

local trailStyles = {
    Meteorflare = {
        Lifetime = 0.52,
        LightEmission = 0.92,
        WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.58),
            NumberSequenceKeypoint.new(0.16, 1.04),
            NumberSequenceKeypoint.new(0.43, 0.68),
            NumberSequenceKeypoint.new(0.73, 0.23),
            NumberSequenceKeypoint.new(1, 0),
        }),
    },
    Shardstep = {
        Lifetime = 0.40,
        LightEmission = 0.88,
        WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.85),
            NumberSequenceKeypoint.new(0.22, 0.43),
            NumberSequenceKeypoint.new(0.45, 0.78),
            NumberSequenceKeypoint.new(0.68, 0.25),
            NumberSequenceKeypoint.new(1, 0),
        }),
    },
    Thunderline = {
        Lifetime = 0.32,
        LightEmission = 1,
        WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.45),
            NumberSequenceKeypoint.new(0.18, 0.82),
            NumberSequenceKeypoint.new(0.35, 0.12),
            NumberSequenceKeypoint.new(0.56, 0.65),
            NumberSequenceKeypoint.new(0.78, 0.10),
            NumberSequenceKeypoint.new(1, 0),
        }),
    },
    Stargazer = {
        Lifetime = 0.62,
        LightEmission = 0.84,
        WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.38),
            NumberSequenceKeypoint.new(0.14, 0.70),
            NumberSequenceKeypoint.new(0.45, 0.53),
            NumberSequenceKeypoint.new(0.76, 0.26),
            NumberSequenceKeypoint.new(1, 0),
        }),
    },
}

local defaultAuraSize = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.28),
    NumberSequenceKeypoint.new(0.45, 0.16),
    NumberSequenceKeypoint.new(1, 0),
})

local auraStyles = {
    Stormglass = {
        Rate = 13,
        Lifetime = NumberRange.new(0.80, 1.22),
        Speed = NumberRange.new(0.45, 1.1),
        Drag = 2.4,
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(0.35, 0.31),
            NumberSequenceKeypoint.new(0.75, 0.13),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Brightness = 0.88,
    },
    Voidwake = {
        Rate = 13,
        Lifetime = NumberRange.new(1.12, 1.62),
        Speed = NumberRange.new(0.25, 0.90),
        Drag = 3,
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.25),
            NumberSequenceKeypoint.new(0.44, 0.39),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Brightness = 0.67,
    },
    CoreMonarch = {
        Rate = 19,
        Lifetime = NumberRange.new(0.38, 0.76),
        Speed = NumberRange.new(1.1, 2.5),
        Drag = 1.4,
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.33),
            NumberSequenceKeypoint.new(0.24, 0.24),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Brightness = 1.04,
    },
    Parallax = {
        Rate = 17,
        Lifetime = NumberRange.new(0.60, 1.06),
        Speed = NumberRange.new(0.65, 1.6),
        Drag = 2.3,
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.20),
            NumberSequenceKeypoint.new(0.53, 0.34),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Brightness = 0.96,
    },
}

local function validColor(color)
    return typeof(color) == "Color3"
end

function CosmeticEffectStyles.trail(item)
    if type(item) ~= "table"
        or not validColor(item.ColorA) or not validColor(item.ColorB) then
        return nil
    end
    local signature = tostring(item.Signature or "")
    local style = trailStyles[signature] or {}
    local sequence = if signature == "Meteorflare" then
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 250, 224)),
            ColorSequenceKeypoint.new(0.22, item.ColorB),
            ColorSequenceKeypoint.new(0.57, item.ColorA),
            ColorSequenceKeypoint.new(1, item.ColorA:Lerp(Color3.fromRGB(61, 30, 42), 0.48)),
        })
        elseif signature == "Shardstep" then
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, item.ColorB),
            ColorSequenceKeypoint.new(0.32, item.ColorA),
            ColorSequenceKeypoint.new(0.62, item.ColorB),
            ColorSequenceKeypoint.new(1, item.ColorA),
        })
        elseif signature == "Thunderline" then
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, item.ColorB),
            ColorSequenceKeypoint.new(0.27, item.ColorA),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(232, 252, 255)),
            ColorSequenceKeypoint.new(0.77, item.ColorA),
            ColorSequenceKeypoint.new(1, item.ColorB),
        })
        elseif signature == "Stargazer" then
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 251, 255)),
            ColorSequenceKeypoint.new(0.30, item.ColorB),
            ColorSequenceKeypoint.new(0.70, item.ColorA),
            ColorSequenceKeypoint.new(1, item.ColorA:Lerp(Color3.fromRGB(48, 35, 100), 0.47)),
        })
        else ColorSequence.new(item.ColorA, item.ColorB)

    return {
        Lifetime = style.Lifetime or 0.48,
        LightEmission = style.LightEmission or 0.78,
        WidthScale = style.WidthScale or defaultTrailWidth,
        Transparency = defaultTrailFade,
        Color = sequence,
    }
end

function CosmeticEffectStyles.aura(item)
    if type(item) ~= "table"
        or not validColor(item.ColorA) or not validColor(item.ColorB) then
        return nil
    end
    local signature = tostring(item.Signature or "")
    local style = auraStyles[signature] or {}
    local color = if signature ~= "" and style.Rate then
        ColorSequence.new({
            ColorSequenceKeypoint.new(0, item.ColorB),
            ColorSequenceKeypoint.new(0.40, item.ColorA),
            ColorSequenceKeypoint.new(1, item.ColorB:Lerp(Color3.fromRGB(18, 27, 57), 0.33)),
        })
        else ColorSequence.new(item.ColorA, item.ColorB)

    return {
        Rate = style.Rate or 18,
        Lifetime = style.Lifetime or NumberRange.new(0.45, 0.9),
        Speed = style.Speed or NumberRange.new(0.6, 1.8),
        Drag = style.Drag or 2,
        Size = style.Size or defaultAuraSize,
        Brightness = style.Brightness or 0.85,
        Color = color,
    }
end

return CosmeticEffectStyles
