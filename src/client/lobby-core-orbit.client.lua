local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local UITheme = require(ReplicatedStorage.Shared.UITheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local LobbyPresentationRules = require(ReplicatedStorage.Shared.LobbyPresentationRules)
local OrbitalReactor = require(script.Parent.ApprovedOrbitalReactorLandmarkMeshKit)
local LobbyMeshPreload = require(script.Parent.LobbyMeshPreload)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "LobbyCoreOrbitLocal"
folder.Parent = workspace

local nodes = {}
local phase = "waiting"
local center = Config.LobbyCenter + Vector3.new(0, 6.6, 0)
local tierName = "Medium"
local refreshProfile
local profileRefreshPending = false

local function scheduleProfileRefresh()
    if profileRefreshPending then return end
    profileRefreshPending = true
    task.defer(function()
        profileRefreshPending = false
        refreshProfile()
    end)
end

local geometryReady = LobbyMeshPreload.new(scheduleProfileRefresh)

local function fitFragment(part, source)
    local currentId = part:IsA("MeshPart") and part.MeshId or nil
    if currentId == (source and source.MeshId) then return part end
    local replacement = if source then source:Clone() else Instance.new("Part")
    if not replacement then return part end
    if source then
        replacement:ClearAllChildren()
        replacement.TextureID = ""
    end
    replacement.Name = part.Name
    replacement.Size = part.Size
    replacement.CFrame = part.CFrame
    replacement.Color = part.Color
    replacement.Material = part.Material
    replacement.Transparency = part.Transparency
    replacement.LocalTransparencyModifier = part.LocalTransparencyModifier
    replacement.Anchored = true
    replacement.CanCollide = false
    replacement.CanTouch = false
    replacement.CanQuery = false
    replacement.CastShadow = false
    for name, value in pairs(part:GetAttributes()) do
        replacement:SetAttribute(name, value)
    end
    replacement.Parent = folder
    part:Destroy()
    return replacement
end

refreshProfile = function()
    if #nodes == 0 then return end
    local pressure = tonumber(player:GetAttribute("OptionalVfxPressure")) or 0
    local source = tierName ~= "Low" and pressure < 1 and OrbitalReactor.coreProfile() or nil
    if source and not geometryReady(source) then source = nil end
    for _, entry in ipairs(nodes) do
        if entry.part.Parent == folder then
            entry.part = fitFragment(entry.part, source)
        end
        if entry.core and entry.core.Parent == folder then
            entry.core = fitFragment(entry.core, source)
        end
    end
end

local function clear()
    folder:ClearAllChildren()
    table.clear(nodes)
end

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function findCenter()
    return LobbyPresentationRules.coreOrbitCenter(workspace, Config.LobbyCenter)
end

local function rebuild()
    clear()
    center = findCenter()

    local tier = quality()
    tierName = tier.Name
    local count = tier.Name == "Low" and 3 or (tier.Name == "Medium" and 5 or 7)
    local radius = tier.Name == "Low" and 7.4 or 8.2
    local active = phase ~= "round" and phase ~= "ready"

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
        shard.Transparency = active and (tier.Name == "Low" and 0.42 or 0.24) or 1
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
            core.Transparency = active and (tier.Name == "High" and 0.06 or 0.14) or 1
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
    refreshProfile()
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
    phase = LobbyPresentationRules.roundPhase(state)
    refreshVisibility()
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    rebuild()
end)

player:GetAttributeChangedSignal("OptionalVfxPressure"):Connect(scheduleProfileRefresh)
local function orbitalSourceChanged(item)
    local holder = ReplicatedStorage:FindFirstChild("ApprovedOrbitalReactorLandmarkTemplates")
    if item.Name == "ApprovedOrbitalReactorLandmarkTemplates"
        or (holder and item:IsDescendantOf(holder)) then
        scheduleProfileRefresh()
    end
end
ReplicatedStorage.DescendantAdded:Connect(orbitalSourceChanged)
ReplicatedStorage.DescendantRemoving:Connect(orbitalSourceChanged)

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
        -- CenterPlatform may stream in after GeneratedMap. Recenter the
        -- same authored shards here without new loops or allocations.
        local newCenter = findCenter()
        if center ~= newCenter then
            center = newCenter
        end
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
