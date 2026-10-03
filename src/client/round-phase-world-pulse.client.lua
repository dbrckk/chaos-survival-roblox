local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "RoundPhaseWorldPulseLocal"
folder.Parent = workspace

local previousPhase = "waiting"
local lastFinalRush = false

local function arenaBase()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    return base and base:IsA("BasePart") and base or nil
end

local function makeRing(name, center, color, startRadius, endRadius, duration, reducedMotion)
    local ring = Instance.new("Part")
    ring.Name = name
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(
        0.055,
        reducedMotion and endRadius or startRadius,
        reducedMotion and endRadius or startRadius
    )
    ring.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.CastShadow = false
    ring.Material = Enum.Material.Neon
    ring.Color = color
    ring.Transparency = reducedMotion and 0.72 or 0.32
    ring.Parent = folder

    TweenService:Create(
        ring,
        TweenInfo.new(
            reducedMotion and math.min(duration, 0.34) or duration,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        {
            Size = Vector3.new(0.055, endRadius, endRadius),
            Transparency = 1,
        }
    ):Play()

    Debris:AddItem(ring, duration + 0.3)
end

local function pulseRoundStart(state)
    local base = arenaBase()
    if not base then
        return
    end

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local reducedMotion = player:GetAttribute("ReduceMotion") == true
    local center = base.Position + Vector3.new(0, base.Size.Y * 0.5 + 0.12, 0)
    local radius = math.max(base.Size.X, base.Size.Z)
    local ids = type(state.disasterIds) == "table" and state.disasterIds or {}
    local primary = UITheme.disasterAccent(ids[1], UITheme.Colors.Cyan)
    local secondary = UITheme.disasterAccent(ids[2], UITheme.Colors.Violet)

    makeRing(
        "RoundStartPrimary",
        center,
        primary,
        5,
        radius * 0.82,
        tier.Name == "Low" and 0.44 or 0.58,
        reducedMotion
    )

    if state.doubleChaos == true and ids[2] and tier.Name ~= "Low" then
        task.delay(reducedMotion and 0.04 or 0.10, function()
            if base.Parent then
                makeRing(
                    "RoundStartSecondary",
                    center + Vector3.new(0, 0.06, 0),
                    secondary,
                    8,
                    radius * 0.94,
                    0.64,
                    reducedMotion
                )
            end
        end)
    end

    if tier.Name == "High" and not reducedMotion then
        local core = Instance.new("Part")
        core.Name = "RoundStartCore"
        core.Shape = Enum.PartType.Cylinder
        core.Size = Vector3.new(0.04, radius * 0.16, radius * 0.16)
        core.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
        core.Anchored = true
        core.CanCollide = false
        core.CanTouch = false
        core.CanQuery = false
        core.CastShadow = false
        core.Material = Enum.Material.Neon
        core.Color = primary:Lerp(secondary, state.doubleChaos == true and 0.35 or 0)
        core.Transparency = 0.50
        core.Parent = folder

        TweenService:Create(
            core,
            TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = Vector3.new(0.04, radius * 0.34, radius * 0.34),
                Transparency = 1,
            }
        ):Play()
        Debris:AddItem(core, 0.55)
    end
end

local function pulseFinalRush()
    local base = arenaBase()
    if not base then
        return
    end

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local reducedMotion = player:GetAttribute("ReduceMotion") == true
    local center = base.Position + Vector3.new(0, base.Size.Y * 0.5 + 0.16, 0)
    local radius = math.max(base.Size.X, base.Size.Z)

    makeRing(
        "FinalRushPulse",
        center,
        UITheme.Colors.Orange,
        radius * 0.35,
        radius * 0.95,
        tier.Name == "Low" and 0.36 or 0.52,
        reducedMotion
    )

    if tier.Name ~= "Low" then
        task.delay(reducedMotion and 0.04 or 0.08, function()
            if base.Parent then
                makeRing(
                    "FinalRushPulseRed",
                    center + Vector3.new(0, 0.05, 0),
                    UITheme.Colors.Red,
                    radius * 0.46,
                    radius * 1.04,
                    0.58,
                    reducedMotion
                )
            end
        end)
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    local phase = tostring(state.phase or "waiting")
    local finalRush = phase == "round" and state.finalRush == true

    if phase == "round" and previousPhase ~= "round" then
        pulseRoundStart(state)
    end

    if finalRush and not lastFinalRush then
        pulseFinalRush()
    end

    previousPhase = phase
    lastFinalRush = finalRush
end)
