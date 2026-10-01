local DisasterImpact = if script then require(script.Parent.Parent.DisasterImpact) else require("../DisasterImpact")
local HazardWarning = if script then require(script.Parent.Parent.HazardWarning) else require("../HazardWarning")

local D = {Name = "BOMB RAIN", Hint = "WATCH THE RED MARKERS!"}

function D.start(ctx)
    local profile = ctx.BalanceProfile or {}
    local warningSeconds = profile.BombWarningSeconds or 1.25
    local damage = profile.BombDamage or 48
    local radius = profile.BombRadius or 8

    task.spawn(function()
        while ctx.Active() do
            local x, z = math.random(-42,42), math.random(-42,42)
            local impactPosition = ctx.Config.ArenaCenter + Vector3.new(x, 1.2, z)

            local marker = Instance.new("Part")
            marker.Name = "BombWarning"
            marker.Size = Vector3.new(5.5,0.2,5.5)
            marker.Anchored = true
            marker.CanCollide = false
            marker.CanTouch = false
            marker.CanQuery = false
            marker.CastShadow = false
            marker.Material = Enum.Material.Neon
            marker.Color = Color3.fromRGB(255,50,50)
            marker.Position = impactPosition
            marker.Parent = workspace
            ctx.Cleanup[#ctx.Cleanup+1] = marker

            task.spawn(function()
                HazardWarning.configure(marker, "Bomb", warningSeconds, 5.5, radius * 2)
                task.wait(warningSeconds)
                if not marker.Parent or not ctx.Active() then
                    return
                end

                local position = marker.Position + Vector3.new(0, 1, 0)
                marker:Destroy()

                DisasterImpact.applyRadialDamage(ctx, position, radius, damage)
                if ctx.OnHazardImpact then
                    pcall(ctx.OnHazardImpact, position, Color3.fromRGB(255, 65, 65), radius, "Bomb")
                end
            end)

            local intensity = ctx.Intensity and ctx.Intensity() or 1
            task.wait(math.max(0.68, 1.0 / intensity))
        end
    end)
end

return D
