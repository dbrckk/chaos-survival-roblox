-- Cosmetic climax language for Bombs and ShrinkingArena.
-- Blast uses discrete pressure fins; shrink uses opposed inward-moving
-- perimeter segments. No full-floor discs, new textures or physical changes.
-- All coordinates are relative to the pitched/rotated arena deck.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local DisasterBoundaryClimaxKit = {}
local COUNTS = {Low = 2, Medium = 4, High = 6}
local ALLOWED = {blast = true, shrink = true}

function DisasterBoundaryClimaxKit.count(tier, reduced)
    if reduced == true then return 2 end
    return COUNTS[tier] or 0
end

function DisasterBoundaryClimaxKit.recipe(kind, index, count, deckSize, stage)
    if not ALLOWED[kind] or type(index) ~= "number"
        or index % 1 ~= 0 or type(count) ~= "number"
        or count % 1 ~= 0 or count < 2 or count > 6
        or index < 1 or index > count
        or typeof(deckSize) ~= "Vector3"
        or deckSize.X <= 0 or deckSize.Z <= 0
        or type(stage) ~= "number" or stage % 1 ~= 0
        or stage < 1 or stage > 3 then
        return nil
    end

    local x = math.clamp(deckSize.X, 24, 220)
    local z = math.clamp(deckSize.Z, 24, 220)
    local avg = math.min(x, z)
    local secondary = index % 2 == 0
    if kind == "blast" then
        -- Broken shockfront fins expand radially without occluding the arena.
        local a = (index - 1) / count * math.pi * 2 + 0.23
        local direction = Vector3.new(math.cos(a), 0, math.sin(a))
        local yaw = -a - math.pi / 2 + (secondary and 0.13 or -0.15)
        local length = avg * (0.115 + 0.013 * stage)
        return {
            Wedge = index % 2 == 1,
            Material = Enum.Material.Metal,
            Start = direction * (avg * 0.055) + Vector3.new(0, 0.16, 0),
            Finish = direction * (avg * (0.19 + stage * 0.042))
                + Vector3.new(0, 0.20, 0),
            Rotation = CFrame.Angles(0, yaw, 0),
            Size = Vector3.new(length * 0.68, 0.11, 0.27),
            GoalSize = Vector3.new(length, 0.055, 0.12),
            Alpha = secondary and 0.30 or 0.35,
            Secondary = secondary,
            Label = "BlastFin",
        }
    end

    -- Low: opposite north/south dashes. Medium: one per cardinal side.
    -- High: four cardinal dashes plus two offset accents on the long sides.
    local slot = count == 2 and (index - 1) * 2 or ((index - 1) % 4)
    local offset = index > 4 and (index == 5 and -0.20 or 0.20) or 0
    local y = 0.15
    local start, finish, rotation, length
    local endFactor = math.max(0.12, 0.38 - stage * 0.077)
    if slot == 0 or slot == 2 then
        local side = slot == 0 and -1 or 1
        start = Vector3.new(x * offset, y, side * z * 0.45)
        finish = Vector3.new(x * offset, y + 0.02, side * z * endFactor)
        rotation = CFrame.new()
        length = x * (index > 4 and 0.19 or 0.39)
    else
        local side = slot == 1 and 1 or -1
        start = Vector3.new(side * x * 0.45, y, z * offset)
        finish = Vector3.new(side * x * endFactor, y + 0.02, z * offset)
        rotation = CFrame.Angles(0, math.pi / 2, 0)
        length = z * 0.39
    end
    return {
        Wedge = false,
        Material = Enum.Material.Glass,
        Start = start,
        Finish = finish,
        Rotation = rotation,
        Size = Vector3.new(length, 0.075, 0.28),
        GoalSize = Vector3.new(length * 0.76, 0.045, 0.11),
        Alpha = secondary and 0.38 or 0.32,
        Secondary = secondary,
        Label = "ClosingEdge",
    }
end

function DisasterBoundaryClimaxKit.emit(parent, kind, deckFrame, deckSize,
        stage, primary, secondary, tier, reduced)
    local result = {}
    local count = DisasterBoundaryClimaxKit.count(tier, reduced)
    if not parent or not ALLOWED[kind] or typeof(deckFrame) ~= "CFrame"
        or typeof(deckSize) ~= "Vector3"
        or typeof(primary) ~= "Color3" or typeof(secondary) ~= "Color3"
        or count == 0 or type(stage) ~= "number"
        or stage % 1 ~= 0 or stage < 1 or stage > 3 then
        return result
    end
    local duration = reduced and 0.19
        or (kind == "blast" and 0.40 or 0.56)

    for i = 1, count do
        local spec = DisasterBoundaryClimaxKit.recipe(
            kind, i, count, deckSize, stage
        )
        if not spec then break end
        local piece = Instance.new(spec.Wedge and "WedgePart" or "Part")
        piece.Name = (kind == "blast"
            and "BombClimax" or "ShrinkClimax") .. spec.Label .. i
        piece.Size = spec.Size
        piece.CFrame = deckFrame
            * CFrame.new(reduced and spec.Finish or spec.Start) * spec.Rotation
        piece.Anchored = true
        piece.CanCollide = false
        piece.CanTouch = false
        piece.CanQuery = false
        piece.CastShadow = false
        piece.Material = spec.Material
        piece.Color = spec.Secondary and secondary or primary
        piece.Transparency = reduced and 0.59 or spec.Alpha
        piece:SetAttribute("ChaosClimaxBoundary", kind)
        piece.Parent = parent
        TweenService:Create(
            piece,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                CFrame = deckFrame * CFrame.new(spec.Finish) * spec.Rotation,
                Size = spec.GoalSize,
                Transparency = 1,
            }
        ):Play()
        Debris:AddItem(piece, duration + 0.12)
        table.insert(result, piece)
    end
    return result
end

return DisasterBoundaryClimaxKit
