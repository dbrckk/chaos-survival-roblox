-- Two lightweight disaster climax silhouettes in arena-local ground space.
-- Freeze: fractured crystalline wedges; JumpShock: broken discharge strokes.
-- These are presentation only: no hitboxes, server damage, point lights or emitters.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local DisasterClimaxSignatureKit = {}

local COUNTS = {Low = 2, Medium = 4, High = 6}
local ALLOWED = {freeze = true, shock = true}

function DisasterClimaxSignatureKit.count(tier, reduced)
    if reduced == true then return COUNTS[tier] and 1 or 0 end
    return COUNTS[tier] or 0
end

function DisasterClimaxSignatureKit.recipe(kind, index, count, span, stage)
    if not ALLOWED[kind] or type(index) ~= "number"
        or type(count) ~= "number" or count % 1 ~= 0 or count < 1 or count > 6
        or index < 1 or index > count or index % 1 ~= 0
        or type(span) ~= "number" or span <= 0 or span ~= span or span == math.huge
        or type(stage) ~= "number" or stage % 1 ~= 0 or stage < 1 or stage > 3 then
        return nil
    end
    local full = math.clamp(span, 20, 240)
    local angle = (index - 1) * math.pi * 2 / count
        + (kind == "freeze" and 0.16 or 0.37)
    local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
    local y = kind == "freeze" and 0.20 or 0.15
    local startRadius = full * (kind == "freeze" and 0.07 or 0.11)
    local endRadius = full * (
        kind == "freeze" and (0.25 + stage * 0.018)
            or (0.29 + stage * 0.014)
    )
    local secondary = index % 2 == 0
    local rotation = CFrame.Angles(
        0, -angle - math.pi * 0.5 + (secondary and 0.18 or -0.16),
        kind == "freeze" and (secondary and 0.10 or -0.10) or 0
    )
    local length = full * (
        kind == "freeze" and (0.11 + stage * 0.012)
            or (0.14 + stage * 0.012)
    )
    return {
        Kind = kind,
        Wedge = kind == "freeze",
        Material = kind == "freeze" and Enum.Material.Ice or Enum.Material.Neon,
        Start = outward * startRadius + Vector3.new(0, y, 0),
        Finish = outward * endRadius + Vector3.new(0, y + 0.04, 0),
        Rotation = rotation,
        Size = Vector3.new(length * 0.76, kind == "freeze" and 0.13 or 0.075,
            kind == "freeze" and 0.34 or 0.18),
        GoalSize = Vector3.new(length, kind == "freeze" and 0.09 or 0.05,
            kind == "freeze" and 0.18 or 0.10),
        Transparency = kind == "freeze" and 0.36 or 0.30,
        Secondary = secondary,
    }
end

function DisasterClimaxSignatureKit.emit(parent, kind, deckCFrame, span,
        stage, primary, secondary, tier, reduced)
    local count = DisasterClimaxSignatureKit.count(tier, reduced)
    local pieces = {}
    if not parent or not ALLOWED[kind] or typeof(deckCFrame) ~= "CFrame"
        or typeof(primary) ~= "Color3" or typeof(secondary) ~= "Color3"
        or type(span) ~= "number" or span <= 0 or span ~= span or span == math.huge or count <= 0
        or type(stage) ~= "number" or stage % 1 ~= 0 or stage < 1 or stage > 3 then
        return pieces
    end
    local duration = reduced and 0.20 or (
        kind == "freeze" and 0.55 or 0.39
    )
    for index = 1, count do
        local spec = DisasterClimaxSignatureKit.recipe(kind, index, count, span, stage)
        if not spec then break end
        local piece = Instance.new(spec.Wedge and "WedgePart" or "Part")
        piece.Name = (kind == "freeze" and "FreezeCrystalClimax"
            or "ShockDischargeClimax") .. index
        piece.Size = spec.Size
        piece.CFrame = deckCFrame
            * CFrame.new(reduced and spec.Finish or spec.Start) * spec.Rotation
        piece.Anchored = true
        piece.CanCollide = false
        piece.CanTouch = false
        piece.CanQuery = false
        piece.CastShadow = false
        piece.Material = spec.Material
        piece.Color = spec.Secondary and secondary or primary
        piece.Transparency = reduced and 0.58 or spec.Transparency
        piece:SetAttribute("ChaosClimaxSignature", kind)
        piece.Parent = parent
        TweenService:Create(piece,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                CFrame = deckCFrame * CFrame.new(spec.Finish) * spec.Rotation,
                Size = spec.GoalSize,
                Transparency = 1,
            }
        ):Play()
        Debris:AddItem(piece, duration + 0.12)
        table.insert(pieces, piece)
    end
    return pieces
end

return DisasterClimaxSignatureKit
