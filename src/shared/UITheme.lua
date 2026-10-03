local TweenService = game:GetService("TweenService")

local UITheme = {}

UITheme.Colors = {
    Panel = Color3.fromRGB(13, 18, 28),
    PanelRaised = Color3.fromRGB(22, 29, 42),
    PanelSoft = Color3.fromRGB(32, 40, 56),
    Border = Color3.fromRGB(82, 105, 145),
    Text = Color3.fromRGB(244, 248, 255),
    Muted = Color3.fromRGB(180, 194, 216),
    Cyan = Color3.fromRGB(72, 205, 255),
    Blue = Color3.fromRGB(82, 145, 255),
    Violet = Color3.fromRGB(168, 98, 255),
    Magenta = Color3.fromRGB(245, 88, 205),
    Orange = Color3.fromRGB(255, 126, 60),
    Red = Color3.fromRGB(242, 72, 72),
    Gold = Color3.fromRGB(255, 216, 95),
    Green = Color3.fromRGB(95, 225, 155),
}

UITheme.DisasterAccents = {
    RisingLava = Color3.fromRGB(255, 105, 38),
    Meteors = Color3.fromRGB(255, 155, 58),
    LowGravity = Color3.fromRGB(118, 145, 255),
    DisappearingPlatforms = Color3.fromRGB(255, 208, 72),
    Tornado = Color3.fromRGB(72, 215, 225),
    Freeze = Color3.fromRGB(92, 195, 255),
    Bombs = Color3.fromRGB(255, 72, 78),
    SpeedSurge = Color3.fromRGB(245, 82, 205),
    Darkness = Color3.fromRGB(108, 96, 205),
    ShrinkingArena = Color3.fromRGB(190, 82, 245),
    JumpShock = Color3.fromRGB(82, 155, 255),
}

UITheme.Corners = {
    Small = UDim.new(0, 10),
    Medium = UDim.new(0, 14),
    Large = UDim.new(0, 18),
    Pill = UDim.new(1, 0),
}

UITheme.Motion = {
    PressIn = TweenInfo.new(0.075, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    PressOut = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    PanelIn = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    EmphasisIn = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    FastFade = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    StandardFade = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

function UITheme.disasterAccent(id, fallback)
    return UITheme.DisasterAccents[id] or fallback or UITheme.Colors.Cyan
end

function UITheme.addStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or UITheme.Colors.Border
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.35
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

function UITheme.addGradient(parent, first, second, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(first, second)
    gradient.Rotation = rotation or 0
    gradient.Parent = parent
    return gradient
end

function UITheme.addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or UITheme.Corners.Medium
    corner.Parent = parent
    return corner
end

function UITheme.addTextConstraint(parent, minSize, maxSize)
    local constraint = Instance.new("UITextSizeConstraint")
    constraint.MinTextSize = math.max(10, math.floor(tonumber(minSize) or 12))
    constraint.MaxTextSize = math.max(
        constraint.MinTextSize,
        math.floor(tonumber(maxSize) or 32)
    )
    constraint.Parent = parent
    return constraint
end

function UITheme.addPressFeedback(button, pressedScale)
    local scale = button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = button

    local target = math.clamp(tonumber(pressedScale) or 0.96, 0.88, 1)
    local activeTween = nil

    local function tweenTo(value, info)
        if activeTween then
            activeTween:Cancel()
        end
        activeTween = TweenService:Create(scale, info, {Scale = value})
        activeTween:Play()
    end

    button.MouseButton1Down:Connect(function()
        tweenTo(target, UITheme.Motion.PressIn)
    end)
    button.MouseButton1Up:Connect(function()
        tweenTo(1, UITheme.Motion.PressOut)
    end)
    button.MouseLeave:Connect(function()
        tweenTo(1, UITheme.Motion.PressOut)
    end)

    return scale
end

return UITheme
