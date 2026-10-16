-- Five recognizable disaster intro silhouettes. No full-floor discs,
-- physics, post-processing, screen flash, sound or per-frame updates.
-- Coordinates are relative to the rotated/pitched arena deck.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local DisasterIntroMotionKit = {}

local COUNT = {Low = 2, Medium = 4, High = 6}
local ALLOWED = {freeze = true, blast = true, void = true,
    collapse = true, shock = true}
local PI2 = math.pi * 2

function DisasterIntroMotionKit.count(tier)
    return COUNT[tier] or 0
end

-- A pure recipe makes all five shapes testable without any rendering.
function DisasterIntroMotionKit.recipe(kind, index, count, span)
    if not ALLOWED[kind] or type(index) ~= "number"
        or type(count) ~= "number" or index < 1 or count < 1
        or index > count or count > 6 or count % 1 ~= 0
        or type(span) ~= "number" or span <= 0 then
        return nil
    end
    local full = math.clamp(span, 8, 240)
    local a = (index - 1) * PI2 / count
    local outward = Vector3.new(math.cos(a), 0, math.sin(a))
    local tangent = CFrame.Angles(0, -a - math.pi * 0.5, 0)
    local startRadius, finishRadius, y, length, width
    local spin, wedge, material = 0, false, Enum.Material.Neon
    local secondary = index % 2 == 0

    if kind == "freeze" then
        -- Ice needles grow outward; slim tips remain visible over pale decks.
        startRadius, finishRadius = full * 0.07, full * 0.30
        y, length, width = 0.24, full * 0.14, 0.23
        wedge, material = true, Enum.Material.Glass
        spin = secondary and math.rad(12) or math.rad(-12)
    elseif kind == "blast" then
        -- Explosive paired lateral ribbons, not a screen-covering circular disc.
        startRadius, finishRadius = full * 0.05, full * 0.39
        y, length, width = 0.26 + (index % 2) * 0.10, full * 0.18, 0.27
        spin = secondary and math.rad(-19) or math.rad(19)
    elseif kind == "void" then
        -- Broken contracting perimeter slashes read as darkness closing in.
        startRadius, finishRadius = full * 0.43, full * 0.12
        y, length, width = 0.22, full * 0.22, 0.18
        spin, material = math.rad(18), Enum.Material.Glass
    elseif kind == "collapse" then
        -- Opposed inward-closing edges convey a shrinking safe platform.
        startRadius, finishRadius = full * 0.48, full * 0.24
        y, length, width = 0.20, full * 0.24, 0.32
        spin = math.rad(-10)
    else -- shock
        -- Pointed alternating electric strokes run along two crossing axes.
        startRadius, finishRadius = full * 0.11, full * 0.35
        y, length, width = 0.29 + (index % 2) * 0.09, full * 0.25, 0.14
        spin = secondary and math.rad(-34) or math.rad(34)
    end
    return {
        Kind = kind,
        Wedge = wedge,
        Material = material,
        Start = outward * startRadius + Vector3.new(0, y, 0),
        Finish = outward * finishRadius + Vector3.new(0, y + 0.05, 0),
        Rotation = tangent * CFrame.Angles(0, spin, 0),
        Size = Vector3.new(length, 0.075, width),
        GoalSize = Vector3.new(length * 1.10, 0.045, width * 0.55),
        ColorSecondary = secondary,
        Transparency = kind == "void" and 0.48 or 0.28,
    }
end

function DisasterIntroMotionKit.emit(parent, kind, deckCFrame, span,
        primary, secondary, tier, reduceMotion, duration)
    local result = {}
    local count = DisasterIntroMotionKit.count(tier)
    if not parent or not ALLOWED[kind]
        or typeof(deckCFrame) ~= "CFrame"
        or typeof(primary) ~= "Color3" or typeof(secondary) ~= "Color3"
        or count == 0 or type(span) ~= "number" or span <= 0
        or type(duration) ~= "number" or duration <= 0 then
        return result
    end
    local lifespan = reduceMotion and math.min(duration, 0.22) or duration
    for index = 1, count do
        local design = DisasterIntroMotionKit.recipe(kind, index, count, span)
        local piece = Instance.new(design.Wedge and "WedgePart" or "Part")
        piece.Name = "Chaos" .. kind .. "IntroStroke" .. index
        piece.Size = design.Size
        piece.CFrame = deckCFrame * CFrame.new(
            reduceMotion and design.Finish or design.Start
        ) * design.Rotation
        piece.Material = design.Material
        piece.Color = design.ColorSecondary and secondary or primary
        piece.Transparency = design.Transparency
        piece.Anchored = true
        piece.CanCollide = false
        piece.CanTouch = false
        piece.CanQuery = false
        piece.CastShadow = false
        piece:SetAttribute("ChaosDisasterIntro", kind)
        piece.Parent = parent
        TweenService:Create(
            piece,
            TweenInfo.new(lifespan, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                CFrame = deckCFrame * CFrame.new(design.Finish) * design.Rotation,
                Size = design.GoalSize,
                Transparency = 1,
            }
        ):Play()
        Debris:AddItem(piece, lifespan + 0.1)
        table.insert(result, piece)
    end
    return result
end

return DisasterIntroMotionKit
