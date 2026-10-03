local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local RoundEventPresentation = require(ReplicatedStorage.Shared.RoundEventPresentation)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local previousPhase = "waiting"
local lastFinalRush = false
local lastOverdrive = false

local function arenaBase()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    return base and base:IsA("BasePart") and base or nil
end

local function makeArenaRing(name, center, color, startRadius, endRadius, duration, reduced)
    local ring = Instance.new("Part")
    ring.Name = name
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(
        0.055,
        reduced and endRadius or startRadius,
        reduced and endRadius or startRadius
    )
    ring.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.CastShadow = false
    ring.Material = Enum.Material.Neon
    ring.Color = color
    ring.Transparency = reduced and 0.72 or 0.32
    ring.Parent = workspace

    TweenService:Create(
        ring,
        TweenInfo.new(
            reduced and math.min(duration, 0.34) or duration,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        {
            Size = Vector3.new(0.055, endRadius, endRadius),
            Transparency = 1,
        }
    ):Play()
    Debris:AddItem(ring, duration + 0.2)
end

local function pulseArena(state, finalRush)
    local base = arenaBase()
    if not base then
        return
    end

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local reduced = player:GetAttribute("ReduceMotion") == true
    local center = base.Position + Vector3.new(0, base.Size.Y * 0.5 + 0.13, 0)
    local radius = math.max(base.Size.X, base.Size.Z)
    local ids = type(state.disasterIds) == "table" and state.disasterIds or {}
    local firstColor = finalRush
        and UITheme.Colors.Orange
        or UITheme.disasterAccent(ids[1], UITheme.Colors.Cyan)
    local secondColor = finalRush
        and UITheme.Colors.Red
        or UITheme.disasterAccent(ids[2], UITheme.Colors.Violet)

    makeArenaRing(
        finalRush and "FinalRushArenaPulse" or "RoundStartArenaPulse",
        center,
        firstColor,
        finalRush and radius * 0.34 or 5,
        finalRush and radius * 0.96 or radius * 0.84,
        tier.Name == "Low" and 0.40 or 0.56,
        reduced
    )

    local secondRing = finalRush or (state.doubleChaos == true and ids[2] ~= nil)
    if secondRing and tier.Name ~= "Low" then
        task.delay(reduced and 0.04 or 0.09, function()
            if base.Parent then
                makeArenaRing(
                    finalRush and "FinalRushArenaPulseRed" or "RoundStartArenaPulseSecondary",
                    center + Vector3.new(0, 0.05, 0),
                    secondColor,
                    finalRush and radius * 0.44 or 8,
                    finalRush and radius * 1.04 or radius * 0.95,
                    0.62,
                    reduced
                )
            end
        end)
    end
end

local function rootPart()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return root and root:IsA("BasePart") and root or nil
end

local function pulse(color, strength, doubleRing)
    local root = rootPart()
    if not root then
        return
    end

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local reduced = player:GetAttribute("ReduceMotion") == true
    local scale = reduced and 0.42 or 1
    local radius = (10 + strength * 8) * scale
    local duration = reduced and 0.24 or (0.34 + strength * 0.12)

    local function makeRing(extraRadius, delaySeconds, alpha)
        task.delay(delaySeconds or 0, function()
            local currentRoot = rootPart()
            if not currentRoot then
                return
            end

            local ring = Instance.new("Part")
            ring.Name = "RoundTransitionPulseLocal"
            ring.Shape = Enum.PartType.Cylinder
            ring.Size = Vector3.new(0.06, 1, 1)
            ring.CFrame = CFrame.new(
                currentRoot.Position + Vector3.new(0, -2.35, 0)
            ) * CFrame.Angles(0, 0, math.rad(90))
            ring.Anchored = true
            ring.CanCollide = false
            ring.CanTouch = false
            ring.CanQuery = false
            ring.CastShadow = false
            ring.Material = Enum.Material.Neon
            ring.Color = color
            ring.Transparency = alpha or 0.22
            ring.Parent = workspace

            TweenService:Create(
                ring,
                TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Size = Vector3.new(0.06, radius + extraRadius, radius + extraRadius),
                    Transparency = 1,
                }
            ):Play()
            Debris:AddItem(ring, duration + 0.08)
        end)
    end

    makeRing(0, 0, reduced and 0.52 or 0.20)
    if doubleRing and tier.Name ~= "Low" and not reduced then
        makeRing(7, 0.07, 0.34)
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    local phase = tostring(state.phase or "waiting")
    local finalRush = phase == "round" and state.finalRush == true
    local overdrive = phase == "round" and state.overdrive == true
    local roundStarted = phase == "round" and previousPhase ~= "round"

    local kick = RoundEventPresentation.cameraKick(
        previousPhase,
        state,
        lastFinalRush,
        lastOverdrive
    )

    if roundStarted then
        pulseArena(state, false)
    elseif finalRush and not lastFinalRush then
        pulseArena(state, true)
    elseif kick > 0 then
        local ids = type(state.disasterIds) == "table" and state.disasterIds or {}
        local color = overdrive and not lastOverdrive
            and UITheme.Colors.Gold
            or RoundEventPresentation.accent(
                ids,
                function(id)
                    return UITheme.disasterAccent(id, UITheme.Colors.Cyan)
                end
            )

        pulse(
            color,
            kick,
            state.doubleChaos == true or overdrive
        )
    end

    previousPhase = phase
    lastFinalRush = finalRush
    lastOverdrive = overdrive
end)
