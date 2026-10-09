-- Stable spectator target selection; only changes presentation, not gameplay.
local SpectatorTargetRules = {}

function SpectatorTargetRules.isSpectating(roundActive, participant, eliminated)
    return roundActive == true
        and (eliminated == true or participant ~= true)
end

-- A living AI rig may still be in the lobby, between respawn and ready.
-- Spectators must only follow active survivors from the current arena.
function SpectatorTargetRules.isEligibleBot(inRound, health)
    return inRound == true and type(health) == "number" and health > 0
end

function SpectatorTargetRules.resolveIndex(targets, selectedCharacter, previousIndex, advance)
    local count = type(targets) == "table" and #targets or 0
    if count == 0 then
        return 0
    end

    if selectedCharacter ~= nil then
        for index, target in ipairs(targets) do
            if target.Character == selectedCharacter then
                if advance == true then
                    return (index % count) + 1
                end
                return index
            end
        end
    end

    -- After elimination, the successor occupies the removed slot. If the
    -- eliminated target was last, wrap to the first surviving target.
    local slot = math.max(1, math.floor(tonumber(previousIndex) or 1))
    return ((slot - 1) % count) + 1
end

return SpectatorTargetRules
