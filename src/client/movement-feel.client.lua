local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local RoundEventPresentation = require(ReplicatedStorage.Shared.RoundEventPresentation)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local hazardImpactEvent = remotes:WaitForChild("HazardImpactFeedback")
local mechanicFeedbackEvent = remotes:WaitForChild("ArenaMechanicFeedback")
local stateEvent = remotes:WaitForChild("RoundState")

local character = nil
local humanoid = nil
local root = nil
local characterConnections = {}

local landingKick = 0
local impactKick = 0
local mechanicKick = 0
local lean = 0
local bob = 0
local shakeClock = 0
local lastVerticalVelocity = 0
local wasAirborne = false
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
local lastFinalRush = false
local lastOverdrive = false

local function disconnectCharacter()
    for _, connection in ipairs(characterConnections) do
        connection:Disconnect()
    end
    table.clear(characterConnections)
end

local function qualityScale()
    local profile = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
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
    if not root or not root.Parent then
        return
    end

    local now = os.clock()
    if now - lastLandingBurstAt < 0.28 then
        return
    end
    lastLandingBurstAt = now

    local tierName = player:GetAttribute("VfxQualityTier")
    local profile = VfxQuality.get(tierName)
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
    disconnectCharacter()
    character = nextCharacter
    humanoid = character:WaitForChild("Humanoid", 5)
    root = character:WaitForChild("HumanoidRootPart", 5)

    landingKick = 0
    impactKick = 0
    mechanicKick = 0
    lean = 0
    bob = 0
    lastVerticalVelocity = 0
    wasAirborne = false
    lastHorizontalSpeed = 0
    accelerationKick = 0
    speedFovOffset = 0
    presentationKick = 0
    presentationKickTarget = 0

    if not humanoid or not root then
        return
    end

    table.insert(characterConnections, humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Freefall then
            wasAirborne = true
        elseif wasAirborne
            and (
                newState == Enum.HumanoidStateType.Landed
                or newState == Enum.HumanoidStateType.Running
                or newState == Enum.HumanoidStateType.RunningNoPhysics
            )
        then
            wasAirborne = false
            local fallSpeed = math.max(0, -lastVerticalVelocity)
            if fallSpeed > 22 then
                local strength = math.clamp((fallSpeed - 22) / 58, 0.08, 0.72)
                landingKick = math.max(landingKick, strength)
                emitLandingBurst(strength)
            end
        end
    end))
end

if player.Character then
    task.spawn(bindCharacter, player.Character)
end
player.CharacterAdded:Connect(bindCharacter)

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
    if not root or not root.Parent or typeof(payload) ~= "table" then
        return
    end

    local position = payload.position
    if typeof(position) ~= "Vector3" then
        return
    end

    local distance = (root.Position - position).Magnitude
    local radius = math.clamp(tonumber(payload.radius) or 8, 1, 40)
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
    local surge = false
    local lowGravity = false
    local phase = state and tostring(state.phase or "waiting") or "waiting"
    local finalRush = phase == "round" and state.finalRush == true
    local overdrive = phase == "round" and state.overdrive == true

    if state and phase == "round" then
        for _, id in ipairs(state.disasterIds or {}) do
            if id == "SpeedSurge" then
                surge = true
            elseif id == "LowGravity" then
                lowGravity = true
            end
        end
    end

    local kick = RoundEventPresentation.cameraKick(
        previousPhase,
        state,
        lastFinalRush,
        lastOverdrive
    )
    presentationKickTarget = math.max(presentationKickTarget, kick)

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
        if not camera or not root or not root.Parent or not humanoid or humanoid.Health <= 0 then
            return
        end

        lastVerticalVelocity = root.AssemblyLinearVelocity.Y

        local scale = qualityScale()
        if scale <= 0 then
            return
        end

        local velocity = root.AssemblyLinearVelocity
        local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
        local speed = horizontalVelocity.Magnitude
        local rawAcceleration = (speed - lastHorizontalSpeed) / math.max(dt, 1 / 240)
        lastHorizontalSpeed = speed
        local targetAccelerationKick = math.clamp(rawAcceleration / 420, -0.030, 0.030)
        local reducedMotion = player:GetAttribute("ReduceMotion") == true
        local speedExcess = math.max(0, speed - 16)
        local surgeFovBonus = speedSurgeActive and math.clamp(speedExcess * 0.16 + 0.8, 0, 2.2) or 0
        local targetFovOffset = reducedMotion and 0 or math.clamp(speedExcess * 0.12 + surgeFovBonus, 0, 4.2)
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
        local targetLean = math.clamp(-lateralSpeed / 950, -0.018, 0.018)
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
            and math.sin(shakeClock * 0.28) * 0.010
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

        local baseFov = tonumber(player:GetAttribute("BaseCameraFov")) or 70
        if not player:GetAttribute("BaseCameraFov") then
            player:SetAttribute("BaseCameraFov", camera.FieldOfView)
            baseFov = camera.FieldOfView
        end
        local targetFov = math.clamp(
            baseFov
                + speedFovOffset * scale
                + presentationKick * 2.4 * scale,
            60,
            90
        )
        camera.FieldOfView = exponential(camera.FieldOfView, targetFov, 6, dt)
    end
)
