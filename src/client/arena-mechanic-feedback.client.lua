local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local feedbackEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ArenaMechanicFeedback")

local gui = Instance.new("ScreenGui")
gui.Name = "ArenaMechanicFeedback"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 60
gui.Parent = player:WaitForChild("PlayerGui")

local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(110, 210, 255)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.ZIndex = 1
flash.Parent = gui

local ACCENTS = {
    Classic = Color3.fromRGB(90, 180, 255),
    Towers = Color3.fromRGB(65, 220, 255),
    Crossroads = Color3.fromRGB(235, 105, 220),
    Orbital = Color3.fromRGB(65, 255, 205),
}

local overdriveLabel = Instance.new("TextLabel")
overdriveLabel.AnchorPoint = Vector2.new(0.5, 0.5)
overdriveLabel.Position = UDim2.fromScale(0.5, 0.61)
overdriveLabel.Size = UDim2.fromOffset(290, 52)
overdriveLabel.BackgroundColor3 = Color3.fromRGB(35, 28, 14)
overdriveLabel.BackgroundTransparency = 1
overdriveLabel.BorderSizePixel = 0
overdriveLabel.Font = Enum.Font.GothamBlack
overdriveLabel.Text = "OVERDRIVE BOOST"
overdriveLabel.TextColor3 = Color3.fromRGB(255, 225, 115)
overdriveLabel.TextScaled = true
overdriveLabel.TextTransparency = 1
overdriveLabel.Visible = false
overdriveLabel.ZIndex = 4
overdriveLabel.Parent = gui

local overdriveCorner = Instance.new("UICorner")
overdriveCorner.CornerRadius = UDim.new(0, 14)
overdriveCorner.Parent = overdriveLabel

local overdriveStroke = Instance.new("UIStroke")
overdriveStroke.Color = Color3.fromRGB(255, 210, 90)
overdriveStroke.Thickness = 1.5
overdriveStroke.Transparency = 0.25
overdriveStroke.Parent = overdriveLabel

local lastTrigger = 0
local titleToken = 0

local function currentVfxTier()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function pulseCharacter(accent)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "MobilityBurst"
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(0.18, 0.32)
    emitter.Speed = NumberRange.new(2, 5)
    emitter.SpreadAngle = Vector2.new(70, 70)
    emitter.LightEmission = 0.9
    emitter.Color = ColorSequence.new(accent, Color3.new(1, 1, 1))
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.26),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.08),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = root
    local tierName = player:GetAttribute("VfxQualityTier")
    local reduced = player:GetAttribute("ReduceMotion") == true
    emitter:Emit(
        VfxQuality.particleCount(
            tierName,
            reduced and 7 or 18,
            reduced and 3 or 6
        )
    )

    task.delay(0.45, function()
        if emitter.Parent then
            emitter:Destroy()
        end
    end)
end

feedbackEvent.OnClientEvent:Connect(function(payload)
    local now = os.clock()
    local gridClear = payload.mechanicName == "GRID CIRCUIT CLEAR"
    -- The final challenge success should never be swallowed by a mobility
    -- pad's short visual cooldown during a fast last-node crossing.
    if now - lastTrigger < 0.18 and not gridClear then
        return
    end
    lastTrigger = now

    local overdrive = payload.overdrive == true
    local fluxRelay = payload.mechanicName == "FLUX RELAY"
    local helixFlow = payload.mechanicName == "HELIX FLOW"
        or payload.mechanicName == "HELIX CHAIN x2"
        or payload.mechanicName == "ORBIT MASTER"
    local orbitMaster = payload.mechanicName == "ORBIT MASTER"
    local accent = overdrive
        and Color3.fromRGB(255, 210, 90)
        or (fluxRelay and Color3.fromRGB(88, 250, 229)
            or (helixFlow and Color3.fromRGB(106, 245, 176)
                or (ACCENTS[payload.variantId] or Color3.fromRGB(110, 210, 255))))
    if gridClear and not overdrive then
        accent = Color3.fromRGB(120, 245, 179)
    end
    local tier = currentVfxTier()
    local reduced = player:GetAttribute("ReduceMotion") == true
    flash.BackgroundColor3 = accent
    flash.BackgroundTransparency = reduced
        and 0.97
        or (0.91 + ((1 - tier.Scale) * 0.04))
    TweenService:Create(
        flash,
        TweenInfo.new(reduced and 0.12 or 0.22),
        {BackgroundTransparency = 1}
    ):Play()

    pulseCharacter(accent)

    if overdrive or fluxRelay or helixFlow or gridClear then
        titleToken += 1
        local token = titleToken
        overdriveLabel.Text = overdrive and "OVERDRIVE BOOST"
            or (gridClear and "GRID CIRCUIT CLEAR"
                or (helixFlow and tostring(payload.mechanicName) or "FLUX RELAY"))
        overdriveLabel.TextColor3 = (overdrive or orbitMaster)
            and Color3.fromRGB(255, 225, 115)
            or (gridClear and Color3.fromRGB(197, 255, 218)
                or (helixFlow and Color3.fromRGB(184, 255, 216)
                    or Color3.fromRGB(147, 255, 232)))
        overdriveStroke.Color = (overdrive or orbitMaster)
            and Color3.fromRGB(255, 210, 90)
            or (gridClear and Color3.fromRGB(120, 245, 179)
                or (helixFlow and Color3.fromRGB(106, 245, 176)
                    or Color3.fromRGB(88, 250, 229)))
        overdriveLabel.Visible = true
        overdriveLabel.TextTransparency = 1
        overdriveLabel.BackgroundTransparency = 1
        TweenService:Create(overdriveLabel, TweenInfo.new(0.12), {
            TextTransparency = 0,
            BackgroundTransparency = 0.10,
        }):Play()
        task.delay(0.55, function()
            if token ~= titleToken then return end
            TweenService:Create(overdriveLabel, TweenInfo.new(0.18), {
                TextTransparency = 1,
                BackgroundTransparency = 1,
            }):Play()
            task.delay(0.2, function()
                if token == titleToken then
                    overdriveLabel.Visible = false
                end
            end)
        end)
    end
end)
