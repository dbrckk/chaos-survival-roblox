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
panel.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 198 or 232, 43)
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
arrow.Position = UDim2.fromOffset(8, 4)
arrow.Size = UDim2.fromOffset(36, 34)
arrow.BackgroundTransparency = 1
arrow.Font = Enum.Font.GothamBlack
arrow.Text = "▲"
arrow.TextScaled = true
arrow.TextColor3 = Color3.fromRGB(111, 226, 247)
arrow.Parent = panel

local text = Instance.new("TextLabel")
text.Name = "ExpeditionHint"
text.Position = UDim2.fromOffset(47, 5)
text.Size = UDim2.new(1, -54, 1, -10)
text.BackgroundTransparency = 1
text.Font = Enum.Font.GothamBold
text.TextSize = UserInputService.TouchEnabled and 12 or 14
text.TextWrapped = true
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

    -- A rotating live signal is the urgent target for up to 12 seconds.
    -- It is server-selected and streamed like any other world Model;
    -- never draw an arrow to a missing or fabricated signal location.
    local signalPosition, signalReward = nil, nil
    if not claimedSignal
        and (tonumber(player:GetAttribute("RoundDistrictSignals")) or 0) == 0
    then
        local map = workspace:FindFirstChild("GeneratedMap")
        local arena = map and map:FindFirstChild("Arena")
        local signals = arena and arena:FindFirstChild("DistrictSignalRush")
        local route = signals and tonumber(signals:GetAttribute("SignalRoute"))
        if route and route >= 1 and route <= 4
            and route == math.floor(route) then
            local station = signals:FindFirstChild("SignalStation" .. route)
            if station and station:IsA("Model")
                and station:GetAttribute("SignalActive") == true then
                local core = station:FindFirstChild("PulseCore")
                if core and core:IsA("BasePart") then
                    signalPosition = core.Position
                    signalReward = math.clamp(
                        tonumber(signals:GetAttribute("SignalReward")) or 2, 1, 2)
                end
            end
        end
    end

    local nearest, nearestPosition, nearestDistance = nil, nil, math.huge
    if signalPosition then
        nearestPosition = signalPosition
        nearestDistance = (signalPosition - root.Position).Magnitude
    end
    for model in pairs(caches) do
        if not cacheEligible(model) then
            caches[model] = nil
        else
            local support = model.Parent
            local tier = model:GetAttribute("CacheTier")
            if not signalPosition
                and (tonumber(player:GetAttribute("RoundDistrictCaches")) or 0) < 2
                and support and support:IsA("BasePart")
                and not (tier == "Easy" and claimedEasy)
                and not (tier == "Elite" and claimedElite)
                and support.CanCollide and support.Transparency < 0.95 then
                local lid = model:FindFirstChild("CacheLid")
                if lid and lid:IsA("BasePart") then
                    local dist = (lid.Position - root.Position).Magnitude
                    if dist < nearestDistance then
                        nearest, nearestPosition, nearestDistance = model, lid.Position, dist
                    end
                end
            end
        end
    end
    -- Keep the navigation secondary to survival and hazard telegraphs.
    -- StreamingEnabled may omit distant caches; never fake a target.
    if not nearestPosition or nearestDistance > (signalPosition and 220 or 165) then
        panel.Visible = false
        return
    end

    local delta = nearestPosition - root.Position
    local horizontal = Vector3.new(delta.X, 0, delta.Z)
    local cameraForward = camera.CFrame.LookVector
    local cameraRight = camera.CFrame.RightVector
    local forward = horizontal:Dot(Vector3.new(cameraForward.X, 0, cameraForward.Z))
    local side = horizontal:Dot(Vector3.new(cameraRight.X, 0, cameraRight.Z))
    local heading = math.atan2(side, forward)
    arrow.Rotation = math.deg(heading)
    local elite = not signalPosition
        and nearest:GetAttribute("CacheTier") == "Elite"
    local reward = signalReward or (tonumber(nearest:GetAttribute("CacheReward"))
        or (elite and 5 or 2))
    if signalPosition then
        text.Text = "LIVE SIGNAL  +" .. tostring(reward) .. " COINS\n"
            .. tostring(math.floor(nearestDistance + 0.5))
            .. " STUDS  •  LIMITED TIME"
    else
        local label = elite and "HIGH ROUTE" or "SHORT ROUTE"
        text.Text = label .. "  +" .. tostring(reward) .. " COINS\n"
            .. tostring(math.floor(nearestDistance + 0.5))
            .. " STUDS  •  OPTIONAL"
    end
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
