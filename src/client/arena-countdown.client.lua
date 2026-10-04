local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local previousPhase = "waiting"

local function centerBeacon()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local decor = arena and arena:FindFirstChild("Decor")
    local beacon = decor and decor:FindFirstChild("CenterBeacon")
    return beacon and beacon:IsA("BasePart") and beacon or nil
end

local function accentFor(state)
    if state.doubleChaos then
        return UITheme.Colors.Magenta
    end

    local primary = state.disasterIds and state.disasterIds[1]
    return UITheme.disasterAccent(primary, UITheme.Colors.Cyan)
end

local function goWave(color)
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    if tier.Name == "Low" then
        return
    end

    local beacon = centerBeacon()
    if not beacon then
        return
    end

    local ring = Instance.new("Part")
    ring.Name = "ArenaGoWaveLocal"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.10, 3.5, 3.5)
    ring.CFrame = CFrame.new(beacon.Position - Vector3.new(0, 6.85, 0))
        * CFrame.Angles(0, 0, math.rad(90))
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.CastShadow = false
    ring.Material = Enum.Material.Neon
    ring.Color = color
    ring.Transparency = 0.22
    ring.Parent = workspace

    TweenService:Create(
        ring,
        TweenInfo.new(0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = Vector3.new(0.10, 30 * tier.Scale, 30 * tier.Scale),
            Transparency = 1,
        }
    ):Play()

    Debris:AddItem(ring, 0.55)
end

stateEvent.OnClientEvent:Connect(function(state)
    local phase = tostring(state.phase or "waiting")

    if phase == "round" and previousPhase == "ready" then
        goWave(accentFor(state))
    end

    previousPhase = phase
end)
