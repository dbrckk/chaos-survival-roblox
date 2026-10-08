local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalizationService = game:GetService("LocalizationService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "ResultSurvivorSpotlightsLocal"
folder.Parent = workspace

local active = {}

local function clear()
    for _, bundle in pairs(active) do
        for _, instance in ipairs(bundle) do
            if instance and instance.Parent then
                instance:Destroy()
            end
        end
    end
    table.clear(active)
end

local function spotlightModel(key, model, labelText, localFocus)
    if active[key] then
        return
    end

    local head = model and model:FindFirstChild("Head")
    local root = model and model:FindFirstChild("HumanoidRootPart")
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    if not model
        or not head
        or not head:IsA("BasePart")
        or not root
        or not root:IsA("BasePart")
        or not humanoid
        or humanoid.Health <= 0
    then
        return
    end

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local bundle = {}
    local accent = localFocus
        and Color3.fromRGB(95, 215, 255)
        or Color3.fromRGB(85, 235, 165)
    local textColor = localFocus
        and Color3.fromRGB(215, 248, 255)
        or Color3.fromRGB(175, 255, 205)

    local highlight = Instance.new("Highlight")
    highlight.Name = "ResultSurvivorHighlight"
    highlight.Adornee = model
    highlight.FillColor = accent
    highlight.FillTransparency = localFocus and 0.80 or 0.88
    highlight.OutlineColor = accent:Lerp(Color3.new(1, 1, 1), 0.52)
    highlight.OutlineTransparency = localFocus and 0.02 or 0.08
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = model
    table.insert(bundle, highlight)

    local gui = Instance.new("BillboardGui")
    gui.Name = "ResultSurvivorBadge"
    gui.Adornee = head
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.Size = UDim2.fromOffset(localFocus and 178 or 150, 38)
    gui.StudsOffsetWorldSpace = Vector3.new(0, localFocus and 3.6 or 3.3, 0)
    gui.MaxDistance = 160
    gui.Parent = folder
    table.insert(bundle, gui)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = localFocus
        and Color3.fromRGB(15, 38, 52)
        or Color3.fromRGB(14, 40, 30)
    label.BackgroundTransparency = 0.12
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBlack
    label.Text = labelText or CoreLocalization.text(localeId, "SURVIVOR_LABEL")
    label.TextColor3 = textColor
    label.TextScaled = true
    label.TextTransparency = 1
    label.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = label

    local stroke = Instance.new("UIStroke")
    stroke.Color = accent
    stroke.Thickness = localFocus and 1.6 or 1.2
    stroke.Transparency = localFocus and 0.12 or 0.28
    stroke.Parent = label

    TweenService:Create(label, TweenInfo.new(0.18), {TextTransparency = 0}):Play()

    if tier.Name ~= "Low" then
        local reducedMotion = player:GetAttribute("ReduceMotion") == true

        if not reducedMotion then
            local motes = Instance.new("Attachment")
            motes.Name = "ResultSurvivorMotes"
            motes.Position = Vector3.new(0, 0.4, 0)
            motes.Parent = root
            table.insert(bundle, motes)

            local emitter = Instance.new("ParticleEmitter")
            emitter.Name = "ResultSurvivorMotesEmitter"
            emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            emitter.Rate = (localFocus and 5 or 3) * tier.ParticleScale
            emitter.Lifetime = NumberRange.new(0.55, 0.95)
            emitter.Speed = NumberRange.new(0.25, localFocus and 1.0 or 0.75)
            emitter.Acceleration = Vector3.new(0, 1.4, 0)
            emitter.SpreadAngle = Vector2.new(55, 55)
            emitter.LightEmission = 0.88
            emitter.LightInfluence = 0
            emitter.Color = ColorSequence.new(
                accent:Lerp(Color3.new(1, 1, 1), 0.18),
                accent
            )
            emitter.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, localFocus and 0.18 or 0.14),
                NumberSequenceKeypoint.new(0.62, localFocus and 0.11 or 0.09),
                NumberSequenceKeypoint.new(1, 0),
            })
            emitter.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.18),
                NumberSequenceKeypoint.new(1, 1),
            })
            emitter.Parent = motes
        end

        local light = Instance.new("PointLight")
        light.Name = "ResultSurvivorGlow"
        light.Color = accent
        light.Brightness = (localFocus and 1.35 or 1.0)
            * tier.Scale
            * (reducedMotion and 0.72 or 1)
        light.Range = (localFocus and 12 or 9) + 3 * tier.Scale
        light.Shadows = false
        light.Parent = root
        table.insert(bundle, light)
    end

    active[key] = bundle
end

local function spotlightPlayer(target)
    local isLocal = target == player
    spotlightModel(
        "player:" .. tostring(target.UserId),
        target.Character,
        isLocal
            and CoreLocalization.text(localeId, "YOU_SURVIVED")
            or CoreLocalization.text(localeId, "SURVIVOR_LABEL"),
        isLocal
    )
end

local function spotlightBots(desired)
    local bots = workspace:FindFirstChild("AISurvivors")
    if not bots then
        return
    end

    for _, model in ipairs(bots:GetChildren()) do
        if model:IsA("Model") and model:GetAttribute("AISurvivor") == true then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local slot = tonumber(model:GetAttribute("AISurvivorSlot")) or 0
                local key = "ai:" .. tostring(slot)
                desired[key] = true
                spotlightModel(
                    key,
                    model,
                    CoreLocalization.text(localeId, "SURVIVOR_LABEL"),
                    false
                )
            end
        end
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    if state.phase ~= "result" then
        clear()
        return
    end

    local desired = {}
    local ids = type(state.survivorUserIds) == "table" and state.survivorUserIds or {}
    for _, userId in ipairs(ids) do
        local numericId = tonumber(userId)
        if numericId then
            local key = "player:" .. tostring(numericId)
            desired[key] = true
            local target = Players:GetPlayerByUserId(numericId)
            if target then
                spotlightPlayer(target)
            end
        end
    end

    spotlightBots(desired)

    for key, bundle in pairs(active) do
        if not desired[key] then
            for _, instance in ipairs(bundle) do
                if instance and instance.Parent then
                    instance:Destroy()
                end
            end
            active[key] = nil
        end
    end
end)

Players.PlayerRemoving:Connect(function(target)
    local bundle = active["player:" .. tostring(target.UserId)]
    if bundle then
        for _, instance in ipairs(bundle) do
            if instance and instance.Parent then
                instance:Destroy()
            end
        end
        active["player:" .. tostring(target.UserId)] = nil
    end
end)
