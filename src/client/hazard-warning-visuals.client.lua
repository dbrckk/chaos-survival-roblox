local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local HazardGlyphs = require(ReplicatedStorage.Shared.HazardGlyphs)

local player = Players.LocalPlayer
local tracked = {}
local localDecor = Instance.new("Folder")
localDecor.Name = "ChaosHazardWarningDecorLocal"
localDecor.Parent = workspace
local currentTier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
local loopStarted = false
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
    if loopStarted then
        return
    end
    loopStarted = true

    task.spawn(function()
        while true do
            if next(tracked) == nil then
                task.wait(0.18)
                continue
            end

            currentTier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
            task.wait(math.max(1 / 30, currentTier.UpdateInterval))

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

                local alpha = math.clamp(
                    (workspace:GetServerTimeNow() - state.startedAt) / state.duration,
                    0,
                    1
                )
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
                    local diameter = state.startSize
                        + ((state.endSize - state.startSize) * alpha)
                    part.Size = Vector3.new(part.Size.X, diameter, diameter)
                    part.Transparency = 0.30 + (0.58 * alpha)

                    if state.ring and state.ring.Parent then
                        local trailingDiameter = math.max(state.startSize, diameter * 0.82)
                        state.ring.Size = Vector3.new(
                            0.08,
                            trailingDiameter,
                            trailingDiameter
                        )
                        state.ring.CFrame = CFrame.new(
                            part.Position + Vector3.new(0, 0.08, 0)
                        ) * CFrame.Angles(0, 0, math.rad(90))
                        state.ring.Transparency = 0.38 + (0.54 * alpha)
                    end
                else
                    local diameter = state.startSize
                        + ((state.endSize - state.startSize) * alpha)
                    part.Size = Vector3.new(diameter, part.Size.Y, diameter)
                    part.Transparency = 0.12 + (pulse * 0.24)

                    if state.ring and state.ring.Parent then
                        local ringScale = reduced and 1.12 or (1.10 + pulse * 0.12)
                        state.ring.Size = Vector3.new(
                            0.10,
                            diameter * ringScale,
                            diameter * ringScale
                        )
                        state.ring.CFrame = CFrame.new(
                            part.Position + Vector3.new(0, 0.06, 0)
                        ) * CFrame.Angles(0, 0, math.rad(90))
                        state.ring.Transparency = 0.42
                            + (0.28 * alpha)
                            + (pulse * 0.08)
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
                        text.TextTransparency = math.clamp(
                            0.02 + alpha * 0.22,
                            0,
                            1
                        )
                        text.TextStrokeTransparency = math.clamp(
                            0.42 + alpha * 0.30,
                            0,
                            1
                        )
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
        end
    end)
end

local WARNING_GLYPH_IDS = {
    Meteor = "Meteors",
    Bomb = "Bombs",
    Freeze = "Freeze",
    JumpShock = "JumpShock",
}

local function addWarningGlyph(parent, kind, color)
    local hazardId = WARNING_GLYPH_IDS[kind]
    local recipe = hazardId and HazardGlyphs.get(hazardId) or nil
    if not recipe then
        return
    end

    local glyph = Instance.new("Frame")
    glyph.Name = "WarningGlyph"
    glyph.AnchorPoint = Vector2.new(0, 0.5)
    glyph.Position = UDim2.fromScale(0.035, 0.5)
    glyph.Size = UDim2.fromScale(0.22, 0.72)
    glyph.BackgroundColor3 = color:Lerp(Color3.fromRGB(12, 16, 24), 0.70)
    glyph.BackgroundTransparency = 0.12
    glyph.BorderSizePixel = 0
    glyph.ZIndex = 2
    glyph.Parent = parent

    local glyphCorner = Instance.new("UICorner")
    glyphCorner.CornerRadius = UDim.new(0, 7)
    glyphCorner.Parent = glyph

    local canvas = Instance.new("Frame")
    canvas.AnchorPoint = Vector2.new(0.5, 0.5)
    canvas.Position = UDim2.fromScale(0.5, 0.5)
    canvas.Size = UDim2.fromScale(0.72, 0.72)
    canvas.BackgroundTransparency = 1
    canvas.ZIndex = 2
    canvas.Parent = glyph

    for _, def in ipairs(recipe) do
        local segment = Instance.new("Frame")
        segment.AnchorPoint = Vector2.new(0.5, 0.5)
        segment.Position = UDim2.fromScale(def.X, def.Y)
        segment.Size = UDim2.fromScale(def.Width, def.Height)
        segment.Rotation = def.Rotation or 0
        segment.BackgroundColor3 = color
        segment.BackgroundTransparency = 0.04
        segment.BorderSizePixel = 0
        segment.ZIndex = 2
        segment.Parent = canvas

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = segment
    end
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
                and Color3.fromRGB(70, 230, 255)
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
    label.Size = UDim2.fromOffset(154, 36)
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
    warningText.ZIndex = 1
    warningText.Parent = label

    local textPadding = Instance.new("UIPadding")
    textPadding.PaddingLeft = UDim.new(0, 38)
    textPadding.PaddingRight = UDim.new(0, 7)
    textPadding.Parent = warningText

    addWarningGlyph(warningText, kind, warningText.TextColor3)

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
