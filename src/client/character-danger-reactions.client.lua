-- Event-driven character micro-VFX: dodge ribbons, blast-pressure arcs and
-- short landing stabilizers. These are extra cosmetic attachments only.
-- Locomotion, hit detection, Animator, physics and camera are untouched.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Rules = require(ReplicatedStorage.Shared.CharacterReactionRules)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local nearMissEvent = remotes:WaitForChild("HazardNearMiss")
local impactEvent = remotes:WaitForChild("HazardImpactFeedback")
local roundEvent = remotes:WaitForChild("RoundState")

local phase = "waiting"
local lastDodge = -math.huge
local lastImpact = -math.huge
local impactByModel = setmetatable({}, {__mode = "k"})
local landingByModel = setmetatable({}, {__mode = "k"})
local watched = setmetatable({}, {__mode = "k"})
local activePieces = setmetatable({}, {__mode = "k"})
local botFolderConnection = nil
local botFolder = nil

local function profile()
    local quality = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    return Rules.profile(quality.Name, player:GetAttribute("ReduceMotion") == true)
end

local function liveRoot(model)
    if not model or not model.Parent then
        return nil
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if humanoid and Rules.isActive(phase, humanoid.Health)
        and root and root:IsA("BasePart")
    then
        return root
    end
    return nil
end

local function viewerPosition()
    local root = liveRoot(player.Character)
    if root then
        return root.Position
    end
    local camera = workspace.CurrentCamera
    return camera and camera.CFrame.Position or nil
end

local function killPieces()
    for object in pairs(activePieces) do
        if object.Parent then
            object:Destroy()
        end
        activePieces[object] = nil
    end
end

local function colorFor(kind, mode)
    if mode == "Landing" then
        return Color3.fromRGB(95, 216, 255)
    elseif kind == "Bomb" then
        return Color3.fromRGB(255, 107, 127)
    elseif kind == "Meteor" then
        return Color3.fromRGB(255, 184, 86)
    end
    return Color3.fromRGB(106, 220, 235)
end

-- Beams create a curved 3D energy silhouette that follows its avatar, even
-- when the character stands still. All artifacts self-destruct in <0.5 sec.
local function stroke(root, mode, kind, index, count, strength)
    local side = index % 2 == 0 and 1 or -1
    local stripe = math.ceil(index / 2)
    local height = 0.24 + stripe * 0.22
    local startPosition
    local endPosition
    if mode == "Dodge" then
        startPosition = Vector3.new(side * 0.72, -0.36 + height, 0.62)
        endPosition = Vector3.new(side * (1.1 + strength * 0.42), 0.92 + height, -0.52)
    elseif mode == "Shock" then
        startPosition = Vector3.new(side * 0.55, 0.16 + height, 0.38)
        endPosition = Vector3.new(side * (1.45 + strength * 0.50), 0.38 + height, -0.40)
    else
        startPosition = Vector3.new(side * 0.45, -1.10, 0.32)
        endPosition = Vector3.new(side * (0.92 + strength * 0.32), -1.62, -0.72)
    end

    local a = Instance.new("Attachment")
    a.Name = "ChaosReaction" .. mode .. "Start"
    a.Position = startPosition
    a.Parent = root
    local b = Instance.new("Attachment")
    b.Name = "ChaosReaction" .. mode .. "End"
    b.Position = endPosition
    b.Parent = root

    local beam = Instance.new("Beam")
    beam.Name = "ChaosReaction" .. mode
    beam.Attachment0 = a
    beam.Attachment1 = b
    beam.Segments = 8
    beam.FaceCamera = true
    beam.LightEmission = 0.72
    beam.LightInfluence = 0
    beam.Width0 = 0.09 + 0.055 * strength
    beam.Width1 = 0.015
    beam.CurveSize0 = side * (0.35 + strength * 0.35)
    beam.CurveSize1 = -side * 0.22
    beam.Color = ColorSequence.new(
        colorFor(kind, mode),
        Color3.fromRGB(230, 248, 255)
    )
    beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(0.60, 0.38),
        NumberSequenceKeypoint.new(1, 1),
    })
    beam.Parent = root

    local lifetime = mode == "Dodge" and 0.42
        or (mode == "Shock" and 0.31 or 0.34)
    for _, instance in ipairs({a, b, beam}) do
        activePieces[instance] = true
        Debris:AddItem(instance, lifetime)
        task.delay(lifetime + 0.02, function()
            activePieces[instance] = nil
        end)
    end
end

local function burst(model, mode, kind, count, strength)
    local root = liveRoot(model)
    if not root or count <= 0 then
        return
    end
    for i = 1, count do
        stroke(root, mode, kind, i, count, strength)
    end
end

local function nearMiss(payload)
    if type(payload) ~= "table" then
        return
    end
    local current = profile()
    if current.Dodge == 0 or not liveRoot(player.Character) then
        return
    end
    local now = os.clock()
    if not Rules.cooldownReady(now, lastDodge, 0.80) then
        return
    end
    lastDodge = now
    burst(player.Character, "Dodge", tostring(payload.kind or ""),
        current.Dodge,
        Rules.dodgeStrength(payload.distance, payload.radius))
end

local function impact(payload)
    if type(payload) ~= "table"
        or typeof(payload.position) ~= "Vector3"
    then
        return
    end
    local p = profile()
    if p.Shock == 0 or p.MaxReactors <= 0 then
        return
    end
    local now = os.clock()
    if not Rules.cooldownReady(now, lastImpact, 0.18) then
        return
    end
    lastImpact = now
    local viewer = viewerPosition()
    if not viewer or (payload.position - viewer).Magnitude > p.Range + 40 then
        return
    end
    local n = 0

    local function candidate(model)
        if n >= p.MaxReactors then
            return
        end
        local root = liveRoot(model)
        if not root or (root.Position - viewer).Magnitude > p.Range then
            return
        end
        local d = (root.Position - payload.position).Magnitude
        local intensity = Rules.airShockStrength(d, payload.radius)
        if intensity <= 0 then
            return
        end
        if not Rules.cooldownReady(now, impactByModel[model], 0.95) then
            return
        end
        impactByModel[model] = now
        n += 1
        burst(model, "Shock", tostring(payload.kind or ""), p.Shock, intensity)
    end

    candidate(player.Character)
    for _, other in ipairs(Players:GetPlayers()) do
        if n >= p.MaxReactors then
            break
        end
        if other ~= player then
            candidate(other.Character)
        end
    end
    if n < p.MaxReactors then
        local bots = workspace:FindFirstChild("AISurvivors")
        if bots then
            for _, model in ipairs(bots:GetChildren()) do
                if n >= p.MaxReactors then
                    break
                end
                if model:IsA("Model") then
                    candidate(model)
                end
            end
        end
    end
end

local function watchLanding(model)
    if watched[model] then
        return
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then
        return
    end
    watched[model] = true
    local airborneAt = nil
    humanoid.StateChanged:Connect(function(_, state)
        if state == Enum.HumanoidStateType.Freefall then
            airborneAt = airborneAt or os.clock()
        elseif state == Enum.HumanoidStateType.Dead then
            airborneAt = nil
        elseif state == Enum.HumanoidStateType.Landed then
            local started = airborneAt
            airborneAt = nil
            if not started then
                return
            end
            local now = os.clock()
            local strength = Rules.landingStrength(now - started)
            local settings = profile()
            if strength == 0 or settings.Landing == 0
                or not Rules.cooldownReady(now, landingByModel[model], 1.20)
            then
                return
            end
            local viewer = viewerPosition()
            if not viewer or (root.Position - viewer).Magnitude > settings.Range then
                return
            end
            landingByModel[model] = now
            burst(model, "Landing", "", settings.Landing, strength)
        end
    end)
end

local function watchPlayer(p)
    p.CharacterAdded:Connect(watchLanding)
    if p.Character then
        task.defer(watchLanding, p.Character)
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    watchPlayer(p)
end
Players.PlayerAdded:Connect(watchPlayer)

local function bindBots(folder)
    if botFolderConnection then
        botFolderConnection:Disconnect()
        botFolderConnection = nil
    end
    botFolder = folder
    if folder then
        for _, model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") then
                task.defer(watchLanding, model)
            end
        end
        botFolderConnection = folder.ChildAdded:Connect(function(model)
            if model:IsA("Model") then
                task.defer(watchLanding, model)
            end
        end)
    end
end

bindBots(workspace:FindFirstChild("AISurvivors"))
workspace.ChildAdded:Connect(function(child)
    if child.Name == "AISurvivors" and child ~= botFolder then
        bindBots(child)
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child == botFolder then
        bindBots(nil)
    end
end)

player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    if player:GetAttribute("ReduceMotion") == true then
        killPieces()
    end
end)
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    if profile().Dodge == 0 then
        killPieces()
    end
end)

roundEvent.OnClientEvent:Connect(function(snapshot)
    phase = tostring(snapshot.phase or "waiting")
    if phase ~= "round" then
        killPieces()
    end
end)

nearMissEvent.OnClientEvent:Connect(nearMiss)
impactEvent.OnClientEvent:Connect(impact)
