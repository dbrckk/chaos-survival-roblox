-- SKYRAIL SLIPSTREAM / Tower Run
-- A mid-bridge movement impulse activated only by a genuinely running
-- in-round survivor. Physical decks remain authoritative and anchored.
local Players = game:GetService("Players")
local MovementSafety = if script then
    require(script.Parent.MovementSafety)
    else require("./MovementSafety")

local SkyrailSlipstream = {}
SkyrailSlipstream.Cooldown = 4.5
SkyrailSlipstream.MinRunSpeed = 9
SkyrailSlipstream.Boost = 12
SkyrailSlipstream.SpeedCap = 42

function SkyrailSlipstream.direction(bridge, velocity)
    if not bridge or not bridge:IsA("BasePart")
        or typeof(velocity) ~= "Vector3"
    then
        return nil
    end
    local alongX = bridge.Size.X > bridge.Size.Z
    local axis = alongX and bridge.CFrame.RightVector
        or bridge.CFrame.LookVector
    local planar = Vector3.new(axis.X, 0, axis.Z)
    if planar.Magnitude < 0.1 then return nil end
    planar = planar.Unit
    local speed = velocity:Dot(planar)
    if math.abs(speed) < SkyrailSlipstream.MinRunSpeed then
        return nil
    end
    return speed > 0 and planar or -planar
end

function SkyrailSlipstream.velocity(current, direction)
    if typeof(direction) ~= "Vector3"
        or direction.Magnitude < 0.99
    then
        return current
    end
    return MovementSafety.addImpulse(
        current, direction * SkyrailSlipstream.Boost,
        SkyrailSlipstream.SpeedCap, -52, 48
    )
end

local function subject(hit)
    local cursor = hit
    while cursor and cursor ~= workspace do
        if cursor:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(cursor)
            local bot = cursor:GetAttribute("AISurvivor") == true
                and cursor:GetAttribute("AISurvivorInRound") == true
            if player or bot then
                local hum = cursor:FindFirstChildOfClass("Humanoid")
                local root = cursor:FindFirstChild("HumanoidRootPart")
                if hum and root and root:IsA("BasePart") then
                    return cursor, hum, root, player, bot
                end
                return nil
            end
        end
        cursor = cursor.Parent
    end
    return nil
end

function SkyrailSlipstream.tryTrigger(ctx, sensor, bridge, hit, ready, now)
    if not ctx or not ctx.Active or not ctx.Active()
        or not sensor or not sensor.Parent
        or not bridge or not bridge.Parent
        or bridge:GetAttribute("ChaosSkybridge") ~= true
    then
        return false
    end
    local rig, hum, root, player, bot = subject(hit)
    if not rig or hum.Health <= 0 then return false end
    local eligible = bot == true or (player ~= nil
        and ctx.IsContestantActive
        and ctx.IsContestantActive(player) == true)
    if not eligible or (ready[rig] or 0) > now then
        return false
    end
    -- Accessories may touch the trigger several studs from the actual rig.
    local offset = sensor.CFrame:PointToObjectSpace(root.Position)
    if math.abs(offset.X) > sensor.Size.X * 0.5 + 1
        or math.abs(offset.Z) > sensor.Size.Z * 0.5 + 1
        or math.abs(offset.Y) > sensor.Size.Y * 0.5 + 1
        or math.abs(root.AssemblyLinearVelocity.Y) > 24
    then
        return false
    end
    local direction = SkyrailSlipstream.direction(
        bridge, root.AssemblyLinearVelocity
    )
    if not direction then return false end

    ready[rig] = now + SkyrailSlipstream.Cooldown
    root.AssemblyLinearVelocity = SkyrailSlipstream.velocity(
        root.AssemblyLinearVelocity, direction
    )
    local usedAt = workspace:GetServerTimeNow()
    sensor:SetAttribute("SkyrailUsedAt", usedAt)
    bridge:SetAttribute("SkyrailUsedAt", usedAt)
    if player and ctx.OnArenaMechanicUsed then
        pcall(ctx.OnArenaMechanicUsed,
            player, "Towers", "SKYRAIL SLIPSTREAM", false)
    end
    return true
end

function SkyrailSlipstream.start(ctx, mechanics, arena)
    local platforms = arena and arena:FindFirstChild("Platforms")
    if not ctx or not mechanics or not platforms then return nil end
    local folder = Instance.new("Folder")
    folder.Name = "SkyrailSlipstream"
    folder.Parent = mechanics
    local ready = setmetatable({}, {__mode = "k"})

    for _, bridge in ipairs(platforms:GetChildren()) do
        if bridge:IsA("BasePart")
            and bridge:GetAttribute("ChaosSkybridge") == true
        then
            local alongX = bridge.Size.X > bridge.Size.Z
            local trigger = Instance.new("Part")
            trigger.Name = "SkyrailSlipstreamTrigger" .. bridge.Name
            trigger.Size = alongX
                and Vector3.new(3, 4.4, bridge.Size.Z + 0.6)
                or Vector3.new(bridge.Size.X + 0.6, 4.4, 3)
            trigger.CFrame = bridge.CFrame * CFrame.new(
                0, bridge.Size.Y * 0.5 + 2.1, 0
            )
            trigger.Transparency = 1
            trigger.Anchored = false
            trigger.Massless = true
            trigger.CanCollide = false
            trigger.CanQuery = false
            trigger.CanTouch = true
            trigger.CastShadow = false
            trigger:SetAttribute("SkyrailBridge", bridge.Name)
            trigger.Parent = folder

            -- Attach to the *physical* span. Shrinking Arena can change
            -- midpoint, length and size without stranding its checkpoint.
            local weld = Instance.new("WeldConstraint")
            weld.Name = "SkyrailFollowBridge"
            weld.Part0 = bridge
            weld.Part1 = trigger
            weld.Parent = trigger

            trigger.Touched:Connect(function(hit)
                SkyrailSlipstream.tryTrigger(
                    ctx, trigger, bridge, hit, ready, os.clock()
                )
            end)
        end
    end
    return folder
end

return SkyrailSlipstream
