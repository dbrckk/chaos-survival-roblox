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
    if phase == "round" or phase == "playing" or phase == "active" then
        roundActive = true
    elseif phase == "intermission" or phase == "voting"
        or phase == "ready" or phase == "results"
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
        or (tonumber(player:GetAttribute("RoundDistrictCaches")) or 0) >= 2
        or not root or not root:IsA("BasePart")
        or not humanoid or humanoid.Health <= 0 or not camera
    then
        panel.Visible = false
        return
    end

    local nearest, nearestPosition, nearestDistance = nil, nil, math.huge
    for model in pairs(caches) do
        if not cacheEligible(model) then
            caches[model] = nil
        else
            local support = model.Parent
            if support and support:IsA("BasePart")
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
    if not nearest or nearestDistance > 165 then
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
    local elite = nearest:GetAttribute("CacheTier") == "Elite"
    local reward = tonumber(nearest:GetAttribute("CacheReward")) or (elite and 5 or 2)
    local label = elite and "HIGH ROUTE" or "SHORT ROUTE"
    text.Text = label .. "  +" .. tostring(reward) .. " COINS\n"
        .. tostring(math.floor(nearestDistance + 0.5)) .. " STUDS  •  OPTIONAL"
    local color = elite and Color3.fromRGB(248, 199, 91)
        or Color3.fromRGB(111, 226, 247)
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
