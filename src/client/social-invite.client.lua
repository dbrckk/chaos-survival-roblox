local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local SocialExperienceRules = require(ReplicatedStorage.Shared.SocialExperienceRules)
local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local touchDevice = UserInputService.TouchEnabled
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("RoundState")
local feedbackEvent = remotes:WaitForChild("RoundFeedback")
local socialSignalEvent = remotes:WaitForChild("SocialSignal")

local currentState = {
    phase = "waiting",
    voteOptions = nil,
}
local previousPhase = "waiting"
local lastSurvived = nil
local canInvite = false
local inviteCheckFinished = false
local inviteCheckInFlight = false
local inviteBusy = false
local ctaExposureSent = false
local pendingFriendName = nil
local friendMessageToken = 0
local viewportConnection = nil

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosSocialInvite"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 34
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Name = "InviteFriendsButton"
button.AnchorPoint = Vector2.new(0, 0)
button.Position = UDim2.fromOffset(16, 112)
button.Size = UDim2.fromOffset(196, 46)
button.BackgroundColor3 = UITheme.Colors.PanelRaised
button.BackgroundTransparency = 0.04
button.BorderSizePixel = 0
button.Font = Enum.Font.GothamBlack
button.Text = CoreLocalization.text(localeId, "INVITE_FRIENDS")
button.TextColor3 = UITheme.Colors.Text
button.TextScaled = true
button.Visible = false
button.AutoButtonColor = false
button.Parent = gui
UITheme.addCorner(button, UITheme.Corners.Medium)
local buttonStroke = UITheme.addStroke(button, UITheme.Colors.Cyan, 1.4, 0.24)
UITheme.addGradient(button, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)
UITheme.addPressFeedback(button, 0.95)
UITheme.addTextConstraint(button, 12, 18)

local accent = Instance.new("Frame")
accent.Name = "SocialAccent"
accent.AnchorPoint = Vector2.new(0, 0.5)
accent.Position = UDim2.new(0, 7, 0.5, 0)
accent.Size = UDim2.new(0, 4, 0.58, 0)
accent.BackgroundColor3 = UITheme.Colors.Cyan
accent.BorderSizePixel = 0
accent.Parent = button
UITheme.addCorner(accent, UITheme.Corners.Pill)

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 18)
padding.PaddingRight = UDim.new(0, 8)
padding.Parent = button

local buttonScale = Instance.new("UIScale")
buttonScale.Scale = 1
buttonScale.Parent = button

local worldFolder = Instance.new("Folder")
worldFolder.Name = "LobbyCrewBeaconLocal"
worldFolder.Parent = workspace

local beaconRoot = nil
local beaconGlow = nil
local beaconBillboard = nil
local beaconTitle = nil
local beaconSubtitle = nil
local beaconParts = {}

local function applyResponsive()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

    if touchDevice then
        local profile = UIResponsive.mobileProfile(viewport)
        button.Position = UDim2.fromOffset(
            profile.veryNarrow and 8 or 12,
            profile.topHeight + (profile.tinyHeight and 8 or 12)
        )
        button.Size = UDim2.fromOffset(
            profile.veryNarrow and 164 or 188,
            profile.tinyHeight and 44 or 48
        )
    else
        button.Position = UDim2.fromOffset(18, 112)
        button.Size = UDim2.fromOffset(202, 48)
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

local function makeBeaconPart(name, size, cframe, color, material, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = material
    part.Color = color
    part.Transparency = transparency
    part.Parent = worldFolder
    table.insert(beaconParts, part)
    return part
end

local function buildBeacon()
    worldFolder:ClearAllChildren()
    table.clear(beaconParts)
    beaconRoot = nil
    beaconGlow = nil
    beaconBillboard = nil
    beaconTitle = nil
    beaconSubtitle = nil

    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    if not lobby then
        return
    end

    local center = Config.LobbyCenter + Vector3.new(27, 0.15, 4)

    beaconRoot = makeBeaconPart(
        "CrewBeaconRing",
        Vector3.new(0.10, 8.4, 8.4),
        CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)),
        UITheme.Colors.Cyan,
        Enum.Material.Neon,
        0.72
    )

    local core = makeBeaconPart(
        "CrewBeaconCore",
        Vector3.new(0.08, 3.4, 3.4),
        CFrame.new(center + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90)),
        UITheme.Colors.Violet,
        Enum.Material.Neon,
        0.54
    )

    for side = -1, 1, 2 do
        local pylon = makeBeaconPart(
            side < 0 and "CrewBeaconPylonL" or "CrewBeaconPylonR",
            Vector3.new(0.9, 5.8, 0.9),
            CFrame.new(center + Vector3.new(side * 4.6, 2.9, 0)),
            UITheme.Colors.PanelRaised,
            Enum.Material.Metal,
            0.10
        )

        makeBeaconPart(
            side < 0 and "CrewBeaconStripL" or "CrewBeaconStripR",
            Vector3.new(0.18, 4.1, 0.96),
            pylon.CFrame * CFrame.new(0, 0.15, -0.05),
            side < 0 and UITheme.Colors.Cyan or UITheme.Colors.Violet,
            Enum.Material.Neon,
            0.32
        )
    end

    beaconGlow = Instance.new("PointLight")
    beaconGlow.Name = "CrewBeaconGlow"
    beaconGlow.Color = UITheme.Colors.Cyan
    beaconGlow.Brightness = 0
    beaconGlow.Range = 16
    beaconGlow.Shadows = false
    beaconGlow.Parent = core

    local anchor = Instance.new("Part")
    anchor.Name = "CrewBeaconLabelAnchor"
    anchor.Size = Vector3.new(0.2, 0.2, 0.2)
    anchor.Position = center + Vector3.new(0, 6.4, 0)
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.Transparency = 1
    anchor.Parent = worldFolder

    beaconBillboard = Instance.new("BillboardGui")
    beaconBillboard.Name = "CrewBeaconLabel"
    beaconBillboard.Adornee = anchor
    beaconBillboard.Size = UDim2.fromOffset(230, 66)
    beaconBillboard.AlwaysOnTop = false
    beaconBillboard.LightInfluence = 0
    beaconBillboard.MaxDistance = 92
    beaconBillboard.Enabled = false
    beaconBillboard.Parent = anchor

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromScale(1, 1)
    panel.BackgroundColor3 = UITheme.Colors.Panel
    panel.BackgroundTransparency = 0.12
    panel.BorderSizePixel = 0
    panel.Parent = beaconBillboard
    UITheme.addCorner(panel, UITheme.Corners.Medium)
    UITheme.addStroke(panel, UITheme.Colors.Cyan, 1.3, 0.30)

    beaconTitle = Instance.new("TextLabel")
    beaconTitle.Position = UDim2.fromScale(0.06, 0.10)
    beaconTitle.Size = UDim2.fromScale(0.88, 0.38)
    beaconTitle.BackgroundTransparency = 1
    beaconTitle.Font = Enum.Font.GothamBlack
    beaconTitle.Text = CoreLocalization.text(localeId, "CREW_SIGNAL")
    beaconTitle.TextColor3 = UITheme.Colors.Cyan
    beaconTitle.TextScaled = true
    beaconTitle.Parent = panel
    UITheme.addTextConstraint(beaconTitle, 11, 17)

    beaconSubtitle = Instance.new("TextLabel")
    beaconSubtitle.Position = UDim2.fromScale(0.06, 0.56)
    beaconSubtitle.Size = UDim2.fromScale(0.88, 0.24)
    beaconSubtitle.BackgroundTransparency = 1
    beaconSubtitle.Font = Enum.Font.GothamBold
    beaconSubtitle.Text = CoreLocalization.text(localeId, "PLAY_TOGETHER")
    beaconSubtitle.TextColor3 = UITheme.Colors.Muted
    beaconSubtitle.TextScaled = true
    beaconSubtitle.Parent = panel
    UITheme.addTextConstraint(beaconSubtitle, 9, 14)
end

local function shouldShow()
    return canInvite and SocialExperienceRules.shouldShow(
        currentState.phase,
        currentState.voteOptions,
        player:GetAttribute("Games"),
        player:GetAttribute("DataLoaded")
    )
end

local function updateBeacon(visible)
    if not beaconRoot or not beaconRoot.Parent then
        buildBeacon()
    end

    local emphasis = SocialExperienceRules.beaconEmphasis(currentState.phase)
    for _, part in ipairs(beaconParts) do
        if part and part.Parent then
            local target
            if not visible then
                target = 1
            elseif part.Material == Enum.Material.Neon then
                target = math.clamp(0.82 - emphasis * 0.42, 0.28, 0.82)
            else
                target = 0.18
            end
            TweenService:Create(
                part,
                TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Transparency = target}
            ):Play()
        end
    end

    if beaconGlow then
        beaconGlow.Brightness = visible and (0.35 + emphasis * 0.75) or 0
    end
    if beaconBillboard then
        beaconBillboard.Enabled = visible
    end
end

local showFriendArrival = nil

local function refresh()
    local visible = shouldShow()
    button.Visible = visible
    if visible and not ctaExposureSent then
        ctaExposureSent = true
        socialSignalEvent:FireServer("invite_cta_shown")
    end
    button.Text = CoreLocalization.text(
        localeId,
        SocialExperienceRules.buttonKey(lastSurvived)
    )

    local accentColor = SocialExperienceRules.intent(lastSurvived) == "comeback"
        and UITheme.Colors.Orange
        or UITheme.Colors.Cyan
    accent.BackgroundColor3 = accentColor
    buttonStroke.Color = accentColor

    updateBeacon(visible)

    if visible and pendingFriendName and showFriendArrival then
        local displayName = pendingFriendName
        pendingFriendName = nil
        task.defer(showFriendArrival, displayName)
    end
end

local function pulseSocialMoment()
    if not shouldShow() or player:GetAttribute("ReduceMotion") == true then
        return
    end

    buttonScale.Scale = 0.92
    TweenService:Create(
        buttonScale,
        TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()

    if beaconRoot and beaconRoot.Parent then
        local original = beaconRoot.Size
        beaconRoot.Size = Vector3.new(original.X, original.Y * 0.86, original.Z * 0.86)
        TweenService:Create(
            beaconRoot,
            TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = original}
        ):Play()
    end
end

showFriendArrival = function(displayName)
    local safeName = tostring(displayName or "")
    if safeName == "" then
        return
    end

    local phase = tostring(currentState.phase or "waiting")
    local voteActive = phase == "intermission"
        and type(currentState.voteOptions) == "table"
        and #currentState.voteOptions > 0
    local calm = phase == "result"
        or phase == "waiting"
        or (phase == "intermission" and not voteActive)

    if not calm then
        pendingFriendName = safeName
        return
    end

    if not beaconSubtitle or not beaconSubtitle.Parent then
        buildBeacon()
    end
    if not beaconSubtitle then
        pendingFriendName = safeName
        return
    end

    friendMessageToken += 1
    local token = friendMessageToken
    beaconSubtitle.Text = CoreLocalization.text(
        localeId,
        "FRIEND_JOINED_CREW",
        safeName
    )
    beaconSubtitle.TextColor3 = UITheme.Colors.Green
    pulseSocialMoment()

    task.delay(4, function()
        if token ~= friendMessageToken or not beaconSubtitle or not beaconSubtitle.Parent then
            return
        end
        beaconSubtitle.Text = CoreLocalization.text(localeId, "PLAY_TOGETHER")
        beaconSubtitle.TextColor3 = UITheme.Colors.Muted
    end)
end

socialSignalEvent.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" or payload.kind ~= "friend_joined" then
        return
    end
    showFriendArrival(payload.displayName)
end)

local function checkInviteAvailability()
    if inviteCheckFinished or inviteCheckInFlight then
        return
    end
    inviteCheckInFlight = true

    task.spawn(function()
        local ok, result = pcall(function()
            return SocialService:CanSendGameInviteAsync(player)
        end)
        inviteCheckInFlight = false

        if ok then
            inviteCheckFinished = true
            canInvite = result == true
        else
            canInvite = false
            task.delay(8, checkInviteAvailability)
        end

        refresh()
    end)
end

button.Activated:Connect(function()
    if inviteBusy or not shouldShow() then
        return
    end

    inviteBusy = true
    button.Active = false
    socialSignalEvent:FireServer("invite_prompt_opened")

    local options = Instance.new("ExperienceInviteOptions")
    options.PromptMessage = CoreLocalization.text(
        localeId,
        SocialExperienceRules.promptKey(lastSurvived)
    )

    local launchOk, launchData = pcall(function()
        return HttpService:JSONEncode({
            source = "chaos_crew",
            inviter = player.UserId,
        })
    end)
    if launchOk and type(launchData) == "string" and #launchData <= 200 then
        options.LaunchData = launchData
    end

    pcall(function()
        SocialService:PromptGameInvite(player, options)
    end)

    options:Destroy()

    task.delay(0.8, function()
        inviteBusy = false
        button.Active = true
    end)
end)

feedbackEvent.OnClientEvent:Connect(function(feedback)
    if type(feedback) == "table" then
        lastSurvived = feedback.survived == true
        refresh()
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    previousPhase = tostring(currentState.phase or "waiting")
    currentState = state or currentState
    refresh()

    if tostring(currentState.phase or "") == "result" and previousPhase ~= "result" then
        task.defer(pulseSocialMoment)
    end
end)

for _, attribute in ipairs({"Games", "DataLoaded"}) do
    local attributeName = attribute
    player:GetAttributeChangedSignal(attributeName):Connect(function()
        if attributeName == "DataLoaded" and player:GetAttribute("DataLoaded") == true then
            checkInviteAvailability()
        end
        refresh()
    end)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(function()
            buildBeacon()
            refresh()
        end)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        worldFolder:ClearAllChildren()
        table.clear(beaconParts)
        beaconRoot = nil
        beaconGlow = nil
        beaconBillboard = nil
    end
end)

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()
buildBeacon()

if player:GetAttribute("DataLoaded") == true then
    checkInviteAvailability()
else
    task.delay(1.2, checkInviteAvailability)
end

refresh()
