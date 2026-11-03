local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local UITheme = {}

UITheme.Colors = {
    Panel = Color3.fromRGB(19, 27, 39),
    PanelRaised = Color3.fromRGB(30, 41, 57),
    PanelSoft = Color3.fromRGB(45, 60, 78),
    Border = Color3.fromRGB(94, 122, 157),
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
    JumpShock = Color3.fromRGB(55, 225, 255),
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

-- Original scalable 2D industrial frame language. Unlike a generic UICorner
-- or rectangular ImageLabel this is a deterministic, crisp machined drawing:
-- engraved corner registers, rivets and brushed inlaid rails. Pure UI geometry
-- makes it independent of external texture IDs or image-loading latency.
-- Use only on the four large HUD / READY / results / boot surfaces.
function UITheme.addMachinedFrame(parent, accent, isCompact)
    if not parent or not parent:IsA("GuiObject") then return nil end
    local existing = parent:FindFirstChild("ChaosMachinedFrame")
    if existing then return existing end

    local color = accent or UITheme.Colors.Cyan
    local zIndex = parent.ZIndex
    local art = Instance.new("Frame")
    art.Name = "ChaosMachinedFrame"
    art.Size = UDim2.fromScale(1, 1)
    art.Position = UDim2.fromScale(0, 0)
    art.BackgroundTransparency = 1
    art.BorderSizePixel = 0
    art.Active = false
    art.ZIndex = zIndex
    art.Parent = parent

    local function mark(name, anchor, position, size, rotation, shade, alpha)
        local item = Instance.new("Frame")
        item.Name = name
        item.AnchorPoint = anchor
        item.Position = position
        item.Size = size
        item.Rotation = rotation or 0
        item.BackgroundColor3 = shade
        item.BackgroundTransparency = alpha
        item.BorderSizePixel = 0
        item.Active = false
        item.ZIndex = zIndex
        item.Parent = art
        return item
    end

    local inset = isCompact and 10 or 14
    local long = isCompact and 13 or 21
    local opaque = color:Lerp(UITheme.Colors.Text, 0.36)

    -- The nonintersecting edge ticks never obscure the text or hazard glyph.
    for _, side in ipairs({-1, 1}) do
        local y = side == -1 and UDim2.new(0, inset, 0, 7)
            or UDim2.new(0, inset, 1, -7)
        mark(side == -1 and "UpperEngravedRail" or "LowerEngravedRail",
            Vector2.new(0, 0.5), y, UDim2.fromOffset(long * 2, 2),
            0, color, 0.34)
        local opposite = side == -1 and UDim2.new(1, -inset, 0, 7)
            or UDim2.new(1, -inset, 1, -7)
        mark(side == -1 and "UpperOppositeRail" or "LowerOppositeRail",
            Vector2.new(1, 0.5), opposite,
            UDim2.fromOffset(long * 2, 2), 0, color, 0.34)
    end

    for corner = 1, 4 do
        local left = corner % 2 == 1
        local upper = corner <= 2
        local signX = left and 1 or -1
        local signY = upper and 1 or -1
        local x = left and 0 or 1
        local y = upper and 0 or 1
        local outer = UDim2.new(x, signX * inset, y, signY * inset)
        local name = "MachinedRegister" .. corner
        mark(name .. "Cut",
            Vector2.new(0.5, 0.5), outer,
            UDim2.fromOffset(isCompact and 9 or 13, 2),
            left == upper and -43 or 43, opaque, 0.18)
        mark(name .. "Rivet",
            Vector2.new(0.5, 0.5),
            UDim2.new(x, signX * (inset + 10), y, signY * (inset + 8)),
            UDim2.fromOffset(3, 3), 45,
            UITheme.Colors.Text, 0.38)
    end
    return art
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
            activeTween = nil
        end
        -- Read the local setting only on input; no per-button frame loop
        -- or additional persistent attribute connection is needed.
        local localPlayer = Players.LocalPlayer
        if localPlayer and localPlayer:GetAttribute("ReduceMotion") == true then
            scale.Scale = 1
            return
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
