local Players = game:GetService("Players")
local D = {Name = "JUMP SHOCK", Hint = "THE GROUND KICKS BACK!"}

function D.start(ctx)
    task.spawn(function()
        while ctx.Active() do
            task.wait(math.random(3,5))
            for _, p in ipairs(Players:GetPlayers()) do
                local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    root.AssemblyLinearVelocity += Vector3.new(math.random(-10,10), math.random(38,55), math.random(-10,10))
                end
            end
        end
    end)
end

return D
