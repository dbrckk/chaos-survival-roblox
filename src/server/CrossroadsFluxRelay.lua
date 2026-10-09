local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FluxRelayRules = require(ReplicatedStorage.Shared.FluxRelayRules)

local CrossroadsFluxRelay = {}

-- The trigger is intentionally invisible. Clients construct the visual frame,
-- so every device can pick its own detail tier without replicating decoration.
local function buildTrigger(folder, center, index, epoch)
    local offset = FluxRelayRules.Offsets[index]
    local alongX = math.abs(offset.X) > 0
    local trigger = Instance.new("Part")
    trigger.Name = "FluxRelay" .. tostring(index)
    trigger.Size = alongX and Vector3.new(3, 6, 8) or Vector3.new(8, 6, 3)
    trigger.Position = center + offset + Vector3.new(0, 3.2, 0)
    trigger.Transparency = 1
    trigger.Anchored = true
    trigger.CanCollide = false
    trigger.CanTouch = true
    trigger.CanQuery = false
    trigger.CastShadow = false
    trigger:SetAttribute("FluxRelayIndex", index)
    trigger:SetAttribute("FluxCycleEpoch", epoch)
    trigger:SetAttribute("FluxPhaseOffset", FluxRelayRules.offsetFor(index))
    trigger.Parent = folder
    return trigger
end

local function subjectFromHit(hit)
    local node = hit
    while node and node ~= workspace do
        if node:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(node)
            local bot = node:GetAttribute("AISurvivor") == true
                and node:GetAttribute("AISurvivorInRound") == true
            if player or bot then
                local hum = node:FindFirstChildOfClass("Humanoid")
                local root = node:FindFirstChild("HumanoidRootPart")
                if hum and root and root:IsA("BasePart") then
                    return node, root, hum, player, bot
                end
                return nil
            end
        end
        node = node.Parent
    end
    return nil
end

function CrossroadsFluxRelay.tryTrigger(ctx, trigger, hit, ready, epoch, now, serverTime, center)
    if not trigger or not trigger.Parent or not ctx.Active() then return false end
    local character, root, humanoid, player, bot = subjectFromHit(hit)
    if not character then return false end
    -- Touched may originate from a giant accessory or a long attached part.
    -- Only accept a real survivor body close to this server-owned arch.
    local delta = root.Position - trigger.Position
    local horizontal = Vector3.new(delta.X, 0, delta.Z).Magnitude
    if horizontal > 9 or math.abs(delta.Y) > 6 then
        return false
    end

    local eligible = bot == true or (player ~= nil
        and ctx.IsContestantActive and ctx.IsContestantActive(player) == true)
    if not FluxRelayRules.canTrigger(
        true, eligible, humanoid.Health, serverTime, epoch,
        trigger:GetAttribute("FluxPhaseOffset"), now, ready[character]
    ) then
        return false
    end

    ready[character] = FluxRelayRules.nextAllowed(now)
    local overdrive = ctx.Overdrive and ctx.Overdrive() == true
    root.AssemblyLinearVelocity = FluxRelayRules.velocity(
        root.AssemblyLinearVelocity, trigger.Position, center, overdrive
    )
    trigger:SetAttribute("FluxTriggeredAt", serverTime)
    if player and ctx.OnArenaMechanicUsed then
        pcall(ctx.OnArenaMechanicUsed, player, "Crossroads", "FLUX RELAY", overdrive)
    end
    return true
end

function CrossroadsFluxRelay.start(ctx, mechanics, center)
    if not mechanics or not mechanics.Parent then return nil end
    local folder = Instance.new("Folder")
    folder.Name = "FluxRelays"
    folder.Parent = mechanics
    local ready = setmetatable({}, {__mode = "k"})
    local epoch = workspace:GetServerTimeNow()

    for index = 1, #FluxRelayRules.Offsets do
        local trigger = buildTrigger(folder, center, index, epoch)
        trigger.Touched:Connect(function(hit)
            CrossroadsFluxRelay.tryTrigger(
                ctx, trigger, hit, ready, epoch,
                os.clock(), workspace:GetServerTimeNow(), center
            )
        end)
    end
    return folder
end

return CrossroadsFluxRelay
