local Players = game:GetService("Players")

local AISurvivorRules = require(script.Parent.AISurvivorRules)
local ArenaPresentation = require(ReplicatedStorage.Shared.ArenaPresentation)
local ArenaMechanics = require(script.Parent.ArenaMechanics)
local LobbyActivities = require(script.Parent.LobbyActivities)

local AISurvivorService = {}

local IDENTITIES = {
    {
        Username = "NovaByte",
        DisplayName = "Nova",
        Skin = Color3.fromRGB(245, 205, 176),
        Torso = Color3.fromRGB(72, 128, 255),
        Legs = Color3.fromRGB(32, 40, 58),
        Accent = Color3.fromRGB(85, 205, 255),
        Height = 0.98,
        Width = 0.96,
    },
    {
        Username = "MiloRush",
        DisplayName = "Milo",
        Skin = Color3.fromRGB(194, 139, 105),
        Torso = Color3.fromRGB(92, 62, 155),
        Legs = Color3.fromRGB(42, 44, 56),
        Accent = Color3.fromRGB(190, 105, 255),
        Height = 1.02,
        Width = 1.00,
    },
    {
        Username = "JaxOrbit",
        DisplayName = "Jax",
        Skin = Color3.fromRGB(120, 82, 62),
        Torso = Color3.fromRGB(36, 142, 126),
        Legs = Color3.fromRGB(28, 38, 45),
        Accent = Color3.fromRGB(75, 235, 190),
        Height = 1.04,
        Width = 1.02,
    },
    {
        Username = "KaiPixel",
        DisplayName = "Kai",
        Skin = Color3.fromRGB(225, 181, 148),
        Torso = Color3.fromRGB(200, 72, 82),
        Legs = Color3.fromRGB(35, 39, 52),
        Accent = Color3.fromRGB(255, 110, 125),
        Height = 1.00,
        Width = 0.98,
    },
    {
        Username = "LumiDash",
        DisplayName = "Lumi",
        Skin = Color3.fromRGB(238, 198, 170),
        Torso = Color3.fromRGB(232, 112, 180),
        Legs = Color3.fromRGB(48, 42, 62),
        Accent = Color3.fromRGB(255, 145, 220),
        Height = 0.97,
        Width = 0.95,
    },
    {
        Username = "TheoFlux",
        DisplayName = "Theo",
        Skin = Color3.fromRGB(166, 112, 82),
        Torso = Color3.fromRGB(225, 142, 55),
        Legs = Color3.fromRGB(42, 44, 48),
        Accent = Color3.fromRGB(255, 190, 80),
        Height = 1.03,
        Width = 1.01,
    },
    {
        Username = "RinVector",
        DisplayName = "Rin",
        Skin = Color3.fromRGB(214, 165, 133),
        Torso = Color3.fromRGB(78, 84, 190),
        Legs = Color3.fromRGB(32, 34, 50),
        Accent = Color3.fromRGB(125, 135, 255),
        Height = 1.01,
        Width = 0.97,
    },
    {
        Username = "EzraJump",
        DisplayName = "Ezra",
        Skin = Color3.fromRGB(108, 75, 58),
        Torso = Color3.fromRGB(56, 164, 214),
        Legs = Color3.fromRGB(30, 42, 54),
        Accent = Color3.fromRGB(90, 205, 255),
        Height = 1.05,
        Width = 1.03,
    },
}

local config = nil
local botsFolder = nil
local records = {}
local currentState = {
    phase = "waiting",
    disasterIds = {},
}
local previousPhase = "waiting"
local voteToken = 0
local voteIds = {}
local voteActive = false
local voteRoundNumber = 1
local started = false
local brainStarted = false
local identityOrder = {}
local roundSerial = 0

local function humanCount()
    return #Players:GetPlayers()
end

local function getLobbyPosition(slot)
    local offsets = {
        Vector3.new(-10, 3.2, 8),
        Vector3.new(11, 3.2, 7),
        Vector3.new(0, 3.2, -9),
    }
    return config.LobbyCenter + offsets[((slot - 1) % #offsets) + 1]
end

local function sortedParts(folder)
    local result = {}
    if not folder then
        return result
    end

    for _, item in ipairs(folder:GetChildren()) do
        if item:IsA("BasePart") then
            table.insert(result, item)
        end
    end

    table.sort(result, function(a, b)
        return a.Name < b.Name
    end)
    return result
end

local function arenaParts()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    return generated, arena
end

local function arenaBase()
    local _, arena = arenaParts()
    local base = arena and arena:FindFirstChild("Base")
    return base and base:IsA("BasePart") and base or nil
end

local function arenaVariantId()
    local _, arena = arenaParts()
    return tostring(arena and arena:GetAttribute("VariantId") or "Classic")
end

local function arenaSpawnCFrame(slot)
    local _, arena = arenaParts()
    local spawns = arena and arena:FindFirstChild("Spawns")
    local list = sortedParts(spawns)
    if #list == 0 then
        local position = config.ArenaCenter + Vector3.new((slot - 2) * 7, 4, 0)
        return ArenaPresentation.spawnCFrame(
            tostring(arena and arena:GetAttribute("VariantId") or "Classic"),
            position,
            config.ArenaCenter
        )
    end

    local spawn = list[((slot - 1) % #list) + 1]
    return spawn.CFrame + Vector3.new(0, 4, 0)
end

local function destroyTracks(record)
    if record.tracks then
        for _, track in pairs(record.tracks) do
            pcall(function()
                track:Stop(0.08)
                track:Destroy()
            end)
        end
    end
    record.tracks = nil

    if record.connections then
        for _, connection in ipairs(record.connections) do
            connection:Disconnect()
        end
    end
    record.connections = {}
end

local function loadTrack(animator, animationId, priority, looped)
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. tostring(animationId)

    local ok, track = pcall(animator.LoadAnimation, animator, animation)
    animation:Destroy()

    if not ok or not track then
        return nil
    end

    track.Priority = priority
    track.Looped = looped
    return track
end

local function attachAnimations(record, humanoid)
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    local tracks = {
        idle = loadTrack(animator, 507766666, Enum.AnimationPriority.Idle, true),
        walk = loadTrack(animator, 507777826, Enum.AnimationPriority.Movement, true),
        jump = loadTrack(animator, 507765000, Enum.AnimationPriority.Action, false),
    }
    record.tracks = tracks

    if tracks.idle then
        pcall(tracks.idle.Play, tracks.idle, 0.15)
    end

    table.insert(record.connections, humanoid.Running:Connect(function(speed)
        if speed > 0.75 then
            if tracks.idle and tracks.idle.IsPlaying then
                tracks.idle:Stop(0.12)
            end
            if tracks.walk and not tracks.walk.IsPlaying then
                tracks.walk:Play(0.12)
            end
            if tracks.walk then
                tracks.walk:AdjustSpeed(
                    math.clamp(
                        (speed / 16) * (record.gaitScale or 1),
                        0.70,
                        1.40
                    )
                )
            end
        else
            if tracks.walk and tracks.walk.IsPlaying then
                tracks.walk:Stop(0.12)
            end
            if tracks.idle and not tracks.idle.IsPlaying then
                tracks.idle:Play(0.12)
            end
        end
    end))

    table.insert(record.connections, humanoid.Jumping:Connect(function(active)
        if active and tracks.jump then
            tracks.jump:Play(0.05)
        end
    end))
end


local function cosmeticPart(parent, name, size, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Material = Enum.Material.SmoothPlastic
    part.Massless = true
    part.Anchored = false
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = true
    part.Parent = parent
    return part
end

local function weldTo(part, target)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = target
    weld.Part1 = part
    weld.Parent = part
end

local function addPrimitiveAccessory(record, model)
    local head = model:FindFirstChild("Head")
    local torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
    if not head or not head:IsA("BasePart") then
        return
    end

    local style = AISurvivorRules.appearanceStyle(record.identityIndex or record.slot)
    local accent = record.identity.Accent

    if style == 1 then
        local visor = cosmeticPart(
            model,
            "PlayerVisor",
            Vector3.new(2.05, 0.24, 1.18),
            accent:Lerp(Color3.new(1, 1, 1), 0.12)
        )
        visor.CFrame = head.CFrame * CFrame.new(0, 0.58, -0.02)
        weldTo(visor, head)

        local brim = cosmeticPart(
            model,
            "PlayerVisorBrim",
            Vector3.new(1.5, 0.10, 0.55),
            accent
        )
        brim.CFrame = head.CFrame * CFrame.new(0, 0.48, -0.67)
        weldTo(brim, head)
    elseif style == 2 then
        for side = -1, 1, 2 do
            local ear = cosmeticPart(
                model,
                side < 0 and "HeadphoneLeft" or "HeadphoneRight",
                Vector3.new(0.34, 0.76, 0.76),
                accent
            )
            ear.Shape = Enum.PartType.Cylinder
            ear.CFrame = head.CFrame
                * CFrame.new(side * 0.98, 0.04, 0)
                * CFrame.Angles(0, 0, math.rad(90))
            weldTo(ear, head)
        end

        local band = cosmeticPart(
            model,
            "HeadphoneBand",
            Vector3.new(1.75, 0.18, 0.28),
            accent:Lerp(Color3.new(1, 1, 1), 0.20)
        )
        band.CFrame = head.CFrame * CFrame.new(0, 0.68, 0)
        weldTo(band, head)
    elseif style == 3 and torso and torso:IsA("BasePart") then
        local pack = cosmeticPart(
            model,
            "PlayerBackpack",
            Vector3.new(1.55, 1.85, 0.48),
            record.identity.Legs:Lerp(accent, 0.24)
        )
        pack.CFrame = torso.CFrame * CFrame.new(0, 0.02, 0.74)
        weldTo(pack, torso)

        local strip = cosmeticPart(
            model,
            "BackpackGlow",
            Vector3.new(0.28, 1.36, 0.10),
            accent
        )
        strip.Material = Enum.Material.Neon
        strip.CFrame = torso.CFrame * CFrame.new(0, 0.02, 1.00)
        weldTo(strip, torso)
    elseif style == 4 then
        local band = cosmeticPart(
            model,
            "PlayerHeadband",
            Vector3.new(2.02, 0.20, 1.08),
            accent
        )
        band.CFrame = head.CFrame * CFrame.new(0, 0.42, 0)
        weldTo(band, head)

        local badge = cosmeticPart(
            model,
            "HeadbandBadge",
            Vector3.new(0.42, 0.30, 0.10),
            accent:Lerp(Color3.new(1, 1, 1), 0.35)
        )
        badge.Material = Enum.Material.Neon
        badge.CFrame = head.CFrame * CFrame.new(0.56, 0.42, -0.56)
        weldTo(badge, head)
    elseif torso and torso:IsA("BasePart") then
        local shoulder = cosmeticPart(
            model,
            "PlayerShoulderBand",
            Vector3.new(0.34, 1.10, 0.62),
            accent:Lerp(record.identity.Torso, 0.28)
        )
        shoulder.CFrame = torso.CFrame * CFrame.new(1.02, 0.35, 0)
        weldTo(shoulder, torso)

        local tag = cosmeticPart(
            model,
            "ShoulderGlow",
            Vector3.new(0.10, 0.56, 0.42),
            accent
        )
        tag.Material = Enum.Material.Neon
        tag.CFrame = torso.CFrame * CFrame.new(1.20, 0.35, -0.02)
        weldTo(tag, torso)
    end
end

local function addCosmeticTrail(record, root)
    local style = AISurvivorRules.appearanceStyle(record.identityIndex or record.slot)
    if style == 1 or style == 4 then
        return
    end

    local left = Instance.new("Attachment")
    left.Name = "AISurvivorTrailLeft"
    left.Position = Vector3.new(-0.65, -0.65, 0.55)
    left.Parent = root

    local right = Instance.new("Attachment")
    right.Name = "AISurvivorTrailRight"
    right.Position = Vector3.new(0.65, -0.65, 0.55)
    right.Parent = root

    local trail = Instance.new("Trail")
    trail.Name = "AISurvivorCosmeticTrail"
    trail.Attachment0 = left
    trail.Attachment1 = right
    trail.Lifetime = 0.11 + (((record.identityIndex or record.slot) % 3) * 0.035)
    trail.MinLength = 0.05
    trail.FaceCamera = true
    trail.LightEmission = 0.72
    trail.Color = ColorSequence.new(
        record.identity.Accent,
        record.identity.Accent:Lerp(Color3.new(1, 1, 1), 0.34)
    )
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.42),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.36),
        NumberSequenceKeypoint.new(1, 0),
    })
    trail.Parent = root
end

local function makeDescription(record)
    local identity = record.identity
    local description = Instance.new("HumanoidDescription")

    local bodyScale, proportionScale = AISurvivorRules.bodyScales(
        record.identityIndex or record.slot
    )
    local depthScale, headScale = AISurvivorRules.shapeScales(
        record.identityIndex or record.slot
    )

    pcall(function()
        description.HeadColor = identity.Skin
        description.LeftArmColor = identity.Skin
        description.RightArmColor = identity.Skin
        description.TorsoColor = identity.Torso
        description.LeftLegColor = identity.Legs
        description.RightLegColor = identity.Legs
        description.HeightScale = identity.Height
        description.WidthScale = identity.Width
        description.DepthScale = depthScale
        description.HeadScale = headScale
        description.BodyTypeScale = bodyScale
        description.ProportionScale = proportionScale
    end)

    return description
end

local function createRig(record)
    destroyTracks(record)

    if record.model and record.model.Parent then
        record.model:Destroy()
    end

    local description = makeDescription(record)
    local ok, model = pcall(
        Players.CreateHumanoidModelFromDescription,
        Players,
        description,
        Enum.HumanoidRigType.R15
    )
    description:Destroy()

    if not ok or not model then
        warn("AI Survivor rig creation failed:", record.identity.Username, model)
        record.model = nil
        record.proxy.Character = nil
        return false
    end

    model.Name = record.identity.Username
    model:SetAttribute("AISurvivor", true)
    model:SetAttribute("AISurvivorSlot", record.slot)
    model:SetAttribute("AISurvivorProfile", record.profile.Id)
    model:SetAttribute("ChaosAccent", record.identity.Accent)

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or not root:IsA("BasePart") then
        model:Destroy()
        record.model = nil
        record.proxy.Character = nil
        return false
    end

    humanoid.DisplayName = record.identity.DisplayName
    humanoid.WalkSpeed = record.profile.WalkSpeed
    humanoid.AutoRotate = true
    humanoid.NameDisplayDistance = 72
    humanoid.HealthDisplayDistance = 42
    humanoid.MaxHealth = 100
    humanoid.Health = 100

    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            pcall(descendant.SetNetworkOwner, descendant, nil)
        end
    end

    model.Parent = botsFolder
    record.model = model
    record.proxy.Character = model
    record.alive = true
    record.target = nil
    record.targetPart = nil
    record.targetIsPad = false
    record.nextThink = 0
    record.nextJump = os.clock() + 1.2 + math.random()
    record.nextPadAt = 0
    record.moveDirection = Vector3.zero
    record.lastMoveTarget = nil
    record.turnPauseUntil = 0
    record.threat = nil
    record.threatSeenAt = nil

    addPrimitiveAccessory(record, model)
    addCosmeticTrail(record, root)
    attachAnimations(record, humanoid)

    table.insert(record.connections, humanoid.Died:Connect(function()
        record.alive = false
        record.target = nil
        record.targetPart = nil

        if currentState.phase == "round" then
            task.delay(2.1 + math.random() * 0.7, function()
                if record.model == model and model.Parent and currentState.phase == "round" then
                    model:Destroy()
                    record.model = nil
                    record.proxy.Character = nil
                end
            end)
        end
    end))

    return true
end

local function pivotRecord(record, target)
    if not record.model or not record.model.Parent then
        return
    end
    local cframe = typeof(target) == "CFrame" and target or CFrame.new(target)
    record.model:PivotTo(cframe)
    local root = record.model:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

local function ensureAliveRig(record)
    local humanoid = record.model and record.model:FindFirstChildOfClass("Humanoid")
    if not record.model or not record.model.Parent or not humanoid or humanoid.Health <= 0 then
        if not createRig(record) then
            return false
        end
        humanoid = record.model and record.model:FindFirstChildOfClass("Humanoid")
    end

    if humanoid then
        humanoid.MaxHealth = 100
        humanoid.Health = 100
        humanoid.WalkSpeed = record.profile.WalkSpeed
    end
    record.alive = true
    return true
end

local function sendToLobby(record)
    if not ensureAliveRig(record) then
        return
    end

    record.inRound = false
    record.target = nil
    record.targetPart = nil
    record.targetIsPad = false
    record.moveDirection = Vector3.zero
    record.lastMoveTarget = nil
    record.turnPauseUntil = 0
    record.resultAction = nil
    record.resultActionUntil = 0
    record.resultTarget = nil
    pivotRecord(record, getLobbyPosition(record.slot))
end

local function sendToArena(record)
    if not ensureAliveRig(record) then
        return
    end

    record.inRound = true
    record.target = nil
    record.targetPart = nil
    record.targetIsPad = false
    record.moveDirection = Vector3.zero
    record.lastMoveTarget = nil
    record.turnPauseUntil = 0
    record.resultAction = nil
    record.resultActionUntil = 0
    record.resultTarget = nil
    pivotRecord(record, arenaSpawnCFrame(record.slot))
end

local function destroyRecord(record)
    destroyTracks(record)
    if record.model and record.model.Parent then
        record.model:Destroy()
    end
    record.model = nil
    record.proxy.Character = nil
    record.alive = false
end

local function newRecord(slot)
    local identityIndex = identityOrder[slot] or (((slot - 1) % #IDENTITIES) + 1)
    local identity = IDENTITIES[identityIndex]
    local baseProfile = AISurvivorRules.profileForSlot(slot)
    local profile = table.clone(baseProfile)

    -- Persistent per-server variance prevents three recognizable fixed NPC archetypes.
    profile.WalkSpeed = math.clamp(baseProfile.WalkSpeed + (math.random() - 0.5) * 1.1, 14.6, 17.6)
    profile.ReactionSeconds = math.clamp(baseProfile.ReactionSeconds + (math.random() - 0.5) * 0.12, 0.16, 0.58)
    profile.Risk = math.clamp(baseProfile.Risk + (math.random() - 0.5) * 0.12, 0.16, 0.82)
    profile.JumpChance = math.clamp(baseProfile.JumpChance + (math.random() - 0.5) * 0.06, 0.10, 0.32)

    local record = {
        slot = slot,
        identity = identity,
        identityIndex = identityIndex,
        profile = profile,
        model = nil,
        proxy = nil,
        connections = {},
        alive = false,
        inRound = false,
        nextThink = 0,
        nextJump = 0,
        nextPadAt = 0,
        target = nil,
        targetPart = nil,
        targetIsPad = false,
        strafeBias = (math.random() * 2 - 1) * 0.32,
        threat = nil,
        threatSeenAt = nil,
        platformThreat = nil,
        platformThreatSeenAt = nil,
        idleUntil = 0,
        lastProgressPosition = nil,
        lastProgressAt = 0,
        stuckCount = 0,
        nextEmoteAt = os.clock() + 3 + math.random() * 6,
        emoteUntil = 0,
        roundTraits = AISurvivorRules.roundTraits(profile, slot, 1),
        nextHesitationAt = 0,
        nextReconsiderAt = 0,
        gaitScale = 0.94 + math.random() * 0.12,
        moveDirection = Vector3.zero,
        lastMoveTarget = nil,
        turnPauseUntil = 0,
        resultAction = nil,
        resultActionUntil = 0,
        resultTarget = nil,
        lobbyActivity = "roam",
        nextSocialAt = 0,
        nextPracticeAt = 0,
        lastSocialPartnerSlot = nil,
    }

    record.proxy = {
        UserId = -900000 - slot,
        Name = identity.Username,
        DisplayName = identity.DisplayName,
        IsAISurvivor = true,
        Character = nil,
        _AISlot = slot,
    }

    return record
end

local function reconcile()
    if not started then
        return
    end

    local desired = AISurvivorRules.desiredBotCount(humanCount())

    for slot = #records, desired + 1, -1 do
        local record = records[slot]
        if record then
            destroyRecord(record)
        end
        records[slot] = nil
    end

    if currentState.phase == "round" then
        return
    end

    for slot = 1, desired do
        if not records[slot] then
            records[slot] = newRecord(slot)
            if createRig(records[slot]) then
                if currentState.phase == "ready" then
                    sendToArena(records[slot])
                else
                    sendToLobby(records[slot])
                end
            end
        end
    end
end

local function hasDisaster(id)
    for _, current in ipairs(currentState.disasterIds or {}) do
        if current == id then
            return true
        end
    end
    return false
end

local function decisionTraits(record)
    local traits = record.roundTraits or record.profile
    local humanoid = record.model and record.model:FindFirstChildOfClass("Humanoid")
    local pressure = AISurvivorRules.survivalPressure(
        humanoid and humanoid.Health or 100,
        humanoid and humanoid.MaxHealth or 100,
        currentState.finalRush == true,
        currentState.doubleChaos == true
    )

    return AISurvivorRules.pressuredTraits(traits, pressure), pressure
end

local function clampToArena(position)
    local base = arenaBase()
    if not base then
        return position
    end

    local halfX = math.max(6, base.Size.X * 0.5 - 5)
    local halfZ = math.max(6, base.Size.Z * 0.5 - 5)
    local localPosition = base.CFrame:PointToObjectSpace(position)

    local clamped = Vector3.new(
        math.clamp(localPosition.X, -halfX, halfX),
        localPosition.Y,
        math.clamp(localPosition.Z, -halfZ, halfZ)
    )
    return base.CFrame:PointToWorldSpace(clamped)
end

local cachedWarningParts = {}
local cachedWarningsAt = -math.huge

local function warningParts()
    local now = os.clock()
    if now - cachedWarningsAt < 0.15 then
        return cachedWarningParts
    end

    table.clear(cachedWarningParts)
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("BasePart")
            and (
                child.Name == "MeteorWarning"
                or child.Name == "BombWarning"
                or child.Name == "FreezeWarning"
                or child.Name == "JumpShockWarning"
            )
        then
            table.insert(cachedWarningParts, child)
        end
    end
    cachedWarningsAt = now
    return cachedWarningParts
end

local function disappearingPlatformEscape(record, root, now)
    if not hasDisaster("DisappearingPlatforms") then
        record.platformThreat = nil
        record.platformThreatSeenAt = nil
        return nil
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = record.model and {record.model} or {}

    local hit = workspace:Raycast(root.Position, Vector3.new(0, -7, 0), rayParams)
    local part = hit and hit.Instance
    local platforms = part and part.Parent
    local isWarning = part
        and part:IsA("BasePart")
        and platforms
        and platforms.Name == "Platforms"
        and part:GetAttribute("CollapsePhase") == "Warning"

    if not isWarning then
        record.platformThreat = nil
        record.platformThreatSeenAt = nil
        return nil
    end

    if record.platformThreat ~= part then
        record.platformThreat = part
        record.platformThreatSeenAt = now
    end

    if not AISurvivorRules.reactionReady(
        record.platformThreatSeenAt,
        now,
        record.profile.ReactionSeconds
    ) then
        return nil
    end

    local base = arenaBase()
    local center = base and base.Position or config.ArenaCenter
    local towardCenter = center - root.Position
    local horizontal = Vector3.new(towardCenter.X, 0, towardCenter.Z)
    if horizontal.Magnitude < 0.5 then
        local angle = record.slot * 2.13 + now
        horizontal = Vector3.new(math.cos(angle), 0, math.sin(angle))
    else
        horizontal = horizontal.Unit
    end

    local tangent = Vector3.new(-horizontal.Z, 0, horizontal.X)
    local dodge = horizontal * (9 + math.random() * 5)
        + tangent * ((math.random() * 2 - 1) * 5)

    return clampToArena(root.Position + dodge)
end

local function immediateThreat(record, root, now)
    local nearest = nil
    local nearestDistance = math.huge
    local velocity = root.AssemblyLinearVelocity
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    local anticipation = 0.18 + (1 - record.profile.Risk) * 0.20
    local predictedPosition = root.Position + horizontalVelocity * anticipation

    for _, warning in ipairs(warningParts()) do
        local currentDistance = (root.Position - warning.Position).Magnitude
        local predictedDistance = (predictedPosition - warning.Position).Magnitude
        local distance = math.min(currentDistance, predictedDistance)
        local warningRadius = math.max(warning.Size.X, warning.Size.Z, warning.Size.Y) * 0.5
        local threshold = warning.Name == "FreezeWarning" or warning.Name == "JumpShockWarning"
            and 80
            or (warningRadius + 9)

        if distance <= threshold and distance < nearestDistance then
            nearest = warning
            nearestDistance = distance
        end
    end

    if nearest ~= record.threat then
        record.threat = nearest
        record.threatSeenAt = nearest and now or nil
    end

    if not nearest
        or not AISurvivorRules.reactionReady(
            record.threatSeenAt,
            now,
            record.profile.ReactionSeconds
        )
    then
        return nil
    end

    if nearest.Name == "FreezeWarning" then
        if math.random() < 0.55 then
            local humanoid = record.model and record.model:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Jump = true
            end
        end
        return nil
    end

    if nearest.Name == "JumpShockWarning" then
        local humanoid = record.model and record.model:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Jump = true
        end
        return nil
    end

    local escapeOrigin = predictedPosition
    local away = escapeOrigin - nearest.Position
    local horizontal = Vector3.new(away.X, 0, away.Z)
    if horizontal.Magnitude < 0.1 then
        horizontal = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
    end
    horizontal = horizontal.Unit

    local tangent = Vector3.new(-horizontal.Z, 0, horizontal.X)
    local wobble = (math.random() - 0.5) * (8 + record.profile.Risk * 8)
    local momentumCorrection = Vector3.new(-horizontalVelocity.X, 0, -horizontalVelocity.Z)
    if momentumCorrection.Magnitude > 8 then
        momentumCorrection = momentumCorrection.Unit * math.min(7, momentumCorrection.Magnitude * 0.22)
    end

    return clampToArena(
        root.Position
            + horizontal * (16 + (1 - record.profile.Risk) * 10)
            + tangent * wobble
            + momentumCorrection
    )
end

local function mechanicsPads()
    local _, arena = arenaParts()
    local mechanics = arena and arena:FindFirstChild("Mechanics")
    local result = {}
    if mechanics then
        for _, child in ipairs(mechanics:GetChildren()) do
            if child:IsA("BasePart") and child:GetAttribute("ArenaMobilityPad") == true then
                table.insert(result, child)
            end
        end
    end
    return result
end

local function arenaCandidates(root)
    local _, arena = arenaParts()
    local result = {}
    if not arena then
        return result
    end

    local spawns = arena:FindFirstChild("Spawns")
    for _, part in ipairs(sortedParts(spawns)) do
        table.insert(result, {part = part, position = part.Position + Vector3.new(0, 2.5, 0)})
    end

    local platforms = arena:FindFirstChild("Platforms")
    local variantId = arenaVariantId()
    for _, part in ipairs(sortedParts(platforms)) do
        local position = part.Position + Vector3.new(0, part.Size.Y * 0.5 + 2.4, 0)
        if AISurvivorRules.platformAvailable(
            part.CanCollide,
            part.Transparency,
            part:GetAttribute("CollapsePhase")
        ) and AISurvivorRules.reachableElevation(
            root and root.Position.Y or position.Y,
            position.Y,
            variantId
        ) then
            table.insert(result, {
                part = part,
                position = position,
            })
        end
    end

    local base = arena:FindFirstChild("Base")
    if base and base:IsA("BasePart") then
        local halfX = math.max(5, base.Size.X * 0.5 - 7)
        local halfZ = math.max(5, base.Size.Z * 0.5 - 7)
        for _ = 1, 4 do
            local localOffset = Vector3.new(
                (math.random() * 2 - 1) * halfX,
                base.Size.Y * 0.5 + 2.6,
                (math.random() * 2 - 1) * halfZ
            )
            table.insert(result, {
                part = base,
                position = base.CFrame:PointToWorldSpace(localOffset),
            })
        end
    end

    return result
end

local function scoreCandidate(record, root, candidate, traits)
    local position = candidate.position
    local center = config.ArenaCenter
    local risk = traits.Risk or record.profile.Risk
    local distanceFromCenter = (Vector3.new(position.X, 0, position.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude
    local travelDistance = (position - root.Position).Magnitude
    local variantId = arenaVariantId()
    local score = (math.random() * 8) - (travelDistance * 0.035)
    score += AISurvivorRules.routeAffinity(variantId, position, center)
    score += AISurvivorRules.routeContinuity(
        variantId,
        root.Position,
        position,
        center,
        (record.roundTraits and record.roundTraits.DirectionBias) or record.strafeBias
    )

    if hasDisaster("RisingLava") then
        score += position.Y * (1.45 - risk * 0.45)
    end

    if hasDisaster("Tornado") then
        score += math.min(distanceFromCenter, 44) * (0.72 - risk * 0.16)
    end

    if hasDisaster("ShrinkingArena") then
        score -= distanceFromCenter * (0.86 - risk * 0.24)
    end

    for _, warning in ipairs(warningParts()) do
        if warning.Name == "MeteorWarning" or warning.Name == "BombWarning" then
            local warningDistance = (position - warning.Position).Magnitude
            local radius = math.max(warning.Size.X, warning.Size.Z) * 0.5 + 7
            if warningDistance < radius then
                score -= 90 * (1 - risk * 0.40)
            end
        end
    end

    if candidate.part
        and candidate.part.Parent
        and candidate.part.Parent.Name == "Platforms"
        and not AISurvivorRules.platformAvailable(
            candidate.part.CanCollide,
            candidate.part.Transparency,
            candidate.part:GetAttribute("CollapsePhase")
        )
    then
        score -= 120
    end

    return score
end

local function socialArenaTarget(record, root, traits)
    if math.random() >= (traits.SocialChance or record.profile.SocialChance or 0) then
        return nil
    end

    local eligible = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local humanRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local humanHumanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local roundEligible = not record.inRound
            or (
                player:GetAttribute("RoundParticipant") == true
                and player:GetAttribute("RoundEliminated") ~= true
            )

        if roundEligible
            and humanRoot
            and humanRoot:IsA("BasePart")
            and humanHumanoid
            and humanHumanoid.Health > 0
            and AISurvivorRules.reachableElevation(
                root.Position.Y,
                humanRoot.Position.Y,
                arenaVariantId()
            )
        then
            table.insert(eligible, {
                player = player,
                root = humanRoot,
            })
        end
    end

    if #eligible == 0 then
        return nil
    end

    local selected = eligible[math.random(1, #eligible)]
    local humanRoot = selected.root
    local humanVelocity = humanRoot.AssemblyLinearVelocity
    local lead = Vector3.new(humanVelocity.X, 0, humanVelocity.Z)
    if lead.Magnitude > 5 then
        lead = lead.Unit * math.min(5, lead.Magnitude * 0.22)
    else
        lead = Vector3.zero
    end

    local offset = root.Position - (humanRoot.Position + lead)
    local horizontal = Vector3.new(offset.X, 0, offset.Z)
    if horizontal.Magnitude < 0.5 then
        local angle = math.random() * math.pi * 2
        horizontal = Vector3.new(math.cos(angle), 0, math.sin(angle))
    else
        horizontal = horizontal.Unit
    end

    return clampToArena(humanRoot.Position + lead + horizontal * (5 + math.random() * 5))
end

local function separateTarget(record, target)
    local adjusted = target
    local push = Vector3.zero

    for _, other in ipairs(records) do
        if other ~= record and other.model and other.model.Parent then
            local otherRoot = other.model:FindFirstChild("HumanoidRootPart")
            if otherRoot and otherRoot:IsA("BasePart") then
                local delta = adjusted - otherRoot.Position
                local horizontal = Vector3.new(delta.X, 0, delta.Z)
                local distance = horizontal.Magnitude
                if distance < 6.5 then
                    local away
                    if distance > 0.2 then
                        away = horizontal.Unit
                    else
                        local angle = (record.slot * 2.17 + other.slot * 1.31)
                        away = Vector3.new(math.cos(angle), 0, math.sin(angle))
                    end
                    push += away * (6.5 - distance) * 0.62
                end
            end

            if other.target then
                local targetDelta = adjusted - other.target
                local targetHorizontal = Vector3.new(targetDelta.X, 0, targetDelta.Z)
                if targetHorizontal.Magnitude < 5 then
                    local angle = record.slot * 1.91 + other.slot * 0.77
                    push += Vector3.new(math.cos(angle), 0, math.sin(angle)) * 3.5
                end
            end
        end
    end

    if push.Magnitude > 0.1 then
        adjusted = clampToArena(adjusted + Vector3.new(push.X, 0, push.Z))
    end
    return adjusted
end

local function chooseMobilityPad(record, root, pads, traits)
    local variantId = arenaVariantId()
    local center = config.ArenaCenter
    local ranked = {}

    for _, pad in ipairs(pads) do
        local distance = (pad.Position - root.Position).Magnitude
        local score = (math.random() * 2.5) - distance * 0.07

        if variantId == "Towers" then
            local lowOnMap = root.Position.Y < center.Y + 10
            if lowOnMap then
                score += 5.5
            end
            if hasDisaster("RisingLava") then
                score += 7.0
            end
        elseif variantId == "Orbital" then
            local offset = Vector3.new(
                root.Position.X - center.X,
                0,
                root.Position.Z - center.Z
            )
            if offset.Magnitude >= 18 then
                score += 4.0
            end
        elseif variantId == "Crossroads" then
            score += 2.0
        elseif hasDisaster("Tornado") then
            score += 2.5
        end

        table.insert(ranked, {pad = pad, score = score})
    end

    table.sort(ranked, function(a, b)
        return a.score > b.score
    end)

    local choiceRange = AISurvivorRules.padChoiceWidth(
        traits.Risk or record.profile.Risk,
        #ranked
    )
    return ranked[math.random(1, choiceRange)].pad
end

local function chooseArenaTarget(record, root, now)
    local traits = decisionTraits(record)
    local socialTarget = socialArenaTarget(record, root, traits)
    if socialTarget then
        record.targetIsPad = false
        record.targetPart = nil
        return separateTarget(record, socialTarget), 0.65 + math.random() * 1.0
    end

    local pads = mechanicsPads()
    local variantId = arenaVariantId()
    local lowOnMap = root.Position.Y < config.ArenaCenter.Y + 10
    local padChance = AISurvivorRules.padInterest(
        traits.PadChance or record.profile.PadChance,
        variantId,
        lowOnMap,
        hasDisaster("RisingLava")
    )
    local wantsPad = #pads > 0
        and now >= record.nextPadAt
        and math.random() < padChance

    if wantsPad then
        local pad = chooseMobilityPad(record, root, pads, traits)
        record.targetIsPad = true
        record.targetPart = pad
        return pad.Position + Vector3.new(0, 1.8, 0), 1.6
    end

    record.targetIsPad = false
    record.targetPart = nil

    local candidates = arenaCandidates(root)
    if #candidates == 0 then
        return clampToArena(config.ArenaCenter + Vector3.new(math.random(-18, 18), 3, math.random(-18, 18))), 1.5
    end

    local ranked = {}
    for _, candidate in ipairs(candidates) do
        table.insert(ranked, {
            candidate = candidate,
            score = scoreCandidate(record, root, candidate, traits),
        })
    end
    table.sort(ranked, function(a, b)
        return a.score > b.score
    end)

    local effectiveRisk = traits.Risk or record.profile.Risk
    local choiceRange = AISurvivorRules.routeChoiceWidth(effectiveRisk, #ranked)

    -- Real players do not always choose the mathematically best route.
    if #ranked > choiceRange and math.random() < (traits.MistakeChance or record.profile.MistakeChance or 0) then
        choiceRange = math.min(#ranked, choiceRange + 2)
    end
    local selected = ranked[math.random(1, choiceRange)].candidate
    local target = separateTarget(record, selected.position)

    if selected.part
        and selected.part.Parent
        and selected.part.Parent.Name == "Platforms"
    then
        record.targetPart = selected.part
    end

    local hold = record.profile.TargetHoldMin
        + math.random() * (record.profile.TargetHoldMax - record.profile.TargetHoldMin)
    return target, hold
end

local function lobbySocialTargets(record)
    local targets = {}

    for _, player in ipairs(Players:GetPlayers()) do
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
            table.insert(targets, {
                root = root,
                partnerSlot = 1000 + math.max(1, player.UserId % 97),
            })
        end
    end

    for _, other in ipairs(records) do
        if other ~= record and other.model and other.model.Parent then
            local root = other.model:FindFirstChild("HumanoidRootPart")
            local humanoid = other.model:FindFirstChildOfClass("Humanoid")
            if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
                table.insert(targets, {
                    root = root,
                    partnerSlot = other.slot,
                })
            end
        end
    end

    return targets
end

local function chooseLobbyTarget(record)
    local center = config.LobbyCenter
    local now = os.clock()

    if voteActive then
        record.lobbyActivity = "vote"
        local offset = AISurvivorRules.voteGatherOffset(record.slot, voteRoundNumber)
        return center + offset + Vector3.new(0, 2.7, 0), 1.0 + math.random() * 0.8, nil
    end

    local traits = record.roundTraits or record.profile
    local socialChance = now >= (record.nextSocialAt or 0)
        and math.clamp((traits.SocialChance or record.profile.SocialChance or 0.2) * 0.78, 0.08, 0.32)
        or 0
    local practiceChance = now >= (record.nextPracticeAt or 0)
        and math.clamp(0.14 + (traits.Risk or record.profile.Risk or 0.5) * 0.12, 0.14, 0.25)
        or 0

    local activity = AISurvivorRules.lobbyActivity(
        math.random(),
        socialChance,
        practiceChance,
        false
    )

    if activity == "social" then
        local targets = lobbySocialTargets(record)
        if #targets > 0 then
            local pool = {}
            for _, candidate in ipairs(targets) do
                if candidate.partnerSlot ~= record.lastSocialPartnerSlot then
                    table.insert(pool, candidate)
                end
            end
            if #pool == 0 then
                pool = targets
            end

            local selected = pool[math.random(1, #pool)]
            record.lastSocialPartnerSlot = selected.partnerSlot
            record.lobbyActivity = "social"
            record.nextSocialAt = now + 5 + math.random() * 7
            local offset = AISurvivorRules.socialSpacing(
                record.slot,
                selected.partnerSlot
            )
            return selected.root.Position + offset, 1.5 + math.random() * 1.8, nil
        end
    elseif activity == "practice" then
        local generated = workspace:FindFirstChild("GeneratedMap")
        local lobby = generated and generated:FindFirstChild("Lobby")
        local activities = lobby and lobby:FindFirstChild("Activities")
        local pads = sortedParts(activities)
        if #pads > 0 then
            local pad = pads[math.random(1, #pads)]
            record.lobbyActivity = "practice"
            record.nextPracticeAt = now + 6 + math.random() * 9
            return pad.Position + Vector3.new(0, 1.7, 0), 1.5 + math.random() * 1.0, pad
        end
    end

    record.lobbyActivity = "roam"
    local angle = math.random() * math.pi * 2
    local radius = 8 + math.random() * 20
    local position = center + Vector3.new(
        math.cos(angle) * radius,
        2.7,
        math.sin(angle) * radius
    )
    return position, 1.8 + math.random() * 2.8, nil
end

local function tryPadImpulse(record, root, now)
    if not record.targetIsPad
        or not record.targetPart
        or not record.targetPart.Parent
        or now < record.nextPadAt
    then
        return
    end

    if (root.Position - record.targetPart.Position).Magnitude > 5.3 then
        return
    end

    local impulse = Vector3.new(
        tonumber(record.targetPart:GetAttribute("ImpulseX")) or 0,
        tonumber(record.targetPart:GetAttribute("ImpulseY")) or 0,
        tonumber(record.targetPart:GetAttribute("ImpulseZ")) or 0
    )

    if impulse.Magnitude <= 0.1 then
        return
    end

    local overdrive = currentState.overdrive == true
    root.AssemblyLinearVelocity = ArenaMechanics.safeVelocity(
        root.AssemblyLinearVelocity,
        ArenaMechanics.impulseFor(impulse, overdrive)
    )

    record.nextPadAt = now + ArenaMechanics.cooldownFor(currentState.finalRush == true)
    record.target = nil
    record.targetPart = nil
    record.targetIsPad = false
end

local function tryLobbyPracticeImpulse(record, root, now)
    local pad = record.targetPart
    if not pad
        or not pad.Parent
        or pad:GetAttribute("LobbyPracticePad") ~= true
        or now < record.nextPadAt
        or (root.Position - pad.Position).Magnitude > 5.4
    then
        return
    end

    local index = tonumber(string.match(pad.Name, "(%d+)$"))
    local definition = index and LobbyActivities.Definitions[index] or nil
    if not definition then
        return
    end

    root.AssemblyLinearVelocity = LobbyActivities.safeVelocity(
        root.AssemblyLinearVelocity,
        definition.impulse
    )
    record.nextPadAt = now + 1.0
    record.nextPracticeAt = math.max(record.nextPracticeAt or 0, now + 7.0)
    record.target = nil
    record.targetPart = nil
end

local function recoverIfStuck(record, humanoid, root, now)
    if not record.target then
        record.lastProgressPosition = root.Position
        record.lastProgressAt = now
        record.stuckCount = 0
        return false
    end

    if not record.lastProgressPosition then
        record.lastProgressPosition = root.Position
        record.lastProgressAt = now
        return false
    end

    if now - (record.lastProgressAt or 0) < 1.15 then
        return false
    end

    local moved = (root.Position - record.lastProgressPosition).Magnitude
    record.lastProgressPosition = root.Position
    record.lastProgressAt = now

    if moved >= 1.15 then
        record.stuckCount = 0
        return false
    end

    record.stuckCount = (record.stuckCount or 0) + 1
    humanoid.Jump = true
    record.target = nil
    record.targetPart = nil
    record.targetIsPad = false
    record.nextThink = 0

    if record.stuckCount >= 2 then
        local side = root.CFrame.RightVector * ((math.random() < 0.5) and -6 or 6)
        local recoveryTarget = root.Position + side
        humanoid:MoveTo(
            record.inRound and clampToArena(recoveryTarget) or recoveryTarget
        )
        record.stuckCount = 0
    end

    return true
end

local function moveHumanLike(record, humanoid, root, target, now, urgent, arenaBounded)
    if not target then
        humanoid:Move(Vector3.zero)
        record.moveDirection = Vector3.zero
        return
    end

    local delta = target - root.Position
    local horizontal = Vector3.new(delta.X, 0, delta.Z)
    if horizontal.Magnitude <= 0.05 then
        humanoid:MoveTo(target)
        record.moveDirection = Vector3.zero
        return
    end

    local direct = urgent == true
        or (record.targetIsPad == true and horizontal.Magnitude < 10)

    local previousTarget = record.lastMoveTarget
    local changedTarget = not previousTarget
        or (Vector3.new(
            target.X - previousTarget.X,
            0,
            target.Z - previousTarget.Z
        ).Magnitude > 5)

    if changedTarget then
        local _, pressure = decisionTraits(record)
        local pause = AISurvivorRules.turnPauseSeconds(
            record.moveDirection,
            horizontal,
            direct,
            pressure
        )
        record.lastMoveTarget = target
        if pause > 0 then
            record.turnPauseUntil = now + pause
            humanoid:Move(Vector3.zero)
            return
        end
    else
        record.lastMoveTarget = target
    end

    if now < (record.turnPauseUntil or 0) then
        humanoid:Move(Vector3.zero)
        return
    end

    local steered = AISurvivorRules.steeredDirection(
        record.moveDirection,
        horizontal,
        direct
    )
    if steered.Magnitude <= 0.001 then
        humanoid:MoveTo(target)
        return
    end

    record.moveDirection = steered
    local stepDistance = math.min(horizontal.Magnitude, direct and 14 or 10)
    local destination = root.Position + steered * stepDistance
    destination = Vector3.new(
        destination.X,
        horizontal.Magnitude < 10 and target.Y or root.Position.Y,
        destination.Z
    )
    humanoid:MoveTo(
        arenaBounded == false and destination or clampToArena(destination)
    )
end

local function maybeSocialGesture(record, humanoid, root, now)
    if now < (record.nextEmoteAt or 0)
        or currentState.phase == "round"
        or voteActive
    then
        return false
    end

    record.nextEmoteAt = now + 5 + math.random() * 9
    if math.random() > 0.46 then
        return false
    end

    local nearest = nil
    local nearestDistance = 22
    for _, candidate in ipairs(lobbySocialTargets(record)) do
        local candidateRoot = candidate.root
        local distance = (candidateRoot.Position - root.Position).Magnitude
        if distance < nearestDistance then
            nearest = candidateRoot
            nearestDistance = distance
        end
    end

    if not nearest then
        return false
    end

    -- A short stop + softer turn reads like acknowledgement without chat spam.
    humanoid:Move(Vector3.zero)
    local look = Vector3.new(nearest.Position.X, root.Position.Y, nearest.Position.Z)
    if (look - root.Position).Magnitude > 0.2 then
        root.CFrame = root.CFrame:Lerp(CFrame.lookAt(root.Position, look), 0.55)
    end
    record.idleUntil = now + 0.35 + math.random() * 0.55
    record.target = nil
    record.targetPart = nil
    record.lobbyActivity = "social"

    if math.random() < 0.28 then
        humanoid.Jump = true
    end
    return true
end

local function stepRecord(record, now)
    local model = record.model
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    local root = model and model:FindFirstChild("HumanoidRootPart")
    if not model or not model.Parent or not humanoid or humanoid.Health <= 0 or not root then
        return
    end

    if voteActive and not record.inRound then
        local gatherTarget = config.LobbyCenter
            + AISurvivorRules.voteGatherOffset(record.slot, voteRoundNumber)
            + Vector3.new(0, 2.7, 0)
        local flatDistance = Vector3.new(
            root.Position.X - gatherTarget.X,
            0,
            root.Position.Z - gatherTarget.Z
        ).Magnitude

        if flatDistance <= 3.8 then
            record.target = gatherTarget
            record.targetPart = nil
            record.targetIsPad = false
            record.lastProgressPosition = root.Position
            record.lastProgressAt = now
            humanoid:Move(Vector3.zero)

            local look = Vector3.new(
                config.LobbyCenter.X,
                root.Position.Y,
                config.LobbyCenter.Z
            )
            if (look - root.Position).Magnitude > 0.2 then
                root.CFrame = root.CFrame:Lerp(
                    CFrame.lookAt(root.Position, look),
                    0.30
                )
            end
            return
        end
    end

    if currentState.phase == "result" then
        if now < (record.resultActionUntil or 0) then
            if record.resultAction == "sidestep" and record.resultTarget then
                moveHumanLike(record, humanoid, root, record.resultTarget, now, false, true)
            elseif record.resultAction == "acknowledge" then
                local nearest = nil
                local nearestDistance = 28
                for _, player in ipairs(Players:GetPlayers()) do
                    local humanRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if humanRoot and humanRoot:IsA("BasePart") then
                        local distance = (humanRoot.Position - root.Position).Magnitude
                        if distance < nearestDistance then
                            nearest = humanRoot
                            nearestDistance = distance
                        end
                    end
                end
                if nearest then
                    local look = Vector3.new(nearest.Position.X, root.Position.Y, nearest.Position.Z)
                    if (look - root.Position).Magnitude > 0.2 then
                        root.CFrame = root.CFrame:Lerp(CFrame.lookAt(root.Position, look), 0.38)
                    end
                end
                humanoid:Move(Vector3.zero)
            else
                humanoid:Move(Vector3.zero)
            end
        else
            humanoid:Move(Vector3.zero)
        end
        return
    end

    if recoverIfStuck(record, humanoid, root, now) then
        return
    end

    if maybeSocialGesture(record, humanoid, root, now) then
        return
    end

    if now < (record.idleUntil or 0) then
        humanoid:Move(Vector3.zero)
        return
    end

    if now >= record.nextJump then
        local _, pressure = decisionTraits(record)
        local jumpChance = AISurvivorRules.freeJumpChance(
            record.profile.JumpChance,
            pressure,
            hasDisaster("LowGravity")
        )
        if math.random() < jumpChance then
            humanoid.Jump = true
        end
        record.nextJump = now + 1.8 + math.random() * 3.4
    end

    if record.inRound and (currentState.phase == "ready" or currentState.phase == "round") then
        tryPadImpulse(record, root, now)

        local urgentTarget = nil
        if currentState.phase == "round" then
            urgentTarget = disappearingPlatformEscape(record, root, now)
            if not urgentTarget then
                urgentTarget = immediateThreat(record, root, now)
            end

            if urgentTarget then
                record.targetIsPad = false
                record.targetPart = nil
                record.target = separateTarget(record, urgentTarget)
                record.nextThink = now + 0.55
            end
        end

        if record.targetPart and record.targetPart.Parent then
            if record.targetIsPad then
                record.target = record.targetPart.Position + Vector3.new(0, 1.8, 0)
            elseif record.targetPart.Parent.Name == "Platforms" then
                if not AISurvivorRules.platformAvailable(
                    record.targetPart.CanCollide,
                    record.targetPart.Transparency,
                    record.targetPart:GetAttribute("CollapsePhase")
                ) then
                    record.target = nil
                    record.targetPart = nil
                    record.nextThink = 0
                elseif hasDisaster("ShrinkingArena") then
                    record.target = record.targetPart.Position
                        + Vector3.new(0, record.targetPart.Size.Y * 0.5 + 2.4, 0)
                end
            end
        elseif record.targetPart then
            record.target = nil
            record.targetPart = nil
            record.targetIsPad = false
            record.nextThink = 0
        end

        if currentState.phase == "round"
            and not urgentTarget
            and record.target
            and not record.targetIsPad
            and now >= (record.nextReconsiderAt or 0)
        then
            record.nextReconsiderAt = now + 1.4 + math.random() * 2.4
            local traits = decisionTraits(record)
            if math.random() < (traits.ReconsiderChance or 0) then
                record.target = nil
                record.targetPart = nil
                record.nextThink = 0
            end
        end

        if record.target and (root.Position - record.target).Magnitude < 4.2 then
            record.target = nil
            record.targetPart = nil
            record.targetIsPad = false
            local _, pressure = decisionTraits(record)
            local pauseChance = 0.38 * (1 - pressure * 0.58)
            if math.random() < pauseChance then
                record.idleUntil = now + 0.35 + math.random() * 1.25
                humanoid:Move(Vector3.zero)
                return
            end
        end

        if now >= record.nextThink or not record.target then
            local traits = decisionTraits(record)
            if currentState.phase == "round"
                and not urgentTarget
                and now >= (record.nextHesitationAt or 0)
            then
                record.nextHesitationAt = now + 2.5 + math.random() * 4.5
                if math.random() < (traits.HesitationChance or 0) then
                    record.idleUntil = now + 0.18 + math.random() * 0.38
                    humanoid:Move(Vector3.zero)
                    return
                end
            end

            local target, hold = chooseArenaTarget(record, root, now)
            record.target = target
            record.nextThink = now + hold * (traits.FollowThrough or 1)
        end

        if record.target then
            local delta = record.target - root.Position
            local horizontal = Vector3.new(delta.X, 0, delta.Z)
            if delta.Y > 2.2 and horizontal.Magnitude < 10 then
                humanoid.Jump = true
            end

            local destination = record.target
            if not urgentTarget
                and not record.targetIsPad
                and horizontal.Magnitude > 8
                and math.abs(record.strafeBias or 0) > 0.03
            then
                local direction = horizontal.Unit
                local tangent = Vector3.new(-direction.Z, 0, direction.X)
                local curve = math.min(3.2, horizontal.Magnitude * 0.10) * record.strafeBias
                destination = clampToArena(destination + tangent * curve)
            end

            moveHumanLike(
                record,
                humanoid,
                root,
                destination,
                now,
                urgentTarget ~= nil,
                true
            )
        end
    else
        tryLobbyPracticeImpulse(record, root, now)

        if record.target and (root.Position - record.target).Magnitude < 3.8 then
            record.target = nil
            if math.random() < 0.56 then
                record.idleUntil = now + 0.6 + math.random() * 1.8
                humanoid:Move(Vector3.zero)
                return
            end
        end

        if now >= record.nextThink or not record.target then
            local target, hold, targetPart = chooseLobbyTarget(record)
            record.target = target
            record.targetPart = targetPart
            record.nextThink = now + hold
        end

        moveHumanLike(record, humanoid, root, record.target, now, false, false)
    end
end

local function startBrain()
    if brainStarted then
        return
    end
    brainStarted = true

    task.spawn(function()
        while started do
            local now = os.clock()
            for _, record in ipairs(records) do
                stepRecord(record, now)
            end
            task.wait(0.18)
        end
        brainStarted = false
    end)
end

function AISurvivorService.start(gameConfig)
    if started then
        return
    end

    started = true
    config = gameConfig

    identityOrder = {}
    for index = 1, #IDENTITIES do
        identityOrder[index] = index
    end
    for index = #identityOrder, 2, -1 do
        local swapIndex = math.random(1, index)
        identityOrder[index], identityOrder[swapIndex] = identityOrder[swapIndex], identityOrder[index]
    end

    botsFolder = workspace:FindFirstChild("AISurvivors")
    if botsFolder then
        botsFolder:Destroy()
    end
    botsFolder = Instance.new("Folder")
    botsFolder.Name = "AISurvivors"
    botsFolder:SetAttribute("ServerControlled", true)
    botsFolder.Parent = workspace

    Players.PlayerAdded:Connect(function()
        task.delay(1.0, reconcile)
    end)
    Players.PlayerRemoving:Connect(function()
        task.delay(0.25, reconcile)
    end)

    reconcile()
    startBrain()
end

function AISurvivorService.setRoundState(state)
    currentState = state or currentState
    local phase = tostring(currentState.phase or "waiting")

    if phase ~= previousPhase then
        if phase == "ready" then
            voteActive = false
            roundSerial += 1
            reconcile()
            for _, record in ipairs(records) do
                record.roundTraits = AISurvivorRules.roundTraits(
                    record.profile,
                    record.slot,
                    roundSerial
                )
                record.nextHesitationAt = os.clock() + 0.8 + math.random() * 2.4
                record.nextReconsiderAt = os.clock() + 1.0 + math.random() * 1.8
                record.strafeBias = math.clamp(
                    (record.roundTraits.DirectionBias or 0) * 0.32,
                    -0.32,
                    0.32
                )
                sendToArena(record)
            end
        elseif phase == "result" then
            for _, record in ipairs(records) do
                local humanoid = record.model and record.model:FindFirstChildOfClass("Humanoid")
                local root = record.model and record.model:FindFirstChild("HumanoidRootPart")
                if humanoid and humanoid.Health > 0 then
                    record.target = nil
                    record.targetPart = nil
                    record.targetIsPad = false
                    record.moveDirection = Vector3.zero
                    humanoid:Move(Vector3.zero)

                    local traits = record.roundTraits or record.profile
                    local action = AISurvivorRules.resultReaction(
                        math.random(),
                        traits.Risk or record.profile.Risk
                    )
                    record.resultAction = action
                    record.resultActionUntil = os.clock() + 0.65 + math.random() * 0.55
                    record.resultTarget = nil

                    if action == "jump" then
                        humanoid.Jump = true
                    elseif action == "sidestep" and root and root:IsA("BasePart") then
                        local angle = math.random() * math.pi * 2
                        record.resultTarget = clampToArena(
                            root.Position
                                + Vector3.new(math.cos(angle) * 4.5, 0, math.sin(angle) * 4.5)
                        )
                    end
                end
            end
        elseif phase == "intermission" or phase == "waiting" then
            voteActive = false
            reconcile()
            for _, record in ipairs(records) do
                sendToLobby(record)
            end
        end
    end

    previousPhase = phase
end

function AISurvivorService.beginVote(options, roundNumber)
    voteToken += 1
    local token = voteToken
    table.clear(voteIds)

    if type(options) ~= "table" or #options == 0 then
        voteActive = false
        return
    end

    voteActive = true
    voteRoundNumber = math.max(1, math.floor(tonumber(roundNumber) or roundSerial or 1))

    local now = os.clock()
    for _, record in ipairs(records) do
        record.target = config.LobbyCenter
            + AISurvivorRules.voteGatherOffset(record.slot, voteRoundNumber)
            + Vector3.new(0, 2.7, 0)
        record.targetPart = nil
        record.targetIsPad = false
        record.lobbyActivity = "vote"
        record.nextThink = now + 1.4 + math.random() * 0.9
    end

    for index, record in ipairs(records) do
        local delaySeconds = 0.45 + (index * 0.33) + math.random() * 1.15
        task.delay(delaySeconds, function()
            if token ~= voteToken then
                return
            end

            local optionIndex = AISurvivorRules.voteIndex(record.slot, #options, roundNumber)
            local option = options[optionIndex]
            if option and option.Id then
                voteIds[record.slot] = option.Id
            end
        end)
    end
end

function AISurvivorService.clearVotes()
    voteToken += 1
    voteActive = false
    table.clear(voteIds)

    for _, record in ipairs(records) do
        if record.lobbyActivity == "vote" then
            record.lobbyActivity = "roam"
            record.target = nil
            record.targetPart = nil
            record.nextThink = 0
            record.nextEmoteAt = os.clock() + 1.5 + math.random() * 2.5
        end
    end
end

function AISurvivorService.voteCounts()
    local counts = {}
    for _, disasterId in pairs(voteIds) do
        counts[disasterId] = (counts[disasterId] or 0) + 1
    end
    return counts
end

function AISurvivorService.isBotSubject(subject)
    return type(subject) == "table" and subject.IsAISurvivor == true
end

function AISurvivorService.isSubjectActive(subject)
    if not AISurvivorService.isBotSubject(subject) then
        return false
    end

    local record = records[tonumber(subject._AISlot) or -1]
    if not record or record.proxy ~= subject or not record.inRound then
        return false
    end

    local humanoid = record.model and record.model:FindFirstChildOfClass("Humanoid")
    return humanoid ~= nil and humanoid.Health > 0
end

function AISurvivorService.hazardContestants(humans)
    local result = {}
    for _, player in ipairs(humans or {}) do
        table.insert(result, player)
    end

    for _, record in ipairs(records) do
        if record.inRound and record.proxy.Character and AISurvivorService.isSubjectActive(record.proxy) then
            table.insert(result, record.proxy)
        end
    end

    return result
end

function AISurvivorService.aliveRoundCount()
    local count = 0
    for _, record in ipairs(records) do
        if record.inRound then
            local humanoid = record.model and record.model:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                count += 1
            end
        end
    end
    return count
end

function AISurvivorService.activeCount()
    return #records
end

function AISurvivorService.visibleCount()
    local count = 0
    for _, record in ipairs(records) do
        local humanoid = record.model and record.model:FindFirstChildOfClass("Humanoid")
        if record.model and record.model.Parent and humanoid and humanoid.Health > 0 then
            count += 1
        end
    end
    return count
end

function AISurvivorService.names()
    local result = {}
    for _, record in ipairs(records) do
        table.insert(result, record.identity.DisplayName)
    end
    return result
end

return AISurvivorService
