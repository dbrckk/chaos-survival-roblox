local Players = game:GetService("Players")
local D = {Name = "FREEZE PULSE", Hint = "MOVE BETWEEN FREEZES!"}

function D.start(ctx)
    task.spawn(function()
        while ctx.Active() do
            task.wait(math.random(4, 7))
            for _, player in ipairs(Players:GetPlayers()) do
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local oldSpeed = hum.WalkSpeed
                    local oldJump = hum.JumpPower
                    hum.WalkSpeed = 0
                    hum.JumpPower = 0
                    task.delay(1.6, function()
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
