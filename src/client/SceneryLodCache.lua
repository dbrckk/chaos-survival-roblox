--!strict
-- Streaming-safe, client-only scenery LOD cache. Roblox can replicate an
-- already-populated Model or Attachment in a single hierarchy mutation.
-- Treat every change as dirty, then rebuild lazily in the EXISTING LOD tick.
local SceneryLodCache = {}
function SceneryLodCache.watch(root, cache)
    assert(typeof(root) == "Instance" and type(cache) == "table",
        "SceneryLodCache.watch requires an Instance and cache")
    root.DescendantAdded:Connect(function()
        cache.dirty = true
    end)
    root.DescendantRemoving:Connect(function()
        cache.dirty = true
    end)
end

function SceneryLodCache.refresh(root, cache, classify)
    assert(typeof(root) == "Instance" and type(cache) == "table"
        and type(classify) == "function",
        "SceneryLodCache.refresh requires root, cache and classifier")
    table.clear(cache.entries)
    for _, descendant in ipairs(root:GetDescendants()) do
        if classify(descendant) then
            cache.entries[#cache.entries + 1] = descendant
        end
    end
    cache.dirty = false
    return cache.entries
end

return SceneryLodCache
