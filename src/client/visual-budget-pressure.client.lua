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

-- The regular round is 45s (30s solo). Decisions every 16s meant a
-- two-step P2 degradation could not happen until AFTER a solo round.
-- Reuse one cooperative census for multiple 5s performance decisions.
-- This keeps the full Workspace traversal at most once every 20s.
local OBSERVE_SECONDS = 5
local CENSUS_SECONDS = 20
local SUSPEND_GAP_SECONDS = 18
local QUALITY_SETTLE_SECONDS = 8
local cachedCounts = nil
local lastCensusAt = nil
local settleUntil = 0

local function invalidateCensus()
    cachedCounts = nil
    lastCensusAt = nil
end

-- A changed adaptive tier changes both the VFX population and the
-- Parts/Lights/Effects allowances. Never reuse a High-tier census against
-- Low-tier limits, nor count old FPS samples toward the new tier's streak.
-- Keep the current pressure (safe, non-visual) while cosmetic owners settle.
local function resetForQualityChange()
    generation += 1
    streak = 0
    invalidateCensus()
    settleUntil = os.clock() + QUALITY_SETTLE_SECONDS
end

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(resetForQualityChange)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(resetForQualityChange)

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
        invalidateCensus()
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
        invalidateCensus()
        publish(0)
    end
end)

task.spawn(function()
    while player.Parent do
        -- task.wait reports the ACTUAL elapsed scheduler delay; use it
        -- instead of assuming Android resumed exactly five seconds later.
        local elapsed = task.wait(OBSERVE_SECONDS)
        local now = os.clock()
        -- Backgrounding Roblox on Android can suspend scheduling for
        -- minutes. Never interpret one wakeup after suspension as a
        -- second consecutive bad FPS sample, or reuse old arena counts.
        if elapsed > SUSPEND_GAP_SECONDS then
            streak = 0
            invalidateCensus()
            -- FPS/p95 may still describe frames from before the Android
            -- process suspension. Give the existing sampler time to
            -- publish new readings before resuming automatic decisions.
            settleUntil = os.clock() + QUALITY_SETTLE_SECONDS
            continue
        end

        -- No full diagnostic traversal during READY, lobby, results or
        -- map streaming. The next live round gets a fresh count.
        if phase ~= "round" or not workspace:FindFirstChild("GeneratedMap") then
            invalidateCensus()
            continue
        end

        local observedGeneration = generation
        if not cachedCounts or not lastCensusAt
            or now - lastCensusAt >= CENSUS_SECONDS then
            local interrupted = false
            local counts = VisualBudgetRules.collect(workspace, function()
                -- Yield at the existing 160-instance checkpoint, never
                -- scan all local decorations in one long Android frame.
                -- Suspension can happen DURING a multi-yield census too.
                if task.wait() > SUSPEND_GAP_SECONDS then
                    interrupted = true
                end
            end)
            if interrupted or observedGeneration ~= generation
                or phase ~= "round"
                or not workspace:FindFirstChild("GeneratedMap")
                or not player.Parent then
                if interrupted then
                    streak = 0
                    settleUntil = os.clock() + QUALITY_SETTLE_SECONDS
                end
                invalidateCensus()
                continue
            end
            cachedCounts = counts
            lastCensusAt = os.clock()
        end
        -- Perf readings are sampled anew each observation; the instance
        -- census is cached, and quality tier normalization stays current.
        if observedGeneration ~= generation or phase ~= "round" then
            invalidateCensus()
            continue
        end
        -- Tier-dependent VFX owners have a short event-driven window to
        -- rebuild. Do not let one just-updated profile prompt an immediate
        -- opposite pressure change and ping-pong with adaptive graphics.
        if os.clock() < settleUntil then
            streak = 0
            continue
        end
        local tier = VfxQuality.deviceTier(
            player:GetAttribute("VfxQualityTier"), true
        ).Name
        local desired = PressureRules.desired(
            tier, cachedCounts,
            player:GetAttribute("ClientObservedFps"),
            player:GetAttribute("ClientObservedP95FrameMs")
        )
        local nextLevel
        nextLevel, streak = PressureRules.advance(pressure, streak, desired)
        publish(nextLevel)
    end
end)
