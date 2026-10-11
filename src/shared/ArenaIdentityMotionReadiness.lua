-- Watches streamed Arena/Decor identity parts and late VariantId.
-- One owner per GeneratedMap; disconnect explicitly on replacement.
-- The caller injects the identity-name predicate. The shared observer stays
-- loadable both in the running Roblox DataModel and in file-based Lest.
local Readiness = {}

function Readiness.watch(generated, onChange, isIdentityPart)
    assert(typeof(generated) == "Instance"
        and type(onChange) == "function"
        and type(isIdentityPart) == "function",
        "ArenaIdentityMotionReadiness.watch requires map, callback and identity filter")
    local mapConnections = {}
    local arenaConnections = {}
    local decorConnections = {}
    local currentArena = nil
    local currentDecor = nil
    local alive = true

    local function disconnect(connections)
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        table.clear(connections)
    end

    local function variant()
        return currentArena and tostring(currentArena:GetAttribute("VariantId") or "Classic")
            or nil
    end

    local function emit()
        if alive then
            onChange(currentArena, currentDecor, variant())
        end
    end

    local function bindDecor(decor)
        disconnect(decorConnections)
        currentDecor = decor
        if decor then
            local function identityChanged(child)
                if child:IsA("BasePart") and isIdentityPart(variant(), child.Name) then
                    emit()
                end
            end
            table.insert(decorConnections, decor.ChildAdded:Connect(identityChanged))
            table.insert(decorConnections, decor.ChildRemoved:Connect(identityChanged))
        end
        emit()
    end

    local function bindArena(arena)
        disconnect(arenaConnections)
        currentArena = arena
        if arena then
            table.insert(arenaConnections, arena.ChildAdded:Connect(function(child)
                if child.Name == "Decor" then
                    bindDecor(child)
                end
            end))
            table.insert(arenaConnections, arena.ChildRemoved:Connect(function(child)
                if child == currentDecor then
                    bindDecor(arena:FindFirstChild("Decor"))
                end
            end))
            table.insert(arenaConnections,
                arena:GetAttributeChangedSignal("VariantId"):Connect(emit))
        end
        bindDecor(arena and arena:FindFirstChild("Decor") or nil)
    end

    table.insert(mapConnections, generated.ChildAdded:Connect(function(child)
        if child.Name == "Arena" then
            bindArena(child)
        end
    end))
    table.insert(mapConnections, generated.ChildRemoved:Connect(function(child)
        if child == currentArena then
            bindArena(generated:FindFirstChild("Arena"))
        end
    end))
    bindArena(generated:FindFirstChild("Arena"))

    return function()
        alive = false
        disconnect(mapConnections)
        disconnect(arenaConnections)
        disconnect(decorConnections)
        currentArena = nil
        currentDecor = nil
    end
end

return Readiness
