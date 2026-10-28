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

    addTree(root)
    local added = root.DescendantAdded:Connect(function(instance)
        if not alive then return end
        addTree(instance)
        onChanged()
    end)
    local removed = root.DescendantRemoving:Connect(function(instance)
        if not alive then return end
        removeTree(instance)
        onChanged()
    end)

    return parts, function()
        if not alive then return end
        alive = false
        added:Disconnect()
        removed:Disconnect()
        table.clear(parts)
    end
end

return Index
