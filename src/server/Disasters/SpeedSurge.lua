local D = {Name = "SPEED SURGE", Hint = "FASTER, BUT STILL CONTROLLABLE!"}

function D.start(ctx)
    local profile = ctx.BalanceProfile or {}
    local multiplier = profile.SpeedMultiplier or 1.5

    local previous = {}
    for _, p in ipairs(ctx.Contestants or {}) do
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
            }
            hum.WalkSpeed = applied
        end
    end

    ctx.OnCleanup[#ctx.OnCleanup+1] = function()
        for hum, state in pairs(previous) do
            if hum and hum.Parent and hum.WalkSpeed == state.applied then
                hum.WalkSpeed = state.original
            end
        end
        table.clear(previous)
    end
end

return D
