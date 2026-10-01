local Players = game:GetService("Players")
local MovementSafety = if script then require(script.Parent.MovementSafety) else require("./MovementSafety")

local LobbyActivities = {}

LobbyActivities.Definitions = {
    {offset = Vector3.new(-22, 1.45, 0), impulse = Vector3.new(31, 28, 0)},
    {offset = Vector3.new(22, 1.45, 0), impulse = Vector3.new(-31, 28, 0)},
    {offset = Vector3.new(0, 1.45, -22), impulse = Vector3.new(0, 28, 31)},
    {offset = Vector3.new(0, 1.45, 22), impulse = Vector3.new(0, 28, -31)},
}

function LobbyActivities.safeVelocity(currentVelocity, impulse)
    return MovementSafety.addImpulse(
        currentVelocity,
        impulse,
        48,
        -45,
        48
    )
end

local function rootAndPlayerFromHit(hit)
    local current = hit
    while current and current ~= workspace do
        if current:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(current)
            if player then
                local humanoid = current:FindFirstChildOfClass("Humanoid")
                local root = current:FindFirstChild("HumanoidRootPart")
                if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
                    return root, player
                end
                return nil, nil
            end
        end
        current = current.Parent
    end

    return nil, nil
end

local function createPad(folder, center, definition, index)
    local pad = Instance.new("Part")
    pad.Name = "PracticeBoostPad" .. tostring(index)
    pad.Size = Vector3.new(7.2, 0.30, 7.2)
    pad.Position = center + definition.offset
    pad.Anchored = true
    pad.CanCollide = false
    pad.CanTouch = true
    pad.CanQuery = false
    pad.CastShadow = false
    pad.Material = Enum.Material.Neon
    pad.Color = index % 2 == 0
        and Color3.fromRGB(160, 95, 255)
        or Color3.fromRGB(70, 215, 255)
    pad.Transparency = 0.20
    pad:SetAttribute("LobbyPracticePad", true)
    pad.Parent = folder

    local light = Instance.new("PointLight")
    light.Name = "PracticePadLight"
    light.Color = pad.Color
    light.Brightness = 0.65
    light.Range = 10
    light.Shadows = false
    light.Parent = pad

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PracticeLabel"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(120, 30)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.45, 0)
    billboard.MaxDistance = 72
    billboard.Parent = pad

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
    label.BackgroundTransparency = 0.28
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBlack
    label.Text = "PRACTICE BOOST"
    label.TextColor3 = pad.Color:Lerp(Color3.new(1, 1, 1), 0.40)
    label.TextScaled = true
    label.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = label

    return pad
end

function LobbyActivities.start(config)
    local generatedMap = workspace:FindFirstChild("GeneratedMap")
    local lobby = generatedMap and generatedMap:FindFirstChild("Lobby")
    if not lobby then
        return nil
    end

    local existing = lobby:FindFirstChild("Activities")
    if existing then
        existing:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = "Activities"
    folder.Parent = lobby

    local cooldownUntil = {}

    for index, definition in ipairs(LobbyActivities.Definitions) do
        local pad = createPad(folder, config.LobbyCenter, definition, index)

        pad.Touched:Connect(function(hit)
            local root, player = rootAndPlayerFromHit(hit)
            if not root or not player then
                return
            end

            local now = os.clock()
            if (cooldownUntil[player.UserId] or 0) > now then
                return
            end
            cooldownUntil[player.UserId] = now + 0.9

            root.AssemblyLinearVelocity = LobbyActivities.safeVelocity(
                root.AssemblyLinearVelocity,
                definition.impulse
            )
        end)
    end

    return folder
end

return LobbyActivities
