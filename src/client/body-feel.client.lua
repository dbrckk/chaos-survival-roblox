local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BodyMotionRules = require(ReplicatedStorage.Shared.BodyMotionRules)

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
local launchWeight = 0
local impactWeight = 0
local jumpWeight = 0
local fallWeight = 0
local strideClock = 0
local lastSpeed = 0
local lastMoveDirection = Vector3.zero
local brakePose = 0
local turnPose = 0
local turnSeverityPose = 0

local function motor(parent, name)
    local item = parent and parent:FindFirstChild(name)
    return item and item:IsA("Motor6D") and item or nil
end

local function resetMotors()
    for _, joint in ipairs({waist, rootJoint, leftHip, rightHip, leftShoulder, rightShoulder}) do
        if joint and joint.Parent then
            joint.Transform = CFrame.identity
        end
    end
end

local function bind(nextCharacter)
    resetMotors()
    character = nextCharacter
    humanoid = character:WaitForChild("Humanoid", 5)
    root = character:WaitForChild("HumanoidRootPart", 5)
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
    jumpWeight = 0
    fallWeight = 0
    strideClock = 0
    lastSpeed = 0
    lastMoveDirection = Vector3.zero
    brakePose = 0
    turnPose = 0
    turnSeverityPose = 0

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

    humanoid.StateChanged:Connect(function(_, state)
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
    resetMotors()
    character = nil
    humanoid = nil
    root = nil
end)

local function expAlpha(speed, dt)
    return 1 - math.exp(-speed * math.max(0, dt))
end

stateEvent.OnClientEvent:Connect(function(state)
    local surge = false
    local lowGravity = false
    if state and state.phase == "round" then
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
    if player:GetAttribute("ReduceMotion") == true
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

    local distance = (root.Position - position).Magnitude
    local radius = math.clamp(tonumber(payload.radius) or 8, 1, 40)
    local reach = math.max(20, radius * 4.2)
    if distance <= reach then
        local proximity = 1 - math.clamp(distance / reach, 0, 1)
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
        return CFrame.identity, CFrame.identity, CFrame.identity
    end

    if celebrationKind == "master" then
        return CFrame.Angles(math.rad(-6) * weight, 0, 0),
            CFrame.Angles(math.rad(-58) * weight, 0, math.rad(-24) * weight),
            CFrame.Angles(math.rad(-58) * weight, 0, math.rad(24) * weight)
    elseif celebrationKind == "survive" then
        return CFrame.Angles(math.rad(-3.5) * weight, 0, 0),
            CFrame.Angles(math.rad(-20) * weight, 0, math.rad(-13) * weight),
            CFrame.Angles(math.rad(-20) * weight, 0, math.rad(13) * weight)
    end

    return CFrame.Angles(math.rad(8) * weight, 0, 0),
        CFrame.Angles(math.rad(12) * weight, 0, math.rad(8) * weight),
        CFrame.Angles(math.rad(12) * weight, 0, math.rad(-8) * weight)
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
        lastSpeed = speed

        local moveDirection = humanoid.MoveDirection
        local signedTurn, turnSeverity = BodyMotionRules.turnResponse(
            lastMoveDirection,
            moveDirection
        )
        if moveDirection.Magnitude > 0.05 then
            lastMoveDirection = moveDirection
        end

        local brakeTarget = BodyMotionRules.brakeWeight(acceleration, moving)
        brakePose += (brakeTarget - brakePose) * expAlpha(10, dt)
        local turnTarget = signedTurn * turnSeverity
        turnPose += (turnTarget - turnPose) * expAlpha(9, dt)
        turnSeverityPose += (turnSeverity - turnSeverityPose) * expAlpha(8, dt)

        local strideWeight, strideFrequency = BodyMotionRules.stride(
            speed,
            grounded,
            speedSurgeActive
        )
        if strideFrequency > 0 then
            strideClock += dt * strideFrequency
        end
        local strideWave = math.sin(strideClock) * strideWeight * scale

        landing *= math.exp(-dt * 11)
        launchWeight *= math.exp(-dt * 4.8)
        impactWeight *= math.exp(-dt * 8.5)
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
        local celebrationWaist, celebrationLeftShoulder, celebrationRightShoulder =
            celebrationTargets(celebrationScale)

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
        local actionRoll = impactWeight
            * math.sin(os.clock() * 24)
            * math.rad(5.5)
            * scale

        local waistTarget = CFrame.Angles(
            math.rad(
                -3.2 * forward * moveWeight
                - landing * 5.5
                - surgeLean
                + moonFloat
                + brakePose * 4.0
            ) * scale
                + math.rad(actionPitch),
            math.rad(turnPose * 3.2) * scale,
            math.rad(
                -3.8 * side * moveWeight
                - turnPose * 1.6
            ) * scale + actionRoll
        ) * celebrationWaist
        local rootTarget = CFrame.new(
            0,
            grounded and (-0.035 * moveWeight - landing * 0.075) * scale
                or (-0.03 * jumpWeight + 0.025 * fallWeight) * scale,
            0
        ) * CFrame.Angles(
            math.rad(
                1.4 * forward * moveWeight
                + landing * 2.4
                - launchWeight * 3.5
                + fallWeight * 2.0
                - brakePose * 1.8
            ) * scale,
            math.rad(turnPose * 1.4) * scale,
            math.rad(
                1.6 * side * moveWeight
                + turnPose * 1.1
            ) * scale
        )

        local hipCounter = math.rad(
            1.5 * side * moveWeight
            + turnPose * 1.2
        ) * scale
        local moonLeg = lowGravityActive and not grounded and math.rad(4.5) * scale or 0
        local tuck = math.rad((jumpWeight * 9.0) + (fallWeight * 5.5)) * scale
        local strideTurnScale = 1 - turnSeverityPose * 0.28
        local strideHip = math.rad(3.4) * strideWave * strideTurnScale
        local leftTarget = CFrame.Angles(
            moonLeg + tuck + strideHip,
            0,
            hipCounter
        )
        local rightTarget = CFrame.Angles(
            -moonLeg + tuck - strideHip,
            0,
            hipCounter
        )

        local actionArmPitch = math.rad(
            -launchWeight * 24
            + jumpWeight * 10
            + fallWeight * 18
            - landing * 11
        ) * scale
        local impactArmRoll = math.rad(impactWeight * 11) * scale
        local strideArm = math.rad(4.6) * strideWave * strideTurnScale
        local turnArm = math.rad(turnPose * 4.0) * scale
        local leftActionShoulder = CFrame.Angles(
            actionArmPitch - strideArm,
            turnArm,
            -impactArmRoll
        )
        local rightActionShoulder = CFrame.Angles(
            actionArmPitch + strideArm,
            -turnArm,
            impactArmRoll
        )

        local alpha = expAlpha(grounded and 11 or 7, dt)
        if waist then
            waist.Transform = waist.Transform:Lerp(waistTarget, alpha)
        end
        if rootJoint then
            rootJoint.Transform = rootJoint.Transform:Lerp(rootTarget, alpha)
        end
        if leftHip then
            leftHip.Transform = leftHip.Transform:Lerp(leftTarget, alpha)
        end
        if rightHip then
            rightHip.Transform = rightHip.Transform:Lerp(rightTarget, alpha)
        end
        if leftShoulder then
            leftShoulder.Transform = leftShoulder.Transform:Lerp(
                leftActionShoulder * celebrationLeftShoulder,
                alpha
            )
        end
        if rightShoulder then
            rightShoulder.Transform = rightShoulder.Transform:Lerp(
                rightActionShoulder * celebrationRightShoulder,
                alpha
            )
        end
    end
)
