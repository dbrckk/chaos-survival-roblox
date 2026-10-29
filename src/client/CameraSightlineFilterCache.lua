--!strict
-- Cache the camera's arena-only raycast filter between 180ms sightline
-- samples. Rebuild only when map topology, the Arena.Base reference,
-- Platforms children or a skybridge's explicit role changes.
-- The cache NEVER changes game objects or collision; it owns connections.
local CameraSightlineFilterCache = {}
CameraSightlineFilterCache.__index = CameraSightlineFilterCache

local function disconnectAll(connections)
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    table.clear(connections)
end

function CameraSightlineFilterCache.new(buildParams)
    assert(type(buildParams) == "function",
        "CameraSightlineFilterCache.new expects a filter builder")
    return setmetatable({
        _build = buildParams,
        _arena = nil,
        _base = nil,
        _platforms = nil,
        _params = nil,
        _dirty = true,
        _arenaConnections = {},
        _platformConnections = {},
        _skybridgeConnections = {},
    }, CameraSightlineFilterCache)
end

function CameraSightlineFilterCache:_clearPlatformWatch()
    disconnectAll(self._platformConnections)
    for part, connection in pairs(self._skybridgeConnections) do
        connection:Disconnect()
        self._skybridgeConnections[part] = nil
    end
    self._platforms = nil
end

function CameraSightlineFilterCache:_bindPlatform(platforms)
    if self._platforms == platforms then return end
    self:_clearPlatformWatch()
    self._platforms = platforms
    self._dirty = true
    if not platforms then return end

    local function watch(part)
        if part:IsA("BasePart") and not self._skybridgeConnections[part] then
            self._skybridgeConnections[part] = part
                :GetAttributeChangedSignal("ChaosSkybridge")
                :Connect(function()
                    self._dirty = true
                end)
        end
    end

    for _, part in ipairs(platforms:GetChildren()) do
        watch(part)
    end
    table.insert(self._platformConnections, platforms.ChildAdded:Connect(function(part)
        watch(part)
        self._dirty = true
    end))
    table.insert(self._platformConnections, platforms.ChildRemoved:Connect(function(part)
        local connection = self._skybridgeConnections[part]
        if connection then
            connection:Disconnect()
            self._skybridgeConnections[part] = nil
        end
        self._dirty = true
    end))
end

function CameraSightlineFilterCache:clear()
    disconnectAll(self._arenaConnections)
    self:_clearPlatformWatch()
    self._arena = nil
    self._base = nil
    self._params = nil
    self._dirty = true
end

function CameraSightlineFilterCache:get(arena, base)
    if typeof(arena) ~= "Instance" then
        self:clear()
        return nil
    end
    if arena ~= self._arena then
        self:clear()
        self._arena = arena
        table.insert(self._arenaConnections, arena.ChildAdded:Connect(function()
            self._dirty = true
        end))
        table.insert(self._arenaConnections, arena.ChildRemoved:Connect(function()
            self._dirty = true
        end))
    end

    if self._base ~= base then
        self._base = base
        self._dirty = true
    end
    self:_bindPlatform(arena:FindFirstChild("Platforms"))
    if self._dirty then
        self._params = self._build(arena, base)
        self._dirty = false
    end
    return self._params
end

return CameraSightlineFilterCache
