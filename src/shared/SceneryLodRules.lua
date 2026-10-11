--!strict
-- Client-only decorative distance LOD. Cosmetic hysteresis prevents scenery
-- visibility popping when a mobile camera hovers near a cutoff.
local SceneryLodRules = {}

SceneryLodRules.Hysteresis = 8

function SceneryLodRules.visible(tier, distance, lowDistance, mediumDistance,
        previouslyVisible)
    if tier ~= "Low" and tier ~= "Medium" then
        return true -- High remains fully visible, as before.
    end

    if type(distance) ~= "number" or distance < 0 or distance ~= distance then
        return false
    end
    local cutoff = tier == "Low" and lowDistance or mediumDistance
    if type(cutoff) ~= "number" or cutoff <= 0 or cutoff ~= cutoff then
        return false
    end

    if previouslyVisible == true then
        return distance <= cutoff + SceneryLodRules.Hysteresis
    elseif previouslyVisible == false then
        return distance <= math.max(0, cutoff - SceneryLodRules.Hysteresis)
    end
    return distance <= cutoff
end

return SceneryLodRules
