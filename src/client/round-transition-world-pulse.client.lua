local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local RoundEventPresentation = require(ReplicatedStorage.Shared.RoundEventPresentation)
local CinematicPulseRingKit = require(script.Parent.CinematicPulseRingKit)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "RoundTransitionPulsesLocal"
folder.Parent = workspace

local previousPhase = "waiting"
local lastFinalRush = false
local lastOverdrive = false

local function arenaBase()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    return base and base:IsA("BasePart") and base or nil
end

local function emitRing(name, frame, color, startDiameter, endDiameter, duration, tier, reduced, alpha)
    return CinematicPulseRingKit.emit(
        folder, name, frame, color,
        startDiameter, endDiameter, duration, tier.Name, reduced, alpha
    )
end

local function pulseArena(state, finalRush)
    local base = arenaBase()
    if not base then return end
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local reduced = player:GetAttribute("ReduceMotion") == true
    local frame = base.CFrame * CFrame.new(0, base.Size.Y * 0.5 + 0.22, 0)
    local diameter = math.max(base.Size.X, base.Size.Z)
    local ids = type(state.disasterIds) == "table" and state.disasterIds or {}
    local firstColor = finalRush and UITheme.Colors.Orange
        or UITheme.disasterAccent(ids[1], UITheme.Colors.Cyan)
    local secondColor = finalRush and UITheme.Colors.Red
        or UITheme.disasterAccent(ids[2], UITheme.Colors.Violet)

    emitRing(
        finalRush and "FinalRushArenaPulse" or "RoundStartArenaPulse",
        frame, firstColor,
        finalRush and diameter * 0.34 or 5,
        finalRush and diameter * 0.96 or diameter * 0.84,
        tier.Name == "Low" and 0.40 or 0.56,
        tier, reduced, 0.46
    )
    local secondRing = finalRush or (state.doubleChaos == true and ids[2] ~= nil)
    if secondRing and tier.Name ~= "Low" and not reduced then
        task.delay(0.09, function()
            if base.Parent then
                emitRing(
                    finalRush and "FinalRushArenaPulseRed" or "RoundStartArenaPulseSecondary",
                    frame * CFrame.new(0, 0.08, 0), secondColor,
                    finalRush and diameter * 0.44 or 8,
                    finalRush and diameter * 1.04 or diameter * 0.95,
                    0.62, tier, false, 0.57
                )
            end
        end)
    end
end

local function rootPart()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return root and root:IsA("BasePart") and root or nil
end

local function pulse(color, strength, doubleRing)
    local root = rootPart()
    if not root then return end
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local reduced = player:GetAttribute("ReduceMotion") == true
    local scale = reduced and 0.42 or 1
    local diameter = (10 + strength * 8) * scale
    local duration = reduced and 0.24 or (0.34 + strength * 0.12)

    local function makeRing(extraDiameter, delaySeconds, alpha)
        task.delay(delaySeconds, function()
            local currentRoot = rootPart()
            if not currentRoot then return end
            emitRing(
                "RoundTransitionPulseLocal",
                CFrame.new(currentRoot.Position + Vector3.new(0, -2.35, 0)),
                color, 1, diameter + extraDiameter,
                duration, tier, reduced, alpha
            )
        end)
    end

    makeRing(0, 0, reduced and 0.70 or 0.48)
    if doubleRing and tier.Name ~= "Low" and not reduced then
        makeRing(7, 0.07, 0.58)
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    local phase = tostring(state.phase or "waiting")
    local finalRush = phase == "round" and state.finalRush == true
    local overdrive = phase == "round" and state.overdrive == true
    local roundStarted = phase == "round" and previousPhase ~= "round"

    local kick = RoundEventPresentation.cameraKick(
        previousPhase,
        state,
        lastFinalRush,
        lastOverdrive
    )

    if roundStarted then
        pulseArena(state, false)
    elseif finalRush and not lastFinalRush then
        pulseArena(state, true)
    elseif kick > 0 then
        local ids = type(state.disasterIds) == "table" and state.disasterIds or {}
        local color = overdrive and not lastOverdrive
            and UITheme.Colors.Gold
            or RoundEventPresentation.accent(
                ids,
                function(id)
                    return UITheme.disasterAccent(id, UITheme.Colors.Cyan)
                end
            )

        pulse(
            color,
            kick,
            state.doubleChaos == true or overdrive
        )
    end

    previousPhase = phase
    lastFinalRush = finalRush
    lastOverdrive = overdrive
end)
