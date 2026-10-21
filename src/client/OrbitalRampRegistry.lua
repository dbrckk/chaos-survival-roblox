-- Event-driven ownership of the eight scored Helix ramps and sixteen
-- physical entry/reactor links. Decorative runners may update rapidly,
-- but streamed geometry is enumerated only after a structural change.
-- All listeners are disconnected on arena replacement.
local OrbitalRampRegistry = {}
OrbitalRampRegistry.__index = OrbitalRampRegistry

local function isRampCandidate(part)
    return part:IsA("BasePart") and (
        part.Name:match("^HelixRamp%d+$") ~= nil
        or part.Name:match("^EntryRamp%d+$") ~= nil
        or part.Name:match("^CoreRamp%d+$") ~= nil
    )
end

function OrbitalRampRegistry.collect(circuit, signKit)
    local scored, access = {}, {}
    if not circuit then return scored, access end

    for _, part in ipairs(circuit:GetChildren()) do
        if isRampCandidate(part) then
            if part:GetAttribute("OrbitalHelixRamp") == true then
                scored[#scored + 1] = part
            elseif signKit.kind(part) ~= nil then
                access[#access + 1] = part
            end
        end
    end

    table.sort(scored, function(a, b)
        local first = tonumber(a:GetAttribute("HelixLane")) or 0
        local second = tonumber(b:GetAttribute("HelixLane")) or 0
        if first ~= second then return first < second end
        return a.Name < b.Name
    end)
    table.sort(access, function(a, b) return a.Name < b.Name end)
    return scored, access
end

function OrbitalRampRegistry.new(signKit)
    local self = setmetatable({
        signKit = signKit,
        circuit = nil,
        dirty = true,
        ramps = {},
        access = {},
        scanCount = 0,
        connections = {},
        partConnections = {},
    }, OrbitalRampRegistry)
    return self
end

function OrbitalRampRegistry:_unwatch(part)
    local tracked = self.partConnections[part]
    if tracked then
        for _, connection in ipairs(tracked) do connection:Disconnect() end
        self.partConnections[part] = nil
    end
end

function OrbitalRampRegistry:_watch(part)
    if not isRampCandidate(part) or self.partConnections[part] then
        return
    end

    local tracked = {}
    self.partConnections[part] = tracked
    -- Attributes can arrive *after* ChildAdded during StreamingEnabled.
    -- HelixLane also controls stable animation order.
    for _, attribute in ipairs({
        "OrbitalHelixRamp", "OrbitalAccessRamp", "OrbitalCoreRamp",
        "HelixLane",
    }) do
        tracked[#tracked + 1] =
            part:GetAttributeChangedSignal(attribute):Connect(function()
                self.dirty = true
            end)
    end
end

function OrbitalRampRegistry:bind(circuit)
    if circuit == self.circuit then return false end

    for _, connection in ipairs(self.connections) do connection:Disconnect() end
    table.clear(self.connections)
    for part in pairs(self.partConnections) do self:_unwatch(part) end

    self.circuit = circuit
    self.dirty = true
    if circuit then
        self.connections[#self.connections + 1] = circuit.ChildAdded:Connect(function(part)
            self:_watch(part)
            if isRampCandidate(part) then self.dirty = true end
        end)
        self.connections[#self.connections + 1] = circuit.ChildRemoved:Connect(function(part)
            self:_unwatch(part)
            if isRampCandidate(part) then self.dirty = true end
        end)
        for _, part in ipairs(circuit:GetChildren()) do
            self:_watch(part)
        end
    end
    return true
end

function OrbitalRampRegistry:snapshot(circuit)
    local replaced = self:bind(circuit)
    if not self.dirty then
        return self.ramps, self.access, false, replaced
    end
    self.ramps, self.access = OrbitalRampRegistry.collect(circuit, self.signKit)
    self.dirty = false
    self.scanCount += 1
    return self.ramps, self.access, true, replaced
end

function OrbitalRampRegistry:destroy()
    self:bind(nil)
    self.ramps, self.access = {}, {}
    self.dirty = true
end

return OrbitalRampRegistry
