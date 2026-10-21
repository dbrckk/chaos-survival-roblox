local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local PlatformVisualRules = require(ReplicatedStorage.Shared.DisappearingPlatformVisualRules)
local PlatformFinishKit = require(script.Parent.PlatformFinishKit)

local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "DisappearingPlatformReadabilityLocal"
folder.Parent = workspace

local tracked = {}
local clock = 0
local lastCollapseWarningCueAt = -math.huge

local function profile()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function clearState(part)
    local state = tracked[part]
    if not state then
        return
    end
    tracked[part] = nil
    for _, instance in ipairs(state.instances) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
end

local function makeEdge(name, color)
    local edge = Instance.new("Part")
    edge.Name = name
    edge.Anchored = true
    edge.CanCollide = false
    edge.CanTouch = false
    edge.CanQuery = false
    edge.CastShadow = false
    edge.Material = Enum.Material.Neon
    edge.Color = color
    edge.Transparency = 1
    edge.Parent = folder
    return edge
end

local function ensureState(part)
    if tracked[part] or not part:IsA("BasePart") then
        return tracked[part]
    end

    local colorA = Color3.fromRGB(255, 225, 90)
    local colorB = Color3.fromRGB(255, 115, 35)
    local north = makeEdge("CollapseEdgeNorth", colorA)
    local south = makeEdge("CollapseEdgeSouth", colorB)
    local west = makeEdge("CollapseEdgeWest", colorB)
    local east = makeEdge("CollapseEdgeEast", colorA)
    local crossA = makeEdge("CollapseWarningCrossA", Color3.fromRGB(255, 245, 185))
    local crossB = makeEdge("CollapseWarningCrossB", Color3.fromRGB(255, 175, 70))

    local state = {
        instances = {north, south, west, east, crossA, crossB},
        north = north,
        south = south,
        west = west,
        east = east,
        crossA = crossA,
        crossB = crossB,
    }
    tracked[part] = state
    return state
end

local function layout(part, state, phase, now)
    local tier = profile()
    local low = tier.Name == "Low"
    local halfX = part.Size.X * 0.5
    local halfZ = part.Size.Z * 0.5
    local thickness = low and 0.12 or 0.16
    local reduced = player:GetAttribute("ReduceMotion") == true
    local pulse = reduced and 0.5
        or (math.sin(now * (phase == "Gone" and 4.2 or 7.2)) + 1) * 0.5
    local baseAlpha = phase == "Gone" and 0.62 or (low and 0.48 or 0.28)
    local alpha = math.clamp(baseAlpha + pulse * (phase == "Gone" and 0.18 or 0.24), 0, 0.9)

    state.north.Size = Vector3.new(part.Size.X + 0.35, 0.06, thickness)
    state.south.Size = state.north.Size
    state.west.Size = Vector3.new(thickness, 0.06, part.Size.Z + 0.35)
    state.east.Size = state.west.Size

    -- Warning contour must clear the opaque server-authored deck panel.
    -- At +0.08 its six thin bars were mostly inside the top panel and
    -- barely visible even while the platform itself was flashing amber.
    local topFrame = part.CFrame * CFrame.new(
        0, PlatformFinishKit.surfacePaintOffset(part, 0.06), 0
    )
    state.north.CFrame = topFrame * CFrame.new(0, 0, -halfZ)
    state.south.CFrame = topFrame * CFrame.new(0, 0, halfZ)
    state.west.CFrame = topFrame * CFrame.new(-halfX, 0, 0)
    state.east.CFrame = topFrame * CFrame.new(halfX, 0, 0)

    for _, edge in ipairs({state.north, state.south, state.west, state.east}) do
        edge.Transparency = alpha
    end

    if part:GetAttribute("ChaosSkybridge") == true then
        -- A 49x4.5 Skybridge cannot use the square-platform diagonal X:
        -- that would draw floating warning bars far beyond the walkable deck.
        -- Two transverse warning stripes remain entirely on the actual span.
        local alongX = part.Size.X >= part.Size.Z
        local length = math.max(part.Size.X, part.Size.Z)
        local width = math.min(part.Size.X, part.Size.Z)
        local stripeOffset = math.min(5, length * 0.18)
        local stripe = alongX
            and Vector3.new(0.22, 0.055, width * 0.85)
            or Vector3.new(width * 0.85, 0.055, 0.22)
        state.crossA.Size = stripe
        state.crossB.Size = stripe
        state.crossA.CFrame = topFrame * CFrame.new(
            alongX and -stripeOffset or 0, 0,
            alongX and 0 or -stripeOffset
        )
        state.crossB.CFrame = topFrame * CFrame.new(
            alongX and stripeOffset or 0, 0,
            alongX and 0 or stripeOffset
        )
    else
        local diagonal = math.sqrt(part.Size.X * part.Size.X + part.Size.Z * part.Size.Z) * 0.86
        state.crossA.Size = Vector3.new(diagonal, 0.055, low and 0.11 or 0.14)
        state.crossB.Size = state.crossA.Size
        state.crossA.CFrame = topFrame * CFrame.Angles(0, math.rad(45), 0)
        state.crossB.CFrame = topFrame * CFrame.Angles(0, math.rad(-45), 0)
    end

    if phase == "Warning" then
        local crossAlpha = math.clamp((low and 0.56 or 0.34) + pulse * 0.20, 0, 0.88)
        state.crossA.Transparency = crossAlpha
        state.crossB.Transparency = math.clamp(crossAlpha + 0.08, 0, 0.9)
    else
        state.crossA.Transparency = 1
        state.crossB.Transparency = 1
    end
end

local loopStarted = false
local ensureRenderLoop

-- Each active platform has one owned attribute connection. Clearing the
-- active folder disconnects every listener and releases all six local parts.
local bound = {}
local activePlatforms = nil
local platformsAddedConnection = nil
local platformsRemovedConnection = nil

local function refreshPart(part)
    if not PlatformVisualRules.shouldDisplay(part, activePlatforms) then
        clearState(part)
        return
    end
    local firstVisibleWarning = tracked[part] == nil
        and part:GetAttribute("CollapsePhase") == "Warning"
    ensureState(part)
    if firstVisibleWarning and player:GetAttribute("AudioMuted") ~= true then
        local camera = workspace.CurrentCamera
        local rig = player.Character
        local root = rig and rig:FindFirstChild("HumanoidRootPart")
        local skybridge = part:GetAttribute("ChaosSkybridge") == true
        -- Ordinary collapse warnings are deliberately personal and nearby;
        -- distant empty platforms must not spam audio across the arena.
        -- Bridge warnings can travel farther because elevated routes are
        -- long and the loss of a 49-stud span is more dangerous.
        local audibleDistance = skybridge and 90 or 26
        local nearby = root and root:IsA("BasePart")
            and (root.Position - part.Position).Magnitude <= audibleDistance
        if camera and nearby
            and (camera.CFrame.Position - part.Position).Magnitude <= 90
            and os.clock() - lastCollapseWarningCueAt >= 1.0
        then
            lastCollapseWarningCueAt = os.clock()
            local cue = Instance.new("Sound")
            cue.Name = skybridge and "SkybridgeOutageWarning"
                or "PlatformCollapseWarning"
            cue.SoundId = "rbxasset://sounds/electronicpingshort.wav"
            cue.Volume = skybridge and 0.23 or 0.18
            cue.PlaybackSpeed = skybridge and 0.78 or 0.70
            cue.RollOffMaxDistance = skybridge and 90 or 34
            cue.RollOffMinDistance = 8
            cue.SoundGroup = SoundService:FindFirstChild("ChaosSFX")
            cue.Parent = part
            cue:Play()
            Debris:AddItem(cue, 2)
        end
    end
    if ensureRenderLoop then
        ensureRenderLoop()
    end
end

local function releasePart(part)
    local connection = bound[part]
    if connection then
        connection:Disconnect()
        bound[part] = nil
    end
    clearState(part)
end

local function bindPart(part)
    if not PlatformVisualRules.ownsPart(part, activePlatforms)
        or bound[part] then
        return
    end

    bound[part] = part:GetAttributeChangedSignal("CollapsePhase"):Connect(function()
        refreshPart(part)
    end)
    refreshPart(part)
end

local function bindPlatformsFolder(platforms)
    if platforms == activePlatforms then return end
    if platformsAddedConnection then
        platformsAddedConnection:Disconnect()
        platformsAddedConnection = nil
    end
    if platformsRemovedConnection then
        platformsRemovedConnection:Disconnect()
        platformsRemovedConnection = nil
    end
    for part in pairs(bound) do
        releasePart(part)
    end
    -- Also handle already detached tracked parts from previous rounds.
    for part in pairs(tracked) do
        clearState(part)
    end

    activePlatforms = platforms
    if not platforms then return end

    for _, child in ipairs(platforms:GetChildren()) do
        bindPart(child)
    end
    platformsAddedConnection = platforms.ChildAdded:Connect(bindPart)
    platformsRemovedConnection = platforms.ChildRemoved:Connect(releasePart)
end

-- React to streaming without WaitForChild timeouts or stale task.defer
-- callbacks. A former map may never rebind after a newer map takes over.
local observedMap = nil
local mapAddedConnection = nil
local mapRemovedConnection = nil

local function findPlatforms(generated)
    local arena = generated and generated:FindFirstChild("Arena")
    return arena and arena:FindFirstChild("Platforms") or nil
end

local function bindGeneratedMap(generated)
    if observedMap == generated then return end
    if mapAddedConnection then
        mapAddedConnection:Disconnect()
        mapAddedConnection = nil
    end
    if mapRemovedConnection then
        mapRemovedConnection:Disconnect()
        mapRemovedConnection = nil
    end
    bindPlatformsFolder(nil)
    observedMap = generated
    if not generated then return end

    mapAddedConnection = generated.DescendantAdded:Connect(function(descendant)
        if descendant.Name == "Arena" or descendant.Name == "Platforms" then
            if workspace:FindFirstChild("GeneratedMap") == generated
                and generated.Parent == workspace then
                bindPlatformsFolder(findPlatforms(generated))
            end
        end
    end)
    mapRemovedConnection = generated.DescendantRemoving:Connect(function(descendant)
        if descendant == activePlatforms or descendant.Name == "Arena" then
            bindPlatformsFolder(nil)
        end
    end)
    bindPlatformsFolder(findPlatforms(generated))
end

local function refreshActiveMap()
    bindGeneratedMap(workspace:FindFirstChild("GeneratedMap"))
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        refreshActiveMap()
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        refreshActiveMap()
    end
end)

refreshActiveMap()

ensureRenderLoop = function()
    if loopStarted then
        return
    end
    loopStarted = true

    task.spawn(function()
        while true do
            if next(tracked) == nil then
                task.wait(0.18)
                continue
            end

            local tier = profile()
            local cadence = math.max(tier.UpdateInterval, tier.Name == "Low" and 0.12 or 0.075)
            local dt = task.wait(cadence)
            clock += dt

            for part, state in pairs(tracked) do
                if not PlatformVisualRules.shouldDisplay(part, activePlatforms) then
                    clearState(part)
                else
                    layout(part, state, part:GetAttribute("CollapsePhase"), clock)
                end
            end
        end
    end)
end

ensureRenderLoop()
