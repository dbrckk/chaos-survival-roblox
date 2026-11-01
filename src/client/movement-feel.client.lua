local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local RoundEventPresentation = require(ReplicatedStorage.Shared.RoundEventPresentation)
local SpectatorTargetRules = require(ReplicatedStorage.Shared.SpectatorTargetRules)
local CameraFeelBus = require(script.Parent.CameraFeelBus)
local LocomotionDynamics = require(ReplicatedStorage.Shared.LocomotionDynamics)
local CharacterReactionRules = require(ReplicatedStorage.Shared.CharacterReactionRules)
local JumpLandingPreviewKit = require(script.Parent.JumpLandingPreviewKit)

local player = Players.LocalPlayer
local landingPreview = JumpLandingPreviewKit.new(player)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local hazardImpactEvent = remotes:WaitForChild("HazardImpactFeedback")
local mechanicFeedbackEvent = remotes:WaitForChild("ArenaMechanicFeedback")
local stateEvent = remotes:WaitForChild("RoundState")

local character = nil
local humanoid = nil
local root = nil
local characterConnections = {}
local humanoidStateConnection = nil
local bindVersion = 0

local landingKick = 0
local impactKick = 0
local mechanicKick = 0
local lean = 0
local bob = 0
local shakeClock = 0
local wasAirborne = false
local airborneStartedAt = -math.huge
local lastAirSampleAt = -math.huge
local peakFallSpeed = 0
local lastLandingBurstAt = 0
local lastHorizontalSpeed = 0
local accelerationKick = 0
local speedFovOffset = 0
local speedSurgeActive = false
local lowGravityActive = false
local tornadoModel = nil
local presentationKick = 0
local presentationKickTarget = 0
local previousPhase = "waiting"
local lastRoundNumber = nil
local lastFinalRush = false
local lastOverdrive = false

-- Clear client-only camera springs whenever Roblox hands camera ownership
-- to a spectator/cinematic or resumes from a suspended Android frame.
-- Rebase speed on the real root so a return cannot invent acceleration.
local function suspendCameraMotion()
    lean, bob = 0, 0
    landingKick, impactKick, mechanicKick = 0, 0, 0
    presentationKick, presentationKickTarget = 0, 0
    accelerationKick, speedFovOffset = 0, 0
    wasAirborne = false
    airborneStartedAt, lastAirSampleAt = -math.huge, -math.huge
    peakFallSpeed = 0
    if root and root.Parent == character then
        local velocity = root.AssemblyLinearVelocity
        lastHorizontalSpeed = Vector3.new(
            velocity.X, 0, velocity.Z
        ).Magnitude
    else
        lastHorizontalSpeed = 0
    end
    CameraFeelBus.reset()
    landingPreview.hide()
end

local function disconnectCharacter()
    bindVersion += 1
    landingPreview.hide()
    if humanoidStateConnection then
        humanoidStateConnection:Disconnect()
        humanoidStateConnection = nil
    end
    for _, connection in ipairs(characterConnections) do
        connection:Disconnect()
    end
    table.clear(characterConnections)
end

local function qualityScale()
    local profile = VfxQuality.deviceTier(
        player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled)
    local scale = profile.Name == "Low" and 0.48 or (profile.Name == "Medium" and 0.76 or 1)
    if UserInputService.TouchEnabled then
        scale *= 0.78
    end
    if player:GetAttribute("ReduceMotion") == true then
        scale *= 0.18
    end
    return scale
end

local function emitLandingBurst(strength)
    if previousPhase ~= "round"
        or player:GetAttribute("RoundParticipant") ~= true
        or player:GetAttribute("RoundEliminated") == true
        or not root or root.Parent ~= character then
        return
    end

    local now = os.clock()
    if now - lastLandingBurstAt < 0.28 then
        return
    end
    lastLandingBurstAt = now

    local profile = VfxQuality.deviceTier(
        player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled)
    local tierName = profile.Name
    if profile.Name == "Low" and strength < 0.34 then
        return
    end

    local attachment = Instance.new("Attachment")
    attachment.Name = "LandingBurstLocal"
    attachment.Position = Vector3.new(0, -2.35, 0)
    attachment.Parent = root

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "LandingDust"
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(0.16, 0.28)
    emitter.Speed = NumberRange.new(2.4, 5.6)
    emitter.SpreadAngle = Vector2.new(145, 12)
    emitter.Acceleration = Vector3.new(0, 1.2, 0)
    emitter.LightInfluence = 0.35
    emitter.Color = ColorSequence.new(
        Color3.fromRGB(130, 155, 190),
        Color3.fromRGB(205, 220, 240)
    )
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18 + strength * 0.18),
        NumberSequenceKeypoint.new(0.55, 0.12),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.28),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment
    local reducedMotion = player:GetAttribute("ReduceMotion") == true
    local fullCount = math.floor(10 + strength * 10)
    emitter:Emit(VfxQuality.particleCount(tierName, reducedMotion and math.max(4, math.floor(fullCount * 0.45)) or fullCount, 4))

    task.delay(0.4, function()
        if attachment.Parent then
            attachment:Destroy()
        end
    end)
end

local function bindCharacter(nextCharacter)
    -- Initial task.spawn and CharacterAdded may arrive out of order.
    if player.Character ~= nextCharacter then return end
    disconnectCharacter()
    local version = bindVersion
    character = nextCharacter
    humanoid = nil
    root = nil

    landingKick = 0
    impactKick = 0
    mechanicKick = 0
    lean = 0
    bob = 0
    wasAirborne = false
    airborneStartedAt = -math.huge
    lastAirSampleAt = -math.huge
    peakFallSpeed = 0
    lastHorizontalSpeed = 0
    accelerationKick = 0
    speedFovOffset = 0
    lastLandingBurstAt = -math.huge
    presentationKick = 0
    presentationKickTarget = 0
    CameraFeelBus.reset()

    -- On slower Android connections a root may replicate well after the
    -- CharacterAdded signal. Avoid yielding for five seconds or permanently
    -- losing that avatar; one ChildAdded listener repairs incomplete rigs.
    local function attachIfReady()
        if bindVersion ~= version or player.Character ~= nextCharacter
            or character ~= nextCharacter then
            return
        end
        local nextHumanoid = nextCharacter:FindFirstChildOfClass("Humanoid")
        local nextRoot = nextCharacter:FindFirstChild("HumanoidRootPart")
        if not nextHumanoid or not nextRoot or not nextRoot:IsA("BasePart")
            or nextHumanoid.Parent ~= nextCharacter
            or nextRoot.Parent ~= nextCharacter then
            return
        end
        if humanoid == nextHumanoid and root == nextRoot then return end

        -- A replaced root/Humanoid is a new camera-body owner. Previous
        -- fall, impact and FOV impulses must never land on the new rig.
        suspendCameraMotion()
        if humanoidStateConnection then
            humanoidStateConnection:Disconnect()
            humanoidStateConnection = nil
        end
        humanoid = nextHumanoid
        root = nextRoot
        -- A newly replicated rig might already be sprinting; its first
        -- velocity sample is a baseline, not an acceleration impulse.
        local initialVelocity = nextRoot.AssemblyLinearVelocity
        lastHorizontalSpeed = Vector3.new(
            initialVelocity.X, 0, initialVelocity.Z
        ).Magnitude
        accelerationKick = 0
        wasAirborne = nextHumanoid:GetState() == Enum.HumanoidStateType.Freefall
        airborneStartedAt = wasAirborne and os.clock() or -math.huge
        lastAirSampleAt = airborneStartedAt
        peakFallSpeed = wasAirborne
            and math.max(0, -nextRoot.AssemblyLinearVelocity.Y) or 0
        -- A streamed/replaced Root cannot leave duplicated state listeners.
        -- The sole bound Humanoid/Root identity is rechecked on each event.
        humanoidStateConnection = nextHumanoid.StateChanged:Connect(function(_, newState)
            if bindVersion ~= version or character ~= nextCharacter
                or player.Character ~= nextCharacter
                or humanoid ~= nextHumanoid or root ~= nextRoot then
                return
            end
            if newState == Enum.HumanoidStateType.Jumping then
                wasAirborne = false
                airborneStartedAt = -math.huge
                lastAirSampleAt = -math.huge
                peakFallSpeed = 0
            elseif newState == Enum.HumanoidStateType.Freefall then
                if not wasAirborne then
                    wasAirborne = true
                    airborneStartedAt = os.clock()
                    peakFallSpeed = 0
                end
                peakFallSpeed = math.max(
                    peakFallSpeed, math.max(0, -nextRoot.AssemblyLinearVelocity.Y)
                )
                lastAirSampleAt = os.clock()
            elseif wasAirborne
                and (
                    newState == Enum.HumanoidStateType.Landed
                    or newState == Enum.HumanoidStateType.Running
                    or newState == Enum.HumanoidStateType.RunningNoPhysics
                )
            then
                local now = os.clock()
                local fallSpeed = LocomotionDynamics.verifiedLandingSpeed(
                    peakFallSpeed, now - airborneStartedAt, now - lastAirSampleAt
                )
                wasAirborne = false
                peakFallSpeed = 0
                airborneStartedAt = -math.huge
                lastAirSampleAt = -math.huge
                if fallSpeed > 22 then
                    local strength = math.clamp((fallSpeed - 22) / 58, 0.08, 0.72)
                    landingKick = math.max(landingKick, strength)
                    emitLandingBurst(strength)
                end
            end
        end)
    end

    table.insert(characterConnections, nextCharacter.ChildAdded:Connect(function(child)
        if child:IsA("Humanoid") or child.Name == "HumanoidRootPart" then
            task.defer(attachIfReady)
        end
    end))
    -- Android replication may insert the replacement FIRST and remove
    -- the previous Humanoid or root a frame later. ChildAdded alone then
    -- finds the old rig, and its final removal used to leave motion feel
    -- disconnected for the rest of this life. Re-evaluate on both sides
    -- of the swap; the version guard rejects a previous CharacterAdded.
    table.insert(characterConnections, nextCharacter.ChildRemoved:Connect(function(child)
        if bindVersion ~= version or character ~= nextCharacter
            or player.Character ~= nextCharacter then
            return
        end
        if child == humanoid or child == root then
            if humanoidStateConnection then
                humanoidStateConnection:Disconnect()
                humanoidStateConnection = nil
            end
            humanoid = nil
            root = nil
            suspendCameraMotion()
        end
        if child:IsA("Humanoid") or child.Name == "HumanoidRootPart" then
            task.defer(attachIfReady)
        end
    end))
    attachIfReady()
end
if player.Character then
    task.spawn(bindCharacter, player.Character)
end
player.CharacterAdded:Connect(bindCharacter)
player.CharacterRemoving:Connect(function(removingCharacter)
    if character ~= removingCharacter then return end
    disconnectCharacter()
    character = nil
    humanoid = nil
    root = nil
    wasAirborne = false
    airborneStartedAt = -math.huge
    lastAirSampleAt = -math.huge
    peakFallSpeed = 0
    landingKick = 0
    accelerationKick = 0
    speedFovOffset = 0
    CameraFeelBus.reset()
end)

local function bindTornado(model)
    if model and model.Name == "RoundTornado" then
        tornadoModel = model
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "RoundTornado" then
        bindTornado(child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child == tornadoModel then
        tornadoModel = nil
    end
end)

bindTornado(workspace:FindFirstChild("RoundTornado"))

hazardImpactEvent.OnClientEvent:Connect(function(payload)
    if previousPhase ~= "round"
        or player:GetAttribute("RoundParticipant") ~= true
        or player:GetAttribute("RoundEliminated") == true
        or not root or root.Parent ~= character or type(payload) ~= "table" then
        return
    end

    local position = payload.position
    if not CharacterReactionRules.validPosition(position) then
        return
    end
    local requestedRadius = tonumber(payload.radius)
    if requestedRadius and (requestedRadius ~= requestedRadius
        or math.abs(requestedRadius) == math.huge
        or requestedRadius <= 0) then
        return
    end

    local distance = (root.Position - position).Magnitude
    local radius = math.clamp(requestedRadius or 8, 1, 40)
    local reach = math.max(24, radius * 5.5)
    if distance > reach then
        return
    end

    local proximity = 1 - math.clamp(distance / reach, 0, 1)
    local kind = tostring(payload.kind or "")
    local kindScale = kind == "Meteor" and 1.0 or (kind == "Bomb" and 0.88 or 0.62)
    impactKick = math.max(impactKick, proximity * kindScale * 0.72)
end)

mechanicFeedbackEvent.OnClientEvent:Connect(function(payload)
    local boost = type(payload) == "table" and payload.overdrive == true
    mechanicKick = math.max(mechanicKick, boost and 0.55 or 0.34)
end)

stateEvent.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    local candidate = tonumber(state.roundNumber)
    local roundNumber = candidate and candidate == candidate
        and candidate >= 1 and candidate < math.huge
        and candidate == math.floor(candidate) and candidate or nil
    if roundNumber and lastRoundNumber and roundNumber < lastRoundNumber then
        -- Old snapshots cannot re-arm a previous round's camera impulses.
        return
    end
    local newRound = roundNumber ~= nil and lastRoundNumber ~= nil
        and roundNumber ~= lastRoundNumber
    if roundNumber then lastRoundNumber = roundNumber end
    local phase = tostring(state.phase or "waiting")
    local finalRush = phase == "round" and state.finalRush == true
    local overdrive = phase == "round" and state.overdrive == true
    local surge, lowGravity = false, false
    if phase == "round" then
        for _, id in ipairs(type(state.disasterIds) == "table"
            and state.disasterIds or {}) do
            if id == "SpeedSurge" then
                surge = true
            elseif id == "LowGravity" then
                lowGravity = true
            end
        end
    end
    if phase ~= previousPhase or newRound then
        suspendCameraMotion()
    end
    local previousRush = lastFinalRush
    local previousOverdrive = lastOverdrive
    if newRound then
        previousRush, previousOverdrive = false, false
    end
    local kick = RoundEventPresentation.cameraKick(
        newRound and "ready" or previousPhase, state,
        previousRush, previousOverdrive
    )
    if player:GetAttribute("RoundEliminated") ~= true
        and (phase ~= "round"
            or player:GetAttribute("RoundParticipant") == true) then
        presentationKickTarget = math.max(presentationKickTarget, kick)
    end
    speedSurgeActive = surge
    lowGravityActive = lowGravity
    previousPhase = phase
    lastFinalRush = finalRush
    lastOverdrive = overdrive
end)

local function exponential(current, target, speed, dt)
    local alpha = 1 - math.exp(-math.max(0, speed) * math.max(0, dt))
    return current + (target - current) * alpha
end

RunService:BindToRenderStep(
    "ChaosMovementFeel",
    Enum.RenderPriority.Camera.Value + 2,
    function(dt)
        local camera = workspace.CurrentCamera
        if SpectatorTargetRules.isSpectating(
            previousPhase == "round",
            player:GetAttribute("RoundParticipant"),
            player:GetAttribute("RoundEliminated")
        ) then
            -- CameraSubject belongs to spectator mode, not the player's
            -- distant lobby avatar; never add local footstep shake to it.
            suspendCameraMotion()
            return
        end
        if not camera or camera.ViewportSize.X <= 0
            or camera.ViewportSize.Y <= 0
            or player.Character ~= character
            or not root or root.Parent ~= character
            or not humanoid or humanoid.Parent ~= character
            or humanoid.Health <= 0 then
            suspendCameraMotion()
            return
        end

        -- Roblox's camera can temporarily belong to a scripted reveal,
        -- another survivor or an external camera owner during respawn.
        -- Never apply footstep rotation/FOV from our local character to a
        -- camera that is NOT actually following that character. Android
        -- thumb-aiming and spectator transitions must remain in control.
        local subject = camera.CameraSubject
        if camera.CameraType == Enum.CameraType.Scriptable
            or not subject
            or (subject ~= humanoid and not subject:IsDescendantOf(character)) then
            suspendCameraMotion()
            return
        end

        -- One existing render owner performs a bounded 10Hz collision
        -- sample while descending. All other frames only check state.
        landingPreview.update(previousPhase, root, humanoid)
        local nowSample = os.clock()
        local verticalSpeed = root.AssemblyLinearVelocity.Y
        local inFreefall = humanoid:GetState() == Enum.HumanoidStateType.Freefall
            and humanoid.FloorMaterial == Enum.Material.Air
        if type(dt) ~= "number" or dt ~= dt or dt <= 0
            or dt == math.huge or dt > 0.30 then
            -- Do not replay a pre-suspension impact or landing after
            -- Android resumes, even if the avatar has stayed alive.
            suspendCameraMotion()
            -- One quiet, bounded restart frame: never feed a 2-second
            -- Android background delta into the camera spring or sine.
            dt = 1 / 60
        end
        if inFreefall then
            if not wasAirborne then
                wasAirborne = true
                airborneStartedAt = nowSample
                peakFallSpeed = 0
            end
            peakFallSpeed = math.max(peakFallSpeed, math.max(0, -verticalSpeed))
            lastAirSampleAt = nowSample
        end

        local scale = qualityScale()
        local precisionFactor = LocomotionDynamics.precisionCameraFactor(
            UserInputService.TouchEnabled, previousPhase,
            humanoid.FloorMaterial ~= Enum.Material.Air, verticalSpeed
        )
        if scale <= 0 then
            suspendCameraMotion()
            return
        end

        local velocity = root.AssemblyLinearVelocity
        local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
        local speed = horizontalVelocity.Magnitude
        local rawAcceleration = (speed - lastHorizontalSpeed) / math.max(dt, 1 / 240)
        lastHorizontalSpeed = speed
        local targetAccelerationKick = math.clamp(
            rawAcceleration / 420, -0.030, 0.030
        ) * precisionFactor
        local reducedMotion = player:GetAttribute("ReduceMotion") == true
        local speedExcess = math.max(0, speed - 16)
        local surgeFovBonus = speedSurgeActive and math.clamp(speedExcess * 0.16 + 0.8, 0, 2.2) or 0
        local targetFovOffset = reducedMotion and 0
            or math.clamp(speedExcess * 0.12 + surgeFovBonus, 0, 4.2)
                * precisionFactor
        speedFovOffset = exponential(
            speedFovOffset,
            targetFovOffset,
            targetFovOffset > speedFovOffset and 5.5 or 3.2,
            dt
        )

        accelerationKick = exponential(
            accelerationKick,
            targetAccelerationKick,
            math.abs(targetAccelerationKick) > math.abs(accelerationKick) and 10 or 6,
            dt
        )

        local lateralSpeed = camera.CFrame.RightVector:Dot(horizontalVelocity)
        local targetLean = math.clamp(
            -lateralSpeed / 950, -0.018, 0.018
        ) * precisionFactor
        lean = exponential(lean, targetLean, 8.5, dt)

        local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
        local moving = humanoid.MoveDirection.Magnitude > 0.08 and speed > 3
        local targetBob = grounded and moving and math.min(1, speed / 18) or 0
        bob = exponential(bob, targetBob, moving and 7 or 11, dt)

        landingKick *= math.exp(-dt * 10.5)
        impactKick *= math.exp(-dt * 8.0)
        mechanicKick *= math.exp(-dt * 7.5)
        presentationKickTarget *= math.exp(-dt * 7.0)
        presentationKick = exponential(
            presentationKick,
            presentationKickTarget,
            presentationKickTarget > presentationKick and 14 or 8,
            dt
        )
        shakeClock += dt * (18 + impactKick * 10)

        local surgeWave = speedSurgeActive and math.sin(shakeClock * 0.92) * 0.006 * math.clamp(speed / 24, 0, 1) or 0
        local lowGravityDrift = lowGravityActive and not grounded
            and math.sin(shakeClock * 0.28) * 0.010 * precisionFactor
            or 0
        local tornadoRoll = 0
        local tornadoLift = 0
        if tornadoModel and tornadoModel.Parent then
            local middle = tornadoModel:FindFirstChild("MiddleFunnel")
            if middle and middle:IsA("BasePart") then
                local delta = Vector3.new(root.Position.X - middle.Position.X, 0, root.Position.Z - middle.Position.Z)
                local distance = delta.Magnitude
                if distance > 1 and distance < 48 then
                    local proximity = 1 - math.clamp((distance - 4) / 44, 0, 1)
                    local tangent = Vector3.new(-delta.Z, 0, delta.X).Unit
                    local cameraSide = camera.CFrame.RightVector:Dot(tangent)
                    tornadoRoll = cameraSide * proximity * 0.016
                    tornadoLift = math.sin(shakeClock * 0.41) * proximity * 0.010
                end
            end
        end

        local walkWave = math.sin(shakeClock * 0.62) * 0.010 * bob + surgeWave
        local walkLift = math.abs(math.cos(shakeClock * 0.62)) * 0.015 * bob + lowGravityDrift + tornadoLift

        local pitch =
            (landingKick * 0.026)
            - (mechanicKick * 0.018)
            - (presentationKick * 0.010)
            - accelerationKick
            - (speedSurgeActive and math.clamp(speedExcess / 520, 0, 0.010) or 0)
            + (math.sin(shakeClock * 1.91) * impactKick * 0.018)
        local roll =
            lean
            + tornadoRoll
            + (math.cos(shakeClock * 2.37) * impactKick * 0.014)
            + walkWave
        local y =
            (-landingKick * 0.055)
            + (mechanicKick * 0.025)
            + walkLift
            + (math.sin(shakeClock * 2.11) * impactKick * 0.035)

        pitch *= scale
        roll *= scale
        y *= scale

        camera.CFrame = camera.CFrame
            * CFrame.new(0, y, 0)
            * CFrame.Angles(pitch, 0, roll)

        CameraFeelBus.setMovementFovOffset(
            speedFovOffset * scale
                + presentationKick * 2.4 * scale
        )
    end
)
