local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LobbyPresentationRules = require(ReplicatedStorage.Shared.LobbyPresentationRules)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "LobbyPresentationLocal"
folder.Parent = workspace

local currentState = {
    phase = "waiting",
    seconds = 0,
    title = "",
}
local previousPhase = "waiting"
local currentLobby = nil
local currentDecor = nil
local currentActivities = nil
local statusGui = nil
local socialPads = {}
local trackedParts = {}
local haloSegments = {}
local loopPanels = {}
local pylonGlows = {}
local approachRibs = {}
local practicePads = {}
local presentationToken = 0
local pulseCursor = 0

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function clearLocal()
    presentationToken += 1
    folder:ClearAllChildren()
    socialPads = {}

    if statusGui and statusGui.Parent then
        statusGui:Destroy()
    end
    statusGui = nil

    trackedParts = {}
    haloSegments = {}
    loopPanels = {}
    pylonGlows = {}
    approachRibs = {}
    practicePads = {}
    currentLobby = nil
    currentDecor = nil
    currentActivities = nil
end

local function findLobby()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    return lobby
end

local function rememberPart(part)
    if not part or not part:IsA("BasePart") or trackedParts[part] then
        return
    end

    trackedParts[part] = {
        Transparency = part.Transparency,
        Color = part.Color,
    }
end

local function cacheActivities()
    practicePads = {}
    currentActivities = currentLobby and currentLobby:FindFirstChild("Activities") or nil
    if not currentActivities then
        return
    end

    for _, child in ipairs(currentActivities:GetChildren()) do
        if child:IsA("BasePart")
            and child:GetAttribute("LobbyPracticePad") == true
        then
            rememberPart(child)
            table.insert(practicePads, child)
        end
    end
    table.sort(practicePads, function(a, b)
        return a.Name < b.Name
    end)
end

local function centerPosition()
    local floor = currentLobby and currentLobby:FindFirstChild("Floor")
    if floor and floor:IsA("BasePart") then
        return floor.Position + Vector3.new(0, floor.Size.Y * 0.5 + 0.08, 0)
    end
    return Vector3.zero
end

local function makeSocialPads()
    local center = centerPosition()
    local offsets = {
        Vector3.new(-13, 0, -13),
        Vector3.new(13, 0, -13),
        Vector3.new(-13, 0, 13),
        Vector3.new(13, 0, 13),
    }

    local budget = LobbyPresentationRules.decorBudget(quality().Name)
    local count = math.min(#offsets, math.max(2, math.floor(budget / 2)))

    for i = 1, count do
        local pad = Instance.new("Part")
        pad.Name = "LobbySocialNode" .. i
        pad.Shape = Enum.PartType.Cylinder
        pad.Size = Vector3.new(0.055, 5.6, 5.6)
        pad.CFrame = CFrame.new(center + offsets[i])
            * CFrame.Angles(0, 0, math.rad(90))
        pad.Anchored = true
        pad.CanCollide = false
        pad.CanTouch = false
        pad.CanQuery = false
        pad.CastShadow = false
        pad.Material = Enum.Material.Neon
        pad.Color = i % 2 == 0
            and VisualTheme.Accents.Violet
            or VisualTheme.Accents.Cyan
        pad.Transparency = 0.74
        pad.Parent = folder
        table.insert(socialPads, pad)

        local core = Instance.new("Part")
        core.Name = "LobbySocialCore" .. i
        core.Shape = Enum.PartType.Cylinder
        core.Size = Vector3.new(0.045, 2.2, 2.2)
        core.CFrame = pad.CFrame + Vector3.new(0, 0.035, 0)
        core.Anchored = true
        core.CanCollide = false
        core.CanTouch = false
        core.CanQuery = false
        core.CastShadow = false
        core.Material = Enum.Material.Neon
        core.Color = pad.Color:Lerp(Color3.new(1, 1, 1), 0.24)
        core.Transparency = 0.56
        core.Parent = folder
    end
end

local function makeStatusGui()
    local anchor = currentDecor and currentDecor:FindFirstChild("CenterGlow")
    if not anchor or not anchor:IsA("BasePart") then
        return
    end

    local gui = Instance.new("BillboardGui")
    gui.Name = "LobbyLiveStatus"
    gui.Adornee = anchor
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.Size = UDim2.fromOffset(300, 72)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 5.2, 0)
    gui.MaxDistance = 105
    gui.Parent = player:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromScale(1, 1)
    panel.BackgroundColor3 = Color3.fromRGB(8, 13, 23)
    panel.BackgroundTransparency = 0.18
    panel.BorderSizePixel = 0
    panel.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Name = "StatusStroke"
    stroke.Color = VisualTheme.Accents.Cyan
    stroke.Thickness = 2
    stroke.Transparency = 0.22
    stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.Name = "StatusTitle"
    title.Position = UDim2.fromScale(0.05, 0.10)
    title.Size = UDim2.fromScale(0.90, 0.44)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.Text = "LOBBY LIVE"
    title.TextColor3 = Color3.fromRGB(244, 248, 255)
    title.TextScaled = true
    title.Parent = panel

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "StatusSubtitle"
    subtitle.Position = UDim2.fromScale(0.05, 0.58)
    subtitle.Size = UDim2.fromScale(0.90, 0.24)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamBold
    subtitle.Text = "PRACTICE • VOTE • SURVIVE"
    subtitle.TextColor3 = VisualTheme.Accents.Cyan
    subtitle.TextScaled = true
    subtitle.TextWrapped = true
    subtitle.Parent = panel

    statusGui = gui
end

local function bindLobby()
    clearLocal()

    currentLobby = findLobby()
    if not currentLobby then
        return
    end

    currentDecor = currentLobby:FindFirstChild("Decor")
    currentActivities = currentLobby:FindFirstChild("Activities")

    if currentDecor then
        for _, name in ipairs({
            "CenterGlow",
            "ArenaRunwayRailLeft",
            "ArenaRunwayRailRight",
            "ArenaGateTop",
        }) do
            rememberPart(currentDecor:FindFirstChild(name))
        end

        for _, descendant in ipairs(currentDecor:GetChildren()) do
            if descendant:IsA("BasePart") then
                if string.find(descendant.Name, "LobbyHaloSegment") then
                    rememberPart(descendant)
                    table.insert(haloSegments, descendant)
                elseif string.find(descendant.Name, "LobbyLoopPanel") then
                    rememberPart(descendant)
                    table.insert(loopPanels, descendant)
                elseif string.find(descendant.Name, "PylonGlow") then
                    rememberPart(descendant)
                    table.insert(pylonGlows, descendant)
                elseif string.find(descendant.Name, "ArenaApproachRibTop") then
                    rememberPart(descendant)
                    table.insert(approachRibs, descendant)
                end
            end
        end

        local function byName(a, b)
            return a.Name < b.Name
        end
        table.sort(haloSegments, byName)
        table.sort(loopPanels, byName)
        table.sort(pylonGlows, byName)
        table.sort(approachRibs, byName)
    end

    cacheActivities()

    makeSocialPads()
    makeStatusGui()
end

local function modeColor(mode)
    if mode == "vote" then
        return VisualTheme.Accents.Magenta
    elseif mode == "launch" then
        return VisualTheme.Accents.Violet
    elseif mode == "social" then
        return VisualTheme.Accents.Cyan
    end
    return VisualTheme.World.MutedText
end

local function tweenPart(part, transparency, color, duration)
    if not part or not part.Parent then
        return
    end

    local goal = {
        Transparency = math.clamp(transparency, 0, 1),
    }
    if color then
        goal.Color = color
    end

    TweenService:Create(
        part,
        TweenInfo.new(duration or 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        goal
    ):Play()
end

local function applyState()
    if not currentLobby or not currentLobby.Parent then
        bindLobby()
    end
    if not currentLobby then
        return
    end

    currentDecor = currentLobby:FindFirstChild("Decor") or currentDecor
    local nextActivities = currentLobby:FindFirstChild("Activities")
    if nextActivities ~= currentActivities then
        currentActivities = nextActivities
        cacheActivities()
    end
    if not statusGui or not statusGui.Parent then
        makeStatusGui()
    end

    local mode = LobbyPresentationRules.mode(
        currentState.phase,
        currentState.voteOptions
    )
    local emphasis = LobbyPresentationRules.emphasis(
        currentState.phase,
        currentState.voteOptions
    )
    local accent = modeColor(mode)
    local q = quality()
    local duration = player:GetAttribute("ReduceMotion") == true and 0.10 or 0.24

    local centerGlow = currentDecor and currentDecor:FindFirstChild("CenterGlow")
    if centerGlow and centerGlow:IsA("BasePart") then
        tweenPart(
            centerGlow,
            0.64 - emphasis.Center * 0.46,
            accent,
            duration
        )
        local light = centerGlow:FindFirstChild("LobbyGlow")
        if light and light:IsA("PointLight") then
            light.Color = accent
            light.Brightness = q.Name == "Low" and 0.45
                or (0.55 + emphasis.Center * (q.Name == "High" and 0.95 or 0.55))
            light.Range = q.Name == "Low" and 18 or 24
        end
    end

    for _, child in ipairs(loopPanels) do
        if child.Parent then
            local index = tonumber(string.match(child.Name, "(%d+)$")) or 1
            local focus = mode == "vote" and index == 1
                or mode == "launch" and index == 2
                or mode == "social" and index == 3
            tweenPart(
                child,
                focus and 0.02 or 0.10,
                focus and accent or VisualTheme.World.Deep,
                duration
            )
        end
    end

    for _, child in ipairs(pylonGlows) do
        if child.Parent then
            tweenPart(
                child,
                0.52 - emphasis.Center * 0.32,
                accent:Lerp(child.Color, 0.24),
                duration
            )
        end
    end

    for _, child in ipairs(approachRibs) do
        if child.Parent then
            local index = tonumber(string.match(child.Name, "(%d+)$")) or 1
            local launchColor = index % 2 == 0
                and VisualTheme.Accents.Gold
                or VisualTheme.Accents.Cyan
            tweenPart(
                child,
                0.66 - emphasis.Runway * 0.52,
                mode == "launch" and launchColor or child.Color,
                duration
            )
        end
    end

    for _, child in ipairs(practicePads) do
        if child.Parent then
            tweenPart(
                child,
                0.74 - emphasis.Practice * 0.56,
                child.Color,
                duration
            )
        end
    end

    for _, pad in ipairs(socialPads) do
        if pad.Parent then
            tweenPart(
                pad,
                mode == "inactive" and 1 or (0.92 - emphasis.Social * 0.30),
                pad.Color,
                duration
            )
        end
    end

    if statusGui and statusGui.Parent then
        statusGui.Enabled = mode ~= "inactive"
    end

    for _, name in ipairs({"ArenaRunwayRailLeft", "ArenaRunwayRailRight"}) do
        local rail = currentDecor and currentDecor:FindFirstChild(name)
        if rail and rail:IsA("BasePart") then
            tweenPart(
                rail,
                0.72 - emphasis.Runway * 0.56,
                name == "ArenaRunwayRailLeft"
                    and VisualTheme.Accents.Cyan
                    or VisualTheme.Accents.Violet,
                duration
            )
        end
    end

    local gate = currentDecor and currentDecor:FindFirstChild("ArenaGateTop")
    if gate and gate:IsA("BasePart") then
        tweenPart(
            gate,
            0.58 - emphasis.Runway * 0.42,
            mode == "launch" and VisualTheme.Accents.Gold or VisualTheme.Accents.Violet,
            duration
        )
    end

    if statusGui and statusGui.Parent then
        local panel = statusGui:FindFirstChildOfClass("Frame")
        local title = panel and panel:FindFirstChild("StatusTitle")
        local subtitle = panel and panel:FindFirstChild("StatusSubtitle")
        local stroke = panel and panel:FindFirstChild("StatusStroke")
        local mainText, subText = LobbyPresentationRules.statusText(
            currentState.phase,
            currentState.seconds,
            currentState.title,
            currentState.voteOptions
        )
        local games = math.max(0, math.floor(tonumber(player:GetAttribute("Games")) or 0))
        if games <= 0
            and currentState.phase == "intermission"
            and currentState.voteOptions == nil
        then
            mainText = "MOVE + JUMP"
            subText = "SURVIVE UNTIL 0"
        end

        if title and title:IsA("TextLabel") then
            title.Text = mainText
        end
        if subtitle and subtitle:IsA("TextLabel") then
            subtitle.Text = subText
            subtitle.TextColor3 = accent
        end
        if stroke and stroke:IsA("UIStroke") then
            stroke.Color = accent
        end
    end
end

local function pulseCenter(mode, token)
    if token ~= presentationToken or not currentDecor then
        return
    end

    local centerGlow = currentDecor:FindFirstChild("CenterGlow")
    if not centerGlow or not centerGlow:IsA("BasePart") then
        return
    end

    local emphasis = LobbyPresentationRules.emphasis(currentState.phase)
    local baseTransparency = 0.64 - emphasis.Center * 0.46
    local pulseTransparency = math.max(0.08, baseTransparency - 0.10)

    TweenService:Create(
        centerGlow,
        TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Transparency = pulseTransparency}
    ):Play()
    task.delay(0.20, function()
        if token == presentationToken and centerGlow.Parent then
            TweenService:Create(
                centerGlow,
                TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Transparency = baseTransparency}
            ):Play()
        end
    end)
end

local function ambientRipple(mode, token)
    if token ~= presentationToken or not currentDecor then
        return
    end

    pulseCursor += 1

    if mode == "social" and #socialPads > 0 then
        local pad = socialPads[((pulseCursor - 1) % #socialPads) + 1]
        if pad and pad.Parent then
            local baseTransparency = 0.92
                - LobbyPresentationRules.emphasis(
                    currentState.phase,
                    currentState.voteOptions
                ).Social * 0.30
            TweenService:Create(
                pad,
                TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Transparency = math.max(0.42, baseTransparency - 0.16)}
            ):Play()
            task.delay(0.22, function()
                if token == presentationToken and pad.Parent then
                    TweenService:Create(
                        pad,
                        TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {Transparency = baseTransparency}
                    ):Play()
                end
            end)
        end
    end

    if mode == "social" or mode == "vote" then
        if #haloSegments > 0 then
            local segment = haloSegments[((pulseCursor - 1) % #haloSegments) + 1]
            local original = trackedParts[segment]
            local targetColor = mode == "vote"
                and VisualTheme.Accents.Magenta
                or VisualTheme.Accents.Cyan
            TweenService:Create(
                segment,
                TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Transparency = 0.10,
                    Color = targetColor,
                }
            ):Play()
            task.delay(0.20, function()
                if token == presentationToken and segment.Parent then
                    TweenService:Create(
                        segment,
                        TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {
                            Transparency = original and original.Transparency or 0.20,
                            Color = original and original.Color or segment.Color,
                        }
                    ):Play()
                end
            end)
        end
    end
end

local function runwaySweep(token)
    if token ~= presentationToken
        or LobbyPresentationRules.mode(
            currentState.phase,
            currentState.voteOptions
        ) ~= "launch"
        or not currentDecor
    then
        return
    end

    local runway = currentDecor:FindFirstChild("ArenaRunway")
    if not runway or not runway:IsA("BasePart") then
        return
    end

    local sweep = Instance.new("Part")
    sweep.Name = "LobbyRunwaySweep"
    sweep.Size = Vector3.new(runway.Size.X * 0.80, 0.04, 0.55)
    sweep.CFrame = runway.CFrame
        * CFrame.new(0, runway.Size.Y * 0.5 + 0.05, runway.Size.Z * 0.42)
    sweep.Anchored = true
    sweep.CanCollide = false
    sweep.CanTouch = false
    sweep.CanQuery = false
    sweep.CastShadow = false
    sweep.Material = Enum.Material.Neon
    sweep.Color = VisualTheme.Accents.Gold
    sweep.Transparency = 0.30
    sweep.Parent = folder

    TweenService:Create(
        sweep,
        TweenInfo.new(
            player:GetAttribute("ReduceMotion") == true and 0.22 or 0.46,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.In
        ),
        {
            CFrame = runway.CFrame
                * CFrame.new(0, runway.Size.Y * 0.5 + 0.05, -runway.Size.Z * 0.42),
            Transparency = 1,
        }
    ):Play()

    task.delay(0.52, function()
        if sweep.Parent then
            sweep:Destroy()
        end
    end)
end

local function startPulseLoop()
    presentationToken += 1
    local token = presentationToken

    task.spawn(function()
        while token == presentationToken do
            local mode = LobbyPresentationRules.mode(
                currentState.phase,
                currentState.voteOptions
            )
            local q = quality()
            local cadence = LobbyPresentationRules.pulseCadence(
                q.Name,
                player:GetAttribute("ReduceMotion") == true,
                mode
            )

            if mode ~= "inactive" then
                pulseCenter(mode, token)
                ambientRipple(mode, token)
                if mode == "launch" then
                    runwaySweep(token)
                end
            end

            task.wait(cadence)
        end
    end)
end

local function lobbyReturnPulse()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then
        return
    end

    local q = quality()
    local reduced = player:GetAttribute("ReduceMotion") == true

    local ring = Instance.new("Part")
    ring.Name = "LobbyReturnPulse"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.04, 2.6, 2.6)
    ring.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.6, 0))
        * CFrame.Angles(0, 0, math.rad(90))
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.CastShadow = false
    ring.Material = Enum.Material.Neon
    ring.Color = VisualTheme.Accents.Cyan
    ring.Transparency = 0.34
    ring.Parent = folder

    local target = q.Name == "Low" and 8.0 or 11.0
    TweenService:Create(
        ring,
        TweenInfo.new(
            reduced and 0.20 or 0.38,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        {
            Size = Vector3.new(0.04, target, target),
            Transparency = 1,
        }
    ):Play()

    task.delay(0.44, function()
        if ring.Parent then
            ring:Destroy()
        end
    end)
end

stateEvent.OnClientEvent:Connect(function(state)
    local nextState = state or currentState
    local nextPhase = tostring(nextState.phase or "waiting")

    if previousPhase == "result"
        and (nextPhase == "intermission" or nextPhase == "waiting")
    then
        task.delay(0.08, lobbyReturnPulse)
    end

    currentState = nextState
    previousPhase = nextPhase
    applyState()
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    bindLobby()
    applyState()
    startPulseLoop()
end)

player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    applyState()
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.delay(0.12, function()
            bindLobby()
            applyState()
            startPulseLoop()
        end)
    end
end)

local generated = workspace:FindFirstChild("GeneratedMap")
if generated then
    generated.ChildAdded:Connect(function(child)
        if child.Name == "Lobby" then
            task.delay(0.08, function()
                bindLobby()
                applyState()
                startPulseLoop()
            end)
        end
    end)
end

bindLobby()
applyState()
startPulseLoop()
