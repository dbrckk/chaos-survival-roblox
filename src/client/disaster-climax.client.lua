local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local DisasterClimax = require(ReplicatedStorage.Shared.DisasterClimax)
local DisasterClimaxSignatureKit = require(script.Parent.DisasterClimaxSignatureKit)
local DisasterBoundaryClimaxKit = require(script.Parent.DisasterBoundaryClimaxKit)
local DisasterClimaxElementKit = require(script.Parent.DisasterClimaxElementKit)
local CelebrationMeshes = require(script.Parent.LobbyCelebrationMeshes)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "DisasterClimaxLocal"
folder.Parent = workspace

local previousPhase = "waiting"
local lastRoundNumber = nil
local stageById = {}
local generationById = {}
local token = 0
local snapshotSerial = 0
local displayedBase = nil

local function arenaBase()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    return base and base:IsA("BasePart") and base or nil
end

local ELEMENT = DisasterClimaxElementKit.emit
local SIGNATURE = DisasterClimaxSignatureKit.emit
local BOUNDARY = DisasterBoundaryClimaxKit.emit

-- Keep each silhouette's existing deck offset and trajectory recipe.
local PRESENTATIONS = {
    lava = {emit = ELEMENT, lift = 0.12, mesh = "pylon"},
    meteor = {emit = ELEMENT, lift = 0.12, mesh = "fragment"},
    gravity = {emit = ELEMENT, lift = 0.12, mesh = "casting"},
    fracture = {emit = ELEMENT, lift = 0.10, mesh = "casting"},
    tornado = {emit = ELEMENT, lift = 0.20, mesh = "casting"},
    freeze = {emit = SIGNATURE, lift = 0.12, mesh = "fragment"},
    bomb = {emit = BOUNDARY, lift = 0.13, mesh = "casting", pattern = "blast"},
    speed = {emit = ELEMENT, lift = 0.10, mesh = "casting"},
    darkness = {emit = ELEMENT, lift = 0.13, mesh = "pylon"},
    shrink = {emit = BOUNDARY, lift = 0.13, mesh = "casting"},
    shock = {emit = SIGNATURE, lift = 0.14, mesh = "casting"},
}

-- Oldest-first eviction keeps the transient-only folder bounded across
-- several rapidly escalating stages. It does not touch warning geometry.
local function reserveClimaxPieces(expectedPieces, limit)
    local children = folder:GetChildren()
    local remove = DisasterClimax.burstEvictions(
        #children, expectedPieces, limit
    )
    for i = 1, math.min(remove, #children) do
        children[i]:Destroy()
    end
end

local function playClimax(id, stage, base, delaySeconds, currentToken, currentGeneration, burstCount)
    local profile = DisasterClimax.get(id)
    local presentation = profile and PRESENTATIONS[profile.Kind]
    if not presentation then
        return
    end

    task.delay(delaySeconds or 0, function()
        if not DisasterClimax.shouldPresent(
            currentToken, token, stage, stageById[id],
            base.Parent ~= nil and arenaBase() == base,
            previousPhase == "round",
            player:GetAttribute("RoundEliminated")
        ) or (generationById[id] or 0) ~= currentGeneration then
            return
        end

        -- Cosmetic Double Chaos tier scales independently of the device's
        -- selected graphics setting; hazard telegraphs are never changed.
        local selectedTier = VfxQuality.deviceTier(
            player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled
        ).Name
        local tierName = DisasterClimax.burstTier(selectedTier, burstCount)
        local reduced = player:GetAttribute("ReduceMotion") == true
        local incoming = DisasterClimax.burstPieceCount(tierName, reduced)
        local limit = DisasterClimax.burstPartLimit(
            selectedTier, burstCount, reduced
        )
        reserveClimaxPieces(incoming, limit)
        local source = tierName ~= "Low" and CelebrationMeshes.readyProfile(
            presentation.mesh, player:GetAttribute("OptionalVfxPressure")
        )
        local clonePiece = if source then function()
            return CelebrationMeshes.cloneProfile(source)
        end else nil
        local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + presentation.lift, 0)
        presentation.emit(folder, presentation.pattern or profile.Kind, deck,
            base.Size, stage, profile.Color, profile.Secondary, tierName, reduced, clonePiece)
    end)
end

-- A round state can precede the arena Base's replication.
-- Only the latest snapshot may retry, for at most three delayed attempts.
local function presentAvailable(state, serial, attempt)
    if serial ~= snapshotSerial or previousPhase ~= "round" then
        return
    end
    local base = arenaBase()
    if not base then
        local delaySeconds = DisasterClimax.replicationRetryDelay(attempt)
        if delaySeconds then
            task.delay(delaySeconds, function()
                presentAvailable(state, serial, attempt + 1)
            end)
        end
        return
    end

    -- A replacement arena needs its own climax stage; invalidate old bursts.
    if displayedBase ~= base then
        displayedBase = base
        table.clear(stageById)
        table.clear(generationById)
        token += 1
        -- Remove old arena's live cosmetics immediately, not after Debris.
        folder:ClearAllChildren()
    end

    local ids = type(state.disasterIds) == "table" and state.disasterIds or {}
    local stage = DisasterClimax.stageFor(
        state.intensity, state.finalRush == true, state.overdrive == true
    )
    -- Track *selected cosmetic* owners rather than all server disasters.
    -- When the selection changes, invalidate already scheduled callbacks
    -- even if the deselected disaster is still active server-side.
    local presentationIds = stage > 0 and DisasterClimax.burstIds(ids) or {}
    DisasterClimax.pruneInactive(
        stageById, generationById, presentationIds
    )
    if stage <= 0 then return end
    local currentToken = token
    for index, id in ipairs(presentationIds) do
        local previousStage = stageById[id] or 0
        if stage > previousStage then
            stageById[id] = stage
            playClimax(id, stage, base, (index - 1) * 0.10,
                currentToken, generationById[id] or 0, #presentationIds)
        end
    end
end

local function discardClimax()
    -- Only local transient silhouettes are owned by this controller.
    -- Invalidate every delayed burst and pending Base replication retry.
    token += 1
    snapshotSerial += 1
    table.clear(stageById)
    table.clear(generationById)
    folder:ClearAllChildren()
    displayedBase = nil
end

stateEvent.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" or type(state.phase) ~= "string" then
        return
    end
    local candidate = tonumber(state.roundNumber)
    local number = candidate and candidate == candidate
        and candidate >= 1 and candidate < math.huge
        and candidate == math.floor(candidate) and candidate or nil
    if number and lastRoundNumber and number < lastRoundNumber then
        -- An out-of-order result must not invalidate the current climax.
        return
    end
    local newRound = number ~= nil and lastRoundNumber ~= nil
        and number ~= lastRoundNumber
    if number then lastRoundNumber = number end

    local nextPhase = state.phase
    if nextPhase ~= previousPhase or newRound then
        -- A numbered round can start with no intervening READY packet.
        -- Always retire the previous climax geometry and queued effects.
        discardClimax()
    end
    previousPhase = nextPhase
    if nextPhase ~= "round" then return end

    snapshotSerial += 1
    presentAvailable(state, snapshotSerial, 1)
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" and displayedBase
        and displayedBase:IsDescendantOf(child) then
        -- Streaming/map rotation may remove the arena before RoundState
        -- announces the transition. Do not leave its climax fins visible.
        discardClimax()
    end
end)
