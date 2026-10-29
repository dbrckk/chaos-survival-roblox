-- One identifiable kinetic hero sculpture per rotating arena.
-- All motion is time-sliced and pauses in the lobby / on reduced motion.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SignatureKit = require(script.Parent.ArenaSignatureKit)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local folder = Instance.new("Folder")
folder.Name = "ArenaSignatureLocal"
folder.Parent = workspace

local phase = "waiting"
local bundle = nil
local disconnectMapWatch = nil
local watchedMap = nil
-- Locally integrated visual time is independent of server clock and Roblox
-- uptime. New rounds, motion preferences and map swaps begin from a calm
-- authored pose instead of teleporting moving sculptures to an arbitrary phase.
local motionTime = 0
local finalRush = false
local rushBlend = 0
local settling = false
local settleElapsed = 0
local SETTLE_SECONDS = 0.72

local function rebuild()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = MapVisualReadiness.part(generated, "Arena", "Base")
    if not base or not base:IsA("BasePart") then
        -- A streamed-out arena must release its local cosmetic instances.
        motionTime = 0
        rushBlend = 0
        settling = false
        settleElapsed = 0
        folder:ClearAllChildren()
        bundle = nil
        return
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local tier = VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled)
    -- Readiness, arena identity and graphics tier can replicate on separate
    -- scheduler turns. If the requested sculpture is already alive and
    -- matches all three inputs, keep it (including animation continuity).
    if SignatureKit.matches(bundle, base, variant, tier.Name, folder) then
        return
    end

    motionTime = 0
    rushBlend = 0
    settling = false
    settleElapsed = 0
    folder:ClearAllChildren()
    bundle = nil
    bundle = SignatureKit.build(folder, base, variant, tier.Name)
    SignatureKit.update(bundle, 0, true)
end

-- Map streaming, a fresh GeneratedMap and a graphics-tier update can
-- all signal the same frame. Build one set per deferred turn instead of
-- allocating and destroying the entire landmark multiple times.
local rebuildScheduled = false
local function scheduleRebuild()
    if rebuildScheduled then return end
    rebuildScheduled = true
    task.defer(function()
        rebuildScheduled = false
        rebuild()
    end)
end

local function bind(generated)
    if watchedMap == generated then return end
    watchedMap = generated
    if disconnectMapWatch then
        disconnectMapWatch()
        disconnectMapWatch = nil
    end
    if generated then
        disconnectMapWatch = MapVisualReadiness.watch(
            generated, "Arena", "Base",
            function()
                scheduleRebuild()
            end
        )
    end
end

-- Treat streaming transitions as a change of the *current* map only.
-- A late removal from an older instance must not dispose the new map's
-- watcher, and an already-present replacement must get its own rebuild.
workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap"
        and workspace:FindFirstChild("GeneratedMap") == child then
        bind(child)
        scheduleRebuild()
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child == watchedMap then
        bind(workspace:FindFirstChild("GeneratedMap"))
        settling = false
        folder:ClearAllChildren()
        bundle = nil
        scheduleRebuild()
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    scheduleRebuild()
end)

player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    motionTime = 0
    rushBlend = 0
    settling = false
    settleElapsed = 0
    if bundle then
        SignatureKit.update(bundle, 0, true)
    end
end)

state.OnClientEvent:Connect(function(snapshot)
    -- Malformed or late event data must not kill the cinematic controller.
    local nextPhase = type(snapshot) == "table"
        and tostring(snapshot.phase or "waiting") or "waiting"
    local wasActive = phase == "round" or phase == "ready"
    local isActive = nextPhase == "round" or nextPhase == "ready"
    if isActive then
        if not wasActive then
            motionTime = 0
            rushBlend = 0
        end
        settling = false
    elseif nextPhase == "result" and wasActive and bundle
        and player:GetAttribute("ReduceMotion") ~= true then
        -- Hold the actual final animation pose and decelerate gracefully.
        -- Repeated result snapshots do not restart this envelope.
        settling = true
        settleElapsed = 0
    elseif nextPhase ~= "result" then
        settling = false
        settleElapsed = 0
        motionTime = 0
        rushBlend = 0
    end
    phase = nextPhase
    finalRush = nextPhase == "round" and type(snapshot) == "table"
        and snapshot.finalRush == true
    if bundle and not isActive and not settling then
        SignatureKit.update(bundle, 0, true)
    end
end)

bind(workspace:FindFirstChild("GeneratedMap"))
scheduleRebuild()

task.spawn(function()
    while true do
        local tier = VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled)
        local active = phase == "round" or phase == "ready"
        local reduced = player:GetAttribute("ReduceMotion") == true
        if (active or settling) and not reduced
            and bundle and bundle.folder.Parent then
            -- A suspended mobile app can resume after a long scheduler gap.
            -- Clamp catch-up so animated equipment never jumps metres in
            -- one frame; the entire signature shares this single timebase.
            local dt = task.wait(tier.Name == "Low" and 0.22
                or (tier.Name == "Medium" and 0.13 or 0.09))
            if player:GetAttribute("ReduceMotion") ~= true
                and bundle and bundle.folder.Parent then
                local step = math.clamp(tonumber(dt) or 0, 0, 0.25)
                if phase == "round" or phase == "ready" then
                    local targetRush = phase == "round" and finalRush and 1 or 0
                    -- Ease in/out: no sudden angular jump at Final Rush.
                    rushBlend += (targetRush - rushBlend) * math.min(1, step * 2.4)
                    motionTime += step * SignatureKit.motionRate(rushBlend)
                    SignatureKit.update(bundle, motionTime, false, rushBlend)
                elseif settling and phase == "result" then
                    settleElapsed += step
                    local blend = SignatureKit.settleAmount(
                        settleElapsed, SETTLE_SECONDS
                    )
                    SignatureKit.update(bundle, motionTime, false, rushBlend, blend)
                    if blend <= 0 then
                        settling = false
                        motionTime = 0
                        rushBlend = 0
                        SignatureKit.update(bundle, 0, true)
                    end
                end
            end
        else
            task.wait(0.60)
        end
    end
end)
