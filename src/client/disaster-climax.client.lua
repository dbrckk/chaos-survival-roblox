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
local token = 0

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
        math.max(base.Size.X, base.Size.Z), stage,
        profile.Color, profile.Secondary, tier.Name, reduced)
end

local function playMeteor(profile, base, stage, tier, reduced)
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.12, 0)
    DisasterClimaxElementKit.emit(folder, "meteor", deck,
        math.max(base.Size.X, base.Size.Z), stage,
        profile.Color, profile.Secondary, tier.Name, reduced)
end

-- Each effect uses an arena-local authored 3D silhouette, not a plain bar.
-- No new emitters, lights or server-side movement; same bounded part caps.
local function playGravity(profile, base, stage, tier, reduced)
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.12, 0)
    DisasterClimaxElementKit.emit(folder, "gravity", deck,
        math.max(base.Size.X, base.Size.Z), stage,
        profile.Color, profile.Secondary, tier.Name, reduced)
end

local function playFracture(profile, base, stage, tier, reduced)
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.10, 0)
    DisasterClimaxElementKit.emit(folder, "fracture", deck,
        math.max(base.Size.X, base.Size.Z), stage,
        profile.Color, profile.Secondary, tier.Name, reduced)
end

local function playTornado(profile, base, stage, tier, reduced)
    -- Arena-local helix rather than long rectangular world-axis streaks.
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.20, 0)
    DisasterClimaxElementKit.emit(folder, "tornado", deck,
        math.max(base.Size.X, base.Size.Z), stage,
        profile.Color, profile.Secondary, tier.Name, reduced)
end

local function playFreeze(profile, base, stage, tier, reduced)
    -- Angle-breaking ice needles replace the old large opaque cylinder.
    -- The whole silhouette inherits the rotated/pitched arena frame.
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.12, 0)
    DisasterClimaxSignatureKit.emit(
        folder, "freeze", deck,
        math.max(base.Size.X, base.Size.Z), stage,
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
        math.max(base.Size.X, base.Size.Z), stage,
        profile.Color, profile.Secondary, tier.Name, reduced)
end

local function playDarkness(profile, base, stage, tier, reduced)
    -- Folded eclipse shutters replace the arena-wide neon cylinder.
    local deck = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.13, 0)
    DisasterClimaxElementKit.emit(folder, "darkness", deck,
        math.max(base.Size.X, base.Size.Z), stage,
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
        math.max(base.Size.X, base.Size.Z), stage,
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

local function playClimax(id, stage, base, delaySeconds, currentToken)
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
        ) then
            return
        end

        local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
        local reduced = player:GetAttribute("ReduceMotion") == true
        play(profile, base, stage, tier, reduced)
    end)
end

stateEvent.OnClientEvent:Connect(function(state)
    local phase = tostring(state.phase or "waiting")

    if phase ~= "round" then
        token += 1
        table.clear(stageById)
        previousPhase = phase
        return
    end

    if previousPhase ~= "round" then
        table.clear(stageById)
        token += 1
    end

    local stage = DisasterClimax.stageFor(
        state.intensity,
        state.finalRush == true,
        state.overdrive == true
    )
    local base = arenaBase()

    if base and stage > 0 then
        local ids = type(state.disasterIds) == "table" and state.disasterIds or {}
        local currentToken = token

        for index, id in ipairs(ids) do
            local previousStage = stageById[id] or 0
            if stage > previousStage then
                stageById[id] = stage
                playClimax(
                    id,
                    stage,
                    base,
                    (index - 1) * 0.10,
                    currentToken
                )
            end
        end
    end

    previousPhase = phase
end)
