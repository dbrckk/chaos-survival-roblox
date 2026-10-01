local Debris = game:GetService("Debris")
local DisasterImpact = if script then require(script.Parent.Parent.DisasterImpact) else require("../DisasterImpact")
local HazardWarning = if script then require(script.Parent.Parent.HazardWarning) else require("../HazardWarning")

local D = {Name = "METEOR SHOWER", Hint = "WATCH THE WARNING CIRCLES!"}

function D.start(ctx)
    local profile = ctx.BalanceProfile or {}
    local warningSeconds = profile.MeteorWarningSeconds or 0.9
    local damage = profile.MeteorDamage or 50
    local radius = profile.MeteorRadius or 8
    local travelSeconds = 0.5

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

            HazardWarning.configure(marker, "Meteor", warningSeconds, 5.5, radius * 2)
            task.wait(warningSeconds)

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
            meteor.Position = impactPosition + Vector3.new(0, 52, 0)
            meteor.Anchored = false
            meteor.CanCollide = false
            meteor.CanTouch = false
            meteor.CanQuery = false
            meteor.CastShadow = false
            meteor.Parent = workspace
            meteor.AssemblyLinearVelocity = Vector3.new(0, -70, 0)

            if marker.Parent then marker:Destroy() end
            ctx.Cleanup[#ctx.Cleanup+1] = meteor
            Debris:AddItem(meteor, travelSeconds + 1)

            task.delay(travelSeconds, function()
                if not ctx.Active() then
                    if meteor.Parent then
                        meteor:Destroy()
                    end
                    return
                end

                if meteor.Parent then
                    meteor.Position = impactPosition + Vector3.new(0, 1, 0)
                end

                local position = impactPosition + Vector3.new(0, 1, 0)
                DisasterImpact.applyRadialDamage(ctx, position, radius, damage, "Meteor")
                if ctx.OnHazardImpact then
                    pcall(ctx.OnHazardImpact, position, Color3.fromRGB(255, 120, 40), radius, "Meteor")
                end

                if meteor.Parent then
                    meteor:Destroy()
                end
            end)

            local intensity = ctx.Intensity and ctx.Intensity() or 1
            task.wait(math.max(0.48, 0.7 / intensity))
        end
    end)
end

return D
