local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UITheme = require(ReplicatedStorage.Shared.UITheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

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
        local accent = i % 3 == 0
            and UITheme.Colors.Orange
            or (i % 2 == 0 and UITheme.Colors.Violet or UITheme.Colors.Cyan)

        local shard = Instance.new("Part")
        shard.Name = "ChaosCoreOrbitShard" .. i
        shard.Size = tier.Name == "Low"
            and Vector3.new(0.28, 0.58, 0.28)
            or Vector3.new(0.34, tier.Name == "High" and 0.92 or 0.78, 0.34)
        shard.Anchored = true
        shard.CanCollide = false
        shard.CanTouch = false
        shard.CanQuery = false
        shard.CastShadow = false
        shard.Material = Enum.Material.Glass
        shard.Color = VisualTheme.World.MetalLight:Lerp(accent, tier.Name == "Low" and 0.32 or 0.48)
        shard.Transparency = tier.Name == "Low" and 0.42 or 0.24
        shard.Parent = folder

        local core = nil
        if tier.Name ~= "Low" then
            core = Instance.new("Part")
            core.Name = "ChaosCoreOrbitShardCore" .. i
            core.Size = Vector3.new(
                0.12,
                tier.Name == "High" and 0.58 or 0.46,
                0.12
            )
            core.Anchored = true
            core.CanCollide = false
            core.CanTouch = false
            core.CanQuery = false
            core.CastShadow = false
            core.Material = Enum.Material.Neon
            core.Color = accent:Lerp(Color3.new(1, 1, 1), 0.18)
            core.Transparency = tier.Name == "High" and 0.06 or 0.14
            core.Parent = folder
        end

        nodes[#nodes + 1] = {
            part = shard,
            core = core,
            angle = ((i - 1) / count) * math.pi * 2,
            radius = radius + ((i % 2) * 0.7),
            height = ((i % 3) - 1) * 0.75,
            spin = 0.18 + (i % 3) * 0.035,
            phase = i * 0.73,
            transparency = tier.Name == "Low" and 0.42 or 0.24,
            coreTransparency = tier.Name == "High" and 0.06 or 0.14,
        }
    end
end

local function refreshVisibility()
    local active = phase ~= "round" and phase ~= "ready"
    for _, entry in ipairs(nodes) do
        local part = entry.part
        if part and part.Parent then
            part.Transparency = active and entry.transparency or 1
        end
        local core = entry.core
        if core and core.Parent then
            core.Transparency = active and entry.coreTransparency or 1
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
                    local y = entry.height + math.sin(now * 1.15 + entry.phase) * amplitude
                    local position = center + Vector3.new(
                        math.cos(angle) * entry.radius,
                        y,
                        math.sin(angle) * entry.radius
                    )
                    local rotation = reduced
                        and CFrame.Angles(math.rad(45), angle, math.rad(45))
                        or CFrame.Angles(
                            math.rad(45) + math.sin(now * 0.62 + i) * 0.10,
                            angle + now * entry.spin,
                            math.rad(45)
                        )
                    local cframe = CFrame.new(position) * rotation
                    part.CFrame = cframe

                    local core = entry.core
                    if core and core.Parent then
                        core.CFrame = cframe
                    end
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
