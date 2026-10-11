--!strict
-- Event-driven lifecycle for the client-only character outline/light owner.
-- Keeps incomplete streamed rigs watchable without polling or expiry timers.
local Registry = {}

function Registry.new(onUpdate, onStop)
    assert(type(onUpdate) == "function", "CharacterPolishRegistry requires an update")
    local entries = setmetatable({}, {__mode = "k"})

    local function stop(model)
        local entry = entries[model]
        if not entry then return end
        entries[model] = nil
        for _, connection in ipairs(entry.connections) do
            connection:Disconnect()
        end
        table.clear(entry.connections)
        if onStop then onStop(model) end
    end

    local function refresh(model)
        if not entries[model] then return end
        if not model:IsDescendantOf(workspace) then
            stop(model)
            return
        end
        onUpdate(model)
    end

    local function watch(model)
        if not model or not model:IsA("Model")
            or not model:IsDescendantOf(workspace) then
            return false
        end
        if entries[model] then
            refresh(model)
            return false
        end
        local entry = {connections = {}}
        entries[model] = entry
        table.insert(entry.connections,
            model:GetAttributeChangedSignal("ChaosAccent"):Connect(function()
                refresh(model)
            end))
        table.insert(entry.connections,
            model:GetAttributeChangedSignal("AISurvivor"):Connect(function()
                refresh(model)
            end))
        local function relevant(child)
            return child:IsA("Humanoid") or child.Name == "UpperTorso"
                or child.Name == "Torso" or child.Name == "HumanoidRootPart"
                or child.Name == "ChaosAuraHighlight"
        end
        table.insert(entry.connections, model.ChildAdded:Connect(function(child)
            if relevant(child) then refresh(model) end
        end))
        table.insert(entry.connections, model.ChildRemoved:Connect(function(child)
            if relevant(child) then refresh(model) end
        end))
        table.insert(entry.connections, model.AncestryChanged:Connect(function()
            if not model:IsDescendantOf(workspace) then stop(model) end
        end))
        table.insert(entry.connections, model.Destroying:Connect(function()
            stop(model)
        end))
        refresh(model)
        return true
    end

    local function refreshAll()
        for model in pairs(entries) do
            refresh(model)
        end
    end

    local function count()
        local total = 0
        for _ in pairs(entries) do total += 1 end
        return total
    end
    return {watch = watch, stop = stop, refresh = refresh,
        refreshAll = refreshAll, count = count}
end

return Registry
