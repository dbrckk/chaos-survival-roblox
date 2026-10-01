local Debris = game:GetService("Debris")

local DisasterImpact = {}

function DisasterImpact.damageForDistance(distance, radius, maxDamage)
    local safeRadius = math.max(0.001, tonumber(radius) or 0.001)
    local safeDamage = math.max(0, tonumber(maxDamage) or 0)
    local safeDistance = math.max(0, tonumber(distance) or 0)

    if safeDistance > safeRadius then
        return 0
    end

    local alpha = math.clamp(safeDistance / safeRadius, 0, 1)
    local multiplier = 1 - (0.65 * alpha)
    return math.floor((safeDamage * multiplier) + 0.5)
end

function DisasterImpact.applyRadialDamage(ctx, position, radius, maxDamage)
    local hits = 0

    for _, player in ipairs(ctx.Contestants or {}) do
        if ctx.IsContestantActive and not ctx.IsContestantActive(player) then
            continue
        end

        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if root and humanoid and humanoid.Health > 0 then
            local distance = (root.Position - position).Magnitude
            local damage = DisasterImpact.damageForDistance(distance, radius, maxDamage)
            if damage > 0 then
                humanoid:TakeDamage(damage)
                hits += 1
            end
        end
    end

    return hits
end

function DisasterImpact.createBurst(position, color, radius)
    local burst = Instance.new("Part")
    burst.Name = "HazardImpactBurst"
    burst.Shape = Enum.PartType.Ball
    burst.Size = Vector3.new(1, 1, 1)
    burst.Position = position
    burst.Anchored = true
    burst.CanCollide = false
    burst.CanTouch = false
    burst.CanQuery = false
    burst.CastShadow = false
    burst.Material = Enum.Material.Neon
    burst.Color = color
    burst.Transparency = 0.18
    burst.Parent = workspace

    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = 2.4
    light.Range = math.max(12, radius * 2.2)
    light.Shadows = false
    light.Parent = burst

    task.spawn(function()
        local started = os.clock()
        local duration = 0.24
        while burst.Parent do
            local alpha = math.clamp((os.clock() - started) / duration, 0, 1)
            local diameter = 1 + ((radius * 2) * alpha)
            burst.Size = Vector3.new(diameter, diameter, diameter)
            burst.Transparency = 0.18 + (0.82 * alpha)
            light.Brightness = 2.4 * (1 - alpha)

            if alpha >= 1 then
                break
            end
            task.wait()
        end
    end)

    Debris:AddItem(burst, 0.32)
    return burst
end

function DisasterImpact.animateMarker(marker, seconds, startSize, endSize)
    local duration = math.max(0.05, tonumber(seconds) or 0.05)
    local started = os.clock()

    while marker.Parent do
        local alpha = math.clamp((os.clock() - started) / duration, 0, 1)
        local pulse = (math.sin(alpha * math.pi * 6) + 1) * 0.5
        local diameter = startSize + ((endSize - startSize) * alpha)

        marker.Size = Vector3.new(diameter, marker.Size.Y, diameter)
        marker.Transparency = 0.12 + (pulse * 0.24)

        if alpha >= 1 then
            break
        end
        task.wait(0.035)
    end
end

return DisasterImpact
