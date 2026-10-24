local D = {Name = "SPEED SURGE", Hint = "FOLLOW THE SPEED RHYTHM!"}

-- Veteran solo-disaster rounds alternate a readable fast/controlled tempo.
-- Beginner and Double Chaos rounds keep the original steady movement.
D.CycleSeconds = 12
D.TransitionSeconds = 0.70

-- Eased physical speed changes give players time to recover their aim,
-- especially near narrow platforms on touch controls. These are ordinary
-- server-owned Humanoid speeds, not impulses or client-side predictions.
-- The opening burst retains its immediate speed; later changes use a
-- short smoothstep curve on both sides of the phase boundary.
function D.speedAt(originalSpeed, boostedSpeed, elapsed, enabled)
    local original = tonumber(originalSpeed) or 16
    local boosted = tonumber(boostedSpeed) or 22
    if original ~= original or math.abs(original) == math.huge then original = 16 end
    if boosted ~= boosted or math.abs(boosted) == math.huge then boosted = 22 end
    original = math.max(0, original)
    boosted = math.max(0, boosted)
    if enabled ~= true then return boosted end

    local time = tonumber(elapsed) or 0
    if time ~= time or math.abs(time) == math.huge then time = 0 end
    time = math.max(0, time)
    local tick = time % D.CycleSeconds
    local function eased(alpha)
        local x = math.clamp(alpha, 0, 1)
        return x * x * (3 - 2 * x)
    end

    if tick < 7 then
        if time < D.CycleSeconds then return boosted end
        local alpha = eased(tick / D.TransitionSeconds)
        return original + (boosted - original) * alpha
    end

    local alpha = eased((tick - 7) / D.TransitionSeconds)
    return boosted + (original - boosted) * alpha
end

-- Roblox can quantize WalkSpeed property assignments. Compare within
-- sub-hundredth precision while respecting meaningful changes by other
-- movement systems, including future disasters or power-ups.
function D.ownsSpeed(actual, assigned)
    local a = tonumber(actual)
    local b = tonumber(assigned)
    return a ~= nil and b ~= nil and a == a and b == b
        and math.abs(a) < math.huge and math.abs(b) < math.huge
        and math.abs(a - b) <= 0.01
end

-- A Roblox Humanoid can store a rounded WalkSpeed. If the observed speed
-- remains ours, the tide may advance; a meaningful external modifier must
-- be left untouched until the other owner releases it.
function D.shouldAssignSpeed(actual, assigned, target)
    return D.ownsSpeed(actual, assigned)
        and D.ownsSpeed(target, target)
        and not D.ownsSpeed(actual, target)
end

function D.tempoAt(elapsed, enabled)
    if enabled ~= true then return "Surge", math.huge end
    local value = tonumber(elapsed) or 0
    if value ~= value or math.abs(value) == math.huge then value = 0 end
    local time = math.max(0, value) % D.CycleSeconds
    if time < 7 then return "Surge", 7 - time end
    return "Recover", D.CycleSeconds - time
end

function D.start(ctx)
    local profile = ctx.BalanceProfile or {}
    local multiplier = profile.SpeedMultiplier or 1.5
    local tempoEnabled = ctx.EnableSpeedTempo == true
    local startedAt = tonumber(ctx.RoundStartedAt) or os.clock()

    local previous = {}
    for _, p in ipairs(ctx.HazardContestants or ctx.Contestants or {}) do
        if ctx.IsContestantActive and not ctx.IsContestantActive(p) then
            continue
        end

        local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            local original = hum.WalkSpeed
            local applied = math.min(26, math.max(22, original * multiplier))
            previous[hum] = {
                original = original,
                applied = applied,
                current = applied,
            }
            hum.WalkSpeed = applied
            -- Capture the Humanoid's real stored value, not the pre-assignment
            -- double precision number which may differ after quantization.
            previous[hum].current = hum.WalkSpeed
        end
    end

    local beacon
    if tempoEnabled then
        -- The always-on-top "SPEED RHYTHM" BillboardGui used to cover the
        -- avatar, hazard telegraphs and round objective on Android.
        -- The phase header + client RoundEvents already announce speed
        -- transitions. Keep only an inert light-free edge landmark here.
        beacon = Instance.new("Part")
        beacon.Name = "SpeedTempoBeacon"
        beacon.Size = Vector3.new(2.4, 2.4, 2.4)
        beacon.Shape = Enum.PartType.Ball
        beacon.Position = ctx.Config.ArenaCenter + Vector3.new(0, 13, -86)
        beacon.Anchored = true
        beacon.CanCollide = false
        beacon.CanTouch = false
        beacon.CanQuery = false
        beacon.CastShadow = false
        beacon.Material = Enum.Material.Neon
        beacon.Color = Color3.fromRGB(255, 95, 190)
        beacon.Parent = workspace
        ctx.Cleanup[#ctx.Cleanup+1] = beacon
    end

    ctx.OnCleanup[#ctx.OnCleanup+1] = function()
        ctx.SpeedTempoPhase = nil
        for hum, state in pairs(previous) do
            if hum and hum.Parent and D.ownsSpeed(hum.WalkSpeed, state.current) then
                hum.WalkSpeed = state.original
            end
        end
        table.clear(previous)
    end

    if tempoEnabled then
        ctx.SpeedTempoPhase = "Surge"
        task.spawn(function()
            while ctx.Active() and beacon.Parent do
                local elapsed = os.clock() - startedAt
                local phase = D.tempoAt(elapsed, true)
                ctx.SpeedTempoPhase = phase
                beacon.Color = phase == "Surge"
                    and Color3.fromRGB(255, 95, 190)
                    or Color3.fromRGB(90, 205, 235)
                for hum, state in pairs(previous) do
                    if hum.Parent and hum.Health > 0 then
                        local actual = hum.WalkSpeed
                        if D.ownsSpeed(actual, state.current) then
                            local target = D.speedAt(
                                state.original, state.applied, elapsed, true
                            )
                            -- Only write when the rounded Humanoid property
                            -- truly needs changing. Do not steal movement
                            -- control from another system.
                            if D.shouldAssignSpeed(actual, state.current, target) then
                                hum.WalkSpeed = target
                            end
                            state.current = hum.WalkSpeed
                        end
                    end
                end
                task.wait(0.12)
            end
        end)
    end
end

return D
