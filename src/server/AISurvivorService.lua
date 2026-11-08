local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AISurvivorRules = if script
    then require(script.Parent.AISurvivorRules)
    else require("./AISurvivorRules")
local ArenaPresentation = if script
    then require(ReplicatedStorage.Shared.ArenaPresentation)
    else require("../shared/ArenaPresentation")
local ArenaMechanics = if script
    then require(script.Parent.ArenaMechanics)
    else require("./ArenaMechanics")
-- Lest Cloud evaluates repository source against an older published place.
-- The Shared folder in that place does not contain new unmerged modules yet.
local fluxRulesInPlace = ReplicatedStorage:FindFirstChild("Shared")
    and ReplicatedStorage.Shared:FindFirstChild("FluxRelayRules")
local FluxRelayRules = if fluxRulesInPlace
    then require(fluxRulesInPlace)
    else require("../shared/FluxRelayRules")
local AISurvivorNetworkOwnership = if script
    then require(script.Parent.AISurvivorNetworkOwnership)
    else require("./AISurvivorNetworkOwnership")
local SpawnSafety = if script
    then require(script.Parent.SpawnSafety)
    else require("./SpawnSafety")
-- Engine suites may evaluate this source against an earlier published
-- place where the new cooperative relay ModuleScript is not installed.
-- Use the repository source fallback, just like FluxRelayRules.
local relayModuleInPlace = script and script.Parent:FindFirstChild("TeamDashRelay")
local TeamDashRelay = if relayModuleInPlace
    then require(script.Parent.TeamDashRelay)
    else require("./TeamDashRelay")
local skyShieldModuleInPlace = script and script.Parent:FindFirstChild("ArenaSkyShieldNetwork")
local ArenaSkyShieldNetwork = if skyShieldModuleInPlace
    then require(skyShieldModuleInPlace)
    else require("./ArenaSkyShieldNetwork")
local skySwitchModule = script and script.Parent:FindFirstChild("SkySpineSwitchyard")
local SkySpineSwitchyard = if skySwitchModule
    then require(skySwitchModule)
    else require("./SkySpineSwitchyard")
local LobbyActivities = if script
    then require(script.Parent.LobbyActivities)
    else require("./LobbyActivities")
local LobbyReturnFormation = if script
    then require(script.Parent.LobbyReturnFormation)
    else require("./LobbyReturnFormation")
local AnimationCatalog = if script
    then require(ReplicatedStorage.Shared.AnimationCatalog)
    else require("../shared/AnimationCatalog")

local AISurvivorService = {}

-- Server-only diagnostics, not replicated to clients and not used for
-- gameplay decisions. The existing shared brain loop publishes one
-- aggregate every 32 passes, avoiding per-bot Instance/attribute churn.
AISurvivorService.PerformanceDiagnostics = {
    Samples = 0,
    AveragePassMs = 0,
    PeakPassMs = 0,
    AverageBotStepMs = 0,
    PeakBotStepMs = 0,
    BotCount = 0,
    Phase = "waiting",
    -- Monotonic server-only counters: distinguish detected stalls from
    -- actual physical exits, and see whether pathfinding is necessary.
    StallDetections = 0,
    LocalRecoveryFound = 0,
    LocalRecoveryFailed = 0,
    GroundReplansRequested = 0,
    -- Outcomes of REAL engine paths, not inferred from request count.
    GroundRoutesAccepted = 0,
    GroundRoutesCompleted = 0,
    GroundRoutesInvalidated = 0,
    GroundRoutesTimedOut = 0,
    GroundRoutesNoPath = 0,
    GroundRoutesExpired = 0,
    GroundRoutesActive = 0,
    GroundRoutesPending = 0,
    InRoundBots = 0,
}

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

-- Additional authored fictional usernames widen the server-to-server
-- variety without impersonating connected Roblox accounts. Every rig
-- remains a marked AISurvivor proxy, NEVER a Player or chat speaker.
-- Reusing vetted body palettes keeps the extra identities cheap on Android.
local extraNames = {
    {"mika_orbit", "mika"}, {"nova_fern", "fern"},
    {"cloudy_ari", "ari"}, {"zenrover", "zen"},
    {"lune_arcade", "lune"}, {"pax_horizon", "pax"},
    {"nori_pixel", "nori"}, {"melo_drifts", "melo"},
    {"ivyglow24", "ivy"}, {"aster_rush", "aster"},
    {"rio_circuit", "rio"}, {"kai_mistral", "mistral"},
}
local originalIdentityCount = #IDENTITIES
for index, names in ipairs(extraNames) do
    local base = table.clone(IDENTITIES[((index - 1) % originalIdentityCount) + 1])
    base.Username = names[1]
    base.DisplayName = names[2]
    table.insert(IDENTITIES, base)
end

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
local nextReadyRepairAt = 0

local function humanCount()
    return #Players:GetPlayers()
end

local function getLobbyPosition(record)
    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    local spawn = lobby and lobby:FindFirstChild("LobbySpawn")
    local floor = lobby and lobby:FindFirstChild("Floor")
    local decor = lobby and lobby:FindFirstChild("Decor")
    local humanoid = record.model and record.model:FindFirstChildOfClass("Humanoid")
    local root = record.model and record.model:FindFirstChild("HumanoidRootPart")
    local hip = humanoid and humanoid.HipHeight or 2
    local halfRoot = root and root.Size.Y * 0.5 or 1

    local landing = LobbyReturnFormation.botLanding(
        spawn, floor, decor, record.slot, hip, halfRoot
    )
    if landing then return landing end

    -- Fail safely if a custom/incomplete map cannot offer enough distinct
    -- landing slots. Never fall back inside the raised centre-stage slab.
    if spawn and spawn:IsA("SpawnLocation")
        and floor and floor:IsA("BasePart") then
        local top = floor.Position.Y + floor.Size.Y * 0.5
        local clearance = math.max(3.5, hip + halfRoot + 1)
        return CFrame.new(spawn.Position.X, top + clearance, spawn.Position.Z)
            * spawn.CFrame.Rotation
    end
    return CFrame.new(config.LobbyCenter + Vector3.new(0, 5, -27))
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

-- Humans use SpawnSafety.resolve; AI must obey the same physical
-- clearance rules. A raw marker + 4 studs can put an NPC inside an
-- overhead deck or on top of another contestant.
local function arenaSpawnCFrame(slot, humanoid, root)
    local _, arena = arenaParts()
    local spawns = arena and arena:FindFirstChild("Spawns")
    local list = sortedParts(spawns)
    if #list == 0 then
        return nil
    end

    -- Preserve the bot's preferred slot, but try the remaining markers
    -- before skipping an unsafe entry. resolve() also checks nearby rigs
    -- and has bounded floor-level offsets for obstructed markers.
    local humanSlots = math.max(1, humanCount())
    local startIndex = ((slot + humanSlots - 1) % #list) + 1
    for offset = 0, #list - 1 do
        local marker = list[((startIndex + offset - 1) % #list) + 1]
        local resolved = SpawnSafety.resolve(arena, marker, humanoid, root)
        if resolved then
            return resolved
        end
    end
    return nil
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
    animation.AnimationId = AnimationCatalog.assetId(animationId)

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
        idle = loadTrack(animator, AnimationCatalog.AISurvivor.Idle, Enum.AnimationPriority.Idle, true),
        walk = loadTrack(animator, AnimationCatalog.AISurvivor.Walk, Enum.AnimationPriority.Movement, true),
        run = loadTrack(animator, AnimationCatalog.AISurvivor.Run, Enum.AnimationPriority.Movement, true),
        jump = loadTrack(animator, AnimationCatalog.AISurvivor.Jump, Enum.AnimationPriority.Action, false),
        fall = loadTrack(animator, AnimationCatalog.AISurvivor.Fall, Enum.AnimationPriority.Movement, true),
    }
    record.tracks = tracks

    local airborne = false
    local locomotionKind = nil

    local function stopTrack(name, fade)
        local track = tracks[name]
        if track and track.IsPlaying then
            track:Stop(fade or 0.10)
        end
    end

    local function playLocomotion(speed)
        local kind, playbackSpeed = AISurvivorRules.locomotionAnimation(
            speed,
            airborne,
            record.gaitScale
        )

        if kind ~= locomotionKind then
            local previousKind = locomotionKind
            local fade = AISurvivorRules.locomotionTransition(previousKind, kind)

            for _, name in ipairs({"idle", "walk", "run", "fall"}) do
                if name ~= kind then
                    stopTrack(name, fade)
                end
            end

            local track = tracks[kind]
            if track and not track.IsPlaying then
                track:Play(fade)
            end
            locomotionKind = kind
        end

        local track = tracks[kind]
        if track then
            track:AdjustSpeed(
                AISurvivorRules.animationPlaybackScale(
                    kind,
                    playbackSpeed,
                    record.gaitScale
                )
            )
        end
    end

    playLocomotion(0)

    table.insert(record.connections, humanoid.Running:Connect(function(speed)
        if not airborne then
            playLocomotion(speed)
        end
    end))

    table.insert(record.connections, humanoid.StateChanged:Connect(function(_, state)
        if state == Enum.HumanoidStateType.Jumping then
            airborne = true
            locomotionKind = nil
            stopTrack("walk", 0.06)
            stopTrack("run", 0.06)
            stopTrack("idle", 0.06)
            stopTrack("fall", 0.04)
            if tracks.jump then
                tracks.jump:AdjustSpeed(
                    AISurvivorRules.animationPlaybackScale(
                        "jump",
                        1,
                        record.gaitScale
                    )
                )
                tracks.jump:Play(0.04)
            end
        elseif state == Enum.HumanoidStateType.Freefall then
            airborne = true
            stopTrack("jump", 0.07)
            locomotionKind = nil
            playLocomotion(0)
        elseif state == Enum.HumanoidStateType.Landed
            or state == Enum.HumanoidStateType.Running
            or state == Enum.HumanoidStateType.RunningNoPhysics
        then
            airborne = false
            stopTrack("jump", 0.06)
            stopTrack("fall", 0.08)
            locomotionKind = nil
            playLocomotion(
                humanoid.MoveDirection.Magnitude * humanoid.WalkSpeed
            )
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
    elseif style == 6 then
        -- Low-profile knit beanie: a dark textured silhouette rather than
        -- another glowing cyber helmet. Two pieces, no render-time work.
        local capColor = record.identity.Legs:Lerp(accent, 0.19)
        local beanie = cosmeticPart(
            model, "PlayerKnitBeanie",
            Vector3.new(0.55, 1.88, 1.72), capColor
        )
        beanie.Shape = Enum.PartType.Cylinder
        beanie.CFrame = head.CFrame
            * CFrame.new(0, 0.69, 0)
            * CFrame.Angles(0, 0, math.rad(90))
        weldTo(beanie, head)

        local cuff = cosmeticPart(
            model, "BeanieFold",
            Vector3.new(1.93, 0.16, 1.77),
            capColor:Lerp(Color3.new(1, 1, 1), 0.10)
        )
        cuff.CFrame = head.CFrame * CFrame.new(0, 0.49, 0)
        weldTo(cuff, head)
    elseif style == 7 and torso and torso:IsA("BasePart") then
        -- Short utilitarian jacket front panels: slight asymmetry and
        -- subdued fabric colors, with no hard-edged aura or light source.
        local jacketColor = record.identity.Torso:Lerp(
            record.identity.Legs, 0.36
        )
        for side = -1, 1, 2 do
            local panel = cosmeticPart(
                model,
                side < 0 and "JacketPanelL" or "JacketPanelR",
                Vector3.new(0.68, 1.26, 0.14),
                jacketColor:Lerp(accent, side < 0 and 0.10 or 0.04)
            )
            panel.CFrame = torso.CFrame * CFrame.new(
                side * 0.43, -0.18, -0.57
            )
            weldTo(panel, torso)
        end
    elseif style == 8 then
        -- Wrist wraps are common player cosmetics and are legible from
        -- behind without excessive neon. Missing streamed limbs fail safe.
        for _, spec in ipairs({
            {"LeftLowerArm", "PlayerWrapLeft"},
            {"RightLowerArm", "PlayerWrapRight"},
        }) do
            local arm = model:FindFirstChild(spec[1])
            if arm and arm:IsA("BasePart") then
                local wrap = cosmeticPart(
                    model, spec[2],
                    Vector3.new(0.64, 0.21, 0.66),
                    record.identity.Legs:Lerp(accent, 0.40)
                )
                wrap.CFrame = arm.CFrame * CFrame.new(0, -0.32, 0)
                weldTo(wrap, arm)
            end
        end
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
    -- An always-on neon streak behind most NPCs immediately exposes
    -- bots on Android. Only the backpack runner variant carries a subtle
    -- optional cosmetic trail, closer to a real user-equipped skin.
    if style ~= 3 then
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
    trail.Lifetime = 0.095
    trail.MinLength = 0.05
    trail.FaceCamera = true
    trail.LightEmission = 0.24
    trail.Color = ColorSequence.new(
        record.identity.Accent,
        record.identity.Accent:Lerp(Color3.new(1, 1, 1), 0.34)
    )
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.76),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.20),
        NumberSequenceKeypoint.new(1, 0),
    })
    trail.Parent = root
end

local function addNameplate(record, model)
    local head = model:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SurvivorNameplate"
    billboard.Adornee = head
    billboard.AlwaysOnTop = false
    billboard.MaxDistance = 90
    -- Ordinary Roblox player names are compact; reserve the second row
    -- only for a brief, contextual in-world bot reaction.
    billboard.Size = UDim2.fromOffset(148, 25)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.35, 0)
    billboard.Parent = head

    -- Use Roblox's native Humanoid display name for EXACTLY the same
    -- overhead name rendering used by real avatars. The custom billboard
    -- exists only for a rare non-chat contextual reaction.
    billboard.Enabled = false

    local role = Instance.new("TextLabel")
    role.Name = "Personality"
    role.Position = UDim2.fromOffset(0, 0)
    role.Size = UDim2.new(1, 0, 1, 0)
    role.BackgroundTransparency = 1
    role.Font = Enum.Font.GothamBold
    role.Text = ""
    role.Visible = false
    role.TextColor3 = record.identity.Accent
    role.TextStrokeColor3 = Color3.fromRGB(10, 14, 20)
    role.TextStrokeTransparency = 0.35
    role.TextScaled = true
    role.Parent = billboard

    local roleSize = Instance.new("UITextSizeConstraint")
    roleSize.MinTextSize = 9
    roleSize.MaxTextSize = 12
    roleSize.Parent = role
    record.roleLabel = role
    record.signalExpire = 0
end

-- A short, explicitly AI-labelled nameplate signal adds emotion without
-- spoofing Roblox chat, writing user messages or needing new remotes.
local function showBotSignal(record, message, now)
    local label = record.roleLabel
    if label and label.Parent then
        label.Text = message
        label.Visible = true
        local billboard = label.Parent
        if billboard and billboard:IsA("BillboardGui") then
            billboard.Enabled = true
        end
        record.signalExpire = now + 1.5
    end
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
    model:SetAttribute("AISurvivorInRound", false)
    model:SetAttribute("AISurvivorSlot", record.slot)
    model:SetAttribute("AISurvivorProfile", record.profile.Id)
    model:SetAttribute("AISurvivorPersonality", record.profile.Role)
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

    -- Parenting first is required by Roblox physics ownership APIs.
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
    record.failedTarget = nil
    record.failedTargetUntil = 0
    record.recoveryAttemptCount = 0
    record.lastRecoveryAt = 0
    record.lastProgressTarget = nil
    record.threat = nil
    record.threatSeenAt = nil
    record.reactedWarnings = setmetatable({}, {__mode = "k"})
    record.escapeWarning = nil
    record.escapeTarget = nil
    record.escapeUntil = 0
    record.escapeWarningVersion = nil
    record.escapeKnownWarnings = nil
    -- The rig is constructed before the file-local warning tracker.
    record.routeWarningVersion = -1
    record.lastObservedHealth = 100
    record.lastDamageSignalAt = -math.huge

    addPrimitiveAccessory(record, model)
    addCosmeticTrail(record, root)
    addNameplate(record, model)
    attachAnimations(record, humanoid)

    -- Physics assembly formation can lag one simulation step behind parenting.
    -- Retry a fixed number of times without retaining a replaced/dead rig.
    task.defer(function()
        for attempt = 1, 3 do
            if record.model ~= model or not model:IsDescendantOf(workspace) then
                return
            end
            if AISurvivorNetworkOwnership.claim(model) then
                return
            end
            if attempt < 3 then
                task.wait(0.20 * attempt)
            end
        end
        if record.model == model and model.Parent then
            warn("AI Survivor server network ownership unavailable:", record.identity.Username)
        end
    end)

    table.insert(record.connections, humanoid.HealthChanged:Connect(function(health)
        local previous = record.lastObservedHealth or 100
        record.lastObservedHealth = health
        local now = os.clock()
        if record.model ~= model or not record.inRound
            or currentState.phase ~= "round"
            or previous - health < 8
            or now - (record.lastDamageSignalAt or -math.huge) < 7
        then
            return
        end
        record.lastDamageSignalAt = now
        local signal = record.profile.Id == "Cautious" and "WATCH OUT!"
            or (record.profile.Id == "Bold" and "STILL HERE!" or "OUCH!")
        showBotSignal(record, signal, now)
    end))

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

-- A path belongs to one physical bot rig and one round only. Invalidating its
-- token also prevents an outstanding ComputeAsync from moving a replacement rig.
local function cancelGroundNavigation(record)
    record.groundNavigation = nil
    record.groundNavigationPending = false
    record.groundNavigationStartedAt = nil
    record.groundNavigationFallbackTarget = nil
    record.groundNavigationPendingGoal = nil
    record.groundNavigationToken = (record.groundNavigationToken or 0) + 1
end

local function sendToLobby(record)
    cancelGroundNavigation(record)
    record.nextGroundNavigationAt = 0
    if not ensureAliveRig(record) then
        return
    end

    record.inRound = false
    record.districtTraverse = nil
    record.signalInterestRoute = nil
    record.signalInterestUntil = 0
    record.model:SetAttribute("AISurvivorInRound", false)
    record.target = nil
    record.targetPart = nil
    record.targetIsPad = false
    record.targetIsSkyrail = false
    record.skyrailDirection = nil
    record.lastProgressPosition = nil
    record.lastProgressTarget = nil
    record.lastProgressAt = 0
    record.stuckCount = 0
    record.recoveryAttemptCount = 0
    record.lastRecoveryAt = 0
    record.recoveryWaypoint = nil
    record.recoveryCommitUntil = 0
    record.failedTarget = nil
    record.failedTargetUntil = 0
    record.nextObstaclePreviewAt = 0
    record.moveDirection = Vector3.zero
    record.lastMoveTarget = nil
    record.turnPauseUntil = 0
    record.resultAction = nil
    record.resultActionUntil = 0
    record.resultTarget = nil
    record.socialPartnerUserId = nil
    record.socialPartnerUntil = 0
    TeamDashRelay.releaseBot(record.model)
    ArenaSkyShieldNetwork.releaseBot(record.model)
    SkySpineSwitchyard.releaseBot(record.model)
    record.assistRelay = nil
    record.assistHoldAt = nil
    record.nextAssistAt = 0
    record.assistShield = nil
    record.shieldHoldAt = nil
    record.nextShieldAt = 0
    record.spineControl = nil
    record.spineHoldAt = nil
    record.nextSpineAt = 0
    pivotRecord(record, getLobbyPosition(record))
end

local function sendToArena(record)
    cancelGroundNavigation(record)
    record.nextGroundNavigationAt = 0
    if not ensureAliveRig(record) then
        return
    end

    local humanoid = record.model:FindFirstChildOfClass("Humanoid")
    local root = record.model:FindFirstChild("HumanoidRootPart")
    local spawn = arenaSpawnCFrame(record.slot, humanoid, root)
    if not spawn then
        -- An unsafe bot must never be counted as an active contestant.
        -- Keep its rig in the lobby for the next round instead.
        record.inRound = false
        record.model:SetAttribute("AISurvivorInRound", false)
        pivotRecord(record, getLobbyPosition(record))
        warn("No collision-free AI round spawn for slot", record.slot)
        return
    end

    record.inRound = true
    record.model:SetAttribute("AISurvivorInRound", true)
    record.reactedWarnings = setmetatable({}, {__mode = "k"})
    record.target = nil
    record.targetPart = nil
    record.targetIsPad = false
    record.targetIsSkyrail = false
    record.skyrailDirection = nil
    record.districtTraverse = nil
    record.nextDistrictTraverseAt = os.clock() + 3
    record.nextRouteJumpAt = 0
    record.nextGapProbeAt = 0
    record.nextDistrictStageCheckAt = 0
    record.signalInterestRoute = nil
    record.signalInterestUntil = 0
    record.nextSignalInterestAt = os.clock() + 2
    record.model:SetAttribute("DistrictSignalWitnessed", 0)
    record.model:SetAttribute("DistrictRouteCompleted", false)
    record.model:SetAttribute("DistrictRouteStep", 0)
    -- A new physical round must not inherit the previous round's
    -- successful team bridge activation diagnostics.
    record.model:SetAttribute("BotSkySpineConnected", false)
    record.model:SetAttribute("BotSkyNetworkConnected", false)
    record.nextSkyrailAt = 0
    record.lastProgressPosition = nil
    record.lastProgressTarget = nil
    record.lastProgressAt = 0
    record.stuckCount = 0
    record.recoveryAttemptCount = 0
    record.lastRecoveryAt = 0
    record.recoveryWaypoint = nil
    record.recoveryCommitUntil = 0
    record.failedTarget = nil
    record.failedTargetUntil = 0
    record.nextObstaclePreviewAt = 0
    record.model:SetAttribute("BotObstaclePreviewCount", 0)
    record.model:SetAttribute("BotObstacleAvoidedCount", 0)
    record.model:SetAttribute("BotStallRecoveryCount", 0)
    record.model:SetAttribute("BotRecoveryRouteFound", nil)
    record.model:SetAttribute("BotGroundRouteNoPathCount", 0)
    record.model:SetAttribute("BotLiveRouteInvalidationCount", 0)
    record.moveDirection = Vector3.zero
    record.lastMoveTarget = nil
    record.turnPauseUntil = 0
    record.resultAction = nil
    record.resultActionUntil = 0
    record.resultTarget = nil
    record.socialPartnerUserId = nil
    record.socialPartnerUntil = 0
    TeamDashRelay.releaseBot(record.model)
    ArenaSkyShieldNetwork.releaseBot(record.model)
    SkySpineSwitchyard.releaseBot(record.model)
    record.assistRelay = nil
    record.assistHoldAt = nil
    record.nextAssistAt = os.clock() + 1.6 + record.slot * 0.25
    record.assistShield = nil
    record.shieldHoldAt = nil
    record.nextShieldAt = os.clock() + 0.75 + record.slot * 0.16
    record.spineControl = nil
    record.spineHoldAt = nil
    record.nextSpineAt = os.clock() + 2 + record.slot * 0.20
    pivotRecord(record, spawn)
end

local function destroyRecord(record)
    cancelGroundNavigation(record)
    TeamDashRelay.releaseBot(record.model)
    ArenaSkyShieldNetwork.releaseBot(record.model)
    SkySpineSwitchyard.releaseBot(record.model)
    destroyTracks(record)
    if record.model and record.model.Parent then
        record.model:Destroy()
    end
    record.model = nil
    record.proxy.Character = nil
    record.alive = false
end

local function newRecord(slot)
    local preferredIndex = identityOrder[slot]
        or (((slot - 1) % #IDENTITIES) + 1)
    local reserved = {}
    for _, existing in pairs(records) do
        if existing.identity then
            table.insert(reserved, existing.identity)
        end
    end
    local identityIndex = AISurvivorRules.availableIdentityIndex(
        IDENTITIES, preferredIndex, Players:GetPlayers(), reserved
    ) or preferredIndex
    local identity = IDENTITIES[identityIndex]
    local baseProfile = AISurvivorRules.profileForSlot(slot)
    local profile = table.clone(baseProfile)

    -- Individual variance preserves identity while keeping each slot's archetype distinct.
    -- All personas stay at or below normal player walking speed.
    profile.WalkSpeed = math.clamp(baseProfile.WalkSpeed + (math.random() - 0.5) * 0.20, 15.6, 16.0)
    profile.ReactionSeconds = math.clamp(baseProfile.ReactionSeconds + (math.random() - 0.5) * 0.035, 0.12, 0.26)
    profile.Risk = math.clamp(baseProfile.Risk + (math.random() - 0.5) * 0.07, 0.12, 0.79)
    profile.JumpChance = math.clamp(baseProfile.JumpChance + (math.random() - 0.5) * 0.04, 0.10, 0.33)

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
        assistRelay = nil,
        assistHoldAt = nil,
        nextAssistAt = 0,
        assistShield = nil,
        shieldHoldAt = nil,
        nextShieldAt = 0,
        spineControl = nil,
        spineHoldAt = nil,
        nextSpineAt = 0,
        nextJump = 0,
        nextPadAt = 0,
        target = nil,
        targetPart = nil,
        targetIsPad = false,
        targetIsSkyrail = false,
        skyrailDirection = nil,
        nextSkyrailAt = 0,
        districtTraverse = nil,
        nextDistrictTraverseAt = 0,
        nextRouteJumpAt = 0,
        nextGapProbeAt = 0,
        nextDistrictStageCheckAt = 0,
        signalInterestRoute = nil,
        signalInterestUntil = 0,
        nextSignalInterestAt = 0,
        strafeBias = (math.random() * 2 - 1) * 0.32,
        threat = nil,
        threatSeenAt = nil,
        platformThreat = nil,
        platformThreatSeenAt = nil,
        idleUntil = 0,
        lastProgressPosition = nil,
        lastProgressAt = 0,
        stuckCount = 0,
        groundNavigation = nil,
        groundNavigationPending = false,
        groundNavigationPendingGoal = nil,
        groundNavigationToken = 0,
        nextGroundNavigationAt = 0,
        recoveryAttemptCount = 0,
        lastRecoveryAt = 0,
        failedTarget = nil,
        failedTargetUntil = 0,
        nextObstaclePreviewAt = 0,
        lastProgressTarget = nil,
        nextEmoteAt = os.clock() + 3 + math.random() * 6,
        emoteUntil = 0,
        nextHazardSignalAt = 0,
        escapeWarning = nil,
        escapeTarget = nil,
        escapeUntil = 0,
        escapeWarningVersion = nil,
        escapeKnownWarnings = nil,
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
        socialPartnerUserId = nil,
        socialPartnerUntil = 0,
        nextRoundGestureAt = os.clock() + 5 + math.random() * 4,
        lastSocialPartnerSlot = nil,
        lobbyRoamCycle = 0,
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

local function reconcile(enteringReady)
    if not started then
        return
    end

    -- Ordinary joins cannot rebalance committed competitors. Reconcile only
    -- once on the actual ready transition so the solo round can recover
    -- missing AI slots before locking the participant roster.
    if not AISurvivorRules.rosterReconciliationAllowed(
        currentState.phase, enteringReady
    ) then
        return
    end

    local humanRosterSize = AISurvivorRules.rosterHumanCount(
        currentState.phase, enteringReady, humanCount(), currentState.readyHumanCount
    )
    local desired = AISurvivorRules.desiredBotCount(humanRosterSize)

    for slot = #records, desired + 1, -1 do
        local record = records[slot]
        if record then
            destroyRecord(record)
        end
        records[slot] = nil
    end

    for slot = 1, desired do
        local record = records[slot]
        if not record then
            record = newRecord(slot)
            records[slot] = record
        end

        local humanoid = record.model and record.model:FindFirstChildOfClass("Humanoid")
        local missingRig = not record.model
            or not record.model.Parent
            or not humanoid
            or humanoid.Health <= 0

        if missingRig and currentState.phase ~= "ready" then
            sendToLobby(record)
        end
        -- At the ready boundary, the caller spawns/teleports each record
        -- exactly once with sendToArena after round traits are assigned.
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

local WARNING_PART_NAMES = {
    MeteorWarning = true,
    BombWarning = true,
    FreezeWarning = true,
    JumpShockWarning = true,
}

local warningPartSet = setmetatable({}, {__mode = "k"})
local cachedWarningParts = {}
local warningCacheDirty = true
-- Each newly spawned/expired real warning invalidates a bot's briefly
-- committed escape path; no extra watcher and no per-tick world scan.
local warningVersion = 0

local function trackWarningPart(child)
    if child:IsA("BasePart") and WARNING_PART_NAMES[child.Name]
        and not warningPartSet[child] then
        warningPartSet[child] = true
        warningCacheDirty = true
        warningVersion += 1
    end
end

local function untrackWarningPart(child)
    if warningPartSet[child] then
        warningPartSet[child] = nil
        warningCacheDirty = true
        warningVersion += 1
    end
end

for _, child in ipairs(workspace:GetChildren()) do
    trackWarningPart(child)
end
workspace.ChildAdded:Connect(trackWarningPart)
workspace.ChildRemoved:Connect(untrackWarningPart)

local function warningParts()
    if not warningCacheDirty then
        return cachedWarningParts
    end

    table.clear(cachedWarningParts)
    for part in pairs(warningPartSet) do
        if part.Parent then
            table.insert(cachedWarningParts, part)
        else
            warningPartSet[part] = nil
        end
    end

    warningCacheDirty = false
    return cachedWarningParts
end

-- Avoid repeating a giant AI-branded phrase every brain tick. Gestures and
-- warnings are visible above bots, never in the actual player chat.
local function warnNearbyContestants(record, now)
    if now < (record.nextHazardSignalAt or 0) then
        return
    end
    record.nextHazardSignalAt = now + 8
    local cue = record.profile.Id == "Cautious" and "DODGE NOW!"
        or (record.profile.Id == "Bold" and "NOT TODAY!" or "WATCH OUT!")
    showBotSignal(record, cue, now)
end

-- Reuse only actual server-created bands from the current arena.
-- No part listeners, replicated client hints or synthetic danger zones.
-- This is sampled only while ranking an imminent impact dodge, not every
-- bot brain tick.
local function activeFloorSweepBands()
    local variant = arenaVariantId()
    local folderName = variant == "Harbor" and "HarborCargoSweep"
        or (variant == "Classic" and "GridSweep" or nil)
    if not folderName then return {} end
    local _, arena = arenaParts()
    local mechanics = arena and arena:FindFirstChild("Mechanics")
    local folder = mechanics and mechanics:FindFirstChild(folderName)
    local phaseName = variant == "Harbor" and "HarborSweepPhase"
        or "GridSweepPhase"
    local bands = {}
    if folder then
        for _, band in ipairs(folder:GetChildren()) do
            if band:IsA("BasePart") then
                local phase = band:GetAttribute(phaseName)
                if phase == "Warning" or phase == "Pulse" then
                    bands[#bands + 1] = band
                end
            end
        end
    end
    return bands
end

-- Sample several WALKABLE escape headings rather than committing to one
-- random tangent. This matters at arena edges, on narrow platforms, and
-- when two growing meteor/bomb warnings overlap. Bounded to six headings,
-- two ground probes per heading, and one re-plan about every half-second.
local function saferThreatEscape(record, root, predictedPosition, warning)
    local away = predictedPosition - warning.Position
    away = Vector3.new(away.X, 0, away.Z)
    if away.Magnitude < 0.2 then
        local angle = record.slot * 2.13 + (roundSerial % 7)
        away = Vector3.new(math.cos(angle), 0, math.sin(angle))
    else
        away = away.Unit
    end
    local tangent = Vector3.new(-away.Z, 0, away.X)
    local headings = {
        away + tangent * 0.30,
        away - tangent * 0.30,
        away * 0.60 + tangent * 0.85,
        away * 0.60 - tangent * 0.85,
        tangent,
        -tangent,
    }

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = botsFolder and {botsFolder}
        or (record.model and {record.model} or {})
    params.RespectCanCollide = true

    -- High sky-deck meteors previously chose a long free-space dodge
    -- using only soft unsupported-floor penalties. Every direction
    -- could still score badly yet win, sending seven bots off the edge.
    -- A single ground ray binds these escapes to the CURRENT safe
    -- oriented landing. Ground-level contestants keep full mobility.
    local base = arenaBase()
    local groundTopY = base and (base.Position.Y + base.Size.Y * 0.5)
        or config.ArenaCenter.Y
    local standingDeck = nil
    if root.Position.Y > groundTopY + 8 then
        local originHit = workspace:Raycast(
            root.Position + Vector3.new(0, 1, 0),
            Vector3.new(0, -7.5, 0),
            params
        )
        local part = originHit and originHit.Instance
        if originHit and originHit.Normal.Y >= 0.78
            and part and part:IsA("BasePart")
            and part.Parent and (part.Parent.Name == "Platforms"
                or part.Parent.Name == "HelixCircuit")
            and AISurvivorRules.platformAvailable(
                part.CanCollide, part.Transparency,
                part:GetAttribute("CollapsePhase"),
                part:GetAttribute("BridgeShutterPhase")
            ) then
            standingDeck = part
        else
            -- An airborne/falling bot cannot invent a supported escape.
            return root.Position
        end
    end

    local length = 17 + (1 - record.profile.Risk) * 7
    local best = nil
    local bestScore = -math.huge
    local bestLandingExposures = math.huge
    local activeWarnings = warningParts()
    local liveSweeps = activeFloorSweepBands()
    for _, heading in ipairs(headings) do
        local destination = clampToArena(
            root.Position + heading.Unit * length
        )
        destination = AISurvivorRules.safeElevatedImpactEscape(
            root.Position, destination, groundTopY,
            standingDeck and standingDeck.CFrame,
            standingDeck and standingDeck.Size
        ) or root.Position
        local shifted = destination - root.Position
        local walked = Vector3.new(shifted.X, 0, shifted.Z).Magnitude
        local warningDistance = Vector3.new(
            destination.X - warning.Position.X, 0,
            destination.Z - warning.Position.Z
        ).Magnitude
        local score = walked * 0.20 + math.min(55, warningDistance) * 0.90

        -- A scored penalty is not a safety constraint: if EVERY route
        -- crosses a void, the "least bad" route would still be selected.
        -- Accept only a physically supported route at both existing
        -- checkpoints, including real solid/available ground and a
        -- walkable surface normal. No additional physics queries.
        local supported = walked >= 1
        for _, fraction in ipairs({0.55, 1.0}) do
            local sample = root.Position:Lerp(destination, fraction)
            local support = workspace:Raycast(
                sample + Vector3.new(0, 4, 0),
                Vector3.new(0, -18, 0),
                params
            )
            local part = support and support.Instance
            local walkable = support and part and part.CanCollide
                and support.Normal.Y >= 0.78
                and (part:IsA("Terrain") or part.Anchored)
                and (not part.Parent or part.Parent.Name ~= "Platforms"
                    or AISurvivorRules.platformAvailable(
                        part.CanCollide, part.Transparency,
                        part:GetAttribute("CollapsePhase"),
                        part:GetAttribute("BridgeShutterPhase")
                    ))
                and (not standingDeck or part == standingDeck)
            if not walkable then
                supported = false
                break
            end
            -- Use the true contact surface; a thick foundation's
            -- center can be far below the level where a bot walks.
            score -= AISurvivorRules.escapeGroundStepPenalty(
                root.Position.Y, support.Position.Y
            )
        end

        -- Count real impact footprints covering the actual destination.
        -- Landing outside every blast is a strict first-class goal:
        -- raw distance/comfort scores must never beat a zero-exposure
        -- route merely because it walks farther from the first warning.
        local landingExposures = 0
        for _, threat in ipairs(activeWarnings) do
            if threat.Name == "MeteorWarning" or threat.Name == "BombWarning" then
                local radius = math.max(5, AISurvivorRules.warningDetectionRadius(
                    threat.Name,
                    math.max(threat.Size.X, threat.Size.Z) * 0.5,
                    threat:GetAttribute("WarningEndSize")
                ) - 9)
                score -= AISurvivorRules.routeWarningPenalty(
                    root.Position, destination, threat.Position, radius
                ) * 1.4
                local clearance = Vector3.new(
                    destination.X - threat.Position.X, 0,
                    destination.Z - threat.Position.Z
                ).Magnitude - radius
                if clearance < 3 then
                    landingExposures += 1
                end
                if clearance < 4 then
                    score -= (4 - clearance) * 4
                end
            end
        end

        -- Two simultaneous hazards must not turn an otherwise sound
        -- meteor escape into a cargo/grid sweep. The server's active band
        -- CFrame and Size are the only authority; the helper checks
        -- the WHOLE walking segment and ignores safe raised platforms.
        for _, band in ipairs(liveSweeps) do
            score -= AISurvivorRules.floorSweepRoutePenalty(
                root.Position, destination, band.CFrame, band.Size
            ) * 1.6
        end

        -- First minimize the number of simultaneous Meteor/Bomb impact
        -- footprints still covering the landing. Among equally exposed
        -- physically supported routes, preserve the existing threat,
        -- sweep and terrain score. If all landings are exposed, still
        -- choose the least dangerous valid escape rather than freezing.
        if supported and (landingExposures < bestLandingExposures
            or (landingExposures == bestLandingExposures
                and score > bestScore)) then
            bestLandingExposures = landingExposures
            bestScore = score
            best = destination
        end
    end
    -- Never walk into unverified air just because every visible option
    -- is poor. Stand on the current support until a real hazard or floor
    -- change permits a safe, physically grounded escape direction.
    return best or root.Position
end

local function disappearingPlatformEscape(record, root, now)
    -- Always drop the previous emergency deck; stale collapse targets
    -- are especially unsafe when the disaster changes platform phase.
    record.collapseEscapeDeck = nil
    record.collapseEscapeHolding = false
    -- Inspect live platform warnings on Towers as well as the dedicated
    -- collapse disaster. Other arenas avoid a new per-bot raycast each tick.
    if not hasDisaster("DisappearingPlatforms")
        and arenaVariantId() ~= "Towers" then
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

    if part:GetAttribute("ChaosSkybridge") == true then
        -- Tower links are narrow elevated spans. Dodging toward the arena
        -- centre crosses open air; run along the bridge to the nearest
        -- supported corner tower instead, without a teleport or speed buff.
        return AISurvivorRules.skybridgeEscapeTarget(
            root.Position, part.CFrame, part.Size, root.AssemblyLinearVelocity
        )
    end

    local base = arenaBase()
    local baseTopY = base and (base.Position.Y + base.Size.Y * 0.5)
        or config.ArenaCenter.Y
    if root.Position.Y > baseTopY + 8 then
        -- The existing centre-directed dodge is safe on the ground, but
        -- sends bots off a 20-stud HIGH perimeter / promenade landing.
        -- Choose only the nearest solid, same-network physical deck.
        -- This scans just the arena's authoritative Platforms folder
        -- during a confirmed warning, after the normal reaction delay.
        local platforms = part.Parent
        local closest, closestCost = nil, math.huge
        for _, deck in ipairs(platforms:GetChildren()) do
            if deck ~= part and deck:IsA("BasePart") then
                local available = AISurvivorRules.platformAvailable(
                    deck.CanCollide, deck.Transparency,
                    deck:GetAttribute("CollapsePhase"),
                    deck:GetAttribute("BridgeShutterPhase")
                )
                if AISurvivorRules.safeCollapseNeighbor(
                    part.CFrame, part.Size,
                    deck.CFrame, deck.Size, available
                ) then
                    local waypoint = deck.Position
                        + deck.CFrame.UpVector * (deck.Size.Y * 0.5 + 2.4)
                    local difference = waypoint - root.Position
                    local flatDistance = Vector3.new(
                        difference.X, 0, difference.Z
                    ).Magnitude
                    -- No world-spanning diagonals across disconnected
                    -- sky sectors even if broad bounding boxes overlap.
                    if flatDistance < 34 and flatDistance < closestCost then
                        closest, closestCost = deck, flatDistance
                    end
                end
            end
        end
        if closest then
            record.collapseEscapeDeck = closest
            return closest.Position
                + closest.CFrame.UpVector * (closest.Size.Y * 0.5 + 2.4)
        end
        -- No physically supported high escape exists. An urgent hold
        -- beats continuing a stale route over void. Preserve threat
        -- priority so a newly visible meteor can still override it.
        record.collapseEscapeHolding = true
        return nil
    end

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

-- A bot that committed to a Skyrail bridge BEFORE its warning should
-- not run straight into a newly raised physical sill. Consult just the
-- current arena's four replicated gates (8 direct children including
-- warning stripes), not the full world. The response follows the same
-- human-readable warning phase with an individual reaction delay.
local function skybridgeShutterEscape(record, root, now)
    if arenaVariantId() ~= "Towers" then
        record.shutterThreat = nil
        record.shutterSeenAt = nil
        return nil
    end
    local _, arena = arenaParts()
    local mechanics = arena and arena:FindFirstChild("Mechanics")
    local folder = mechanics and mechanics:FindFirstChild("SkybridgeShutters")
    local platforms = arena and arena:FindFirstChild("Platforms")
    if not folder or not platforms then
        record.shutterThreat = nil
        record.shutterSeenAt = nil
        return nil
    end
    local threatened, escape = nil, nil
    for _, gate in ipairs(folder:GetChildren()) do
        if gate:IsA("BasePart")
            and gate:GetAttribute("BridgeShutter") == true then
            local phase = gate:GetAttribute("ShutterPhase")
            if phase == "Warning" or phase == "Raising"
                or phase == "Raised" then
                local bridgeName = gate:GetAttribute("BridgeName")
                local bridge = type(bridgeName) == "string"
                    and platforms:FindFirstChild(bridgeName) or nil
                if bridge and bridge:IsA("BasePart")
                    and bridge:GetAttribute("ChaosSkybridge") == true
                    and bridge.CanCollide then
                    local target = AISurvivorRules.skybridgeShutterEscapeTarget(
                        root.Position, bridge.CFrame, bridge.Size, phase
                    )
                    if target then
                        threatened = gate
                        escape = target
                        break
                    end
                end
            end
        end
    end
    if not threatened then
        record.shutterThreat = nil
        record.shutterSeenAt = nil
        return nil
    end
    if record.shutterThreat ~= threatened then
        record.shutterThreat = threatened
        record.shutterSeenAt = now
    end
    if AISurvivorRules.reactionReady(
        record.shutterSeenAt, now, record.profile.ReactionSeconds
    ) then
        return escape
    end
    return nil
end

-- Both Classic's grid pulses and Storm Harbor's crane service sweeps
-- are server-authoritative floor hazards, not workspace disaster markers.
-- Bots see the exact same replicated warning as players, hesitate for
-- their existing personality-dependent reaction time, then physically
-- walk out of the marked lane. NO bot immunity, speed or teleport.
local function floorSweepEscape(record, root, now)
    local variant = arenaVariantId()
    local folderName = variant == "Classic" and "GridSweep"
        or (variant == "Harbor" and "HarborCargoSweep" or nil)
    if not folderName then
        record.gridSweepThreat = nil
        record.gridSweepThreatSeenAt = nil
        return nil
    end
    local _, arena = arenaParts()
    local mechanics = arena and arena:FindFirstChild("Mechanics")
    local folder = mechanics and mechanics:FindFirstChild(folderName)
    local phaseAttribute = variant == "Classic"
        and "GridSweepPhase" or "HarborSweepPhase"
    local threat
    local threatApproachPosition = nil
    if folder then
        for _, band in ipairs(folder:GetChildren()) do
            if band:IsA("BasePart") and (
                band:GetAttribute(phaseAttribute) == "Warning"
                or band:GetAttribute(phaseAttribute) == "Pulse"
            ) then
                -- Anticipate an approaching lane during the warning,
                -- without predicting a dodge from a stationary bot.
                local velocity = root.AssemblyLinearVelocity
                local horizon = band:GetAttribute(phaseAttribute) == "Warning"
                    and 0.32 or 0
                local predicted = root.Position + Vector3.new(
                    velocity.X, 0, velocity.Z) * horizon
                local point = band.CFrame:PointToObjectSpace(root.Position)
                local ahead = band.CFrame:PointToObjectSpace(predicted)
                local function nearLane(p)
                    return math.abs(p.X) <= band.Size.X * 0.5 + 1.2
                        and math.abs(p.Z) <= band.Size.Z * 0.5 + 1.2
                        and p.Y >= 1 and p.Y <= 5.1
                end
                if nearLane(point) or nearLane(ahead) then
                    threat = band
                    -- If the bot has not entered the lane yet, use its
                    -- predicted entry to select the correct escape edge.
                    threatApproachPosition = nearLane(point)
                        and root.Position or predicted
                    break
                end
            end
        end
    end
    if not threat then
        record.gridSweepThreat = nil
        record.gridSweepThreatSeenAt = nil
        return nil
    end
    if record.gridSweepThreat ~= threat then
        record.gridSweepThreat = threat
        record.gridSweepThreatSeenAt = now
    end
    if not AISurvivorRules.reactionReady(
        record.gridSweepThreatSeenAt, now, record.profile.ReactionSeconds
    ) then return nil end

    -- Human runners can use either SIDE or END of the marked corridor.
    -- At a long strip's end the old cross-axis-only rule unnecessarily
    -- made bots traverse the lane. The real server band is oriented, so
    -- derive the nearest physical escape in local space, keeping the
    -- current Y and normal walk speed (no bot-only teleport or jump).
    local base = arenaBase()
    local exit = AISurvivorRules.floorSweepExitTarget(
        threat.CFrame, threat.Size,
        threatApproachPosition or root.Position,
        base and base.Position or config.ArenaCenter
    )
    return exit and clampToArena(exit) or nil
end

local function immediateThreat(record, root, now)
    local nearest = nil
    local nearestDistance = math.huge
    local nearestPriority = -1
    local nearestLead = math.huge
    local currentThreat = record.threat
    local currentThreatDistance = math.huge
    local currentPriority = -1
    local currentLead = math.huge
    local serverTime = workspace:GetServerTimeNow()
    local velocity = root.AssemblyLinearVelocity
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    local anticipation = 0.18 + (1 - record.profile.Risk) * 0.20
    local predictedPosition = root.Position + horizontalVelocity * anticipation

    for _, warning in ipairs(warningParts()) do
        local currentDistance = (root.Position - warning.Position).Magnitude
        local predictedDistance = (predictedPosition - warning.Position).Magnitude
        local distance = math.min(currentDistance, predictedDistance)
        local warningRadius = math.max(warning.Size.X, warning.Size.Z, warning.Size.Y) * 0.5
        local threshold = AISurvivorRules.warningDetectionRadius(
            warning.Name, warningRadius, warning:GetAttribute("WarningEndSize")
        )

        if distance <= threshold then
            local priority = AISurvivorRules.warningThreatPriority(warning.Name)
            local lead = AISurvivorRules.impactLeadRemaining(
                warning.Name, warning:GetAttribute("WarningStartedAt"),
                warning:GetAttribute("WarningDuration"), serverTime
            )
            if warning == currentThreat then
                currentThreatDistance = distance
                currentPriority = priority
                currentLead = lead
            end
            -- Under simultaneous Meteor/Bomb rings, a genuinely EARLIER
            -- impact outranks a nearer one only when its deadline beats
            -- the other by >0.30s. Otherwise preserve nearby focus and
            -- the original individual reaction delay.
            local earlier = priority == 2
                and AISurvivorRules.impactDeadlineEarlier(
                    lead, nearestLead, 0.30
                )
            local notLater = priority ~= 2
                or not AISurvivorRules.impactDeadlineEarlier(
                    nearestLead, lead, 0.30
                )
            if priority > nearestPriority
                or (priority == nearestPriority
                    and (earlier
                        or (notLater and distance < nearestDistance)))
            then
                nearest = warning
                nearestDistance = distance
                nearestPriority = priority
                nearestLead = lead
            end
        end
    end

    -- Nearby simultaneous danger rings may trade "nearest" every 0.18s
    -- as the NPC moves. Preserve focus while the previous *live* warning
    -- remains within four studs of the closest alternative. This retains
    -- realistic reaction timing and avoids a twitchy, cancelled escape.
    if currentThreat ~= nearest
        and currentPriority == nearestPriority
        -- Do not lock focus onto a slightly nearer impact if another
        -- already visible blast will land appreciably sooner.
        and (nearestPriority ~= 2
            or not AISurvivorRules.impactDeadlineEarlier(
                nearestLead, currentLead, 0.30
            ))
        and AISurvivorRules.keepThreatFocus(
            currentThreatDistance, nearestDistance, 4
        )
    then
        nearest = currentThreat
    end

    if nearest ~= record.threat then
        record.threat = nearest
        record.threatSeenAt = nearest and now or nil
        record.escapeTarget = nil
        record.escapeWarning = nil
        record.escapeUntil = 0
        record.escapeWarningVersion = nil
        record.escapeKnownWarnings = nil
        if nearest then
            warnNearbyContestants(record, now)
        end
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

    if nearest.Name == "FreezeWarning" or nearest.Name == "JumpShockWarning" then
        -- Jump Shock requires a *late* jump; jumping on first sight would
        -- leave a bot descending when the new physical dodge check runs.
        -- Warning timestamps are workspace server-time, unlike the
        -- os.clock() used for routine AI reaction delays.
        if nearest.Name == "JumpShockWarning"
            and not AISurvivorRules.shockJumpWindow(
                nearest:GetAttribute("WarningStartedAt"),
                nearest:GetAttribute("WarningDuration"),
                workspace:GetServerTimeNow()
            ) then
            return nil
        end
        -- Keep one reaction per actual pulse instance, even if it remains in
        -- range for many 0.18-second AI brain steps. Weak keys prevent stale
        -- destroyed warning parts from being retained across long sessions.
        local handled = record.reactedWarnings
        if not handled then
            handled = setmetatable({}, {__mode = "k"})
            record.reactedWarnings = handled
        end
        if AISurvivorRules.consumeWarningJump(
            handled, nearest, math.random(), record.profile.FreezeJumpChance
        ) then
            local humanoid = record.model and record.model:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Jump = true
            end
        end
        return nil
    end

    -- Commit for a short time so the bot does not twitch left and right
    -- on every 0.18s brain tick. Re-evaluate if the warning moves/changes.
    if record.escapeWarning == nearest and record.escapeTarget
        and record.escapeWarningVersion ~= warningVersion
    then
        -- A distant new impact must not trigger six candidate routes and
        -- twelve ground raycasts. Recalculate early only when a NEW real
        -- Meteor/Bomb ring actually intersects the committed direction.
        local known = record.escapeKnownWarnings or {}
        local live = warningParts() -- event-cached, not Workspace traversal
        local blocked = false
        for _, candidate in ipairs(live) do
            if not known[candidate]
                and AISurvivorRules.newImpactIntersectsEscape(
                    root.Position, record.escapeTarget,
                    candidate.Name, candidate.Position,
                    math.max(candidate.Size.X, candidate.Size.Z) * 0.5,
                    candidate:GetAttribute("WarningEndSize")
                )
            then
                blocked = true
                break
            end
        end
        if not blocked then
            record.escapeWarningVersion = warningVersion
            for _, candidate in ipairs(live) do
                known[candidate] = true
            end
            record.escapeKnownWarnings = known
        end
    end

    if record.escapeWarning == nearest
        and AISurvivorRules.keepEscapeRoute(
            record.escapeTarget, root.Position, now,
            record.escapeUntil, record.escapeWarningVersion, warningVersion
        )
    then
        return record.escapeTarget
    end

    record.escapeWarning = nearest
    record.escapeTarget = saferThreatEscape(record, root, predictedPosition, nearest)
    record.escapeUntil = now + 0.54
    record.escapeWarningVersion = warningVersion
    -- Remember only impact warnings included in this plan, with weak keys.
    -- Removed transient server warnings cannot accumulate across rounds.
    local known = setmetatable({}, {__mode = "k"})
    for _, candidate in ipairs(warningParts()) do
        known[candidate] = true
    end
    record.escapeKnownWarnings = known
    return record.escapeTarget
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

    local variantId = arenaVariantId()
    local groundBase = arena:FindFirstChild("Base")
    local groundTopY = groundBase and groundBase:IsA("BasePart")
        and (groundBase.Position.Y + groundBase.Size.Y * 0.5)
        or config.ArenaCenter.Y + 1
    -- A spawn marker lives on the real ARENA FLOOR, not an upper route.
    -- A downward difference of 8-10 studs used to pass reachableElevation
    -- and convince a sky bot to walk into open air towards that marker.
    local onGroundNetwork = not root
        or AISurvivorRules.elevatedRouteHasSupport(
            root.Position.Y, groundTopY, false)
    local spawns = arena:FindFirstChild("Spawns")
    for _, part in ipairs(sortedParts(spawns)) do
        local position = part.Position + Vector3.new(0, 2.5, 0)
        if onGroundNetwork and AISurvivorRules.reachableElevation(
            root and root.Position.Y or position.Y, position.Y, variantId
        ) then
            table.insert(result, {part = part, position = position})
        end
    end

    local platforms = arena:FindFirstChild("Platforms")
    local standingDeck = nil
    if root and platforms and root.Position.Y > groundTopY + 8 then
        -- One server physics ray per decision, never one per waypoint.
        -- A 34-stud center-distance limit alone allowed diagonally
        -- separated sky decks with no possible human jump between them.
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {root.Parent}
        params.RespectCanCollide = true
        local floor = workspace:Raycast(
            root.Position + Vector3.new(0, 1, 0),
            Vector3.new(0, -7.5, 0), params
        )
        local floorPart = floor and floor.Instance
        if floor and floor.Normal.Y >= 0.78 and floorPart
            and floorPart.Parent == platforms
            and AISurvivorRules.platformAvailable(
                floorPart.CanCollide, floorPart.Transparency,
                floorPart:GetAttribute("CollapsePhase"),
                floorPart:GetAttribute("BridgeShutterPhase")
            ) then
            standingDeck = floorPart
        end
    end
    for _, part in ipairs(sortedParts(platforms)) do
        local position = part.Position + Vector3.new(0, part.Size.Y * 0.5 + 2.4, 0)
        if AISurvivorRules.platformAvailable(
            part.CanCollide,
            part.Transparency,
            part:GetAttribute("CollapsePhase"),
            part:GetAttribute("BridgeShutterPhase")
        ) and AISurvivorRules.reachableElevation(
            root and root.Position.Y or position.Y,
            position.Y,
            variantId
        ) and AISurvivorRules.elevatedWaypointNearby(
            root and root.Position or position, position, groundTopY
        ) and AISurvivorRules.elevatedRouteHasSupport(
            root and root.Position.Y or position.Y,
            groundTopY, standingDeck ~= nil
        ) and (not standingDeck or part == standingDeck
            or AISurvivorRules.neighboringPhysicalDeck(
                standingDeck.CFrame, standingDeck.Size,
                part.CFrame, part.Size
            )
        ) and AISurvivorRules.outerStepReachable(
            part:GetAttribute("PerimeterStep"),
            root and root.Position, position,
            hasDisaster("ShrinkingArena")
        ) then
            table.insert(result, {
                part = part,
                position = position,
            })
        end
    end

    if variantId == "Orbital" then
        local helix = arena:FindFirstChild("HelixCircuit")
        for _, ramp in ipairs(sortedParts(helix)) do
            -- The authored Entry/Helix/Core route is physical for bots too.
            -- A bot approaching the outer deck should seek the floor ramp,
            -- not repeatedly try to jump through the underside of a deck.
            -- Keep the same bounded elevation/proximity filter to avoid
            -- selecting the high core from the floor.
            local isWalkway = ramp:GetAttribute("OrbitalHelixRamp") == true
                or ramp:GetAttribute("OrbitalAccessRamp") == true
                or ramp:GetAttribute("OrbitalCoreRamp") == true
            if isWalkway and ramp.CanCollide then
                local waypoint = ramp.Position
                    + ramp.CFrame.UpVector * (ramp.Size.Y * 0.5 + 2.4)
                if AISurvivorRules.helixWaypointReachable(
                    root and root.Position, waypoint
                ) then
                    table.insert(result, {
                        part = ramp,
                        position = waypoint,
                    })
                end
            end
        end
    end

    local base = groundBase
    if onGroundNetwork and base and base:IsA("BasePart")
        and AISurvivorRules.reachableElevation(
            root and root.Position.Y or base.Position.Y,
            base.Position.Y + base.Size.Y * 0.5 + 2.6,
            variantId
        ) then
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

    return result, standingDeck
end

local function scoreCandidate(record, root, candidate, traits)
    local position = candidate.position
    local center = config.ArenaCenter
    local risk = traits.Risk or record.profile.Risk
    local distanceFromCenter = (Vector3.new(position.X, 0, position.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude
    local travelDistance = (position - root.Position).Magnitude
    local variantId = arenaVariantId()
    local score = (math.random() * 8) - (travelDistance * 0.035)
    local landingExposures = 0
    score += AISurvivorRules.routeAffinity(variantId, position, center)
    score += AISurvivorRules.routeContinuity(
        variantId,
        root.Position,
        position,
        center,
        (record.roundTraits and record.roundTraits.DirectionBias) or record.strafeBias
    )
    if candidate.part
        and candidate.part:GetAttribute("PerimeterStep") ~= nil
        and not hasDisaster("RisingLava")
        and not hasDisaster("ShrinkingArena")
    then
        -- The new perimeter routes are optional, but should be chosen
        -- often enough to actually see opponents occupying those sectors.
        -- Hazards below still win on danger scoring; no speed advantage.
        score += 4.5 + risk * 2.0
    end
    if candidate.part
        and (candidate.part:GetAttribute("OrbitalHelixRamp") == true
            or candidate.part:GetAttribute("OrbitalAccessRamp") == true
            or candidate.part:GetAttribute("OrbitalCoreRamp") == true)
    then
        -- Bot intent should use the actual geometry from floor to reactor.
        -- An elevated core link is not a candidate until near enough in
        -- height; no teleport, scoring boost, or extra navigation loop.
        score += 7
        if candidate.part:GetAttribute("HelixPulseActive") == true then
            -- Charged ramps offer a mild routing preference, never enough
            -- to outweigh urgent hazard warnings or elevation safety.
            score += 3.5
        end
    end

    if hasDisaster("RisingLava") then
        score += position.Y * (1.45 - risk * 0.45)
    end

    if hasDisaster("Tornado") then
        -- Follow the storm's replicated position, not the old map center.
        -- Cautious bots can also recognize reachable high-ground routes.
        local cyclone = workspace:FindFirstChild("RoundTornado")
        local currentCenter = AISurvivorRules.tornadoCenter(cyclone, center)
        score += AISurvivorRules.tornadoRouteScore(
            position, currentCenter or center, risk
        )
    end

    if hasDisaster("ShrinkingArena") then
        score -= distanceFromCenter * (0.86 - risk * 0.24)
    end

    for _, warning in ipairs(warningParts()) do
        if warning.Name == "MeteorWarning" or warning.Name == "BombWarning" then
            -- The painted warning starts small and can grow to the server's
            -- final blast radius. Avoid crossing its FUTURE footprint, even
            -- when the waypoint itself lies safely on the far side.
            local radius = math.max(5, AISurvivorRules.warningDetectionRadius(
                warning.Name,
                math.max(warning.Size.X, warning.Size.Z) * 0.5,
                warning:GetAttribute("WarningEndSize")
            ) - 9)
            score -= AISurvivorRules.routeWarningPenalty(
                root.Position, position, warning.Position, radius
            ) * (1 - risk * 0.25)
            -- The destination must not win a personality lottery while
            -- still inside the TRUE final blast footprint. Count distinct
            -- currently live Meteor/Bomb areas; retain the full-path
            -- weighted penalty to rank routes with equal exposure.
            local dx = position.X - warning.Position.X
            local dz = position.Z - warning.Position.Z
            if dx * dx + dz * dz < (radius + 3) * (radius + 3) then
                landingExposures += 1
            end
        end
    end

    if candidate.part
        and candidate.part.Parent
        and candidate.part.Parent.Name == "Platforms"
        and not AISurvivorRules.platformAvailable(
            candidate.part.CanCollide,
            candidate.part.Transparency,
            candidate.part:GetAttribute("CollapsePhase"),
            candidate.part:GetAttribute("BridgeShutterPhase")
        )
    then
        score -= 120
    end

    return score, landingExposures
end

local function socialArenaTarget(record, root, traits, now)
    -- Choose a consistent human or NPC rival/teammate instead of turning
    -- toward an unrelated random location every time the brain replans.
    -- All simulated contestants remain explicitly marked as AI.
    local baseSocial = traits.SocialChance or record.profile.SocialChance or 0
    local socialMultiplier = record.profile.Id == "Balanced" and 1.55
        or (record.profile.Id == "Bold" and 1.18 or 0.85)
    if math.random() >= math.clamp(baseSocial * socialMultiplier, 0, 0.70) then
        return nil
    end

    local eligible = {}
    local arenaGround = arenaBase()
    local groundTopY = arenaGround
        and (arenaGround.Position.Y + arenaGround.Size.Y * 0.5)
        or config.ArenaCenter.Y + 1
    if root.Position.Y > groundTopY + 8 then
        -- Social urges must not override lost-footing safety: if the
        -- current roof vanished, chasing a teammate would walk the
        -- NPC farther into empty air. This ray runs only on an actual
        -- social decision, not on every brain tick.
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {record.model}
        params.RespectCanCollide = true
        local floor = workspace:Raycast(
            root.Position + Vector3.new(0, 1, 0),
            Vector3.new(0, -7.5, 0), params
        )
        if not floor or floor.Normal.Y < 0.78
            or not floor.Instance or not floor.Instance.CanCollide
            or not AISurvivorRules.platformAvailable(
                floor.Instance.CanCollide, floor.Instance.Transparency,
                floor.Instance:GetAttribute("CollapsePhase"),
                floor.Instance:GetAttribute("BridgeShutterPhase")
            ) then return nil end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        local humanRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local humanHumanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local roundEligible = player:GetAttribute("RoundParticipant") == true
            and player:GetAttribute("RoundEliminated") ~= true

        if roundEligible and humanRoot and humanRoot:IsA("BasePart")
            and humanHumanoid and humanHumanoid.Health > 0
            and AISurvivorRules.reachableElevation(
                root.Position.Y, humanRoot.Position.Y, arenaVariantId()
            )
            and AISurvivorRules.elevatedWaypointNearby(
                root.Position, humanRoot.Position, groundTopY
            )
        then
            table.insert(eligible, {
                partnerId = player.UserId,
                root = humanRoot,
                human = true,
            })
        end
    end

    -- NPC-to-NPC relationships make a solo round look like a group contest.
    -- Only target lower numbered bots, preventing mutual endless follow loops.
    for _, other in ipairs(records) do
        if other ~= record and other.slot < record.slot
            and other.inRound and other.alive and other.model
            and other.model.Parent
        then
            local otherRoot = other.model:FindFirstChild("HumanoidRootPart")
            local otherHumanoid = other.model:FindFirstChildOfClass("Humanoid")
            if otherRoot and otherRoot:IsA("BasePart")
                and otherHumanoid and otherHumanoid.Health > 0
                and AISurvivorRules.reachableElevation(
                    root.Position.Y, otherRoot.Position.Y, arenaVariantId()
                )
                and AISurvivorRules.elevatedWaypointNearby(
                    root.Position, otherRoot.Position, groundTopY
                )
            then
                table.insert(eligible, {
                    partnerId = other.proxy.UserId,
                    root = otherRoot,
                    human = false,
                })
            end
        end
    end

    if #eligible == 0 then
        record.socialPartnerUserId = nil
        return nil
    end

    local selected = nil
    if now < (record.socialPartnerUntil or 0) then
        for _, entry in ipairs(eligible) do
            if entry.partnerId == record.socialPartnerUserId then
                selected = entry
                break
            end
        end
    end
    if not selected then
        -- Real users remain the main social focus. Bot rivalries add variety
        -- rather than stealing the whole match from the human tester.
        local humanCandidates = {}
        for _, entry in ipairs(eligible) do
            if entry.human then
                table.insert(humanCandidates, entry)
            end
        end
        local humanPreference = record.profile.Id == "Balanced" and 0.86
            or (record.profile.Id == "Bold" and 0.72 or 0.64)
        local pool = #humanCandidates > 0 and math.random() < humanPreference
            and humanCandidates or eligible

        if record.profile.Id == "Balanced" then
            table.sort(pool, function(left, right)
                return (left.root.Position - root.Position).Magnitude
                    < (right.root.Position - root.Position).Magnitude
            end)
            selected = pool[1]
        else
            selected = pool[math.random(1, #pool)]
        end
        record.socialPartnerUserId = selected.partnerId
        record.socialPartnerUntil = now + 7 + math.random() * 5
    end

    local partnerRoot = selected.root
    local delta = root.Position - partnerRoot.Position
    local away = Vector3.new(delta.X, 0, delta.Z)
    if away.Magnitude < 0.5 then
        local angle = record.slot * 2.21
        away = Vector3.new(math.cos(angle), 0, math.sin(angle))
    else
        away = away.Unit
    end

    local velocity = partnerRoot.AssemblyLinearVelocity
    local flat = Vector3.new(velocity.X, 0, velocity.Z)
    local moving = flat.Magnitude > 2
    local forward = moving and flat.Unit or -away
    local lead = moving and forward * math.min(6, flat.Magnitude * 0.30)
        or Vector3.zero

    local target
    if record.profile.Id == "Bold" then
        -- Rival: try to beat the other contestant to the next safe spot.
        target = partnerRoot.Position + lead + forward * (7 + math.random() * 4)
    elseif record.profile.Id == "Balanced" then
        -- Teammate: shadow a flank without crowding or body blocking.
        target = partnerRoot.Position + lead + away * (5 + math.random() * 3)
    else
        -- Tactician: watch the group's route from a safer distance.
        target = partnerRoot.Position + lead + away * (9 + math.random() * 3)
    end

    target = clampToArena(target)
    local safeDeck = nil
    if root.Position.Y > groundTopY + 8 then
        -- Rooftop social spacing can put an otherwise harmless rival
        -- chase OUTSIDE a 12-stud bridge. Use the partner's actual
        -- grounded physical deck, not an imaginary landing coordinate.
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {
            record.model, partnerRoot.Parent
        }
        params.RespectCanCollide = true
        local surface = workspace:Raycast(
            partnerRoot.Position + Vector3.new(0, 1, 0),
            Vector3.new(0, -6, 0), params
        )
        local part = surface and surface.Instance
        if not part or not part:IsA("BasePart")
            or not part.Parent or part.Parent.Name ~= "Platforms"
            or surface.Normal.Y < 0.78
            or not AISurvivorRules.platformAvailable(
                part.CanCollide, part.Transparency,
                part:GetAttribute("CollapsePhase"),
                part:GetAttribute("BridgeShutterPhase")
            ) then return nil end
        -- A nearby teammate on a separate parallel sky route is NOT a
        -- safe social objective just because both roots have equal Y.
        -- A normal player could not cross 10 studs of air to meet them.
        local ownSurface = workspace:Raycast(
            root.Position + Vector3.new(0, 1, 0),
            Vector3.new(0, -7.5, 0), params
        )
        local ownDeck = ownSurface and ownSurface.Instance
        if not ownDeck or ownDeck.Parent ~= part.Parent
            or ownSurface.Normal.Y < 0.78
            or not AISurvivorRules.platformAvailable(
                ownDeck.CanCollide, ownDeck.Transparency,
                ownDeck:GetAttribute("CollapsePhase"),
                ownDeck:GetAttribute("BridgeShutterPhase"))
            or (ownDeck ~= part
                and not AISurvivorRules.neighboringPhysicalDeck(
                    ownDeck.CFrame, ownDeck.Size, part.CFrame, part.Size
                )) then return nil end
        safeDeck = part
        target = AISurvivorRules.clampWaypointToDeck(
            safeDeck.CFrame, safeDeck.Size, target
        ) or target
    end
    -- A social impulse may not override the existing server hazard evaluator.
    if scoreCandidate(record, root, {position = target}, traits) < -32 then
        return nil
    end
    return target, safeDeck
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

-- Real, sequential district exploration for NPCs. A bot can attempt
-- the same jump-by-jump perimeter climb as a human: no teleports, phantom
-- pathfinding nodes, privileged speed or artificial score rewards.
-- A session is short, interruptible and confined to at most TWO NPCs.
local function districtTraverseTarget(record, root, now)
    local expedition = record.districtTraverse
    local blocked = currentState.phase ~= "round"
        or not record.inRound
        or hasDisaster("ShrinkingArena")
        or hasDisaster("DisappearingPlatforms")
        or hasDisaster("RisingLava")
        or hasDisaster("Tornado")
        or currentState.finalRush == true
    if blocked then
        record.districtTraverse = nil
        return nil
    end

    local _, arena = arenaParts()
    local platforms = arena and arena:FindFirstChild("Platforms")
    if not platforms then
        record.districtTraverse = nil
        return nil
    end

    if expedition and now > expedition.deadline then
        record.districtTraverse = nil
        record.nextDistrictTraverseAt = now + 9
        expedition = nil
    end

    -- Keep most AI on the central battleground, so lobbies remain lively.
    -- Riskier personalities explore further; avatars remain capped at 16
    -- studs/second and all jumps use the ordinary Humanoid controller.
    if not expedition then
        -- A bot already pursuing a time-limited station must not suddenly
        -- start a long parkour outing on the next ordinary rethink tick.
        if record.signalInterestRoute then return nil end
        if now < (record.nextDistrictTraverseAt or 0) then
            return nil
        end
        local chance = record.profile.Id == "Bold" and 0.25
            or (record.profile.Id == "Balanced" and 0.17 or 0.105)
        if math.random() >= chance then
            return nil
        end

        local occupied, busyRoutes = 0, {}
        for _, other in ipairs(records) do
            if other ~= record and other.districtTraverse
                and other.inRound and other.alive then
                occupied += 1
                busyRoutes[other.districtTraverse.route] = true
            end
        end
        if occupied >= 2 then
            return nil
        end

        local candidates = {}
        for _, part in ipairs(platforms:GetChildren()) do
            if part:IsA("BasePart")
                and part:GetAttribute("PerimeterStep") == 1
                and AISurvivorRules.platformAvailable(
                    part.CanCollide, part.Transparency,
                    part:GetAttribute("CollapsePhase"),
                    part:GetAttribute("BridgeShutterPhase")
                )
            then
                local route = tonumber(part:GetAttribute("PerimeterRoute"))
                if route and route >= 1 and route <= 4
                    and not busyRoutes[route] then
                    local gap = part.Position - root.Position
                    local horizontal = Vector3.new(gap.X, 0, gap.Z).Magnitude
                    if horizontal <= 115 then
                        candidates[#candidates + 1] = {
                            route = route, distance = horizontal,
                            score = horizontal + math.random() * 18,
                        }
                    end
                end
            end
        end
        if #candidates == 0 then
            return nil
        end
        table.sort(candidates, function(a, b)
            return a.score < b.score
        end)
        local chosen = candidates[math.random(1, math.min(2, #candidates))]
        -- Some physical branch expeditions have a concrete cooperative
        -- destination: the live command on promenade step FOUR. Never
        -- route a bot toward an already activated or missing switch.
        local skyStation = arena:FindFirstChild("SkySpineSwitchyard")
        local branch = record.profile.Id == "Bold"
            or (record.profile.Id == "Balanced" and math.random() < 0.42)
        local skyMission = branch and skyStation ~= nil
            and skyStation:GetAttribute("SkyNetworkConnected") == false
            and math.random() < (record.profile.Id == "Bold" and 0.55 or 0.37)
        expedition = {
            route = chosen.route,
            stage = 1,
            deadline = now + (skyMission and 54 or 23),
            branch = branch,
            skyMission = skyMission,
        }
        record.districtTraverse = expedition
    end

    -- Abort an optional sky-command expedition if the cooperative goal
    -- disappears or another contestant has already connected the network.
    -- Ordinary on-deck survival/roaming continues with no invented stop.
    if expedition.skyMission then
        local command = arena:FindFirstChild("SkySpineSwitchyard")
        if not command or command:GetAttribute("SkyNetworkConnected") ~= false then
            record.districtTraverse = nil
            record.nextDistrictTraverseAt = now + 7
            return nil
        end
    end

    -- Resolve the live server-created decks each decision. Structural
    -- catastrophes may remove them during the round; stale references
    -- must never become an invisible AI teleport destination.
    local perimeter, branch, sky = {}, {}, {}
    for _, part in ipairs(platforms:GetChildren()) do
        if part:IsA("BasePart") then
            if part:GetAttribute("PerimeterRoute") == expedition.route then
                local step = tonumber(part:GetAttribute("PerimeterStep"))
                if step and step >= 1 and step <= 8 then
                    perimeter[step] = part
                end
            elseif expedition.branch
                and part:GetAttribute("BranchRoute") == expedition.route then
                local step = tonumber(part:GetAttribute("BranchStep"))
                if step and step >= 1 and step <= 4 then
                    branch[step] = part
                end
            elseif expedition.skyMission
                and part:GetAttribute("PromenadeLane")
                    == (expedition.route <= 2 and 1 or 2) then
                local step = tonumber(part:GetAttribute("PromenadeStep"))
                if step and step >= 1 and step <= 8 then
                    sky[step] = part
                end
            end
        end
    end

    local stages = {}
    for step = 1, expedition.branch and 5 or 8 do
        if not perimeter[step] then
            record.districtTraverse = nil
            return nil
        end
        stages[#stages + 1] = perimeter[step]
    end
    if expedition.branch then
        for step = 1, 4 do
            if not branch[step] then
                record.districtTraverse = nil
                return nil
            end
            stages[#stages + 1] = branch[step]
        end
    end
    if expedition.skyMission then
        -- Physically walk from BranchStep 4 onto its REAL, overlapping
        -- promenade endpoint. Then jump each 2.4-stud horizontal gap
        -- (1->4 west or 8->4 east) with the existing native Humanoid
        -- and 0.20-second bounded raycast gap-jump controller. The
        -- command deck is the FINAL stage; no direct airborne targets.
        local direction = expedition.route % 2 == 1 and 1 or -1
        local entry = direction == 1 and 1 or 8
        local previous = stages[#stages]
        for stage = entry, 4, direction do
            local deck = sky[stage]
            if not deck or not AISurvivorRules.platformAvailable(
                deck.CanCollide, deck.Transparency,
                deck:GetAttribute("CollapsePhase"),
                deck:GetAttribute("BridgeShutterPhase")
            ) or not AISurvivorRules.neighboringPhysicalDeck(
                previous.CFrame, previous.Size, deck.CFrame, deck.Size
            ) then
                record.districtTraverse = nil
                record.nextDistrictTraverseAt = now + 8
                return nil
            end
            if previous:GetAttribute("PromenadeLane") ~= nil then
                local first = direction == 1 and previous or deck
                local second = direction == 1 and deck or previous
                if not SkySpineSwitchyard.promenadeGapBetween(
                    first, second) then
                    record.districtTraverse = nil
                    record.nextDistrictTraverseAt = now + 8
                    return nil
                end
            else
                -- Overlap with the genuine branch terminal is a WALK.
                local top = previous.Position.Y + previous.Size.Y * 0.5
                local landingTop = deck.Position.Y + deck.Size.Y * 0.5
                if math.abs(top - landingTop) > 0.25 then
                    record.districtTraverse = nil
                    return nil
                end
            end
            stages[#stages + 1] = deck
            previous = deck
        end
    end

    local step = expedition.stage
    local deck = stages[step]
    if not deck or not AISurvivorRules.platformAvailable(
        deck.CanCollide, deck.Transparency,
        deck:GetAttribute("CollapsePhase"),
        deck:GetAttribute("BridgeShutterPhase")
    ) then
        record.districtTraverse = nil
        return nil
    end

    local humanoid = record.model
        and record.model:FindFirstChildOfClass("Humanoid")
    local grounded = humanoid ~= nil
        and humanoid.FloorMaterial ~= Enum.Material.Air
    local standing = AISurvivorRules.landedOnRouteDeck(
        deck.CFrame, deck.Size, root.Position, grounded
    )

    if standing then
        step += 1
        expedition.stage = step
        if step > #stages then
            record.districtTraverse = nil
            record.nextDistrictTraverseAt = now + 15
            record.model:SetAttribute("DistrictRouteCompleted", true)
            return nil
        end
        deck = stages[step]
    elseif step > 1 then
        local previous = stages[step - 1]
        local oldTop = previous.Position.Y + previous.Size.Y * 0.5
        if root.Position.Y < oldTop - 1.6 then
            -- Fell off the route: abandon the exhibition gracefully.
            record.districtTraverse = nil
            record.nextDistrictTraverseAt = now + 7
            return nil
        end
    end

    if not AISurvivorRules.platformAvailable(
        deck.CanCollide, deck.Transparency,
        deck:GetAttribute("CollapsePhase"),
        deck:GetAttribute("BridgeShutterPhase")
    ) then
        record.districtTraverse = nil
        return nil
    end

    local destination = deck.Position
        + Vector3.new(0, deck.Size.Y * 0.5 + 2.5, 0)
    local diff = destination - root.Position
    local flat = Vector3.new(diff.X, 0, diff.Z).Magnitude
    if flat > 140 then
        record.districtTraverse = nil
        return nil
    end
    record.targetIsPad = false
    record.targetPart = deck
    record.model:SetAttribute("DistrictRouteStep", step)
    -- The regular movement controller performs the actual jump. A real
    -- incoming impact can still preempt and cancel this scenic outing.
    return destination, math.clamp(
        flat / math.max(9, record.profile.WalkSpeed) + 0.95,
        1.25, 5.2
    )
end

-- Live district missions should attract nearby NPC competitors, too.
-- This is social world presence, NOT a server coin claim: bots never
-- masquerade as Player instances and cannot trigger ProximityPrompt
-- reward callbacks. Uses only real active stations and normal walking.
local function liveDistrictSignalTarget(record, root, now, traits)
    if not record.inRound or currentState.phase ~= "round"
        or currentState.finalRush == true
        or record.districtTraverse ~= nil
        or hasDisaster("ShrinkingArena")
        or hasDisaster("RisingLava")
        or hasDisaster("Tornado")
        or hasDisaster("DisappearingPlatforms")
    then
        record.signalInterestRoute = nil
        return nil
    end

    local _, arena = arenaParts()
    local folder = arena and arena:FindFirstChild("DistrictSignalRush")
    local route = folder and tonumber(folder:GetAttribute("SignalRoute"))
    if not route or route < 1 or route > 4
        or route ~= math.floor(route) then
        record.signalInterestRoute = nil
        return nil
    end
    local station = folder:FindFirstChild("SignalStation" .. route)
    local floor = station and station:FindFirstChild("Foundation")
    if not station or station:GetAttribute("SignalActive") ~= true
        or station:GetAttribute("SignalClaimed") == true
        or not floor or not floor:IsA("BasePart")
    then
        record.signalInterestRoute = nil
        return nil
    end

    local target = floor.Position + Vector3.new(0, 2.5, 0)
    local diff = target - root.Position
    local distance = Vector3.new(diff.X, 0, diff.Z).Magnitude
    if math.abs(diff.Y) > 5.8 then
        record.signalInterestRoute = nil
        return nil
    end

    local endAt = tonumber(folder:GetAttribute("SignalEndsAt"))
    local remaining = endAt and endAt > 0
        and math.max(0, endAt - workspace:GetServerTimeNow()) or 8.0
    local speed = math.max(10, tonumber(record.profile.WalkSpeed) or 16)
    if remaining <= 2.2
        or distance > math.min(83, speed * (remaining - 0.8))
    then
        record.signalInterestRoute = nil
        return nil
    end

    if distance < 7.0 then
        if record.signalInterestRoute == route then
            record.model:SetAttribute("DistrictSignalWitnessed", route)
            showBotSignal(record, "FOUND IT!", now)
        end
        record.signalInterestRoute = nil
        record.nextSignalInterestAt = now + 12
        return nil
    end

    local pursuing = record.signalInterestRoute == route
        and (record.signalInterestUntil or 0) > now
    if not pursuing then
        if now < (record.nextSignalInterestAt or 0) then
            return nil
        end
        record.nextSignalInterestAt = now + 2.5 + math.random() * 1.8

        -- One active AI explorer at a time; the others remain near
        -- the real players rather than all clustering at one beacon.
        for _, other in ipairs(records) do
            if other ~= record and other.inRound and other.alive
                and other.signalInterestRoute == route
                and (other.signalInterestUntil or 0) > now
            then
                return nil
            end
        end

        local risk = traits.Risk or record.profile.Risk
        local chance = record.profile.Id == "Bold" and 0.49
            or (record.profile.Id == "Balanced" and 0.31 or 0.15)
        if math.random() > chance * (0.8 + risk * 0.35) then
            return nil
        end
        -- Existing impact-path danger scoring also protects this new
        -- optional interest. A mission never takes priority over life.
        if scoreCandidate(record, root, {position = target}, traits) < -25 then
            return nil
        end
        record.signalInterestRoute = route
    end

    record.signalInterestUntil = now + math.min(6, remaining)
    record.targetPart = nil
    record.targetIsPad = false
    return separateTarget(record, target), math.clamp(
        distance / speed + 0.40, 1.1, 4.3)
end

local function chooseArenaTarget(record, root, now)
    local traits = decisionTraits(record)
    record.targetIsSkyrail = false
    record.skyrailDirection = nil
    -- During a real Meteor/Bomb round, a bot may proactively operate one
    -- of four huge protective machines to defend live HUMAN contestants.
    -- It walks normally, waits for the genuine physical hold, and must
    -- abandon the plan as soon as any warning demands emergency evasion.
    if record.inRound and currentState.phase == "round"
        and not record.assistRelay and not record.assistShield
        and not record.districtTraverse
        and now >= (record.nextShieldAt or 0)
        and not hasDisaster("ShrinkingArena")
        and not hasDisaster("RisingLava")
        and not hasDisaster("Tornado")
        and root.Position.Y <= config.ArenaCenter.Y + 7.5 then
        local helpPoint, station = ArenaSkyShieldNetwork.botOpportunity(
            record.model, now
        )
        if helpPoint then
            record.assistShield = station
            record.shieldHoldAt = nil
            record.idleUntil = 0
            record.turnPauseUntil = 0
            record.targetPart = nil
            record.targetIsPad = false
            record.nextShieldAt = now + 12
            return helpPoint, 1.5
        end
        record.nextShieldAt = now + 2.9 + record.slot * 0.18
    end

    -- An elevated bot can now actively WALK toward the genuine console
    -- on its own current solid deck instead of only activating by chance
    -- when it happens to spawn within the old 7.5-stud prompt radius.
    -- The station service verifies the exact supporting collision Part,
    -- reserves one bot for a short time and never invents a cross-gap path.
    if record.inRound and currentState.phase == "round"
        and not record.assistShield and not record.assistRelay
        and not record.districtTraverse
        and now >= (record.nextSpineAt or 0)
        and not hasDisaster("ShrinkingArena")
        and not hasDisaster("RisingLava")
        and not hasDisaster("Tornado") then
        local approach, core = SkySpineSwitchyard.botApproach(
            record.model, now)
        if approach and core then
            record.spineControl = core
            record.spineHoldAt = nil
            record.idleUntil = 0
            record.turnPauseUntil = 0
            record.targetPart = nil
            record.targetIsPad = false
            record.nextSpineAt = now + 8
            return approach, 1.2
        end
        record.nextSpineAt = now + 2.8 + record.slot * 0.15
    end

    -- Once the bot has committed to helping a real teammate, don't
    -- start a competing multistep parkour route before it finishes
    -- the actual console approach/hold. Urgent hazards still override
    -- this in stepRecord before any cooperative action.
    if not record.assistShield then
        local physicalRoute, routeHold = districtTraverseTarget(record, root, now)
        if physicalRoute then
            return physicalRoute, routeHold
        end
        local signalTarget, signalHold = liveDistrictSignalTarget(
            record, root, now, traits)
        if signalTarget then
            return signalTarget, signalHold
        end
    end
    -- Bots can use REAL server-owned world consoles, but only as helpers
    -- for live nearby HUMAN contestants. No client event, teleport,
    -- fabricated DASH token or interaction while the floor is contracting.
    -- Reserve one of two consoles to avoid seven NPCs swarming it.
    if record.inRound and currentState.phase == "round"
        and not record.assistShield
        and now >= (record.nextAssistAt or 0)
        and not hasDisaster("ShrinkingArena")
        and not hasDisaster("RisingLava")
        and not hasDisaster("Tornado")
        and root.Position.Y <= config.ArenaCenter.Y + 7.5 then
        local assistPoint, station = TeamDashRelay.botOpportunity(
            record.model, now
        )
        if assistPoint then
            record.assistRelay = station
            record.assistHoldAt = nil
            record.idleUntil = 0
            record.turnPauseUntil = 0
            record.targetPart = nil
            record.targetIsPad = false
            record.nextAssistAt = now + 11
            return assistPoint, 1.6
        end
        record.nextAssistAt = now + 2.8 + record.slot * 0.15
    end

    local socialTarget, socialDeck =
        socialArenaTarget(record, root, traits, now)
    if socialTarget then
        record.targetIsPad = false
        record.targetPart = socialDeck
        local waypoint = separateTarget(record, socialTarget)
        if socialDeck then
            waypoint = AISurvivorRules.clampWaypointToDeck(
                socialDeck.CFrame, socialDeck.Size, waypoint
            ) or socialTarget
        end
        return waypoint, 0.65 + math.random() * 1.0
    end

    -- When a Flux Relay can be reached before its charge window ends,
    -- humanlike bots sometimes pick it as a planned escape route. A bot
    -- never targets a gate during shrinking-floor or rising-lava hazards.
    if currentState.phase == "round"
        and not hasDisaster("ShrinkingArena")
        and not hasDisaster("RisingLava")
        and math.random() < (0.13 + (traits.Risk or record.profile.Risk) * 0.14)
    then
        local _, arena = arenaParts()
        local mechanics = arena and arena:FindFirstChild("Mechanics")
        local relayFolder = mechanics and mechanics:FindFirstChild("FluxRelays")
        if relayFolder then
            local choices = {}
            local serverTime = workspace:GetServerTimeNow()
            for _, relay in ipairs(relayFolder:GetChildren()) do
                if relay:IsA("BasePart") and relay:GetAttribute("FluxRelayIndex") ~= nil then
                    local gap = relay.Position - root.Position
                    local horizontal = Vector3.new(gap.X, 0, gap.Z).Magnitude
                    if math.abs(gap.Y) <= 6
                        and FluxRelayRules.viableRoute(
                            serverTime,
                            relay:GetAttribute("FluxCycleEpoch"),
                            relay:GetAttribute("FluxPhaseOffset"),
                            horizontal,
                            record.profile.WalkSpeed
                        )
                    then
                        table.insert(choices, {part = relay, distance = horizontal})
                    end
                end
            end
            table.sort(choices, function(a, b)
                return a.distance < b.distance
            end)
            if #choices > 0 then
                local relay = choices[1].part
                record.targetIsPad = false
                record.targetPart = relay
                -- Aim beyond the trigger so the walking bot actually crosses
                -- its volume. Stopping at the centre alone would be cancelled
                -- by the regular four-stud target-arrival tolerance.
                local outward = relay.Position - config.ArenaCenter
                local flat = Vector3.new(outward.X, 0, outward.Z)
                local crossing = relay.Position + (flat.Magnitude > 0.1
                    and flat.Unit * 7 or Vector3.zero)
                return clampToArena(separateTarget(record, crossing)), 1.0
            end
        end
    end

    -- Elevated bots occasionally complete a full Skyrail crossing.
    -- Only enter from a real mid-deck endpoint: never navigate from
    -- ground-level into an unreachable airborne bridge.
    if currentState.phase == "round"
        and record.inRound
        and arenaVariantId() == "Towers"
        and now >= (record.nextSkyrailAt or 0)
        and not hasDisaster("Tornado")
        and not hasDisaster("ShrinkingArena")
        and math.random() < (0.14 + (traits.Risk or record.profile.Risk) * 0.19)
    then
        local _, arena = arenaParts()
        local platforms = arena and arena:FindFirstChild("Platforms")
        if platforms then
            local options = {}
            for _, bridge in ipairs(platforms:GetChildren()) do
                if bridge:IsA("BasePart")
                    and bridge:GetAttribute("ChaosSkybridge") == true
                    and (bridge:GetAttribute("BridgeShutterPhase") == nil
                        or bridge:GetAttribute("BridgeShutterPhase") == "Idle")
                    and AISurvivorRules.platformAvailable(
                        bridge.CanCollide, bridge.Transparency,
                        bridge:GetAttribute("CollapsePhase"),
                        bridge:GetAttribute("BridgeShutterPhase"))
                then
                    local finish, sign = AISurvivorRules.skyrailCrossingTarget(
                        root.Position, bridge.CFrame, bridge.Size)
                    if finish then
                        table.insert(options, {part = bridge,
                            target = finish, sign = sign})
                    end
                end
            end
            if #options > 0 then
                local choice = options[math.random(1, #options)]
                record.targetPart = choice.part
                record.targetIsPad = false
                record.targetIsSkyrail = true
                record.skyrailDirection = choice.sign
                record.nextSkyrailAt = now + 11
                -- No social separation or sideways bias on narrow decks.
                return choice.target, 4.6
            end
        end
    end

    -- Classic Grid runners visibly attempt the optional four-station
    -- clockwise mastery course instead of ignoring authored world content.
    -- Live hazards and regular dodge decisions still take precedence.
    if record.inRound and currentState.phase == "round"
        and arenaVariantId() == "Classic"
        and not hasDisaster("RisingLava")
        and not hasDisaster("Tornado")
        and not hasDisaster("ShrinkingArena")
        and record.model
        and record.model:GetAttribute("GridCircuitComplete") ~= true
    then
        local step = tonumber(record.model:GetAttribute("GridCircuitStep")) or 0
        local chosenChance = step > 0 and 0.60 or 0.12
        if math.random() < chosenChance then
            local _, arena = arenaParts()
            local mechanics = arena and arena:FindFirstChild("Mechanics")
            local grid = mechanics and mechanics:FindFirstChild("GridCircuit")
            if grid then
                local targetIndex = tonumber(
                    record.model:GetAttribute("GridCircuitNext")
                ) or 0
                if targetIndex < 1 or targetIndex > 4 then
                    targetIndex = math.random(1, 4)
                end
                local node = grid:FindFirstChild("GridCircuitNode" .. targetIndex)
                if node and node:IsA("BasePart") then
                    local gap = node.Position - root.Position
                    local flat = Vector3.new(gap.X, 0, gap.Z)
                    if math.abs(gap.Y) < 5.5 and flat.Magnitude < 60 then
                        -- Walk through, not merely to, the edge of the
                        -- trigger; bot AI considers itself 'arrived' ~4
                        -- studs before the target and can stop short.
                        local crossing = node.Position + (
                            flat.Magnitude > 0.01
                            and flat.Unit * 5.0 or Vector3.zero
                        )
                        record.targetIsPad = false
                        record.targetPart = node
                        return clampToArena(separateTarget(record, crossing)),
                            math.clamp(flat.Magnitude /
                                math.max(10, record.profile.WalkSpeed or 16) + 0.8,
                                1.6, 4.6)
                    end
                end
            end
        end
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
    -- Mobility pads are authored on the main ARENA FLOOR, not on
    -- the 20+ stud sky promenade. A tempting distant pad previously
    -- bypassed elevated-deck safety filtering and led bots off roofs.
    -- Upper bots must first descend through actual physical walkways.
    local wantsPad = lowOnMap
        and not hasDisaster("LowGravity")
        and #pads > 0
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

    local rawCandidates, standingDeck = arenaCandidates(root)
    local candidates = AISurvivorRules.filterRecentlyFailedCandidates(
        rawCandidates, record.failedTarget, now,
        record.failedTargetUntil
    )
    if #candidates == 0 then
        -- No reachable physical waypoint? Stay on the CURRENT footing
        -- rather than ordering a sky-deck bot to run toward a random
        -- ground point and fall to its death. Hazard evasion still wins.
        return root.Position, 1.5
    end

    local ranked = {}
    local lowestExposure = math.huge
    for _, candidate in ipairs(candidates) do
        -- Once already standing on an upper deck, prefer progressing
        -- to a physically adjacent platform instead of repeatedly
        -- standing at the center of the same roof. Hazard penalties
        -- are still scored independently and retain absolute priority.
        local continuation = standingDeck
            and candidate.part and candidate.part ~= standingDeck
            and candidate.part.Parent == standingDeck.Parent
            and 10 or 0
        local score, landingExposures =
            scoreCandidate(record, root, candidate, traits)
        lowestExposure = math.min(lowestExposure, landingExposures)
        table.insert(ranked, {
            candidate = candidate,
            score = score + continuation,
            landingExposures = landingExposures,
        })
    end
    -- Random personality choices may vary within the safest tier, but
    -- cannot pick a blast-covered destination if a verified candidate
    -- outside every active impact exists. When all are exposed, prefer
    -- the least-overlapping locations before applying ordinary scoring.
    local safeRanked = {}
    for _, entry in ipairs(ranked) do
        if entry.landingExposures == lowestExposure then
            safeRanked[#safeRanked + 1] = entry
        end
    end
    ranked = safeRanked
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
        -- Don't let crowd-avoidance vectors push a real sky landing off
        -- its collision surface. The world location is authoritative.
        target = AISurvivorRules.clampWaypointToDeck(
            selected.part.CFrame, selected.part.Size, target
        ) or selected.position
    end

    local hold = record.profile.TargetHoldMin
        + math.random() * (record.profile.TargetHoldMax - record.profile.TargetHoldMin)
    local outerStep = selected.part
        and selected.part:GetAttribute("PerimeterStep") or nil
    if outerStep then
        local flat = target - root.Position
        local horizontalDistance = Vector3.new(flat.X, 0, flat.Z).Magnitude
        hold = AISurvivorRules.outerRouteHold(
            hold, horizontalDistance, record.profile.WalkSpeed, outerStep
        )
    end
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
        and math.clamp(
            (traits.SocialChance or record.profile.SocialChance or 0.2)
                * (record.profile.Id == "Balanced" and 1.55 or 0.95),
            0.08, 0.48
        )
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

            -- The teammate seeks real players instead of spending every
            -- lobby cycle beside another bot; other roles remain varied.
            if record.profile.Id == "Balanced" and math.random() < 0.78 then
                local humanPartners = {}
                for _, candidate in ipairs(pool) do
                    if candidate.partnerSlot >= 1000 then
                        table.insert(humanPartners, candidate)
                    end
                end
                if #humanPartners > 0 then
                    pool = humanPartners
                end
            end
            local selected = pool[math.random(1, #pool)]
            record.lastSocialPartnerSlot = selected.partnerSlot
            record.lobbyActivity = "social"
            record.nextSocialAt = now + (record.profile.Id == "Balanced" and 3 or 5)
                + math.random() * 5
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
    record.lobbyRoamCycle = (record.lobbyRoamCycle or 0) + 1

    if math.random() < 0.56 then
        local offset = AISurvivorRules.lobbyNodeOffset(
            record.slot,
            record.lobbyRoamCycle
        )
        return center + offset + Vector3.new(0, 2.7, 0),
            1.8 + math.random() * 2.2,
            nil
    end

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

-- A stranded bot must not endlessly retry the exact same piece of
-- machinery or walk into a wall. Test physical clearance and support only
-- after genuinely failing to advance; there is no extra per-frame raycast.
local function nearbyRecoveryStep(record, root, failedDestination, now)
    -- Check the REAL intended route, not the NPC's potentially rotated
    -- RightVector: that used to send several stuck bots into the same wall.
    local directions = AISurvivorRules.recoveryDirections(
        root.Position, failedDestination or record.failedTarget
            or (root.Position + root.CFrame.LookVector * 8),
        (record.slot or 1) + (record.recoveryAttemptCount or 0))
    -- Rank the SAME seven local detours by real contestant occupancy
    -- before running any expensive collision/floor probes. Previously
    -- four bots on matching slot parity took the same first sidestep,
    -- sometimes repeatedly blocking each other. A recent physical
    -- recovery target is only a short-lived reservation hint, not a
    -- fabricated wall or reason to reject a valid route.
    local peers = {}
    for _, other in ipairs(records) do
        if other ~= record and other.inRound and other.alive
            and other.model and other.model.Parent then
            local otherRoot = other.model:FindFirstChild("HumanoidRootPart")
            if otherRoot and otherRoot:IsA("BasePart")
                and math.abs(otherRoot.Position.Y - root.Position.Y) < 6
                and (otherRoot.Position - root.Position).Magnitude < 18 then
                peers[#peers + 1] = otherRoot.Position
                local target = other.target
                if typeof(target) == "Vector3"
                    and now - (other.lastRecoveryAt or -math.huge) < 2.2
                    and now >= (other.lastRecoveryAt or -math.huge)
                    and (target - otherRoot.Position).Magnitude < 10 then
                    peers[#peers + 1] = target
                end
            end
        end
    end
    local rankedDirections = {}
    for index, direction in ipairs(directions) do
        local candidate = clampToArena(root.Position + direction * 6.5)
        local cost = 0
        for _, peerPosition in ipairs(peers) do
            local dx = candidate.X - peerPosition.X
            local dz = candidate.Z - peerPosition.Z
            local distance = math.sqrt(dx * dx + dz * dz)
            cost += math.max(0, 6 - distance)
        end
        rankedDirections[#rankedDirections + 1] = {
            direction = direction, cost = cost, original = index,
        }
    end
    table.sort(rankedDirections, function(a, b)
        if a.cost == b.cost then return a.original < b.original end
        return a.cost < b.cost
    end)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    -- Crowd members are dynamic blockers, never a valid floor. The old
    -- ground rays could hit a teammate's limb first and reject a real
    -- safe detour, leaving several clustered bots permanently stalled.
    -- Filter only avatars for the ground probe; the separate full-body
    -- clearance check still detects real anchored walls.
    local groundExclusions = {record.model}
    if botsFolder then groundExclusions[#groundExclusions + 1] = botsFolder end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            groundExclusions[#groundExclusions + 1] = player.Character
        end
    end
    params.FilterDescendantsInstances = groundExclusions
    params.RespectCanCollide = true
    local function groundAt(candidate)
        local ray = workspace:Raycast(
            candidate + Vector3.new(0, 3, 0),
            Vector3.new(0, -9, 0), params)
        if not ray or not ray.Instance or not ray.Instance.CanCollide
            or ray.Normal.Y < 0.78 then return nil end
        -- A visually present deck can be blinking out under a bot.
        if not AISurvivorRules.platformAvailable(
            ray.Instance.CanCollide,
            ray.Instance.Transparency,
            ray.Instance:GetAttribute("CollapsePhase"),
            ray.Instance:GetAttribute("BridgeShutterPhase")
        ) then return nil end
        return ray.Position.Y
    end

    -- Only run these rays after a confirmed stall, not on every AI tick.
    -- The original shoulder-only line missed short barriers and rails
    -- that block a humanoid's feet or torso. Sample the full body column.
    local originFloorY = groundAt(root.Position)
    if not originFloorY then return nil end
    local clearanceOffsets = {-1.35, 0, 1.1}
    local function blockedByStatic(origin, displacement)
        -- Other moving R15 contestants are temporary crowding, not
        -- permanent walls. A single ray hit on their limbs previously
        -- discarded otherwise valid recovery routes for all seven bots.
        -- Look past at most three dynamic hits while still rejecting any
        -- anchored solid obstruction behind them. This runs only on a
        -- confirmed physical stall, never on each brain/physics frame.
        local exclusions = {record.model}
        local clearanceParams = RaycastParams.new()
        clearanceParams.FilterType = Enum.RaycastFilterType.Exclude
        clearanceParams.RespectCanCollide = true
        for _ = 1, 4 do
            clearanceParams.FilterDescendantsInstances = exclusions
            local hit = workspace:Raycast(
                origin, displacement, clearanceParams
            )
            if not hit then return false end
            if hit.Instance.Anchored then return true end
            exclusions[#exclusions + 1] = hit.Instance
        end
        -- An unusually dense moving crowd cannot justify claiming
        -- the corridor is clear without seeing past the last body.
        return true
    end
    for _, option in ipairs(rankedDirections) do
        local step = option.direction * 6.5
        local candidate = clampToArena(root.Position + step)
        local actualStep = Vector3.new(candidate.X - root.Position.X,
            0, candidate.Z - root.Position.Z)
        -- Never treat boundary-clamped 0.5-stud twitching as a rescue.
        if actualStep.Magnitude >= 4.5 then
            -- A mechanically walkable sidestep can still run through a
            -- genuine upcoming Meteor/Bomb blast. Reject it using the
            -- same cached warning parts and impact-corridor rule as
            -- live urgent evasion, before expensive physical probes.
            local insideImpactRoute = false
            for _, warning in ipairs(warningParts()) do
                if AISurvivorRules.newImpactIntersectsEscape(
                    root.Position, candidate, warning.Name,
                    warning.Position,
                    math.max(warning.Size.X, warning.Size.Z) * 0.5,
                    warning:GetAttribute("WarningEndSize")
                ) then
                    insideImpactRoute = true
                    break
                end
            end
            local blocked = insideImpactRoute
            if not blocked then
                for _, offset in ipairs(clearanceOffsets) do
                    if blockedByStatic(
                        root.Position + Vector3.new(0, offset, 0),
                        actualStep
                    ) then
                        blocked = true
                        break
                    end
                end
            end
            if not blocked then
                -- Midpoint AND endpoint need real walkable support; matching
                -- the measured current floor handles differing rig scales.
                -- A 6.5-stud detour can cross a narrow gap hidden
                -- between safe midpoint/endpoint samples. Probe every
                -- quarter and bound elevation changes between neighbors.
                local quarterY = groundAt(
                    root.Position + actualStep * 0.25)
                local midpointY = quarterY and groundAt(
                    root.Position + actualStep * 0.50)
                local threeQuarterY = midpointY and groundAt(
                    root.Position + actualStep * 0.75)
                local endpointY = threeQuarterY and groundAt(candidate)
                if AISurvivorRules.recoveryGroundSamplesSafe(
                    root.Position.Y, originFloorY, quarterY,
                    midpointY, threeQuarterY, endpointY,
                    actualStep.Magnitude
                ) then
                    return Vector3.new(
                        candidate.X, root.Position.Y, candidate.Z)
                end
            end
        end
    end
    return nil
end

-- Ground-only large-obstacle fallback. The fast local detour remains first.
-- ComputeAsync yields, so never run it in the sequential eight-bot brain loop.
-- Candidate waypoints must be on the EXISTING collidable arena base: no
-- invisible bridges, obstacle phasing, height cheats or movement teleports.
local function requestGroundNavigation(record, root, goal, now)
    if record.groundNavigationPending or record.groundNavigation
        or now < (record.nextGroundNavigationAt or 0)
        or currentState.phase ~= "round" or not record.inRound
        or typeof(goal) ~= "Vector3"
        or hasDisaster("RisingLava") or hasDisaster("ShrinkingArena")
        or hasDisaster("Tornado") or hasDisaster("DisappearingPlatforms")
        or #warningParts() > 0 then
        return
    end
    local base = arenaBase()
    if not base or not base:IsA("BasePart") or not base.CanCollide then
        return
    end
    local top = base.Position.Y + base.Size.Y * 0.5
    if math.abs(root.Position.Y - top) > 7
        or math.abs(goal.Y - root.Position.Y) > 5 then
        return
    end
    local flat = Vector3.new(goal.X - root.Position.X, 0, goal.Z - root.Position.Z)
    if flat.Magnitude < 9 or flat.Magnitude > 110 then
        return
    end

    record.nextGroundNavigationAt = now + 9
    record.groundNavigationPending = true
    record.groundNavigationStartedAt = now
    record.groundNavigationFallbackTarget = nil
    -- Keep the actual requested destination while ComputeAsync yields.
    -- The temporary physical sidestep is not the goal to quarantine.
    record.groundNavigationPendingGoal = goal
    record.groundNavigationToken = (record.groundNavigationToken or 0) + 1
    local token = record.groundNavigationToken
    local rig = record.model
    local start = root.Position

    task.spawn(function()
        local ok, waypoints = pcall(function()
            local path = PathfindingService:CreatePath({
                AgentRadius = 2.5,
                AgentHeight = 6,
                AgentCanJump = false,
                WaypointSpacing = 5,
            })
            path:ComputeAsync(start, goal)
            if path.Status ~= Enum.PathStatus.Success then
                return nil
            end
            return path:GetWaypoints()
        end)
        if record.groundNavigationToken ~= token or record.model ~= rig then
            return
        end
        record.groundNavigationPending = false
        record.groundNavigationStartedAt = nil
        record.groundNavigationPendingGoal = nil
        -- A real "no path" result is different from a transient engine
        -- error, a newly active disaster or an obsolete asynchronous
        -- answer. Quarantine only the original goal when this exact
        -- still-current request produced no usable NavMesh route.
        local fallback = record.groundNavigationFallbackTarget
        if ok and (not waypoints or #waypoints < 2)
            and rig and rig.Parent and record.inRound
            and currentState.phase == "round"
            and arenaBase() == base and #warningParts() == 0
            and not hasDisaster("RisingLava")
            and not hasDisaster("ShrinkingArena")
            and not hasDisaster("Tornado")
            and not hasDisaster("DisappearingPlatforms")
            and record.failedTarget == goal
            and fallback ~= nil and record.target == fallback
            and record.targetPart == nil
            and record.assistShield == nil and record.assistRelay == nil
            and record.spineControl == nil and record.districtTraverse == nil
            and record.signalInterestRoute == nil then
            local decidedAt = os.clock()
            record.recoveryAttemptCount = AISurvivorRules.nextRecoveryAttempt(
                record.recoveryAttemptCount, record.lastRecoveryAt, decidedAt)
            record.lastRecoveryAt = decidedAt
            record.failedTargetUntil = decidedAt
                + AISurvivorRules.failedGoalCooldown(
                    record.recoveryAttemptCount)
            record.groundNavigationFallbackTarget = nil
            record.target = nil
            record.lastMoveTarget = nil
            record.lastProgressTarget = nil
            record.nextThink = 0
            AISurvivorService.PerformanceDiagnostics.GroundRoutesNoPath += 1
            rig:SetAttribute("BotGroundRouteNoPathCount",
                (tonumber(rig:GetAttribute(
                    "BotGroundRouteNoPathCount")) or 0) + 1)
            return
        end
        -- ComputeAsync may raise a transient engine error rather than
        -- returning a definitive NoPath. When the bot still owns this
        -- recovery fallback, release it so normal AI can choose another
        -- physically valid objective. Never quarantine the original
        -- destination for an engine exception, and never overwrite a
        -- newer cooperative or hazard decision.
        if not ok and rig and rig.Parent and record.inRound
            and currentState.phase == "round"
            and record.failedTarget == goal
            and fallback ~= nil and record.target == fallback
            and record.targetPart == nil
            and record.assistShield == nil and record.assistRelay == nil
            and record.spineControl == nil and record.districtTraverse == nil
            and record.signalInterestRoute == nil then
            record.groundNavigationFallbackTarget = nil
            record.recoveryWaypoint = nil
            record.recoveryCommitUntil = 0
            record.target = nil
            record.lastMoveTarget = nil
            record.lastProgressTarget = nil
            record.nextThink = 0
            return
        end
        -- A two-waypoint NavMesh path (start + goal) is legitimate.
        -- Still require the exact same real-floor and corridor checks.
        if not ok or not waypoints or #waypoints < 2
            or #waypoints > 24 or not rig or not rig.Parent
            or not record.inRound or currentState.phase ~= "round"
            or arenaBase() ~= base or #warningParts() > 0
            or hasDisaster("RisingLava") or hasDisaster("ShrinkingArena")
            or hasDisaster("Tornado") or hasDisaster("DisappearingPlatforms")
            or record.failedTarget ~= goal
            -- A bot may accept a newer cooperative station or roam goal
            -- while ComputeAsync yields. Never overwrite that decision
            -- with an obsolete obstacle detour.
            or record.groundNavigationFallbackTarget == nil
            or record.target ~= record.groundNavigationFallbackTarget
            or record.targetPart ~= nil
            or record.assistShield ~= nil or record.assistRelay ~= nil
            or record.spineControl ~= nil or record.districtTraverse ~= nil
            or record.signalInterestRoute ~= nil then
            return
        end

        -- An ordinary downward ray can hit a collidable bridge, avatar
        -- or industrial prop above a valid base waypoint. The computed
        -- NavMesh route is rejected even though the REAL floor is intact.
        -- Reuse the base-only support policy of liveGroundRouteCorridorSafe:
        -- the waypoint must be on this arena's low floor, and the ray must
        -- contact the exact server-owned base collider.
        local baseOnly = RaycastParams.new()
        baseOnly.FilterType = Enum.RaycastFilterType.Include
        baseOnly.FilterDescendantsInstances = {base}
        baseOnly.RespectCanCollide = true
        local function onPhysicalBase(point)
            if typeof(point) ~= "Vector3"
                or math.abs(point.Y - top) > 5 then
                return false
            end
            local localPoint = base.CFrame:PointToObjectSpace(point)
            if math.abs(localPoint.X) > base.Size.X * 0.5 - 1.5
                or math.abs(localPoint.Z) > base.Size.Z * 0.5 - 1.5 then
                return false
            end
            local hit = workspace:Raycast(
                point + Vector3.new(0, 7, 0),
                Vector3.new(0, -15, 0), baseOnly)
            return hit ~= nil and hit.Instance == base
                and hit.Normal.Y >= 0.78
                and math.abs(hit.Position.Y - top) < 2.5
        end
        if not onPhysicalBase(start) then return end
        local points = {}
        local previous = start
        local length = 0
        for index, waypoint in ipairs(waypoints) do
            if waypoint.Action == Enum.PathWaypointAction.Jump then return end
            if index > 1 then
                local point = waypoint.Position
                local difference = point - previous
                local distance = difference.Magnitude
                length += distance
                if distance > 13 or length > 155
                    or not onPhysicalBase(point)
                    or not onPhysicalBase(previous + difference * 0.5) then
                    return
                end
                table.insert(points, Vector3.new(point.X, start.Y, point.Z))
                previous = point
            end
        end
        -- Pathfinding can finish after the bot has moved elsewhere or a
        -- hazard appeared: never force it back to the old starting point.
        local liveRoot = rig:FindFirstChild("HumanoidRootPart")
        if not liveRoot or (liveRoot.Position - start).Magnitude > 9
            or #points < 1 or record.groundNavigationToken ~= token then
            return
        end
        record.groundNavigationFallbackTarget = nil
        AISurvivorService.PerformanceDiagnostics.GroundRoutesAccepted += 1
        local acceptedAt = os.clock()
        record.groundNavigation = {
            points = points,
            origin = start,
            goal = goal,
            base = base,
            index = 1,
            nextLiveCheckAt = 0,
            -- Allow a long but genuinely advancing route to finish.
            -- Still enforce both a per-waypoint stall deadline and a
            -- hard lifetime, so the bot cannot retain a path forever.
            expires = acceptedAt + 11,
            hardExpires = acceptedAt + 30,
        }
        record.target = points[1]
        record.targetPart = nil
        record.targetIsPad = false
        record.targetIsSkyrail = false
        record.lastMoveTarget = nil
        record.turnPauseUntil = 0
        record.idleUntil = 0
        record.nextThink = os.clock() + 1
        rig:SetAttribute("BotGroundNavigationCount",
            (tonumber(rig:GetAttribute("BotGroundNavigationCount")) or 0) + 1)
    end)
end

-- Live ground-route safety checks are EVENTUAL, not physics frame polling.
-- An engine NavMesh path can become stale after a physical obstacle enters
-- the next lane. Recheck ONLY the immediate segment every ~0.8s per bot.
-- Never claim a sky deck, dynamic avatar or invisible bridge as base floor.
-- Short-lived physics query for permanent-obstacle probes. A moving
-- participant is never a static wall or the arena's floor: without this
-- filter, a body in front can hide a real anchored barrier behind it.
-- Only executed by bounded NavMesh corridor / ground preview checks.
local function staticObstacleProbeParams(record)
    local exclusions = {record.model}
    if botsFolder then
        exclusions[#exclusions + 1] = botsFolder
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            exclusions[#exclusions + 1] = player.Character
        end
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = exclusions
    params.RespectCanCollide = true
    return params
end

local function liveGroundRouteCorridorSafe(record, root, waypoint, base)
    if not root or not root.Parent or not base or not base.Parent
        or not base:IsA("BasePart")
        or not base.Anchored or not base.CanCollide
        or base.Transparency >= 0.90
        or typeof(waypoint) ~= "Vector3" then
        return false
    end
    local top = base.Position.Y + base.Size.Y * 0.5
    local origin = base.CFrame:PointToObjectSpace(root.Position)
    if math.abs(origin.X) > base.Size.X * 0.5 - 1.5
        or math.abs(origin.Z) > base.Size.Z * 0.5 - 1.5
        or root.Position.Y < top + 1.2
        or root.Position.Y > top + 6.5 then
        return false
    end
    local travel = Vector3.new(waypoint.X - root.Position.X, 0,
        waypoint.Z - root.Position.Z)
    if travel.Magnitude > 14.5 then return false end
    local params = staticObstacleProbeParams(record)
    -- A human or one of the other six moving R15 bots may stand exactly
    -- above the midpoint. Only the REAL floor counts as ground support:
    -- filtering the downward sample to the server base prevents those
    -- mobile rigs from causing spurious route invalidations.
    local baseOnly = RaycastParams.new()
    baseOnly.FilterType = Enum.RaycastFilterType.Include
    baseOnly.FilterDescendantsInstances = {base}
    baseOnly.RespectCanCollide = true
    local function realBaseUnder(position)
        local hit = workspace:Raycast(
            position + Vector3.new(0, 4, 0),
            Vector3.new(0, -11, 0), baseOnly)
        return hit and hit.Instance == base and hit.Normal.Y >= 0.78
            and math.abs(hit.Position.Y - top) < 1.5
    end
    if not realBaseUnder(root.Position:Lerp(waypoint, 0.5))
        or not realBaseUnder(waypoint) then
        return false
    end
    -- Two body heights, not a single shoulder ray. Other non-anchored
    -- characters are not permanent walls and must not cause reroutes.
    if travel.Magnitude > 0.5 then
        local direction = travel.Unit * math.min(8, travel.Magnitude)
        for _, offset in ipairs({-1.15, 0.75}) do
            local hit = workspace:Raycast(
                root.Position + Vector3.new(0, offset, 0),
                direction, params)
            if hit and hit.Instance and hit.Instance.Anchored
                and hit.Instance.CanCollide
                and hit.Instance ~= base then
                return false
            end
        end
    end
    return true
end

local function advanceGroundNavigation(record, root, now)
    if AISurvivorRules.groundNavigationQueryTimedOut(
        record.groundNavigationPending,
        record.groundNavigationStartedAt, now
    ) then
        -- The async request may have left the bot holding its own
        -- temporary recovery fallback (including its current position).
        -- A timeout must release that owned target, or the bot can remain
        -- idle even though the obsolete ComputeAsync answer was canceled.
        -- Never erase a newer hazard, station or roaming decision.
        local pendingGoal = record.groundNavigationPendingGoal
        local fallback = record.groundNavigationFallbackTarget
        local ownsFallback = pendingGoal ~= nil and fallback ~= nil
            and record.failedTarget == pendingGoal
            and record.target == fallback
            and record.targetPart == nil
            and record.assistShield == nil and record.assistRelay == nil
            and record.spineControl == nil and record.districtTraverse == nil
            and record.signalInterestRoute == nil
        -- Invalidate the still-yielding callback before releasing the
        -- pending state. A late engine response cannot retarget this NPC.
        cancelGroundNavigation(record)
        if ownsFallback then
            record.recoveryWaypoint = nil
            record.recoveryCommitUntil = 0
            record.target = nil
            record.lastMoveTarget = nil
            record.lastProgressTarget = nil
            record.nextThink = 0
        end
        AISurvivorService.PerformanceDiagnostics.GroundRoutesTimedOut += 1
        record.nextGroundNavigationAt = now + 3
        if record.model then
            record.model:SetAttribute("BotPathTimeoutCount",
                (tonumber(record.model:GetAttribute(
                    "BotPathTimeoutCount")) or 0) + 1)
        end
    end
    local route = record.groundNavigation
    if not route then return end
    if #warningParts() > 0
        or hasDisaster("RisingLava") or hasDisaster("ShrinkingArena")
        or hasDisaster("Tornado") or hasDisaster("DisappearingPlatforms")
        or not record.inRound or currentState.phase ~= "round" then
        cancelGroundNavigation(record)
        record.target = nil
        record.nextThink = 0
        return
    end
    local target = route.points[route.index]
    local previousIndex = route.index
    local humanoid = record.model and record.model:FindFirstChildOfClass("Humanoid")
    -- A horizontal overlap is not a waypoint arrival while falling or
    -- jumping across the route. The bot must actually stand near the
    -- waypoint at the expected elevation before progressing the path
    -- or counting a completed long route.
    local grounded = humanoid and humanoid.Health > 0
        and humanoid.FloorMaterial ~= Enum.Material.Air
        and humanoid.SeatPart == nil
    while target and grounded do
        local dx = target.X - root.Position.X
        local dz = target.Z - root.Position.Z
        local previous = route.points[route.index - 1] or route.origin
        local upcoming = route.points[route.index + 1]
        if math.abs(target.Y - root.Position.Y) > 3.5
            or dx*dx + dz*dz > AISurvivorRules.groundNavigationArrivalRadius(
                previous, target, upcoming)^2 then
            break
        end
        route.index += 1
        target = route.points[route.index]
    end
    if route.index > previousIndex then
        -- Only REAL waypoint arrival counts as progress; a bot that
        -- repeatedly pushes into a wall cannot extend this deadline.
        route.expires = math.min(now + 11, route.hardExpires)
    end
    if not target then
        AISurvivorService.PerformanceDiagnostics.GroundRoutesCompleted += 1
        cancelGroundNavigation(record)
        record.target = nil
        record.nextThink = 0
        return
    end
    -- Check completion and authoritative hazard cancellation BEFORE
    -- treating a deadline as a failure. A bot physically at the final
    -- waypoint succeeded even if this AI pass began just after its TTL.
    -- Conversely a hazard interruption is not evidence that the goal
    -- itself was unreachable.
    if now > route.expires or now > route.hardExpires then
        -- Expiring a real NavMesh path means the ORIGINAL destination
        -- failed, not just its last temporary turn waypoint. Without
        -- quarantine, the very next normal roam decision can select
        -- the exact same blocked goal and restart an endless route loop.
        -- Use the same bounded failed-goal policy as a live invalidation.
        local badGoal = route.goal
        AISurvivorService.PerformanceDiagnostics.GroundRoutesExpired += 1
        cancelGroundNavigation(record)
        record.recoveryAttemptCount = AISurvivorRules.nextRecoveryAttempt(
            record.recoveryAttemptCount, record.lastRecoveryAt, now)
        record.lastRecoveryAt = now
        if typeof(badGoal) == "Vector3" then
            record.failedTarget = badGoal
            record.failedTargetUntil = now
                + AISurvivorRules.failedGoalCooldown(
                    record.recoveryAttemptCount)
        end
        record.target = nil
        record.targetPart = nil
        record.lastMoveTarget = nil
        record.lastProgressTarget = nil
        record.nextThink = 0
        if record.model then
            record.model:SetAttribute("BotGroundRouteExpiryCount",
                (tonumber(record.model:GetAttribute(
                    "BotGroundRouteExpiryCount")) or 0) + 1)
        end
        return
    end
    -- Corridor rays assume a grounded walking rig. A brief physical
    -- knock-up or fall can put the root outside the base-height band
    -- even though the same path is still usable after landing. Do not
    -- quarantine the ORIGINAL goal solely because of that airborne
    -- frame. The unchanged absolute/rolling TTL still bounds the wait,
    -- and urgent hazards were already handled above.
    if grounded and now >= (route.nextLiveCheckAt or 0) then
        route.nextLiveCheckAt = now + 0.72
            + ((record.slot or 1) % 3) * 0.12
        if arenaBase() ~= route.base
            or not liveGroundRouteCorridorSafe(
                record, root, target, route.base) then
            -- Never proceed into a newly blocked physical segment.
            -- Quarantine its original unreachable GOAL, not the nearby
            -- turn point, and invalidate any stale ComputeAsync token.
            local badGoal = route.goal or target
            AISurvivorService.PerformanceDiagnostics.GroundRoutesInvalidated += 1
            cancelGroundNavigation(record)
            record.recoveryAttemptCount = AISurvivorRules.nextRecoveryAttempt(
                record.recoveryAttemptCount, record.lastRecoveryAt, now)
            record.lastRecoveryAt = now
            record.failedTarget = badGoal
            record.failedTargetUntil = now
                + AISurvivorRules.failedGoalCooldown(record.recoveryAttemptCount)
            record.target = nil
            record.targetPart = nil
            record.lastMoveTarget = nil
            record.lastProgressTarget = nil
            record.nextThink = 0
            if record.model then
                record.model:SetAttribute("BotLiveRouteInvalidationCount",
                    (tonumber(record.model:GetAttribute(
                        "BotLiveRouteInvalidationCount")) or 0) + 1)
            end
            return
        end
    end
    if record.target ~= target then
        record.lastMoveTarget = nil
        record.lastProgressTarget = nil
    end
    record.target = target
    record.nextThink = now + 1
end

local function recoverIfStuck(record, humanoid, root, now)
    local goal = record.target
    if typeof(goal) ~= "Vector3" then
        record.lastProgressPosition = root.Position
        record.lastProgressTarget = nil
        record.lastProgressAt = now
        -- Do NOT clear the failure quarantine here. The old reset
        -- erased stuckCount immediately after abandoning a failed goal,
        -- so its >= 2 physical recovery branch was effectively dead.
        return false
    end
    if not record.lastProgressPosition
        or typeof(record.lastProgressTarget) ~= "Vector3"
        or (goal - record.lastProgressTarget).Magnitude > 5 then
        record.lastProgressPosition = root.Position
        record.lastProgressTarget = goal
        record.lastProgressAt = now
        return false
    end
    -- Deliberate pauses, grounded prompt-holds, airborne jumps and
    -- turn animations must NEVER be interpreted as failed navigation.
    local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
    local walking = now >= (record.turnPauseUntil or 0)
        and now >= (record.idleUntil or 0)
        and (Vector3.new(goal.X - root.Position.X, 0,
            goal.Z - root.Position.Z)).Magnitude > 3.5
    if not grounded or not walking then
        -- A pause or knockback is not a physical navigation failure.
        -- Restart the progress baseline at the current position so a
        -- subsequent grounded walking pass must actually spend 1.15s
        -- attempting movement before it can be classified as stalled.
        record.lastProgressPosition = root.Position
        record.lastProgressAt = now
        return false
    end
    local elapsed = now - (record.lastProgressAt or now)
    if elapsed < 1.15 then return false end
    local isStalled = AISurvivorRules.isGenuineStall(
        record.lastProgressPosition, root.Position,
        goal, elapsed, grounded, walking)
    record.lastProgressPosition = root.Position
    record.lastProgressAt = now
    if not isStalled then
        -- Genuine movement is not necessarily evidence that a previously
        -- blocked destination is now reachable. Keep the bounded recovery
        -- attempt history until its existing cooldown policy ages it out.
        -- Otherwise a bot making small successful sidesteps can retry
        -- the same obstacle forever from the same recovery side.
        record.stuckCount = 0
        return false
    end

    record.stuckCount = (record.stuckCount or 0) + 1
    AISurvivorService.PerformanceDiagnostics.StallDetections += 1
    -- A NavMesh waypoint is a transient segment, not the real goal.
    -- Once stuck on one segment, quarantine the ORIGINAL unreachable
    -- destination and never submit a new full route to that short
    -- waypoint. The small physical sidestep still avoids the actual
    -- current segment where progress stopped.
    local blockedGoal = record.groundNavigation
        and record.groundNavigation.goal
        or (record.groundNavigationPending
            and record.groundNavigationPendingGoal)
        or goal
    if record.groundNavigation then
        cancelGroundNavigation(record)
    end
    -- Preserve the recovery-side sequence even when short detours make
    -- progress. Previously that success reset stuckCount and sent every
    -- later attempt around the exact same obstacle on the same side.
    record.recoveryAttemptCount = AISurvivorRules.nextRecoveryAttempt(
        record.recoveryAttemptCount, record.lastRecoveryAt, now)
    record.lastRecoveryAt = now
    record.failedTarget = blockedGoal
    record.failedTargetUntil = now
        + AISurvivorRules.failedGoalCooldown(record.recoveryAttemptCount)
    -- Physical stations and expedition reservations cannot be held by
    -- an NPC walking into a wall. Release ALL claims before detouring.
    if record.assistShield then
        ArenaSkyShieldNetwork.releaseBot(record.model)
        record.assistShield = nil
        record.shieldHoldAt = nil
        record.nextShieldAt = now + 4
    end
    if record.assistRelay then
        TeamDashRelay.releaseBot(record.model)
        record.assistRelay = nil
        record.assistHoldAt = nil
        record.nextAssistAt = now + 4
    end
    -- A stalled bot must not lock the shared sky switch while recovering.
    SkySpineSwitchyard.releaseBot(record.model)
    record.spineControl = nil
    record.spineHoldAt = nil
    record.nextSpineAt = now + 7
    if record.districtTraverse then
        record.districtTraverse = nil
        record.nextDistrictTraverseAt = now + 9
        if record.model then
            record.model:SetAttribute("DistrictRouteStep", 0)
        end
    end
    if record.signalInterestRoute then
        record.signalInterestRoute = nil
        record.signalInterestUntil = 0
        record.nextSignalInterestAt = now + 6
    end
    -- React on the FIRST confirmed 1.15s stall. Repeated failures rotate
    -- which SIDE is tried first, but every step needs real body clearance
    -- plus floor at the midpoint and endpoint. Never PivotTo / warp.
    local recovery = nearbyRecoveryStep(
        record, root, goal, now)
    -- A wall wider than the local 6.5-stud rescue step needs a complete
    -- physical ground route. Start only after repeated stalls, or immediately
    -- when no local safe step exists. The existing detour remains usable
    -- while the asynchronous route is being computed.
    if recovery then
        AISurvivorService.PerformanceDiagnostics.LocalRecoveryFound += 1
    else
        AISurvivorService.PerformanceDiagnostics.LocalRecoveryFailed += 1
    end
    if not recovery or record.recoveryAttemptCount >= 2 then
        -- Count actual new requests, not every brain pass while an
        -- asynchronous NavMesh computation is already in flight.
        local alreadyNavigating = record.groundNavigationPending
            or record.groundNavigation ~= nil
        requestGroundNavigation(record, root, blockedGoal, now)
        if not alreadyNavigating and record.groundNavigationPending then
            AISurvivorService.PerformanceDiagnostics.GroundReplansRequested += 1
        end
    end
    record.targetPart = nil
    record.targetIsPad = false
    record.targetIsSkyrail = false
    record.skyrailDirection = nil
    record.turnPauseUntil = 0
    record.idleUntil = 0
    record.lastMoveTarget = nil
    record.moveDirection = Vector3.zero
    record.lastProgressPosition = root.Position
    record.lastProgressAt = now
    -- A validated detour must survive the next random rethink clock.
    -- A confirmed new stall or any urgent hazard can still interrupt.
    record.recoveryWaypoint = recovery
    record.recoveryCommitUntil = recovery and (now + 2.4) or 0
    record.target = recovery
    if record.groundNavigationPending then
        record.groundNavigationFallbackTarget = recovery or root.Position
        -- No safe sidestep: the brain will hold its actual position until
        -- a verified route arrives; preserve this as the expected fallback.
        if not recovery then record.target = root.Position end
    end
    record.lastProgressTarget = recovery
    record.nextThink = recovery and (now + 1.6) or 0
    if record.model then
        record.model:SetAttribute("BotStallRecoveryCount",
            (tonumber(record.model:GetAttribute(
                "BotStallRecoveryCount")) or 0) + 1)
        record.model:SetAttribute("BotRecoveryRouteFound",
            recovery ~= nil)
    end
    if recovery then
        humanoid:MoveTo(recovery)
    else
        -- No physically safe adjacent floor exists. Let the next
        -- ordinary server route selection choose a different objective;
        -- do not move to a guessed coordinate over void.
        humanoid:Move(Vector3.zero)
    end
    return true
end

-- Anticipate a real ANCHORED, colliding obstruction before the bot
-- walks repeatedly into it. This runs only when committing a new normal
-- ground roaming goal (at most once every ~2.4 s per bot); NOT per frame.
-- Use native physics and the existing five-ground-sample detour solver.
-- If no supported sidestep exists, request the existing asynchronous
-- PathfindingService route; never invent a waypoint or teleport a rig.
local function anticipateGroundObstacle(
    record, humanoid, root, goal, now)
    local base = arenaBase()
    if not base or not base:IsA("BasePart")
        or not base.CanCollide or typeof(goal) ~= "Vector3"
        or record.groundNavigation or record.groundNavigationPending then
        return nil
    end
    local floorY = base.Position.Y + base.Size.Y * 0.5
    local travel = Vector3.new(
        goal.X-root.Position.X, 0, goal.Z-root.Position.Z)
    local targetIsPlatform = record.targetPart
        and record.targetPart.Parent
        and record.targetPart.Parent.Name == "Platforms"
    local committed = record.targetIsPad == true
        or record.targetIsSkyrail == true
        or record.spineControl ~= nil
        or record.districtTraverse ~= nil
        or record.signalInterestRoute ~= nil
        or record.assistRelay ~= nil
        or record.assistShield ~= nil
        or targetIsPlatform == true
    if not AISurvivorRules.groundObstaclePreviewAllowed(
        now, record.nextObstaclePreviewAt or 0,
        currentState.phase == "round" and record.inRound,
        humanoid.FloorMaterial ~= Enum.Material.Air,
        hasDisaster("RisingLava") or hasDisaster("ShrinkingArena")
            or hasDisaster("DisappearingPlatforms")
            or hasDisaster("Tornado") or #warningParts() > 0,
        committed, root.Position.Y, floorY, goal.Y, travel.Magnitude
    ) then return nil end
    record.nextObstaclePreviewAt = now + 2.4
        + ((record.slot or 1) % 3) * 0.12
    local params = staticObstacleProbeParams(record)
    local standing = workspace:Raycast(
        root.Position + Vector3.new(0, 0.5, 0),
        Vector3.new(0, -6.5, 0), params
    )
    -- This never tries to navigate an elevated walkway as if it were the
    -- continuous ground floor, even when the vertical heights are close.
    if not standing or standing.Instance ~= base
        or standing.Normal.Y < 0.78 then return nil end

    local probe = travel.Unit * math.min(10, travel.Magnitude)
    local obstacle = nil
    for _, height in ipairs({-1.3, 0.65}) do
        local hit = workspace:Raycast(
            root.Position + Vector3.new(0, height, 0),
            probe, params
        )
        -- Other avatars are not permanent obstacles. Avoid seven bots
        -- constantly detouring each other when everyone starts together.
        if hit and hit.Instance and hit.Instance.CanCollide
            and hit.Instance.Anchored and hit.Instance ~= base then
            obstacle = hit.Instance
            break
        end
    end
    if not obstacle then return nil end

    -- One real blocked segment, no generic wander goal and no rig warp.
    local detour = nearbyRecoveryStep(record, root, goal, now)
    record.recoveryAttemptCount = AISurvivorRules.nextRecoveryAttempt(
        record.recoveryAttemptCount, record.lastRecoveryAt, now)
    record.lastRecoveryAt = now
    record.failedTarget = goal
    record.failedTargetUntil = now
        + AISurvivorRules.failedGoalCooldown(record.recoveryAttemptCount)
    record.lastMoveTarget = nil
    record.targetPart = nil
    record.targetIsPad = false
    record.targetIsSkyrail = false
    record.skyrailDirection = nil
    record.model:SetAttribute("BotObstaclePreviewCount",
        (tonumber(record.model:GetAttribute(
            "BotObstaclePreviewCount")) or 0) + 1)
    if detour then
        record.recoveryWaypoint = detour
        record.recoveryCommitUntil = now + 2.4
        record.model:SetAttribute("BotObstacleAvoidedCount",
            (tonumber(record.model:GetAttribute(
                "BotObstacleAvoidedCount")) or 0) + 1)
        return detour, 1.5
    end
    -- An unwalkable shortcut is not an invitation to run into the
    -- barrier. Safe, grounded pathfinding is already asynchronous.
    requestGroundNavigation(record, root, goal, now)
    if record.groundNavigationPending then
        record.groundNavigationFallbackTarget = root.Position
    end
    return root.Position, 0.65
end

-- Ordinary AI height-based jumps never fire across the eight flat
-- promenade decks and ten flat Sky Spine decks. Probe at a bounded
-- cadence ONLY while the bot is actually approaching a real elevated
-- platform; jump with native Humanoid physics if the intervening gap
-- has no footing and the far side has a safe, level landing.
local function tryPhysicalSkyGapJump(record, humanoid, root, now, target,
        emergencyDeck)
    local deck = emergencyDeck or record.targetPart
    if not deck or not deck:IsA("BasePart")
        or not deck.Parent or deck.Parent.Name ~= "Platforms"
        or typeof(target) ~= "Vector3"
        or humanoid.FloorMaterial == Enum.Material.Air
        or now < (record.nextRouteJumpAt or 0)
        or now < (record.nextGapProbeAt or 0) then return false end
    local base = arenaBase()
    if not base then return false end
    local delta = target - root.Position
    local travel = Vector3.new(delta.X, 0, delta.Z)
    if travel.Magnitude < 4.2 or travel.Magnitude > 34
        or root.Position.Y < base.Position.Y + base.Size.Y * 0.5 + 7
        or not AISurvivorRules.platformAvailable(
            deck.CanCollide, deck.Transparency,
            deck:GetAttribute("CollapsePhase"),
            deck:GetAttribute("BridgeShutterPhase")
        ) then return false end

    record.nextGapProbeAt = now + 0.20
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {record.model}
    params.RespectCanCollide = true
    local forward = travel.Unit
    local function floorAt(distance, allowThreatenedOrigin)
        local result = workspace:Raycast(
            root.Position + forward * distance + Vector3.new(0, 1.5, 0),
            Vector3.new(0, -7, 0),
            params
        )
        if result and result.Normal.Y >= 0.78
            and result.Instance and result.Instance.CanCollide
            and (AISurvivorRules.platformAvailable(
                result.Instance.CanCollide,
                result.Instance.Transparency,
                result.Instance:GetAttribute("CollapsePhase"),
                result.Instance:GetAttribute("BridgeShutterPhase")
            ) or (allowThreatenedOrigin == true
                and emergencyDeck ~= nil
                and result.Instance == record.platformThreat
                and result.Instance.Transparency < 0.90))
        then
            return result
        end
        return nil
    end

    -- Warning platforms remain physically solid until the "Gone"
    -- transition. Allow standing on that EXACT live warning surface
    -- for takeoff; the destination must always be a safe ready deck.
    local origin = floorAt(0, emergencyDeck ~= nil)
    if not origin or not origin.Instance.Parent
        or origin.Instance.Parent.Name ~= "Platforms" then return false end
    local gap = floorAt(3.4)
    if gap then return false end
    local landing = floorAt(7.2)
    -- A nearby unrelated deck does not prove that the SELECTED next
    -- waypoint is reachable. Jump only toward its exact solid floor,
    -- with a verified centerline gap within normal Humanoid reach.
    if not landing or landing.Instance ~= deck
        or not AISurvivorRules.neighboringPhysicalDeck(
            origin.Instance.CFrame, origin.Instance.Size,
            deck.CFrame, deck.Size
        ) then return false end
    if AISurvivorRules.skyGapJumpReady(
        true, root.Position.Y - (base.Position.Y + base.Size.Y * 0.5),
        travel.Magnitude, origin.Position.Y, false, landing.Position.Y
    ) then
        humanoid.Jump = true
        record.nextRouteJumpAt = now + 0.80
        return true
    end
    return false
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

    -- Narrow server-owned sky crossings need accurate physical heading,
    -- not a blended previous turn that curves off a 12-stud walkway.
    -- Ordinary ground roaming keeps its humanlike steering inertia.
    -- Committed cooperative console approaches are deliberate paths:
    -- humanlike wandering curves and reaction pauses can pull the rig
    -- out of the real hold range even after an AI chose to help someone.
    local direct = urgent == true
        or (record.recoveryWaypoint
            and record.target == record.recoveryWaypoint
            and now < (record.recoveryCommitUntil or 0))
        or record.spineControl ~= nil
        or record.assistShield ~= nil
        or record.assistRelay ~= nil
        or (record.targetIsPad == true and horizontal.Magnitude < 10)
        or record.groundNavigation ~= nil
        or AISurvivorRules.committedWorldRoute(
            record.targetIsSkyrail, record.targetPart,
            record.districtTraverse ~= nil
        )

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
        or record.inRound
        or voteActive
    then
        return false
    end

    local teammate = record.profile.Id == "Balanced"
    record.nextEmoteAt = now + (teammate and 3 or 5)
        + math.random() * (teammate and 5 or 8)
    if math.random() > (record.profile.GestureChance or 0.46) then
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

    if math.random() < (record.profile.Id == "Bold" and 0.60 or 0.20) then
        humanoid.Jump = true
    end
    return true
end

-- Brief, low-frequency reactions to nearby competitors. Unlike scripted
-- chat, these visible glances, celebratory hops and teammate jump-mirroring
-- use the normal rig and never impersonate a connected player.
local function maybeRoundGesture(record, humanoid, root, now)
    if not record.inRound or currentState.phase ~= "round"
        or now < (record.nextRoundGestureAt or 0)
    then
        return false
    end

    -- A cosmetic greeting must never interrupt a real navigation route,
    -- physical platform crossing or a cooperative interaction. Keep the
    -- cooldown short when busy so a free bot can still acknowledge peers.
    if record.groundNavigation or record.groundNavigationPending
        or record.districtTraverse or record.signalInterestRoute
        or record.assistRelay or record.assistShield
        or record.spineControl or record.targetIsSkyrail
        or record.targetIsPad
        -- An actual obstacle-recovery detour is a committed physical
        -- action, not free time for a greeting or a show-off jump.
        or (record.recoveryWaypoint
            and record.target == record.recoveryWaypoint
            and now < (record.recoveryCommitUntil or 0))
        -- Even if no impact currently intersects this bot, warning
        -- markers can appear during its next short social pause. A
        -- disaster warning takes priority over optional social flair.
        or #warningParts() > 0
        or humanoid.FloorMaterial == Enum.Material.Air
        or humanoid.SeatPart ~= nil then
        record.nextRoundGestureAt = now + 2
        return false
    end

    record.nextRoundGestureAt = now + 5.5 + math.random() * 5.5
    local _, pressure = decisionTraits(record)
    if pressure > 0.50 or record.threat or record.platformThreat
        or currentState.finalRush == true
    then
        return false
    end

    local nearby = nil
    local nearbyHumanoid = nil
    local nearest = record.profile.Id == "Balanced" and 17 or 13
    local function consider(candidateRoot, candidateHumanoid)
        if not candidateRoot or not candidateRoot:IsA("BasePart")
            or not candidateHumanoid or candidateHumanoid.Health <= 0
        then
            return
        end
        local difference = candidateRoot.Position - root.Position
        local horizontal = Vector3.new(difference.X, 0, difference.Z).Magnitude
        if horizontal < nearest and math.abs(difference.Y) < 5 then
            nearest = horizontal
            nearby = candidateRoot
            nearbyHumanoid = candidateHumanoid
        end
    end

    -- Prefer actual round participants. NPC-to-NPC gestures fill the gaps
    -- only when nobody eligible is standing close to this AI.
    for _, player in ipairs(Players:GetPlayers()) do
        if player:GetAttribute("RoundParticipant") == true
            and player:GetAttribute("RoundEliminated") ~= true
        then
            local character = player.Character
            consider(
                character and character:FindFirstChild("HumanoidRootPart"),
                character and character:FindFirstChildOfClass("Humanoid")
            )
        end
    end
    if not nearby then
        for _, other in ipairs(records) do
            if other ~= record and other.inRound and other.alive
                and other.model and other.model.Parent
            then
                consider(
                    other.model:FindFirstChild("HumanoidRootPart"),
                    other.model:FindFirstChildOfClass("Humanoid")
                )
            end
        end
    end
    if not nearby then
        return false
    end

    -- An acknowledgement is legible on mobile but lasts only a fraction
    -- of a second. The urgent-hazard path runs before every gesture check.
    local look = Vector3.new(nearby.Position.X, root.Position.Y, nearby.Position.Z)
    if (look - root.Position).Magnitude > 0.5 then
        root.CFrame = root.CFrame:Lerp(CFrame.lookAt(root.Position, look), 0.32)
    end

    if humanoid.FloorMaterial ~= Enum.Material.Air
        and not hasDisaster("LowGravity")
    then
        local peerState = nearbyHumanoid:GetState()
        local peerJumping = peerState == Enum.HumanoidStateType.Jumping
            or peerState == Enum.HumanoidStateType.Freefall
        if record.profile.Id == "Bold" and math.random() < 0.70 then
            -- The rival loves a show-off hop on the way past someone.
            humanoid.Jump = true
        elseif record.profile.Id == "Balanced" and peerJumping
            and math.random() < 0.78
        then
            -- Copy a teammate's visible movement occasionally, not blindly.
            humanoid.Jump = true
        end
    end

    local greeting = record.profile.Id == "Cautious" and "STAY SHARP!"
        or (record.profile.Id == "Bold" and "RACE YOU!" or "LET'S GO!")
    showBotSignal(record, greeting, now)

    if record.profile.Id == "Balanced" and nearest < 10 then
        -- A quick friendly nod, never a long stop in the danger zone.
        record.idleUntil = now + 0.18
        humanoid:Move(Vector3.zero)
        return true
    end
    return false
end

local function stepRecord(record, now)
    local model = record.model
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    local root = model and model:FindFirstChild("HumanoidRootPart")
    if not model or not model.Parent or not humanoid or humanoid.Health <= 0 or not root then
        return
    end

    if (record.signalExpire or 0) > 0 and now >= record.signalExpire then
        local label = record.roleLabel
        if label and label.Parent then
            label.Text = ""
            label.Visible = false
            local billboard = label.Parent
            if billboard and billboard:IsA("BillboardGui") then
                billboard.Enabled = false
            end
        end
        record.signalExpire = 0
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

    -- Survival has priority over the bot's humanlike hesitation, idle,
    -- turn pause, and stuck-recovery routines. Previously these routines
    -- returned before warning detection, allowing a bot to stand still
    -- through an incoming impact or a collapsing deck.
    local urgentTarget = nil
    if record.inRound and currentState.phase == "round" then
        urgentTarget = disappearingPlatformEscape(record, root, now)
        if not urgentTarget then
            urgentTarget = immediateThreat(record, root, now)
        end
        if not urgentTarget then
            urgentTarget = floorSweepEscape(record, root, now)
        end
        if not urgentTarget then
            urgentTarget = skybridgeShutterEscape(record, root, now)
        end
        -- An impossible elevated retreat must not hide a genuine
        -- meteor, bomb, sweep or shutter escape found above.
        urgentTarget = AISurvivorRules.collapseFallbackTarget(
            urgentTarget, record.collapseEscapeHolding, root.Position
        )
    end

    if urgentTarget and (record.groundNavigation
        or record.groundNavigationPending) then
        cancelGroundNavigation(record)
    elseif not urgentTarget then
        advanceGroundNavigation(record, root, now)
    end

    -- Do not teleport or auto-activate AI. Hold time and proximity are
    -- checked AGAIN against the actual model on the shield service.
    -- An imminent impact always cancels the cooperative approach.
    if record.assistShield then
        local approach, station = nil, nil
        if not urgentTarget and record.inRound
            and currentState.phase == "round"
            and not hasDisaster("ShrinkingArena")
            and not hasDisaster("RisingLava")
            and not hasDisaster("Tornado") then
            approach, station = ArenaSkyShieldNetwork.botOpportunity(
                record.model, now, record.assistShield
            )
        end
        if not station then
            ArenaSkyShieldNetwork.releaseBot(record.model)
            record.assistShield = nil
            record.shieldHoldAt = nil
            record.target = nil
            record.targetPart = nil
            record.nextThink = 0
            record.nextShieldAt = now + 4
        else
            record.target = approach
            record.targetPart = nil
            record.targetIsPad = false
            record.nextThink = now + 1.1
            local flat = Vector3.new(
                approach.X - root.Position.X, 0,
                approach.Z - root.Position.Z
            ).Magnitude
            -- A shockwave jump, fall or interrupted landing cancels the
            -- physical hold. Merely staying horizontally inside the
            -- console radius while airborne cannot complete it.
            if flat <= 4.3 and humanoid.FloorMaterial ~= Enum.Material.Air
                and humanoid.SeatPart == nil and not humanoid.Jump then
                if not record.shieldHoldAt then
                    record.shieldHoldAt = now + ArenaSkyShieldNetwork.HoldSeconds
                end
                humanoid:Move(Vector3.zero)
                if now < record.shieldHoldAt then return end
                local helped = ArenaSkyShieldNetwork.activateBot(
                    record.model, now, record.assistShield
                )
                ArenaSkyShieldNetwork.releaseBot(record.model)
                record.assistShield = nil
                record.shieldHoldAt = nil
                record.target = nil
                record.nextThink = 0
                -- A contested/expired station is not a successful assist.
                -- Retry other real opportunities sooner without spamming.
                record.nextShieldAt = now + (helped and 14 or 4)
                if helped then
                    showBotSignal(record, "SHIELD UP!", now)
                    record.model:SetAttribute("BotTeamShieldsUsed",
                        (tonumber(record.model:GetAttribute(
                            "BotTeamShieldsUsed")) or 0) + 1)
                end
            else
                record.shieldHoldAt = nil
            end
        end
    end

    -- A planned team-network action is a REAL WALK on an existing
    -- elevated platform, followed by the same 0.7-second physical hold
    -- as a human. Only a raycast-verified supporting deck can renew the
    -- exclusive claim. Hazards immediately cancel, never trump evasion.
    if record.inRound and currentState.phase == "round"
        and not urgentTarget and not record.assistShield
        and not record.assistRelay and not record.districtTraverse
        -- A newly discovered switch must not hijack a verified NavMesh
        -- route, signal mission, narrow skyrail or an impulse-pad goal.
        -- A bot already holding the switch may always finish/cancel it.
        and (record.spineControl ~= nil
            or (not record.groundNavigation
                and not record.groundNavigationPending
                and not record.signalInterestRoute
                and not record.targetIsSkyrail
                and not record.targetIsPad))
        and not hasDisaster("ShrinkingArena")
        and not hasDisaster("RisingLava")
        and not hasDisaster("Tornado") then
        local approach, switchCore
        if record.spineControl then
            approach, switchCore = SkySpineSwitchyard.botApproach(
                record.model, now, record.spineControl)
        else
            switchCore = SkySpineSwitchyard.botOpportunity(
                record.model, now)
            if switchCore then
                approach = Vector3.new(
                    switchCore.Position.X, root.Position.Y,
                    switchCore.Position.Z)
            end
        end
        if switchCore then
            record.spineControl = switchCore
            record.target = approach
            record.targetPart = nil
            record.targetIsPad = false
            record.targetIsSkyrail = false
            record.nextThink = now + 1.2
            local close = SkySpineSwitchyard.botOpportunity(
                record.model, now, switchCore) == switchCore
            -- Require continuous grounded contact for the whole
            -- switchyard hold, not only at final server activation.
            if close and humanoid.FloorMaterial ~= Enum.Material.Air
                and humanoid.SeatPart == nil and not humanoid.Jump then
                if not record.spineHoldAt then
                    record.spineHoldAt =
                        now + SkySpineSwitchyard.HoldSeconds
                end
                humanoid:Move(Vector3.zero)
                if now < record.spineHoldAt then return end
                local connected = SkySpineSwitchyard.activateBot(
                    record.model, switchCore)
                SkySpineSwitchyard.releaseBot(record.model)
                record.spineControl = nil
                record.spineHoldAt = nil
                record.nextSpineAt = now + 12
                record.target = nil
                record.nextThink = 0
                if connected then
                    record.model:SetAttribute("BotSkySpineConnected", true)
                    record.model:SetAttribute("BotSkyNetworkConnected", true)
                    showBotSignal(record, "3 ROUTES OPEN!", now)
                end
            else
                record.spineHoldAt = nil
                -- No early return: ordinary MoveTo performs the approach
                -- with normal speed and existing collision, while the
                -- stuck-recovery path can still abandon a blocked goal.
            end
        elseif record.spineControl then
            SkySpineSwitchyard.releaseBot(record.model)
            record.spineControl = nil
            record.spineHoldAt = nil
            record.nextSpineAt = now + 5
            record.target = nil
            record.targetPart = nil
            record.nextThink = 0
        end
    elseif record.spineControl then
        SkySpineSwitchyard.releaseBot(record.model)
        record.spineControl = nil
        record.spineHoldAt = nil
        record.nextSpineAt = now + 5
        if urgentTarget then
            record.target = nil
            record.targetPart = nil
            record.nextThink = 0
        end
    end

    -- Physical cooperation never outranks a real impact/escape, and
    -- stale station claims are released as soon as the human beneficiary
    -- leaves, the deck retracts or another participant uses the console.
    if record.assistRelay then
        local assistPoint, station = nil, nil
        if not urgentTarget and record.inRound
            and currentState.phase == "round"
            and not hasDisaster("ShrinkingArena")
            and not hasDisaster("RisingLava")
            and not hasDisaster("Tornado") then
            assistPoint, station = TeamDashRelay.botOpportunity(
                record.model, now, record.assistRelay
            )
        end
        if not station then
            TeamDashRelay.releaseBot(record.model)
            record.assistRelay = nil
            record.assistHoldAt = nil
            record.target = nil
            record.targetPart = nil
            record.nextThink = 0
            record.nextAssistAt = now + 4
        else
            record.target = assistPoint
            record.targetPart = nil
            record.targetIsPad = false
            record.nextThink = now + 1.2
            local delta = assistPoint - root.Position
            local horizontal = Vector3.new(delta.X, 0, delta.Z).Magnitude
            if horizontal <= 4.3
                and humanoid.FloorMaterial ~= Enum.Material.Air
                and humanoid.SeatPart == nil and not humanoid.Jump then
                -- Mimic the same physical hold required of a human
                -- (0.65s), without fabricating ProximityPrompt.Triggered.
                -- Both model position and real beneficiaries are
                -- rechecked by the relay before granting any charge.
                if not record.assistHoldAt then
                    record.assistHoldAt = now + TeamDashRelay.HoldSeconds
                end
                humanoid:Move(Vector3.zero)
                if now < record.assistHoldAt then return end
                local helped = TeamDashRelay.activateBot(
                    record.model, now, record.assistRelay
                )
                TeamDashRelay.releaseBot(record.model)
                record.assistRelay = nil
                record.assistHoldAt = nil
                record.target = nil
                record.nextThink = 0
                -- A failed activation must not sideline this teammate
                -- for the same cooldown as a successful team charge.
                record.nextAssistAt = now + (helped and 13 or 4)
                if helped then
                    showBotSignal(record, "TEAM UP!", now)
                    record.model:SetAttribute("BotTeamDashRelaysUsed",
                        (tonumber(record.model:GetAttribute(
                            "BotTeamDashRelaysUsed")) or 0) + 1)
                end
            else
                record.assistHoldAt = nil
            end
        end
    end

    -- A timed signal may close while the bot is holding a long movement
    -- target. Verify the *actual* server station each brain tick so rivals
    -- stop running toward dead events instead of wasting another 2-5s.
    -- Reactions use the original AI nameplate, never player chat.
    if not urgentTarget and record.signalInterestRoute
        and record.inRound and currentState.phase == "round"
    then
        local trackedRoute = record.signalInterestRoute
        local _, arena = arenaParts()
        local signals = arena and arena:FindFirstChild("DistrictSignalRush")
        local station = signals and signals:FindFirstChild(
            "SignalStation" .. tostring(trackedRoute))
        local foundation = station and station:FindFirstChild("Foundation")
        local endAt = signals and tonumber(signals:GetAttribute("SignalEndsAt"))
        local stillOpen = signals
            and tonumber(signals:GetAttribute("SignalRoute")) == trackedRoute
            and station and station:GetAttribute("SignalActive") == true
            and foundation and foundation:IsA("BasePart")
            and not hasDisaster("ShrinkingArena")
            and not hasDisaster("RisingLava")
            and not hasDisaster("Tornado")
            and not hasDisaster("DisappearingPlatforms")
            and currentState.finalRush ~= true
            and (not endAt or endAt <= 0
                or workspace:GetServerTimeNow() + 0.30 < endAt)
        local reached = false
        if stillOpen then
            local delta = foundation.Position - root.Position
            local flat = Vector3.new(delta.X, 0, delta.Z).Magnitude
            reached = flat < 6.8 and math.abs(delta.Y) < 6.5
        end
        if not stillOpen or reached then
            if reached and record.model then
                record.model:SetAttribute("DistrictSignalWitnessed", trackedRoute)
                showBotSignal(record, "FOUND IT!", now)
            end
            record.signalInterestRoute = nil
            record.signalInterestUntil = 0
            record.nextSignalInterestAt = now + (reached and 12 or 4)
            record.target = nil
            record.targetPart = nil
            record.lastMoveTarget = nil
            record.nextThink = 0
        end
    end

    if not urgentTarget then
        if recoverIfStuck(record, humanoid, root, now) then
            return
        end

        if not record.spineControl
            and not (record.recoveryWaypoint
                and record.target == record.recoveryWaypoint
                and now < (record.recoveryCommitUntil or 0)) then
            if maybeSocialGesture(record, humanoid, root, now) then
                return
            end

            if maybeRoundGesture(record, humanoid, root, now) then
                return
            end
        end

        if now < (record.idleUntil or 0)
            and not record.spineControl
            and not record.assistShield
            and not record.assistRelay then
            humanoid:Move(Vector3.zero)
            return
        end
    end

    -- A raised terrace is not reachable by walking toward its centre:
    -- make a normal Humanoid jump near its leading edge. This does not
    -- increase jump power, speed or grant a physics advantage.
    if not urgentTarget and record.districtTraverse
        and record.targetPart and record.targetPart.Parent
        and humanoid.FloorMaterial ~= Enum.Material.Air
        and now >= (record.nextRouteJumpAt or 0)
    then
        local deck = record.targetPart
        local top = deck.Position.Y + deck.Size.Y * 0.5
        local delta = deck.Position - root.Position
        local gap = Vector3.new(delta.X, 0, delta.Z).Magnitude
        local rise = top + 2.5 - root.Position.Y
        if rise > 1.4 and rise < 7 and gap > 3.2 and gap < 13.0 then
            humanoid.Jump = true
            record.nextRouteJumpAt = now + 0.72
        end
    end

    if not urgentTarget and not record.districtTraverse
        and not record.spineControl
        -- Personality jumps are cosmetic. A hop while approaching or
        -- holding a real relay/shield station can break the physical
        -- hold and prevent a useful action for a nearby human.
        and not record.assistRelay
        and not record.assistShield
        and not record.signalInterestRoute
        -- The ground route was validated for walking, not random
        -- airborne shortcuts across its narrow physical corridor.
        and not record.groundNavigation
        and not record.groundNavigationPending
        and not (record.recoveryWaypoint
            and record.target == record.recoveryWaypoint
            and now < (record.recoveryCommitUntil or 0))
        and now >= record.nextJump then
        local _, pressure = decisionTraits(record)
        local jumpChance = AISurvivorRules.freeJumpChance(
            record.profile.JumpChance,
            pressure,
            hasDisaster("LowGravity")
        )
        -- All-seven-bots pogo-jumping mid-disaster looked artificial in
        -- actual Android play. Keep purposeful ascent and warning escapes
        -- above; casual personality jumps are rare on live terrain and
        -- never attempted in the air or on a committed narrow route.
        local livelyRound = record.inRound
            and currentState.phase == "round"
        if livelyRound then jumpChance *= 0.20 end
        if humanoid.FloorMaterial ~= Enum.Material.Air
            and not record.targetIsSkyrail
            and record.targetPart == nil
            and math.random() < jumpChance then
            humanoid.Jump = true
        end
        record.nextJump = now + 1.8 + math.random() * 3.4
    end

    if record.inRound and (currentState.phase == "ready" or currentState.phase == "round") then
        -- The pad may launch a bot into an impact footprint while an active
        -- warning requires the opposite movement. Save mobility for safety.
        if not urgentTarget then
            tryPadImpulse(record, root, now)
        end

        if urgentTarget then
            -- Any real disaster outranks a local obstacle sidestep.
            record.recoveryWaypoint = nil
            record.recoveryCommitUntil = 0
            record.districtTraverse = nil
            record.signalInterestRoute = nil
            record.signalInterestUntil = 0
            record.nextSignalInterestAt = now + 4.5
            record.nextDistrictTraverseAt = now + 4.5
            -- An imminent hazard cancels cosmetic indecision immediately.
            -- No new speed/health advantage: locomotion remains Humanoid
            -- movement with the existing server-owned target clamping.
            record.idleUntil = 0
            record.turnPauseUntil = 0
            record.targetIsPad = false
            record.targetIsSkyrail = false
            record.skyrailDirection = nil
            record.targetPart = nil
            -- Separation offsets would push a Skybridge escape target off
            -- the narrow deck. Keep the server-planned centre-line path.
            local skybridgeEscape = (record.platformThreat
                    and record.platformThreat.Parent
                    and record.platformThreat:GetAttribute("ChaosSkybridge") == true)
                or (record.shutterThreat and record.shutterThreat.Parent
                    and (record.shutterThreat:GetAttribute("ShutterPhase") == "Warning"
                        or record.shutterThreat:GetAttribute("ShutterPhase") == "Raising"
                        or record.shutterThreat:GetAttribute("ShutterPhase") == "Raised"))
            -- Both Classic and Harbor sweeps are real spatial hazards.
            -- NEVER add the social sidestep jitter to the server-derived
            -- floor exit: Harbor used to miss this check, steering NPCs
            -- straight back through an active cargo lane.
            local sweepBand = record.gridSweepThreat
            local sweepPhase = sweepBand
                and (sweepBand:GetAttribute("GridSweepPhase")
                    or sweepBand:GetAttribute("HarborSweepPhase"))
            local floorSweepEscape = sweepBand
                and sweepBand.Parent ~= nil
                and (sweepPhase == "Warning" or sweepPhase == "Pulse")
            -- saferThreatEscape already validated this exact destination
            -- against *every* live bomb and meteor corridor and real floor
            -- support. Adding a random social separation offset afterward
            -- can put a bot straight back into an impact circle or a gap.
            -- Keep its deliberate escape vector; regular roaming still
            -- uses realistic bot-to-bot spacing.
            local warnedEscape = record.escapeWarning
                and record.escapeWarning.Parent
                and record.escapeTarget == urgentTarget
            -- An imminent elevated collapse has a prevalidated real
            -- landing. Social spacing must not push that target off it.
            record.target = (skybridgeEscape or floorSweepEscape
                or warnedEscape or record.collapseEscapeDeck
                or record.collapseEscapeHolding)
                and urgentTarget or separateTarget(record, urgentTarget)
            record.nextThink = now + 0.55
        end

        -- The short arena rethink clock must not strand a runner on an
        -- already-reached terrace for five seconds. Recheck the physical
        -- landing at a bounded rate, advance only after a real landing,
        -- and never run this optional exploration check during danger.
        if not urgentTarget and record.districtTraverse
            and now >= (record.nextDistrictStageCheckAt or 0)
        then
            record.nextDistrictStageCheckAt = now + 0.42
            local previousStage = record.districtTraverse.stage
            local stageTarget, stageHold = districtTraverseTarget(
                record, root, now)
            if not record.districtTraverse then
                -- Fell, expired or disappeared: do not keep walking to the
                -- old high deck as if the aborted route still existed.
                record.target = nil
                record.targetPart = nil
                record.targetIsPad = false
                record.nextThink = 0
            elseif record.districtTraverse.stage ~= previousStage
                and stageTarget then
                record.target = stageTarget
                record.nextThink = now + stageHold
                record.lastMoveTarget = nil
            end
        end

        if record.targetPart and record.targetPart.Parent then
            if record.targetIsPad then
                record.target = record.targetPart.Position + Vector3.new(0, 1.8, 0)
            elseif record.targetPart.Parent.Name == "HelixCircuit" then
                if record.targetPart:GetAttribute("OrbitalHelixRamp") == true then
                    record.target = record.targetPart.Position
                        + record.targetPart.CFrame.UpVector
                            * (record.targetPart.Size.Y * 0.5 + 2.4)
                else
                    record.target = nil
                    record.targetPart = nil
                    record.nextThink = 0
                end
            elseif record.targetPart.Parent.Name == "Platforms" then
                if not AISurvivorRules.platformAvailable(
                    record.targetPart.CanCollide,
                    record.targetPart.Transparency,
                    record.targetPart:GetAttribute("CollapsePhase"),
                    record.targetPart:GetAttribute("BridgeShutterPhase")
                ) then
                    record.target = nil
                    record.targetPart = nil
                    record.targetIsSkyrail = false
                    record.skyrailDirection = nil
                    record.nextThink = 0
                elseif record.targetIsSkyrail
                    and record.targetPart:GetAttribute("ChaosSkybridge") == true
                then
                    -- Keep the same far-side destination when a moving
                    -- physical deck changes size/position during the round.
                    record.target = AISurvivorRules.skyrailExitTarget(
                        record.targetPart.CFrame, record.targetPart.Size,
                        record.skyrailDirection)
                    if not record.target then
                        record.targetPart = nil
                        record.targetIsSkyrail = false
                        record.nextThink = 0
                    end
                elseif hasDisaster("ShrinkingArena") then
                    record.target = record.targetPart.Position
                        + Vector3.new(0, record.targetPart.Size.Y * 0.5 + 2.4, 0)
                end
            end
        elseif record.targetPart then
            record.target = nil
            record.targetPart = nil
            record.targetIsPad = false
            record.targetIsSkyrail = false
            record.skyrailDirection = nil
            record.nextThink = 0
        end

        -- A freshly spawned server warning can cut across an ordinary
        -- walking route while its bot is still OUTSIDE the warning circle.
        -- The local impact dodge would not yet fire, so do not let the
        -- existing rethink timer send the bot back into that future blast.
        -- Check the event-owned warning cache only when its version changes,
        -- not every physics frame, and never replace committed platform
        -- crossings, real console holds, or an emergency escape.
        if currentState.phase == "round"
            and not urgentTarget
            and record.routeWarningVersion ~= warningVersion then
            record.routeWarningVersion = warningVersion
            if record.target and not record.groundNavigation
                and not record.groundNavigationPending
                and not record.districtTraverse
                and not record.signalInterestRoute
                and not record.assistShield
                and not record.assistRelay
                and not record.spineControl
                and not record.targetIsSkyrail
                and not AISurvivorRules.committedWorldRoute(
                    record.targetIsSkyrail, record.targetPart, false
                ) then
                for _, warning in ipairs(warningParts()) do
                    if AISurvivorRules.newImpactIntersectsEscape(
                        root.Position, record.target, warning.Name,
                        warning.Position,
                        math.max(warning.Size.X, warning.Size.Z) * 0.5,
                        warning:GetAttribute("WarningEndSize")
                    ) then
                        record.target = nil
                        record.targetPart = nil
                        record.targetIsPad = false
                        record.lastMoveTarget = nil
                        record.nextThink = 0
                        record.idleUntil = 0
                        record.turnPauseUntil = 0
                        record.model:SetAttribute("BotHazardRouteInvalidations",
                            (tonumber(record.model:GetAttribute(
                                "BotHazardRouteInvalidations")) or 0) + 1)
                        break
                    end
                end
            end
        end

        if currentState.phase == "round"
            and not urgentTarget
            -- A deliberate NavMesh fallback or live waypoint must not be
            -- discarded by the unrelated random roam reconsideration.
            -- Pending requests are already bounded by the timeout guard.
            and not record.groundNavigationPending
            and not record.groundNavigation
            and not record.districtTraverse
            and not record.signalInterestRoute
            and not record.assistShield
            and not record.assistRelay
            and not record.spineControl
            and record.target
            and not record.targetIsPad
            and not AISurvivorRules.committedWorldRoute(
                record.targetIsSkyrail, record.targetPart,
                record.districtTraverse ~= nil
            )
            and now >= (record.nextReconsiderAt or 0)
            and not (record.recoveryWaypoint
                and record.target == record.recoveryWaypoint
                and now < (record.recoveryCommitUntil or 0))
        then
            record.nextReconsiderAt = now + 1.4 + math.random() * 2.4
            local traits = decisionTraits(record)
            if math.random() < (traits.ReconsiderChance or 0) then
                record.target = nil
                record.targetPart = nil
                record.targetIsSkyrail = false
                record.skyrailDirection = nil
                record.nextThink = 0
            end
        end

        if not urgentTarget and record.target
            and not record.groundNavigation
            -- The pending path's physical fallback is deliberately a
            -- temporary waypoint (possibly the bot's own position).
            -- Do not clear it as "arrived" before ComputeAsync returns.
            and not record.groundNavigationPending
            and not record.districtTraverse
            and not record.signalInterestRoute
            and not record.assistShield
            and not record.assistRelay
            and not record.spineControl
            and (root.Position - record.target).Magnitude < 4.2
        then
            record.target = nil
            record.targetPart = nil
            record.targetIsPad = false
            record.targetIsSkyrail = false
            record.skyrailDirection = nil
            local _, pressure = decisionTraits(record)
            -- Competitors don't stand still for a second after every
            -- waypoint. The daredevil sometimes showboats, while the
            -- tactician tends to stay in motion.
            local basePause = record.profile.Id == "Bold" and 0.24
                or (record.profile.Id == "Balanced" and 0.18 or 0.10)
            local pauseChance = basePause * (1 - pressure * 0.58)
            if math.random() < pauseChance then
                record.idleUntil = now + 0.16 + math.random() * 0.55
                humanoid:Move(Vector3.zero)
                return
            end
        end

        -- Preserve the pending request's fallback for its bounded
        -- six-second lifetime. Replanning an ordinary roam target on
        -- every brain pass invalidated the asynchronous result before
        -- it could be accepted. Urgent threats still cancel it above.
        if not record.groundNavigation
            and not record.groundNavigationPending
            and not record.assistShield
            and not record.assistRelay
            and not record.spineControl
            and not (record.recoveryWaypoint
                and record.target == record.recoveryWaypoint
                and now < (record.recoveryCommitUntil or 0))
            and AISurvivorRules.shouldReplanTarget(
            currentState.phase,
            now,
            record.nextThink,
            record.target,
            record.targetIsSkyrail,
            record.targetPart,
            urgentTarget ~= nil,
            record.districtTraverse ~= nil
        ) then
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
            -- Temporarily reject the destination that just made the
            -- NPC oscillate in place. Valid new threats override this.
            if not urgentTarget and target and record.failedTarget
                and now < (record.failedTargetUntil or 0)
                and (Vector3.new(target.X - record.failedTarget.X, 0,
                    target.Z - record.failedTarget.Z)).Magnitude < 11 then
                local alternative = nearbyRecoveryStep(
                    record, root, record.failedTarget, now
                )
                if alternative then
                    target, hold = alternative, 1.2
                    record.recoveryWaypoint = alternative
                    record.recoveryCommitUntil = now + 2.4
                else
                    -- The physical detour solver found no safe support.
                    -- Never fall through to the quarantined wall goal:
                    -- remain on actual footing and reconsider next tick.
                    -- An already-pending asynchronous ground route can
                    -- still replace this hold with validated waypoints.
                    target, hold = root.Position, 0.65
                end
                record.targetPart = nil
                record.targetIsPad = false
                record.targetIsSkyrail = false
                record.skyrailDirection = nil
            end
            -- Before an ordinary ground wander, make a bounded physical
            -- obstruction preview. Upper-deck jumps and urgent hazard
            -- routes keep their existing dedicated movement controller.
            if not urgentTarget then
                local safeTarget, safeHold = anticipateGroundObstacle(
                    record, humanoid, root, target, now)
                if safeTarget then
                    target, hold = safeTarget, safeHold
                end
            end
            record.target = target
            record.nextThink = now + hold * (traits.FollowThrough or 1)
        end

        if record.target then
            local delta = record.target - root.Position
            local horizontal = Vector3.new(delta.X, 0, delta.Z)
            -- The old generic height check fired on every brain tick,
            -- even while airborne, overriding the bounded parkour jump
            -- cooldown and creating unnatural pogo-stick movement.
            local emergencyDeck =
                urgentTarget and record.collapseEscapeDeck or nil
            if not urgentTarget or emergencyDeck then
                tryPhysicalSkyGapJump(record, humanoid, root, now,
                    record.target, emergencyDeck)
            end
            if delta.Y > 2.2 and horizontal.Magnitude < 10
                and humanoid.FloorMaterial ~= Enum.Material.Air
                and now >= (record.nextRouteJumpAt or 0)
            then
                humanoid.Jump = true
                record.nextRouteJumpAt = now + 0.75
            end

            local destination = record.target
            if not urgentTarget
                and not record.groundNavigation
                -- Do not offset a certified narrow clearance toward
                -- an obstacle with cosmetic random strafing.
                and not (record.recoveryWaypoint
                    and record.target == record.recoveryWaypoint
                    and now < (record.recoveryCommitUntil or 0))
                and not record.spineControl
                and not record.assistShield
                and not record.assistRelay
                and AISurvivorRules.allowRouteStrafe(
                    record.targetIsPad,
                    record.targetIsSkyrail,
                    record.targetPart,
                    record.districtTraverse ~= nil
                )
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
        local nextPresenceCheck = 0
        local nextReconcileWarningAt = -math.huge
        local brainPassSamples = 0
        local brainPassTotalMs = 0
        local brainPassPeakMs = 0
        local botStepSamples = 0
        local botStepTotalMs = 0
        local botStepPeakMs = 0

        while started do
            local passStartedAt = os.clock()
            local now = passStartedAt

            if currentState.phase ~= "round" and now >= nextPresenceCheck then
                local ok, err = pcall(reconcile)
                if not ok and now >= nextReconcileWarningAt then
                    warn("AI Survivor roster reconcile failed:", err)
                    nextReconcileWarningAt = now + 8
                end
                nextPresenceCheck = now + 2.5
            end

            for _, record in ipairs(records) do
                local stepStartedAt = os.clock()
                local ok, err, shouldReport = AISurvivorRules.runBrainStep(
                    record, now, stepRecord
                )
                local stepMs = (os.clock() - stepStartedAt) * 1000
                botStepSamples += 1
                botStepTotalMs += stepMs
                botStepPeakMs = math.max(botStepPeakMs, stepMs)
                if not ok and shouldReport then
                    warn("AI Survivor brain step failed:", record.identity.Username, err)
                end
            end

            local passMs = (os.clock() - passStartedAt) * 1000
            brainPassSamples += 1
            brainPassTotalMs += passMs
            brainPassPeakMs = math.max(brainPassPeakMs, passMs)
            if brainPassSamples >= 32 then
                local diagnostic = AISurvivorService.PerformanceDiagnostics
                diagnostic.Samples += brainPassSamples
                diagnostic.AveragePassMs = brainPassTotalMs / brainPassSamples
                diagnostic.PeakPassMs = brainPassPeakMs
                diagnostic.AverageBotStepMs = botStepSamples > 0
                    and botStepTotalMs / botStepSamples or 0
                diagnostic.PeakBotStepMs = botStepPeakMs
                diagnostic.BotCount = #records
                diagnostic.Phase = currentState.phase
                local active, pending, inRound = 0, 0, 0
                for _, bot in ipairs(records) do
                    if bot.inRound and bot.alive then
                        inRound += 1
                        if bot.groundNavigation then active += 1 end
                        if bot.groundNavigationPending then pending += 1 end
                    end
                end
                diagnostic.InRoundBots = inRound
                diagnostic.GroundRoutesActive = active
                diagnostic.GroundRoutesPending = pending
                brainPassSamples = 0
                brainPassTotalMs = 0
                brainPassPeakMs = 0
                botStepSamples = 0
                botStepTotalMs = 0
                botStepPeakMs = 0
            end

            task.wait(AISurvivorRules.brainCadence(
                #records,
                currentState.phase
            ))
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
        task.defer(reconcile)
    end)
    Players.PlayerRemoving:Connect(function()
        task.delay(0.25, reconcile)
    end)

    reconcile()
    startBrain()
end

-- A bot can reuse a surviving rig across multiple rounds. Reset all
-- optional circuit progress so yesterday's clear cannot disable navigation.
function AISurvivorService.resetGridCircuit(model)
    if typeof(model) ~= "Instance" or not model:IsA("Model") then
        return false
    end
    model:SetAttribute("GridCircuitStep", 0)
    model:SetAttribute("GridCircuitNext", 0)
    model:SetAttribute("GridCircuitDeadline", 0)
    model:SetAttribute("GridCircuitComplete", false)
    return true
end

function AISurvivorService.setRoundState(state)
    currentState = state or currentState
    local phase = tostring(currentState.phase or "waiting")

    if phase ~= previousPhase then
        if phase == "ready" then
            voteActive = false
            roundSerial += 1
            nextReadyRepairAt = os.clock() + 0.8
            reconcile(true)
            for _, record in ipairs(records) do
                record.roundTraits = AISurvivorRules.roundTraits(
                    record.profile,
                    record.slot,
                    roundSerial
                )
                record.nextHesitationAt = os.clock() + 0.8 + math.random() * 2.4
                record.nextRoundGestureAt = os.clock() + 4 + math.random() * 4
                record.nextReconsiderAt = os.clock() + 1.0 + math.random() * 1.8
                record.strafeBias = math.clamp(
                    (record.roundTraits.DirectionBias or 0) * 0.32,
                    -0.32,
                    0.32
                )
                record.readySpawnRetries = 0
                sendToArena(record)
                AISurvivorService.resetGridCircuit(record.model)
            end
        elseif phase == "result" then
            for _, record in ipairs(records) do
                cancelGroundNavigation(record)
            end
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
                    local action = AISurvivorRules.personalityResultAction(
                        record.profile,
                        math.random(),
                        traits.Risk or record.profile.Risk
                    )
                    record.resultAction = action
                    record.resultActionUntil = os.clock() + 0.65 + math.random() * 0.55
                    record.resultTarget = nil
                    local celebration = record.profile.Id == "Cautious"
                        and "I KNEW IT!"
                        or (record.profile.Id == "Bold"
                            and "TOO EASY!" or "WE MADE IT!")
                    showBotSignal(record, celebration, os.clock())

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

    -- Roblox R15 rig creation and physical spawn resolution can fail on
    -- the FIRST READY frame. Retry only missing, allocated NPCs twice
    -- during the following READY broadcasts. Never respawn an eliminated
    -- contestant during ROUND, which would invalidate survival results.
    if phase == "ready" and phase == previousPhase
        and os.clock() >= nextReadyRepairAt then
        nextReadyRepairAt = os.clock() + 0.9
        for _, record in ipairs(records) do
            if not record.inRound
                and (record.readySpawnRetries or 0) < 2 then
                record.readySpawnRetries = (record.readySpawnRetries or 0) + 1
                sendToArena(record)
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

            local optionIndex = AISurvivorRules.personalityVoteIndex(
                record.profile, options, record.slot, roundNumber
            )
            local option = options[optionIndex]
            if option and option.Id then
                voteIds[record.slot] = option.Id
                if record.model and record.model.Parent
                    and currentState.phase ~= "round"
                then
                    local reaction = record.profile.Id == "Cautious"
                        and "SAFE PICK!"
                        or (record.profile.Id == "Bold"
                            and "BRING CHAOS!" or "GOOD LUCK!")
                    showBotSignal(record, reaction, os.clock())
                end
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

-- Return the unique LAST living AI contestant's slot. Never use
-- lobby mannequins, disconnected proxies or an AI that died during the
-- countdown. A unique human winner is decided separately by the
-- authoritative frozen result roster; this function makes no claims
-- about human competitors or awards.
function AISurvivorService.soleAliveRoundSlot()
    local lastSlot = nil
    for _, record in ipairs(records) do
        if record.inRound then
            local humanoid = record.model
                and record.model:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if lastSlot ~= nil then return nil end
                lastSlot = record.slot
            end
        end
    end
    return lastSlot
end

-- A living lobby rig is not an arena contestant. Keep the roster
-- denominator stable after deaths/removal until the next intermission:
-- record.inRound remains true for bots admitted at READY.
function AISurvivorService.roundRosterCount()
    local count = 0
    for _, record in ipairs(records) do
        if record.inRound then
            count += 1
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

-- Read-only snapshot for server-side roster validation and engine QA.
-- These are authored fictional NPC personas, not account identities.
function AISurvivorService.identityCatalog()
    local result = {}
    for _, identity in ipairs(IDENTITIES) do
        table.insert(result, {
            Username = identity.Username,
            DisplayName = identity.DisplayName,
        })
    end
    return result
end

return AISurvivorService
