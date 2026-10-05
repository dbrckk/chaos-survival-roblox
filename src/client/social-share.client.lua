local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CaptureService = game:GetService("CaptureService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local ShareMomentRules = require(ReplicatedStorage.Shared.ShareMomentRules)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local touchDevice = UserInputService.TouchEnabled
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("RoundState")
local feedbackEvent = remotes:WaitForChild("RoundFeedback")
local socialSignalEvent = remotes:WaitForChild("SocialSignal")

local currentState = {
    phase = "waiting",
}
local previousPhase = "waiting"
local lastFeedback = nil
local shareBusy = false
local exposureSentThisResult = false
local viewportConnection = nil
local operationToken = 0
local awaitingCapture = false
local sharePromptOpen = false

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosMomentShare"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 36
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Name = "ShareMomentButton"
button.AnchorPoint = Vector2.new(1, 0)
button.Position = UDim2.new(1, -18, 0, 112)
button.Size = UDim2.fromOffset(218, 62)
button.BackgroundColor3 = UITheme.Colors.PanelRaised
button.BackgroundTransparency = 0.04
button.BorderSizePixel = 0
button.Text = ""
button.AutoButtonColor = false
button.Visible = false
button.Parent = gui
UITheme.addCorner(button, UITheme.Corners.Large)
local stroke = UITheme.addStroke(button, UITheme.Colors.Gold, 1.4, 0.24)
UITheme.addGradient(button, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)
UITheme.addPressFeedback(button, 0.95)

local accent = Instance.new("Frame")
accent.Name = "ShareAccent"
accent.AnchorPoint = Vector2.new(0, 0.5)
accent.Position = UDim2.new(0, 7, 0.5, 0)
accent.Size = UDim2.new(0, 4, 0.66, 0)
accent.BackgroundColor3 = UITheme.Colors.Gold
accent.BorderSizePixel = 0
accent.Parent = button
UITheme.addCorner(accent, UITheme.Corners.Pill)

local title = Instance.new("TextLabel")
title.Name = "ShareTitle"
title.Position = UDim2.fromOffset(18, 7)
title.Size = UDim2.new(1, -28, 0, 24)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = CoreLocalization.text(localeId, "SHARE_MOMENT")
title.TextColor3 = UITheme.Colors.Text
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = button
UITheme.addTextConstraint(title, 11, 17)

local reasonLabel = Instance.new("TextLabel")
reasonLabel.Name = "ShareReason"
reasonLabel.Position = UDim2.fromOffset(18, 33)
reasonLabel.Size = UDim2.new(1, -28, 0, 17)
reasonLabel.BackgroundTransparency = 1
reasonLabel.Font = Enum.Font.GothamBold
reasonLabel.Text = ""
reasonLabel.TextColor3 = UITheme.Colors.Gold
reasonLabel.TextScaled = true
reasonLabel.TextXAlignment = Enum.TextXAlignment.Left
reasonLabel.TextTruncate = Enum.TextTruncate.AtEnd
reasonLabel.Parent = button
UITheme.addTextConstraint(reasonLabel, 8, 12)

local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = button

local function currentReason()
    return ShareMomentRules.reason(lastFeedback, currentState)
end

local function shouldShow()
    return not shareBusy
        and ShareMomentRules.shouldShow(
            lastFeedback,
            currentState,
            player:GetAttribute("Games")
        )
end

local function applyResponsive()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)

    if touchDevice then
        local profile = UIResponsive.mobileProfile(viewport)
        button.Position = UDim2.new(
            1,
            -(profile.veryNarrow and 8 or 12),
            0,
            profile.topHeight + (profile.tinyHeight and 8 or 12)
        )
        button.Size = UDim2.fromOffset(
            profile.veryNarrow and 178 or 208,
            profile.tinyHeight and 56 or 62
        )
    else
        button.Position = UDim2.new(1, -18, 0, 112)
        button.Size = UDim2.fromOffset(218, 62)
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

local function refresh()
    local reason = currentReason()
    local visible = shouldShow()

    button.Visible = visible
    if reason then
        local reasonKey = ShareMomentRules.reasonKey(reason)
        reasonLabel.Text = reasonKey
            and CoreLocalization.text(localeId, reasonKey)
            or ""
    else
        reasonLabel.Text = ""
    end

    if visible and not exposureSentThisResult then
        exposureSentThisResult = true
        socialSignalEvent:FireServer("share_cta_shown")
    end
end

local function setBusy(value)
    shareBusy = value == true
    button.Active = not shareBusy

    if shareBusy then
        button.Visible = true
        title.Text = CoreLocalization.text(localeId, "SHARE_CAPTURING")
        reasonLabel.Text = ""
    else
        title.Text = CoreLocalization.text(localeId, "SHARE_MOMENT")
        refresh()
    end
end

local function showUnavailable(token)
    if token ~= operationToken then
        return
    end

    awaitingCapture = false
    sharePromptOpen = false
    socialSignalEvent:FireServer("share_failed")
    title.Text = CoreLocalization.text(localeId, "SHARE_UNAVAILABLE")
    reasonLabel.Text = ""

    task.delay(1.6, function()
        if token ~= operationToken then
            return
        end
        setBusy(false)
    end)
end

local function buildLaunchData(reason)
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode({
            source = "chaos_share",
            sharer = player.UserId,
            reason = ShareMomentRules.launchReason(reason),
        })
    end)

    if ok and type(encoded) == "string" and #encoded <= 200 then
        return encoded
    end
    return ""
end

local function promptShare(content, launchData, token)
    if token ~= operationToken then
        return
    end

    awaitingCapture = false
    sharePromptOpen = true

    local ok = pcall(function()
        CaptureService:PromptShareCapture(
            content,
            launchData,
            function()
                if token ~= operationToken then
                    return
                end
                sharePromptOpen = false
                socialSignalEvent:FireServer("share_accepted")
                setBusy(false)
            end,
            function()
                if token ~= operationToken then
                    return
                end
                sharePromptOpen = false
                socialSignalEvent:FireServer("share_denied")
                setBusy(false)
            end
        )
    end)

    if not ok then
        sharePromptOpen = false
        showUnavailable(token)
    end
end

local function tryLegacyScreenshot(launchData, token)
    local ok = pcall(function()
        CaptureService:CaptureScreenshot(function(contentId)
            if token ~= operationToken then
                return
            end

            local contentOk, content = pcall(function()
                return Content.fromUri(tostring(contentId))
            end)
            if not contentOk or not content then
                showUnavailable(token)
                return
            end
            promptShare(content, launchData, token)
        end)
    end)

    if not ok then
        showUnavailable(token)
    end
end

local function captureAndShare()
    local reason = currentReason()
    if shareBusy or not reason or not shouldShow() then
        return
    end

    operationToken += 1
    local token = operationToken
    awaitingCapture = true
    setBusy(true)
    socialSignalEvent:FireServer("share_capture_requested")

    if player:GetAttribute("ReduceMotion") ~= true then
        scale.Scale = 0.94
        TweenService:Create(
            scale,
            TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Scale = 1}
        ):Play()
    end

    local launchData = buildLaunchData(reason)
    local ok = pcall(function()
        CaptureService:TakeScreenshotCaptureAsync(
            function(result, screenshotCapture)
                if token ~= operationToken then
                    return
                end

                if result ~= Enum.ScreenshotCaptureResult.Success or not screenshotCapture then
                    tryLegacyScreenshot(launchData, token)
                    return
                end

                local contentOk, content = pcall(function()
                    return Content.fromObject(screenshotCapture)
                end)
                if not contentOk or not content then
                    tryLegacyScreenshot(launchData, token)
                    return
                end

                promptShare(content, launchData, token)
            end,
            {
                UICaptureMode = Enum.UICaptureMode.None,
            }
        )
    end)

    if not ok then
        tryLegacyScreenshot(launchData, token)
    end

    task.delay(10, function()
        if token == operationToken and shareBusy and awaitingCapture then
            awaitingCapture = false
            showUnavailable(token)
        end
    end)
end

button.Activated:Connect(captureAndShare)

feedbackEvent.OnClientEvent:Connect(function(feedback)
    if type(feedback) == "table" then
        lastFeedback = feedback
        refresh()
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    previousPhase = tostring(currentState.phase or "waiting")
    currentState = type(state) == "table" and state or currentState

    local phase = tostring(currentState.phase or "waiting")
    if phase ~= "result" then
        exposureSentThisResult = false
        if previousPhase == "result" then
            if awaitingCapture then
                operationToken += 1
                awaitingCapture = false
                shareBusy = false
            elseif not sharePromptOpen then
                shareBusy = false
            end
            title.Text = CoreLocalization.text(localeId, "SHARE_MOMENT")
        end
    end

    if phase == "round" and previousPhase ~= "round" then
        lastFeedback = nil
    end

    refresh()
end)

player:GetAttributeChangedSignal("Games"):Connect(refresh)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)

bindCamera()
refresh()
