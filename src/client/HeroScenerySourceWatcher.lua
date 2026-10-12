-- Small lifecycle watcher for client-owned animated hero scenery.
-- Only direct BasePart changes can change the set of animated ornaments.
-- No polling, waits or server ownership.
local SourceWatcher = {}

function SourceWatcher.watch(folder, onChange)
    assert(typeof(folder) == "Instance" and folder:IsA("Folder")
        and type(onChange) == "function",
        "HeroScenerySourceWatcher.watch expects Folder and callback")
    local alive = true
    local function changed(child)
        if alive and child:IsA("BasePart") then
            onChange()
        end
    end
    local added = folder.ChildAdded:Connect(changed)
    local removed = folder.ChildRemoved:Connect(changed)
    return function()
        alive = false
        added:Disconnect()
        removed:Disconnect()
    end
end

return SourceWatcher
