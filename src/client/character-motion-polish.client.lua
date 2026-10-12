-- Human-only momentum ribbons; bot trails have their own owner.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Quality = require(ReplicatedStorage.Shared.VfxQuality)
local Rules = require(ReplicatedStorage.Shared.CharacterMotionTrailRules)
local Viewport = require(ReplicatedStorage.Shared.VisualViewportRules)
local Builder = require(script.Parent.CharacterMotionTrailBuilder)
local Registry = require(script.Parent.CharacterMotionTrailRegistry)
local localPlayer = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local tracked, stop, watch = Registry.start(Players)
local phase, finalRush = "waiting", false
local remoteCandidates, selectedRemote = {}, {}

event.OnClientEvent:Connect(function(state)
    local snapshot = type(state) == "table" and state or {}
    phase = tostring(snapshot.phase or "waiting")
    finalRush = phase == "round" and snapshot.finalRush == true
end)

task.spawn(function()
    while true do
        local tier = Quality.get(localPlayer:GetAttribute("VfxQualityTier"))
        task.wait(Rules.updateInterval(tier.Name, phase,
            localPlayer:GetAttribute("ReduceMotion") == true, finalRush))
        local reduceMotion = localPlayer:GetAttribute("ReduceMotion") == true
        local ribbonPhaseActive = phase == "round" and not finalRush
            and not reduceMotion and tier.Name ~= "Low"
        local camera = workspace.CurrentCamera
        local localRoot = localPlayer.Character
            and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        local viewer = camera and camera.CFrame.Position
            or (localRoot and localRoot.Position)

        -- First collect eligible rigs; only the nearest remote humans
        -- receive a translucent ribbon. Local feedback is never budgeted out.
        table.clear(remoteCandidates)
        for model, state in pairs(tracked) do
            if not model.Parent then
                stop(model)
                continue
            end
            local root, humanoid = state.root, state.humanoid
            if root.Parent ~= model or humanoid.Parent ~= model then
                -- Keep a model watcher while its native rig is streamed out.
                -- Rebind the next Root/Humanoid instead of forgetting it.
                watch(model)
                continue
            end
            local visible = false
            local distance = math.huge
            local owner = state.player
            if ribbonPhaseActive and humanoid.Health > 0
                and owner and owner.Parent == Players
                and Rules.humanEligible(owner:GetAttribute("RoundParticipant"),
                    owner:GetAttribute("RoundEliminated")) then
                local velocity = root.AssemblyLinearVelocity
                local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
                local ratio = math.clamp(speed / math.max(1, humanoid.WalkSpeed), 0, 1.35)
                state.momentumBand = Rules.momentumBand(ratio, state.momentumBand)
                distance = model == localPlayer.Character and 0
                    or (viewer and (root.Position - viewer).Magnitude or math.huge)
                local retained = state.trail ~= nil and state.trail.Parent ~= nil
                    and state.trail.Enabled == true
                visible = Rules.visible(phase, finalRush, state.airborne,
                    ratio, tier.Name, reduceMotion, distance, retained)
                -- Project only distance/sprint-eligible remote humans; local
                -- movement feedback is unaffected by camera direction.
                if visible and camera and model ~= localPlayer.Character then
                    local projected = camera:WorldToViewportPoint(root.Position)
                    local viewport = camera.ViewportSize
                    visible = Viewport.contains(projected.X, projected.Y,
                        projected.Z, viewport.X, viewport.Y, retained)
                end
            end
            state.eligible = visible
            if visible and model ~= localPlayer.Character then
                state.distance = distance
                remoteCandidates[#remoteCandidates + 1] = state
            end
        end
        Rules.selectRemote(remoteCandidates, tier.Name, selectedRemote)

        for model, state in pairs(tracked) do
            local visible = state.eligible
                and (model == localPlayer.Character or selectedRemote[state] == true)
            if visible then
                local color = model:GetAttribute("ChaosAccent")
                if typeof(color) ~= "Color3" then
                    color = Color3.fromRGB(90, 190, 255)
                end
                if not Builder.isIntact(state.trail, state.root) then
                    state.trail = Builder.ensure(state.root, color)
                    state.appliedTier = nil
                    state.appliedBand = nil
                    state.appliedAccent = color
                elseif state.appliedAccent ~= color then
                    -- Cosmetics can change during a round; recolor the same
                    -- ribbon only on accent changes, never on every frame.
                    Builder.setAccent(state.trail, color)
                    state.appliedAccent = color
                end
            end
            local trail = state.trail
            if trail and trail.Parent then
                local band = state.momentumBand or "Flow"
                if state.appliedTier ~= tier.Name or state.appliedBand ~= band then
                    -- Exactly one Trail; avoid per-tick NumberSequence churn.
                    if Builder.applyMomentumStyle(trail,
                        Rules.momentumStyle(tier.Name, band)) then
                        state.appliedTier = tier.Name
                        state.appliedBand = band
                    end
                end
                if trail.Enabled ~= visible then trail.Enabled = visible end
            end
        end
    end
end)
