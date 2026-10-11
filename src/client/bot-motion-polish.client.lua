-- AI movement polish only. Uses server-owned bot positions and animations.
-- Cosmetic floor traces are rate-limited and disabled on Low/ReduceMotion.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local BotRules = require(ReplicatedStorage.Shared.BotMotionPresentationRules)
local ViewportRules = require(ReplicatedStorage.Shared.VisualViewportRules)
local GroundFx = require(script.Parent.LocomotionGroundFx)

local player = Players.LocalPlayer
local phaseEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local phase = "waiting"
local folder = nil
local folderAddedConnection = nil
local folderRemovedConnection = nil
local bots = setmetatable({}, {__mode = "k"})
local pending = setmetatable({}, {__mode = "k"})
local lastGlobalCueAt = -math.huge
local lastSampleAt = os.clock()

local function tier()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function disposeBot(model)
    local waiting = pending[model]
    if waiting then
        waiting:Disconnect()
        pending[model] = nil
    end
    local state = bots[model]
    if state then
        local trail = state.root and state.root:FindFirstChild("AISurvivorCosmeticTrail")
        if trail and trail:IsA("Trail") then
            trail.Enabled = false
            if state.defaultTrailColor then
                trail.Color = state.defaultTrailColor
            end
        end
        bots[model] = nil
    end
end

local function watch(model)
    if not folder or not model or model.Parent ~= folder
        or not model:IsA("Model") or bots[model] then
        return
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or not root:IsA("BasePart") then
        -- A delayed/streamed bot is subscribed once, instead of scheduling
        -- unbounded 0.12-second polling tasks for incomplete rigs.
        if not pending[model] then
            pending[model] = model.ChildAdded:Connect(function(child)
                if child:IsA("Humanoid") or child.Name == "HumanoidRootPart" then
                    task.defer(watch, model)
                end
            end)
        end
        return
    end
    if pending[model] then
        pending[model]:Disconnect()
        pending[model] = nil
    end

    local index = 1
    for i, child in ipairs(folder:GetChildren()) do
        if child == model then index = i; break end
    end
    bots[model] = {
        humanoid = humanoid,
        root = root,
        index = index,
        lastSpeed = 0,
        lastVelocity = root.AssemblyLinearVelocity,
        lastCueAt = -math.huge,
        cueKind = nil,
        cueUntil = 0,
        trail = nil,
        defaultTrailColor = nil,
        appliedTrailKind = nil,
        appliedTrailLifetime = nil,
    }
end

local function bind(nextFolder)
    if folderAddedConnection then
        folderAddedConnection:Disconnect()
        folderAddedConnection = nil
    end
    if folderRemovedConnection then
        folderRemovedConnection:Disconnect()
        folderRemovedConnection = nil
    end
    for model in pairs(bots) do
        disposeBot(model)
    end
    for model in pairs(pending) do
        disposeBot(model)
    end
    folder = nextFolder

    if not folder then return end
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then watch(child) end
    end
    folderAddedConnection = folder.ChildAdded:Connect(function(child)
        if child:IsA("Model") then task.defer(watch, child) end
    end)
    folderRemovedConnection = folder.ChildRemoved:Connect(disposeBot)
end

bind(workspace:FindFirstChild("AISurvivors"))
workspace.ChildAdded:Connect(function(child)
    if child.Name == "AISurvivors" and child ~= folder then
        bind(child)
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child == folder then
        bind(nil)
    end
end)

phaseEvent.OnClientEvent:Connect(function(state)
    phase = tostring(state and state.phase or "waiting")
    if phase ~= "round" then
        for _, entry in pairs(bots) do
            local trail = entry.root and entry.root:FindFirstChild("AISurvivorCosmeticTrail")
            if trail and trail:IsA("Trail") then
                trail.Enabled = false
            end
        end
    end
end)

task.spawn(function()
    while true do
        local q = tier()
        task.wait(q.DecorUpdateInterval or math.max(1 / 30, q.UpdateInterval))
        local now = os.clock()
        local dt = math.clamp(now - lastSampleAt, 1 / 120, 0.25)
        lastSampleAt = now
        local reduceMotion = player:GetAttribute("ReduceMotion") == true
        local botProfile = BotRules.profile(q.Name, reduceMotion)
        local viewerRoot = player.Character
            and player.Character:FindFirstChild("HumanoidRootPart")
        local camera = workspace.CurrentCamera
        -- Camera position remains authoritative for spectators following
        -- bots; the avatar can be far away from the active view.
        local viewerPosition = camera and camera.CFrame.Position
            or (viewerRoot and viewerRoot.Position)
        local emissions = 0

        for model, state in pairs(bots) do
            if not folder or model.Parent ~= folder then
                disposeBot(model)
                continue
            end
            if not state.root.Parent or not state.humanoid.Parent then
                disposeBot(model)
                watch(model)
                continue
            end
            if state.humanoid.Health <= 0 then
                local trail = state.root:FindFirstChild("AISurvivorCosmeticTrail")
                if trail and trail:IsA("Trail") then trail.Enabled = false end
                continue
            end

            local velocity = state.root.AssemblyLinearVelocity
            local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
            local previousVelocity = state.lastVelocity
            state.lastVelocity = velocity
            state.lastSpeed += (speed - state.lastSpeed) * 0.22

            local distance = viewerPosition
                and (state.root.Position - viewerPosition).Magnitude or math.huge
            local trail = state.root:FindFirstChild("AISurvivorCosmeticTrail")
            local onScreen = true
            -- Only project nearby rigs that could show optional VFX; never
            -- spend camera work on Low/ReduceMotion or distant bots.
            if camera and phase == "round" and not reduceMotion
                and q.Name ~= "Low" and distance <= 110 then
                local p = camera:WorldToViewportPoint(state.root.Position)
                local view = camera.ViewportSize
                onScreen = ViewportRules.contains(p.X, p.Y, p.Z,
                    view.X, view.Y, trail ~= nil and trail:IsA("Trail")
                        and trail.Enabled == true)
            end
            if trail and trail:IsA("Trail") then
                if state.trail ~= trail then
                    state.trail = trail
                    state.defaultTrailColor = trail.Color
                    state.appliedTrailKind = nil
                    state.appliedTrailLifetime = nil
                end
                local accentKind = phase == "round" and not reduceMotion
                    and q.Name ~= "Low" and now < state.cueUntil
                    and state.cueKind or nil
                if state.appliedTrailKind ~= accentKind then
                    local accent = BotRules.trailAccent(accentKind)
                    trail.Color = accent and ColorSequence.new(accent)
                        or state.defaultTrailColor
                    state.appliedTrailKind = accentKind
                end
                local ratio = math.clamp(
                    state.lastSpeed / math.max(1, state.humanoid.WalkSpeed),
                    0, 1.25
                )
                local visible = onScreen and BotRules.trailVisible(
                    q.Name, reduceMotion, phase,
                    state.humanoid.FloorMaterial ~= Enum.Material.Air,
                    ratio, distance, trail.Enabled
                )
                if trail.Enabled ~= visible then trail.Enabled = visible end
                local lifetime = (0.09 + (state.index % 3) * 0.024)
                    * (q.Name == "High" and 1 or 0.72)
                if state.appliedTrailLifetime ~= lifetime then
                    if trail.Lifetime ~= lifetime then trail.Lifetime = lifetime end
                    state.appliedTrailLifetime = lifetime
                end
            end

            if emissions < botProfile.MaxPerScan
                and now - lastGlobalCueAt >= 0.55
                and now - state.lastCueAt >= botProfile.Cooldown
                and viewerPosition ~= nil and onScreen
            then
                local cue, strength = BotRules.cue(
                    velocity, previousVelocity, dt,
                    state.humanoid.FloorMaterial ~= Enum.Material.Air,
                    q.Name, reduceMotion, phase, distance
                )
                if cue then
                    local effect = GroundFx.emit(state.root, cue, strength, q.Name)
                    if effect then
                        lastGlobalCueAt = now
                        state.lastCueAt = now
                        state.cueKind = cue
                        state.cueUntil = now + 0.32
                        emissions += 1
                    end
                end
            end
        end
    end
end)
