-- Pattern director for the existing server-authoritative Meteor/Bomb hazards.
-- Turns a randomized shower into readable sequences without extra strikes,
-- faster timers, larger damage radii, telegraph removal or new physics.
-- A small number of authored lanes change the decisions players make:
-- scatter -> advancing sweep -> alternating flanks.
local ImpactWaveDirector = {}

ImpactWaveDirector.SCATTER = "Scatter"
ImpactWaveDirector.SWEEP = "Sweep"
ImpactWaveDirector.FLANKS = "Flanks"
ImpactWaveDirector.MinRoundSeconds = 24
ImpactWaveDirector.MinHalfExtent = 32

local function finiteNumber(value, fallback)
    local n = tonumber(value)
    if not n or n ~= n or math.abs(n) == math.huge then
        return fallback
    end
    return n
end

-- Disable advanced waves during the three-round learning window, in
-- short rounds, and once the shrinking arena is too small to guarantee
-- room to dodge a standard eight-stud impact. Scatter is the safe default.
function ImpactWaveDirector.mode(elapsed, duration, enabled, halfX, halfZ)
    local total = finiteNumber(duration, 0)
    if enabled ~= true or total < ImpactWaveDirector.MinRoundSeconds then
        return ImpactWaveDirector.SCATTER
    end
    if halfX ~= nil and finiteNumber(halfX, 0) < ImpactWaveDirector.MinHalfExtent
        or halfZ ~= nil and finiteNumber(halfZ, 0) < ImpactWaveDirector.MinHalfExtent
    then
        return ImpactWaveDirector.SCATTER
    end
    local fraction = math.clamp(finiteNumber(elapsed, 0) / total, 0, 1)
    if fraction < 0.32 then
        return ImpactWaveDirector.SCATTER
    elseif fraction < 0.67 then
        return ImpactWaveDirector.SWEEP
    end
    return ImpactWaveDirector.FLANKS
end

function ImpactWaveDirector.forContext(ctx, now, halfX, halfZ)
    if type(ctx) ~= "table" then return ImpactWaveDirector.SCATTER end
    local start = finiteNumber(ctx.RoundStartedAt, nil)
    local clock = finiteNumber(now, nil)
    if not start or not clock then return ImpactWaveDirector.SCATTER end
    return ImpactWaveDirector.mode(
        math.max(0, clock - start), ctx.RoundSeconds,
        ctx.EnableImpactWaves, halfX, halfZ
    )
end

-- Predictable ordered patterns, varied by match and hazard type.
-- A sweep travels horizontally across the center lane then returns on
-- an outer flank. Crossfire alternates the corners with a periodically
-- telegraphed center strike, so no single camping spot is permanently safe.
-- Individual ground circles remain authoritative and fully avoidable.
function ImpactWaveDirector.anchor(mode, sequence, roundNumber, hazardId, halfX, halfZ)
    if mode ~= ImpactWaveDirector.SWEEP and mode ~= ImpactWaveDirector.FLANKS then
        return nil
    end
    local hx = finiteNumber(halfX, 0)
    local hz = finiteNumber(halfZ, 0)
    if hx < ImpactWaveDirector.MinHalfExtent
        or hz < ImpactWaveDirector.MinHalfExtent then
        return nil
    end
    local step = math.max(0, math.floor(finiteNumber(sequence, 1) - 1))
    local round = math.max(1, math.floor(finiteNumber(roundNumber, 1)))
    local invert = ((round % 2) == 0) ~= (hazardId == "Bombs")
    local sign = invert and -1 or 1

    if mode == ImpactWaveDirector.SWEEP then
        -- Three wide lanes deliberately exceed the 22-stud shared
        -- warning separation budget. The central pass prevents effortless
        -- safe camping; the return uses the offset flank for variety.
        local pass = math.floor(step / 3)
        local lane = step % 3
        local direction = pass % 2 == 0 and 1 or -1
        local x = ((lane - 1) * 0.72) * direction * sign
        local z = (pass % 2 == 0 and 0 or -0.56) * sign
        return Vector3.new(x * hx, 0, z * hz)
    end

    -- Four diagonal flank strikes, then a transparent center telegraph.
    -- That fifth beat prevents a zero-risk "always camp mid" strategy,
    -- without new hitboxes or any shortened warning reaction time.
    local index = (step % 5) + 1
    if index == 5 then
        return Vector3.zero
    end
    local corners = {
        Vector2.new(-0.54, -0.52),
        Vector2.new(0.54, 0.52),
        Vector2.new(-0.54, 0.52),
        Vector2.new(0.54, -0.52),
    }
    local point = corners[((index + round - 2) % 4) + 1]
    return Vector3.new(point.X * hx * sign, 0, point.Y * hz)
end

-- Candidate alternatives stay close to the forecast lane, but can move
-- away from another pending warning before resorting to random placement.
-- No new Part, region query, physics or per-frame coroutine is allocated.
function ImpactWaveDirector.candidates(mode, sequence, round, hazard, halfX, halfZ)
    local center = ImpactWaveDirector.anchor(
        mode, sequence, round, hazard, halfX, halfZ
    )
    if not center then return {} end
    local marginX = math.min(3.4, halfX * 0.09)
    local marginZ = math.min(3.4, halfZ * 0.09)
    local maxX = halfX * 0.78
    local maxZ = halfZ * 0.78
    local candidates = {}
    for _, pair in ipairs({
        {0, 0},
        {1, 0}, {-1, 0},
        {0, 1}, {0, -1},
        {1, 1}, {-1, -1},
    }) do
        candidates[#candidates + 1] = Vector3.new(
            math.clamp(center.X + pair[1] * marginX, -maxX, maxX),
            0,
            math.clamp(center.Z + pair[2] * marginZ, -maxZ, maxZ)
        )
    end
    return candidates
end

return ImpactWaveDirector
