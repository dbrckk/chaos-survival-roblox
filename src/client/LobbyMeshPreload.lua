-- Wait for geometry in already authenticated lobby templates.
local ContentProvider = game:GetService("ContentProvider")

local LobbyMeshPreload = {}

function LobbyMeshPreload.new(onChanged)
    local pendingMeshes = {}
    local preloadAttempts = {}

    return function(template)
        local requested = {}
        local ready = true
        for _, part in ipairs(template:GetDescendants()) do
            if not part:IsA("MeshPart") then continue end
            local id = part.MeshId
            if ContentProvider:GetAssetFetchStatus(id) ~= Enum.AssetFetchStatus.Success then
                ready = false
                local attempts = preloadAttempts[id] or 0
                if not pendingMeshes[id] and attempts < 2 then
                    pendingMeshes[id] = true
                    preloadAttempts[id] = attempts + 1
                    requested[#requested + 1] = id
                end
            end
        end
        if #requested == 0 then return ready end

        task.spawn(function()
            pcall(ContentProvider.PreloadAsync, ContentProvider, requested)
            local retry = {}
            for _, id in ipairs(requested) do
                local loaded = ContentProvider:GetAssetFetchStatus(id) == Enum.AssetFetchStatus.Success
                if loaded or preloadAttempts[id] >= 2 then
                    pendingMeshes[id] = nil
                else
                    retry[#retry + 1] = id
                end
            end
            if #retry > 0 then
                task.delay(20, function()
                    for _, id in ipairs(retry) do pendingMeshes[id] = nil end
                    onChanged()
                end)
            end
            onChanged()
        end)
        return false
    end
end

return LobbyMeshPreload
