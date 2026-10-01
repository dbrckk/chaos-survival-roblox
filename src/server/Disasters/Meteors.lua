local Debris = game:GetService("Debris")
local DisasterImpact = require(script.Parent.Parent.DisasterImpact)

local D = {Name = "METEOR SHOWER", Hint = "WATCH THE WARNING CIRCLES!"}

function D.start(ctx)
    local profile = ctx.BalanceProfile or {}
    local warningSeconds = profile.MeteorWarningSeconds or 0.9
    local damage = profile.MeteorDamage or 50
    local radius = profile.MeteorRadius or 8

    task.spawn(function()
        while ctx.Active() do
            local x, z = math.random(-42,42), math.random(-42,42)
            local impactPosition = ctx.Config.ArenaCenter + Vector3.new(x, 1.2, z)

            local marker = Instance.new("Part")
            marker.Name = "MeteorWarning"
            marker.Size = Vector3.new(5.5, 0.15, 5.5)
            marker.Anchored = true
            marker.CanCollide = false
            marker.CanTouch = false
            marker.CanQuery = false
            marker.CastShadow = false
            marker.Material = Enum.Material.Neon
            marker.Color = Color3.fromRGB(255, 165, 60)
            marker.Transparency = 0.15
            marker.Position = impactPosition
            marker.Parent = workspace
            ctx.Cleanup[#ctx.Cleanup+1] = marker

            DisasterImpact.animateMarker(marker, warningSeconds, 5.5, radius * 2)

            if not ctx.Active() then
                if marker.Parent then marker:Destroy() end
                break
            end

            local meteor = Instance.new("Part")
            meteor.Name = "RoundMeteor"
            meteor.Shape = Enum.PartType.Ball
            meteor.Size = Vector3.new(7,7,7)
            meteor.Material = Enum.Material.Neon
            meteor.Color = Color3.fromRGB(255,120,40)
            meteor.Position = impactPosition + Vector3.new(0, 65, 0)
            meteor.Anchored = false
            meteor.CanCollide = true
            meteor.CanTouch = true
            meteor.Parent = workspace
            meteor.AssemblyLinearVelocity = Vector3.new(math.random(-5,5), -72, math.random(-5,5))

            local resolved = false
            local connection
            connection = meteor.Touched:Connect(function(hit)
                if resolved or not ctx.Active() then
                    return
                end

                local character = hit and hit.Parent
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if humanoid and character == meteor.Parent then
                    return
                end

                resolved = true
                if connection then
                    connection:Disconnect()
                end

                local position = meteor.Position
                DisasterImpact.applyRadialDamage(ctx, position, radius, damage)
                DisasterImpact.createBurst(position, Color3.fromRGB(255, 120, 40), radius)

                if meteor.Parent then
                    meteor:Destroy()
                end
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
