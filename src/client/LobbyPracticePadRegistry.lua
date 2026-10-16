-- Client-only registry for late-replicated lobby boost pads.
-- Watch a small named lobby subtree rather than all workspace parts:
-- attributes may replicate after DescendantAdded and must be observed.
local Registry = {}

function Registry.isCandidate(pad)
    if typeof(pad) ~= "Instance" or not pad:IsA("BasePart") then
        return false
    end
    local activities = pad.Parent
    local lobby = activities and activities.Parent
    local generated = lobby and lobby.Parent
    return activities ~= nil and activities.Name == "Activities"
        and lobby ~= nil and lobby.Name == "Lobby"
        and generated ~= nil and generated.Name == "GeneratedMap"
end

function Registry.new(onAttach, onDetach)
    assert(type(onAttach) == "function", "onAttach callback required")
    assert(type(onDetach) == "function", "onDetach callback required")
    local watchers = {}

    local function stop(pad)
        local entry = watchers[pad]
        if not entry then return false end
        watchers[pad] = nil
        entry.changed:Disconnect()
        if entry.attached then onDetach(pad) end
        return true
    end

    local function watch(pad)
        if not Registry.isCandidate(pad) or watchers[pad] then
            return false
        end

        local entry = {attached = false}
        watchers[pad] = entry
        local function sync()
            if watchers[pad] ~= entry then return end
            local shouldAttach = pad:GetAttribute("LobbyPracticePad") == true
            if shouldAttach == entry.attached then return end
            entry.attached = shouldAttach
            if shouldAttach then
                onAttach(pad)
            else
                onDetach(pad)
            end
        end

        entry.changed = pad:GetAttributeChangedSignal("LobbyPracticePad")
            :Connect(sync)
        sync() -- attributes can be present before the observation begins.
        return true
    end

    local function count()
        local n = 0
        for _ in pairs(watchers) do n += 1 end
        return n
    end

    return {watch = watch, stop = stop, count = count}
end

return Registry
