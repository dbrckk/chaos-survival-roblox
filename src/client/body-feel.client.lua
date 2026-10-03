local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local feedbackEvent = remotes:WaitForChild("RoundFeedback")
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
        if state == Enum.HumanoidStateType.Freefall then
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
        local scale = reduced and 0.18 or 1

        landing *= math.exp(-dt * 11)
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
        local waistTarget = CFrame.Angles(
            math.rad(-3.2 * forward * moveWeight - landing * 5.5 - surgeLean + moonFloat) * scale,
            0,
            math.rad(-3.8 * side * moveWeight) * scale
        ) * celebrationWaist
        local rootTarget = CFrame.new(
            0,
            grounded and (-0.035 * moveWeight - landing * 0.075) * scale or 0,
            0
        ) * CFrame.Angles(
            math.rad(1.4 * forward * moveWeight + landing * 2.4) * scale,
            0,
            math.rad(1.6 * side * moveWeight) * scale
        )

        local hipCounter = math.rad(1.5 * side * moveWeight) * scale
        local moonLeg = lowGravityActive and not grounded and math.rad(4.5) * scale or 0
        local leftTarget = CFrame.Angles(moonLeg, 0, hipCounter)
        local rightTarget = CFrame.Angles(-moonLeg, 0, hipCounter)

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
            leftShoulder.Transform = leftShoulder.Transform:Lerp(celebrationLeftShoulder, alpha)
        end
        if rightShoulder then
            rightShoulder.Transform = rightShoulder.Transform:Lerp(celebrationRightShoulder, alpha)
        end
    end
)
