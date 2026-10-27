-- Optional district expedition navigator. Client-only: no authoritative
-- rewards, server state mutations, network traffic or new per-frame loops.
-- Shows one nearby unclaimed cache on Android/desktop, not all eight.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local caches = {}
local roundActive = false
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
gui.Parent = player:WaitForChild("PlayerGui")

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

local function cacheEligible(model)
    return model:IsA("Model")
        and model:GetAttribute("DistrictSupplyCache") == true
        and model.Parent ~= nil
end

local function track(instance)
    if cacheEligible(instance) then
        caches[instance] = true
    end
end

workspace.DescendantAdded:Connect(track)
workspace.DescendantRemoving:Connect(function(instance)
    caches[instance] = nil
end)
for _, item in ipairs(workspace:GetDescendants()) do
    track(item)
end

stateEvent.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    local phase = tostring(state.phase or state.Phase or ""):lower()
    if phase == "round" then
        if not roundActive then
            claimedEasy, claimedElite, claimedSignal = false, false, false
        end
        roundActive = true
    elseif phase == "intermission" or phase == "voting"
        or phase == "ready" or phase == "result"
        or phase == "postround" or phase == "waiting"
    then
        roundActive = false
        panel.Visible = false
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

    if highestReached >= #stages then
        return destination, "OPEN SUPPLY CACHE", true
    end
    local nextStep = highestReached + 1
    local deck = stages[nextStep]
    local surface = deck.Position.Y + deck.Size.Y * 0.5
    return Vector3.new(deck.Position.X, surface + 2.5, deck.Position.Z),
        "CLIMB " .. nextStep .. "/" .. #stages, false
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
    return header.Position, "FAST TRAVEL • DISTRICT " .. route
end

local function currentArena()
    local generated = workspace:FindFirstChild("GeneratedMap")
    return generated and generated:FindFirstChild("Arena")
end

local function update()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local camera = workspace.CurrentCamera
    if not roundActive or player:GetAttribute("RoundParticipant") ~= true
        or player:GetAttribute("RoundEliminated") == true
        or not root or not root:IsA("BasePart")
        or not humanoid or humanoid.Health <= 0 or not camera
    then
        panel.Visible = false
        return
    end

    local arena = currentArena()
    if not arena then
        panel.Visible = false
        return
    end

    local signalPosition, signalReward, signalRoute, upcoming = nil, nil, nil, false
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
                    and not (tier == "Easy" and claimedEasy)
                    and not (tier == "Elite" and claimedElite)
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
        return
    end

    local route = signalRoute
        or (nearest and tonumber(nearest:GetAttribute("DistrictRoute")))
    local elite = nearest and nearest:GetAttribute("CacheTier") == "Elite"
    local reward = signalReward or (nearest
        and tonumber(nearest:GetAttribute("CacheReward")))
        or (elite and 5 or 2)
    local waypoint, taskLabel = targetPosition, nil

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
                and ("NEXT SIGNAL • DISTRICT " .. tostring(route))
                or "SECURE LIVE SIGNAL"
        end
    else
        if route and route >= 1 and route <= 4
            and route == math.floor(route) then
            local stage, label = chooseParkourWaypoint(
                arena, route, elite, root, targetPosition)
            if stage then
                waypoint, taskLabel = stage, label
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
    local cue = signalPosition
        and (upcoming and "SIGNAL SOON • +" .. reward
            or "LIVE NOW • +" .. reward)
        or ("CACHE +" .. reward .. " COINS")
    -- Distance is explicitly TO THE NEXT WAYPOINT, not falsely to the
    -- final chest when several physical jump gaps remain.
    text.Text = taskLabel .. "\n" .. cue
        .. " • " .. tostring(waypointDistance) .. " STUDS"
    local color = signalPosition and Color3.fromRGB(255, 163, 83)
        or (elite and Color3.fromRGB(248, 199, 91)
            or Color3.fromRGB(111, 226, 247))
    arrow.TextColor3 = color
    border.Color = color
    panel.Visible = true
end

task.spawn(function()
    while gui.Parent do
        update()
        task.wait(0.25)
    end
end)
