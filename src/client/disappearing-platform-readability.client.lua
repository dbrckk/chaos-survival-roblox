local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "DisappearingPlatformReadabilityLocal"
folder.Parent = workspace

local tracked = {}
local clock = 0
local updateClock = 0

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

    local state = {
        instances = {north, south, west, east},
        north = north,
        south = south,
        west = west,
        east = east,
    }
    tracked[part] = state
    return state
end

local function layout(part, state, phase, now)
    local tier = profile()
    local low = tier.Name == "Low"
    local halfX = part.Size.X * 0.5
    local halfZ = part.Size.Z * 0.5
    local y = part.Position.Y + part.Size.Y * 0.5 + 0.08
    local thickness = low and 0.12 or 0.16
    local pulse = (math.sin(now * (phase == "Gone" and 4.2 or 7.2)) + 1) * 0.5
    local baseAlpha = phase == "Gone" and 0.62 or (low and 0.48 or 0.28)
    local alpha = math.clamp(baseAlpha + pulse * (phase == "Gone" and 0.18 or 0.24), 0, 0.9)

    state.north.Size = Vector3.new(part.Size.X + 0.35, 0.06, thickness)
    state.south.Size = state.north.Size
    state.west.Size = Vector3.new(thickness, 0.06, part.Size.Z + 0.35)
    state.east.Size = state.west.Size

    state.north.CFrame = CFrame.new(part.Position.X, y, part.Position.Z - halfZ)
    state.south.CFrame = CFrame.new(part.Position.X, y, part.Position.Z + halfZ)
    state.west.CFrame = CFrame.new(part.Position.X - halfX, y, part.Position.Z)
    state.east.CFrame = CFrame.new(part.Position.X + halfX, y, part.Position.Z)

    for _, edge in ipairs(state.instances) do
        edge.Transparency = alpha
    end
end

local function refreshPart(part)
    local phase = part:GetAttribute("CollapsePhase")
    if phase ~= "Warning" and phase ~= "Gone" then
        clearState(part)
        return
    end
    ensureState(part)
end

local function bindPart(part)
    if not part:IsA("BasePart") or not part:IsDescendantOf(workspace) then
        return
    end

    part:GetAttributeChangedSignal("CollapsePhase"):Connect(function()
        refreshPart(part)
    end)

    if part:GetAttribute("CollapsePhase") ~= nil then
        refreshPart(part)
    end
end

workspace.DescendantAdded:Connect(function(instance)
    if instance:IsA("BasePart") then
        bindPart(instance)
    end
end)

workspace.DescendantRemoving:Connect(function(instance)
    if tracked[instance] then
        clearState(instance)
    end
end)

for _, descendant in ipairs(workspace:GetDescendants()) do
    if descendant:IsA("BasePart") and descendant:GetAttribute("CollapsePhase") ~= nil then
        bindPart(descendant)
    end
end

RunService.RenderStepped:Connect(function(dt)
    if next(tracked) == nil then
        return
    end

    clock += dt
    updateClock += dt

    local tier = profile()
    local cadence = tier.Name == "Low" and 0.12 or 0.075
    if updateClock < cadence then
        return
    end
    updateClock = 0

    for part, state in pairs(tracked) do
        if not part.Parent then
            clearState(part)
        else
            local phase = part:GetAttribute("CollapsePhase")
            if phase == "Warning" or phase == "Gone" then
                layout(part, state, phase, clock)
            else
                clearState(part)
            end
        end
    end
end)
