local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LandmarkReactions = require(ReplicatedStorage.Shared.LandmarkDisasterReactionRules)
local HeroMotionBudget = require(ReplicatedStorage.Shared.HeroMotionBudgetRules)
local player = Players.LocalPlayer
local roundEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local source = workspace:WaitForChild("ArenaHeroSceneryLocal", 10)

local tracked = {}
local clock = 0
local lastScan = 0
local currentPhase = "waiting"
local activeDisasters = {}
local finalRush = false
local reaction = nil

local function refreshReaction()
    reaction = LandmarkReactions.compose(
        activeDisasters, currentPhase,
        player:GetAttribute("VfxQualityTier"),
        player:GetAttribute("ReduceMotion") == true, finalRush
    )
end

local function tierName()
    return tostring(player:GetAttribute("VfxQualityTier") or "Medium")
end


local function track(nextTracked, part, role, index)
    if not part or not part:IsA("BasePart") then
        return
    end

    local state = tracked[part]
    if state then
        state.role = role
        state.index = index or 1
        nextTracked[part] = state
        return
    end

    nextTracked[part] = {
        role = role,
        index = index or 1,
        baseCFrame = part.CFrame,
        baseTransparency = part.Transparency,
        baseColor = part.Color,
        baseSize = part.Size,
        resumeAt = clock,
        wasLodHidden = false,
    }
end

-- A stable, authored pose replaces every continuous landmark gesture when
-- ReduceMotion is enabled. Reapply only on scene/state/tier changes; hazard
-- identity remains visible via a very subtle static accent.
local function applyReducedPose()
    if player:GetAttribute("ReduceMotion") ~= true then return end
    for part, state in pairs(tracked) do
        HeroMotionBudget.applyStillPose(part, state, reaction)
    end
end

local function scan()
    if not source or not source.Parent then
        source = workspace:FindFirstChild("ArenaHeroSceneryLocal")
        if not source then
            table.clear(tracked)
            return
        end
    end

    local nextTracked = {}

    track(nextTracked, source:FindFirstChild("TowerServiceCar"), "lift", 1)
    track(nextTracked, source:FindFirstChild("TowerServiceCrown"), "pulse", 2)
    track(nextTracked, source:FindFirstChild("TowerMaintenanceCraneCable"), "cable", 3)
    track(nextTracked, source:FindFirstChild("TowerMaintenanceCounterweight"), "craneWeight", 4)

    track(nextTracked, source:FindFirstChild("OrbitalReactorCore"), "reactorCore", 1)
    for i = 1, 6 do
        track(nextTracked, source:FindFirstChild("OrbitalReactorArm" .. i), "reactorArm", i)
    end

    track(nextTracked, source:FindFirstChild("ClassicBroadcastTally"), "scan", 1)
    track(nextTracked, source:FindFirstChild("ClassicOpsAntenna"), "opsAntenna", 1)
    track(nextTracked, source:FindFirstChild("OrbitalDockingArmGlow"), "dockGlow", 1)
    for i = 1, 3 do
        track(nextTracked, source:FindFirstChild("CrossroadsClosedLaneBarrier" .. i),
            "closureBar", i)
    end
    for i = 1, 2 do
        track(
            nextTracked,
            source:FindFirstChild(i == 1 and "ClassicBroadcastAntennaL" or "ClassicBroadcastAntennaR"),
            "antenna",
            i
        )
    end

    for i = 1, 3 do
        track(nextTracked, source:FindFirstChild("CrossroadsTransitSignal" .. i), "signal", i)
    end

    for part, state in pairs(tracked) do
        if not nextTracked[part] and part.Parent then
            part.CFrame = state.baseCFrame
            part.Transparency = state.baseTransparency
            part.Color = state.baseColor
            part.Size = state.baseSize
        end
    end

    tracked = nextTracked
    applyReducedPose()
end

roundEvent.OnClientEvent:Connect(function(state)
    currentPhase = tostring(state and state.phase or "waiting")
    activeDisasters = state and state.disasterIds or {}
    finalRush = currentPhase == "round" and state.finalRush == true
    refreshReaction()
    applyReducedPose()
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "ArenaHeroSceneryLocal" then
        source = child
        task.delay(0.12, scan)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child == source then
        source = nil
        table.clear(tracked)
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    scan()
    refreshReaction()
    applyReducedPose()
end)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    refreshReaction()
    if player:GetAttribute("ReduceMotion") ~= true then
        -- Returning from a still pose must not teleport the lift or arms
        -- straight into their full sine-wave displacement.
        for _, state in pairs(tracked) do
            state.resumeAt = clock
        end
    end
    applyReducedPose()
end)

refreshReaction()
scan()

task.spawn(function()
    while true do
        local tier = tierName()
        local reduced = player:GetAttribute("ReduceMotion") == true
        local interval = HeroMotionBudget.interval(tier, reduced, next(tracked) ~= nil)
        local dt = task.wait(interval)
        clock += dt

    if clock - lastScan > 2.5 then
        lastScan = clock
        scan()
    end

    -- One-shot reduced-motion pose is updated from events above. Do not
    -- perform trigonometry, CFrame writes or pulse updates each idle tick.
    if reduced then
        continue
    end
    local tierScale = HeroMotionBudget.motionScale(tier, reduced)

    for part, state in pairs(tracked) do
        if not part.Parent then
            tracked[part] = nil
            continue
        end
        -- Scenery LOD has already hidden this client-only landmark. Avoid
        -- animating off-screen parts until their original visibility returns.
        if not HeroMotionBudget.shouldUpdate(part) then
            if not state.wasLodHidden then
                -- Return the hidden monument to its authored geometry once,
                -- leaving LOD-owned visibility/transparency untouched.
                part.CFrame = state.baseCFrame
                part.Size = state.baseSize
                state.wasLodHidden = true
            end
            continue
        end
        if state.wasLodHidden then
            state.wasLodHidden = false
            state.resumeAt = clock
        end

        local resume = HeroMotionBudget.resumeEnvelope(
            clock - (state.resumeAt or clock)
        )
        local scale = tierScale * resume
        local i = state.index
        local frame = state.baseCFrame
        local signature = HeroMotionBudget.signatureOffset(
            state.role, state.index, clock, scale
        )
        if signature then
            frame = frame * signature
        end
        local ownsAnimatedCFrame = state.role == "lift"
            or state.role == "cable" or state.role == "reactorArm"
            or state.role == "antenna" or state.role == "signal"
            or state.role == "craneWeight" or state.role == "opsAntenna"
            or (state.role == "reactorCore" and tierScale > 0.18)
            or state.hadCoreMotion == true
        if state.role == "lift" then
            local travel = math.sin(clock * 0.48) * 5.2 * scale
            frame = state.baseCFrame * CFrame.new(0, travel, 0)
        elseif state.role == "pulse" then
            local wave = (math.sin(clock * 2.2) + 1) * 0.5
            part.Transparency = math.clamp(
                state.baseTransparency + (0.16 - wave * 0.18) * scale,
                0.12,
                0.70
            )
        elseif state.role == "cable" then
            local sway = math.sin(clock * 0.72) * math.rad(3.2) * scale
            frame = state.baseCFrame * CFrame.Angles(0, 0, sway)
        elseif state.role == "craneWeight" then
            -- The crane counterweight answers its cable's sway with a
            -- small opposing mechanical travel on the same client tick.
            frame = state.baseCFrame
                * HeroMotionBudget.craneCounterweightOffset(clock, scale)
        elseif state.role == "reactorCore" then
            -- A slow, bounded precession complements the existing core
            -- light pulse. Low stays static and pays no new CFrame writes.
            frame = state.baseCFrame
                * HeroMotionBudget.reactorCoreOffset(clock, scale)
            local wave = (math.sin(clock * 2.8) + 1) * 0.5
            local sizeScale = 1 + wave * 0.08 * scale
            part.Size = state.baseSize * sizeScale
            part.Transparency = math.clamp(
                state.baseTransparency + (0.08 - wave * 0.12) * scale,
                0.10,
                0.62
            )
            part.Color = state.baseColor:Lerp(Color3.new(1, 1, 1), wave * 0.12 * scale)
        elseif state.role == "reactorArm" then
            local angle = clock * 0.22 * scale + (i - 1) * math.pi / 3
            frame = state.baseCFrame
                * CFrame.Angles(0, 0, math.sin(angle) * math.rad(3.5) * scale)
        elseif state.role == "opsAntenna" then
            -- Locally articulated surveillance antenna; its booth stays fixed.
            frame = state.baseCFrame
                * HeroMotionBudget.serviceAntennaOffset(clock, scale)
        elseif state.role == "dockGlow" or state.role == "closureBar" then
            -- Staggered, low-contrast existing Neon, not gameplay warnings.
            local glow = HeroMotionBudget.servicePulse(state.role, i, clock)
            part.Transparency = math.clamp(
                state.baseTransparency + (0.08 - glow * 0.16) * scale,
                0.08, 0.85
            )
        elseif state.role == "scan" then
            local wave = (math.sin(clock * 3.1) + 1) * 0.5
            part.Transparency = math.clamp(
                state.baseTransparency + (0.18 - wave * 0.22) * scale,
                0.12,
                0.70
            )
        elseif state.role == "antenna" then
            local wave = (math.sin(clock * 2.1 + i * 1.9) + 1) * 0.5
            part.Transparency = math.clamp(
                state.baseTransparency + (0.12 - wave * 0.16) * scale,
                0.16,
                0.72
            )
        elseif state.role == "signal" then
            local glow = HeroMotionBudget.signalPulse(clock, i)
            part.Transparency = math.clamp(
                state.baseTransparency + (0.18 - glow * 0.30) * scale,
                0.08, 0.78
            )
            part.Color = state.baseColor:Lerp(
                Color3.new(1, 1, 1), glow * 0.16 * scale
            )
        end

        -- Compose authored hero motion and disaster reaction before one
        -- CFrame write, including on pitched/rotated arenas.
        local reacts = reaction and reaction.Active == true
        if reacts then
            local shift, bank, yaw, tint = LandmarkReactions.offset(
                state.role, state.index, clock, reaction
            )
            frame = HeroMotionBudget.reactiveFrame(
                frame, shift * resume, yaw * resume, bank * resume
            )
            -- Core and crossing-signal animation authored its own color
            -- earlier this tick; all other roles restore captured base color.
            local animatedColor = (state.role == "reactorCore"
                or state.role == "signal") and part.Color or state.baseColor
            part.Color = animatedColor:Lerp(reaction.Accent, tint)
        elseif HeroMotionBudget.shouldRestoreBaseColor(state.role,
            state.hadReaction) then
            -- Only the first non-reactive tick needs to undo hazard tint.
            -- Static service parts otherwise retain their authored color
            -- without redundant BasePart.Color writes on Android.
            part.Color = state.baseColor
        end
        -- Static pieces only need a CFrame write while reacting, then
        -- one reset after the hazard ends. Moving pieces update every tick.
        if ownsAnimatedCFrame or reacts or state.hadReaction == true then
            part.CFrame = frame
        end
        state.hadReaction = reacts
        -- Reset once if graphics drop to Low after a Medium/High frame.
        state.hadCoreMotion = state.role == "reactorCore" and tierScale > 0.18
    end
    end
end)
