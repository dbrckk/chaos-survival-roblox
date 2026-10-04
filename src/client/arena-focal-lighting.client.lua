local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ArenaFocalLightingRules = require(ReplicatedStorage.Shared.ArenaFocalLightingRules)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "ArenaFocalLightingLocal"
folder.Parent = workspace

local lights = {}
local phase = "waiting"
local finalRush = false
local mapConnection = nil

local function clear()
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
    for _, light in ipairs(lights) do
        if light and light.Parent then
            TweenService:Create(
                light,
                TweenInfo.new(
                    duration or 0.24,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                ),
                {Brightness = targetBrightness(light)}
            ):Play()
        end
    end
end

local function rebuild()
    clear()

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not arena or not base or not base:IsA("BasePart") then
        return
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local theme = VisualTheme.arena(variant)
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local count = ArenaFocalLightingRules.sourceCount(tier.Name)
    if count <= 0 then
        return
    end

    local definitions = ArenaFocalLightingRules.definitions(variant)
    local halfX = base.Size.X * 0.5
    local halfZ = base.Size.Z * 0.5
    for i = 1, math.min(count, #definitions) do
        local definition = definitions[i]
        local offset = definition.Offset
        local worldPosition = base.CFrame:PointToWorldSpace(Vector3.new(
            offset.X * halfX,
            offset.Y,
            offset.Z * halfZ
        ))
        local focusLocal = Vector3.new(
            math.clamp(offset.X, -1, 1) * halfX * 0.42,
            4.0,
            math.clamp(offset.Z, -1, 1) * halfZ * 0.42
        )
        local target = base.CFrame:PointToWorldSpace(focusLocal)

        local anchor = Instance.new("Part")
        anchor.Name = "ArenaFocalLightAnchor" .. i
        anchor.Size = Vector3.new(0.18, 0.18, 0.18)
        anchor.CFrame = CFrame.lookAt(worldPosition, target)
        anchor.Anchored = true
        anchor.CanCollide = false
        anchor.CanTouch = false
        anchor.CanQuery = false
        anchor.CastShadow = false
        anchor.Transparency = 1
        anchor.Parent = folder

        local light = Instance.new("SpotLight")
        light.Name = "ArenaFocalSpot" .. i
        light.Face = Enum.NormalId.Front
        light.Color = colorFor(theme, definition.Role)
        light.Angle = math.clamp(tonumber(definition.Angle) or 50, 1, 180)
        light.Range = math.clamp(tonumber(definition.Range) or 48, 8, 80)
        light.Shadows = tier.Name == "High"
        light.Brightness = 0
        light:SetAttribute(
            "BaseBrightness",
            tier.Name == "High" and 1.22 or 0.82
        )
        light.Parent = anchor
        table.insert(lights, light)
    end

    refresh(0.16)
end

local function bindMap()
    if mapConnection then
        mapConnection:Disconnect()
        mapConnection = nil
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    if generated then
        mapConnection = generated.ChildAdded:Connect(function(child)
            if child.Name == "Arena" then
                task.delay(0.08, rebuild)
            end
        end)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(function()
            bindMap()
            rebuild()
        end)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clear()
        bindMap()
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(rebuild)

stateEvent.OnClientEvent:Connect(function(state)
    phase = tostring(state.phase or "waiting")
    finalRush = phase == "round" and state.finalRush == true
    refresh(finalRush and 0.08 or 0.26)
end)

bindMap()
rebuild()
