-- Eight distinct, authored 3D one-shot silhouettes for native Showtime.
-- Client-only presentation, without game controls or avatar Motor6D edits.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Kit = {}

local NAMES = {
    dance = "RhythmCrescent",
    shuffle = "SkateStepChevron",
    groove = "BassWaveFin",
    robot = "RobotCircuitGlyph",
    orbit = "OrbitalDancePetal",
    cheer = "VictoryFanfareSpike",
    wave = "GreetingArc",
    laugh = "LaughRippleRib",
}
local BUDGET = {Medium = 3, High = 6}

function Kit.count(tier, reduced)
    return reduced == true and 0 or (BUDGET[tier] or 0)
end

function Kit.recipe(kind, index, count)
    if not NAMES[kind] or type(index) ~= "number"
        or type(count) ~= "number" or count % 1 ~= 0 or index % 1 ~= 0
        or count < 1 or count > 6 or index < 1 or index > count
    then return nil end

    local a = (index - 1) / count * math.pi * 2 + 0.19
    local side = index % 2 == 0 and 1 or -1
    local pair = math.floor((index - 1) / 2)
    local x = math.cos(a)
    local z = math.sin(a)
    local start, finish, size, rotation
    local className = "WedgePart"
    local material = Enum.Material.SmoothPlastic
    local alpha = 0.42

    if kind == "dance" then
        -- Floor-level outward-sweeping crescents on opposing beats.
        start = Vector3.new(x * 1.05, -2.3, z * 1.05)
        finish = Vector3.new(x * 2.5, -2.18, z * 2.5)
        size = Vector3.new(0.25, 0.10, 1.0 + pair * 0.10)
        rotation = CFrame.Angles(math.rad(-10), a + math.pi / 2,
            side * math.rad(24))
    elseif kind == "shuffle" then
        -- Two-sided footwork chevrons shoot forward from the heel line.
        start = Vector3.new(side * (0.45 + pair * 0.22), -2.32, 0.35)
        finish = Vector3.new(side * (0.65 + pair * 0.30), -2.28, -2.3)
        size = Vector3.new(0.27, 0.08, 0.78)
        rotation = CFrame.Angles(0, side * math.rad(24), 0)
    elseif kind == "groove" then
        -- Alternating upright bass-wave strips move at hip height.
        start = Vector3.new(side * (0.8 + pair * 0.30), -0.65,
            (index - 3.5) * 0.17)
        finish = start + Vector3.new(side * 0.35, 0.8 + pair * 0.16, 0)
        size = Vector3.new(0.19, 1.10 + pair * 0.20, 0.18)
        rotation = CFrame.Angles(0, side * 0.18, side * math.rad(20))
        className = "Part"
    elseif kind == "robot" then
        -- Stepped circuit bars: upright angular industrial silhouette.
        start = Vector3.new(side * (1.15 + pair * 0.30), -1.1, -0.45)
        finish = start + Vector3.new(side * 0.16, 1.5, -0.20)
        size = Vector3.new(0.22, 1.25 + pair * 0.15, 0.26)
        rotation = CFrame.Angles(0, side * math.rad(18), side * math.rad(13))
    elseif kind == "orbit" then
        -- Twisted petal fragments climb around the player's sides.
        start = Vector3.new(x * 1.35, -1.15, z * 1.35)
        finish = Vector3.new(
            math.cos(a + 1.10) * 2.15, 1.20,
            math.sin(a + 1.10) * 2.15)
        size = Vector3.new(0.27, 0.16, 1.38)
        rotation = CFrame.Angles(math.rad(28), a, side * math.rad(35))
    elseif kind == "cheer" then
        -- Victory spikes point upward; no full-screen celebration flash.
        start = Vector3.new(x * 1.05, -0.85, z * 1.05)
        finish = Vector3.new(x * 1.85, 1.95 + pair * 0.20, z * 1.85)
        size = Vector3.new(0.22, 1.25, 0.30)
        rotation = CFrame.Angles(math.rad(-16), a, side * math.rad(22))
    elseif kind == "wave" then
        -- One-sided open greeting arc, distinct from radial fireworks.
        start = Vector3.new(1.03 + x * 0.32,
            0.12 + math.sin(a) * 0.25, -0.18)
        finish = Vector3.new(1.55 + x * 0.48,
            1.0 + pair * 0.20, -0.60 + z * 0.30)
        size = Vector3.new(0.18, 0.68, 0.22)
        rotation = CFrame.Angles(0, a * 0.28, side * math.rad(27))
    else
        -- Laugh produces expanding low ripple ribs, not random confetti.
        start = Vector3.new(x * 0.80, -2.26, z * 0.80)
        finish = Vector3.new(x * 2.25, -2.22, z * 2.25)
        size = Vector3.new(0.18, 0.065, 0.85)
        rotation = CFrame.Angles(0, a + math.pi / 2, 0)
        className = "Part"
    end

    return {
        Name = NAMES[kind],
        Class = className,
        Material = material,
        Start = start,
        Finish = finish,
        Rotation = rotation,
        Size = size,
        GoalSize = Vector3.new(size.X * 0.44,
            math.max(0.04, size.Y * 0.55), size.Z * 0.72),
        Transparency = alpha,
        Duration = 0.72,
    }
end

function Kit.emit(parent, rootFrame, kind, tier, reduced, primary, secondary)
    local pieces = {}
    local count = Kit.count(tier, reduced)
    if not parent or not NAMES[kind] or count == 0
        or typeof(rootFrame) ~= "CFrame"
        or typeof(primary) ~= "Color3"
        or typeof(secondary) ~= "Color3" then
        return pieces
    end

    -- Switching dances never stacks several full 3D glyph sets. Do not
    -- touch permanent stage assets or unrelated lobby visual owners.
    for _, item in ipairs(parent:GetChildren()) do
        if item:GetAttribute("ChaosShowtimeSignature") == true then
            item:Destroy()
        end
    end
    for i = 1, count do
        local spec = Kit.recipe(kind, i, count)
        local part = Instance.new(spec.Class)
        part.Name = spec.Name .. i
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.Size = spec.Size
        part.Material = spec.Material
        part.Transparency = spec.Transparency
        part.Color = i % 2 == 0 and secondary or primary
        part.CFrame = rootFrame * CFrame.new(spec.Start) * spec.Rotation
        part:SetAttribute("ChaosShowtimeSignature", true)
        part:SetAttribute("ChaosShowtimeStyle", kind)
        part.Parent = parent
        TweenService:Create(part,
            TweenInfo.new(spec.Duration, Enum.EasingStyle.Cubic,
                Enum.EasingDirection.Out),
            {
                CFrame = rootFrame * CFrame.new(spec.Finish) * spec.Rotation,
                Size = spec.GoalSize,
                Transparency = 1,
            }
        ):Play()
        Debris:AddItem(part, spec.Duration + 0.12)
        table.insert(pieces, part)
    end
    return pieces
end

return Kit
