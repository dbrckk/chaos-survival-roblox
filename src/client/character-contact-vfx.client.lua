local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local GroundContactRules = require(ReplicatedStorage.Shared.GroundContactRules)
local LandingImprintKit = require(script.Parent.LandingImprintKit)

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

    -- A material-aware, paper-thin imprint replaces the old filled disc.
    -- Build exactly the existing 1/3/4/6-part device budget; keep one
    -- shared active-piece registry for all human and AI survivors.
    local contactFrame = surfaceFrame(hit.Position + hit.Normal * 0.04,
        hit.Normal)
    local pieces = LandingImprintKit.build(
        folder, contactFrame, color, materialStyle, hit.Material,
        count, strength, reduced
    )
    for _, piece in ipairs(pieces) do
        registerPart(piece)
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
