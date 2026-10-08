local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalizationService = game:GetService("LocalizationService")

local Config = require(ReplicatedStorage.Shared.Config)
local UITheme = require(ReplicatedStorage.Shared.UITheme)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local HazardGlyphs = require(ReplicatedStorage.Shared.HazardGlyphs)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "LobbyRoundRecapLocal"
folder.Parent = workspace

local currentPhase = "waiting"
local latestRecap = nil
local anchor = nil
local billboard = nil
local title = nil
local hazard = nil
local meta = nil
local accent = nil
local scale = nil
local glyphCanvas = nil
local survivorFill = nil
local wasVisible = false

local function clear()
    folder:ClearAllChildren()
    anchor = nil
    billboard = nil
    title = nil
    hazard = nil
    meta = nil
    accent = nil
    scale = nil
    glyphCanvas = nil
    survivorFill = nil
    wasVisible = false
end

local function renderGlyph(container, hazardId, color)
    if not container then
        return
    end

    for _, child in ipairs(container:GetChildren()) do
        child:Destroy()
    end

    local recipe = HazardGlyphs.get(hazardId)
    if not recipe then
        return
    end

    for index, def in ipairs(recipe) do
        local segment = Instance.new("Frame")
        segment.Name = "GlyphStroke" .. tostring(index)
        segment.AnchorPoint = Vector2.new(0.5, 0.5)
        segment.Position = UDim2.fromScale(def.X, def.Y)
        segment.Size = UDim2.fromScale(def.Width, def.Height)
        segment.Rotation = def.Rotation or 0
        segment.BackgroundColor3 = color
        segment.BackgroundTransparency = 0.08
        segment.BorderSizePixel = 0
        segment.Parent = container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = segment
    end
end

local function build()
    clear()

    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    if not lobby then
        return
    end

    anchor = Instance.new("Part")
    anchor.Name = "RoundRecapAnchor"
    anchor.Size = Vector3.new(0.2, 0.2, 0.2)
    anchor.Position = Config.LobbyCenter + Vector3.new(27, 8.2, -13)
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.CastShadow = false
    anchor.Transparency = 1
    anchor.Parent = folder

    billboard = Instance.new("BillboardGui")
    billboard.Name = "RoundRecapBoard"
    billboard.Adornee = anchor
    billboard.Size = UDim2.fromOffset(390, 142)
    billboard.AlwaysOnTop = false
    billboard.LightInfluence = 0
    billboard.MaxDistance = 82
    billboard.Enabled = false
    billboard.Parent = anchor

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromScale(1, 1)
    panel.BackgroundColor3 = UITheme.Colors.Panel
    panel.BackgroundTransparency = 0.09
    panel.BorderSizePixel = 0
    panel.Parent = billboard
    UITheme.addCorner(panel, UITheme.Corners.Large)
    UITheme.addStroke(panel, UITheme.Colors.Cyan, 1.4, 0.34)
    UITheme.addGradient(panel, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

    scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = panel

    accent = Instance.new("Frame")
    accent.Name = "HazardAccent"
    accent.Position = UDim2.fromScale(0.05, 0.06)
    accent.Size = UDim2.fromScale(0.90, 0.045)
    accent.BackgroundColor3 = UITheme.Colors.Cyan
    accent.BorderSizePixel = 0
    accent.Parent = panel
    UITheme.addCorner(accent, UITheme.Corners.Pill)

    title = Instance.new("TextLabel")
    title.Position = UDim2.fromScale(0.05, 0.15)
    title.Size = UDim2.fromScale(0.90, 0.18)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = CoreLocalization.text(localeId, "LAST_CHAOS")
    title.TextColor3 = UITheme.Colors.Muted
    title.TextScaled = true
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = panel
    UITheme.addTextConstraint(title, 10, 15)

    hazard = Instance.new("TextLabel")
    hazard.Position = UDim2.fromScale(0.05, 0.36)
    hazard.Size = UDim2.fromScale(0.69, 0.26)
    hazard.BackgroundTransparency = 1
    hazard.Font = Enum.Font.GothamBlack
    hazard.Text = "CHAOS"
    hazard.TextColor3 = UITheme.Colors.Text
    hazard.TextScaled = true
    hazard.TextWrapped = true
    hazard.TextXAlignment = Enum.TextXAlignment.Left
    hazard.Parent = panel
    UITheme.addTextConstraint(hazard, 15, 24)

    meta = Instance.new("TextLabel")
    meta.Position = UDim2.fromScale(0.05, 0.68)
    meta.Size = UDim2.fromScale(0.69, 0.18)
    meta.BackgroundTransparency = 1
    meta.Font = Enum.Font.GothamBold
    meta.Text = ""
    meta.TextColor3 = UITheme.Colors.Cyan
    meta.TextScaled = true
    meta.TextXAlignment = Enum.TextXAlignment.Left
    meta.Parent = panel
    UITheme.addTextConstraint(meta, 10, 15)

    local glyphFrame = Instance.new("Frame")
    glyphFrame.Name = "RecapHazardGlyph"
    glyphFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    glyphFrame.Position = UDim2.fromScale(0.855, 0.52)
    glyphFrame.Size = UDim2.fromScale(0.18, 0.47)
    glyphFrame.BackgroundColor3 = UITheme.Colors.PanelSoft
    glyphFrame.BackgroundTransparency = 0.16
    glyphFrame.BorderSizePixel = 0
    glyphFrame.Parent = panel
    UITheme.addCorner(glyphFrame, UITheme.Corners.Medium)
    UITheme.addStroke(glyphFrame, UITheme.Colors.Cyan, 1.0, 0.42)

    glyphCanvas = Instance.new("Frame")
    glyphCanvas.AnchorPoint = Vector2.new(0.5, 0.5)
    glyphCanvas.Position = UDim2.fromScale(0.5, 0.5)
    glyphCanvas.Size = UDim2.fromScale(0.72, 0.72)
    glyphCanvas.BackgroundTransparency = 1
    glyphCanvas.Parent = glyphFrame

    local survivorTrack = Instance.new("Frame")
    survivorTrack.Name = "SurvivorRatioTrack"
    survivorTrack.Position = UDim2.fromScale(0.05, 0.91)
    survivorTrack.Size = UDim2.fromScale(0.90, 0.035)
    survivorTrack.BackgroundColor3 = UITheme.Colors.PanelSoft
    survivorTrack.BackgroundTransparency = 0.10
    survivorTrack.BorderSizePixel = 0
    survivorTrack.Parent = panel
    UITheme.addCorner(survivorTrack, UITheme.Corners.Pill)

    survivorFill = Instance.new("Frame")
    survivorFill.Name = "SurvivorRatioFill"
    survivorFill.Size = UDim2.fromScale(0, 1)
    survivorFill.BackgroundColor3 = UITheme.Colors.Cyan
    survivorFill.BorderSizePixel = 0
    survivorFill.Parent = survivorTrack
    UITheme.addCorner(survivorFill, UITheme.Corners.Pill)
end

local function shouldShow()
    if not latestRecap or player:GetAttribute("DataLoaded") ~= true then
        return false
    end
    if math.max(0, math.floor(tonumber(player:GetAttribute("Games")) or 0)) < 1 then
        return false
    end
    return currentPhase == "intermission" or currentPhase == "waiting"
end

local function refresh()
    if not billboard or not billboard.Parent then
        build()
    end
    if not billboard then
        return
    end

    local visible = shouldShow()
    billboard.Enabled = visible

    if latestRecap and hazard and meta and accent then
        local ids = type(latestRecap.disasterIds) == "table"
            and latestRecap.disasterIds
            or {}
        hazard.Text = CoreLocalization.hazardTitle(
            localeId,
            ids,
            CoreLocalization.text(localeId, "LAST_CHAOS")
        )

        local survivors = math.max(0, math.floor(tonumber(latestRecap.survivorsAlive) or 0))
        local contestants = math.max(
            survivors,
            math.floor(tonumber(latestRecap.contestantCount) or survivors)
        )
        local arenaName = CoreLocalization.arenaName(
            localeId,
            latestRecap.arenaId or latestRecap.arenaName,
            latestRecap.arenaName or "ARENA"
        )

        meta.Text = CoreLocalization.text(
            localeId,
            "SURVIVED_COUNT",
            survivors,
            contestants
        ) .. "  •  " .. tostring(arenaName)

        accent.BackgroundColor3 = UITheme.disasterAccent(
            ids[1],
            UITheme.Colors.Cyan
        )
        meta.TextColor3 = accent.BackgroundColor3

        renderGlyph(glyphCanvas, ids[1], accent.BackgroundColor3)
        local ratio = contestants > 0 and math.clamp(survivors / contestants, 0, 1) or 0
        if survivorFill then
            survivorFill.Size = UDim2.fromScale(ratio, 1)
            survivorFill.BackgroundColor3 = ratio >= 0.75
                and UITheme.Colors.Green
                or (ratio >= 0.40 and UITheme.Colors.Cyan or UITheme.Colors.Orange)
        end
    end

    if visible and not wasVisible and scale then
        if player:GetAttribute("ReduceMotion") == true then
            scale.Scale = 1
        else
            scale.Scale = 0.92
            TweenService:Create(
                scale,
                TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Scale = 1}
            ):Play()
        end
    end
    wasVisible = visible
end

stateEvent.OnClientEvent:Connect(function(state)
    currentPhase = tostring(state.phase or "waiting")

    if currentPhase == "result"
        and type(state.disasterIds) == "table"
        and #state.disasterIds > 0
    then
        latestRecap = {
            disasterIds = table.clone(state.disasterIds),
            arenaId = state.arenaId,
            arenaName = state.arenaName,
            survivorsAlive = state.survivorsAlive,
            contestantCount = state.contestantCount,
        }
    end

    refresh()
end)

for _, attribute in ipairs({"Games", "DataLoaded", "ReduceMotion"}) do
    local attributeName = attribute
    player:GetAttributeChangedSignal(attributeName):Connect(refresh)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(function()
            build()
            refresh()
        end)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clear()
    end
end)

build()
refresh()
