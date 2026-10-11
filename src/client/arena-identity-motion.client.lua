local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local MotionRules = require(ReplicatedStorage.Shared.ArenaIdentityMotionRules)
local MotionReadiness = require(ReplicatedStorage.Shared.ArenaIdentityMotionReadiness)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local currentArena = nil
local currentVariant = nil
local tracked = {}
local phase = "waiting"
local phaseStartedAt = os.clock()
local phaseFromIntensity = 0
local disconnectStructure = nil
local watchedMap = nil
local rebuildQueued = false
local rebuildSerial = 0

local function restoreTracked()
    for _, item in ipairs(tracked) do
        local part = item.part
        if part and part.Parent then
            part.CFrame = item.baseCFrame
            part.Transparency = item.baseTransparency
            part.Color = item.baseColor
        end
    end
end

local function clear()
    restoreTracked()
    table.clear(tracked)
    currentArena = nil
    currentVariant = nil
end

local function trackPart(part, index)
    if not part or not part:IsA("BasePart") then
        return
    end

    tracked[#tracked + 1] = {
        part = part,
        index = index or #tracked + 1,
        baseCFrame = part.CFrame,
        baseTransparency = part.Transparency,
        baseColor = part.Color,
    }
end

local function rebuild()
    clear()

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local decor = arena and arena:FindFirstChild("Decor")
    if not arena or not decor then
        return
    end

    currentArena = arena
    currentVariant = tostring(arena:GetAttribute("VariantId") or "Classic")

    if currentVariant == "Classic" then
        for i = 1, 4 do
            trackPart(decor:FindFirstChild("GridMarkerGlow" .. i), i)
            trackPart(decor:FindFirstChild("ClassicBroadcastGlow" .. i), i + 4)
        end
    elseif currentVariant == "Towers" then
        for tower = 1, 4 do
            for level = 1, 3 do
                trackPart(decor:FindFirstChild("TowerBand" .. tower .. "_" .. level), (tower - 1) * 3 + level)
            end
            trackPart(decor:FindFirstChild("TowerMachineryCap" .. tower), 12 + tower)
            trackPart(decor:FindFirstChild("TowerAntenna" .. tower), 16 + tower)
        end
    elseif currentVariant == "Crossroads" then
        for i = 1, 4 do
            trackPart(decor:FindFirstChild("CrossroadGate" .. i), i)
            trackPart(decor:FindFirstChild("CrossroadSignal" .. i), i + 4)
        end
    elseif currentVariant == "Orbital" then
        for i = 1, 12 do
            trackPart(decor:FindFirstChild("OrbitalCrown" .. i), i)
        end
        for i = 1, 8 do
            trackPart(decor:FindFirstChild("OrbitalReactorNode" .. i), 12 + i)
        end
    end

end

-- Reconnect to each map generation; late Arena, Decor, VariantId and
-- named ornaments are observed by a single disposeable structure watcher.
local function bindMap()
    rebuildSerial += 1
    rebuildQueued = false
    if disconnectStructure then
        disconnectStructure()
        disconnectStructure = nil
    end
    clear()
    local generated = workspace:FindFirstChild("GeneratedMap")
    watchedMap = generated
    if not generated then return end
    disconnectStructure = MotionReadiness.watch(generated, function()
        if rebuildQueued then return end
        rebuildQueued = true
        local serial = rebuildSerial
        task.defer(function()
            if serial ~= rebuildSerial then return end
            rebuildQueued = false
            if workspace:FindFirstChild("GeneratedMap") == generated then
                rebuild()
            end
        end)
    end, MotionRules.isIdentityPart)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindMap()
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child == watchedMap then
        bindMap()
    end
end)

bindMap()

stateEvent.OnClientEvent:Connect(function(state)
    local previousPhase = phase
    local incomingPhase = tostring(state and state.phase or "waiting")
    if incomingPhase ~= phase then
        local now = os.clock()
        phaseFromIntensity = MotionRules.phaseEnvelope(
            phase, now - phaseStartedAt, phaseFromIntensity
        )
        phaseStartedAt = now
    end
    phase = incomingPhase

    local wasActive = previousPhase == "ready"
        or previousPhase == "round"
        or previousPhase == "result"
    local isActive = phase == "ready"
        or phase == "round"
        or phase == "result"

    if wasActive and not isActive then
        restoreTracked()
    end
end)

player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    if player:GetAttribute("ReduceMotion") == true then
        -- A frozen Orbital crown should return to the original authored pose,
        -- not stay suspended at the last animation frame.
        restoreTracked()
    else
        -- Resume authored ornament motion from rest, not a full-scale jump.
        phaseFromIntensity = 0
        phaseStartedAt = os.clock()
    end
end)

task.spawn(function()
    while true do
        local active = phase == "ready"
            or phase == "round"
            or phase == "result"

        local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
        local reduced = player:GetAttribute("ReduceMotion") == true
        local now = os.clock()
        local scale = MotionRules.motionScale(tier, reduced)
            * MotionRules.phaseEnvelope(
                phase, now - phaseStartedAt, phaseFromIntensity
            )

        if active and scale > 0 then
            for _, item in ipairs(tracked) do
            local part = item.part
            if not MotionRules.shouldUpdate(part) then
                continue
            end

            local phase = now * 1.8 + item.index * 0.62
            local wave = (math.sin(phase) + 1) * 0.5

            if currentVariant == "Classic" then
                part.Transparency = math.clamp(
                    item.baseTransparency + (0.16 - wave * 0.13) * scale,
                    0.06,
                    0.62
                )
                part.Color = item.baseColor:Lerp(Color3.new(1, 1, 1), wave * 0.10 * scale)
            elseif currentVariant == "Towers" then
                local towerWave = (math.sin(now * 2.1 - item.index * 0.72) + 1) * 0.5
                part.Transparency = math.clamp(
                    item.baseTransparency + (0.20 - towerWave * 0.17) * scale,
                    0.05,
                    0.68
                )
                part.Color = item.baseColor:Lerp(Color3.new(1, 1, 1), towerWave * 0.12 * scale)
            elseif currentVariant == "Crossroads" then
                local directionPulse = (math.sin(now * 2.55 + item.index * math.pi * 0.5) + 1) * 0.5
                part.Transparency = math.clamp(
                    item.baseTransparency + (0.18 - directionPulse * 0.15) * scale,
                    0.04,
                    0.66
                )
            elseif currentVariant == "Orbital" then
                local angle = math.rad(math.sin(now * 0.9 + item.index * 0.31) * 2.2 * scale)
                local lift = math.sin(now * 1.25 + item.index * 0.46) * 0.32 * scale
                part.CFrame = item.baseCFrame
                    * CFrame.new(0, lift, 0)
                    * CFrame.Angles(0, angle, 0)
                part.Transparency = math.clamp(
                    item.baseTransparency + (0.10 - wave * 0.08) * scale,
                    0.06,
                    0.56
                )
            end

            -- Distinct tiny mechanical gestures for the existing anchored,
            -- collision-free survey crowns, gantries and machinery.
            -- The original CFrame is always the base (no accumulated drift).
            if currentVariant ~= "Orbital" then
                local offset = MotionRules.ornamentOffset(
                    currentVariant, part.Name, now, item.index, scale
                )
                if offset then
                    part.CFrame = item.baseCFrame * offset
                end
            end
        end
        end

        task.wait(MotionRules.interval(tier, reduced, active, #tracked > 0))
    end
end)
