local DisasterImpact = {}

-- Streaming/physics can yield NaN or infinite positions and parameters.
-- Invalid impact distances must never become center hits or near misses.
local function finiteNumber(value)
    local number = tonumber(value)
    if number == nil or number ~= number
        or number == math.huge or number == -math.huge then
        return nil
    end
    return number
end

function DisasterImpact.damageForDistance(distance, radius, maxDamage)
    local safeDistance = finiteNumber(distance)
    local safeDamage = finiteNumber(maxDamage)
    if safeDistance == nil or safeDamage == nil or safeDamage <= 0 then
        return 0
    end

    local safeRadius = math.max(0.001, finiteNumber(radius) or 0.001)
    safeDistance = math.max(0, safeDistance)

    if safeDistance > safeRadius then
        return 0
    end

    local alpha = math.clamp(safeDistance / safeRadius, 0, 1)
    local multiplier = 1 - (0.65 * alpha)
    return math.floor((safeDamage * multiplier) + 0.5)
end

function DisasterImpact.nearMissForDistance(distance, radius, margin)
    local safeDistance = finiteNumber(distance)
    if safeDistance == nil then
        return false
    end
    local safeRadius = math.max(0.001, finiteNumber(radius) or 0.001)
    local safeMargin = math.max(0, finiteNumber(margin) or 0)
    safeDistance = math.max(0, safeDistance)

    return safeDistance > safeRadius and safeDistance <= (safeRadius + safeMargin)
end

function DisasterImpact.applyRadialDamage(ctx, position, radius, maxDamage, hazardKind)
    local hits = 0

    for _, player in ipairs(ctx.HazardContestants or ctx.Contestants or {}) do
        -- An impact may eliminate the last survivor and end the round while
        -- its damage callbacks are still being delivered. Do not carry a
        -- single blast into the next lobby/round or credit a stale near miss.
        -- Some pure test contexts deliberately omit Active.
        if type(ctx.Active) == "function" and not ctx.Active() then
            break
        end
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
                local appliedDamage = math.min(damage, humanoid.Health)
                if hazardKind and ctx.OnHazardDamage then
                    pcall(ctx.OnHazardDamage, player, hazardKind, appliedDamage)
                end
                humanoid:TakeDamage(appliedDamage)
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
