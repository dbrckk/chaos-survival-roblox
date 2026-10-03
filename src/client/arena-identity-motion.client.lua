local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local currentArena = nil
local currentVariant = nil
local tracked = {}
local phase = "waiting"
local rebuildToken = 0

local function clear()
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
    rebuildToken += 1
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

local function qualityScale()
    local profile = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local scale
    if profile.Name == "Low" then
        scale = 0.38
    elseif profile.Name == "Medium" then
        scale = 0.68
    else
        scale = 1
    end

    if player:GetAttribute("ReduceMotion") == true then
        scale *= 0.30
    end
    return scale
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(rebuild)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clear()
    end
end)

task.defer(rebuild)

stateEvent.OnClientEvent:Connect(function(state)
    phase = tostring(state.phase or "waiting")
end)

task.spawn(function()
    while true do
        if not currentArena or not currentArena.Parent then
            rebuild()
        end

        local active = phase == "ready"
            or phase == "round"
            or phase == "result"

        local scale = qualityScale()
        local now = os.clock()

        if active then
            for _, item in ipairs(tracked) do
            local part = item.part
            if not part or not part.Parent then
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
        end
        end

        task.wait(
            active
                and (scale < 0.5 and 0.16 or 0.09)
                or 0.60
        )
    end
end)
