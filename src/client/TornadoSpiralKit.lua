-- Client-only, non-colliding glass ribbons outside the server's cyclone core.
-- Reuses the disaster-motion-vfx clock; never starts a second render loop.
local TornadoSpiralKit = {}

function TornadoSpiralKit.clear(state)
    if type(state) ~= "table" then return end
    for _, part in ipairs(state.parts or {}) do
        if part then part:Destroy() end
    end
    state.parts = {}
    state.source = nil
    state.lastOrigin = nil
    state.tier = nil
    state.reduced = nil
end

function TornadoSpiralKit.sync(state, source, parent, tier, reduced, elapsed, rules)
    if type(state) ~= "table" then return end
    local valid = typeof(source) == "Instance" and source:IsA("BasePart")
        and source:IsDescendantOf(workspace)
        and typeof(parent) == "Instance" and parent.Parent ~= nil
        and type(rules) == "table"
    local count = valid and rules.count(tier, reduced) or 0
    if count == 0 then
        TornadoSpiralKit.clear(state)
        return
    end

    if state.source ~= source or #state.parts ~= count then
        TornadoSpiralKit.clear(state)
        state.source = source
        state.parts = {}
        for index = 1, count do
            local part = Instance.new("Part")
            part.Name = "LocalTornadoSpiral" .. index
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part.Material = Enum.Material.Glass
            part.Parent = parent
            state.parts[index] = part
        end
    end

    -- The replicated LowerFunnel is offset +3 studs from the storm's
    -- authoritative center. This decoration does not touch its hit range.
    local origin = source.Position - Vector3.new(0, 3, 0)
    local still = reduced == true or tier == "Low"
    if still and state.lastOrigin == origin
        and state.tier == tier and state.reduced == reduced then
        return
    end
    state.tier, state.reduced, state.lastOrigin = tier, reduced, origin

    for index, part in ipairs(state.parts) do
        local recipe = rules.segment(origin, index, count, elapsed, still)
        if recipe then
            part.CFrame = recipe.CFrame
            part.Size = recipe.Size
            part.Color = recipe.Color
            part.Transparency = recipe.Transparency
        end
    end
end

return TornadoSpiralKit
