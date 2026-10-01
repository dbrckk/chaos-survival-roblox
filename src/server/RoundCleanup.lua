local RoundCleanup = {}

function RoundCleanup.disconnectAll(connections, onError)
    local failures = 0
    for key, connection in pairs(connections or {}) do
        if connection then
            local ok, err = pcall(function()
                connection:Disconnect()
            end)
            if not ok then
                failures += 1
                if onError then
                    onError("disconnect", key, err)
                end
            end
        end
    end
    return failures
end

function RoundCleanup.runCallbacks(callbacks, onError)
    local failures = 0
    local list = callbacks or {}
    for index = #list, 1, -1 do
        local callback = list[index]
        local ok, err = pcall(callback)
        if not ok then
            failures += 1
            if onError then
                onError("callback", index, err)
            end
        end
    end
    return failures
end

function RoundCleanup.destroyAll(objects, onError)
    local failures = 0
    local list = objects or {}
    for index = #list, 1, -1 do
        local object = list[index]
        if object and object.Parent then
            local ok, err = pcall(function()
                object:Destroy()
            end)
            if not ok then
                failures += 1
                if onError then
                    onError("destroy", index, err)
                end
            end
        end
    end
    return failures
end

function RoundCleanup.execute(connections, callbacks, objects, onError)
    return RoundCleanup.disconnectAll(connections, onError)
        + RoundCleanup.runCallbacks(callbacks, onError)
        + RoundCleanup.destroyAll(objects, onError)
end

return RoundCleanup
