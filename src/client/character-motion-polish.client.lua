local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local localPlayer = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local watched = setmetatable({}, {__mode = "k"})
local phase = "waiting"
local finalRush = false
local clock = 0
local updateClock = 0

local function qualityScale()
    local tier = VfxQuality.get(localPlayer:GetAttribute("VfxQualityTier"))
    local scale = tier.Name == "Low" and 0.28 or (tier.Name == "Medium" and 0.66 or 1)
    if localPlayer:GetAttribute("ReduceMotion") == true then
        scale *= 0.22
    end
    return scale, tier
end

local function activeModel(model)
    if not model or not model.Parent then
        return false
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    return humanoid ~= nil and humanoid.Health > 0
end

local function ensureTrail(root, accent)
    local existing = root:FindFirstChild("ChaosMotionTrail")
    if existing and existing:IsA("Trail") then
        return existing
    end

    local left = root:FindFirstChild("ChaosMotionTrailLeft")
    if not left then
        left = Instance.new("Attachment")
        left.Name = "ChaosMotionTrailLeft"
        left.Position = Vector3.new(-0.72, -0.85, 0.48)
        left.Parent = root
    end

    local right = root:FindFirstChild("ChaosMotionTrailRight")
    if not right then
        right = Instance.new("Attachment")
        right.Name = "ChaosMotionTrailRight"
        right.Position = Vector3.new(0.72, -0.85, 0.48)
        right.Parent = root
    end

    local trail = Instance.new("Trail")
    trail.Name = "ChaosMotionTrail"
    trail.Attachment0 = left
    trail.Attachment1 = right
    trail.FaceCamera = true
    trail.MinLength = 0.05
    trail.LightEmission = 0.8
    trail.Color = ColorSequence.new(
        accent,
        accent:Lerp(Color3.new(1, 1, 1), 0.28)
    )
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.58),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.34),
        NumberSequenceKeypoint.new(1, 0),
    })
    trail.Enabled = false
    trail.Parent = root
    return trail
end

local function ensureLeanMotor(model)
    local lower = model:FindFirstChild("LowerTorso")
    local root = model:FindFirstChild("HumanoidRootPart")
    if lower and root then
        local rootJoint = lower:FindFirstChild("Root")
        if rootJoint and rootJoint:IsA("Motor6D") then
            return rootJoint
        end
    end
    return nil
end

local function accentFor(model)
    local accent = model:GetAttribute("ChaosAccent")
    if typeof(accent) == "Color3" then
        return accent
    end
    if model:GetAttribute("AISurvivor") == true then
        return Color3.fromRGB(110, 225, 190)
    end
    return Color3.fromRGB(90, 190, 255)
end

local function watchModel(model)
    if watched[model] then
        return
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or not root:IsA("BasePart") then
        task.delay(0.12, function()
            if model.Parent then
                watchModel(model)
            end
        end)
        return
    end

    local state = {
        model = model,
        humanoid = humanoid,
        root = root,
        rootJoint = ensureLeanMotor(model),
        baseTransform = CFrame.identity,
        trail = nil,
        airborne = false,
        airborneAt = nil,
        landingKick = 0,
        isAI = model:GetAttribute("AISurvivor") == true,
        phaseOffset = ((#watched + 1) * 0.73) % 6.28,
    }

    if state.rootJoint then
        state.baseTransform = state.rootJoint.Transform
    end

    state.trail = ensureTrail(root, accentFor(model))
    watched[model] = state

    humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Jumping
            or newState == Enum.HumanoidStateType.Freefall
        then
            state.airborne = true
            state.airborneAt = state.airborneAt or os.clock()
        elseif newState == Enum.HumanoidStateType.Landed
            or newState == Enum.HumanoidStateType.Running
            or newState == Enum.HumanoidStateType.RunningNoPhysics
        then
            if state.airborneAt then
                local airtime = os.clock() - state.airborneAt
                state.landingKick = math.clamp((airtime - 0.2) / 0.8, 0, 1)
            end
            state.airborne = false
            state.airborneAt = nil
        end
    end)
end

local function watchPlayer(player)
    player.CharacterAdded:Connect(watchModel)
    if player.Character then
        watchModel(player.Character)
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    watchPlayer(p)
end
Players.PlayerAdded:Connect(watchPlayer)

local function watchBots(folder)
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            watchModel(child)
        end
    end
    folder.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            task.defer(watchModel, child)
        end
    end)
end

local bots = workspace:FindFirstChild("AISurvivors")
if bots then
    watchBots(bots)
end
workspace.ChildAdded:Connect(function(child)
    if child.Name == "AISurvivors" then
        watchBots(child)
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    phase = tostring(state.phase or "waiting")
    finalRush = phase == "round" and state.finalRush == true
end)

RunService.RenderStepped:Connect(function(dt)
    clock += dt
    updateClock += dt

    local scale, tier = qualityScale()
    if updateClock < math.max(1 / 45, tier.UpdateInterval) then
        return
    end
    updateClock = 0

    for model, state in pairs(watched) do
        if not activeModel(model) then
            if state.trail and state.trail.Parent then
                state.trail.Enabled = false
            end
            if state.rootJoint and state.rootJoint.Parent then
                state.rootJoint.Transform = state.baseTransform
            end
            continue
        end

        local root = state.root
        local humanoid = state.humanoid
        if not root or not root.Parent or not humanoid or humanoid.Health <= 0 then
            continue
        end

        local localVelocity = root.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity)
        local horizontalSpeed = Vector3.new(localVelocity.X, 0, localVelocity.Z).Magnitude
        local normalized = math.clamp(horizontalSpeed / math.max(1, humanoid.WalkSpeed), 0, 1.35)

        if state.rootJoint and state.rootJoint.Parent then
            local pitch = math.rad(math.clamp(localVelocity.Z * 0.45, -8, 8))
            local roll = math.rad(math.clamp(-localVelocity.X * 0.48, -7, 7))
            local bob = 0

            if not state.airborne and normalized > 0.12 then
                bob = math.sin(clock * (7.2 + normalized * 2.4) + state.phaseOffset)
                    * 0.035
                    * normalized
            end

            if state.isAI then
                pitch *= 0.92
                roll *= 1.08
            end

            if state.airborne then
                pitch *= 0.45
                roll *= 0.55
            end

            local landing = state.landingKick
            state.landingKick = math.max(0, state.landingKick - dt * 4.5)

            state.rootJoint.Transform = state.baseTransform
                * CFrame.new(0, -bob - landing * 0.06 * scale, 0)
                * CFrame.Angles(
                    (pitch - landing * math.rad(4.5)) * scale,
                    0,
                    roll * scale
                )
        end

        if state.trail and state.trail.Parent then
            local shouldTrail = phase == "round"
                and not finalRush
                and not state.airborne
                and normalized > (state.isAI and 0.72 or 0.82)
                and tier.Name ~= "Low"

            state.trail.Enabled = shouldTrail
            if shouldTrail then
                state.trail.Lifetime = (state.isAI and 0.11 or 0.14)
                    * (tier.Name == "High" and 1 or 0.78)
                    * (localPlayer:GetAttribute("ReduceMotion") == true and 0.35 or 1)
            end
        end
    end
end)
