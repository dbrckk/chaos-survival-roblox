local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BodyMotionRules = require(ReplicatedStorage.Shared.BodyMotionRules)
local LocomotionDynamics = require(ReplicatedStorage.Shared.LocomotionDynamics)
local GroundFx = require(script.Parent.LocomotionGroundFx)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local feedbackEvent = remotes:WaitForChild("RoundFeedback")
local mechanicFeedbackEvent = remotes:WaitForChild("ArenaMechanicFeedback")
local hazardImpactEvent = remotes:WaitForChild("HazardImpactFeedback")
local stateEvent = remotes:WaitForChild("RoundState")

local character = nil
local humanoid = nil
local root = nil
local waist = nil
local rootJoint = nil
local leftHip = nil
local rightHip = nil
local leftShoulder = nil
local rightShoulder = nil
local landing = 0
local celebrationKind = nil
local celebrationWeight = 0
local celebrationUntil = 0
local airborne = false
local lastY = 0
local speedSurgeActive = false
local lowGravityActive = false
local roundPhase = "waiting"
local readyPose = 0
local launchWeight = 0
local impactWeight = 0
local impactSide = 0
local impactForward = 0
local jumpWeight = 0
local fallWeight = 0
local strideClock = 0
local lastSpeed = 0
local lastMoveDirection = Vector3.zero
local brakePose = 0
local turnPose = 0
local turnSeverityPose = 0
local startPose = 0
local skidPose = 0
local cutPose = 0
local footPlantPose = 0
local ascentReachPose = 0
local descentBracePose = 0
local lastGroundCueAt = -math.huge
local baseC0 = setmetatable({}, {__mode = "k"})
local bindSerial = 0
local humanoidStateConnection = nil

local function motor(parent, name)
    local item = parent and parent:FindFirstChild(name)
    return item and item:IsA("Motor6D") and item or nil
end

local function resetMotors()
    for _, joint in ipairs({waist, rootJoint, leftHip, rightHip, leftShoulder, rightShoulder}) do
        if joint then
            local original = baseC0[joint]
            if original and joint.Parent then
                joint.C0 = original
            end
            baseC0[joint] = nil
        end
    end
end

local function rememberBaseC0(joint)
    if joint and not baseC0[joint] then
        baseC0[joint] = joint.C0
    end
end

local function bind(nextCharacter)
    bindSerial += 1
    local serial = bindSerial
    if humanoidStateConnection then
        humanoidStateConnection:Disconnect()
        humanoidStateConnection = nil
    end
    resetMotors()
    character = nextCharacter
    -- Block rendering on this rig until both body anchors are present.
    humanoid = nil
    root = nil
    waist = nil
    rootJoint = nil
    leftHip = nil
    rightHip = nil
    leftShoulder = nil
    rightShoulder = nil
    landing = 0
    celebrationKind = nil
    celebrationWeight = 0
    celebrationUntil = 0
    airborne = false
    lastY = 0
    launchWeight = 0
    impactWeight = 0
    impactSide = 0
    impactForward = 0
    jumpWeight = 0
    fallWeight = 0
    strideClock = 0
    lastSpeed = 0
    lastMoveDirection = Vector3.zero
    brakePose = 0
    turnPose = 0
    turnSeverityPose = 0
    startPose = 0
    skidPose = 0
    cutPose = 0
    footPlantPose = 0
    ascentReachPose = 0
    descentBracePose = 0
    lastGroundCueAt = -math.huge
    readyPose = 0

    -- CharacterAdded can fire again while a streamed rig is still yielding.
    -- An older promise must never overwrite this client's current motors.
    local nextHumanoid = nextCharacter:WaitForChild("Humanoid", 5)
    local nextRoot = nextCharacter:WaitForChild("HumanoidRootPart", 5)
    if serial ~= bindSerial or character ~= nextCharacter
        or player.Character ~= nextCharacter then
        return
    end
    humanoid = nextHumanoid
    root = nextRoot
    if not humanoid or not root or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
        return
    end

    local lower = character:FindFirstChild("LowerTorso")
    local upper = character:FindFirstChild("UpperTorso")
    waist = motor(upper, "Waist")
    rootJoint = motor(lower, "Root")
    leftHip = motor(lower, "LeftHip")
    rightHip = motor(lower, "RightHip")
    leftShoulder = motor(upper, "LeftShoulder")
    rightShoulder = motor(upper, "RightShoulder")

    for _, joint in ipairs({
        waist,
        rootJoint,
        leftHip,
        rightHip,
        leftShoulder,
        rightShoulder,
    }) do
        rememberBaseC0(joint)
    end

    humanoidStateConnection = humanoid.StateChanged:Connect(function(_, state)
        if serial ~= bindSerial then return end
        if state == Enum.HumanoidStateType.Jumping then
            jumpWeight = math.max(jumpWeight, 1)
        elseif state == Enum.HumanoidStateType.Freefall then
            airborne = true
        elseif airborne and (
            state == Enum.HumanoidStateType.Landed
            or state == Enum.HumanoidStateType.Running
            or state == Enum.HumanoidStateType.RunningNoPhysics
        ) then
            airborne = false
            local fallSpeed = math.max(0, -lastY)
            if fallSpeed > 20 then
                landing = math.max(landing, math.clamp((fallSpeed - 20) / 60, 0.08, 0.65))
            end
        end
    end)
end

if player.Character then
    task.spawn(bind, player.Character)
end
player.CharacterAdded:Connect(bind)
player.CharacterRemoving:Connect(function()
    bindSerial += 1
    if humanoidStateConnection then
        humanoidStateConnection:Disconnect()
        humanoidStateConnection = nil
    end
    resetMotors()
    character = nil
    humanoid = nil
    root = nil
    waist = nil
    rootJoint = nil
    leftHip = nil
    rightHip = nil
    leftShoulder = nil
    rightShoulder = nil
end)

local function expAlpha(speed, dt)
    return 1 - math.exp(-speed * math.max(0, dt))
end

stateEvent.OnClientEvent:Connect(function(state)
    local surge = false
    local lowGravity = false
    roundPhase = state and tostring(state.phase or "waiting") or "waiting"
    if state and roundPhase == "round" then
        for _, id in ipairs(state.disasterIds or {}) do
            if id == "SpeedSurge" then
                surge = true
            elseif id == "LowGravity" then
                lowGravity = true
            end
        end
    end
    speedSurgeActive = surge
    lowGravityActive = lowGravity
end)

mechanicFeedbackEvent.OnClientEvent:Connect(function(payload)
    if player:GetAttribute("ReduceMotion") == true then
        return
    end
    launchWeight = math.max(
        launchWeight,
        type(payload) == "table" and payload.overdrive == true and 1 or 0.72
    )
end)

hazardImpactEvent.OnClientEvent:Connect(function(payload)
    if roundPhase ~= "round"
        or player:GetAttribute("RoundParticipant") ~= true
        or player:GetAttribute("RoundEliminated") == true
        or player:GetAttribute("ReduceMotion") == true
        or typeof(payload) ~= "table"
        or not root
        or not root.Parent
    then
        return
    end

    local position = payload.position
    if typeof(position) ~= "Vector3" then
        return
    end

    local proximity, side, forward = BodyMotionRules.blastResponse(
        root.CFrame, position, payload.radius
    )
    if proximity > 0 then
        -- Keep the existing soft impulse envelope; new directional accents
        -- follow the hazard instead of rotating the player's character.
        if proximity * 0.82 >= impactWeight then
            impactSide = side
            impactForward = forward
        end
        impactWeight = math.max(impactWeight, proximity * 0.82)
    end
end)

feedbackEvent.OnClientEvent:Connect(function(feedback)
    if type(feedback) ~= "table" or player:GetAttribute("ReduceMotion") == true then
        return
    end

    local survived = feedback.survived == true
    local momentumBest = math.max(0, math.floor(tonumber(feedback.momentumBest) or 0))
    local masterRound = survived
        and feedback.challengeCompleted == true
        and momentumBest >= 4

    celebrationKind = masterRound and "master" or (survived and "survive" or "eliminated")
    celebrationWeight = 1
    celebrationUntil = os.clock() + (masterRound and 1.35 or (survived and 0.95 or 0.65))
end)

local function celebrationTargets(weight)
    if not celebrationKind or weight <= 0.001 then
        return CFrame.identity,
            CFrame.identity,
            CFrame.identity,
            CFrame.identity,
            CFrame.identity,
            CFrame.identity
    end

    if celebrationKind == "master" then
        return CFrame.Angles(math.rad(-7) * weight, 0, 0),
            CFrame.Angles(math.rad(-62) * weight, 0, math.rad(-26) * weight),
            CFrame.Angles(math.rad(-62) * weight, 0, math.rad(26) * weight),
            CFrame.new(0, 0.055 * weight, 0)
                * CFrame.Angles(math.rad(-2.5) * weight, 0, 0),
            CFrame.Angles(math.rad(4) * weight, 0, math.rad(-3) * weight),
            CFrame.Angles(math.rad(-4) * weight, 0, math.rad(3) * weight)
    elseif celebrationKind == "survive" then
        return CFrame.Angles(math.rad(-4) * weight, 0, 0),
            CFrame.Angles(math.rad(-23) * weight, 0, math.rad(-14) * weight),
            CFrame.Angles(math.rad(-23) * weight, 0, math.rad(14) * weight),
            CFrame.new(0, 0.025 * weight, 0),
            CFrame.Angles(math.rad(2) * weight, 0, math.rad(-1.5) * weight),
            CFrame.Angles(math.rad(-2) * weight, 0, math.rad(1.5) * weight)
    end

    return CFrame.Angles(math.rad(9) * weight, 0, 0),
        CFrame.Angles(math.rad(14) * weight, 0, math.rad(9) * weight),
        CFrame.Angles(math.rad(14) * weight, 0, math.rad(-9) * weight),
        CFrame.new(0, -0.055 * weight, 0)
            * CFrame.Angles(math.rad(3) * weight, 0, 0),
        CFrame.Angles(math.rad(5) * weight, 0, math.rad(3) * weight),
        CFrame.Angles(math.rad(5) * weight, 0, math.rad(-3) * weight)
end

RunService:BindToRenderStep(
    "ChaosBodyFeel",
    Enum.RenderPriority.Character.Value + 1,
    function(dt)
        if not root or not root.Parent or not humanoid or humanoid.Health <= 0 then
            return
        end
        if not waist and not rootJoint then
            return
        end

        lastY = root.AssemblyLinearVelocity.Y
        local velocity = root.AssemblyLinearVelocity
        local localVelocity = root.CFrame:VectorToObjectSpace(Vector3.new(velocity.X, 0, velocity.Z))
        local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
        local moving = humanoid.MoveDirection.Magnitude > 0.05 and speed > 2.5
        local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
        local reduced = player:GetAttribute("ReduceMotion") == true
        local scale = BodyMotionRules.motionScale(reduced)

        local acceleration = (speed - lastSpeed) / math.max(dt, 1 / 240)
        local launchTarget, skidTarget = LocomotionDynamics.acceleration(
            speed, lastSpeed, dt, grounded
        )
        lastSpeed = speed
        local dynamicScale = LocomotionDynamics.profile(
            player:GetAttribute("VfxQualityTier"), reduced
        )
        startPose += (launchTarget - startPose) * expAlpha(11, dt)
        skidPose += (skidTarget - skidPose) * expAlpha(12, dt)

        local moveDirection = humanoid.MoveDirection
        local previousMoveDirection = lastMoveDirection
        local signedTurn, turnSeverity = BodyMotionRules.turnResponse(
            previousMoveDirection,
            moveDirection
        )
        if moveDirection.Magnitude > 0.05 then
            lastMoveDirection = moveDirection
        end

        local brakeTarget = BodyMotionRules.brakeWeight(acceleration, moving)
        brakePose += (brakeTarget - brakePose) * expAlpha(10, dt)
        local cutTarget = LocomotionDynamics.cut(
            previousMoveDirection, moveDirection, speed, grounded
        )
        cutPose += (cutTarget - cutPose) * expAlpha(11, dt)

        local cue, cueStrength = LocomotionDynamics.groundCue(
            launchTarget, skidTarget, cutTarget,
            player:GetAttribute("VfxQualityTier"), reduced, roundPhase
        )
        local now = os.clock()
        if cue and LocomotionDynamics.footworkEligible(
            roundPhase, player:GetAttribute("RoundParticipant"),
            player:GetAttribute("RoundEliminated"), humanoid.Health
        ) and now - lastGroundCueAt >= 0.55 then
            -- No extra per-frame loop: only a brief geometry burst for a
            -- grounded start, hard-stop skid or high-speed planted pivot.
            local contact = GroundFx.emit(
                root, cue, cueStrength, player:GetAttribute("VfxQualityTier")
            )
            if contact then
                lastGroundCueAt = now
            end
        end
        local turnTarget = signedTurn * turnSeverity
        turnPose += (turnTarget - turnPose) * expAlpha(9, dt)
        turnSeverityPose += (turnSeverity - turnSeverityPose) * expAlpha(8, dt)

        local readyTarget = BodyMotionRules.readyStance(
            roundPhase,
            grounded,
            speed
        )
        readyPose += (readyTarget - readyPose) * expAlpha(
            readyTarget > readyPose and 9 or 12,
            dt
        )

        local strideWeight, strideFrequency = BodyMotionRules.stride(
            speed,
            grounded,
            speedSurgeActive
        )
        if strideFrequency > 0 then
            strideClock += dt * strideFrequency
        end
        local strideWave = math.sin(strideClock) * strideWeight * scale
        local plantTarget = LocomotionDynamics.footPlant(
            strideClock, strideWeight, grounded
        )
        footPlantPose += (plantTarget - footPlantPose) * expAlpha(13, dt)
        local ascentTarget, descentTarget = LocomotionDynamics.flight(
            velocity.Y, grounded, lowGravityActive
        )
        ascentReachPose += (ascentTarget - ascentReachPose) * expAlpha(9, dt)
        descentBracePose += (descentTarget - descentBracePose) * expAlpha(11, dt)

        landing *= math.exp(-dt * 11)
        launchWeight *= math.exp(-dt * 4.8)
        impactWeight *= math.exp(-dt * 8.5)
        impactSide *= math.exp(-dt * 7.2)
        impactForward *= math.exp(-dt * 7.2)
        jumpWeight *= math.exp(-dt * 6.5)

        if not grounded then
            local downward = math.clamp(-velocity.Y / 46, 0, 1)
            local upward = math.clamp(velocity.Y / 42, 0, 1)
            fallWeight = math.max(
                fallWeight * math.exp(-dt * 4.2),
                downward * (lowGravityActive and 0.45 or 1)
            )
            jumpWeight = math.max(jumpWeight, upward * 0.42)
        else
            fallWeight *= math.exp(-dt * 12)
        end
        local forward = math.clamp(-localVelocity.Z / 42, -1, 1)
        local side = math.clamp(localVelocity.X / 38, -1, 1)
        local moveWeight = moving and math.min(1, speed / 17) or 0

        if celebrationKind then
            if os.clock() <= celebrationUntil then
                celebrationWeight = math.min(1, celebrationWeight + dt * 8)
            else
                celebrationWeight *= math.exp(-dt * 5.5)
                if celebrationWeight < 0.01 then
                    celebrationKind = nil
                    celebrationWeight = 0
                end
            end
        end

        local celebrationScale = reduced and 0 or celebrationWeight
        local celebrationWaist,
            celebrationLeftShoulder,
            celebrationRightShoulder,
            celebrationRoot,
            celebrationLeftHip,
            celebrationRightHip = celebrationTargets(celebrationScale)

        local surgeLean = speedSurgeActive and math.min(4.2, speed * 0.12) or 0
        local moonFloat = lowGravityActive and not grounded
            and math.sin(os.clock() * 2.0) * 1.4
            or 0
        local actionPitch = (
            -launchWeight * 8.5
            - jumpWeight * 4.0
            + fallWeight * 5.5
            + impactWeight * 4.2
        ) * scale
        local actionRoll = (
            impactWeight * math.sin(os.clock() * 24) * math.rad(1.8)
            + impactSide * impactWeight * math.rad(6.0)
        ) * scale

        local waistTarget = CFrame.Angles(
            math.rad(
                -3.2 * forward * moveWeight
                - landing * 5.5
                - readyPose * 5.2
                - surgeLean
                + moonFloat
                + brakePose * 4.0
                + impactForward * impactWeight * 4.8
            ) * scale
                + math.rad(
                    -startPose * 3.8 + skidPose * 5.0
                    + descentBracePose * 2.2
                ) * dynamicScale
                + math.rad(actionPitch),
            math.rad(turnPose * 3.2 + impactSide * impactWeight * 3.8) * scale,
            math.rad(
                -3.8 * side * moveWeight
                - turnPose * 1.6
            ) * scale + actionRoll
                + math.rad(cutPose * 5.5) * dynamicScale
        ) * celebrationWaist
        local rootTarget = CFrame.new(
            0,
            grounded and (
                -0.035 * moveWeight - landing * 0.075
                - footPlantPose * 0.022
                - skidPose * 0.025
            ) * scale or (-0.03 * jumpWeight + 0.025 * fallWeight) * scale,
            0
        ) * CFrame.Angles(
            math.rad(
                1.4 * forward * moveWeight
                + landing * 2.4
                - launchWeight * 3.5
                + readyPose * 2.8
                + fallWeight * 2.0
                - brakePose * 1.8
            ) * scale
                + math.rad(-startPose * 2.2 + skidPose * 3.6) * dynamicScale,
            math.rad(turnPose * 1.4) * scale,
            math.rad(
                1.6 * side * moveWeight
                + turnPose * 1.1
            ) * scale
                + math.rad(-cutPose * 3.8) * dynamicScale
        ) * celebrationRoot

        local hipCounter = math.rad(
            1.5 * side * moveWeight
            + turnPose * 1.2
        ) * scale
        local moonLeg = lowGravityActive and not grounded and math.rad(4.5) * scale or 0
        local tuck = math.rad(
            (jumpWeight * 9.0)
            + (fallWeight * 5.5)
            + (readyPose * 3.6)
        ) * scale
        local strideTurnScale = 1 - turnSeverityPose * 0.28
        local strideHip = math.rad(3.4) * strideWave * strideTurnScale
        local pivotHip = math.rad(cutPose * 3.0) * dynamicScale
        local brakeKnee = math.rad(skidPose * 4.2) * dynamicScale
        local leftTarget = CFrame.Angles(
            moonLeg + tuck + strideHip + brakeKnee,
            0,
            hipCounter + pivotHip
        ) * celebrationLeftHip
        local rightTarget = CFrame.Angles(
            -moonLeg + tuck - strideHip + brakeKnee,
            0,
            hipCounter - pivotHip
        ) * celebrationRightHip

        local actionArmPitch = math.rad(
            -launchWeight * 24
            - readyPose * 7.5
            + jumpWeight * 10
            + fallWeight * 18
            - landing * 11
        ) * scale
        local impactArmRoll = math.rad(impactWeight * 11) * scale
        local impactAsymmetry = math.rad(impactSide * impactWeight * 9) * scale
        local strideArm = math.rad(4.6) * strideWave * strideTurnScale
        local turnArm = math.rad(turnPose * 4.0) * scale
        local reachArm = math.rad(
            ascentReachPose * 8.0 - descentBracePose * 10.5
            - startPose * 7.2 + skidPose * 6.4
        ) * dynamicScale
        local cutArm = math.rad(cutPose * 5.5) * dynamicScale
        local leftActionShoulder = CFrame.Angles(
            actionArmPitch - strideArm + reachArm,
            turnArm,
            -impactArmRoll - cutArm - impactAsymmetry
        )
        local rightActionShoulder = CFrame.Angles(
            actionArmPitch + strideArm + reachArm,
            -turnArm,
            impactArmRoll + cutArm - impactAsymmetry
        )

        local alpha = expAlpha(grounded and 11 or 7, dt)

        local function applyOffset(joint, offset)
            local original = joint and baseC0[joint]
            if joint and original then
                joint.C0 = joint.C0:Lerp(original * offset, alpha)
            end
        end

        applyOffset(waist, waistTarget)
        applyOffset(rootJoint, rootTarget)
        applyOffset(leftHip, leftTarget)
        applyOffset(rightHip, rightTarget)
        applyOffset(
            leftShoulder,
            leftActionShoulder * celebrationLeftShoulder
        )
        applyOffset(
            rightShoulder,
            rightActionShoulder * celebrationRightShoulder
        )
    end
)
