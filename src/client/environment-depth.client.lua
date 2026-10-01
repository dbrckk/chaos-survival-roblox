local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "ChaosEnvironmentDepthLocal"
folder.Parent = workspace

local structures = {}
local glows = {}
local currentAccent = VisualTheme.Accents.Cyan
local secondaryAccent = VisualTheme.Accents.Violet

local function clear()
    for _, instance in ipairs(structures) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
    table.clear(structures)
    table.clear(glows)
end

local function makePart(name, size, cframe, color, material, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Size = size
    p.CFrame = cframe
    p.Color = color
    p.Material = material
    p.Transparency = transparency or 0
    p.Parent = folder
    table.insert(structures, p)
    return p
end

local function rebuild()
    clear()

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local count = tier.Name == "Low" and 6 or (tier.Name == "Medium" and 8 or 10)
    local radius = 128

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2
        local height = 28 + ((i * 11) % 24)
        local width = 7 + ((i * 5) % 5)
        local position = Config.ArenaCenter + Vector3.new(
            math.cos(angle) * radius,
            (height * 0.5) - 5,
            math.sin(angle) * radius
        )

        local body = makePart(
            "DistantSpire" .. i,
            Vector3.new(width, height, width),
            CFrame.new(position) * CFrame.Angles(0, -angle, 0),
            VisualTheme.World.Deep:Lerp(VisualTheme.World.Metal, 0.28),
            VisualTheme.Materials.Structure,
            0.16
        )

        local cap = makePart(
            "DistantSpireGlow" .. i,
            Vector3.new(width + 1.6, 0.5, width + 1.6),
            body.CFrame + Vector3.new(0, (height * 0.5) + 0.4, 0),
            i % 2 == 0 and currentAccent or secondaryAccent,
            VisualTheme.Materials.Glow,
            tier.Name == "Low" and 0.48 or 0.32
        )
        table.insert(glows, cap)

        if tier.Name ~= "Low" and i % 2 == 1 then
            local bridgeAngle = angle + (math.pi / count)
            local bridgePosition = Config.ArenaCenter + Vector3.new(
                math.cos(bridgeAngle) * (radius - 10),
                24 + ((i * 3) % 10),
                math.sin(bridgeAngle) * (radius - 10)
            )
            local bridge = makePart(
                "DistantBridge" .. i,
                Vector3.new(18, 0.6, 2.2),
                CFrame.new(bridgePosition) * CFrame.Angles(0, -bridgeAngle, math.rad((i % 3) - 1)),
                VisualTheme.World.Metal,
                VisualTheme.Materials.Structure,
                0.24
            )
            bridge.CastShadow = false
        end
    end
end

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(rebuild)

stateEvent.OnClientEvent:Connect(function(state)
    local ids = state.disasterIds or {}
    local profile = DisasterVisuals.combine(ids)
    local secondary = ids[2] and DisasterVisuals.get(ids[2]) or nil

    if profile then
        currentAccent = profile.Accent
        secondaryAccent = secondary and secondary.Accent or VisualTheme.Accents.Violet
    else
        currentAccent = VisualTheme.Accents.Cyan
        secondaryAccent = VisualTheme.Accents.Violet
    end

    for i, glow in ipairs(glows) do
        if glow.Parent then
            glow.Color = i % 2 == 0 and currentAccent or secondaryAccent
        end
    end
end)

rebuild()
