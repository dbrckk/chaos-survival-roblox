-- Stable spectator target selection; only changes presentation, not gameplay.
local SpectatorTargetRules = {}

function SpectatorTargetRules.isSpectating(roundActive, participant, eliminated)
    return roundActive == true
        and (eliminated == true or participant ~= true)
end

-- A late entrant is not on the committed round roster. They can learn
-- movement on the lobby practice pads, then return to spectating, without
-- granting participation, rewards or access to the active arena. Eliminated
-- contestants must not get a second in-round attempt through this UI.
function SpectatorTargetRules.canPractice(roundActive, participant, eliminated)
    return roundActive == true and participant == false and eliminated == false
end

-- Invalid RoundState packets must not crash or reset a live spectator camera.
-- A known non-round phase ends spectating; malformed payloads are ignored.
function SpectatorTargetRules.roundActive(snapshot)
    if type(snapshot) ~= "table" or type(snapshot.phase) ~= "string" then
        return nil
    end
    return snapshot.phase == "round"
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
