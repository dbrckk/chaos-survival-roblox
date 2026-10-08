-- Stable spectator target selection; only changes presentation, not gameplay.
local SpectatorTargetRules = {}

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

    -- After elimination the next survivor already occupies the removed slot.
    return math.clamp(math.floor(tonumber(previousIndex) or 1), 1, count)
end

return SpectatorTargetRules
