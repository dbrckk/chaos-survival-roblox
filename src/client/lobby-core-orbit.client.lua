local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UITheme = require(ReplicatedStorage.Shared.UITheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "LobbyCoreOrbitLocal"
folder.Parent = workspace

local nodes = {}
local phase = "waiting"
local center = Config.LobbyCenter + Vector3.new(0, 6.6, 0)
local tierName = "Medium"

local function clear()
    folder:ClearAllChildren()
    table.clear(nodes)
end

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function findCenter()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    local decor = lobby and lobby:FindFirstChild("Decor")
    local platform = decor and decor:FindFirstChild("CenterPlatform")
    if platform and platform:IsA("BasePart") then
        return platform.Position + Vector3.new(0, 5.2, 0)
    end
    return Config.LobbyCenter + Vector3.new(0, 6.6, 0)
end

local function rebuild()
    clear()
    center = findCenter()

    local tier = quality()
    tierName = tier.Name
    local count = tier.Name == "Low" and 3 or (tier.Name == "Medium" and 5 or 7)
    local radius = tier.Name == "Low" and 7.4 or 8.2

    for i = 1, count do
        local node = Instance.new("Part")
        node.Name = "ChaosCoreOrbitNode" .. i
        node.Shape = Enum.PartType.Ball
        node.Size = Vector3.new(0.55, 0.55, 0.55)
        node.Anchored = true
        node.CanCollide = false
        node.CanTouch = false
        node.CanQuery = false
        node.CastShadow = false
        node.Material = Enum.Material.Neon
        node.Color = i % 2 == 0 and UITheme.Colors.Violet or UITheme.Colors.Cyan
        node.Transparency = tier.Name == "Low" and 0.36 or 0.16
        node.Parent = folder

        nodes[#nodes + 1] = {
            part = node,
            angle = ((i - 1) / count) * math.pi * 2,
            radius = radius + ((i % 2) * 0.7),
            height = ((i % 3) - 1) * 0.75,
        }
    end
end

local function refreshVisibility()
    local active = phase ~= "round" and phase ~= "ready"
    for _, entry in ipairs(nodes) do
        local part = entry.part
        if part and part.Parent then
            part.Transparency = active
                and (tierName == "Low" and 0.36 or 0.16)
                or 1
        end
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    phase = tostring(state.phase or "waiting")
    refreshVisibility()
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    rebuild()
    refreshVisibility()
end)

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

task.spawn(function()
    while true do
        local active = phase ~= "round" and phase ~= "ready"

        if active then
            local reduced = player:GetAttribute("ReduceMotion") == true
            local speed = reduced and 0.10 or 0.42
            local amplitude = reduced and 0.12 or 0.55
            local now = os.clock()

            for i, entry in ipairs(nodes) do
                local part = entry.part
                if part and part.Parent then
                    local angle = entry.angle + now * speed
                    local y = entry.height + math.sin(now * 1.15 + i) * amplitude
                    part.Position = center + Vector3.new(
                        math.cos(angle) * entry.radius,
                        y,
                        math.sin(angle) * entry.radius
                    )
                end
            end

            local cadence = reduced and 0.22
                or (tierName == "Low" and 0.16 or 0.10)
            task.wait(cadence)
        else
            task.wait(0.60)
        end
    end
end)
