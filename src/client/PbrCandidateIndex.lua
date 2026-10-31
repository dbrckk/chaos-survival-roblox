-- Cache only BaseParts eligible for a future PBR decision.
-- Rebuilding on streaming events avoids a full GetDescendants() walk each
-- time an Android camera crosses the 28-degree/32-stud rescan threshold.
-- No per-Part connections, polling or changes to PBR ownership/materials.
local Index = {}

function Index.watch(root, onChanged)
    assert(typeof(root) == "Instance" and type(onChanged) == "function",
        "PbrCandidateIndex.watch requires an Instance and callback")

    local parts = {}
    local alive = true

    local function addTree(instance)
        if instance:IsA("BasePart") then
            parts[instance] = true
        end
        for _, descendant in ipairs(instance:GetDescendants()) do
            if descendant:IsA("BasePart") then
                parts[descendant] = true
            end
        end
    end

    local function removeTree(instance)
        if instance:IsA("BasePart") then
            parts[instance] = nil
        end
        for _, descendant in ipairs(instance:GetDescendants()) do
            if descendant:IsA("BasePart") then
                parts[descendant] = nil
            end
        end
    end

    -- A populated streamed building can emit DescendantAdded for the Model,
    -- its Folders, and every Part in one burst. Walk each highest queued
    -- subtree once at the end of the scheduler turn, rather than doing
    -- repeated GetDescendants() scans of the same geometry.
    local pendingAdds = {}
    local flushScheduled = false

    -- Roblox can dispatch DescendantRemoving for both a removed Model
    -- and its nested Parts. The old implementation called GetDescendants
    -- for EVERY callback, repeatedly scanning an entire streamed subtree.
    -- Prune the first removed subtree synchronously, then skip children
    -- already covered by it until the end of the scheduler turn.
    local removedRoots = {}
    local removalFlushScheduled = false
    local function flushRemovals()
        removalFlushScheduled = false
        table.clear(removedRoots)
        if alive then onChanged() end
    end

    local function flushAdds()
        flushScheduled = false
        if not alive then return end
        local batch = pendingAdds
        pendingAdds = {}
        local changed = false
        for instance in pairs(batch) do
            if instance:IsDescendantOf(root) then
                local parent = instance.Parent
                local covered = false
                while parent and parent ~= root do
                    if batch[parent] then
                        covered = true
                        break
                    end
                    parent = parent.Parent
                end
                if not covered then
                    addTree(instance)
                    changed = true
                end
            end
        end
        if changed then onChanged() end
    end

    addTree(root)
    local added = root.DescendantAdded:Connect(function(instance)
        if not alive then return end
        pendingAdds[instance] = true
        if flushScheduled then return end
        flushScheduled = true
        task.defer(flushAdds)
    end)
    local removed = root.DescendantRemoving:Connect(function(instance)
        if not alive then return end
        -- DescendantRemoving fires before the subtree is detached or
        -- destroyed. Remove each FIRST affected tree synchronously, so
        -- the parts table can never serve a detached Part to the PBR scan.
        local ancestor = instance.Parent
        while ancestor and ancestor ~= root do
            if removedRoots[ancestor] then
                pendingAdds[instance] = nil
                return
            end
            ancestor = ancestor.Parent
        end
        removedRoots[instance] = true
        removeTree(instance)
        pendingAdds[instance] = nil
        -- Keep PBR invalidation once per removal burst, rather than once
        -- for every Part in a large atomic streamed building.
        if not removalFlushScheduled then
            removalFlushScheduled = true
            task.defer(flushRemovals)
        end
    end)

    return parts, function()
        if not alive then return end
        alive = false
        added:Disconnect()
        removed:Disconnect()
        table.clear(pendingAdds)
        table.clear(removedRoots)
        table.clear(parts)
    end
end

return Index
