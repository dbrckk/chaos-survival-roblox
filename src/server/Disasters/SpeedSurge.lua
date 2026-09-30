local Players = game:GetService("Players")
local D = {Name = "SPEED SURGE", Hint = "TOO FAST TO STOP!"}

function D.start(ctx)
    local previous = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            previous[hum] = hum.WalkSpeed
            hum.WalkSpeed = math.max(28, hum.WalkSpeed * 1.8)
        end
    end

    ctx.OnCleanup[#ctx.OnCleanup+1] = function()
        for hum, speed in pairs(previous) do
            if hum and hum.Parent then hum.WalkSpeed = speed end
        end
    end
end

return D
