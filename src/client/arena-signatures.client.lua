-- One identifiable kinetic hero sculpture per rotating arena.
-- All motion is time-sliced and pauses in the lobby / on reduced motion.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
-- Locally integrated visual time is independent of server clock and Roblox
-- uptime. New rounds, motion preferences and map swaps begin from a calm
-- authored pose instead of teleporting moving sculptures to an arbitrary phase.
local motionTime = 0
local builtBase = nil
local builtVariant = nil
local builtTier = nil

local function rebuild()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = MapVisualReadiness.part(generated, "Arena", "Base")
    if not base or not base:IsA("BasePart") then
        -- A streamed-out arena must release its local cosmetic instances.
        motionTime = 0
        folder:ClearAllChildren()
        bundle = nil
        builtBase, builtVariant, builtTier = nil, nil, nil
        return
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    -- Readiness, arena identity and graphics tier can replicate on separate
    -- scheduler turns. If the requested sculpture is already alive and
    -- matches all three inputs, keep it (including animation continuity).
    if bundle and bundle.folder.Parent == folder
        and builtBase == base
        and builtVariant == variant
        and builtTier == tier.Name then
        return
    end

    motionTime = 0
    folder:ClearAllChildren()
    bundle = nil
    builtBase, builtVariant, builtTier = nil, nil, nil
    bundle = SignatureKit.build(folder, base, variant, tier.Name)
    builtBase, builtVariant, builtTier = base, variant, tier.Name
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

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bind(child)
        scheduleRebuild()
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bind(nil)
        folder:ClearAllChildren()
        bundle = nil
        builtBase, builtVariant, builtTier = nil, nil, nil
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    scheduleRebuild()
end)

player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    motionTime = 0
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
    if wasActive ~= isActive then
        motionTime = 0
    end
    phase = nextPhase
    if bundle and not isActive then
        SignatureKit.update(bundle, 0, true)
    end
end)

bind(workspace:FindFirstChild("GeneratedMap"))
scheduleRebuild()

task.spawn(function()
    while true do
        local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
        local active = phase == "round" or phase == "ready"
        local reduced = player:GetAttribute("ReduceMotion") == true
        if active and not reduced and bundle and bundle.folder.Parent then
            -- A suspended mobile app can resume after a long scheduler gap.
            -- Clamp catch-up so animated equipment never jumps metres in
            -- one frame; the entire signature shares this single timebase.
            local dt = task.wait(tier.Name == "Low" and 0.22
                or (tier.Name == "Medium" and 0.13 or 0.09))
            if (phase == "round" or phase == "ready")
                and player:GetAttribute("ReduceMotion") ~= true
                and bundle and bundle.folder.Parent
            then
                motionTime += math.clamp(tonumber(dt) or 0, 0, 0.25)
                SignatureKit.update(bundle, motionTime, false)
            end
        else
            task.wait(0.60)
        end
    end
end)
