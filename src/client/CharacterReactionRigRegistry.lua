--!strict
-- Event-driven lifecycle owner for short cosmetic character reactions.
-- Handles late Humanoid/Root replication, streamed replacement and cleanup.
-- Never changes movement, health, character Animator or physics.
local RigRegistry = {}

function RigRegistry.new(onState)
    assert(type(onState) == "function", "RigRegistry.new requires a callback")
    local entries = setmetatable({}, {__mode = "k"})

    local function stop(model)
        if not model then return end
        local entry = entries[model]
        if not entry then return end
        entries[model] = nil
        for _, connection in ipairs(entry.connections) do
            connection:Disconnect()
        end
        table.clear(entry.connections)
        if entry.stateChanged then
            entry.stateChanged:Disconnect()
            entry.stateChanged = nil
        end
        entry.humanoid = nil
        entry.root = nil
        entry.airborneAt = nil
    end

    local function bind(model, entry)
        if entries[model] ~= entry or not model:IsDescendantOf(workspace) then
            stop(model)
            return
        end
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")
        if not root or not root:IsA("BasePart") then root = nil end
        if humanoid == entry.humanoid and root == entry.root then return end
        -- A replacement Humanoid or streamed-out root ends the old jump:
        -- never deliver its stale landing to the new rig.
        if entry.stateChanged then
            entry.stateChanged:Disconnect()
            entry.stateChanged = nil
        end
        entry.airborneAt = nil
        entry.humanoid, entry.root = humanoid, root
        if not humanoid or not root then return end
        entry.stateChanged = humanoid.StateChanged:Connect(function(_, state)
            if entries[model] == entry
                and entry.humanoid == humanoid and entry.root == root
                and model:IsDescendantOf(workspace)
                and humanoid.Parent == model and root.Parent == model then
                onState(model, root, state, entry)
            end
        end)
    end

    local function watch(model)
        if not model or not model:IsA("Model")
            or not model:IsDescendantOf(workspace) then
            return false
        end
        local existing = entries[model]
        if existing then
            bind(model, existing)
            return false
        end
        -- Keep lightweight ChildAdded/Removed watchers for the lifetime
        -- of a *live* model: the old fixed 8s timeout lost late streams.
        -- Ancestry/Destroying and explicit CharacterRemoving disconnect all.
        local entry = {
            connections = {},
            stateChanged = nil,
            humanoid = nil,
            root = nil,
            airborneAt = nil,
        }
        entries[model] = entry
        table.insert(entry.connections, model.ChildAdded:Connect(function(child)
            if child:IsA("Humanoid") or child.Name == "HumanoidRootPart" then
                bind(model, entry)
            end
        end))
        table.insert(entry.connections, model.ChildRemoved:Connect(function(child)
            if child == entry.humanoid or child == entry.root then
                bind(model, entry)
            end
        end))
        table.insert(entry.connections, model.AncestryChanged:Connect(function()
            if not model:IsDescendantOf(workspace) then stop(model) end
        end))
        table.insert(entry.connections, model.Destroying:Connect(function()
            stop(model)
        end))
        bind(model, entry)
        return true
    end

    local function rig(model)
        local entry = entries[model]
        if not entry or not entry.stateChanged then return nil end
        return entry.root, entry.humanoid
    end

    local function count()
        local total = 0
        for _ in pairs(entries) do total += 1 end
        return total
    end

    -- Phase changes discard jump history without tearing down rig listeners.
    -- Required for long-lived streamed rigs on back-to-back rounds.
    local function clearAirborne()
        for _, entry in pairs(entries) do
            entry.airborneAt = nil
        end
    end

    return {watch = watch, stop = stop, rig = rig, count = count,
        clearAirborne = clearAirborne}
end

return RigRegistry
