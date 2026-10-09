local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local GroundContactRules = require(ReplicatedStorage.Shared.GroundContactRules)

local localPlayer = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local watched = setmetatable({}, {__mode = "k"})
local finalRush = false
local botFolderConnection = nil
local currentPhase = "waiting"
local lastContact = setmetatable({}, {__mode = "k"})
local pendingRigs = setmetatable({}, {__mode = "k"})
local activePieces = setmetatable({}, {__mode = "k"})
local folder = Instance.new("Folder")
folder.Name = "CharacterContactLocal"
folder.Parent = workspace

local function countActive()
    local count = 0
    for instance in pairs(activePieces) do
        if not instance.Parent then
            activePieces[instance] = nil
        else
            count += 1
        end
    end
    return count
end

local function registerPart(part)
    activePieces[part] = true
end

local function surfaceFrame(position, normal)
    local up = normal.Magnitude > 0.01 and normal.Unit or Vector3.yAxis
    local guide = math.abs(up:Dot(Vector3.zAxis)) > 0.95
        and Vector3.xAxis or Vector3.zAxis
    local right = guide:Cross(up).Unit
    local back = up:Cross(right).Unit
    return CFrame.fromMatrix(position, right, up, back)
end

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

    local human = Players:GetPlayerFromCharacter(model)
    if not GroundContactRules.eligible(
        currentPhase, human ~= nil,
        human and human:GetAttribute("RoundParticipant"),
        human and human:GetAttribute("RoundEliminated"),
        model:GetAttribute("AISurvivor")
    ) then
        return
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local quality = VfxQuality.get(localPlayer:GetAttribute("VfxQualityTier"))
    local reduced = localPlayer:GetAttribute("ReduceMotion") == true
    local localCharacter = model == localPlayer.Character
    local count = GroundContactRules.pieceBudget(
        quality.Name, reduced, finalRush, localCharacter)
    if count == 0 or airtime < GroundContactRules.minAirtime(quality.Name) then
        return
    end
    local observerRoot = localRoot()
    local observer = observerRoot and observerRoot.Position
        or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position)
    if not observer or (observer - root.Position).Magnitude
        > GroundContactRules.maxDistance(quality.Name)
    then
        return
    end
    local now = os.clock()
    if not GroundContactRules.cooldownReady(now, lastContact[model]) then
        return
    end
    if countActive() + count > GroundContactRules.concurrentLimit(quality.Name) then
        return
    end

    local hit = sampleSurface(root)
    if not hit then return end
    lastContact[model] = now
    local materialStyle = GroundContactRules.materialStyle(hit.Material)

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
    ring.Material = materialStyle == "Crystal" and Enum.Material.Glass
        or (materialStyle == "Mechanical" and Enum.Material.Metal
            or Enum.Material.SmoothPlastic)
    ring.Color = color
    ring.Transparency = 0.58
    ring.Parent = folder
    registerPart(ring)

    local target = reduced and 0.95 or (2.2 + strength * 2.8)
    TweenService:Create(
        ring,
        TweenInfo.new(
            reduced and 0.12 or (quality.Name == "Low" and 0.18 or 0.28),
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        {
            Size = Vector3.new(0.035, target, target),
            Transparency = 1,
        }
    ):Play()
    Debris:AddItem(ring, 0.34)

    if count <= 1 then return end

    local basis = surfaceFrame(hit.Position, hit.Normal)
    for i = 1, count - 1 do
        local angle = ((i - 1) / count) * math.pi * 2 + ((i * 17) % 11) * 0.04
        local shard = (materialStyle == "Mineral" or materialStyle == "Crystal")
            and Instance.new("WedgePart") or Instance.new("Part")
        -- Material style determines shape; never change the actual platform.
        shard.Name = "CharacterLanding" .. materialStyle .. "Shard"
        shard.Size = Vector3.new(0.10, 0.05, 0.22)
        shard.CFrame = basis
            * CFrame.new(math.cos(angle) * 0.55, 0.08, math.sin(angle) * 0.55)
            * CFrame.Angles(0, angle, math.rad((i * 19) % 25))
        shard.Anchored = true
        shard.CanCollide = false
        shard.CanTouch = false
        shard.CanQuery = false
        shard.CastShadow = false
        shard.Material = materialStyle == "Crystal" and Enum.Material.Glass
            or hit.Material
        shard.Color = color:Lerp(Color3.new(0, 0, 0), 0.18)
        shard.Transparency = 0.18
        shard.Parent = folder
        registerPart(shard)

        TweenService:Create(
            shard,
            TweenInfo.new(0.26 + i * 0.018, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Position = shard.Position
                    + basis:VectorToWorldSpace(Vector3.new(
                        math.cos(angle) * 0.8, 0.16 + strength * 0.24,
                        math.sin(angle) * 0.8)),
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
        if not pendingRigs[model] and model.Parent then
            local connection = model.ChildAdded:Connect(function(child)
                if child:IsA("Humanoid") or child.Name == "HumanoidRootPart" then
                    task.defer(watchModel, model)
                end
            end)
            pendingRigs[model] = connection
            -- A half-streamed rig cannot create endless polling tasks.
            task.delay(8, function()
                if pendingRigs[model] == connection then
                    connection:Disconnect()
                    pendingRigs[model] = nil
                end
            end)
        end
        return
    end
    if pendingRigs[model] then
        pendingRigs[model]:Disconnect()
        pendingRigs[model] = nil
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
    if botFolderConnection then
        botFolderConnection:Disconnect()
        botFolderConnection = nil
    end

    if not folder then
        return
    end

    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then
            watchModel(model)
        end
    end
    botFolderConnection = folder.ChildAdded:Connect(function(model)
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

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "AISurvivors" then
        watchBots(nil)
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    currentPhase = tostring(state.phase or "waiting")
    finalRush = currentPhase == "round" and state.finalRush == true
    if currentPhase ~= "round" then
        folder:ClearAllChildren()
    end
end)

localPlayer:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    if localPlayer:GetAttribute("ReduceMotion") == true then
        folder:ClearAllChildren()
    end
end)
localPlayer:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    if VfxQuality.get(localPlayer:GetAttribute("VfxQualityTier")).Name == "Low" then
        folder:ClearAllChildren()
    end
end)
