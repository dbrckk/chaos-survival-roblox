local Players = game:GetService("Players")
local D = {Name = "FREEZE PULSE", Hint = "MOVE BETWEEN SHORT FREEZES!"}

function D.start(ctx)
    local profile = ctx.BalanceProfile or {}
    local freezeSeconds = profile.FreezeSeconds or 1.1

    task.spawn(function()
        while ctx.Active() do
            task.wait(math.random(5, 7))
            for _, player in ipairs(Players:GetPlayers()) do
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local oldSpeed = hum.WalkSpeed
                    local oldJump = hum.JumpPower
                    hum.WalkSpeed = 4
                    hum.JumpPower = 0
                    task.delay(freezeSeconds, function()
                        if hum and hum.Parent and hum.Health > 0 then
                            hum.WalkSpeed = oldSpeed
                            hum.JumpPower = oldJump
                        end
                    end)
                end
            end
        end
    end)
end

return D
