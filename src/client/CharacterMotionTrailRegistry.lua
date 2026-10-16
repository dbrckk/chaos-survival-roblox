-- Event-driven human momentum trail registration. A model remains
-- watchable through delayed Humanoid/Root streaming without any expiry timer.
local Registry = {}

function Registry.create(players, releaseTrail)
    local tracked = setmetatable({}, {__mode = "k"})
    local watches = setmetatable({}, {__mode = "k"})
    local nextOrder = 0

    local function retire(entry)
        if entry.stateChanged then
            entry.stateChanged:Disconnect()
            entry.stateChanged = nil
        end
        if entry.trail and entry.trail.Parent then
            -- Streaming a root, replacing a Humanoid or removing a player
            -- must release our allocated GPU Trail, not merely hide it.
            -- Fail soft for callers that do not provide a cleanup owner.
            local released = type(releaseTrail) == "function"
                and releaseTrail(entry.root, entry.trail)
            if not released and entry.trail.Parent then
                entry.trail.Enabled = false
            end
        end
        entry.trail = nil
        entry.appliedTier = nil
        entry.appliedAccent = nil
        entry.appliedBand = nil
        entry.momentumBand = nil
        entry.airborne = false
    end

    local function stop(model)
        local entry = watches[model]
        if not entry then return end
        watches[model] = nil
        tracked[model] = nil
        retire(entry)
        for _, connection in ipairs(entry.connections) do
            connection:Disconnect()
        end
        table.clear(entry.connections)
        entry.root = nil
        entry.humanoid = nil
    end

    local function refresh(model, entry)
        if watches[model] ~= entry then return end
        if not model:IsDescendantOf(workspace) then
            -- CharacterAdded may precede workspace parenting. Retain a
            -- lightweight watcher only until its first live attachment;
            -- once streamed out, detach all listeners.
            if entry.everInWorkspace then stop(model) end
            return
        end
        entry.everInWorkspace = true
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")
        if not root or not root:IsA("BasePart") then root = nil end
        if entry.humanoid == humanoid and entry.root == root then return end
        retire(entry)
        tracked[model] = nil
        entry.humanoid, entry.root = humanoid, root
        if not humanoid or not root then return end
        nextOrder += 1
        entry.order = nextOrder
        tracked[model] = entry
        entry.stateChanged = humanoid.StateChanged:Connect(function(_, state)
            if tracked[model] ~= entry
                or entry.root ~= root or entry.humanoid ~= humanoid
                or root.Parent ~= model or humanoid.Parent ~= model then
                return
            end
            if state == Enum.HumanoidStateType.Jumping
                or state == Enum.HumanoidStateType.Freefall then
                entry.airborne = true
            elseif state == Enum.HumanoidStateType.Landed
                or state == Enum.HumanoidStateType.Running
                or state == Enum.HumanoidStateType.RunningNoPhysics then
                entry.airborne = false
            end
        end)
    end

    local function watch(model, owner)
        if not model or not model:IsA("Model") then return end
        if model.Parent ~= nil and not model:IsDescendantOf(workspace) then
            return
        end
        local entry = watches[model]
        if entry then
            if owner then entry.player = owner end
            refresh(model, entry)
            return
        end
        entry = {
            root = nil, humanoid = nil, airborne = false, order = 0,
            everInWorkspace = model:IsDescendantOf(workspace),
            player = owner or players:GetPlayerFromCharacter(model),
            stateChanged = nil, connections = {},
        }
        watches[model] = entry
        table.insert(entry.connections, model.ChildAdded:Connect(function(child)
            if child:IsA("Humanoid") or child.Name == "HumanoidRootPart" then
                refresh(model, entry)
            end
        end))
        table.insert(entry.connections, model.ChildRemoved:Connect(function(child)
            if child == entry.root or child == entry.humanoid then
                refresh(model, entry)
            end
        end))
        table.insert(entry.connections, model.AncestryChanged:Connect(function()
            refresh(model, entry)
        end))
        table.insert(entry.connections, model.Destroying:Connect(function()
            stop(model)
        end))
        refresh(model, entry)
    end

    local function watchedCount()
        local total = 0
        for _ in pairs(watches) do total += 1 end
        return total
    end
    return tracked, stop, watch, watchedCount
end

function Registry.start(players, releaseTrail)
    local tracked, stop, watch = Registry.create(players, releaseTrail)
    local connectionsByPlayer = {}

    local function watchPlayer(player)
        if connectionsByPlayer[player] then return end
        local connections = {}
        connectionsByPlayer[player] = connections
        connections[#connections + 1] = player.CharacterAdded:Connect(function(model)
            watch(model, player)
        end)
        connections[#connections + 1] = player.CharacterRemoving:Connect(stop)
        if player.Character then watch(player.Character, player) end
    end
    for _, player in ipairs(players:GetPlayers()) do watchPlayer(player) end
    players.PlayerAdded:Connect(watchPlayer)
    players.PlayerRemoving:Connect(function(player)
        if player.Character then stop(player.Character) end
        local connections = connectionsByPlayer[player]
        if connections then
            for _, connection in ipairs(connections) do
                connection:Disconnect()
            end
            connectionsByPlayer[player] = nil
        end
    end)
    return tracked, stop, watch
end

return Registry
