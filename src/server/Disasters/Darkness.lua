local D = {Name = "BLACKOUT", Hint = "VISIBILITY IS LOW — REMEMBER YOUR ROUTE!"}

-- Advanced, single-disaster Blackout alternates sustained low visibility
-- with short, gently lit windows for planning a safe route. The lighting
-- remains CLIENT-LOCAL: spectators/lobby players never lose visibility.
-- Rookie and Double Chaos rounds keep the original constant darkness.
D.CycleSeconds = 13
D.PowerStartsAt = 7
D.PowerEndsAt = 10

function D.stageAt(elapsedSeconds, enabled)
    if enabled ~= true then return nil end
    local elapsed = tonumber(elapsedSeconds)
    if not elapsed or elapsed ~= elapsed or math.abs(elapsed) == math.huge then
        elapsed = 0
    end
    local time = math.max(0, elapsed) % D.CycleSeconds
    if time >= D.PowerStartsAt and time < D.PowerEndsAt then
        return "PowerReturn"
    end
    return "Dark"
end

function D.start(ctx)
    if ctx.EnableBlackoutWindows ~= true then
        return
    end

    local startedAt = tonumber(ctx.RoundStartedAt) or os.clock()
    ctx.BlackoutStage = "Dark"
    ctx.OnCleanup[#ctx.OnCleanup + 1] = function()
        ctx.BlackoutStage = nil
    end

    task.spawn(function()
        while ctx.Active() do
            ctx.BlackoutStage = D.stageAt(os.clock() - startedAt, true)
            task.wait(0.2)
        end
    end)
end

return D
