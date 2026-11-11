-- Optional creator-approved hero art is never a dependency of the playable map.
-- Give the current arena's signature one bounded first-round opportunity.
-- A second arena selected during the wait may also become eligible immediately.
-- Inactive variants retain their fallback deadline; an optional shared-source
-- alias can prioritize a second real consumer. All actual imports
-- still pass through PremiumApprovedAssetImportGate (two in flight maximum).
local Schedule = {}

local function currentArena()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    if generated and generated.Parent == workspace
        and arena and arena:IsA("Folder") and arena.Parent == generated
    then
        return generated, arena
    end
    return nil, nil
end

function Schedule.waitFor(variant, earlySeconds, fallbackSeconds, alsoVariant)
    assert(type(variant) == "string" and variant ~= "")
    assert(alsoVariant == nil or (type(alsoVariant) == "string"
        and alsoVariant ~= "" and alsoVariant ~= variant))
    assert(type(earlySeconds) == "number" and earlySeconds > 0)
    assert(type(fallbackSeconds) == "number"
        and fallbackSeconds >= earlySeconds)

    -- One original approved source can serve two real variants.
    -- No extra worker, request or dependency on the playable map.
    local function isTarget(arena)
        if not arena then return false end
        local id = arena:GetAttribute("VariantId")
        return id == variant or (alsoVariant ~= nil and id == alsoVariant)
    end

    -- This runs inside each owner's existing task.spawn, after MapBuilder.
    -- Do not delay first join, round logic, bots, or native fallback art.
    task.wait(earlySeconds)
    local _, initial = currentArena()
    if initial and isTarget(initial) then
        return true
    end
    local remaining = fallbackSeconds - earlySeconds
    if remaining <= 0 then return false end

    -- A map may rotate from Classic to another arena while an optional
    -- source is sleeping. Listen to the actual Arena attribute instead of
    -- waiting until the old 62-104s fallback and missing the next round.
    -- Exactly one event/timer per pending source, never a polling loop.
    local wake = Instance.new("BindableEvent")
    local settled = false
    local active = false
    local mapConnections = {}
    local workspaceConnections = {}
    local arenaConnection = nil
    local watchedMap = nil

    local function finish(wasActive)
        if settled then return end
        settled = true
        active = wasActive
        wake:Fire()
    end

    local function checkActive()
        local _, arena = currentArena()
        if arena and isTarget(arena) then
            finish(true)
        end
    end

    local function watchArena(arena)
        if arenaConnection then
            arenaConnection:Disconnect()
            arenaConnection = nil
        end
        if arena and arena:IsA("Folder") then
            arenaConnection = arena:GetAttributeChangedSignal("VariantId")
                :Connect(checkActive)
        end
        checkActive()
    end

    local function watchMap(map)
        for _, connection in ipairs(mapConnections) do
            connection:Disconnect()
        end
        table.clear(mapConnections)
        watchedMap = map
        if map then
            mapConnections[#mapConnections + 1] =
                map.ChildAdded:Connect(function(child)
                    if child.Name == "Arena" then watchArena(child) end
                end)
            mapConnections[#mapConnections + 1] =
                map.ChildRemoved:Connect(function(child)
                    if child.Name == "Arena" then
                        watchArena(map:FindFirstChild("Arena"))
                    end
                end)
            watchArena(map:FindFirstChild("Arena"))
        else
            watchArena(nil)
        end
    end

    workspaceConnections[#workspaceConnections + 1] =
        workspace.ChildAdded:Connect(function(child)
            if child.Name == "GeneratedMap" then watchMap(child) end
        end)
    workspaceConnections[#workspaceConnections + 1] =
        workspace.ChildRemoved:Connect(function(child)
            if child == watchedMap then
                watchMap(workspace:FindFirstChild("GeneratedMap"))
            end
        end)
    watchMap(workspace:FindFirstChild("GeneratedMap"))

    -- Unlike a periodic task.wait loop, this fixed deadline cannot grow
    -- when a new map arrives or another source is stuck in AssetService.
    task.delay(remaining, function()
        finish(false)
    end)
    if not settled then wake.Event:Wait() end

    if arenaConnection then arenaConnection:Disconnect() end
    for _, connection in ipairs(mapConnections) do
        connection:Disconnect()
    end
    for _, connection in ipairs(workspaceConnections) do
        connection:Disconnect()
    end
    wake:Destroy()
    return active
end

return Schedule
