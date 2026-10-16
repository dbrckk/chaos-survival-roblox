-- Event-driven character micro-VFX: dodge ribbons, blast-pressure arcs and
-- short landing stabilizers. These are extra cosmetic attachments only.
-- Locomotion, hit detection, Animator, physics and camera are untouched.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rules = require(ReplicatedStorage.Shared.CharacterReactionRules)
local ReactionVisuals = require(script.Parent.CharacterReactionVisuals)
local RigRegistry = require(script.Parent.CharacterReactionRigRegistry)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local Viewport = require(ReplicatedStorage.Shared.VisualViewportRules)

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
local activePieces = setmetatable({}, {__mode = "k"})
local botFolderConnection = nil
local botFolderRemovedConnection = nil
local botFolder = nil

local function profile()
    local quality = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    return Rules.profile(quality.Name, player:GetAttribute("ReduceMotion") == true)
end

local function liveRoot(model)
    if not model or not model.Parent then
        return nil
    end
    local owner = Players:GetPlayerFromCharacter(model)
    if owner then
        if not Rules.humanEligible(
            owner:GetAttribute("RoundParticipant"),
            owner:GetAttribute("RoundEliminated")
        ) then
            return nil
        end
    elseif model:GetAttribute("AISurvivor") ~= true then
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
    -- Spectators follow other players or AI; even active survivors can
    -- use offset cameras. Presentation distance should match the actual
    -- rendered view, not an off-screen avatar's root.
    local camera = workspace.CurrentCamera
    if camera then return camera.CFrame.Position end
    local root = liveRoot(player.Character)
    return root and root.Position or nil
end

local function visibleToCamera(model, root)
    -- Keep first-person feedback for the local participant even if the
    -- root projects behind the camera due to native camera offsets.
    if model == player.Character then return true end
    local camera = workspace.CurrentCamera
    if not camera then return true end
    local screen = camera:WorldToViewportPoint(root.Position)
    local bounds = camera.ViewportSize
    return Viewport.contains(screen.X, screen.Y, screen.Z,
        bounds.X, bounds.Y, false)
end

local function killPieces()
    for object in pairs(activePieces) do
        if object.Parent then
            object:Destroy()
        end
        activePieces[object] = nil
    end
end

local function nearMiss(payload)
    if type(payload) ~= "table" then
        return
    end
    local current = profile()
    local root = liveRoot(player.Character)
    if current.Dodge == 0 or not root then
        return
    end
    local now = os.clock()
    if not Rules.cooldownReady(now, lastDodge, 0.80) then
        return
    end
    local intensity = Rules.dodgeStrength(payload.distance, payload.radius)
    if intensity <= 0 then return end
    local emitted = ReactionVisuals.burst(root,
        "Dodge", tostring(payload.kind or ""), current.Dodge,
        intensity, activePieces)
    lastDodge = Rules.cooldownAfterEmission(lastDodge, now, emitted)
end

local function impact(payload)
    if type(payload) ~= "table"
        or not Rules.validPosition(payload.position)
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
    local viewer = viewerPosition()
    if not viewer or (payload.position - viewer).Magnitude > p.Range + 40 then
        return
    end
    -- Prioritize the local participant, then the closest visible combatants,
    -- regardless of whether they are humans or AI. Previously, the Player
    -- iteration order exhausted the small 2/3-reactor budget before bots
    -- were considered in populated rounds.
    local contenders = {}
    local function consider(model)
        local root = liveRoot(model)
        if not root then return end
        local cameraDistance = (root.Position - viewer).Magnitude
        if cameraDistance > p.Range or not visibleToCamera(model, root) then
            return
        end
        local intensity = Rules.airShockStrength(
            (root.Position - payload.position).Magnitude, payload.radius
        )
        if intensity <= 0 or not Rules.cooldownReady(
            now, impactByModel[model], 0.95
        ) then
            return
        end
        table.insert(contenders, {
            model = model,
            root = root,
            strength = intensity,
            distance = cameraDistance,
            localOwned = model == player.Character,
        })
    end

    consider(player.Character)
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            consider(other.Character)
        end
    end
    local bots = workspace:FindFirstChild("AISurvivors")
    if bots then
        for _, model in ipairs(bots:GetChildren()) do
            if model:IsA("Model") then consider(model) end
        end
    end
    table.sort(contenders, function(a, b)
        if a.localOwned ~= b.localOwned then
            return a.localOwned
        end
        if a.distance ~= b.distance then
            return a.distance < b.distance
        end
        return a.model.Name < b.model.Name
    end)

    local n = 0
    for _, contender in ipairs(contenders) do
        if n >= p.MaxReactors then break end
        -- A character could be eliminated or stream out after collection.
        if liveRoot(contender.model) == contender.root then
            local emitted = ReactionVisuals.burst(
                contender.root, "Shock", tostring(payload.kind or ""),
                p.Shock, contender.strength, activePieces, payload.position
            )
            if emitted > 0 then
                impactByModel[contender.model] = now
                n += 1
            end
        end
    end
    -- No visible reaction means the next valid impact must remain eligible.
    lastImpact = Rules.cooldownAfterEmission(lastImpact, now, n)
end

-- Only a currently attached HumanoidRootPart can receive its own landing.
-- Streamed replacements must not replay a stale airborne start timestamp.
local rigRegistry = RigRegistry.new(function(model, root, state, entry)
    if state == Enum.HumanoidStateType.Freefall then
        entry.airborneAt = phase == "round" and liveRoot(model) == root
            and (entry.airborneAt or os.clock()) or nil
    elseif state == Enum.HumanoidStateType.Dead then
        entry.airborneAt = nil
    elseif Rules.isLandingTransition(state) then
        local started = entry.airborneAt
        entry.airborneAt = nil
        if not started or liveRoot(model) ~= root then return end
        local now = os.clock()
        local strength = Rules.landingStrength(now - started)
        local settings = profile()
        if strength == 0 or settings.Landing == 0
            or not Rules.cooldownReady(now, landingByModel[model], 1.20)
        then
            return
        end
        local viewer = viewerPosition()
        if not viewer or (root.Position - viewer).Magnitude > settings.Range
            or not visibleToCamera(model, root) then
            return
        end
        local emitted = ReactionVisuals.burst(root, "Landing", "",
            settings.Landing, strength, activePieces)
        landingByModel[model] = Rules.cooldownAfterEmission(
            landingByModel[model], now, emitted)
    end
end)

local function watchLanding(model)
    rigRegistry.watch(model)
end

local function watchPlayer(p)
    p.CharacterAdded:Connect(function(character)
        task.defer(watchLanding, character)
    end)
    p.CharacterRemoving:Connect(function(character)
        rigRegistry.stop(character)
        landingByModel[character] = nil
        impactByModel[character] = nil
    end)
    if p.Character then task.defer(watchLanding, p.Character) end
end

for _, p in ipairs(Players:GetPlayers()) do
    watchPlayer(p)
end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(p)
    if p.Character then rigRegistry.stop(p.Character) end
end)

local function bindBots(folder)
    if botFolderConnection then
        botFolderConnection:Disconnect()
        botFolderConnection = nil
    end
    if botFolderRemovedConnection then
        botFolderRemovedConnection:Disconnect()
        botFolderRemovedConnection = nil
    end
    if botFolder and botFolder ~= folder then
        for _, model in ipairs(botFolder:GetChildren()) do
            if model:IsA("Model") then rigRegistry.stop(model) end
        end
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
        botFolderRemovedConnection = folder.ChildRemoved:Connect(function(model)
            if model:IsA("Model") then
                rigRegistry.stop(model)
                landingByModel[model] = nil
                impactByModel[model] = nil
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
    phase = tostring(type(snapshot) == "table"
        and snapshot.phase or "waiting")
    if phase ~= "round" then
        rigRegistry.clearAirborne()
        killPieces()
    end
end)

nearMissEvent.OnClientEvent:Connect(nearMiss)
impactEvent.OnClientEvent:Connect(impact)
