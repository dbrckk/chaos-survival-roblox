-- Event-driven character micro-VFX: dodge ribbons, blast-pressure arcs and
-- short landing stabilizers. These are extra cosmetic attachments only.
-- Locomotion, hit detection, Animator, physics and camera are untouched.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rules = require(ReplicatedStorage.Shared.CharacterReactionRules)
local ReactionVisuals = require(script.Parent.CharacterReactionVisuals)
local RigRegistry = require(script.Parent.CharacterReactionRigRegistry)
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
        local emitted = ReactionVisuals.burst(root, "Shock",
            tostring(payload.kind or ""), p.Shock, intensity,
            activePieces, payload.position)
        if emitted > 0 then
            impactByModel[model] = now
            n += 1
        end
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
    -- No visible reaction means the next valid impact must remain eligible.
    lastImpact = Rules.cooldownAfterEmission(lastImpact, now, n)
end

-- Only a currently attached HumanoidRootPart can receive its own landing.
-- Streamed replacements must not replay a stale airborne start timestamp.
local rigRegistry = RigRegistry.new(function(model, root, state, entry)
    if state == Enum.HumanoidStateType.Freefall then
        entry.airborneAt = entry.airborneAt or os.clock()
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
        if not viewer or (root.Position - viewer).Magnitude > settings.Range then
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
        killPieces()
    end
end)

nearMissEvent.OnClientEvent:Connect(nearMiss)
impactEvent.OnClientEvent:Connect(impact)
