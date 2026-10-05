local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local tracked = {}
local localDecor = Instance.new("Folder")
localDecor.Name = "ChaosHazardWarningDecorLocal"
localDecor.Parent = workspace
local currentTier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
local renderConnection = nil
local warningNames = {
    BombWarning = true,
    MeteorWarning = true,
    FreezeWarning = true,
    JumpShockWarning = true,
}

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    currentTier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end)

local function ensureRenderLoop()
    if renderConnection or next(tracked) == nil then
        return
    end

    renderConnection = RunService.RenderStepped:Connect(function(dt)
        for part, state in pairs(tracked) do
            if not part.Parent then
                if state.ring and state.ring.Parent then
                    state.ring:Destroy()
                end
                if state.label and state.label.Parent then
                    state.label:Destroy()
                end
                tracked[part] = nil
                continue
            end

            state.clock += dt
            if state.clock < currentTier.UpdateInterval then
                continue
            end
            state.clock = 0

            local alpha = math.clamp((workspace:GetServerTimeNow() - state.startedAt) / state.duration, 0, 1)
            local reduced = player:GetAttribute("ReduceMotion") == true
            local pulse = reduced
                and 0.5
                or ((math.sin(alpha * math.pi * 6) + 1) * 0.5)

            if state.kind == "Freeze" then
                local freezePeak = 0.18 * currentTier.Scale
                part.Transparency = math.clamp(
                    0.84 - (freezePeak * math.sin(alpha * math.pi)),
                    0.60,
                    0.92
                )
            elseif state.kind == "JumpShock" then
                local diameter = state.startSize + ((state.endSize - state.startSize) * alpha)
                part.Size = Vector3.new(part.Size.X, diameter, diameter)
                part.Transparency = 0.30 + (0.58 * alpha)

                if state.ring and state.ring.Parent then
                    local trailingDiameter = math.max(state.startSize, diameter * 0.82)
                    state.ring.Size = Vector3.new(0.08, trailingDiameter, trailingDiameter)
                    state.ring.CFrame = CFrame.new(part.Position + Vector3.new(0, 0.08, 0))
                        * CFrame.Angles(0, 0, math.rad(90))
                    state.ring.Transparency = 0.38 + (0.54 * alpha)
                end
            else
                local diameter = state.startSize + ((state.endSize - state.startSize) * alpha)
                part.Size = Vector3.new(diameter, part.Size.Y, diameter)
                part.Transparency = 0.12 + (pulse * 0.24)

                if state.ring and state.ring.Parent then
                    local ringScale = reduced and 1.12 or (1.10 + (pulse * 0.12))
                    state.ring.Size = Vector3.new(0.10, diameter * ringScale, diameter * ringScale)
                    state.ring.CFrame = CFrame.new(part.Position + Vector3.new(0, 0.06, 0))
                        * CFrame.Angles(0, 0, math.rad(90))
                    state.ring.Transparency = 0.42 + (0.28 * alpha) + (pulse * 0.08)
                end
            end

            if state.label and state.label.Parent then
                state.label.StudsOffsetWorldSpace = Vector3.new(
                    0,
                    reduced and 2.66 or (2.6 + pulse * 0.18),
                    0
                )
                local text = state.label:FindFirstChild("WarningText")
                if text and text:IsA("TextLabel") then
                    text.TextTransparency = math.clamp(0.02 + alpha * 0.22, 0, 1)
                    text.TextStrokeTransparency = math.clamp(0.42 + alpha * 0.30, 0, 1)
                end
            end

            if alpha >= 1 then
                if state.ring and state.ring.Parent then
                    state.ring:Destroy()
                end
                if state.label and state.label.Parent then
                    state.label:Destroy()
                end
                tracked[part] = nil
            end
        end

        if next(tracked) == nil and renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
    end)
end

local function register(part)
    if not part:IsA("BasePart") then
        return
    end

    local kind = part:GetAttribute("WarningKind")
    if type(kind) ~= "string" or kind == "" then
        return
    end

    local ring = nil
    if kind == "Meteor" or kind == "Bomb" or kind == "JumpShock" then
        ring = Instance.new("Part")
        ring.Name = kind .. "WarningRingLocal"
        ring.Shape = Enum.PartType.Cylinder
        ring.Anchored = true
        ring.CanCollide = false
        ring.CanTouch = false
        ring.CanQuery = false
        ring.CastShadow = false
        ring.Material = Enum.Material.Neon
        ring.Color = kind == "Meteor"
            and Color3.fromRGB(255, 190, 78)
            or (kind == "JumpShock"
                and Color3.fromRGB(115, 190, 255)
                or Color3.fromRGB(255, 72, 72))
        ring.Transparency = 0.48
        ring.Size = Vector3.new(0.10, part.Size.X * 1.12, part.Size.Z * 1.12)
        ring.CFrame = CFrame.new(part.Position + Vector3.new(0, 0.06, 0))
            * CFrame.Angles(0, 0, math.rad(90))
        ring.Parent = localDecor
    end


    local label = Instance.new("BillboardGui")
    label.Name = kind .. "WarningLabelLocal"
    label.Adornee = part
    label.Size = UDim2.fromOffset(132, 34)
    label.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
    label.AlwaysOnTop = true
    label.LightInfluence = 0
    label.MaxDistance = currentTier.Name == "Low" and 90 or 130
    label.Parent = localDecor

    local warningText = Instance.new("TextLabel")
    warningText.Name = "WarningText"
    warningText.Size = UDim2.fromScale(1, 1)
    warningText.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
    warningText.BackgroundTransparency = 0.18
    warningText.BorderSizePixel = 0
    warningText.Font = Enum.Font.GothamBlack
    warningText.Text = kind == "JumpShock"
        and "JUMP"
        or string.upper(kind)
    warningText.TextColor3 = kind == "Bomb"
        and Color3.fromRGB(255, 120, 120)
        or (kind == "Meteor"
            and Color3.fromRGB(255, 205, 115)
            or Color3.fromRGB(170, 225, 255))
    warningText.TextScaled = true
    warningText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    warningText.TextStrokeTransparency = 0.42
    warningText.Parent = label

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = warningText

    local stroke = Instance.new("UIStroke")
    stroke.Color = warningText.TextColor3
    stroke.Thickness = 1
    stroke.Transparency = 0.35
    stroke.Parent = warningText

    tracked[part] = {
        startedAt = tonumber(part:GetAttribute("WarningStartedAt")) or workspace:GetServerTimeNow(),
        kind = kind,
        duration = math.max(0.05, tonumber(part:GetAttribute("WarningDuration")) or 0.05),
        startSize = math.max(0.1, tonumber(part:GetAttribute("WarningStartSize")) or part.Size.X),
        endSize = math.max(0.1, tonumber(part:GetAttribute("WarningEndSize")) or part.Size.X),
        clock = 0,
        ring = ring,
        label = label,
    }

    ensureRenderLoop()
end

local function maybeRegister(part)
    if not part:IsA("BasePart") then
        return
    end

    if part:GetAttribute("WarningKind") then
        register(part)
        return
    end

    if not warningNames[part.Name] then
        return
    end

    local connection
    connection = part:GetAttributeChangedSignal("WarningKind"):Connect(function()
        if part:GetAttribute("WarningKind") then
            if connection then
                connection:Disconnect()
            end
            register(part)
        end
    end)

    task.delay(1, function()
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end)
end

for _, child in ipairs(workspace:GetChildren()) do
    maybeRegister(child)
end

workspace.ChildAdded:Connect(maybeRegister)
workspace.ChildRemoved:Connect(function(child)
    local state = tracked[child]
    if state and state.ring and state.ring.Parent then
        state.ring:Destroy()
    end
    if state and state.label and state.label.Parent then
        state.label:Destroy()
    end
    tracked[child] = nil
end)
