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

UITheme.Corners = {
    Small = UDim.new(0, 10),
    Medium = UDim.new(0, 14),
    Large = UDim.new(0, 18),
    Pill = UDim.new(1, 0),
}

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

return UITheme
