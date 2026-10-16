-- Event-driven remote-player Phase Dash pulse observer.
-- Disconnect player and avatar subscriptions on removal/respawn.
-- No polling, render connections, persistent attachments or extra instances.
local Registry = {}

function Registry.new(onPulse)
    assert(type(onPulse) == "function", "onPulse callback required")
    local watchers = {}

    local function detachPulse(entry)
        if entry.pulse then
            entry.pulse:Disconnect()
            entry.pulse = nil
        end
        entry.character = nil
    end

    local function stop(player)
        local entry = watchers[player]
        if not entry then return false end
        watchers[player] = nil
        detachPulse(entry)
        entry.added:Disconnect()
        entry.removing:Disconnect()
        return true
    end

    local function bindCharacter(player, character)
        local entry = watchers[player]
        if not entry then return end
        detachPulse(entry)
        if not character or not character:IsA("Model") then return end
        entry.character = character
        entry.pulse = character:GetAttributeChangedSignal("PhaseDashPulse")
            :Connect(function()
                if watchers[player] == entry and entry.character == character
                    and player.Character == character then
                    onPulse(character, player)
                end
            end)
    end

    local function watch(player)
        if not player or watchers[player] then return false end
        local entry = {}
        watchers[player] = entry
        entry.added = player.CharacterAdded:Connect(function(character)
            bindCharacter(player, character)
        end)
        entry.removing = player.CharacterRemoving:Connect(function(character)
            if entry.character == character then detachPulse(entry) end
        end)
        if player.Character then bindCharacter(player, player.Character) end
        return true
    end

    local function count()
        local total = 0
        for _ in pairs(watchers) do total += 1 end
        return total
    end
    return {watch = watch, stop = stop, count = count}
end

return Registry
