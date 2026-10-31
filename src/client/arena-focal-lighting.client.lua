local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local ArenaFocalLightingRules = require(ReplicatedStorage.Shared.ArenaFocalLightingRules)
local ArenaCrisisSurfaceRules = require(ReplicatedStorage.Shared.ArenaCrisisSurfaceRules)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)
local ArenaFocalFixtureKit = require(script.Parent.ArenaFocalFixtureKit)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "ArenaFocalLightingLocal"
folder.Parent = workspace

local lights = {}
local anchorStates = {}
local basePoseConnections = {}
local liveBase = nil
local poseSerial = 0
local poseQueued = false
local phase = "waiting"
local finalRush = false
local activeDisasters = {}
local disconnectMapWatch = nil

local function clear()
    poseSerial += 1
    poseQueued = false
    for _, connection in ipairs(basePoseConnections) do
        connection:Disconnect()
    end
    table.clear(basePoseConnections)
    liveBase = nil
    table.clear(anchorStates)
    for _, light in ipairs(lights) do
        if light and light.Parent then
            light:Destroy()
        end
    end
    table.clear(lights)
    folder:ClearAllChildren()
end

local function colorFor(theme, role)
    if role == "Secondary" then
        return theme.Secondary
    elseif role == "Detail" then
        return theme.Detail
    end
    return theme.Accent
end

local function targetBrightness(light)
    local base = tonumber(light:GetAttribute("BaseBrightness")) or 0
    return base * ArenaFocalLightingRules.phaseScale(phase, finalRush)
end

local function refresh(duration)
    local response = ArenaCrisisSurfaceRules.profile(
        activeDisasters, phase,
        VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled).Name,
        player:GetAttribute("ReduceMotion") == true, finalRush
    )
    for index, light in ipairs(lights) do
        if light and light.Parent then
            local baseColor = light:GetAttribute("BaseColor")
            if typeof(baseColor) ~= "Color3" then
                baseColor = light.Color
                light:SetAttribute("BaseColor", baseColor)
            end
            local color, brightness = ArenaCrisisSurfaceRules.light(
                baseColor, targetBrightness(light), index, response
            )
            TweenService:Create(
                light,
                TweenInfo.new(
                    duration or 0.24,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                ),
                {Brightness = brightness, Color = color}
            ):Play()
        end
    end
end

-- Only during an actual Base.Size/CFrame change (ShrinkingArena or a
-- tilting map), reposition the *existing* spotlights AND their anchored
-- hardware together. No per-frame polling and no new light allocations.
local function syncAnchorFrames()
    local base = liveBase
    if not base or not base.Parent then return end
    local frame, size = base.CFrame, base.Size
    for _, state in ipairs(anchorStates) do
        local nextFrame = ArenaFocalLightingRules.anchorFrame(
            frame, size, state.definition
        )
        if nextFrame and state.anchor.Parent
            and state.anchor.CFrame ~= nextFrame then
            state.anchor.CFrame = nextFrame
            for _, fixture in ipairs(state.fixtures) do
                if fixture.part.Parent then
                    fixture.part.CFrame = nextFrame * fixture.localFrame
                end
            end
        end
    end
end

local function queueAnchorSync()
    if poseQueued then return end
    poseQueued = true
    local serial = poseSerial
    task.defer(function()
        if serial ~= poseSerial then return end
        poseQueued = false
        syncAnchorFrames()
    end)
end

local function rebuild()
    clear()

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = MapVisualReadiness.part(generated, "Arena", "Base")
    if not arena or not base or not base:IsA("BasePart") then
        return
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local theme = VisualTheme.arena(variant)
    local tier = VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled)
    local count = ArenaFocalLightingRules.sourceCount(tier.Name)
    if count <= 0 then
        return
    end

    local definitions = ArenaFocalLightingRules.definitions(variant)
    for i = 1, math.min(count, #definitions) do
        local definition = definitions[i]
        local frame = ArenaFocalLightingRules.anchorFrame(
            base.CFrame, base.Size, definition
        )
        if not frame then continue end

        local anchor = Instance.new("Part")
        anchor.Name = "ArenaFocalLightAnchor" .. i
        anchor.Size = Vector3.new(0.18, 0.18, 0.18)
        anchor.CFrame = frame
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false
        anchor.CastShadow = false
        anchor.Transparency = 1
        anchor.Parent = folder
        local parts = ArenaFocalFixtureKit.build(
            folder, anchor, variant, tier.Name, theme, i
        )
        local fixtures = {}
        for _, part in ipairs(parts) do
            fixtures[#fixtures + 1] = {
                part = part,
                localFrame = frame:ToObjectSpace(part.CFrame),
            }
        end
        anchorStates[#anchorStates + 1] = {
            anchor = anchor,
            definition = definition,
            fixtures = fixtures,
        }

        local light = Instance.new("SpotLight")
        light.Name = "ArenaFocalSpot" .. i
        light.Face = Enum.NormalId.Front
        light.Color = colorFor(theme, definition.Role)
        light:SetAttribute("BaseColor", light.Color)
        light.Angle = math.clamp(tonumber(definition.Angle) or 50, 1, 180)
        light.Range = math.clamp(tonumber(definition.Range) or 48, 8, 80)
        light.Shadows = tier.Name == "High"
        light.Brightness = 0
        local hierarchyScale = math.clamp(tonumber(definition.Intensity) or 1, 0.20, 1.25)
        light:SetAttribute(
            "BaseBrightness",
            -- Keep architectural light accents, but avoid washing the
            -- dark runway and warning colors into saturated cyan.
            (tier.Name == "High" and 1.04 or 0.70) * hierarchyScale
        )
        light.Parent = anchor
        table.insert(lights, light)
    end

    liveBase = base
    basePoseConnections[#basePoseConnections + 1] =
        base:GetPropertyChangedSignal("Size"):Connect(queueAnchorSync)
    basePoseConnections[#basePoseConnections + 1] =
        base:GetPropertyChangedSignal("CFrame"):Connect(queueAnchorSync)
    -- Catch a size/pose update that happened while we created the lights.
    syncAnchorFrames()
    refresh(0.16)
end

-- All map, quality and late replication signals share a deferred
-- single-flight rebuild. Avoid allocating the fixtures twice in one turn.
local rebuildPending = false
local watchedMap = nil

local function scheduleRebuild()
    if rebuildPending then return end
    rebuildPending = true
    task.defer(function()
        rebuildPending = false
        rebuild()
    end)
end

local function bindMap(generated)
    if disconnectMapWatch then
        disconnectMapWatch()
        disconnectMapWatch = nil
    end
    watchedMap = generated
    if generated then
        disconnectMapWatch = MapVisualReadiness.watch(
            generated, "Arena", "Base", scheduleRebuild
        )
    else
        clear()
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap"
        and workspace:FindFirstChild("GeneratedMap") == child then
        bindMap(child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child == watchedMap then
        bindMap(workspace:FindFirstChild("GeneratedMap"))
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(scheduleRebuild)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    refresh(0.18)
end)

stateEvent.OnClientEvent:Connect(function(state)
    -- A malformed packet cannot terminate this client's light controller.
    if type(state) ~= "table" then return end
    local nextPhase = tostring(state.phase or "waiting")
    local nextFinalRush = nextPhase == "round" and state.finalRush == true
    local nextDisasters = type(state.disasterIds) == "table"
        and state.disasterIds or {}

    if not ArenaFocalLightingRules.visualStateChanged(
        phase, finalRush, activeDisasters,
        nextPhase, nextFinalRush, nextDisasters
    ) then
        return
    end

    phase = nextPhase
    finalRush = nextFinalRush
    activeDisasters = table.clone(nextDisasters)
    refresh(finalRush and 0.08 or 0.26)
end)

bindMap(workspace:FindFirstChild("GeneratedMap"))
scheduleRebuild()
