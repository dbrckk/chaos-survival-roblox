local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local localPlayer = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local watched = setmetatable({}, {__mode = "k"})
local finalRush = false

local function localRoot()
    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return root and root:IsA("BasePart") and root or nil
end

local function sampleSurface(root)
    local generated = workspace:FindFirstChild("GeneratedMap")
    if not generated then
        return nil
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {generated}
    params.IgnoreWater = true

    return workspace:Raycast(
        root.Position + Vector3.new(0, 1.5, 0),
        Vector3.new(0, -7, 0),
        params
    )
end

local function cylinderOnSurface(position, normal)
    local xAxis = normal.Magnitude > 0.01
        and normal.Unit
        or Vector3.new(0, 1, 0)
    local seed = math.abs(xAxis:Dot(Vector3.new(0, 1, 0))) > 0.95
        and Vector3.new(0, 0, 1)
        or Vector3.new(0, 1, 0)
    local zAxis = xAxis:Cross(seed).Unit
    local yAxis = zAxis:Cross(xAxis).Unit
    return CFrame.fromMatrix(position, xAxis, yAxis, zAxis)
end

local function emitLanding(model, airtime)
    local root = model:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return
    end

    if finalRush and model ~= localPlayer.Character then
        return
    end

    local observerRoot = localRoot()
    if observerRoot and (observerRoot.Position - root.Position).Magnitude > 90 then
        return
    end

    local quality = VfxQuality.get(localPlayer:GetAttribute("VfxQualityTier"))
    local reduced = localPlayer:GetAttribute("ReduceMotion") == true
    if quality.Name == "Low" and airtime < 0.65 then
        return
    end

    local hit = sampleSurface(root)
    if not hit then
        return
    end

    local strength = math.clamp((airtime - 0.28) / 1.15, 0.18, 1)
    if reduced then
        strength *= 0.45
    end

    local color = hit.Instance:IsA("BasePart")
        and hit.Instance.Color:Lerp(Color3.new(1, 1, 1), 0.12)
        or Color3.fromRGB(150, 160, 175)

    local ring = Instance.new("Part")
    ring.Name = "CharacterLandingContact"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.035, 0.8, 0.8)
    ring.CFrame = cylinderOnSurface(
        hit.Position + hit.Normal * 0.045,
        hit.Normal
    )
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.CastShadow = false
    ring.Material = Enum.Material.Neon
    ring.Color = color
    ring.Transparency = 0.58
    ring.Parent = workspace

    local target = 2.2 + strength * 2.8
    TweenService:Create(
        ring,
        TweenInfo.new(
            quality.Name == "Low" and 0.18 or 0.28,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        {
            Size = Vector3.new(0.035, target, target),
            Transparency = 1,
        }
    ):Play()
    Debris:AddItem(ring, 0.34)

    if quality.Name == "Low" or reduced then
        return
    end

    local count = quality.Name == "High" and 5 or 3
    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2 + ((i * 17) % 11) * 0.04
        local shard = Instance.new("Part")
        shard.Name = "CharacterLandingShard"
        shard.Size = Vector3.new(0.10, 0.05, 0.22)
        shard.CFrame = CFrame.new(
            hit.Position
                + hit.Normal * 0.08
                + Vector3.new(math.cos(angle), 0, math.sin(angle)) * 0.55
        ) * CFrame.Angles(0, angle, math.rad((i * 19) % 25))
        shard.Anchored = true
        shard.CanCollide = false
        shard.CanTouch = false
        shard.CanQuery = false
        shard.CastShadow = false
        shard.Material = hit.Material
        shard.Color = color:Lerp(Color3.new(0, 0, 0), 0.18)
        shard.Transparency = 0.18
        shard.Parent = workspace

        TweenService:Create(
            shard,
            TweenInfo.new(0.26 + i * 0.018, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Position = shard.Position
                    + Vector3.new(math.cos(angle) * 0.8, 0.16 + strength * 0.24, math.sin(angle) * 0.8),
                Transparency = 1,
            }
        ):Play()
        Debris:AddItem(shard, 0.42)
    end
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

    watched[model] = true
    local airborneAt = nil

    humanoid.StateChanged:Connect(function(_, state)
        if state == Enum.HumanoidStateType.Freefall then
            airborneAt = airborneAt or os.clock()
        elseif airborneAt and (
            state == Enum.HumanoidStateType.Landed
            or state == Enum.HumanoidStateType.Running
            or state == Enum.HumanoidStateType.RunningNoPhysics
        ) then
            local airtime = os.clock() - airborneAt
            airborneAt = nil
            if airtime >= 0.34 then
                emitLanding(model, airtime)
            end
        elseif state == Enum.HumanoidStateType.Dead then
            airborneAt = nil
        end
    end)
end

local function watchPlayer(player)
    player.CharacterAdded:Connect(watchModel)
    if player.Character then
        watchModel(player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    watchPlayer(player)
end
Players.PlayerAdded:Connect(watchPlayer)

local function watchBots(folder)
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then
            watchModel(model)
        end
    end
    folder.ChildAdded:Connect(function(model)
        if model:IsA("Model") then
            task.defer(watchModel, model)
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
    finalRush = tostring(state.phase or "") == "round"
        and state.finalRush == true
end)
