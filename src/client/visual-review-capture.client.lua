-- Native screenshots of the currently running Roblox scene.
-- This is NOT a visual mockup: CaptureService reads the player's 3D frame.
-- Nothing uploads automatically; the player first approves saving to Roblox Captures.
-- Export to the Android photo gallery is a separate user action via Roblox > Captures.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CaptureService = game:GetService("CaptureService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local ViewportRules = require(ReplicatedStorage.Shared.VisualViewportRules)
local VisualBudgetRules = require(ReplicatedStorage.Shared.VisualBudgetRules)
local Shared = ReplicatedStorage:WaitForChild("Shared")

local player = Players.LocalPlayer
local french = string.sub(string.lower(LocalizationService.RobloxLocaleId), 1, 2) == "fr"
local touch = UserInputService.TouchEnabled
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local roundEvent = remotes:WaitForChild("RoundState")
local impactEvent = remotes:WaitForChild("HazardImpactFeedback")

local phase = "waiting"
local activeDisasterIds = {}
local armed = false
local busy = false
local captureSerial = 0
local viewportConnection = nil
-- The module is generated only by the isolated staging publish workflow.
-- An ordinary production build has no marker and never displays QA controls.
local stagingEnabled = false

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosNativeVisualReview"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 37
gui.Parent = player:WaitForChild("PlayerGui")

-- Independent stamp stays in HUD-enabled shots while the photo buttons
-- hide. HUD-free 3D captures intentionally contain no UI at all.
local stampGui = Instance.new("ScreenGui")
stampGui.Name = "ChaosVisualStagingStamp"
stampGui.ResetOnSpawn = false
stampGui.IgnoreGuiInset = true
stampGui.DisplayOrder = 36
stampGui.Enabled = false
stampGui.Parent = player:WaitForChild("PlayerGui")
local stampLabel = Instance.new("TextLabel")
stampLabel.Name = "StagingCommit"
stampLabel.AnchorPoint = Vector2.new(0, 1)
-- Keep commit provenance above the bottom-centred runtime panel. On
-- portrait Android both occupied the same bottom strip and overlapped.
stampLabel.Position = UDim2.new(0, 10, 1, -98)
stampLabel.Size = UDim2.fromOffset(190, 24)
stampLabel.BackgroundColor3 = UITheme.Colors.Panel
stampLabel.BackgroundTransparency = 0.35
stampLabel.BorderSizePixel = 0
stampLabel.Font = Enum.Font.GothamBold
stampLabel.TextSize = 11
stampLabel.TextColor3 = UITheme.Colors.Text
stampLabel.Text = ""
stampLabel.Parent = stampGui
UITheme.addCorner(stampLabel, UITheme.Corners.Pill)

-- Live on-device measurements appear only in the isolated test experience.
-- Camera captures with HUD keep these numbers alongside the source SHA.
local telemetry = Instance.new("TextLabel")
telemetry.Name = "StagingRuntimeBudget"
telemetry.AnchorPoint = Vector2.new(0.5, 1)
telemetry.Position = UDim2.new(0.5, 0, 1, -10)
telemetry.Size = UDim2.fromOffset(300, 78)
telemetry.BackgroundColor3 = UITheme.Colors.Panel
telemetry.BackgroundTransparency = 0.22
telemetry.BorderSizePixel = 0
telemetry.Font = Enum.Font.GothamBold
telemetry.TextSize = 10
telemetry.TextWrapped = true
telemetry.TextColor3 = UITheme.Colors.Text
telemetry.Text = "STAGING / profiling graphics..."
telemetry.Parent = stampGui
UITheme.addCorner(telemetry, UITheme.Corners.Medium)

-- Health/provenance labels must refresh immediately: READY is only a
-- few seconds long, and a four-second graphics sample could miss it.
-- Expensive visual folder traversal remains on its existing 4-second timer.
local performanceSummary = "FPS -- | WORST --ms | -- | --\nPARTS --   LIGHTS --   FX --\nCHAOS --   WARN --   METEORS --"
local performanceWarning = false
local telemetryRunning = false

local function renderRuntimeTelemetry()
    if not stagingEnabled or not stampGui.Parent then return end
    local save = "LOADING"
    if player:GetAttribute("DataSaveConflict") == true then
        save = "CONFLICT"
    elseif player:GetAttribute("DataPersistenceAvailable") == true then
        save = player:GetAttribute("LastSaveFailed") == true
            and "RETRY" or "READY"
    elseif player:GetAttribute("DataLoaded") == true then
        save = "TEMP"
    end

    local entry = "LOBBY"
    -- RoundParticipant is not set until a round actually starts, but
    -- eliminated players can respawn in the lobby before it finishes.
    -- Never report CLEAR for spectators or eliminated avatars.
    if phase == "round" and player:GetAttribute("RoundEliminated") == true then
        entry = "OUT"
    elseif phase == "round"
        and player:GetAttribute("RoundParticipant") ~= true then
        entry = "SPECTATE"
    elseif phase == "ready" or phase == "round" then
        local clear = player:GetAttribute("ArenaSpawnClear")
        entry = clear == true and "CLEAR"
            or (clear == false and "BLOCKED" or "CHECKING")
    elseif player:GetAttribute("LobbySpawnRecovered") == true then
        entry = "RESCUED"
    end

    telemetry.Text = performanceSummary
        .. string.format("\nENTRY %s   SAVE %s", entry, save)
    telemetry.TextColor3 = (performanceWarning or entry == "BLOCKED"
        or save == "CONFLICT" or save == "TEMP" or save == "RETRY")
        and UITheme.Colors.Orange or UITheme.Colors.Text
end

local function startPerformanceTelemetry()
    if telemetryRunning then return end
    telemetryRunning = true
    renderRuntimeTelemetry()
    -- Reuse the authoritative FPS sampler. Only aggregate visual objects
    -- every four seconds; phase and persistence status are event-driven.
    task.spawn(function()
        while stagingEnabled and gui.Parent do
            task.wait(4)
            if not stagingEnabled or not gui.Parent then break end
            local fps = tonumber(player:GetAttribute("ClientObservedFps"))
            local worst = tonumber(player:GetAttribute("ClientObservedWorstFrameMs"))
            local tier = tostring(player:GetAttribute("VfxQualityTier") or "High")
            local budget = VisualBudgetRules.forTier(tier)
            local counts = VisualBudgetRules.collect(workspace)
            local status = VisualBudgetRules.status(tier, counts)
            -- Count only genuine replicated hazard pieces and RoundState
            -- disaster IDs. The 4-second cadence is deliberately shared
            -- with visual budget collection so double-catastrophe sessions
            -- do not add a second frame-rate or Workspace scan loop.
            local hazard = VisualBudgetRules.hazardSnapshot(
                workspace, phase == "round" and activeDisasterIds or nil
            )

            performanceSummary = string.format(
                "FPS %s | WORST %sms | %s | %s\nPARTS %d/%d   LIGHTS %d/%d   FX %d/%d\nCHAOS %d   WARN %d   METEORS %d",
                fps and tostring(fps) or "--",
                worst and tostring(worst) or "--",
                tier, status,
                counts.Parts, budget.Parts,
                counts.Lights, budget.Lights,
                counts.Effects, budget.Effects,
                hazard.ActiveDisasters, hazard.Warnings, hazard.LiveMeteors
            )
            performanceWarning = ((fps and fps < 30) or status ~= "OK") == true
            renderRuntimeTelemetry()
        end
        telemetryRunning = false
    end)
end

local launcher = Instance.new("TextButton")
launcher.Name = "VisualReviewPhoto"
launcher.Size = UDim2.fromOffset(78, 44)
launcher.Position = UDim2.fromOffset(12, 98)
launcher.BackgroundColor3 = UITheme.Colors.PanelRaised
launcher.BackgroundTransparency = 0.12
launcher.BorderSizePixel = 0
launcher.Font = Enum.Font.GothamBold
launcher.TextColor3 = UITheme.Colors.Cyan
launcher.TextScaled = true
launcher.Text = "PHOTO"
launcher.AutoButtonColor = false
launcher.Visible = false
launcher.Parent = gui
UITheme.addCorner(launcher, UITheme.Corners.Pill)
UITheme.addStroke(launcher, UITheme.Colors.Cyan, 1, 0.42)
UITheme.addPressFeedback(launcher, 0.96)
UITheme.addTextConstraint(launcher, 10, 14)

-- Save/failure feedback must remain visible after the capture menu closes.
local toast = Instance.new("TextLabel")
toast.Name = "VisualReviewNotice"
toast.Size = UDim2.fromOffset(194, 34)
toast.Position = UDim2.fromOffset(12, 150)
toast.BackgroundColor3 = UITheme.Colors.Panel
toast.BackgroundTransparency = 0.08
toast.BorderSizePixel = 0
toast.Font = Enum.Font.GothamBold
toast.TextScaled = true
toast.TextColor3 = UITheme.Colors.Text
toast.Visible = false
toast.Parent = gui
UITheme.addCorner(toast, UITheme.Corners.Medium)
UITheme.addTextConstraint(toast, 10, 14)

local panel = Instance.new("Frame")
panel.Name = "VisualReviewMenu"
panel.Size = UDim2.fromOffset(194, 258)
panel.Position = UDim2.fromOffset(12, 150)
panel.BackgroundColor3 = UITheme.Colors.Panel
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
UITheme.addCorner(panel, UITheme.Corners.Medium)
UITheme.addStroke(panel, UITheme.Colors.Cyan, 1, 0.34)

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingLeft = UDim.new(0, 8)
panelPadding.PaddingRight = UDim.new(0, 8)
panelPadding.PaddingTop = UDim.new(0, 8)
panelPadding.PaddingBottom = UDim.new(0, 8)
panelPadding.Parent = panel

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 6)
layout.Parent = panel

local function action(name, label)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, 0, 0, 44)
    button.BackgroundColor3 = UITheme.Colors.PanelRaised
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.Text = label
    button.TextColor3 = UITheme.Colors.Text
    button.TextScaled = true
    button.AutoButtonColor = false
    button.Parent = panel
    UITheme.addCorner(button, UITheme.Corners.Medium)
    UITheme.addPressFeedback(button, 0.96)
    UITheme.addTextConstraint(button, 11, 16)
    return button
end

local cleanButton = action("CaptureWorld", french and "PHOTO 3D" or "3D PHOTO")
local hudButton = action("CaptureHud", french and "PHOTO + HUD" or "PHOTO + HUD")
local videoButton = action("RecordShortVideo",
    french and "VIDEO 8 SEC" or "8 SEC VIDEO")
local nextButton = action("CaptureNextImpact",
    french and "PROCHAIN IMPACT" or "NEXT IMPACT")

local status = Instance.new("TextLabel")
status.Name = "PhotoStatus"
status.Size = UDim2.new(1, 0, 0, 32)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextColor3 = UITheme.Colors.TextMuted or UITheme.Colors.Text
status.TextWrapped = true
status.TextScaled = true
status.Text = french and "Après capture : Roblox > Captures > Enregistrer" or "Then: Roblox > Captures > Save"
status.Parent = panel
UITheme.addTextConstraint(status, 9, 12)

local function layoutForCamera()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local mobile = UIResponsive.mobileProfile(viewport)
    local left = mobile.veryNarrow and 8 or 12
    local top = touch and mobile.topHeight + 12 or 96
    launcher.Position = UDim2.fromOffset(left, top)
    panel.Position = UDim2.fromOffset(left, top + 51)
    toast.Position = UDim2.fromOffset(left, top + 51)
    -- Keep the capture menu and HUD diagnostics within narrow viewports.
    local width = mobile.veryNarrow and 182 or 194
    panel.Size = UDim2.fromOffset(width, 258)
    toast.Size = UDim2.fromOffset(width, 34)
    telemetry.Size = UDim2.fromOffset(
        math.min(300, math.max(120, viewport.X - 20)),
        78
    )
end

local function bindCamera()
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end
    local camera = workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize")
            :Connect(layoutForCamera)
    end
    layoutForCamera()
end

local function refresh()
    launcher.Visible = stagingEnabled
        and player:GetAttribute("DataLoaded") == true
    if not stagingEnabled then
        panel.Visible = false
        toast.Visible = false
    end
    launcher.Active = not busy
    launcher.Text = busy and (french and "PHOTO..." or "CAPTURE...")
        or (armed and (french and "VFX..." or "NEXT VFX") or "PHOTO")
    nextButton.Text = armed and (french and "ANNULER IMPACT" or "CANCEL NEXT")
        or (french and "PROCHAIN IMPACT" or "NEXT IMPACT")
end

local function finishCapture(token, message)
    if token ~= captureSerial then return end
    busy = false
    gui.Enabled = true
    panel.Visible = false
    status.Text = message
    toast.Text = message
    toast.Visible = true
    refresh()
    task.delay(5, function()
        if token == captureSerial then toast.Visible = false end
    end)
end

local function takeNativeCapture(mode)
    if busy then return end
    armed = false
    busy = true
    captureSerial += 1
    local token = captureSerial
    -- Hide only our capture controls, not the actual game's HUD.
    -- UICaptureMode.None gives a completely HUD-free 3D capture.
    panel.Visible = false
    toast.Visible = false
    gui.Enabled = false

    task.spawn(function()
        RunService.RenderStepped:Wait()
        if token ~= captureSerial then return end
        local launched = pcall(function()
            CaptureService:TakeScreenshotCaptureAsync(
                function(result, screenshotCapture)
                    if token ~= captureSerial then return end
                    gui.Enabled = true
                    if result ~= Enum.ScreenshotCaptureResult.Success
                        or not screenshotCapture then
                        finishCapture(token, french and "Capture indisponible"
                            or "Capture unavailable")
                        return
                    end
                    -- A screenshot isn't saved to Roblox Captures unless the player
                    -- accepts this prompt. Export to device storage is separate.
                    local accepted = pcall(function()
                        CaptureService:PromptSaveCapturesToGallery(
                            {screenshotCapture},
                            function(saveResults)
                                if token ~= captureSerial then return end
                                local saved = type(saveResults) == "table"
                                    and saveResults[screenshotCapture] == true
                                finishCapture(token, saved
                                    and (french and "Roblox > Captures > Enregistrer"
                                        or "Roblox > Captures > Save")
                                    or (french and "Non enregistrée dans Roblox"
                                        or "Not saved in Roblox"))
                            end
                        )
                    end)
                    if not accepted then
                        finishCapture(token, french and "Galerie indisponible"
                            or "Gallery unavailable")
                    end
                end,
                {UICaptureMode = mode}
            )
        end)
        if not launched then
            finishCapture(token, french and "Capture indisponible"
                or "Capture unavailable")
        end
    end)

    task.delay(12, function()
        if token == captureSerial and busy and not gui.Enabled then
            finishCapture(token, french and "Capture expirée"
                or "Capture timed out")
        end
    end)
end

-- The native video is recorded by Roblox, not synthesized from scripted
-- scene geometry or a collection of fake still frames. Saving remains
-- opt-in through Roblox's own gallery confirmation on supported devices.
local function takeNativeVideo()
    if busy then return end
    armed = false
    busy = true
    captureSerial += 1
    local token = captureSerial
    panel.Visible = false
    toast.Visible = false
    gui.Enabled = false

    task.spawn(function()
        RunService.RenderStepped:Wait()
        if token ~= captureSerial then return end
        local ok, started = pcall(function()
            return CaptureService:StartVideoCaptureAsync(function(result, video)
                if token ~= captureSerial then return end
                gui.Enabled = true
                if not video or (
                    result ~= Enum.VideoCaptureResult.Success
                    and result ~= Enum.VideoCaptureResult.TimeLimitReached
                ) then
                    finishCapture(token, french and "Vidéo indisponible"
                        or "Video unavailable")
                    return
                end
                local promptOk = pcall(function()
                    CaptureService:PromptSaveCapturesToGallery({video},
                        function(saveResults)
                            if token ~= captureSerial then return end
                            local saved = type(saveResults) == "table"
                                and saveResults[video] == true
                            finishCapture(token, saved
                                and (french and "Roblox > Captures > Enregistrer"
                                    or "Roblox > Captures > Save")
                                or (french and "Vidéo non enregistrée dans Roblox"
                                    or "Video not saved in Roblox"))
                        end)
                end)
                if not promptOk then
                    finishCapture(token, french and "Galerie indisponible"
                        or "Gallery unavailable")
                end
            end, {})
        end)
        if not ok or started ~= Enum.VideoCaptureStartedResult.Success then
            finishCapture(token, french and "Vidéo non compatible"
                or "Video recording unsupported")
            return
        end
        task.delay(8, function()
            if token == captureSerial and busy then
                pcall(function() CaptureService:StopVideoCapture() end)
            end
        end)
    end)

    task.delay(25, function()
        if token == captureSerial and busy and not gui.Enabled then
            pcall(function() CaptureService:StopVideoCapture() end)
            finishCapture(token, french and "Vidéo expirée"
                or "Video timed out")
        end
    end)
end

cleanButton.Activated:Connect(function()
    takeNativeCapture(Enum.UICaptureMode.None)
end)
hudButton.Activated:Connect(function()
    takeNativeCapture(Enum.UICaptureMode.All)
end)
videoButton.Activated:Connect(takeNativeVideo)
nextButton.Activated:Connect(function()
    if busy then return end
    armed = not armed
    panel.Visible = false
    status.Text = armed
        and (french and "En attente d'un impact visible"
            or "Waiting for a visible impact")
        or (french and "Capture annulée" or "Capture cancelled")
    refresh()
end)
launcher.Activated:Connect(function()
    if busy then return end
    panel.Visible = not panel.Visible
    refresh()
end)

-- Only capture a near-screen, server-signalled hazard impact. This doesn't
-- generate, replay or spoof any effects: the real game renders as normal.
-- The short delay lets the existing VFX owners spawn their strokes first.
impactEvent.OnClientEvent:Connect(function(payload)
    if not armed or busy or phase ~= "round" or type(payload) ~= "table"
        or typeof(payload.position) ~= "Vector3" then
        return
    end
    local camera = workspace.CurrentCamera
    if not camera or (camera.CFrame.Position - payload.position).Magnitude > 130 then
        return
    end
    local p = camera:WorldToViewportPoint(payload.position)
    local view = camera.ViewportSize
    if not ViewportRules.contains(p.X, p.Y, p.Z, view.X, view.Y, false) then
        return
    end
    armed = false
    refresh()
    task.delay(0.13, function()
        if phase == "round" and player:GetAttribute("DataLoaded") == true then
            takeNativeCapture(Enum.UICaptureMode.None)
        end
    end)
end)

roundEvent.OnClientEvent:Connect(function(state)
    phase = tostring(type(state) == "table" and state.phase or "waiting")
    activeDisasterIds = {}
    if phase == "round" and type(state.disasterIds) == "table" then
        -- Record the server-declared hazards, never infer Double Chaos
        -- from the temporary presence of decorative effects.
        for _, id in ipairs(state.disasterIds) do
            if type(id) == "string" then
                activeDisasterIds[#activeDisasterIds + 1] = id
            end
        end
    end
    if phase ~= "round" and armed then
        armed = false
        refresh()
    end
    renderRuntimeTelemetry()
end)
player:GetAttributeChangedSignal("DataLoaded"):Connect(refresh)
-- A screen capture during short READY / rejoin now shows the current
-- server-owned state even if the 4 s visual budget timer has not elapsed.
for _, attribute in ipairs({
    "DataLoaded", "DataPersistenceAvailable", "DataSaveConflict",
    "LastSaveFailed", "ArenaSpawnClear", "LobbySpawnRecovered",
    "RoundParticipant", "RoundEliminated",
}) do
    player:GetAttributeChangedSignal(attribute):Connect(renderRuntimeTelemetry)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)

local function activateStagingMarker(child)
    if child.Name ~= "VisualStagingStamp" or not child:IsA("ModuleScript") then
        return
    end
    local ok, value = pcall(require, child)
    if not ok or type(value) ~= "table" or value.Environment ~= "STAGING"
        or type(value.Commit) ~= "string" or #value.Commit ~= 40
        or not string.match(value.Commit, "^[0-9a-f]+$") then
        return
    end
    stagingEnabled = true
    startPerformanceTelemetry()
    stampLabel.Text = "STAGING · " .. string.sub(value.Commit, 1, 10)
    stampGui.Enabled = true
    refresh()
end

-- ReplicatedStorage can replicate late on a slow Android connection.
-- Bind both immediately and on arrival; an unmarked live build stays clean.
Shared.ChildAdded:Connect(activateStagingMarker)
local initialStamp = Shared:FindFirstChild("VisualStagingStamp")
if initialStamp then activateStagingMarker(initialStamp) end

bindCamera()
refresh()
