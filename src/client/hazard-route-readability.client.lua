local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local WarningRules = require(ReplicatedStorage.Shared.HazardWarningSignatureRules)
local HarborSweepGuidance = require(ReplicatedStorage.Shared.HarborSweepGuidance)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "HazardRouteReadabilityLocal"
folder.Parent = workspace

local cueGui = Instance.new("ScreenGui")
cueGui.Name = "HazardReadabilityCue"
cueGui.ResetOnSpawn = false
cueGui.IgnoreGuiInset = true
cueGui.DisplayOrder = 19
cueGui.Parent = player:WaitForChild("PlayerGui")

local cue = Instance.new("Frame")
cue.Name = "NearestHazardCue"
cue.AnchorPoint = Vector2.new(0.5, 0)
cue.Position = UDim2.fromScale(0.5, 0.20)
cue.Size = UDim2.fromOffset(230, 42)
cue.BackgroundColor3 = UITheme.Colors.Panel
cue.BackgroundTransparency = 0.05
cue.BorderSizePixel = 0
cue.Visible = false
cue.Parent = cueGui
UITheme.addCorner(cue, UITheme.Corners.Pill)
local cueStroke = UITheme.addStroke(cue, UITheme.Colors.Red, 2, 0.12)

local cueBadge = Instance.new("TextLabel")
cueBadge.Size = UDim2.fromOffset(38, 34)
cueBadge.Position = UDim2.fromOffset(4, 4)
cueBadge.BackgroundColor3 = UITheme.Colors.Red
cueBadge.BackgroundTransparency = 0.02
cueBadge.BorderSizePixel = 0
cueBadge.Font = Enum.Font.GothamBlack
cueBadge.TextColor3 = UITheme.Colors.Text
cueBadge.TextScaled = true
cueBadge.Text = "!"
cueBadge.Parent = cue
UITheme.addCorner(cueBadge, UITheme.Corners.Pill)
UITheme.addTextConstraint(cueBadge, 15, 23)

local cueText = Instance.new("TextLabel")
cueText.Position = UDim2.fromOffset(48, 4)
cueText.Size = UDim2.new(1, -54, 1, -8)
cueText.BackgroundTransparency = 1
cueText.Font = Enum.Font.GothamBlack
cueText.TextColor3 = UITheme.Colors.Text
cueText.TextScaled = true
cueText.TextXAlignment = Enum.TextXAlignment.Left
cueText.Text = CoreLocalization.text(localeId, "DANGER")
cueText.Parent = cue
UITheme.addTextConstraint(cueText, 14, 21)

local offscreenArrow = Instance.new("TextLabel")
offscreenArrow.Name = "OffscreenHazardArrow"
offscreenArrow.AnchorPoint = Vector2.new(0.5, 0.5)
offscreenArrow.Size = UDim2.fromOffset(42, 42)
offscreenArrow.BackgroundColor3 = UITheme.Colors.Panel
offscreenArrow.BackgroundTransparency = 0.14
offscreenArrow.BorderSizePixel = 0
offscreenArrow.Font = Enum.Font.GothamBlack
offscreenArrow.Text = "▲"
offscreenArrow.TextColor3 = UITheme.Colors.Red
offscreenArrow.TextScaled = true
offscreenArrow.Visible = false
offscreenArrow.ZIndex = 4
offscreenArrow.Parent = cueGui
UITheme.addCorner(offscreenArrow, UITheme.Corners.Pill)
local offscreenStroke = UITheme.addStroke(offscreenArrow, UITheme.Colors.Red, 1.4, 0.24)
UITheme.addTextConstraint(offscreenArrow, 18, 28)

local cameraConnection = nil

local function applyCueLayout()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local profile = UIResponsive.mobileProfile(viewport)
    local compact = profile.compactHeight
    local cueHeight = profile.tinyHeight and 34 or (compact and 38 or 42)
    local cueWidth = profile.veryNarrow and 210 or 230
    local topGap = profile.tinyHeight and 8 or 10

    cue.Position = UDim2.new(0.5, 0, 0, profile.topHeight + topGap)
    cue.Size = UDim2.fromOffset(cueWidth, cueHeight)

    local badgeSize = math.max(30, cueHeight - 8)
    cueBadge.Size = UDim2.fromOffset(badgeSize, badgeSize)
    cueBadge.Position = UDim2.fromOffset(4, math.floor((cueHeight - badgeSize) * 0.5))
    cueText.Position = UDim2.fromOffset(badgeSize + 12, 3)
    cueText.Size = UDim2.new(1, -(badgeSize + 18), 1, -6)
end

local function bindCamera()
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end

    local camera = workspace.CurrentCamera
    if camera then
        cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyCueLayout)
    end
    applyCueLayout()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()

local currentPhase = "waiting"
local finalRush = false
local warningStates = {}
local pendingWarnings = {}
local loopStarted = false
local ensureRenderLoop

local SUPPORTED = {
    Meteor = true,
    Bomb = true,
    JumpShock = true,
}

local WARNING_NAMES = {
    MeteorWarning = true,
    BombWarning = true,
    JumpShockWarning = true,
}

local KIND_COLORS = {
    Meteor = Color3.fromRGB(255, 175, 70),
    Bomb = Color3.fromRGB(255, 75, 75),
    JumpShock = Color3.fromRGB(100, 185, 255),
}

local KIND_DISASTER_IDS = {
    Meteor = "Meteors",
    Bomb = "Bombs",
}

local function localizedHazardCue(kind)
    local disasterId = KIND_DISASTER_IDS[kind]
    local name = CoreLocalization.hazardName(localeId, disasterId)
        or CoreLocalization.text(localeId, "DANGER")
    local action = CoreLocalization.hazardAction(localeId, disasterId)
        or CoreLocalization.text(localeId, "STAY_ALERT")
    return name .. "  •  " .. action
end

local KIND_BADGES = {
    Meteor = "M",
    Bomb = "B",
    JumpShock = "↑",
}

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function rootPart()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end
    return nil
end

local function releasePending(warning)
    local list = pendingWarnings[warning]
    if not list then return end
    pendingWarnings[warning] = nil
    for _, connection in ipairs(list) do
        connection:Disconnect()
    end
end

local function destroyState(warning)
    releasePending(warning)
    local state = warningStates[warning]
    if not state then
        return
    end
    warningStates[warning] = nil
    for _, instance in ipairs(state.instances) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
end

local function makeArrowPart(name, color)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = 1
    part.Size = Vector3.new(1.5, 0.06, 0.18)
    part.Parent = folder
    return part
end

-- The SAME primary danger HUD handles Storm Harbor's server-owned
-- cargo lanes. Reuse its existing adaptive loop; no new scheduler.
local harborArrows = nil

local function hideHarborArrows()
    if not harborArrows then return end
    for _, part in ipairs(harborArrows) do
        if part and part.Parent then part.Transparency = 1 end
    end
end

local function drawHarborExit(guide, characterRoot, tier, now)
    if not harborArrows or not harborArrows[1].Parent
        or not harborArrows[2].Parent then
        harborArrows = {
            makeArrowPart("LocalHarborExitLeft", UITheme.Colors.Orange),
            makeArrowPart("LocalHarborExitRight", UITheme.Colors.Orange),
        }
    end
    local direction = guide.direction
    local lateral = Vector3.new(direction.Z, 0, -direction.X)
    local origin = characterRoot.Position + Vector3.new(0, -2.65, 0)
        + direction * 3.0
    local yaw = math.atan2(-direction.X, -direction.Z)
    local color = guide.phase == "Pulse" and UITheme.Colors.Red
        or Color3.fromRGB(255, 186, 76)
    local reduced = player:GetAttribute("ReduceMotion") == true
    local pulse = reduced and 0.5 or (math.sin(now * 7.5) + 1) * 0.5
    local transparency = (tier.Name == "Low" and 0.35 or 0.22)
        + pulse * 0.16
    for index, part in ipairs(harborArrows) do
        local side = index == 1 and -1 or 1
        part.Color = color
        part.CFrame = CFrame.new(origin + lateral * side * 0.52)
            * CFrame.Angles(0, yaw - side * math.rad(43), 0)
        part.Size = Vector3.new(
            tier.Name == "High" and 2.1 or 1.75, 0.065, 0.25
        )
        part.Transparency = math.clamp(transparency, 0, 0.9)
    end
end

local function harborSweepFolder()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    if not arena or arena:GetAttribute("VariantId") ~= "Harbor" then
        return nil, nil
    end
    local mechanics = arena:FindFirstChild("Mechanics")
    local sweep = mechanics and mechanics:FindFirstChild("HarborCargoSweep")
    local base = arena:FindFirstChild("Base")
    if not sweep or not base or not base:IsA("BasePart") then
        return nil, nil
    end
    return sweep, base
end

local function harborWaveActive()
    local sweep = harborSweepFolder()
    if not sweep then return false end
    for _, band in ipairs(sweep:GetChildren()) do
        if band:IsA("BasePart") then
            local phase = band:GetAttribute("HarborSweepPhase")
            if phase == "Warning" or phase == "Pulse" then
                return true
            end
        end
    end
    return false
end

local function createState(warning, snapshot)
    if warningStates[warning] or not warning:IsA("BasePart") then
        return
    end
    local kind = snapshot.Kind
    local color = KIND_COLORS[kind] or warning.Color
    -- A global Jump Shock needs a timed jump, not a misleading floor
    -- arrow suggesting that the player can outrun its arena-wide wave.
    local left, right = nil, nil
    local instances = {}
    if kind ~= "JumpShock" then
        left = makeArrowPart("HazardEscapeL_" .. kind, color)
        right = makeArrowPart("HazardEscapeR_" .. kind, color)
        instances = {left, right}
    end

    warningStates[warning] = {
        kind = kind,
        startedAt = snapshot.StartedAt,
        duration = snapshot.Duration,
        endSize = snapshot.EndSize,
        instances = instances,
        left = left,
        right = right,
    }

    if ensureRenderLoop then
        ensureRenderLoop()
    end
end

local function maybeBind(instance)
    if not instance:IsA("BasePart") or not WARNING_NAMES[instance.Name]
        or instance.Parent ~= workspace or warningStates[instance] then
        return
    end

    -- A late WarningKind without WarningEndSize cannot yield a truthful
    -- escape direction. Wait for the same complete server snapshot as the
    -- companion world-label controller; release watchers on removal.
    local snapshot = WarningRules.snapshot(instance, workspace:GetServerTimeNow())
    if snapshot and SUPPORTED[snapshot.Kind] then
        releasePending(instance)
        createState(instance, snapshot)
        return
    end
    if pendingWarnings[instance] then return end

    local watchers = {}
    pendingWarnings[instance] = watchers
    for _, attribute in ipairs({
        "WarningKind", "WarningStartedAt", "WarningDuration",
        "WarningStartSize", "WarningEndSize",
    }) do
        table.insert(watchers,
            instance:GetAttributeChangedSignal(attribute):Connect(function()
                if instance.Parent == workspace then
                    maybeBind(instance)
                else
                    releasePending(instance)
                end
            end))
    end
    maybeBind(instance)
end

local function hideState(state)
    for _, part in ipairs(state.instances) do
        if part and part.Parent then
            part.Transparency = 1
        end
    end
end

local function hideAllStates()
    for _, state in pairs(warningStates) do
        hideState(state)
    end
    hideHarborArrows()
end

local function updateState(warning, state, root, tier, now, serverNow)
    if not warning.Parent or not root then
        hideState(state)
        return math.huge
    end

    if serverNow >= state.startedAt + state.duration then
        hideState(state)
        return math.huge
    end

    if state.kind == "JumpShock" then
        return math.huge
    end

    -- The luminous disc expands for readability, but damage uses the final
    -- server warning radius. Guide players away from the FULL danger footprint
    -- from the start, including during Double Chaos.
    local playerPosition = root.Position
    -- Meteors and bombs both resolve server damage one stud above their
    -- warning marker. Match that impact center for elevated arena routes.
    local clearance = WarningRules.escapeClearance(
        playerPosition, warning.Position + Vector3.new(0, 1, 0),
        state.endSize
    )
    if clearance == nil then
        hideState(state)
        return math.huge
    end
    if clearance > (tier.Name == "High" and 7 or 5) then
        hideState(state)
        return clearance
    end

    local direction = WarningRules.escapeDirection(
        playerPosition, warning.Position, root.CFrame.LookVector
    )
    if not direction then
        hideState(state)
        return clearance
    end
    local lateral = Vector3.new(direction.Z, 0, -direction.X)
    local origin = playerPosition + Vector3.new(0, -2.65, 0) + direction * 3.1
    local yaw = math.atan2(-direction.X, -direction.Z)
    local reduced = player:GetAttribute("ReduceMotion") == true
    local pulse = reduced and 0.5 or (math.sin(now * 7.5) + 1) * 0.5
    local transparency = (tier.Name == "Low" and 0.42 or 0.28) + pulse * 0.20
    if finalRush then
        transparency += 0.10
    end

    local isBomb = state.kind == "Bomb"
    local spread = isBomb
        and (tier.Name == "Low" and 0.52 or 0.70)
        or (tier.Name == "Low" and 0.42 or 0.58)
    local arrowAngle = isBomb and 56 or 38
    state.left.CFrame = CFrame.new(origin - lateral * spread)
        * CFrame.Angles(0, yaw + math.rad(arrowAngle), 0)
    state.right.CFrame = CFrame.new(origin + lateral * spread)
        * CFrame.Angles(0, yaw - math.rad(arrowAngle), 0)
    state.left.Transparency = math.clamp(transparency, 0, 0.9)
    state.right.Transparency = math.clamp(transparency, 0, 0.9)

    local length = isBomb
        and (tier.Name == "High" and 1.75 or 1.45)
        or (tier.Name == "High" and 2.1 or 1.7)
    local width = isBomb and 0.28 or 0.18
    state.left.Size = Vector3.new(length, 0.06, width)
    state.right.Size = Vector3.new(length, 0.06, width)

    return clearance
end

workspace.ChildAdded:Connect(maybeBind)
workspace.ChildRemoved:Connect(function(instance)
    destroyState(instance)
end)

for _, child in ipairs(workspace:GetChildren()) do
    maybeBind(child)
end

stateEvent.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    currentPhase = tostring(state.phase or "waiting")
    finalRush = state.finalRush == true

    if currentPhase ~= "round" then
        cue.Visible = false
        offscreenArrow.Visible = false
        hideAllStates()
    elseif ensureRenderLoop then
        ensureRenderLoop()
    end
end)

ensureRenderLoop = function()
    if loopStarted then
        return
    end
    loopStarted = true

    task.spawn(function()
        while true do
            if currentPhase ~= "round"
                or (next(warningStates) == nil and not harborWaveActive()) then
                cue.Visible = false
                offscreenArrow.Visible = false
                hideAllStates()
                task.wait(0.18)
                continue
            end

            local tier = quality()
            local cadence = tier.Name == "Low" and 0.12 or 0.075
            task.wait(cadence)

            -- A round may finish, the map may change or warnings may be
            -- removed during the wait. Never revive stale escape arrows
            -- over the result screen or the next arena's onboarding.
            if currentPhase ~= "round"
                or (next(warningStates) == nil and not harborWaveActive()) then
                cue.Visible = false
                offscreenArrow.Visible = false
                hideAllStates()
                continue
            end

            if player:GetAttribute("RoundParticipant") ~= true
                or player:GetAttribute("RoundEliminated") == true
            then
                cue.Visible = false
                offscreenArrow.Visible = false
                hideAllStates()
                continue
            end

            local root = rootPart()
            if not root then
                cue.Visible = false
                offscreenArrow.Visible = false
                hideAllStates()
                continue
            end

            local now = os.clock()
            local serverNow = workspace:GetServerTimeNow()
            local nearestWarning = nil
            local nearestState = nil
            local nearestClearance = math.huge
            local nearestRemaining = math.huge
            local shockRemaining = math.huge
            local sweepFolder, harborFloor = harborSweepFolder()
            local harborGuide = sweepFolder and harborFloor
                and HarborSweepGuidance.select(
                    sweepFolder, root.Position, harborFloor.Position, serverNow
                ) or nil

            -- Select threats before drawing ANY escape arrows. The
            -- previous order drew every overlapping warning, then hid
            -- nearly all of them on Low Android/final rush, wasting
            -- geometry writes and prioritizing deepest exposure even
            -- when another already-dangerous bomb was about to land.
            for warning, state in pairs(warningStates) do
                if not warning.Parent then
                    destroyState(warning)
                else
                    local remaining = WarningRules.window(
                        state.startedAt, state.duration, serverNow
                    )
                    if remaining and remaining > 0.02 then
                        if state.kind == "JumpShock" then
                            shockRemaining = math.min(shockRemaining, remaining)
                        else
                            local clearance = WarningRules.escapeClearance(
                                root.Position, warning.Position + Vector3.new(0, 1, 0),
                                state.endSize
                            )
                            if WarningRules.preferThreat(
                                clearance, remaining,
                                nearestClearance, nearestRemaining
                            ) then
                                nearestClearance = clearance
                                nearestRemaining = remaining
                                nearestWarning = warning
                                nearestState = state
                            end
                        end
                    end
                end
            end

            local onlyNearest = WarningRules.nearestEscapeArrowsOnly(
                UserInputService.TouchEnabled, tier.Name, finalRush
            )
            for warning, state in pairs(warningStates) do
                if onlyNearest and warning ~= nearestWarning then
                    hideState(state)
                else
                    updateState(warning, state, root, tier, now, serverNow)
                end
            end

            -- The Android foreground must give one truthful action.
            -- When global Jump Shock hits first, "JUMP!" cannot be hidden
            -- by a still-distant bomb/meteor warning from Double Chaos.
            -- On desktop, keep the previous impact-first presentation.
            local cueMode
            if UserInputService.TouchEnabled then
                cueMode = WarningRules.mobileActionCue(
                    nearestClearance, nearestRemaining, shockRemaining
                )
            elseif nearestState ~= nil and nearestClearance <= 5 then
                cueMode = "escape"
            elseif shockRemaining < math.huge then
                cueMode = "shock"
            end
            -- Deadly impacts/shock outrank the nonlethal cargo sweep.
            if cueMode == nil and harborGuide then
                cueMode = "harbor"
            end
            local showCue = cueMode == "escape"
            local showShock = cueMode == "shock"
            local showHarbor = cueMode == "harbor"
            cue.Visible = cueMode ~= nil
            if showHarbor then
                drawHarborExit(harborGuide, root, tier, now)
            else
                hideHarborArrows()
            end
            if showCue then
                local kind = nearestState.kind
                local color = KIND_COLORS[kind] or UITheme.Colors.Red
                cueStroke.Color = color
                cueBadge.BackgroundColor3 = color
                cueBadge.Text = KIND_BADGES[kind] or "!"
                cueText.Text = localizedHazardCue(kind)
            elseif showHarbor then
                local color = harborGuide.phase == "Pulse"
                    and UITheme.Colors.Red
                    or Color3.fromRGB(255, 186, 76)
                cueStroke.Color = color
                cueBadge.BackgroundColor3 = color
                cueBadge.Text = "!"
                local fr = string.sub(string.lower(tostring(localeId)), 1, 2) == "fr"
                if harborGuide.phase == "Pulse" then
                    cueText.Text = fr and "BALAYAGE !  ÉCARTE-TOI"
                        or "SWEEP ACTIVE!  MOVE"
                else
                    cueText.Text = string.format("%s  %.1fs",
                        fr and "SAUTE OU SORS" or "JUMP OR EXIT",
                        harborGuide.remaining
                    )
                end
            elseif showShock then
                local color = KIND_COLORS.JumpShock
                cueStroke.Color = color
                cueBadge.BackgroundColor3 = color
                cueBadge.Text = KIND_BADGES.JumpShock
                local prompt = WarningRules.jumpPrompt(
                    shockRemaining, localeId, CoreLocalization
                )
                cueText.Text = (prompt or "") .. string.format("  %.1fs", shockRemaining)
            end

            offscreenArrow.Visible = false
            local camera = workspace.CurrentCamera
            if camera
                and nearestWarning
                and nearestState
                and nearestClearance <= 14
                and cueMode ~= "harbor"
                and (not UserInputService.TouchEnabled or not showShock)
            then
                local viewportPoint, onScreen =
                    camera:WorldToViewportPoint(nearestWarning.Position)
                if not onScreen or viewportPoint.Z <= 0 then
                    local viewport = camera.ViewportSize
                    local center = viewport * 0.5
                    local point = Vector2.new(viewportPoint.X, viewportPoint.Y)
                    local direction = point - center

                    if viewportPoint.Z <= 0 then
                        direction = -direction
                    end
                    if direction.Magnitude < 0.01 then
                        direction = Vector2.new(0, -1)
                    else
                        direction = direction.Unit
                    end

                    local sideMargin = 54
                    local topMargin = 78
                    local bottomMargin = UserInputService.TouchEnabled and 138 or 62
                    local minX = sideMargin
                    local minY = topMargin
                    local maxX = math.max(minX, viewport.X - sideMargin)
                    local maxY = math.max(minY, viewport.Y - bottomMargin)

                    local tx = math.huge
                    if math.abs(direction.X) > 0.001 then
                        tx = direction.X > 0
                            and ((maxX - center.X) / direction.X)
                            or ((minX - center.X) / direction.X)
                    end

                    local ty = math.huge
                    if math.abs(direction.Y) > 0.001 then
                        ty = direction.Y > 0
                            and ((maxY - center.Y) / direction.Y)
                            or ((minY - center.Y) / direction.Y)
                    end

                    local edgeDistance = math.max(0, math.min(tx, ty))
                    local candidate = center + direction * edgeDistance
                    local x = math.clamp(candidate.X, minX, maxX)
                    local y = math.clamp(candidate.Y, minY, maxY)

                    local kind = nearestState.kind
                    local color = KIND_COLORS[kind] or UITheme.Colors.Red
                    offscreenArrow.Position = UDim2.fromOffset(x, y)
                    offscreenArrow.Rotation =
                        math.deg(math.atan2(direction.Y, direction.X)) + 90
                    offscreenArrow.TextColor3 = color
                    offscreenStroke.Color = color
                    offscreenArrow.Visible = true
                end
            end
        end
    end)
end

ensureRenderLoop()
