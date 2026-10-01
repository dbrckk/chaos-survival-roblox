local RemoteRegistry = {}

function RemoteRegistry.ensureFolder(parent, name)
    local existing = parent:FindFirstChild(name)
    if existing and not existing:IsA("Folder") then
        existing:Destroy()
        existing = nil
    end

    local folder = existing or Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

function RemoteRegistry.ensureRemoteEvent(parent, name)
    local existing = parent:FindFirstChild(name)
    if existing and not existing:IsA("RemoteEvent") then
        existing:Destroy()
        existing = nil
    end

    local remote = existing or Instance.new("RemoteEvent")
    remote.Name = name
    remote.Parent = parent
    return remote
end

return RemoteRegistry
