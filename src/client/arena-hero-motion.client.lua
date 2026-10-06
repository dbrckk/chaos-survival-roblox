local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local source = workspace:WaitForChild("ArenaHeroSceneryLocal", 10)

local tracked = {}
local clock = 0
local updateClock = 0
local lastScan = 0

local function tierName()
    return tostring(player:GetAttribute("VfxQualityTier") or "Medium")
end

local function motionScale()
    if player:GetAttribute("ReduceMotion") == true then
        return 0.18
    end
    local tier = tierName()
    if tier == "Low" then
        return 0.18
    elseif tier == "Medium" then
        return 0.62
    end
    return 1
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
    }
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

    track(nextTracked, source:FindFirstChild("OrbitalReactorCore"), "reactorCore", 1)
    for i = 1, 6 do
        track(nextTracked, source:FindFirstChild("OrbitalReactorArm" .. i), "reactorArm", i)
    end

    track(nextTracked, source:FindFirstChild("ClassicBroadcastTally"), "scan", 1)
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
end

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

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(scan)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(scan)

scan()

RunService.RenderStepped:Connect(function(dt)
    clock += dt
    updateClock += dt

    local tier = tierName()
    local interval = tier == "Low" and 0.16 or (tier == "Medium" and 0.09 or 0.055)
    if updateClock < interval then
        return
    end
    updateClock = 0

    if clock - lastScan > 2.5 then
        lastScan = clock
        scan()
    end

    local scale = motionScale()

    for part, state in pairs(tracked) do
        if not part.Parent then
            tracked[part] = nil
            continue
        end

        local i = state.index
        if state.role == "lift" then
            local travel = math.sin(clock * 0.48) * 5.2 * scale
            part.CFrame = state.baseCFrame * CFrame.new(0, travel, 0)
        elseif state.role == "pulse" then
            local wave = (math.sin(clock * 2.2) + 1) * 0.5
            part.Transparency = math.clamp(
                state.baseTransparency + 0.16 - wave * 0.18 * scale,
                0.12,
                0.70
            )
        elseif state.role == "cable" then
            local sway = math.sin(clock * 0.72) * math.rad(3.2) * scale
            part.CFrame = state.baseCFrame * CFrame.Angles(0, 0, sway)
        elseif state.role == "reactorCore" then
            local wave = (math.sin(clock * 2.8) + 1) * 0.5
            local sizeScale = 1 + wave * 0.08 * scale
            part.Size = state.baseSize * sizeScale
            part.Transparency = math.clamp(
                state.baseTransparency + 0.08 - wave * 0.12 * scale,
                0.10,
                0.62
            )
            part.Color = state.baseColor:Lerp(Color3.new(1, 1, 1), wave * 0.12 * scale)
        elseif state.role == "reactorArm" then
            local angle = clock * 0.22 * scale + (i - 1) * math.pi / 3
            part.CFrame = state.baseCFrame
                * CFrame.Angles(0, 0, math.sin(angle) * math.rad(3.5) * scale)
        elseif state.role == "scan" then
            local wave = (math.sin(clock * 3.1) + 1) * 0.5
            part.Transparency = math.clamp(
                state.baseTransparency + 0.18 - wave * 0.22 * scale,
                0.12,
                0.70
            )
        elseif state.role == "antenna" then
            local wave = (math.sin(clock * 2.1 + i * 1.9) + 1) * 0.5
            part.Transparency = math.clamp(
                state.baseTransparency + 0.12 - wave * 0.16 * scale,
                0.16,
                0.72
            )
        elseif state.role == "signal" then
            local phase = (math.floor(clock * 2.4) + i) % 3
            local active = phase == 0
            part.Transparency = active
                and math.max(0.10, state.baseTransparency - 0.10 * scale)
                or math.min(0.72, state.baseTransparency + 0.26 * scale)
            part.Color = active
                and state.baseColor:Lerp(Color3.new(1, 1, 1), 0.16 * scale)
                or state.baseColor
        end
    end
end)
