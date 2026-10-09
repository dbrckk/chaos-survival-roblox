local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- The Open Cloud suite imports source modules against the last published
-- place, so pre-merge Shared modules may not be replicated there yet.
local fluxRulesInPlace = ReplicatedStorage:FindFirstChild("Shared")
    and ReplicatedStorage.Shared:FindFirstChild("FluxRelayRules")
local FluxRelayRules = if fluxRulesInPlace
    then require(fluxRulesInPlace)
    else require("../shared/FluxRelayRules")

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
    local states = ctx.FluxWeaveStates
    local previous = type(states) == "table" and states[character] or nil
    local weave, advanced = FluxRelayRules.advanceWeave(
        previous, trigger:GetAttribute("FluxRelayIndex"), now
    )
    if type(states) == "table" and weave then
        states[character] = weave
    end
    local tier = weave and weave.tier or 1
    if player then
        player:SetAttribute("RoundFluxWeaveCombo", tier)
        player:SetAttribute("RoundFluxWeaveNextParity",
            FluxRelayRules.nextParity(weave))
        player:SetAttribute("RoundFluxWeaveBest", math.max(
            tonumber(player:GetAttribute("RoundFluxWeaveBest")) or 0,
            tier
        ))
    else
        character:SetAttribute("FluxWeaveCombo", tier)
    end

    -- A repeated/previously mastered gate can still return the runner
    -- inward, but must not rebroadcast a rare MASTER visual award.
    trigger:SetAttribute("FluxWeaveTier", advanced and tier or 1)
    trigger:SetAttribute("FluxTriggeredAt", serverTime)
    if player and advanced and ctx.OnArenaMechanicUsed then
        local label = tier == 3 and "FLUX MASTER"
            or (tier == 2 and "FLUX WEAVE x2" or "FLUX RELAY")
        pcall(ctx.OnArenaMechanicUsed,
            player, "Crossroads", label, overdrive)
    end
    return true
end

function CrossroadsFluxRelay.start(ctx, mechanics, center)
    if not mechanics or not mechanics.Parent then return nil end
    local folder = Instance.new("Folder")
    folder.Name = "FluxRelays"
    folder.Parent = mechanics
    local ready = setmetatable({}, {__mode = "k"})
    ctx.FluxWeaveStates = setmetatable({}, {__mode = "k"})
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
