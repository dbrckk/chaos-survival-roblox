local Players = game:GetService("Players")
local D = {Name = "TORNADO", Hint = "STAY AWAY FROM THE CENTER!"}

function D.start(ctx)
    task.spawn(function()
        while ctx.Active() do
            for _, player in ipairs(Players:GetPlayers()) do
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local delta = root.Position - ctx.Config.ArenaCenter
                    local horizontal = Vector3.new(delta.X, 0, delta.Z)
                    local dist = horizontal.Magnitude
                    if dist < 45 then
                        local tangent = Vector3.new(-horizontal.Z, 0, horizontal.X)
                        if tangent.Magnitude > 0 then
                            tangent = tangent.Unit
                        end
                        root.AssemblyLinearVelocity += tangent * 20 + Vector3.new(0, math.max(0, 28 - dist * 0.4), 0)
                    end
                end
            end
            task.wait(0.2)
        end
    end)
end

return D
