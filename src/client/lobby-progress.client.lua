local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")

local Config = require(ReplicatedStorage.Shared.Config)
local UITheme = require(ReplicatedStorage.Shared.UITheme)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId

local folder = Instance.new("Folder")
folder.Name = "LobbyPersonalProgressLocal"
folder.Parent = workspace

local anchor = Instance.new("Part")
anchor.Name = "PersonalProgressAnchor"
anchor.Size = Vector3.new(0.4, 0.4, 0.4)
anchor.Anchored = true
anchor.CanCollide = false
anchor.CanTouch = false
anchor.CanQuery = false
anchor.CastShadow = false
anchor.Transparency = 1
anchor.Position = Config.LobbyCenter + Vector3.new(0, 8.5, -18.5)
anchor.Parent = folder

local billboard = Instance.new("BillboardGui")
billboard.Name = "PersonalProgressBoard"
billboard.Size = UDim2.fromOffset(560, 180)
billboard.StudsOffset = Vector3.new(0, 0, 0)
billboard.AlwaysOnTop = false
billboard.MaxDistance = 90
billboard.LightInfluence = 0
billboard.Parent = anchor

local panel = Instance.new("Frame")
panel.Size = UDim2.fromScale(1, 1)
panel.BackgroundColor3 = UITheme.Colors.Panel
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = billboard
UITheme.addCorner(panel, UITheme.Corners.Large)
UITheme.addStroke(panel, UITheme.Colors.Cyan, 2, 0.28)
UITheme.addGradient(panel, UITheme.Colors.PanelRaised, UITheme.Colors.Panel, 90)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -32, 0.26, 0)
title.Position = UDim2.fromOffset(16, 10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextColor3 = UITheme.Colors.Cyan
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = CoreLocalization.text(localeId, "CHAOS_RUN")
title.Parent = panel

local stats = Instance.new("TextLabel")
stats.Size = UDim2.new(1, -32, 0.28, 0)
stats.Position = UDim2.new(0, 16, 0.30, 0)
stats.BackgroundTransparency = 1
stats.Font = Enum.Font.GothamBold
stats.TextColor3 = UITheme.Colors.Text
stats.TextScaled = true
stats.TextXAlignment = Enum.TextXAlignment.Left
stats.Text = CoreLocalization.text(localeId, "RUN_STATS", 1, 0, 0, 0)
stats.Parent = panel

local goal = Instance.new("TextLabel")
goal.Size = UDim2.new(1, -32, 0.20, 0)
goal.Position = UDim2.new(0, 16, 0.58, 0)
goal.BackgroundTransparency = 1
goal.Font = Enum.Font.GothamMedium
goal.TextColor3 = UITheme.Colors.Muted
goal.TextScaled = true
goal.TextXAlignment = Enum.TextXAlignment.Left
goal.Text = CoreLocalization.text(localeId, "RUN_NEXT_LEVEL", 2, 0)
goal.Parent = panel

local barBack = Instance.new("Frame")
barBack.Size = UDim2.new(1, -32, 0.08, 0)
barBack.Position = UDim2.new(0, 16, 0.84, 0)
barBack.BackgroundColor3 = UITheme.Colors.PanelSoft
barBack.BackgroundTransparency = 0.08
barBack.BorderSizePixel = 0
barBack.Parent = panel
UITheme.addCorner(barBack, UITheme.Corners.Pill)

local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0, 1)
bar.BackgroundColor3 = UITheme.Colors.Cyan
bar.BorderSizePixel = 0
bar.Parent = barBack
UITheme.addCorner(bar, UITheme.Corners.Pill)
UITheme.addGradient(bar, UITheme.Colors.Cyan, UITheme.Colors.Violet, 0)

local function ownedCount()
    local raw = tostring(player:GetAttribute("OwnedCosmetics") or "")
    if raw == "" then
        return 0
    end
    local count = 0
    for _ in string.gmatch(raw, "[^,]+") do
        count += 1
    end
    return count
end

local function levelBounds(level)
    local current = math.max(0, ((level - 1) * (level - 1)) * 100)
    local nextValue = math.max(current + 1, (level * level) * 100)
    return current, nextValue
end

local function refresh()
    local level = math.max(1, math.floor(tonumber(player:GetAttribute("Level")) or 1))
    local wins = math.max(0, math.floor(tonumber(player:GetAttribute("Wins")) or 0))
    local xp = math.max(0, math.floor(tonumber(player:GetAttribute("XP")) or 0))
    local owned = ownedCount()
    local total = math.max(owned, math.floor(tonumber(player:GetAttribute("CosmeticCatalogTotal")) or 0))

    local currentXP, nextXP = levelBounds(level)
    local span = math.max(1, nextXP - currentXP)
    local progress = math.clamp((xp - currentXP) / span, 0, 1)
    local remaining = math.max(0, nextXP - xp)

    stats.Text = CoreLocalization.text(
        localeId,
        "RUN_STATS",
        level,
        wins,
        owned,
        total
    )
    goal.Text = remaining > 0
        and CoreLocalization.text(localeId, "RUN_NEXT_LEVEL", level + 1, remaining)
        or CoreLocalization.text(localeId, "RUN_LEVEL_READY", level + 1)
    bar.Size = UDim2.fromScale(progress, 1)

    local complete = total > 0 and owned >= total
    if complete then
        title.Text = CoreLocalization.text(localeId, "CHAOS_RUN_COMPLETE")
        title.TextColor3 = UITheme.Colors.Gold
    else
        title.Text = CoreLocalization.text(localeId, "CHAOS_RUN")
        title.TextColor3 = UITheme.Colors.Cyan
    end
end

for _, attribute in ipairs({"Level", "Wins", "XP", "OwnedCosmetics", "CosmeticCatalogTotal"}) do
    player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

local function bindMap()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    local games = math.max(0, math.floor(tonumber(player:GetAttribute("Games")) or 0))
    anchor.Position = Config.LobbyCenter + Vector3.new(0, 8.5, -18.5)
    billboard.Enabled = lobby ~= nil and games >= 1
end

player:GetAttributeChangedSignal("Games"):Connect(function()
    refresh()
    bindMap()
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(bindMap)
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        billboard.Enabled = false
    end
end)

refresh()
bindMap()
