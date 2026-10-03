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

    local kick = RoundEventPresentation.cameraKick(
        previousPhase,
        state,
        lastFinalRush,
        lastOverdrive
    )

    if kick > 0 then
        local color
        if finalRush and not lastFinalRush then
            color = UITheme.Colors.Orange
        elseif overdrive and not lastOverdrive then
            color = UITheme.Colors.Gold
        else
            local ids = type(state.disasterIds) == "table" and state.disasterIds or {}
            color = RoundEventPresentation.accent(
                ids,
                function(id)
                    return UITheme.disasterAccent(id, UITheme.Colors.Cyan)
                end
            )
        end

        pulse(color, kick, state.doubleChaos == true or finalRush)
    end

    previousPhase = phase
    lastFinalRush = finalRush
    lastOverdrive = overdrive
end)
