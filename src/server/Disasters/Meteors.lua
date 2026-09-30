local Debris = game:GetService("Debris")
local D = {Name = "METEOR SHOWER", Hint = "KEEP MOVING!"}

function D.start(ctx)
    task.spawn(function()
        while ctx.Active() do
            local meteor = Instance.new("Part")
            meteor.Shape = Enum.PartType.Ball
            meteor.Size = Vector3.new(7,7,7)
            meteor.Material = Enum.Material.Neon
            meteor.Color = Color3.fromRGB(255,120,40)
            meteor.Position = ctx.Config.ArenaCenter + Vector3.new(math.random(-45,45), 65, math.random(-45,45))
            meteor.Anchored = false
            meteor.CanCollide = true
            meteor.Parent = workspace
            meteor.AssemblyLinearVelocity = Vector3.new(math.random(-8,8), -85, math.random(-8,8))

            meteor.Touched:Connect(function(hit)
                local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
                if hum then hum:TakeDamage(60) end
            end)

            ctx.Cleanup[#ctx.Cleanup+1] = meteor
            Debris:AddItem(meteor, 6)
            task.wait(0.45)
        end
    end)
end

return D
