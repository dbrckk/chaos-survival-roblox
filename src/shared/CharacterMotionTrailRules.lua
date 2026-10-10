-- Cosmetic human momentum trail budget; never affects movement or damage.
local Rules = {}

function Rules.visible(phase, finalRush, airborne, ratio, tier, reduceMotion, distance)
    if phase ~= "round" or finalRush == true or airborne == true
        or reduceMotion == true or (tier ~= "Medium" and tier ~= "High")
    then
        return false
    end
    local limit = tier == "High" and 90 or 60
    return (tonumber(ratio) or 0) > 0.82
        and (tonumber(distance) or math.huge) <= limit
end

function Rules.style(tier)
    if tier == "High" then
        return 0.14, 0.34
    elseif tier == "Medium" then
        return 0.1092, 0.2244
    end
    return 0, 0
end

return Rules
