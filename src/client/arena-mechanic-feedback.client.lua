local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalizationService = game:GetService("LocalizationService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
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
local flashTween = nil
local titleTweens = {}

-- Rapidly chained pads must never allow an old fade to hide a new reward.
local function stopTitleTweens()
    for _, tween in ipairs(titleTweens) do
        tween:Cancel()
    end
    table.clear(titleTweens)
end

local function titleTween(seconds, goals)
    local tween = TweenService:Create(
        overdriveLabel,
        TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        goals
    )
    table.insert(titleTweens, tween)
    tween:Play()
end

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
    if type(payload) ~= "table" then return end
    local now = os.clock()
    local gridClear = payload.mechanicName == "GRID CIRCUIT CLEAR"
    local skyrail = payload.mechanicName == "SKYRAIL SLIPSTREAM"
        or payload.mechanicName == "SKYRAIL CHAIN x2"
        or payload.mechanicName == "SKYRAIL ACE"
    local skyrailAce = payload.mechanicName == "SKYRAIL ACE"
    local fluxWeave = payload.mechanicName == "FLUX WEAVE x2"
        or payload.mechanicName == "FLUX MASTER"
    local fluxMaster = payload.mechanicName == "FLUX MASTER"
    -- The final challenge success should never be swallowed by a mobility
    -- pad's short visual cooldown during a fast last-node crossing.
    local orbitMaster = payload.mechanicName == "ORBIT MASTER"
    local priority = gridClear or fluxWeave or skyrailAce or fluxMaster
        or orbitMaster
    if now - lastTrigger < 0.18 and not priority then
        return
    end
    lastTrigger = now

    local overdrive = payload.overdrive == true
    local fluxRelay = payload.mechanicName == "FLUX RELAY" or fluxWeave
    local helixFlow = payload.mechanicName == "HELIX FLOW"
        or payload.mechanicName == "HELIX CHAIN x2"
        or payload.mechanicName == "ORBIT MASTER"
    local accent = overdrive
        and Color3.fromRGB(255, 210, 90)
        or (fluxRelay and Color3.fromRGB(88, 250, 229)
            or (helixFlow and Color3.fromRGB(106, 245, 176)
                or (ACCENTS[payload.variantId] or Color3.fromRGB(110, 210, 255))))
    if gridClear and not overdrive then
        accent = Color3.fromRGB(120, 245, 179)
    elseif skyrail and not overdrive then
        accent = skyrailAce and Color3.fromRGB(255, 214, 117)
            or Color3.fromRGB(100, 230, 250)
    elseif fluxMaster and not overdrive then
        accent = Color3.fromRGB(255, 206, 106)
    end
    local tier = currentVfxTier()
    local reduced = player:GetAttribute("ReduceMotion") == true
    if flashTween then
        flashTween:Cancel()
        flashTween = nil
    end
    flash.BackgroundColor3 = accent
    if reduced then
        -- Reduced Motion keeps the readable textual acknowledgement
        -- without a full-screen flash or particle overdraw.
        flash.BackgroundTransparency = 1
    else
        flash.BackgroundTransparency = 0.91 + ((1 - tier.Scale) * 0.04)
        flashTween = TweenService:Create(
            flash, TweenInfo.new(0.22), {BackgroundTransparency = 1}
        )
        flashTween:Play()
    end

    if not reduced and tier.Name ~= "Low" then
        pulseCharacter(accent)
    end

    if overdrive or fluxRelay or helixFlow or gridClear or skyrail then
        titleToken += 1
        local token = titleToken
        stopTitleTweens()
        local serverCue = overdrive and "OVERDRIVE BOOST"
            or (gridClear and "GRID CIRCUIT CLEAR"
                or (fluxWeave and tostring(payload.mechanicName)
                    or (skyrail and tostring(payload.mechanicName)
                        or (helixFlow and tostring(payload.mechanicName) or "FLUX RELAY"))))
        overdriveLabel.Text = CoreLocalization.mechanicFeedback(localeId, serverCue)
        overdriveLabel.TextColor3 = (overdrive or orbitMaster or skyrailAce or fluxMaster)
            and Color3.fromRGB(255, 225, 115)
            or (gridClear and Color3.fromRGB(197, 255, 218)
                or (helixFlow and Color3.fromRGB(184, 255, 216)
                    or Color3.fromRGB(147, 255, 232)))
        overdriveStroke.Color = (overdrive or orbitMaster or skyrailAce or fluxMaster)
            and Color3.fromRGB(255, 210, 90)
            or (gridClear and Color3.fromRGB(120, 245, 179)
                or (helixFlow and Color3.fromRGB(106, 245, 176)
                    or Color3.fromRGB(88, 250, 229)))
        overdriveLabel.Visible = true
        overdriveLabel.TextTransparency = 1
        overdriveLabel.BackgroundTransparency = 1
        if reduced then
            overdriveLabel.TextTransparency = 0
            overdriveLabel.BackgroundTransparency = 0.10
        else
            titleTween(0.12, {
                TextTransparency = 0,
                BackgroundTransparency = 0.10,
            })
        end
        task.delay(0.55, function()
            if token ~= titleToken then return end
            stopTitleTweens()
            if player:GetAttribute("ReduceMotion") == true then
                overdriveLabel.Visible = false
                overdriveLabel.TextTransparency = 1
                overdriveLabel.BackgroundTransparency = 1
                return
            end
            titleTween(0.18, {
                TextTransparency = 1,
                BackgroundTransparency = 1,
            })
            task.delay(0.20, function()
                if token == titleToken then
                    overdriveLabel.Visible = false
                end
            end)
        end)
    end
end)

-- Accessibility can be toggled while a tween is running.
player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    if player:GetAttribute("ReduceMotion") ~= true then return end
    if flashTween then
        flashTween:Cancel()
        flashTween = nil
    end
    flash.BackgroundTransparency = 1
    stopTitleTweens()
    if overdriveLabel.Visible then
        overdriveLabel.TextTransparency = 0
        overdriveLabel.BackgroundTransparency = 0.10
    end
end)
