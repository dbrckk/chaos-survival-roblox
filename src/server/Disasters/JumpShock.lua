local D = {Name = "JUMP SHOCK", Hint = "THE GROUND KICKS BACK!"}

function D.start(ctx)
    local profile = ctx.BalanceProfile or {}
    local horizontal = profile.JumpHorizontalForce or 8

    task.spawn(function()
        while ctx.Active() do
            task.wait(math.random(4,6))
            for _, p in ipairs(ctx.Contestants or {}) do
                local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    root.AssemblyLinearVelocity += Vector3.new(
                        math.random(-horizontal,horizontal),
                        math.random(34,46),
                        math.random(-horizontal,horizontal)
                    )
                end
            end
        end
    end)
end

return D
