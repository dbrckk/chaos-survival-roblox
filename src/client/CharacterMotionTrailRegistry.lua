-- Tracks human rigs without polling or retaining stale humanoid events.
local Registry = {}
function Registry.start(players)
    local tracked = setmetatable({}, {__mode = "k"})
    local pending = setmetatable({}, {__mode = "k"})
    local nextOrder = 0

    local function stop(model)
        if pending[model] then
            pending[model]:Disconnect()
            pending[model] = nil
        end
        local entry = tracked[model]
        if not entry then return end
        tracked[model] = nil
        if entry.trail and entry.trail.Parent then entry.trail.Enabled = false end
        if entry.stateChanged then entry.stateChanged:Disconnect() end
        if entry.destroying then entry.destroying:Disconnect() end
    end

    local function watch(model)
        if not model or not model.Parent or tracked[model] then return end
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")
        if not humanoid or not root or not root:IsA("BasePart") then
            if not pending[model] then
                local connection
                connection = model.ChildAdded:Connect(function(child)
                    if child:IsA("Humanoid") or child.Name == "HumanoidRootPart" then
                        task.defer(watch, model)
                    end
                end)
                pending[model] = connection
                task.delay(8, function()
                    if pending[model] == connection then stop(model) end
                end)
            end
            return
        end
        if pending[model] then
            pending[model]:Disconnect()
            pending[model] = nil
        end
        nextOrder += 1
        local entry = {humanoid = humanoid, root = root, airborne = false, order = nextOrder}
        tracked[model] = entry
        entry.stateChanged = humanoid.StateChanged:Connect(function(_, nextState)
            if nextState == Enum.HumanoidStateType.Jumping
                or nextState == Enum.HumanoidStateType.Freefall then
                entry.airborne = true
            elseif nextState == Enum.HumanoidStateType.Landed
                or nextState == Enum.HumanoidStateType.Running
                or nextState == Enum.HumanoidStateType.RunningNoPhysics then
                entry.airborne = false
            end
        end)
        entry.destroying = model.Destroying:Connect(function() stop(model) end)
    end

    local function watchPlayer(player)
        player.CharacterAdded:Connect(watch)
        player.CharacterRemoving:Connect(stop)
        if player.Character then watch(player.Character) end
    end
    for _, player in ipairs(players:GetPlayers()) do watchPlayer(player) end
    players.PlayerAdded:Connect(watchPlayer)
    return tracked, stop, watch
end
return Registry
