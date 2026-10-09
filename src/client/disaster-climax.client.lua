local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DisasterClimax = require(ReplicatedStorage.Shared.DisasterClimax)
local DisasterClimaxSignatureKit = require(script.Parent.DisasterClimaxSignatureKit)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "DisasterClimaxLocal"
folder.Parent = workspace

local previousPhase = "waiting"
local stageById = {}
local token = 0

local function arenaBase()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    return base and base:IsA("BasePart") and base or nil
end

local function makePart(name, size, cframe, color, transparency, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Material = Enum.Material.Neon
    p.Color = color
    p.Transparency = transparency or 0.35
    if shape then
        p.Shape = shape
    end
    p.Parent = folder
    return p
end

local function tweenOut(part, duration, goal)
    TweenService:Create(
        part,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        goal
    ):Play()
    Debris:AddItem(part, duration + 0.2)
end

local function lineBetween(name, from, to, width, color, transparency)
    local delta = to - from
    local length = math.max(0.1, delta.Magnitude)
    local mid = from + delta * 0.5
    return makePart(
        name,
        Vector3.new(width, width, length),
        CFrame.lookAt(mid, to),
        color,
        transparency
    )
end

local function ring(name, center, diameter, color, transparency)
    return makePart(
        name,
        Vector3.new(0.055, diameter, diameter),
        CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)),
        color,
        transparency,
        Enum.PartType.Cylinder
    )
end

local function stageScale(stage)
    if stage >= 3 then
        return 1.65
    elseif stage == 2 then
        return 1.30
    end
    return 1
end

local function countForTier(tier, low, medium, high)
    if tier.Name == "Low" then
        return low
    elseif tier.Name == "Medium" then
        return medium
    end
    return high
end

local function playLava(profile, base, stage, tier, reduced)
    local center = base.Position + Vector3.new(0, base.Size.Y * 0.5 + 0.12, 0)
    local span = math.max(base.Size.X, base.Size.Z)
    local count = countForTier(tier, 2, 4, 6)
    local scale = stageScale(stage)

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2
        local radius = span * (0.34 + 0.03 * stage)
        local position = center + Vector3.new(
            math.cos(angle) * radius,
            0,
            math.sin(angle) * radius
        )
        local p = makePart(
            "LavaClimaxJet" .. i,
            Vector3.new(0.22, 1.5, 0.22),
            CFrame.new(position),
            i % 2 == 0 and profile.Secondary or profile.Color,
            0.28
        )
        tweenOut(
            p,
            reduced and 0.24 or 0.50,
            {
                Size = Vector3.new(0.14, 8 * scale, 0.14),
                CFrame = p.CFrame * CFrame.new(0, 4 * scale, 0),
                Transparency = 1,
            }
        )
    end
end

local function playMeteor(profile, base, stage, tier, reduced)
    local center = base.Position + Vector3.new(0, base.Size.Y * 0.5, 0)
    local span = math.max(base.Size.X, base.Size.Z)
    local count = countForTier(tier, 2, 4, 6)
    local scale = stageScale(stage)

    for i = 1, count do
        local x = (((i * 29) % 9) - 4) * span * 0.07
        local z = (((i * 47) % 9) - 4) * span * 0.07
        local from = center + Vector3.new(x - 7 * scale, 23 + i * 1.1, z + 5 * scale)
        local to = center + Vector3.new(x, 3, z)
        local streak = lineBetween(
            "MeteorClimaxStreak" .. i,
            from,
            to,
            stage >= 3 and 0.34 or 0.24,
            i % 2 == 0 and profile.Secondary or profile.Color,
            0.30
        )
        tweenOut(
            streak,
            reduced and 0.22 or 0.46,
            {
                CFrame = streak.CFrame * CFrame.new(0, 0, streak.Size.Z * 0.45),
                Transparency = 1,
            }
        )
    end
end

local function playGravity(profile, base, stage, tier, reduced)
    local center = base.Position + Vector3.new(0, base.Size.Y * 0.5 + 0.12, 0)
    local span = math.max(base.Size.X, base.Size.Z)
    local count = countForTier(tier, 3, 5, 8)
    local scale = stageScale(stage)

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2
        local radius = span * 0.28
        local p = makePart(
            "GravityClimaxLift" .. i,
            Vector3.new(0.16, 2.8, 0.16),
            CFrame.new(center + Vector3.new(
                math.cos(angle) * radius,
                0,
                math.sin(angle) * radius
            )),
            i % 2 == 0 and profile.Secondary or profile.Color,
            0.42
        )
        tweenOut(
            p,
            reduced and 0.26 or 0.62,
            {
                CFrame = p.CFrame * CFrame.new(0, 9 * scale, 0),
                Size = Vector3.new(0.08, 5.5 * scale, 0.08),
                Transparency = 1,
            }
        )
    end
end

local function playFracture(profile, base, stage, tier, reduced)
    local center = base.Position + Vector3.new(0, base.Size.Y * 0.5 + 0.10, 0)
    local span = math.max(base.Size.X, base.Size.Z)
    local count = countForTier(tier, 3, 5, 7)
    local scale = stageScale(stage)

    for i = 1, count do
        local yaw = math.rad((i - 1) * (180 / count))
        local p = makePart(
            "FractureClimax" .. i,
            Vector3.new(span * 0.36, 0.06, 0.14),
            CFrame.new(center)
                * CFrame.Angles(0, yaw, 0)
                * CFrame.new((i % 2 == 0 and 1 or -1) * span * 0.08, 0, 0),
            i % 2 == 0 and profile.Secondary or profile.Color,
            0.34
        )
        tweenOut(
            p,
            reduced and 0.22 or 0.46,
            {
                Size = Vector3.new(span * 0.56 * scale, 0.04, 0.06),
                Transparency = 1,
            }
        )
    end
end

local function playTornado(profile, base, stage, tier, reduced)
    local center = base.Position + Vector3.new(0, base.Size.Y * 0.5 + 0.2, 0)
    local span = math.max(base.Size.X, base.Size.Z)
    local count = countForTier(tier, 3, 5, 7)
    local scale = stageScale(stage)

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2
        local from = center + Vector3.new(
            math.cos(angle) * span * 0.32,
            1,
            math.sin(angle) * span * 0.32
        )
        local to = center + Vector3.new(
            math.cos(angle + 1.15) * span * 0.08,
            8 * scale,
            math.sin(angle + 1.15) * span * 0.08
        )
        local streak = lineBetween(
            "TornadoClimaxSpiral" .. i,
            from,
            to,
            0.18,
            i % 2 == 0 and profile.Secondary or profile.Color,
            0.38
        )
        tweenOut(
            streak,
            reduced and 0.24 or 0.52,
            {
                Transparency = 1,
                Size = Vector3.new(0.08, 0.08, streak.Size.Z * 0.68),
            }
        )
    end
end

local function playFreeze(profile, base, stage, tier, reduced)
    -- Angle-breaking ice needles replace the old large opaque cylinder.
    -- The whole silhouette inherits the rotated/pitched arena frame.
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.12, 0)
    DisasterClimaxSignatureKit.emit(
        folder, "freeze", deck,
        math.max(base.Size.X, base.Size.Z), stage,
        profile.Color, profile.Secondary, tier.Name, reduced
    )
end

local function playBomb(profile, base, stage, tier, reduced)
    local center = base.Position + Vector3.new(0, base.Size.Y * 0.5 + 0.13, 0)
    local span = math.max(base.Size.X, base.Size.Z)
    local scale = stageScale(stage)
    local count = tier.Name == "Low" and 1 or 2

    for i = 1, count do
        local p = ring(
            "BombClimaxRing" .. i,
            center + Vector3.new(0, i * 0.05, 0),
            span * (0.16 + i * 0.05),
            i == 1 and profile.Color or profile.Secondary,
            0.24 + i * 0.06
        )
        tweenOut(
            p,
            reduced and 0.20 or 0.42,
            {
                Size = Vector3.new(
                    0.055,
                    span * (0.60 + i * 0.12) * scale,
                    span * (0.60 + i * 0.12) * scale
                ),
                Transparency = 1,
            }
        )
    end
end

local function playSpeed(profile, base, stage, tier, reduced)
    local center = base.Position + Vector3.new(0, base.Size.Y * 0.5 + 0.10, 0)
    local span = math.max(base.Size.X, base.Size.Z)
    local count = countForTier(tier, 3, 5, 7)
    local scale = stageScale(stage)

    for i = 1, count do
        local angle = math.rad((i - 1) * (180 / count))
        local p = makePart(
            "SpeedClimaxLane" .. i,
            Vector3.new(span * 0.26, 0.055, 0.11),
            CFrame.new(center) * CFrame.Angles(0, angle, 0),
            i % 2 == 0 and profile.Secondary or profile.Color,
            0.32
        )
        tweenOut(
            p,
            reduced and 0.20 or 0.42,
            {
                CFrame = p.CFrame * CFrame.new(0, 0, -span * 0.20 * scale),
                Size = Vector3.new(span * 0.42 * scale, 0.04, 0.06),
                Transparency = 1,
            }
        )
    end
end

local function playDarkness(profile, base, stage, tier, reduced)
    local center = base.Position + Vector3.new(0, base.Size.Y * 0.5 + 0.13, 0)
    local span = math.max(base.Size.X, base.Size.Z)
    local scale = stageScale(stage)

    local p = ring(
        "DarknessClimaxVoid",
        center,
        span * 0.96,
        profile.Color,
        0.72
    )
    tweenOut(
        p,
        reduced and 0.24 or 0.58,
        {
            Size = Vector3.new(
                0.055,
                span * 0.18 / scale,
                span * 0.18 / scale
            ),
            Transparency = 1,
        }
    )

    if stage >= 2 and tier.Name ~= "Low" then
        local core = makePart(
            "DarknessClimaxCore",
            Vector3.new(0.35, 8 * scale, 0.35),
            CFrame.new(center + Vector3.new(0, 4 * scale, 0)),
            profile.Secondary,
            0.60
        )
        tweenOut(
            core,
            reduced and 0.20 or 0.40,
            {Transparency = 1, Size = Vector3.new(0.12, 13 * scale, 0.12)}
        )
    end
end

local function playShrink(profile, base, stage, tier, reduced)
    local center = base.Position + Vector3.new(0, base.Size.Y * 0.5 + 0.13, 0)
    local span = math.max(base.Size.X, base.Size.Z)
    local scale = stageScale(stage)

    local p = ring(
        "ShrinkClimaxRing",
        center,
        span * 1.02,
        profile.Color,
        0.28
    )
    tweenOut(
        p,
        reduced and 0.24 or 0.56,
        {
            Size = Vector3.new(
                0.055,
                span * 0.48 / math.max(1, scale * 0.86),
                span * 0.48 / math.max(1, scale * 0.86)
            ),
            Transparency = 1,
        }
    )

    if tier.Name == "High" then
        local inner = ring(
            "ShrinkClimaxInner",
            center + Vector3.new(0, 0.05, 0),
            span * 0.82,
            profile.Secondary,
            0.42
        )
        tweenOut(
            inner,
            reduced and 0.20 or 0.48,
            {
                Size = Vector3.new(0.055, span * 0.38, span * 0.38),
                Transparency = 1,
            }
        )
    end
end

local function playShock(profile, base, stage, tier, reduced)
    -- Staggered zig-zag discharge strokes, not two full-floor discs.
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.14, 0)
    DisasterClimaxSignatureKit.emit(
        folder, "shock", deck,
        math.max(base.Size.X, base.Size.Z), stage,
        profile.Color, profile.Secondary, tier.Name, reduced
    )
end

local PLAYERS = {
    lava = playLava,
    meteor = playMeteor,
    gravity = playGravity,
    fracture = playFracture,
    tornado = playTornado,
    freeze = playFreeze,
    bomb = playBomb,
    speed = playSpeed,
    darkness = playDarkness,
    shrink = playShrink,
    shock = playShock,
}

local function playClimax(id, stage, base, delaySeconds, currentToken)
    local profile = DisasterClimax.get(id)
    local play = profile and PLAYERS[profile.Kind]
    if not profile or not play then
        return
    end

    task.delay(delaySeconds or 0, function()
        if token ~= currentToken
            or not base.Parent
            or player:GetAttribute("RoundEliminated") == true
        then
            return
        end

        local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
        local reduced = player:GetAttribute("ReduceMotion") == true
        play(profile, base, stage, tier, reduced)
    end)
end

stateEvent.OnClientEvent:Connect(function(state)
    local phase = tostring(state.phase or "waiting")

    if phase ~= "round" then
        token += 1
        table.clear(stageById)
        previousPhase = phase
        return
    end

    if previousPhase ~= "round" then
        table.clear(stageById)
        token += 1
    end

    local stage = DisasterClimax.stageFor(
        state.intensity,
        state.finalRush == true,
        state.overdrive == true
    )
    local base = arenaBase()

    if base and stage > 0 then
        local ids = type(state.disasterIds) == "table" and state.disasterIds or {}
        local currentToken = token

        for index, id in ipairs(ids) do
            local previousStage = stageById[id] or 0
            if stage > previousStage then
                stageById[id] = stage
                playClimax(
                    id,
                    stage,
                    base,
                    (index - 1) * 0.10,
                    currentToken
                )
            end
        end
    end

    previousPhase = phase
end)
