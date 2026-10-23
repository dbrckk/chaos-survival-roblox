-- Contextual lava high-ground guidance, built only from the server's
-- actual tier-four collision decks. No fake walkways, new physics or remotes.
-- Four billboards maximum (one in Orbital); no RenderStepped/polling.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")

local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)
local PlatformFinishKit = require(script.Parent.PlatformFinishKit)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local guiFolder = Instance.new("Folder")
guiFolder.Name = "LavaHighGroundSignsLocal"
guiFolder.Parent = playerGui

local worldFolder = Instance.new("Folder")
worldFolder.Name = "LavaHighGroundOutlinesLocal"
worldFolder.Parent = workspace

local activeMap = nil
local activePlatforms = nil
local disconnectMap = nil
local disconnectPlatforms = nil
local signs = {}
local currentState = nil
local rebuildQueued = false

local function lavaIsActive(state)
    if type(state) ~= "table"
        or (state.phase ~= "ready" and state.phase ~= "round")
        or type(state.disasterIds) ~= "table" then
        return false
    end
    return table.find(state.disasterIds, "RisingLava") ~= nil
end

local function clear()
    table.clear(signs)
    guiFolder:ClearAllChildren()
    worldFolder:ClearAllChildren()
end

local function visualQuality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
end

local function isCurrentArena(state)
    if not activeMap or not activeMap.Parent then return false end
    local arena = activeMap:FindFirstChild("Arena")
    if not arena then return false end
    -- READY/RESULT packets include arenaId. Refuse to show previous-map
    -- markers while a new arena streams in after an intermission.
    return state.arenaId == nil
        or state.arenaId == arena:GetAttribute("VariantId")
end

local function refresh()
    local active = lavaIsActive(currentState)
        and isCurrentArena(currentState)
    local quality = visualQuality()
    for _, sign in ipairs(signs) do
        local platform = sign.platform
        -- Dual-hazard rounds may collapse the same high deck. Never
        -- advertise an absent or temporarily non-solid "safe" platform.
        local visible = active
            and platform.Parent == activePlatforms
            and platform.CanCollide
            and platform:GetAttribute("CollapsePhase") == nil
        sign.billboard.Enabled = visible
        sign.outline.Enabled = visible and quality ~= "Low"
    end
end

local function createSign(platform, accent)
    local gui = Instance.new("BillboardGui")
    gui.Name = "HighGroundRouteSign"
    gui.Adornee = platform
    gui.AlwaysOnTop = false
    gui.LightInfluence = 0
    gui.MaxDistance = 76
    gui.Size = UDim2.fromOffset(132, 38)
    gui.StudsOffsetWorldSpace = Vector3.new(
        0, platform.Size.Y * 0.5 + 3.3, 0
    )
    gui.Enabled = false
    gui.ResetOnSpawn = false
    gui.Parent = guiFolder

    local panel = Instance.new("Frame")
    panel.Name = "RouteLabel"
    panel.Size = UDim2.fromScale(1, 1)
    panel.BackgroundColor3 = Color3.fromRGB(15, 31, 42)
    panel.BackgroundTransparency = 0.12
    panel.BorderSizePixel = 0
    panel.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = panel

    local border = Instance.new("UIStroke")
    border.Color = accent
    border.Thickness = 1.5
    border.Transparency = 0.20
    border.Parent = panel

    local stripe = Instance.new("Frame")
    stripe.Name = "SignalRail"
    stripe.Size = UDim2.new(0, 4, 0.62, 0)
    stripe.Position = UDim2.fromScale(0.07, 0.19)
    stripe.BackgroundColor3 = accent
    stripe.BorderSizePixel = 0
    stripe.Parent = panel

    local label = Instance.new("TextLabel")
    label.Name = "HighGroundText"
    label.BackgroundTransparency = 1
    label.Position = UDim2.fromScale(0.17, 0.06)
    label.Size = UDim2.fromScale(0.77, 0.88)
    label.Font = Enum.Font.GothamBold
    label.Text = CoreLocalization.text(
        LocalizationService.RobloxLocaleId, "LAVA_HIGH_GROUND"
    )
    label.TextColor3 = Color3.fromRGB(232, 250, 255)
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = panel

    local textLimit = Instance.new("UITextSizeConstraint")
    textLimit.MinTextSize = 10
    textLimit.MaxTextSize = 16
    textLimit.Parent = label

    -- Outline is client-only and occluded: it does not reveal decks
    -- behind solid obstacles or create a misleading safe floor.
    local outline = Instance.new("Highlight")
    outline.Name = "HighGroundRouteOutline"
    outline.Adornee = platform
    outline.FillColor = accent
    outline.FillTransparency = 0.94
    outline.OutlineColor = accent
    outline.OutlineTransparency = 0.36
    outline.DepthMode = Enum.HighlightDepthMode.Occluded
    outline.Enabled = false
    outline.Parent = worldFolder

    signs[#signs + 1] = {
        platform = platform,
        billboard = gui,
        outline = outline,
    }
end

local function rebuild()
    clear()
    local arena = activeMap and activeMap:FindFirstChild("Arena")
    local platforms = arena and arena:FindFirstChild("Platforms")
    if not platforms or platforms ~= activePlatforms then return end

    local accent = VisualTheme.arena(
        tostring(arena:GetAttribute("VariantId") or "Classic")
    ).Accent
    local count = 0
    for _, platform in ipairs(PlatformFinishKit.orderedPlatforms(platforms)) do
        if tonumber(platform:GetAttribute("RouteTier")) == 4
            and platform.Name:match("^Platform%d+$") then
            createSign(platform, accent)
            count += 1
            if count >= 4 then break end
        end
    end
    refresh()
end

local function scheduleRebuild()
    if rebuildQueued then return end
    rebuildQueued = true
    task.defer(function()
        rebuildQueued = false
        rebuild()
    end)
end

local function bindPlatforms()
    local arena = activeMap and activeMap:FindFirstChild("Arena")
    local platforms = arena and arena:FindFirstChild("Platforms")
    if platforms == activePlatforms then return end
    if disconnectPlatforms then
        disconnectPlatforms()
        disconnectPlatforms = nil
    end
    activePlatforms = platforms
    if platforms then
        disconnectPlatforms = MapVisualReadiness.watchChildrenAttributes(
            platforms, {"RouteTier", "CollapsePhase"},
            scheduleRebuild
        )
    end
    scheduleRebuild()
end

local function bindMap(map)
    if disconnectMap then
        disconnectMap()
        disconnectMap = nil
    end
    if disconnectPlatforms then
        disconnectPlatforms()
        disconnectPlatforms = nil
    end
    activePlatforms = nil
    activeMap = map
    clear()
    if map then
        -- The Platforms container is a Folder, so use the section watcher
        -- for arrival/removal and reselect its current folder explicitly.
        disconnectMap = MapVisualReadiness.watch(
            map, "Arena", "Platforms", bindPlatforms
        )
    end
    bindPlatforms()
end

stateEvent.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    currentState = state
    refresh()
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap"
        and workspace:FindFirstChild("GeneratedMap") == child then
        bindMap(child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child == activeMap then
        bindMap(workspace:FindFirstChild("GeneratedMap"))
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(refresh)
bindMap(workspace:FindFirstChild("GeneratedMap"))
