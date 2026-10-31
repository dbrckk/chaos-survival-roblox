-- Low-frequency Android-only backpressure for OPTIONAL cosmetics. The
-- owner piggybacks on existing frame-pacing attributes and reuses the
-- existing cooperative VisualBudgetRules collector; no RenderStepped loop,
-- server requests, warning edits, or gameplay gating are introduced.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

if not UserInputService.TouchEnabled then return end

local VisualBudgetRules = require(ReplicatedStorage.Shared.VisualBudgetRules)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local PressureRules = require(ReplicatedStorage.Shared.VisualBudgetPressureRules)
local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local phase = "waiting"
local lastRoundNumber = nil
local generation = 0
local pressure = 0
local streak = 0

local function publish(nextValue)
    if pressure == nextValue
        and player:GetAttribute("OptionalVfxPressure") == nextValue then
        return
    end
    pressure = nextValue
    player:SetAttribute("OptionalVfxPressure", nextValue)
end

publish(0)

stateEvent.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" or type(state.phase) ~= "string" then
        return
    end
    local candidate = tonumber(state.roundNumber)
    local number = candidate and candidate == candidate
        and candidate >= 1 and candidate < math.huge
        and candidate == math.floor(candidate) and candidate or nil
    if number and lastRoundNumber and number < lastRoundNumber then
        return
    end
    local newRound = number and lastRoundNumber and number ~= lastRoundNumber
    if number then lastRoundNumber = number end

    local newPhase = state.phase
    if newRound or phase ~= newPhase then
        generation += 1
        streak = 0
        -- Never carry last round's pressure into another arena/lobby.
        -- Restart observation when the new playable round is actually live.
        publish(0)
    end
    phase = newPhase
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        generation += 1
        streak = 0
        publish(0)
    end
end)

task.spawn(function()
    while player.Parent do
        -- No diagnostic traversal in READY, lobby, results or loading.
        -- Worst case one full collection each 16s while playing on touch.
        task.wait(16)
        if phase ~= "round" or not workspace:FindFirstChild("GeneratedMap") then
            continue
        end
        local observedGeneration = generation
        local tier = VfxQuality.deviceTier(
            player:GetAttribute("VfxQualityTier"), true
        ).Name
        local counts = VisualBudgetRules.collect(workspace, function()
            -- The existing sampler's 160-instance checkpoint keeps the
            -- scan cooperative on low-end Android during Double Chaos.
            task.wait()
        end)
        if observedGeneration ~= generation or phase ~= "round"
            or not player.Parent then
            continue
        end
        local desired = PressureRules.desired(
            tier, counts,
            player:GetAttribute("ClientObservedFps"),
            player:GetAttribute("ClientObservedP95FrameMs")
        )
        local nextLevel
        nextLevel, streak = PressureRules.advance(pressure, streak, desired)
        publish(nextLevel)
    end
end)
