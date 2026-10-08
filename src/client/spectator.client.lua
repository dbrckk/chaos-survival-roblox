local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local HazardGlyphs = require(ReplicatedStorage.Shared.HazardGlyphs)
local SpectatorTargetRules = require(ReplicatedStorage.Shared.SpectatorTargetRules)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosSpectator"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 45
gui.Parent = player:WaitForChild("PlayerGui")

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5, 1)
card.Position = UDim2.fromScale(0.5, 0.88)
card.Size = UDim2.fromScale(0.58, 0.105)
card.BackgroundColor3 = UITheme.Colors.Panel
card.BackgroundTransparency = 0.05
card.BorderSizePixel = 0
card.Visible = false
card.Parent = gui

local cardConstraint = Instance.new("UISizeConstraint")
cardConstraint.MinSize = Vector2.new(280, 62)
cardConstraint.MaxSize = Vector2.new(620, 86)
cardConstraint.Parent = card

UITheme.addCorner(card, UITheme.Corners.Large)
local cardStroke = UITheme.addStroke(card, UITheme.Colors.Blue, 1.3, 0.28)
UITheme.addGradient(card, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local accentRail = Instance.new("Frame")
accentRail.Size = UDim2.new(0.90, 0, 0, 4)
accentRail.Position = UDim2.fromScale(0.05, 0.06)
accentRail.BackgroundColor3 = UITheme.Colors.Blue
accentRail.BorderSizePixel = 0
accentRail.Parent = card
UITheme.addCorner(accentRail, UITheme.Corners.Pill)

local accentGradient = Instance.new("UIGradient")
accentGradient.Color = ColorSequence.new(UITheme.Colors.Blue, UITheme.Colors.Cyan)
accentGradient.Parent = accentRail

local hazardGlyph = Instance.new("Frame")
hazardGlyph.Name = "SpectatorHazardGlyph"
hazardGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
hazardGlyph.Position = UDim2.fromScale(0.12, 0.48)
hazardGlyph.Size = UDim2.fromScale(0.15, 0.58)
hazardGlyph.BackgroundTransparency = 1
hazardGlyph.Visible = false
hazardGlyph.ZIndex = 1
hazardGlyph.Parent = card

local hazardGlyphSecondary = Instance.new("Frame")
hazardGlyphSecondary.Name = "SpectatorHazardGlyphSecondary"
hazardGlyphSecondary.AnchorPoint = Vector2.new(0.5, 0.5)
hazardGlyphSecondary.Position = UDim2.fromScale(0.24, 0.48)
hazardGlyphSecondary.Size = UDim2.fromScale(0.13, 0.50)
hazardGlyphSecondary.BackgroundTransparency = 1
hazardGlyphSecondary.Visible = false
hazardGlyphSecondary.ZIndex = 1
hazardGlyphSecondary.Parent = card

local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = card

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.68, -14, 0.64, -4)
label.Position = UDim2.fromOffset(12, 7)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextColor3 = UITheme.Colors.Text
label.TextScaled = true
label.TextWrapped = true
label.TextXAlignment = Enum.TextXAlignment.Left
label.Text = "SPECTATING"
label.ZIndex = 2
label.Parent = card

local nextButton = Instance.new("TextButton")
nextButton.Name = "NextSpectator"
nextButton.AnchorPoint = Vector2.new(1, 0.5)
nextButton.Position = UDim2.new(1, -8, 0.5, 0)
nextButton.Size = UDim2.new(0.28, 0, 0.72, 0)
nextButton.BackgroundColor3 = UITheme.Colors.Blue
nextButton.Font = Enum.Font.GothamBlack
nextButton.TextColor3 = UITheme.Colors.Text
nextButton.TextScaled = true
nextButton.Text = CoreLocalization.text(localeId, "NEXT")
nextButton.ZIndex = 2
nextButton.Parent = card
UITheme.addCorner(nextButton, UITheme.Corners.Medium)
UITheme.addStroke(nextButton, UITheme.Colors.Cyan, 1.1, 0.35)
UITheme.addGradient(nextButton, UITheme.Colors.Blue, UITheme.Colors.Violet, 25)
UITheme.addPressFeedback(nextButton, 0.94)

local healthTrack = Instance.new("Frame")
healthTrack.Name = "TargetHealthTrack"
healthTrack.Position = UDim2.fromScale(0.04, 0.79)
healthTrack.Size = UDim2.fromScale(0.62, 0.10)
healthTrack.BackgroundColor3 = UITheme.Colors.PanelSoft
healthTrack.BackgroundTransparency = 0.05
healthTrack.BorderSizePixel = 0
healthTrack.ZIndex = 2
healthTrack.Parent = card
UITheme.addCorner(healthTrack, UITheme.Corners.Pill)

local healthFill = Instance.new("Frame")
healthFill.Name = "TargetHealthFill"
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = UITheme.Colors.Green
healthFill.BorderSizePixel = 0
healthFill.ZIndex = 2
healthFill.Parent = healthTrack
UITheme.addCorner(healthFill, UITheme.Corners.Pill)

local roundActive = false
local latestState = nil
local targets = {}
local targetIndex = 0
local selectedCharacter = nil
local targetHealthConnection = nil
local observedHumanoid = nil
local shownPrimaryId = nil
local shownSecondaryId = nil
local targetDiedConnection = nil
local spectateIndex
local viewportConnection = nil
local applyResponsive

local function renderSpectatorGlyph(container, hazardId, color, transparency)
    for _, child in ipairs(container:GetChildren()) do
        if child:GetAttribute("HazardGlyphSegment") == true then
            child:Destroy()
        end
    end

    local recipe = HazardGlyphs.get(hazardId)
    container.Visible = recipe ~= nil
    if not recipe then
        return
    end

    for _, def in ipairs(recipe) do
        local segment = Instance.new("Frame")
        segment.AnchorPoint = Vector2.new(0.5, 0.5)
        segment.Position = UDim2.fromScale(def.X, def.Y)
        segment.Size = UDim2.fromScale(def.Width, def.Height)
        segment.Rotation = def.Rotation or 0
        segment.BackgroundColor3 = color
        segment.BackgroundTransparency = transparency or 0.82
        segment.BorderSizePixel = 0
        segment.ZIndex = container.ZIndex
        segment:SetAttribute("HazardGlyphSegment", true)
        segment.Parent = container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = segment
    end
end

local function refreshHazardIdentity(state)
    local ids = state and type(state.disasterIds) == "table" and state.disasterIds or {}
    local primaryId = ids[1]
    local secondaryId = ids[2]

    -- RoundState ticks every second; do not reconstruct unchanged glyph parts.
    if primaryId == shownPrimaryId and secondaryId == shownSecondaryId then
        return
    end
    shownPrimaryId = primaryId
    shownSecondaryId = secondaryId

    if not primaryId then
        hazardGlyph.Visible = false
        hazardGlyphSecondary.Visible = false
        cardStroke.Color = UITheme.Colors.Blue
        accentGradient.Color = ColorSequence.new(UITheme.Colors.Blue, UITheme.Colors.Cyan)
        return
    end

    local primary = UITheme.disasterAccent(primaryId, UITheme.Colors.Cyan)
    local secondary = secondaryId
        and UITheme.disasterAccent(secondaryId, UITheme.Colors.Violet)
        or primary:Lerp(UITheme.Colors.Blue, 0.35)

    cardStroke.Color = primary
    accentGradient.Color = ColorSequence.new(primary, secondary)
    renderSpectatorGlyph(hazardGlyph, primaryId, primary, 0.84)
    renderSpectatorGlyph(hazardGlyphSecondary, secondaryId, secondary, 0.86)

    if applyResponsive then
        applyResponsive()
    end
end

applyResponsive = function()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

    if UserInputService.TouchEnabled then
        local profile = UIResponsive.mobileProfile(viewport)
        local cardHeight = profile.tinyHeight and 64 or 72
        card.Position = UDim2.fromScale(0.5, profile.tinyHeight and 0.76 or 0.82)
        card.Size = UDim2.new(profile.veryNarrow and 0.92 or 0.78, 0, 0, cardHeight)

        nextButton.Size = UDim2.fromOffset(profile.tinyHeight and 88 or 98, 44)
        nextButton.Position = UDim2.new(1, -8, 0.5, 0)

        local glyphSize = profile.tinyHeight and 30 or 36
        hazardGlyph.Size = UDim2.fromOffset(glyphSize, glyphSize)
        hazardGlyph.Position = UDim2.new(0, 10 + glyphSize * 0.5, 0.48, 0)

        if profile.veryNarrow then
            hazardGlyphSecondary.Visible = false
        else
            -- On viewport widening, bring back the Double Chaos symbol.
            hazardGlyphSecondary.Visible = shownSecondaryId ~= nil
                and HazardGlyphs.get(shownSecondaryId) ~= nil
            local secondarySize = profile.tinyHeight and 26 or 30
            hazardGlyphSecondary.Size = UDim2.fromOffset(secondarySize, secondarySize)
            hazardGlyphSecondary.Position = UDim2.new(
                0,
                16 + glyphSize + secondarySize * 0.5,
                0.48,
                0
            )
        end

        local leftInset = 12
        if hazardGlyphSecondary.Visible then
            leftInset = 24 + glyphSize + (profile.tinyHeight and 26 or 30)
        elseif hazardGlyph.Visible then
            leftInset = 18 + glyphSize
        end

        local rightReserve = profile.tinyHeight and 112 or 122
        label.Position = UDim2.new(0, leftInset, 0, 7)
        label.Size = UDim2.new(1, -(leftInset + rightReserve), 0.64, -4)
        healthTrack.Size = UDim2.new(1, -(profile.tinyHeight and 124 or 136), 0.10, 0)
    else
        hazardGlyphSecondary.Visible = shownSecondaryId ~= nil
            and HazardGlyphs.get(shownSecondaryId) ~= nil
        card.Position = UDim2.fromScale(0.5, 0.88)
        card.Size = UDim2.fromScale(0.58, 0.105)
        nextButton.Size = UDim2.new(0.28, 0, 0.72, 0)
        nextButton.Position = UDim2.new(1, -8, 0.5, 0)

        hazardGlyph.Size = UDim2.fromScale(0.15, 0.58)
        hazardGlyph.Position = UDim2.fromScale(
            hazardGlyphSecondary.Visible and 0.10 or 0.13,
            0.48
        )
        hazardGlyphSecondary.Size = UDim2.fromScale(0.13, 0.50)
        hazardGlyphSecondary.Position = UDim2.fromScale(0.23, 0.48)

        local leftScale = hazardGlyphSecondary.Visible
            and 0.31
            or (hazardGlyph.Visible and 0.20 or 0)
        label.Position = leftScale > 0
            and UDim2.new(leftScale, 0, 0, 7)
            or UDim2.fromOffset(12, 7)
        label.Size = UDim2.new(
            0.68 - leftScale,
            leftScale > 0 and -6 or -14,
            0.64,
            -4
        )
        healthTrack.Size = UDim2.fromScale(0.62, 0.10)
    end
end

local function bindCamera()
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end

    local camera = workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsive)
    end
    applyResponsive()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()

local function clearTargetHealth()
    if targetHealthConnection then
        targetHealthConnection:Disconnect()
        targetHealthConnection = nil
    end
    if targetDiedConnection then
        targetDiedConnection:Disconnect()
        targetDiedConnection = nil
    end
    observedHumanoid = nil
    healthFill.Size = UDim2.fromScale(0, 1)
end

local function bindTargetHealth(humanoid)
    if observedHumanoid == humanoid then
        return
    end
    clearTargetHealth()
    if not humanoid then
        return
    end
    observedHumanoid = humanoid

    local function update()
        local ratio = humanoid.MaxHealth > 0
            and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            or 0
        healthFill.BackgroundColor3 = ratio > 0.55
            and UITheme.Colors.Green
            or (ratio > 0.25 and UITheme.Colors.Gold or UITheme.Colors.Red)
        TweenService:Create(
            healthFill,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.fromScale(ratio, 1)}
        ):Play()
    end

    update()
    targetHealthConnection = humanoid.HealthChanged:Connect(update)
    targetDiedConnection = humanoid.Died:Connect(function()
        task.delay(0.08, function()
            if roundActive and card.Visible and spectateIndex then
                spectateIndex(targetIndex + 1)
            end
        end)
    end)
end

local function localHumanoid()
    local character = player.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function validPlayerTarget(other)
    if other == player then return false end
    if other:GetAttribute("RoundParticipant") ~= true then return false end
    if other:GetAttribute("RoundEliminated") == true then return false end

    local character = other.Character
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function addBotTargets()
    local folder = workspace:FindFirstChild("AISurvivors")
    if not folder then
        return
    end

    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") and model:GetAttribute("AISurvivor") == true then
            local hum = model:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(targets, {
                    Character = model,
                    DisplayName = hum.DisplayName ~= "" and hum.DisplayName or model.Name,
                    IsBot = true,
                    SortKey = math.max(
                        0,
                        math.floor(tonumber(model:GetAttribute("AISurvivorSlot")) or 0)
                    ),
                })
            end
        end
    end
end

local function rebuildTargets()
    targets = {}
    for _, other in ipairs(Players:GetPlayers()) do
        if validPlayerTarget(other) then
            table.insert(targets, {
                Character = other.Character,
                DisplayName = other.DisplayName,
                IsBot = false,
                SortKey = other.UserId,
            })
        end
    end

    addBotTargets()

    table.sort(targets, function(a, b)
        if a.IsBot ~= b.IsBot then
            return a.IsBot ~= true
        end
        return (a.SortKey or 0) < (b.SortKey or 0)
    end)
end

local function restoreCamera()
    local camera = workspace.CurrentCamera
    local hum = localHumanoid()
    if camera and hum then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = hum
    end
end

local function roundSummary()
    local state = latestState
    if not state then
        return ""
    end

    local alive = tonumber(state.survivorsAlive)
    local seconds = tonumber(state.seconds)
    local pieces = {}

    if alive then
        table.insert(
            pieces,
            CoreLocalization.text(
                localeId,
                "ALIVE_SHORT",
                math.max(0, math.floor(alive))
            )
        )
    end
    if seconds then
        table.insert(pieces, tostring(math.max(0, math.floor(seconds))) .. "s")
    end

    return table.concat(pieces, "  •  ")
end

spectateIndex = function(index)
    rebuildTargets()

    if #targets == 0 then
        local summary = roundSummary()
        if player:GetAttribute("RoundParticipant") == true then
            label.Text = CoreLocalization.text(localeId, "ELIMINATED_WAITING")
        else
            label.Text = CoreLocalization.text(localeId, "JOINING_WAITING")
        end
        if summary ~= "" then
            label.Text ..= "\n" .. summary
        end
        nextButton.Visible = false
        clearTargetHealth()
        restoreCamera()
        return
    end

    targetIndex = ((index - 1) % #targets) + 1
    local target = targets[targetIndex]
    local character = target and target.Character
    local hum = character and character:FindFirstChildOfClass("Humanoid")

    if hum and workspace.CurrentCamera then
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        workspace.CurrentCamera.CameraSubject = hum
        local summary = roundSummary()
        local displayName = tostring(
            target.DisplayName or CoreLocalization.text(localeId, "SURVIVOR_LABEL")
        )
        if player:GetAttribute("RoundParticipant") == true then
            label.Text = CoreLocalization.text(localeId, "SPECTATING", displayName)
        else
            label.Text = CoreLocalization.text(localeId, "JOINING_NEXT", displayName)
        end
        if summary ~= "" then
            label.Text ..= "\n" .. summary
        end
        nextButton.Visible = #targets > 1
        bindTargetHealth(hum)
    end
end

local function refresh()
    local eliminated = player:GetAttribute("RoundEliminated") == true
    local participant = player:GetAttribute("RoundParticipant") == true
    local shouldSpectate = roundActive and (eliminated or not participant)

    if shouldSpectate then
        if not card.Visible then
            card.Visible = true
            scale.Scale = 0.88
            TweenService:Create(
                scale,
                TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Scale = 1}
            ):Play()
        end
        spectateIndex(math.max(1, targetIndex))
    else
        card.Visible = false
        targetIndex = 0
        clearTargetHealth()
        restoreCamera()
    end
end

nextButton.Activated:Connect(function()
    spectateIndex(targetIndex + 1)
end)

player:GetAttributeChangedSignal("RoundEliminated"):Connect(refresh)
player:GetAttributeChangedSignal("RoundParticipant"):Connect(refresh)
player.CharacterAdded:Connect(function()
    task.wait(0.1)
    local eliminated = player:GetAttribute("RoundEliminated") == true
    local participant = player:GetAttribute("RoundParticipant") == true

    if roundActive and (eliminated or not participant) then
        spectateIndex(math.max(1, targetIndex))
    else
        restoreCamera()
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    latestState = state
    roundActive = state.phase == "round"
    refreshHazardIdentity(state)
    refresh()
end)
