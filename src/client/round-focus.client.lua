local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)

local player = Players.LocalPlayer
local touchDevice = UserInputService.TouchEnabled
local localeId = LocalizationService.RobloxLocaleId
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosRoundFocus"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 18
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Name = "FocusBar"
root.AnchorPoint = Vector2.new(0.5, touchDevice and 0.5 or 1)
root.Position = touchDevice
    and UDim2.fromScale(0.5, 0.77)
    or UDim2.new(0.5, 0, 1, -18)
root.Size = touchDevice
    and UDim2.new(0.62, 0, 0, 48)
    or UDim2.new(0.82, 0, 0, 54)
root.BackgroundColor3 = UITheme.Colors.Panel
root.BackgroundTransparency = 0.05
root.BorderSizePixel = 0
root.Visible = false
root.Parent = gui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(250, 48)
sizeConstraint.MaxSize = Vector2.new(620, 58)
sizeConstraint.Parent = root

UITheme.addCorner(root, UITheme.Corners.Large)
local stroke = UITheme.addStroke(root, UITheme.Colors.Blue, 1.2, 0.30)
UITheme.addGradient(root, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local accentRail = Instance.new("Frame")
accentRail.Name = "DisasterAccent"
accentRail.AnchorPoint = Vector2.new(0.5, 0)
accentRail.Position = UDim2.fromScale(0.5, 0)
accentRail.Size = UDim2.new(0.90, 0, 0, 4)
accentRail.BackgroundColor3 = UITheme.Colors.Cyan
accentRail.BorderSizePixel = 0
accentRail.Parent = root
UITheme.addCorner(accentRail, UITheme.Corners.Pill)

local accentGradient = Instance.new("UIGradient")
accentGradient.Color = ColorSequence.new(UITheme.Colors.Cyan)
accentGradient.Parent = accentRail

local scale = Instance.new("UIScale")
scale.Scale = 0.96
scale.Parent = root

local shard = Instance.new("TextLabel")
shard.Name = "ShardCount"
shard.Position = UDim2.fromScale(0.025, 0.12)
shard.Size = UDim2.fromScale(0.27, 0.43)
shard.BackgroundColor3 = UITheme.Colors.PanelSoft
shard.BackgroundTransparency = 0.16
shard.BorderSizePixel = 0
shard.Font = Enum.Font.GothamBlack
shard.Text = CoreLocalization.text(localeId, "SHARDS_COUNT", 0)
shard.TextColor3 = UITheme.Colors.Cyan
shard.TextScaled = true
shard.TextXAlignment = Enum.TextXAlignment.Left
shard.Parent = root
local shardTextConstraint = UITheme.addTextConstraint(shard, 12, 19)
UITheme.addCorner(shard, UITheme.Corners.Pill)

local challenge = Instance.new("TextLabel")
challenge.Name = "RoundChallenge"
challenge.Position = UDim2.fromScale(0.31, 0.12)
challenge.Size = UDim2.fromScale(0.32, 0.43)
challenge.BackgroundColor3 = UITheme.Colors.PanelSoft
challenge.BackgroundTransparency = 0.18
challenge.BorderSizePixel = 0
challenge.Font = Enum.Font.GothamBold
challenge.Text = CoreLocalization.text(localeId, "ROUND_CHALLENGE")
challenge.TextColor3 = UITheme.Colors.Muted
challenge.TextScaled = true
challenge.TextWrapped = true
challenge.Parent = root
local challengeTextConstraint = UITheme.addTextConstraint(challenge, 12, 18)
UITheme.addCorner(challenge, UITheme.Corners.Pill)

local status = Instance.new("TextLabel")
status.Name = "Status"
status.AnchorPoint = Vector2.new(1, 0)
status.Position = UDim2.fromScale(0.975, 0.12)
status.Size = UDim2.fromScale(0.36, 0.43)
status.BackgroundColor3 = UITheme.Colors.PanelSoft
status.BackgroundTransparency = 0.18
status.BorderSizePixel = 0
status.Font = Enum.Font.GothamBold
status.Text = "STABLE"
status.TextColor3 = UITheme.Colors.Muted
status.TextScaled = true
status.TextXAlignment = Enum.TextXAlignment.Right
status.Parent = root
local statusTextConstraint = UITheme.addTextConstraint(status, 12, 18)
UITheme.addCorner(status, UITheme.Corners.Pill)

local barBg = Instance.new("Frame")
barBg.Name = "IntensityBackground"
barBg.Position = UDim2.fromScale(0.025, 0.68)
barBg.Size = UDim2.fromScale(0.95, 0.14)
barBg.BackgroundColor3 = UITheme.Colors.PanelSoft
barBg.BackgroundTransparency = 0.08
barBg.BorderSizePixel = 0
barBg.Parent = root

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(1, 0)
bgCorner.Parent = barBg

local fill = Instance.new("Frame")
fill.Name = "IntensityFill"
fill.Size = UDim2.fromScale(0.08, 1)
fill.BackgroundColor3 = UITheme.Colors.Blue
fill.BorderSizePixel = 0
fill.Parent = barBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 190, 255)),
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(175, 120, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 85, 70)),
})
gradient.Parent = fill


local function applyResponsiveLayout()
    if not touchDevice then
        root.AnchorPoint = Vector2.new(0.5, 1)
        root.Position = UDim2.new(0.5, 0, 1, -18)
        root.Size = UDim2.new(0.82, 0, 0, 54)
        sizeConstraint.MinSize = Vector2.new(250, 48)
        return
    end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local profile = UIResponsive.mobileProfile(viewport)
    local criticalMin = UIResponsive.criticalTextMin(viewport)
    shardTextConstraint.MinTextSize = math.max(12, criticalMin - 1)
    challengeTextConstraint.MinTextSize = criticalMin
    statusTextConstraint.MinTextSize = criticalMin

    root.AnchorPoint = Vector2.new(0.5, 1)
    root.Position = UDim2.new(0.5, 0, 1, -profile.roundFocusBottomOffset)
    root.Size = UDim2.new(
        profile.roundFocusWidthScale,
        0,
        0,
        profile.roundFocusHeight
    )
    sizeConstraint.MinSize = Vector2.new(
        profile.veryNarrow and 220 or 250,
        profile.roundFocusHeight
    )

    if profile.tinyHeight then
        shard.Size = UDim2.fromScale(0.24, 0.43)
        challenge.Position = UDim2.fromScale(0.275, 0.12)
        challenge.Size = UDim2.fromScale(0.35, 0.43)
        status.Size = UDim2.fromScale(0.32, 0.43)
        barBg.Position = UDim2.fromScale(0.025, 0.70)
        barBg.Size = UDim2.fromScale(0.95, 0.12)
    else
        shard.Size = UDim2.fromScale(0.27, 0.43)
        challenge.Position = UDim2.fromScale(0.31, 0.12)
        challenge.Size = UDim2.fromScale(0.32, 0.43)
        status.Size = UDim2.fromScale(0.36, 0.43)
        barBg.Position = UDim2.fromScale(0.025, 0.68)
        barBg.Size = UDim2.fromScale(0.95, 0.14)
    end
end
applyResponsiveLayout()

local responsiveCamera = nil
local viewportConnection = nil

local function bindResponsiveCamera(camera)
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end

    responsiveCamera = camera
    if responsiveCamera then
        applyResponsiveLayout()
        viewportConnection = responsiveCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsiveLayout)
    end
end

bindResponsiveCamera(workspace.CurrentCamera)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    bindResponsiveCamera(workspace.CurrentCamera)
end)

local currentState = nil
local visibleToken = 0
local completedChallengeId = nil
local rookieCompactMode = false

local function shardCount()
    return math.max(0, math.floor(tonumber(player:GetAttribute("RoundChaosShards")) or 0))
end

local function setRookieCompactMode(enabled)
    if rookieCompactMode == enabled then
        return
    end
    rookieCompactMode = enabled

    if enabled then
        shard.Visible = false
        challenge.Position = UDim2.fromScale(0.025, 0.12)
        challenge.Size = UDim2.fromScale(0.46, 0.43)
        status.Size = UDim2.fromScale(0.46, 0.43)
    else
        shard.Visible = true
        applyResponsiveLayout()
    end
end

local function challengeProgress(state)
    local metric = state and state.challengeMetric
    if metric == "shards" then
        return math.max(0, math.floor(tonumber(player:GetAttribute("RoundChaosShards")) or 0))
    elseif metric == "pads" then
        return math.max(0, math.floor(tonumber(player:GetAttribute("RoundMechanicUses")) or 0))
    elseif metric == "nearMisses" then
        return math.max(0, math.floor(tonumber(player:GetAttribute("RoundNearMisses")) or 0))
    elseif metric == "momentum" then
        return math.max(0, math.floor(tonumber(player:GetAttribute("RoundMomentumBest")) or 0))
    elseif metric == "flow" then
        return (tonumber(player:GetAttribute("RoundFlowCoins")) or 0) > 0 and 1 or 0
    elseif metric == "variety" then
        local variety = 0
        if (tonumber(player:GetAttribute("RoundChaosShards")) or 0) > 0 then variety += 1 end
        if (tonumber(player:GetAttribute("RoundMechanicUses")) or 0) > 0 then variety += 1 end
        if (tonumber(player:GetAttribute("RoundNearMisses")) or 0) > 0 then variety += 1 end
        if (tonumber(player:GetAttribute("RoundMomentumBest")) or 0) >= 2 then variety += 1 end
        return variety
    end
    return 0
end

local function dangerStatusLabel(disasterId, value, seconds)
    if seconds <= 5 then
        return CoreLocalization.text(localeId, "SURVIVE")
            .. "  "
            .. tostring(math.max(0, math.floor(seconds)))
            .. "s",
            Color3.fromRGB(255, 105, 92)
    end

    local base = CoreLocalization.hazardName(localeId, disasterId)
        or CoreLocalization.text(localeId, "STAY_ALERT")

    if value >= 1.18 then
        return base .. "  •  " .. CoreLocalization.text(localeId, "INTENSE"),
            Color3.fromRGB(245, 115, 190)
    elseif value >= 1.08 then
        return base .. "  •  " .. CoreLocalization.text(localeId, "FASTER"),
            Color3.fromRGB(235, 175, 105)
    end
    return base, Color3.fromRGB(205, 220, 240)
end

local function refresh()
    local state = currentState
    local isParticipant = player:GetAttribute("RoundParticipant") == true
    local isEliminated = player:GetAttribute("RoundEliminated") == true

    if not state or state.phase ~= "round" or not isParticipant or isEliminated then
        setRookieCompactMode(false)
        if root.Visible then
            visibleToken += 1
            local token = visibleToken
            TweenService:Create(root, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
            TweenService:Create(scale, TweenInfo.new(0.18), {Scale = 0.9}):Play()
            task.delay(0.2, function()
                if token == visibleToken then
                    root.Visible = false
                    root.BackgroundTransparency = 0.12
                end
            end)
        end
        return
    end

    if not root.Visible then
        visibleToken += 1
        root.Visible = true
        root.BackgroundTransparency = 1
        scale.Scale = 0.9
        TweenService:Create(root, TweenInfo.new(0.2), {BackgroundTransparency = 0.12}):Play()
        TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    end

    local count = shardCount()
    shard.Text = count == 1
        and CoreLocalization.text(localeId, "SHARD_ONE")
        or CoreLocalization.text(localeId, "SHARDS_COUNT", count)

    local rookieRound = math.max(0, math.floor(tonumber(player:GetAttribute("Games")) or 0)) <= 1
    setRookieCompactMode(rookieRound and count <= 0)
    local challengeId = state.challengeId
    local challengeTarget = math.max(1, math.floor(tonumber(state.challengeTarget) or 1))
    local progress = math.min(challengeTarget, challengeProgress(state))
    if state.finalRush then
        challenge.Text = CoreLocalization.text(localeId, "SURVIVE")
        challenge.TextColor3 = UITheme.Colors.Orange
        challenge.BackgroundColor3 = UITheme.Colors.Red:Lerp(UITheme.Colors.PanelSoft, 0.82)
        completedChallengeId = nil
    elseif rookieRound then
        challenge.Text = CoreLocalization.text(localeId, "STAY_ALIVE")
        challenge.TextColor3 = UITheme.Colors.Text
        challenge.BackgroundColor3 = UITheme.Colors.PanelSoft
        completedChallengeId = nil
    elseif challengeId then
        local completed = progress >= challengeTarget
        local challengeShort = CoreLocalization.challengeShort(
            localeId,
            state.challengeId,
            tostring(state.challengeShort or CoreLocalization.text(localeId, "ROUND_CHALLENGE"))
        )
        challenge.Text = completed
            and (CoreLocalization.text(localeId, "DONE") .. "  " .. challengeShort)
            or string.format("%s  %d/%d", challengeShort, progress, challengeTarget)
        challenge.TextColor3 = completed and UITheme.Colors.Green or UITheme.Colors.Text

        if completed and completedChallengeId ~= challengeId then
            completedChallengeId = challengeId
            challenge.BackgroundColor3 = UITheme.Colors.Green:Lerp(UITheme.Colors.PanelSoft, 0.68)
            scale.Scale = 1.05
            TweenService:Create(scale, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        elseif not completed then
            completedChallengeId = nil
            challenge.BackgroundColor3 = UITheme.Colors.PanelSoft
        end
    else
        challenge.Text = CoreLocalization.text(localeId, "ROUND_CHALLENGE")
        challenge.TextColor3 = UITheme.Colors.Muted
        challenge.BackgroundColor3 = UITheme.Colors.PanelSoft
        completedChallengeId = nil
    end

    local intensity = math.clamp(tonumber(state.intensity) or 1, 0.85, 1.25)
    local normalized = math.clamp((intensity - 0.85) / 0.40, 0.08, 1)
    TweenService:Create(
        fill,
        TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.fromScale(normalized, 1)}
    ):Play()

    local primaryId = state.disasterIds and state.disasterIds[1]
    local text, color = dangerStatusLabel(
        primaryId,
        intensity,
        tonumber(state.seconds) or 0
    )
    if state.finalRush then
        text = CoreLocalization.text(
            localeId,
            "FINAL_RUSH_SECONDS",
            math.max(0, math.floor(tonumber(state.seconds) or 0))
        )
        color = UITheme.Colors.Red
    elseif state.overdrive then
        text = CoreLocalization.text(
            localeId,
            "OVERDRIVE_SECONDS",
            math.max(1, math.floor(tonumber(state.overdriveSeconds) or 1))
        )
        color = UITheme.Colors.Gold
    elseif state.doubleChaos then
        text = tostring(state.fusionName or CoreLocalization.text(localeId, "CHAOS_FUSION"))
        color = UITheme.Colors.Violet
    elseif rookieRound then
        text = CoreLocalization.text(
            localeId,
            "SURVIVE_SECONDS",
            math.max(0, math.floor(tonumber(state.seconds) or 0))
        )
        color = UITheme.Colors.Text
    end
    status.Text = text
    status.TextColor3 = color

    local secondaryId = state.disasterIds and state.disasterIds[2]
    local disasterAccent = UITheme.disasterAccent(primaryId, UITheme.Colors.Cyan)
    local secondaryAccent = UITheme.disasterAccent(secondaryId, UITheme.Colors.Violet)
    accentRail.BackgroundColor3 = disasterAccent
    fill.BackgroundColor3 = disasterAccent
    accentGradient.Color = state.doubleChaos and secondaryId
        and ColorSequence.new(disasterAccent, secondaryAccent)
        or ColorSequence.new(disasterAccent)
    gradient.Color = state.doubleChaos and secondaryId
        and ColorSequence.new({
            ColorSequenceKeypoint.new(0, disasterAccent),
            ColorSequenceKeypoint.new(0.58, secondaryAccent),
            ColorSequenceKeypoint.new(1, UITheme.Colors.Red),
        })
        or ColorSequence.new({
            ColorSequenceKeypoint.new(0, disasterAccent),
            ColorSequenceKeypoint.new(0.55, disasterAccent:Lerp(UITheme.Colors.Violet, 0.45)),
            ColorSequenceKeypoint.new(1, UITheme.Colors.Red),
        })

    if state.finalRush then
        stroke.Color = UITheme.Colors.Red
        accentRail.BackgroundColor3 = UITheme.Colors.Orange
        accentGradient.Color = ColorSequence.new(UITheme.Colors.Orange)
        shard.TextColor3 = UITheme.Colors.Orange
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, UITheme.Colors.Orange),
            ColorSequenceKeypoint.new(0.5, UITheme.Colors.Red),
            ColorSequenceKeypoint.new(1, UITheme.Colors.Magenta),
        })
    elseif state.overdrive then
        stroke.Color = UITheme.Colors.Gold
        accentRail.BackgroundColor3 = UITheme.Colors.Gold
        accentGradient.Color = ColorSequence.new(UITheme.Colors.Gold)
        shard.TextColor3 = UITheme.Colors.Gold
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, UITheme.Colors.Gold),
            ColorSequenceKeypoint.new(0.55, UITheme.Colors.Cyan),
            ColorSequenceKeypoint.new(1, UITheme.Colors.Violet),
        })
    elseif state.doubleChaos then
        stroke.Color = UITheme.Colors.Violet
        shard.TextColor3 = Color3.fromRGB(215, 165, 255)
    else
        stroke.Color = disasterAccent
        shard.TextColor3 = disasterAccent
    end
end

player:GetAttributeChangedSignal("RoundParticipant"):Connect(refresh)
player:GetAttributeChangedSignal("RoundEliminated"):Connect(refresh)

player:GetAttributeChangedSignal("RoundNearMisses"):Connect(refresh)
player:GetAttributeChangedSignal("RoundMechanicUses"):Connect(refresh)
player:GetAttributeChangedSignal("RoundMomentumBest"):Connect(refresh)
player:GetAttributeChangedSignal("RoundFlowCoins"):Connect(refresh)

player:GetAttributeChangedSignal("RoundChaosShards"):Connect(function()
    local previous = shard.Text
    refresh()

    if root.Visible and shard.Text ~= previous then
        shard.TextTransparency = 0.1
        TweenService:Create(
            shard,
            TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {TextTransparency = 0}
        ):Play()

        scale.Scale = 1.04
        TweenService:Create(
            scale,
            TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1}
        ):Play()
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    currentState = state
    refresh()
end)
