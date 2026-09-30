local Debris = game:GetService("Debris")
local D = {Name = "BOMB RAIN", Hint = "WATCH THE RED MARKERS!"}

function D.start(ctx)
    local profile = ctx.BalanceProfile or {}
    local warningSeconds = profile.BombWarningSeconds or 1.25

    task.spawn(function()
        while ctx.Active() do
            local x, z = math.random(-42,42), math.random(-42,42)
            local marker = Instance.new("Part")
            marker.Size = Vector3.new(8,0.2,8)
            marker.Anchored = true
            marker.CanCollide = false
            marker.Material = Enum.Material.Neon
            marker.Color = Color3.fromRGB(255,50,50)
            marker.Position = ctx.Config.ArenaCenter + Vector3.new(x,1.2,z)
            marker.Parent = workspace
            ctx.Cleanup[#ctx.Cleanup+1] = marker

            task.delay(warningSeconds, function()
                if not marker or not marker.Parent or not ctx.Active() then return end
                local explosion = Instance.new("Explosion")
                explosion.Position = marker.Position + Vector3.new(0,1,0)
                explosion.BlastRadius = 8
                explosion.BlastPressure = 0
                explosion.DestroyJointRadiusPercent = 0
                explosion.Parent = workspace
                marker:Destroy()
                Debris:AddItem(explosion, 1)
            end)

            task.wait(1.0)
        end
    end)
end

return D
