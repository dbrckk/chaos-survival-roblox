local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UITheme = require(ReplicatedStorage.Shared.UITheme)
local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("RoundState")
local cosmeticStateEvent = remotes:WaitForChild("CosmeticState")

local folder = Instance.new("Folder")
folder.Name = "LobbyProfileHologramLocal"
folder.Parent = workspace

local anchor = nil
local gui = nil
local statsLabel = nil
local progressLabel = nil
local collectionLabel = nil
local xpFill = nil
local currentPhase = "waiting"
local collectionOwned = nil
local collectionTotal = nil

local function clear()
    folder:ClearAllChildren()
    anchor = nil
    gui = nil
    statsLabel = nil
    progressLabel = nil
    collectionLabel = nil
    xpFill = nil
end

local function nextLevelXP(level)
    local numericLevel = math.max(1, math.floor(tonumber(level) or 1))
    return numericLevel * numericLevel * 100
end

local function previousLevelXP(level)
    local numericLevel = math.max(1, math.floor(tonumber(level) or 1))
    if numericLevel <= 1 then
        return 0
    end
    local previous = numericLevel - 1
    return previous * previous * 100
end

local function refreshVisibility()
    if gui then
        gui.Enabled = currentPhase ~= "round" and currentPhase ~= "ready"
    end
end

local function refresh()
    if not gui or not statsLabel or not progressLabel or not xpFill then
        return
    end

    local level = math.max(1, math.floor(tonumber(player:GetAttribute("Level")) or 1))
    local xp = math.max(0, math.floor(tonumber(player:GetAttribute("XP")) or 0))
    local wins = math.max(0, math.floor(tonumber(player:GetAttribute("Wins")) or 0))
    local coins = math.max(0, math.floor(tonumber(player:GetAttribute("Coins")) or 0))

    local fromXP = previousLevelXP(level)
    local toXP = nextLevelXP(level)
    local span = math.max(1, toXP - fromXP)
    local progress = math.clamp((xp - fromXP) / span, 0, 1)
    local remaining = math.max(0, toXP - xp)

    statsLabel.Text = string.format("LVL %d  •  %d WINS  •  %d COINS", level, wins, coins)
    progressLabel.Text = remaining > 0
        and string.format("NEXT LEVEL  •  %d XP TO GO", remaining)
        or "NEXT LEVEL READY"
    xpFill.Size = UDim2.fromScale(progress, 1)

    if collectionLabel then
        if collectionOwned ~= nil and collectionTotal ~= nil then
            collectionLabel.Text = string.format(
                "COLLECTION  %d / %d",
                collectionOwned,
                collectionTotal
            )
        else
            collectionLabel.Text = "COLLECTION  •  SYNCING"
        end
    end

    refreshVisibility()
end

local function build()
    clear()

    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    if not lobby then
        return
    end

    anchor = Instance.new("Part")
    anchor.Name = "ProfileHologramAnchor"
    anchor.Size = Vector3.new(0.2, 0.2, 0.2)
    anchor.Position = Config.LobbyCenter + Vector3.new(-27, 8.2, 3)
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanTouch = false
    anchor.CanQuery = false
    anchor.CastShadow = false
    anchor.Transparency = 1
    anchor.Parent = folder

    gui = Instance.new("BillboardGui")
    gui.Name = "ProfileHologram"
    gui.Adornee = anchor
    gui.Size = UDim2.fromOffset(390, 178)
    gui.StudsOffset = Vector3.new(0, 0, 0)
    gui.AlwaysOnTop = false
    gui.LightInfluence = 0
    gui.MaxDistance = 78
    gui.Parent = anchor

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromScale(1, 1)
    panel.BackgroundColor3 = UITheme.Colors.Panel
    panel.BackgroundTransparency = 0.10
    panel.BorderSizePixel = 0
    panel.Parent = gui
    UITheme.addCorner(panel, UITheme.Corners.Large)
    UITheme.addStroke(panel, UITheme.Colors.Cyan, 1.4, 0.30)
    UITheme.addGradient(
        panel,
        UITheme.Colors.PanelRaised,
        UITheme.Colors.Panel,
        90
    )

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1, 0, 0, 6)
    accent.BackgroundColor3 = UITheme.Colors.Cyan
    accent.BorderSizePixel = 0
    accent.Parent = panel
    UITheme.addCorner(accent, UITheme.Corners.Pill)

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromScale(0.05, 0.08)
    title.Size = UDim2.fromScale(0.90, 0.19)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.Text = "YOUR CHAOS PROFILE"
    title.TextColor3 = UITheme.Colors.Cyan
    title.TextScaled = true
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = panel

    statsLabel = Instance.new("TextLabel")
    statsLabel.Position = UDim2.fromScale(0.05, 0.30)
    statsLabel.Size = UDim2.fromScale(0.90, 0.16)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Font = Enum.Font.GothamBold
    statsLabel.TextColor3 = UITheme.Colors.Text
    statsLabel.TextScaled = true
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Parent = panel

    local xpTrack = Instance.new("Frame")
    xpTrack.Position = UDim2.fromScale(0.05, 0.51)
    xpTrack.Size = UDim2.fromScale(0.90, 0.075)
    xpTrack.BackgroundColor3 = UITheme.Colors.PanelSoft
    xpTrack.BackgroundTransparency = 0.10
    xpTrack.BorderSizePixel = 0
    xpTrack.Parent = panel
    UITheme.addCorner(xpTrack, UITheme.Corners.Pill)

    xpFill = Instance.new("Frame")
    xpFill.Size = UDim2.fromScale(0, 1)
    xpFill.BackgroundColor3 = UITheme.Colors.Cyan
    xpFill.BorderSizePixel = 0
    xpFill.Parent = xpTrack
    UITheme.addCorner(xpFill, UITheme.Corners.Pill)
    UITheme.addGradient(xpFill, UITheme.Colors.Cyan, UITheme.Colors.Violet, 0)

    progressLabel = Instance.new("TextLabel")
    progressLabel.Position = UDim2.fromScale(0.05, 0.61)
    progressLabel.Size = UDim2.fromScale(0.90, 0.13)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Font = Enum.Font.GothamMedium
    progressLabel.TextColor3 = UITheme.Colors.Muted
    progressLabel.TextScaled = true
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Parent = panel

    collectionLabel = Instance.new("TextLabel")
    collectionLabel.Position = UDim2.fromScale(0.05, 0.78)
    collectionLabel.Size = UDim2.fromScale(0.90, 0.13)
    collectionLabel.BackgroundTransparency = 1
    collectionLabel.Font = Enum.Font.GothamBold
    collectionLabel.TextColor3 = UITheme.Colors.Gold
    collectionLabel.TextScaled = true
    collectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    collectionLabel.Parent = panel

    refresh()
end

for _, attribute in ipairs({"Level", "XP", "Wins", "Coins", "DataLoaded"}) do
    player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

cosmeticStateEvent.OnClientEvent:Connect(function(payload)
    local state = payload and payload.state
    local log = state and state.collectionLog
    if type(log) == "table" then
        collectionOwned = math.max(0, math.floor(tonumber(log.owned) or 0))
        collectionTotal = math.max(0, math.floor(tonumber(log.total) or 0))
        refresh()
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    currentPhase = tostring(state.phase or "waiting")
    refreshVisibility()
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(build)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clear()
    end
end)

task.defer(build)
