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

function DisasterImpact.nearMissForDistance(distance, radius, margin)
    local safeRadius = math.max(0.001, tonumber(radius) or 0.001)
    local safeMargin = math.max(0, tonumber(margin) or 0)
    local safeDistance = math.max(0, tonumber(distance) or 0)

    return safeDistance > safeRadius and safeDistance <= (safeRadius + safeMargin)
end

function DisasterImpact.applyRadialDamage(ctx, position, radius, maxDamage, hazardKind)
    local hits = 0

    for _, player in ipairs(ctx.HazardContestants or ctx.Contestants or {}) do
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
                if hazardKind and ctx.OnHazardDamage then
                    pcall(ctx.OnHazardDamage, player, hazardKind, damage)
                end
                humanoid:TakeDamage(damage)
                hits += 1
            elseif hazardKind
                and DisasterImpact.nearMissForDistance(distance, radius, 3.5)
                and ctx.OnHazardNearMiss
            then
                pcall(ctx.OnHazardNearMiss, player, hazardKind, distance, radius)
            end
        end
    end

    return hits
end


return DisasterImpact
