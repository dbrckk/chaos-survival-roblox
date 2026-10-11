local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DisasterClimax = require(ReplicatedStorage.Shared.DisasterClimax)
local DisasterClimaxSignatureKit = require(script.Parent.DisasterClimaxSignatureKit)
local DisasterBoundaryClimaxKit = require(script.Parent.DisasterBoundaryClimaxKit)
local DisasterClimaxElementKit = require(script.Parent.DisasterClimaxElementKit)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "DisasterClimaxLocal"
folder.Parent = workspace

local previousPhase = "waiting"
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

-- Original 3D silhouettes replace flat lava bars and meteor streaks.
-- Count stays within 2/4/6 pieces, or one static reduced-motion wedge.
local function playLava(profile, base, stage, tier, reduced)
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.12, 0)
    DisasterClimaxElementKit.emit(folder, "lava", deck,
        base.Size, stage,
        profile.Color, profile.Secondary, tier.Name, reduced)
end

local function playMeteor(profile, base, stage, tier, reduced)
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.12, 0)
    DisasterClimaxElementKit.emit(folder, "meteor", deck,
        base.Size, stage,
        profile.Color, profile.Secondary, tier.Name, reduced)
end

-- Each effect uses an arena-local authored 3D silhouette, not a plain bar.
-- No new emitters, lights or server-side movement; same bounded part caps.
local function playGravity(profile, base, stage, tier, reduced)
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.12, 0)
    DisasterClimaxElementKit.emit(folder, "gravity", deck,
        base.Size, stage,
        profile.Color, profile.Secondary, tier.Name, reduced)
end

local function playFracture(profile, base, stage, tier, reduced)
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.10, 0)
    DisasterClimaxElementKit.emit(folder, "fracture", deck,
        base.Size, stage,
        profile.Color, profile.Secondary, tier.Name, reduced)
end

local function playTornado(profile, base, stage, tier, reduced)
    -- Arena-local helix rather than long rectangular world-axis streaks.
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.20, 0)
    DisasterClimaxElementKit.emit(folder, "tornado", deck,
        base.Size, stage,
        profile.Color, profile.Secondary, tier.Name, reduced)
end

local function playFreeze(profile, base, stage, tier, reduced)
    -- Angle-breaking ice needles replace the old large opaque cylinder.
    -- The whole silhouette inherits the rotated/pitched arena frame.
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.12, 0)
    DisasterClimaxSignatureKit.emit(
        folder, "freeze", deck,
        base.Size, stage,
        profile.Color, profile.Secondary, tier.Name, reduced
    )
end

local function playBomb(profile, base, stage, tier, reduced)
    -- Separated impulse fins show pressure direction without covering the
    -- playing field with a second opaque circular cylinder.
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.13, 0)
    DisasterBoundaryClimaxKit.emit(
        folder, "blast", deck, base.Size, stage,
        profile.Color, profile.Secondary, tier.Name, reduced
    )
end

local function playSpeed(profile, base, stage, tier, reduced)
    -- Swept chevrons in the deck's local basis, bounded on every tier.
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.10, 0)
    DisasterClimaxElementKit.emit(folder, "speed", deck,
        base.Size, stage,
        profile.Color, profile.Secondary, tier.Name, reduced)
end

local function playDarkness(profile, base, stage, tier, reduced)
    -- Folded eclipse shutters replace the arena-wide neon cylinder.
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.13, 0)
    DisasterClimaxElementKit.emit(folder, "darkness", deck,
        base.Size, stage,
        profile.Color, profile.Secondary, tier.Name, reduced)
end

local function playShrink(profile, base, stage, tier, reduced)
    -- Short rectangular perimeter segments visibly close in. The persistent
    -- shrinking boundary is drawn elsewhere; these are transient accents.
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.13, 0)
    DisasterBoundaryClimaxKit.emit(
        folder, "shrink", deck, base.Size, stage,
        profile.Color, profile.Secondary, tier.Name, reduced
    )
end

local function playShock(profile, base, stage, tier, reduced)
    -- Staggered zig-zag discharge strokes, not two full-floor discs.
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.14, 0)
    DisasterClimaxSignatureKit.emit(
        folder, "shock", deck,
        base.Size, stage,
        profile.Color, profile.Secondary, tier.Name, reduced
    )
end

local PLAYERS = {
    lava = playLava,
    meteor = playMeteor,
    gravity = playGravity,
    fracture = playFracture,
    tornado = playTornado,
    freeze = playFreeze,
    bomb = playBomb,
    speed = playSpeed,
    darkness = playDarkness,
    shrink = playShrink,
    shock = playShock,
}

local function playClimax(id, stage, base, delaySeconds, currentToken, currentGeneration, burstCount)
    local profile = DisasterClimax.get(id)
    local play = profile and PLAYERS[profile.Kind]
    if not profile or not play then
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
        local tierName = DisasterClimax.burstTier(
            player:GetAttribute("VfxQualityTier"), burstCount
        )
        local tier = VfxQuality.get(tierName)
        local reduced = player:GetAttribute("ReduceMotion") == true
        play(profile, base, stage, tier, reduced)
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
    DisasterClimax.pruneInactive(stageById, generationById, ids)
    local stage = DisasterClimax.stageFor(
        state.intensity, state.finalRush == true, state.overdrive == true
    )
    if stage <= 0 then return end
    -- Select a maximum of two distinct, valid cosmetic bursts. Unknown
    -- IDs and duplicates never steal GPU budget from active disasters.
    local presentationIds = DisasterClimax.burstIds(ids)
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

stateEvent.OnClientEvent:Connect(function(state)
    snapshotSerial += 1
    local phase = tostring(state.phase or "waiting")
    if phase ~= "round" then
        token += 1
        table.clear(stageById)
        table.clear(generationById)
        folder:ClearAllChildren()
        displayedBase = nil
        previousPhase = phase
        return
    end
    if previousPhase ~= "round" then
        table.clear(stageById)
        table.clear(generationById)
        displayedBase = nil
        token += 1
    end
    previousPhase = phase
    presentAvailable(state, snapshotSerial, 1)
end)
