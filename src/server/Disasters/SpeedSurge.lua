local Players = game:GetService("Players")
local D = {Name = "SPEED SURGE", Hint = "FASTER, BUT STILL CONTROLLABLE!"}

function D.start(ctx)
    local profile = ctx.BalanceProfile or {}
    local multiplier = profile.SpeedMultiplier or 1.5

    local previous = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            previous[hum] = hum.WalkSpeed
            hum.WalkSpeed = math.min(26, math.max(22, hum.WalkSpeed * multiplier))
        end
    end

    ctx.OnCleanup[#ctx.OnCleanup+1] = function()
        for hum, speed in pairs(previous) do
            if hum and hum.Parent then hum.WalkSpeed = speed end
        end
    end
end

return D
