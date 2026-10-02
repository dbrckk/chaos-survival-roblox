local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local feedbackEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundFeedback")

local lastCelebrationAt = 0

local function profile()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function rootPart()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function makeRing(root, color, radius, duration, height)
    local ring = Instance.new("Part")
    ring.Name = "LocalRoundCelebrationRing"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.08, 1, 1)
    ring.CFrame = CFrame.new(root.Position + Vector3.new(0, height or -2.35, 0))
        * CFrame.Angles(0, 0, math.rad(90))
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.CastShadow = false
    ring.Material = Enum.Material.Neon
    ring.Color = color
    ring.Transparency = 0.18
    ring.Parent = workspace

    TweenService:Create(
        ring,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = Vector3.new(0.08, radius, radius),
            Transparency = 1,
        }
    ):Play()
    Debris:AddItem(ring, duration + 0.08)
end

local function makeBurst(root, color, count, speed)
    local attachment = Instance.new("Attachment")
    attachment.Name = "LocalRoundCelebration"
    attachment.Position = Vector3.new(0, 0.2, 0)
    attachment.Parent = root

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "CelebrationBurst"
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(0.32, 0.70)
    emitter.Speed = NumberRange.new(speed * 0.65, speed)
    emitter.Acceleration = Vector3.new(0, 2.8, 0)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.LightEmission = 0.92
    emitter.Color = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.58))
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.30),
        NumberSequenceKeypoint.new(0.60, 0.18),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.06),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment
    emitter:Emit(count)

    Debris:AddItem(attachment, 1.0)
end

local function celebrate(feedback)
    local now = os.clock()
    if now - lastCelebrationAt < 0.7 then
        return
    end
    lastCelebrationAt = now

    local root = rootPart()
    if not root then
        return
    end

    local tier = profile()
    local survived = feedback.survived == true
    local momentumBest = math.max(0, math.floor(tonumber(feedback.momentumBest) or 0))
    local masterRound = survived
        and feedback.challengeCompleted == true
        and momentumBest >= 4

    local firstChaos = false
    if type(feedback.medals) == "table" then
        for _, medal in ipairs(feedback.medals) do
            if medal == "FIRST CHAOS" then
                firstChaos = true
                break
            end
        end
    end

    if survived then
        local color = masterRound and UITheme.Colors.Gold or UITheme.Colors.Green
        local ringRadius = masterRound and 22 or 16
        makeRing(root, color, ringRadius, masterRound and 0.62 or 0.48, -2.3)

        if tier.Name ~= "Low" then
            local count = VfxQuality.particleCount(
                tier.Name,
                masterRound and 28 or 18,
                masterRound and 10 or 7
            )
            makeBurst(root, color, count, masterRound and 8.5 or 6.3)
        end

        if masterRound and tier.Name == "High" then
            task.delay(0.10, function()
                local currentRoot = rootPart()
                if currentRoot then
                    makeRing(currentRoot, UITheme.Colors.Cyan, 29, 0.72, -2.15)
                end
            end)
        end
    else
        local color = UITheme.Colors.Red
        makeRing(root, color, tier.Name == "Low" and 8 or 11, 0.36, -2.3)

        if tier.Name == "High" then
            makeBurst(
                root,
                color:Lerp(UITheme.Colors.Panel, 0.40),
                VfxQuality.particleCount("High", 10, 4),
                3.5
            )
        end
    end

    if firstChaos then
        task.delay(0.08, function()
            local currentRoot = rootPart()
            if not currentRoot then
                return
            end

            makeRing(
                currentRoot,
                UITheme.Colors.Cyan,
                tier.Name == "Low" and 12 or 17,
                0.52,
                -2.15
            )

            if tier.Name ~= "Low" then
                makeBurst(
                    currentRoot,
                    UITheme.Colors.Cyan,
                    VfxQuality.particleCount(tier.Name, 12, 5),
                    4.8
                )
            end
        end)
    end
end

feedbackEvent.OnClientEvent:Connect(celebrate)
