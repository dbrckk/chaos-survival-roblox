local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- In Lest cloud tests the published place may not contain our branch-only
-- Shared module. Resolve source fallback without changing live behavior.
local shared = ReplicatedStorage:FindFirstChild("Shared")
local rulesModule = shared and shared:FindFirstChild("GridCircuitRules")
local GridCircuitRules = if rulesModule
    then require(rulesModule)
    else require("../shared/GridCircuitRules")

local GridCircuitService = {}

local function validCharacter(hit)
    local cursor = hit
    while cursor and cursor ~= workspace do
        if cursor:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(cursor)
            if player then
                local hum = cursor:FindFirstChildOfClass("Humanoid")
                local root = cursor:FindFirstChild("HumanoidRootPart")
                if hum and root and root:IsA("BasePart") then
                    return player, root, hum
                end
                return nil
            end
        end
        cursor = cursor.Parent
    end
    return nil
end

local function makeSensor(parent, center, index)
    local sensor = Instance.new("Part")
    sensor.Name = "GridCircuitNode" .. tostring(index)
    sensor.Size = Vector3.new(7.2, 5, 7.2)
    sensor.Position = center + GridCircuitRules.Offsets[index]
        + Vector3.new(0, 3.3, 0)
    sensor.Anchored = true
    sensor.Transparency = 1
    sensor.CanCollide = false
    sensor.CanTouch = true
    sensor.CanQuery = false
    sensor.CastShadow = false
    sensor:SetAttribute("GridCircuitIndex", index)
    sensor.Parent = parent
    return sensor
end

function GridCircuitService.tryTouch(ctx, sensor, hit, states, readyAt, now, serverTime)
    if not ctx or type(ctx.Active) ~= "function" or not ctx.Active()
        or not sensor or not sensor.Parent
    then
        return false
    end

    local player, root, hum = validCharacter(hit)
    if not player then return false end
    local dist = root.Position - sensor.Position
    local horizontal = Vector3.new(dist.X, 0, dist.Z).Magnitude
    local active = type(ctx.IsContestantActive) == "function"
        and ctx.IsContestantActive(player) == true
    if not GridCircuitRules.eligible(
        true, active, hum.Health, horizontal, dist.Y, now, readyAt[player]
    ) then
        return false
    end

    local index = sensor:GetAttribute("GridCircuitIndex")
    local previous = states[player]
    local nextState, advanced = GridCircuitRules.advance(
        previous, index, serverTime
    )
    if not advanced then return false end

    states[player] = nextState
    readyAt[player] = now + GridCircuitRules.TouchCooldown

    player:SetAttribute("RoundGridCircuitStep", nextState.step)
    player:SetAttribute("RoundGridCircuitNext", nextState.nextNode)
    player:SetAttribute("RoundGridCircuitDeadline", nextState.expiresAt)
    player:SetAttribute("RoundGridCircuitComplete", nextState.completed)

    sensor:SetAttribute("GridCircuitPulseAt", serverTime)
    sensor:SetAttribute("GridCircuitPulseStep", nextState.step)
    if nextState.completed and ctx.OnArenaMechanicUsed then
        pcall(ctx.OnArenaMechanicUsed, player, "Classic", "GRID CIRCUIT CLEAR", false)
    end
    return true
end

function GridCircuitService.start(ctx, mechanics, arenaCenter)
    if not ctx or not mechanics or not mechanics.Parent
        or typeof(arenaCenter) ~= "Vector3"
    then
        return nil
    end

    local folder = Instance.new("Folder")
    folder.Name = "GridCircuit"
    folder.Parent = mechanics

    local state = setmetatable({}, {__mode = "k"})
    local ready = setmetatable({}, {__mode = "k"})
    for _, player in ipairs(ctx.Contestants or {}) do
        if typeof(player) == "Instance" and player:IsA("Player") then
            player:SetAttribute("RoundGridCircuitStep", 0)
            player:SetAttribute("RoundGridCircuitNext", 0)
            player:SetAttribute("RoundGridCircuitDeadline", 0)
            player:SetAttribute("RoundGridCircuitComplete", false)
        end
    end

    for index = 1, GridCircuitRules.Count do
        local sensor = makeSensor(folder, arenaCenter, index)
        sensor.Touched:Connect(function(hit)
            GridCircuitService.tryTouch(ctx, sensor, hit, state, ready,
                os.clock(), workspace:GetServerTimeNow())
        end)
    end
    return folder
end

return GridCircuitService
