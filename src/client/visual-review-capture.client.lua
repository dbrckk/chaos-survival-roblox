-- Native screenshots of the currently running Roblox scene.
-- This is NOT a visual mockup: CaptureService reads the player's 3D frame.
-- Nothing uploads automatically; the player explicitly approves gallery saving.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CaptureService = game:GetService("CaptureService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local ViewportRules = require(ReplicatedStorage.Shared.VisualViewportRules)

local player = Players.LocalPlayer
local french = string.sub(string.lower(LocalizationService.RobloxLocaleId), 1, 2) == "fr"
local touch = UserInputService.TouchEnabled
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local roundEvent = remotes:WaitForChild("RoundState")
local impactEvent = remotes:WaitForChild("HazardImpactFeedback")

local phase = "waiting"
local armed = false
local busy = false
local captureSerial = 0
local viewportConnection = nil

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosNativeVisualReview"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 37
gui.Parent = player:WaitForChild("PlayerGui")

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

local panel = Instance.new("Frame")
panel.Name = "VisualReviewMenu"
panel.Size = UDim2.fromOffset(194, 210)
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
status.Text = french and "Vraies images du jeu" or "Real in-game frames"
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
    -- Keep the panel narrow enough for portrait Android layouts.
    panel.Size = UDim2.fromOffset(mobile.veryNarrow and 182 or 194, 210)
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
    launcher.Visible = player:GetAttribute("DataLoaded") == true
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
    refresh()
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
                    -- A screenshot isn't persisted, transferred, or shared
                    -- without the user accepting the native gallery prompt.
                    local accepted = pcall(function()
                        CaptureService:PromptSaveCapturesToGallery(
                            {screenshotCapture},
                            function(saveResults)
                                if token ~= captureSerial then return end
                                local saved = type(saveResults) == "table"
                                    and saveResults[screenshotCapture] == true
                                finishCapture(token, saved
                                    and (french and "Image sauvegardée"
                                        or "Image saved")
                                    or (french and "Enregistrement refusé"
                                        or "Not saved"))
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

cleanButton.Activated:Connect(function()
    takeNativeCapture(Enum.UICaptureMode.None)
end)
hudButton.Activated:Connect(function()
    takeNativeCapture(Enum.UICaptureMode.All)
end)
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
    if phase ~= "round" and armed then
        armed = false
        refresh()
    end
end)
player:GetAttributeChangedSignal("DataLoaded"):Connect(refresh)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)

bindCamera()
refresh()
