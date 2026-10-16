--!strict
-- Event-driven cosmetic ownership for human/bot models. Explicitly releases
-- descendant listeners as rigs stream away and rejects deferred stale work.
local Registry = {}

local TYPES = {
    ChaosAura = "ParticleEmitter",
    ChaosAuraLight = "PointLight",
    ChaosTrail = "Trail",
    AISurvivorCosmeticTrail = "Trail",
    ChaosAuraHighlight = "Highlight",
}

function Registry.relevant(instance)
    if typeof(instance) ~= "Instance" then return false end
    local expectedType = TYPES[instance.Name]
    return expectedType ~= nil and instance:IsA(expectedType)
end

function Registry.new(onRefresh, onNewEffect)
    assert(type(onRefresh) == "function", "onRefresh callback required")
    assert(type(onNewEffect) == "function", "onNewEffect callback required")
    local entries = {}

    local function stop(model)
        local entry = entries[model]
        if not entry then return false end
        entries[model] = nil
        for _, connection in ipairs(entry.connections) do
            connection:Disconnect()
        end
        table.clear(entry.connections)
        return true
    end

    local function refresh(model)
        if not entries[model] then return false end
        if not model.Parent then return false end
        onRefresh(model)
        return true
    end

    local function watch(model)
        if typeof(model) ~= "Instance" or not model:IsA("Model") then
            return false
        end
        if entries[model] then return false end
        -- CharacterAdded may precede parenting a new rig into workspace.
        -- Keep it pending until its first attachment instead of losing it.
        local entry = {connections = {}, everParented = model.Parent ~= nil}
        entries[model] = entry
        table.insert(entry.connections, model.DescendantAdded:Connect(function(child)
            if not Registry.relevant(child) then return end
            -- Roblox can defer event delivery until after a bot was removed.
            task.defer(function()
                if entries[model] == entry and child:IsDescendantOf(model) then
                    onNewEffect(child)
                end
            end)
        end))
        table.insert(entry.connections, model.AncestryChanged:Connect(function()
            if entries[model] ~= entry then return end
            if model.Parent == nil then
                if entry.everParented then stop(model) end
            elseif not entry.everParented then
                entry.everParented = true
                refresh(model)
            end
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
        local n = 0
        for _ in pairs(entries) do n += 1 end
        return n
    end

    return {
        watch = watch,
        stop = stop,
        refresh = refresh,
        refreshAll = refreshAll,
        count = count,
    }
end

return Registry
