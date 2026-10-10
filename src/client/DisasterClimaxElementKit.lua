-- Authored procedural 3D climax signatures: volcanic rising fins and
-- meteor impact shards. Visual only; no hitboxes, lights, emitters or assets.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Kit = {}
local VALID = {lava = true, meteor = true, tornado = true}
local COUNTS = {Low = 2, Medium = 4, High = 6}

function Kit.count(tier, reduced)
    if reduced == true then return COUNTS[tier] and 1 or 0 end
    return COUNTS[tier] or 0
end

function Kit.recipe(kind, index, count, span, stage, tier)
    if not VALID[kind] or type(index) ~= "number" or index % 1 ~= 0
        or type(count) ~= "number" or count % 1 ~= 0 or count < 1
        or count > 6 or index < 1 or index > count
        or type(span) ~= "number" or span <= 0
        or type(stage) ~= "number" or stage % 1 ~= 0
        or stage < 1 or stage > 3 or not COUNTS[tier] then
        return nil
    end

    local width = math.clamp(span, 24, 220)
    local angle = (index - 1) / count * math.pi * 2
        + (kind == "lava" and 0.21 or 0.38)
    local side = index % 2 == 0 and 1 or -1
    local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
    local yaw = -angle - math.pi * 0.5 + side * 0.18

    if kind == "lava" then
        -- Three-dimensional asymmetric volcanic fins grow outward/upward.
        local start = direction * (width * 0.30)
            + Vector3.new(0, 0.65, 0)
        local finish = direction * (width * (0.32 + stage * 0.012))
            + Vector3.new(0, 5.2 + stage * 1.3, 0)
        return {
            Kind = kind,
            Name = "LavaClimaxVolcanicFin",
            Start = start,
            Finish = finish,
            Rotation = CFrame.Angles(0, yaw, side * math.rad(13)),
            Size = Vector3.new(0.50, 1.45, 0.28),
            GoalSize = Vector3.new(0.22, 3.4 + stage * 0.82, 0.12),
            Material = tier == "High" and Enum.Material.Neon
                or Enum.Material.SmoothPlastic,
            Transparency = tier == "Low" and 0.52 or 0.38,
            Duration = 0.48,
        }
    end

    if kind == "tornado" then
        -- A pitched, inward-winding helix of angular 3D fins, not bars.
        local start = direction * (width * 0.30)
            + Vector3.new(0, 0.85 + index * 0.20, 0)
        local finish = Vector3.new(
            math.cos(angle + 1.18) * width * 0.065,
            6.5 + stage * 1.85 + index * 0.38,
            math.sin(angle + 1.18) * width * 0.065
        )
        return {
            Kind = kind,
            Name = "TornadoClimaxHelixFin",
            Start = start,
            Finish = finish,
            Rotation = CFrame.Angles(math.rad(18), yaw + 0.48,
                side * math.rad(19)),
            Size = Vector3.new(0.30, 1.10, 3.0 + stage * 0.32),
            GoalSize = Vector3.new(0.14, 0.43, 1.4 + stage * 0.22),
            Material = tier == "High" and Enum.Material.Metal
                or Enum.Material.SmoothPlastic,
            Transparency = tier == "Low" and 0.58 or 0.44,
            Duration = 0.52,
        }
    end

    -- Falling spearheads: short chamfer-like wedges, not thick square beams.
    local start = direction * (width * 0.28)
        + Vector3.new(0, 20 + index * 0.75, 0)
    local finish = direction * (width * 0.16)
        + Vector3.new(0, 0.85, 0)
    return {
        Kind = kind,
        Name = "MeteorClimaxSpearhead",
        Start = start,
        Finish = finish,
        Rotation = CFrame.Angles(math.rad(-33), yaw, side * math.rad(8)),
        Size = Vector3.new(0.44, 0.80, 3.0 + stage * 0.30),
        GoalSize = Vector3.new(0.16, 0.25, 1.2 + stage * 0.20),
        Material = tier == "Low" and Enum.Material.SmoothPlastic
            or Enum.Material.Metal,
        Transparency = tier == "Low" and 0.56 or 0.40,
        Duration = 0.44,
    }
end

function Kit.emit(parent, kind, deckFrame, span, stage, primary,
        secondary, tier, reduced)
    local pieces = {}
    local count = Kit.count(tier, reduced)
    if not parent or not VALID[kind] or typeof(deckFrame) ~= "CFrame"
        or typeof(primary) ~= "Color3" or typeof(secondary) ~= "Color3"
        or count == 0 then
        return pieces
    end
    for i = 1, count do
        local spec = Kit.recipe(kind, i, count, span, stage, tier)
        if not spec then return pieces end
        local part = Instance.new("WedgePart")
        part.Name = spec.Name .. i
        part.Size = spec.Size
        part.CFrame = deckFrame
            * CFrame.new(reduced and spec.Finish or spec.Start)
            * spec.Rotation
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.Material = spec.Material
        part.Color = i % 2 == 0 and secondary or primary
        part.Transparency = reduced and 0.64 or spec.Transparency
        part:SetAttribute("ChaosClimaxElement", kind)
        part.Parent = parent
        local duration = reduced and 0.18 or spec.Duration
        TweenService:Create(part,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                CFrame = deckFrame * CFrame.new(spec.Finish) * spec.Rotation,
                Size = spec.GoalSize,
                Transparency = 1,
            }
        ):Play()
        Debris:AddItem(part, duration + 0.12)
        table.insert(pieces, part)
    end
    return pieces
end

return Kit
