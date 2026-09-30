local Players = game:GetService("Players")
local D = {Name = "TORNADO", Hint = "KEEP YOUR DISTANCE!"}

function D.start(ctx)
    local profile = ctx.BalanceProfile or {}
    local force = profile.TornadoForce or 17

    task.spawn(function()
        while ctx.Active() do
            for _, player in ipairs(Players:GetPlayers()) do
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local delta = root.Position - ctx.Config.ArenaCenter
                    local horizontal = Vector3.new(delta.X, 0, delta.Z)
                    local dist = horizontal.Magnitude
                    if dist < 42 and dist > 2 then
                        local tangent = Vector3.new(-horizontal.Z, 0, horizontal.X).Unit
                        local strength = math.clamp((42 - dist) / 42, 0, 1)
                        root.AssemblyLinearVelocity += tangent * force * strength + Vector3.new(0, 10 * strength, 0)
                    end
                end
            end
            task.wait(0.25)
        end
    end)
end

return D
