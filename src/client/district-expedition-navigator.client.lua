-- Optional district expedition navigator. Client-only: no authoritative
-- rewards, server state mutations, network traffic or new per-frame loops.
-- Shows one nearby unclaimed cache on Android/desktop, not all eight.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local caches = {}
local roundActive = false
local roundFinalRush = false
local climbedStage = {}
local claimedEasy, claimedElite, claimedSignal = false, false, false
local shardEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChaosShardCollected")
shardEvent.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then return end
    if payload.source == "DistrictSignal" then
        claimedSignal = true
        return
    end
    if payload.source ~= "DistrictCache" then return end
    if tonumber(payload.reward) == 5 then
        claimedElite = true
    elseif tonumber(payload.reward) == 2 then
        claimedEasy = true
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "DistrictExpeditionNavigator"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 12
local playerGui = player:WaitForChild("PlayerGui")
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "NearestSupplyRoute"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, UserInputService.TouchEnabled and 90 or 96)
panel.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 208 or 250, 51)
panel.BackgroundColor3 = Color3.fromRGB(13, 25, 39)
panel.BackgroundTransparency = 0.19
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
local rounded = Instance.new("UICorner")
rounded.CornerRadius = UDim.new(0, 12)
rounded.Parent = panel
local border = Instance.new("UIStroke")
border.Thickness = 1.2
border.Transparency = 0.3
border.Color = Color3.fromRGB(100, 219, 243)
border.Parent = panel

local arrow = Instance.new("TextLabel")
arrow.Name = "Direction"
arrow.Position = UDim2.fromOffset(7, 7)
arrow.Size = UDim2.fromOffset(36, 36)
arrow.BackgroundTransparency = 1
arrow.Font = Enum.Font.GothamBlack
arrow.Text = "▲"
arrow.TextScaled = true
arrow.TextColor3 = Color3.fromRGB(111, 226, 247)
arrow.Parent = panel

-- Only one next-landing marker is ever rendered. It is a local
-- BillboardGui on a REAL physical deck, not a replicated fake platform.
-- This provides an intuitive world reference for mobile jumps without
-- adding particle effects, 3D Parts or an extra animation loop.
local stepMarker = Instance.new("BillboardGui")
stepMarker.Name = "NextPhysicalDistrictStep"
stepMarker.ResetOnSpawn = false
stepMarker.Size = UDim2.fromOffset(104, 32)
stepMarker.MaxDistance = 100
-- Stay readable in dusk/dark maps but still occlude behind real walls.
stepMarker.LightInfluence = 0
stepMarker.AlwaysOnTop = false
stepMarker.Enabled = false
stepMarker.Parent = playerGui

local markerFrame = Instance.new("Frame")
markerFrame.Name = "WaypointPlate"
markerFrame.Size = UDim2.fromScale(1, 1)
markerFrame.BackgroundColor3 = Color3.fromRGB(12, 25, 40)
markerFrame.BackgroundTransparency = 0.14
markerFrame.BorderSizePixel = 0
markerFrame.Parent = stepMarker

local markerCorner = Instance.new("UICorner")
markerCorner.CornerRadius = UDim.new(0, 9)
markerCorner.Parent = markerFrame

local markerStroke = Instance.new("UIStroke")
markerStroke.Color = Color3.fromRGB(111, 226, 247)
markerStroke.Thickness = 1.3
markerStroke.Transparency = 0.14
markerStroke.Parent = markerFrame

local markerText = Instance.new("TextLabel")
markerText.Name = "ActualLanding"
markerText.BackgroundTransparency = 1
markerText.Size = UDim2.fromScale(1, 1)
markerText.Font = Enum.Font.GothamBold
markerText.TextColor3 = Color3.fromRGB(236, 248, 255)
markerText.TextSize = 12
markerText.Text = "NEXT JUMP"
markerText.Parent = markerFrame

local text = Instance.new("TextLabel")
text.Name = "ExpeditionHint"
text.Position = UDim2.fromOffset(47, 5)
text.Size = UDim2.new(1, -53, 1, -10)
text.BackgroundTransparency = 1
text.Font = Enum.Font.GothamBold
text.TextSize = UserInputService.TouchEnabled and 11 or 13
text.TextWrapped = true
text.TextYAlignment = Enum.TextYAlignment.Center
text.TextXAlignment = Enum.TextXAlignment.Left
text.TextColor3 = Color3.fromRGB(225, 247, 255)
text.Text = ""
text.Parent = panel

-- Mobile survival HUD takes priority over optional rewards. The other
-- owner is the authoritative hazard-route-readability client: do not
-- re-parent or reposition its urgent warning. Hide this *secondary*
-- compass while either high-priority warning surface is visible.
local function hazardCueVisible()
    local owner = playerGui:FindFirstChild("HazardReadabilityCue")
    if not owner or not owner:IsA("ScreenGui") or not owner.Enabled then
        return false
    end
    local near = owner:FindFirstChild("NearestHazardCue")
    local offscreen = owner:FindFirstChild("OffscreenHazardArrow")
    return (near and near:IsA("GuiObject") and near.Visible == true)
        or (offscreen and offscreen:IsA("GuiObject")
            and offscreen.Visible == true)
        or false
end

local viewportConnection
local function applyNavigatorLayout()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize
        or Vector2.new(1280, 720)
    local profile = UIResponsive.mobileProfile(viewport)
    local touch = UserInputService.TouchEnabled
    local width = touch and (profile.veryNarrow and 190 or 208) or 250
    local height = touch and (profile.tinyHeight and 46 or 51) or 51
    local x = touch and profile.topCenterXScale or 0.50
    -- The danger panel starts just below the top timer and spans
    -- 34-42px. This panel owns the next lane, not the same pixels.
    local y = profile.topHeight
        + (profile.tinyHeight and 50 or 62)
    panel.Position = UDim2.new(x, 0, 0, y)
    panel.Size = UDim2.fromOffset(
        math.min(width, math.max(168, viewport.X - 20)), height)
end

local function bindNavigatorCamera()
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end
    local camera = workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal(
            "ViewportSize"):Connect(applyNavigatorLayout)
    end
    applyNavigatorLayout()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindNavigatorCamera)
bindNavigatorCamera()

local function cacheEligible(model)
    return model:IsA("Model")
        and model:GetAttribute("DistrictSupplyCache") == true
        and model.Parent ~= nil
end

local function tierAlreadyClaimed(tier)
    if tier == "Easy" then
        return claimedEasy
            or player:GetAttribute("RoundDistrictEasyClaimed") == true
    elseif tier == "Elite" then
        return claimedElite
            or player:GetAttribute("RoundDistrictEliteClaimed") == true
    end
    return false
end

local function hideClaimedCache(model)
    if not cacheEligible(model)
        or not tierAlreadyClaimed(model:GetAttribute("CacheTier")) then
        return
    end
    -- Each model is a globally shared server chest. Mask its optional
    -- interaction *only for this player* after the server has consumed
    -- their tier entitlement; never destroy the chest for other users.
    local lid = model:FindFirstChild("CacheLid")
    if not lid then return end
    local prompt = lid:FindFirstChild("OpenDistrictCache")
    if prompt and prompt:IsA("ProximityPrompt") then
        prompt.Enabled = false
    end
    local label = lid:FindFirstChild("SupplyCacheLabel")
    if label and label:IsA("BillboardGui") then
        label.Enabled = false
    end
end

local function hideClaimedCues()
    for model in pairs(caches) do
        if cacheEligible(model) then
            hideClaimedCache(model)
        else
            caches[model] = nil
        end
    end
end

local function track(instance)
    if cacheEligible(instance) then
        caches[instance] = true
        hideClaimedCache(instance)
    end
end

workspace.DescendantAdded:Connect(track)
workspace.DescendantRemoving:Connect(function(instance)
    caches[instance] = nil
end)
for _, item in ipairs(workspace:GetDescendants()) do
    track(item)
end
player:GetAttributeChangedSignal("RoundDistrictEasyClaimed"):Connect(hideClaimedCues)
player:GetAttributeChangedSignal("RoundDistrictEliteClaimed"):Connect(hideClaimedCues)

stateEvent.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    roundFinalRush = state.finalRush == true
    local phase = tostring(state.phase or state.Phase or ""):lower()
    if phase == "round" then
        if not roundActive then
            claimedEasy, claimedElite, claimedSignal = false, false, false
            table.clear(climbedStage)
        end
        roundActive = true
    elseif phase == "intermission" or phase == "voting"
        or phase == "ready" or phase == "result"
        or phase == "postround" or phase == "waiting"
    then
        roundActive = false
        panel.Visible = false
        stepMarker.Enabled = false
    end
end)

-- A destination arrow that ignores real parkour gaps encourages players
-- to jump directly into walls. Guide through *real, currently collidable*
-- platforms in order, and gracefully fall back when streaming omits one.
local function stagesForRoute(arena, route, elite)
    local folder = arena and arena:FindFirstChild("Platforms")
    if not folder then return nil end
    local perimeter, branch = {}, {}
    for _, platform in ipairs(folder:GetChildren()) do
        if platform:IsA("BasePart") and platform.Parent
            and platform.CanCollide and platform.Transparency < 0.95 then
            if platform:GetAttribute("PerimeterRoute") == route then
                local step = tonumber(platform:GetAttribute("PerimeterStep"))
                if step and step >= 1 and step <= 8
                    and step == math.floor(step) then
                    perimeter[step] = platform
                end
            end
            if elite and platform:GetAttribute("BranchRoute") == route then
                local step = tonumber(platform:GetAttribute("BranchStep"))
                if step and step >= 1 and step <= 4
                    and step == math.floor(step) then
                    branch[step] = platform
                end
            end
        end
    end

    local stages = {}
    local lastPerimeter = elite and 5 or 4
    for step = 1, lastPerimeter do
        if not perimeter[step] then return nil end
        stages[#stages + 1] = perimeter[step]
    end
    if elite then
        for step = 1, 4 do
            if not branch[step] then return nil end
            stages[#stages + 1] = branch[step]
        end
    end
    return stages
end

local function chooseParkourWaypoint(arena, route, elite, root, destination)
    local stages = stagesForRoute(arena, route, elite)
    if not stages then return nil end

    -- A character is on a deck when close in the horizontal plane AND
    -- at the correct height. A player standing beneath an elevated final
    -- chest should still be directed to the bottom of its climb.
    local highestReached = 0
    for i, deck in ipairs(stages) do
        local dx = root.Position.X - deck.Position.X
        local dz = root.Position.Z - deck.Position.Z
        local horizontal = math.sqrt(dx * dx + dz * dz)
        local surface = deck.Position.Y + deck.Size.Y * 0.5
        if horizontal <= 7.8
            and root.Position.Y >= surface + 0.6
            and math.abs(root.Position.Y - (surface + 2.5)) <= 4.7
        then
            highestReached = i
        end
    end

    local key = tostring(route) .. (elite and ":Elite" or ":Easy")
    local previous = climbedStage[key] or 0
    -- Retain the last stable landing while jumping between decks. This
    -- prevents the arrow from snapping backwards to stage one mid-jump.
    -- If the avatar actually falls below that deck, restart the ascent.
    if previous > 0 then
        local priorDeck = stages[previous]
        local priorTop = priorDeck
            and (priorDeck.Position.Y + priorDeck.Size.Y * 0.5)
        if not priorTop or root.Position.Y < priorTop - 1.0 then
            previous = 0
        end
    end
    highestReached = math.max(previous, highestReached)
    climbedStage[key] = highestReached
    if highestReached >= #stages then
        return destination, "OPEN SUPPLY CACHE", true, nil, nil, nil
    end
    local nextStep = highestReached + 1
    local deck = stages[nextStep]
    local surface = deck.Position.Y + deck.Size.Y * 0.5
    return Vector3.new(deck.Position.X, surface + 2.5, deck.Position.Z),
        "CLIMB " .. nextStep .. "/" .. #stages, false,
        deck, nextStep, #stages
end

-- Free transit is useful for ground-level timed signals. Only recommend
-- a gate if both physical stations exist, the prompt is enabled, and
-- walking via the gate beats travelling to the real objective directly.
-- Never recommend transit for upper decks: it can deposit the player
-- beneath an unreachable elite cache without an upward access route.
local function chooseTransitWaypoint(arena, route, root, destination)
    local stations = arena and arena:FindFirstChild("DistrictTransit")
    if not stations then return nil end
    local hub = stations:FindFirstChild("Transit" .. route .. "Hub")
    local outer = stations:FindFirstChild("Transit" .. route .. "Outer")
    local prompt = hub and hub:FindFirstChild("TransitHeader")
    prompt = prompt and prompt:FindFirstChild("TravelToDistrict")
    local outerHeader = outer and outer:FindFirstChild("TransitHeader")
    if not (prompt and prompt:IsA("ProximityPrompt")
        and prompt.Enabled and outerHeader and outerHeader:IsA("BasePart"))
    then return nil end
    local header = hub:FindFirstChild("TransitHeader")
    local direct = (root.Position - destination).Magnitude
    local toHub = (root.Position - header.Position).Magnitude
    local after = (outerHeader.Position - destination).Magnitude
    if direct < 36 or toHub + after + 17 >= direct
        or toHub > 160 then
        return nil
    end
    return header.Position, "FAST TRAVEL D" .. route
end

local function currentArena()
    local generated = workspace:FindFirstChild("GeneratedMap")
    return generated and generated:FindFirstChild("Arena")
end

local function update()
    -- Caches can be parented before all child parts arrive, or the server
    -- can refresh a shared prompt as a platform changes collision. Re-mask
    -- any spent personal tier using the existing 4Hz compass heartbeat.
    hideClaimedCues()
    if hazardCueVisible() then
        panel.Visible = false
        stepMarker.Enabled = false
        return
    end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local camera = workspace.CurrentCamera
    if not roundActive or roundFinalRush
        or player:GetAttribute("RoundParticipant") ~= true
        or player:GetAttribute("RoundEliminated") == true
        or not root or not root:IsA("BasePart")
        or not humanoid or humanoid.Health <= 0 or not camera
    then
        panel.Visible = false
        stepMarker.Enabled = false
        return
    end

    local arena = currentArena()
    if not arena then
        panel.Visible = false
        stepMarker.Enabled = false
        return
    end

    local signalPosition, signalReward, signalRoute, upcoming = nil, nil, nil, false
    local signalSeconds = nil
    if not claimedSignal
        and (tonumber(player:GetAttribute("RoundDistrictSignals")) or 0) == 0
    then
        local signals = arena:FindFirstChild("DistrictSignalRush")
        local activeRoute = signals
            and tonumber(signals:GetAttribute("SignalRoute"))
        local nextRoute = signals
            and tonumber(signals:GetAttribute("UpcomingSignalRoute"))
        local route = activeRoute and activeRoute >= 1 and activeRoute <= 4
            and activeRoute or nextRoute
        if route and route >= 1 and route <= 4
            and route == math.floor(route) then
            local station = signals:FindFirstChild("SignalStation" .. route)
            if station and station:IsA("Model") then
                local active = station:GetAttribute("SignalActive") == true
                local preview = not active and activeRoute == 0
                    and nextRoute == route
                local core = station:FindFirstChild("PulseCore")
                if (active or preview) and core and core:IsA("BasePart") then
                    signalPosition = core.Position
                    signalRoute = route
                    upcoming = preview
                    signalReward = math.clamp(
                        tonumber(signals:GetAttribute("SignalReward")) or 2,
                        1, 2)
                    -- Server-provided clock timestamps drive the countdown.
                    -- Local client clocks cannot reliably estimate when
                    -- a replicated objective was scheduled or activated.
                    local timestamp = tonumber(signals:GetAttribute(
                        preview and "SignalStartsAt" or "SignalEndsAt"))
                    if timestamp and timestamp > 0 then
                        signalSeconds = math.clamp(math.ceil(
                            timestamp - workspace:GetServerTimeNow()), 0, 60)
                    end
                end
            end
        end
    end

    local nearest, targetPosition, targetDistance = nil, signalPosition, math.huge
    if signalPosition then
        targetDistance = (signalPosition - root.Position).Magnitude
    else
        for model in pairs(caches) do
            if not cacheEligible(model) then
                caches[model] = nil
            else
                local support = model.Parent
                local tier = model:GetAttribute("CacheTier")
                if (tonumber(player:GetAttribute("RoundDistrictCaches")) or 0) < 2
                    and support and support:IsA("BasePart")
                    and not tierAlreadyClaimed(tier)
                    and support.CanCollide and support.Transparency < 0.95 then
                    local lid = model:FindFirstChild("CacheLid")
                    if lid and lid:IsA("BasePart") then
                        local distance = (lid.Position - root.Position).Magnitude
                        if distance < targetDistance then
                            nearest, targetPosition, targetDistance
                                = model, lid.Position, distance
                        end
                    end
                end
            end
        end
    end

    -- StreamingEnabled may omit far-off objects; no fictitious targets.
    if not targetPosition or targetDistance > (signalPosition and 230 or 170) then
        panel.Visible = false
        stepMarker.Enabled = false
        return
    end

    local route = signalRoute
        or (nearest and tonumber(nearest:GetAttribute("DistrictRoute")))
    local elite = nearest and nearest:GetAttribute("CacheTier") == "Elite"
    local reward = signalReward or (nearest
        and tonumber(nearest:GetAttribute("CacheReward")))
        or (elite and 5 or 2)
    local waypoint, taskLabel = targetPosition, nil
    local landingDeck, landingStep, landingTotal = nil, nil, nil

    if signalPosition then
        if route and route >= 1 and route <= 4 then
            local gate, gateLabel = chooseTransitWaypoint(
                arena, route, root, targetPosition)
            if gate then
                waypoint, taskLabel = gate, gateLabel
            end
        end
        if not taskLabel then
            taskLabel = upcoming
                and ("NEXT SIGNAL D" .. tostring(route))
                or "SECURE LIVE SIGNAL"
        end
    else
        if route and route >= 1 and route <= 4
            and route == math.floor(route) then
            local stage, label, _, deck, stageIndex, stageCount =
                chooseParkourWaypoint(
                    arena, route, elite, root, targetPosition)
            if stage then
                waypoint, taskLabel = stage, label
                landingDeck, landingStep, landingTotal =
                    deck, stageIndex, stageCount
            end
        end
        if not taskLabel then
            taskLabel = elite and "FIND HIGH ROUTE" or "FIND SHORT ROUTE"
        end
    end

    local delta = waypoint - root.Position
    local horizontal = Vector3.new(delta.X, 0, delta.Z)
    local cameraForward = camera.CFrame.LookVector
    local cameraRight = camera.CFrame.RightVector
    local forward = horizontal:Dot(Vector3.new(cameraForward.X, 0, cameraForward.Z))
    local side = horizontal:Dot(Vector3.new(cameraRight.X, 0, cameraRight.Z))
    if horizontal.Magnitude > 0.2 then
        arrow.Rotation = math.deg(math.atan2(side, forward))
    end
    local waypointDistance = math.floor(delta.Magnitude + 0.5)
    local cue
    if signalPosition then
        local remaining = signalSeconds and (tostring(signalSeconds) .. "s")
            or (upcoming and "SOON" or "NOW")
        cue = (upcoming and "OPENS " or "ENDS ")
            .. remaining .. " • +" .. reward
    else
        cue = "CACHE +" .. reward .. " COINS"
    end
    -- Distance is explicitly TO THE NEXT WAYPOINT, not falsely to the
    -- final chest when several physical jump gaps remain.
    text.Text = taskLabel .. "\n" .. cue
        .. " • " .. tostring(waypointDistance) .. "st"
    local color = signalPosition and Color3.fromRGB(255, 163, 83)
        or (elite and Color3.fromRGB(248, 199, 91)
            or Color3.fromRGB(111, 226, 247))
    arrow.TextColor3 = color
    border.Color = color
    panel.Visible = true

    -- The server chest already owns the final platform's BillboardGui.
    -- Show our one intermediate jump marker only while it is nearby,
    -- visible, and the authoritative survival warning has no priority.
    if landingDeck and landingDeck.Parent
        and landingStep and landingTotal
        and landingStep < landingTotal
        and landingDeck.CanCollide
        and landingDeck.Transparency < 0.95
        and (landingDeck.Position - root.Position).Magnitude <= 100
    then
        if stepMarker.Adornee ~= landingDeck then
            stepMarker.Adornee = landingDeck
        end
        stepMarker.StudsOffsetWorldSpace =
            Vector3.new(0, landingDeck.Size.Y * 0.5 + 5.0, 0)
        local caption = "JUMP " .. landingStep .. "/" .. landingTotal
        if markerText.Text ~= caption then
            markerText.Text = caption
        end
        if markerStroke.Color ~= color then
            markerStroke.Color = color
        end
        stepMarker.Enabled = true
    else
        stepMarker.Enabled = false
    end
end

task.spawn(function()
    while gui.Parent do
        update()
        task.wait(0.25)
    end
end)
