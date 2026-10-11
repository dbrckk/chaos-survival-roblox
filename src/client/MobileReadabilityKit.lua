-- Touch-device decor readability: bounded, deterministic tier transforms.
-- A watch handles delayed Arena/Decor replication without polling.
local Kit = {}

function Kit.profile(tier)
    if tier == "Low" then
        return 0.18, 0.62
    elseif tier == "Medium" then
        return 0.12, 0.72
    end
    return 0.08, 0.80
end

function Kit.isGameplayEdge(part)
    local name = part.Name
    return string.sub(name, 1, 4) == "Edge"
        or string.find(name, "PlatformGlow", 1, true) ~= nil
        or string.find(name, "SpawnGlow", 1, true) ~= nil
end

-- Store each light's unscaled brightness, so repeated tier changes never
-- compound the dimming. The owner keeps a weak-key cache for map churn.
function Kit.applyInstance(instance, tier, originalBrightness)
    local decorTransparency, lightScale = Kit.profile(tier)
    if instance:IsA("BasePart") and instance.Material == Enum.Material.Neon then
        if Kit.isGameplayEdge(instance) then
            instance.LocalTransparencyModifier = math.min(0.07, decorTransparency * 0.45)
        else
            instance.LocalTransparencyModifier = decorTransparency
        end
    elseif instance:IsA("PointLight")
        or instance:IsA("SpotLight")
        or instance:IsA("SurfaceLight")
    then
        local baseline = originalBrightness[instance]
        if baseline == nil then
            baseline = instance.Brightness
            originalBrightness[instance] = baseline
        end
        instance.Brightness = baseline * lightScale
    end
end

-- Emissions are always the currently available Decor or nil. Listener
-- teardown is explicit when a map/arena disappears or another one arrives.
function Kit.watch(generated, onDecor)
    assert(typeof(generated) == "Instance" and type(onDecor) == "function",
        "MobileReadabilityKit.watch requires a map and callback")
    local sourceConnections = {}
    local arenaConnections = {}
    local currentArena = nil
    local alive = true

    local function disconnect(connections)
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        table.clear(connections)
    end

    local function emit()
        if alive then
            onDecor(currentArena and currentArena:FindFirstChild("Decor") or nil)
        end
    end

    local function bindArena(arena)
        disconnect(arenaConnections)
        currentArena = arena
        if arena then
            table.insert(arenaConnections, arena.ChildAdded:Connect(function(child)
                if child.Name == "Decor" then
                    emit()
                end
            end))
            table.insert(arenaConnections, arena.ChildRemoved:Connect(function(child)
                if child.Name == "Decor" then
                    emit()
                end
            end))
        end
        emit()
    end

    table.insert(sourceConnections, generated.ChildAdded:Connect(function(child)
        if child.Name == "Arena" then
            bindArena(child)
        end
    end))
    table.insert(sourceConnections, generated.ChildRemoved:Connect(function(child)
        if child == currentArena then
            bindArena(generated:FindFirstChild("Arena"))
        end
    end))
    bindArena(generated:FindFirstChild("Arena"))

    return function()
        alive = false
        disconnect(sourceConnections)
        disconnect(arenaConnections)
        currentArena = nil
    end
end

return Kit
