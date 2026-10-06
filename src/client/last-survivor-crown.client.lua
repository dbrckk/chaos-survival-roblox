local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalizationService = game:GetService("LocalizationService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)

local localPlayer = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local gui = Instance.new("BillboardGui")
gui.Name = "LastSurvivorCrown"
gui.ResetOnSpawn = false
gui.AlwaysOnTop = true
gui.LightInfluence = 0
gui.Size = UDim2.fromOffset(190, 48)
gui.StudsOffsetWorldSpace = Vector3.new(0, 3.7, 0)
gui.MaxDistance = 180
gui.Enabled = false
gui.Parent = localPlayer:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundColor3 = Color3.fromRGB(30, 24, 10)
label.BackgroundTransparency = 0.10
label.BorderSizePixel = 0
label.Font = Enum.Font.GothamBlack
label.Text = "★  " .. CoreLocalization.text(localeId, "RESULT_SOLE_SURVIVOR")
label.TextColor3 = Color3.fromRGB(255, 225, 100)
label.TextScaled = true
label.TextStrokeColor3 = Color3.fromRGB(60, 34, 5)
label.TextStrokeTransparency = 0.35
label.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = label

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 190, 55)
stroke.Thickness = 1.4
stroke.Transparency = 0.18
stroke.Parent = label

local scale = Instance.new("UIScale")
scale.Scale = 0.86
scale.Parent = label

local activeHighlight = nil
local activeAura = nil
local activeCharacter = nil
local activeKey = nil
local pulseClock = 0

local function clear()
    activeKey = nil
    activeCharacter = nil
    gui.Enabled = false
    gui.Adornee = nil

    if activeHighlight then
        activeHighlight:Destroy()
        activeHighlight = nil
    end

    if activeAura then
        activeAura:Destroy()
        activeAura = nil
    end
end

local function bindCharacter(key, character)
    local head = character and character:FindFirstChild("Head")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not key
        or not character
        or not head
        or not head:IsA("BasePart")
        or not humanoid
        or humanoid.Health <= 0
    then
        clear()
        return
    end

    if activeKey == key and activeCharacter == character then
        return
    end

    clear()
    activeKey = key
    activeCharacter = character
    gui.Adornee = head
    gui.Enabled = true

    label.TextTransparency = 1
    label.BackgroundTransparency = 1
    stroke.Transparency = 1
    scale.Scale = 0.78

    TweenService:Create(label, TweenInfo.new(0.18), {
        TextTransparency = 0,
        BackgroundTransparency = 0.10,
    }):Play()
    TweenService:Create(stroke, TweenInfo.new(0.18), {
        Transparency = 0.18,
    }):Play()
    TweenService:Create(
        scale,
        TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()

    local highlight = Instance.new("Highlight")
    highlight.Name = "LastSurvivorHighlightLocal"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 205, 70)
    highlight.FillTransparency = 0.88
    highlight.OutlineColor = Color3.fromRGB(255, 235, 145)
    highlight.OutlineTransparency = 0.10
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = character
    activeHighlight = highlight

    local aura = Instance.new("Attachment")
    aura.Name = "LastSurvivorAuraLocal"
    aura.Position = Vector3.new(0, 1.15, 0)
    aura.Parent = head

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "CrownMotes"
    emitter.Rate = 0
    emitter.Lifetime = NumberRange.new(0.45, 0.85)
    emitter.Speed = NumberRange.new(0.45, 1.2)
    emitter.Acceleration = Vector3.new(0, 1.8, 0)
    emitter.SpreadAngle = Vector2.new(55, 55)
    emitter.LightEmission = 1
    emitter.Color = ColorSequence.new(
        Color3.fromRGB(255, 235, 145),
        Color3.fromRGB(255, 155, 55)
    )
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18),
        NumberSequenceKeypoint.new(0.55, 0.11),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = aura

    local light = Instance.new("PointLight")
    light.Name = "CrownLight"
    light.Color = Color3.fromRGB(255, 205, 80)
    light.Brightness = 0.85
    light.Range = 8
    light.Shadows = false
    light.Parent = aura

    local tier = VfxQuality.get(localPlayer:GetAttribute("VfxQualityTier"))
    if tier.Name ~= "Low" then
        emitter:Emit(VfxQuality.particleCount(tier.Name, 16, 6))
    end
    light.Enabled = tier.Name == "High"

    activeAura = aura
end

local function bindPlayer(userId)
    local target = userId and Players:GetPlayerByUserId(userId)
    bindCharacter(
        target and ("player:" .. tostring(target.UserId)) or nil,
        target and target.Character or nil
    )
end

local function bindLastAI()
    local folder = workspace:FindFirstChild("AISurvivors")
    if not folder then
        clear()
        return
    end

    local candidate = nil
    local candidateSlot = nil
    local aliveCount = 0

    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") and model:GetAttribute("AISurvivor") == true then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                aliveCount += 1
                candidate = model
                candidateSlot = math.max(
                    0,
                    math.floor(tonumber(model:GetAttribute("AISurvivorSlot")) or 0)
                )
                if aliveCount > 1 then
                    break
                end
            end
        end
    end

    if aliveCount == 1 and candidate then
        bindCharacter("ai:" .. tostring(candidateSlot), candidate)
    else
        clear()
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    if state.phase ~= "round" or tonumber(state.survivorsAlive) ~= 1 then
        clear()
        return
    end

    local userId = tonumber(state.lastSurvivorUserId)
    if userId then
        bindPlayer(userId)
    elseif tonumber(state.aiSurvivors) == 1 then
        bindLastAI()
    else
        clear()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if activeKey == "player:" .. tostring(player.UserId) then
        clear()
    end
end)


local emitClock = 0
task.spawn(function()
    while true do
        if not activeAura or not activeAura.Parent or not activeHighlight then
            task.wait(0.18)
            continue
        end

        local tier = VfxQuality.get(localPlayer:GetAttribute("VfxQualityTier"))
        local reduced = localPlayer:GetAttribute("ReduceMotion") == true
        local cadence = tier.DecorUpdateInterval or math.max(1 / 30, tier.UpdateInterval)
        if reduced then
            cadence = math.max(cadence, 0.18)
        end
        local dt = task.wait(cadence)
        pulseClock += dt
        emitClock += dt
        local pulse = reduced
            and 0.5
            or ((math.sin(pulseClock * 3.4) + 1) * 0.5)

        activeHighlight.FillTransparency = math.clamp(
            0.91 - (pulse * 0.07 * tier.Scale),
            0.78,
            0.95
        )
        activeHighlight.OutlineTransparency = math.clamp(
            0.15 - (pulse * 0.08 * tier.Scale),
            0.02,
            0.24
        )
        stroke.Transparency = math.clamp(0.24 - pulse * 0.12, 0.06, 0.28)

        local light = activeAura:FindFirstChild("CrownLight")
        if light and light:IsA("PointLight") then
            light.Enabled = tier.Name == "High" and not reduced
            light.Brightness = reduced and 0.72 or (0.72 + pulse * 0.42)
        end

        if tier.Name ~= "Low"
            and not reduced
            and emitClock >= math.max(0.45, 0.72 / tier.Scale)
        then
            emitClock = 0
            local emitter = activeAura:FindFirstChild("CrownMotes")
            if emitter and emitter:IsA("ParticleEmitter") then
                emitter:Emit(VfxQuality.particleCount(tier.Name, 5, 2))
            end
        end
    end
end)
