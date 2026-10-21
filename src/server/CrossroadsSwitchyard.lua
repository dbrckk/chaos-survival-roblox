-- CROSSROADS / SWITCHYARD
-- Intentional lateral lane changes, not another inward Flux Relay.
-- Four noncolliding central junction pads; two opposing pads charge at
-- once. Routes and collisions stay open whether or not the skill is active.
local Players = game:GetService("Players")
local movementModule = script and script.Parent:FindFirstChild("MovementSafety")
local MovementSafety = if movementModule
    then require(movementModule) else require("./MovementSafety")

local CrossroadsSwitchyard = {}

CrossroadsSwitchyard.PairSeconds = 9
CrossroadsSwitchyard.Cooldown = 4
CrossroadsSwitchyard.Offset = 13
CrossroadsSwitchyard.SideImpulse = 20

local OFFSETS = {
    Vector3.new(1, 0, 0),
    Vector3.new(0, 0, 1),
    Vector3.new(-1, 0, 0),
    Vector3.new(0, 0, -1),
}

function CrossroadsSwitchyard.pair(roundNumber, cycle)
    local round = math.max(1, math.floor(tonumber(roundNumber) or 1))
    local step = math.max(0, math.floor(tonumber(cycle) or 0))
    return (round + step) % 2
end

function CrossroadsSwitchyard.activeLane(index, pair)
    local lane, selected = tonumber(index), tonumber(pair)
    return lane ~= nil and lane % 1 == 0 and lane >= 1 and lane <= 4
        and (selected == 0 or selected == 1)
        and lane % 2 == selected
end

-- A straight return from an outer Flux Relay should NOT accidentally
-- trigger a sideways launch. The runner must already be steering across
-- lanes with an unmistakable tangential velocity component.
function CrossroadsSwitchyard.tangentVelocity(velocity, outward)
    if typeof(velocity) ~= "Vector3"
        or typeof(outward) ~= "Vector3" then return nil end
    local radial = Vector3.new(outward.X, 0, outward.Z)
    if radial.Magnitude < 0.1 then return nil end
    local along = Vector3.new(-radial.Z, 0, radial.X).Unit
    local motion = Vector3.new(velocity.X, 0, velocity.Z)
    local sideways = motion:Dot(along)
    if motion.Magnitude < 9 or math.abs(sideways) < 6
        or math.abs(sideways) / motion.Magnitude < 0.38
    then return nil end
    return along * math.sign(sideways)
end

function CrossroadsSwitchyard.velocity(current, tangent)
    if typeof(tangent) ~= "Vector3" then return current end
    return MovementSafety.addImpulse(
        current, tangent * CrossroadsSwitchyard.SideImpulse, 48, -52, 58
    )
end

local function subjectFromHit(hit)
    local node = hit
    while node and node ~= workspace do
        if node:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(node)
            local bot = node:GetAttribute("AISurvivor") == true
                and node:GetAttribute("AISurvivorInRound") == true
            if player or bot then
                local humanoid = node:FindFirstChildOfClass("Humanoid")
                local root = node:FindFirstChild("HumanoidRootPart")
                if humanoid and root and root:IsA("BasePart") then
                    return node, player, bot, humanoid, root
                end
                return nil
            end
        end
        node = node.Parent
    end
    return nil
end

function CrossroadsSwitchyard.tryTrigger(ctx, pad, hit, ready, claimed, now)
    if not ctx or type(ctx.Active) ~= "function" or not ctx.Active()
        or not pad or not pad.Parent
        or pad:GetAttribute("JunctionActive") ~= true
    then return false end
    local character, player, bot, humanoid, root = subjectFromHit(hit)
    if not character or humanoid.Health <= 0 then return false end
    if not bot and (not player
        or type(ctx.IsContestantActive) ~= "function"
        or ctx.IsContestantActive(player) ~= true)
    then return false end

    -- Accessory hits must never launch characters from across the arena.
    local delta = root.Position - pad.Position
    if math.abs(delta.X) > 5 or math.abs(delta.Y) > 4.5
        or math.abs(delta.Z) > 5 then return false end

    local index = pad:GetAttribute("JunctionIndex")
    local offset = OFFSETS[index]
    if not offset then return false end
    local direction = CrossroadsSwitchyard.tangentVelocity(
        root.AssemblyLinearVelocity, offset
    )
    if not direction or (ready[character] or -math.huge) > now
        or (claimed[character] and claimed[character][index])
    then return false end
    -- The charge can change at the exact moment eligibility was checked.
    if not ctx.Active() or pad:GetAttribute("JunctionActive") ~= true
    then return false end

    ready[character] = now + CrossroadsSwitchyard.Cooldown
    if not claimed[character] then claimed[character] = {} end
    claimed[character][index] = true
    root.AssemblyLinearVelocity = CrossroadsSwitchyard.velocity(
        root.AssemblyLinearVelocity, direction
    )
    pad:SetAttribute("JunctionTriggeredAt", workspace:GetServerTimeNow())
    pad:SetAttribute("JunctionTravelSign", direction:Dot(
        Vector3.new(-offset.Z, 0, offset.X)
    ) >= 0 and 1 or -1)
    if player and ctx.OnArenaMechanicUsed then
        pcall(ctx.OnArenaMechanicUsed, player, "Crossroads", "JUNCTION CUT", false)
    end
    return true
end

local function signal(parent, name, pad, size, localOffset, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = pad.CFrame * CFrame.new(localOffset)
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = 0.68
    part.Parent = parent
    return part
end

function CrossroadsSwitchyard.start(ctx, mechanics, center)
    if not ctx or ctx.EnableJunctionSwitchyard ~= true
        or type(ctx.Active) ~= "function"
        or type(ctx.OnCleanup) ~= "table"
        or not mechanics or typeof(center) ~= "Vector3"
    then return nil end

    local folder = Instance.new("Folder")
    folder.Name = "JunctionSwitchyard"
    folder.Parent = mechanics
    local ready = setmetatable({}, {__mode = "k"})
    local claimed = setmetatable({}, {__mode = "k"})
    local pads = {}
    local signalSets = {}

    local idle = Color3.fromRGB(122, 104, 174)
    local charged = Color3.fromRGB(255, 203, 99)
    for index, outward in ipairs(OFFSETS) do
        local pad = Instance.new("Part")
        pad.Name = "JunctionSwitch" .. tostring(index)
        pad.Size = Vector3.new(6.2, 4.8, 6.2)
        pad.Position = center + outward * CrossroadsSwitchyard.Offset
            + Vector3.new(0, 3.15, 0)
        pad.Anchored = true
        pad.CanCollide = false
        pad.CanTouch = true
        pad.CanQuery = false
        pad.CastShadow = false
        pad.Transparency = 1
        pad:SetAttribute("JunctionIndex", index)
        pad.Parent = folder
        pads[index] = pad

        -- Two fixed transverse arrows, fitted entirely inside the marked
        -- six-stud control surface. Server-painted for Low-end Android.
        local alongX = math.abs(outward.X) > 0
        local thin = alongX and Vector3.new(0.32, 0.065, 2.3)
            or Vector3.new(2.3, 0.065, 0.32)
        signalSets[index] = {
            signal(folder, "JunctionChevron" .. index .. "A",
                pad, thin, Vector3.new(
                    alongX and -0.65 or 0, -2.04,
                    alongX and 0 or -0.65
                ), idle),
            signal(folder, "JunctionChevron" .. index .. "B",
                pad, thin, Vector3.new(
                    alongX and 0.65 or 0, -2.04,
                    alongX and 0 or 0.65
                ), idle),
        }
        pad.Touched:Connect(function(hit)
            CrossroadsSwitchyard.tryTrigger(
                ctx, pad, hit, ready, claimed, os.clock()
            )
        end)
    end

    local active = true
    local cycle = 0
    local function paint()
        local pair = CrossroadsSwitchyard.pair(ctx.RoundNumber, cycle)
        for index, pad in ipairs(pads) do
            local on = CrossroadsSwitchyard.activeLane(index, pair)
            pad:SetAttribute("JunctionActive", on)
            for _, piece in ipairs(signalSets[index]) do
                piece.Color = on and charged or idle
                piece.Transparency = on and 0.12 or 0.68
            end
        end
    end
    paint()
    ctx.OnCleanup[#ctx.OnCleanup + 1] = function()
        active = false
        for index, pad in ipairs(pads) do
            if pad.Parent then
                pad:SetAttribute("JunctionActive", nil)
            end
            for _, piece in ipairs(signalSets[index]) do
                if piece.Parent then
                    piece.Color = idle
                    piece.Transparency = 0.68
                end
            end
        end
    end

    task.spawn(function()
        while active and ctx.Active() and folder.Parent do
            task.wait(CrossroadsSwitchyard.PairSeconds)
            if not active or not ctx.Active() or not folder.Parent then
                break
            end
            cycle += 1
            paint()
        end
    end)

    return folder
end

return CrossroadsSwitchyard
