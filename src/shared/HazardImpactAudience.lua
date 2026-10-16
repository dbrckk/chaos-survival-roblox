-- Cosmetic hazard impact routing only. Gameplay damage and near-miss
-- detection remain server authoritative in DisasterImpact.
local HazardImpactAudience = {}

function HazardImpactAudience.shouldSend(position, characterPosition, participant, eliminated, range)
    if typeof(position) ~= "Vector3" then
        return false
    end
    -- Spectators can be eliminated or late-joining nonparticipants.
    -- Their camera follows another avatar, not their lobby root.
    if eliminated == true or participant ~= true then
        return true
    end
    if typeof(characterPosition) ~= "Vector3" then
        return false
    end
    local reach = math.clamp(tonumber(range) or 180, 1, 250)
    return (characterPosition - position).Magnitude <= reach
end

return HazardImpactAudience
