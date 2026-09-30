local Debris = game:GetService("Debris")
local D = {Name = "METEOR SHOWER", Hint = "WATCH THE WARNING CIRCLES!"}

function D.start(ctx)
    local profile = ctx.BalanceProfile or {}
    local warningSeconds = profile.MeteorWarningSeconds or 0.9
    local damage = profile.MeteorDamage or 50

    task.spawn(function()
        while ctx.Active() do
            local x, z = math.random(-42,42), math.random(-42,42)

            local marker = Instance.new("Part")
            marker.Name = "MeteorWarning"
            marker.Size = Vector3.new(8, 0.15, 8)
            marker.Anchored = true
            marker.CanCollide = false
            marker.Material = Enum.Material.Neon
            marker.Color = Color3.fromRGB(255, 165, 60)
            marker.Transparency = 0.15
            marker.Position = ctx.Config.ArenaCenter + Vector3.new(x, 1.15, z)
            marker.Parent = workspace
            ctx.Cleanup[#ctx.Cleanup+1] = marker

            task.wait(warningSeconds)
            if not ctx.Active() then
                if marker.Parent then marker:Destroy() end
                break
            end

            local meteor = Instance.new("Part")
            meteor.Shape = Enum.PartType.Ball
            meteor.Size = Vector3.new(7,7,7)
            meteor.Material = Enum.Material.Neon
            meteor.Color = Color3.fromRGB(255,120,40)
            meteor.Position = ctx.Config.ArenaCenter + Vector3.new(x, 65, z)
            meteor.Anchored = false
            meteor.CanCollide = true
            meteor.Parent = workspace
            meteor.AssemblyLinearVelocity = Vector3.new(math.random(-5,5), -72, math.random(-5,5))

            meteor.Touched:Connect(function(hit)
                local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
                if hum then hum:TakeDamage(damage) end
            end)

            if marker.Parent then marker:Destroy() end
            ctx.Cleanup[#ctx.Cleanup+1] = meteor
            Debris:AddItem(meteor, 6)
            local intensity = ctx.Intensity and ctx.Intensity() or 1
            task.wait(math.max(0.48, 0.7 / intensity))
        end
    end)
end

return D
