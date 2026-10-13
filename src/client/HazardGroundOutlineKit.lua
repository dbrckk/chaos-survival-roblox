-- A hollow, world-space warning contour replaces an opaque duplicate disc.
-- Cosmetics only: no collision, extra lights, particles or render loops.
local Kit = {}

local PALETTES = {
    Meteor = {Color3.fromRGB(255, 184, 72), Color3.fromRGB(255, 227, 133)},
    Bomb = {Color3.fromRGB(255, 79, 70), Color3.fromRGB(255, 165, 102)},
}

local function addContour(canvas, name, size, color, thickness, opacity)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.Size = UDim2.fromScale(size, size)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = canvas
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Name = name .. "Stroke"
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = color
    stroke.Thickness = thickness
    stroke.Transparency = opacity
    stroke.Parent = frame
    return stroke
end

function Kit.recipe(kind, diameter, progress, reduced, pulse, tier)
    if not PALETTES[kind] or type(diameter) ~= "number"
        or diameter ~= diameter or diameter <= 0 or diameter == math.huge then
        return nil
    end
    local d = math.clamp(diameter, 0.1, 220)
    local alpha = reduced and 0.35
        or math.clamp(tonumber(progress) or 0, 0, 1)
    local wave = reduced and 0.5 or math.clamp(tonumber(pulse) or 0.5, 0, 1)
    return {
        Diameter = d * (reduced and 1.12 or (1.10 + wave * 0.12)),
        OuterTransparency = math.clamp(
            0.16 + alpha * 0.35 + (reduced and 0 or wave * 0.09), 0.12, 0.75
        ),
        InnerTransparency = math.clamp(0.56 + alpha * 0.23, 0.56, 0.85),
        Thickness = tier == "Low" and 3 or (tier == "High" and 5 or 4),
        InnerVisible = tier ~= "Low",
        TicksVisible = tier == "High" and not reduced,
    }
end

function Kit.create(parent, kind)
    local palette = PALETTES[kind]
    if typeof(parent) ~= "Instance" or not palette then return nil end
    local carrier = Instance.new("Part")
    carrier.Name = kind .. "WarningOutlineLocal"
    carrier.Size = Vector3.new(5.5, 0.08, 5.5)
    carrier.Anchored = true
    carrier.CanCollide = false
    carrier.CanTouch = false
    carrier.CanQuery = false
    carrier.CastShadow = false
    carrier.Transparency = 1
    carrier.Material = Enum.Material.SmoothPlastic

    local canvas = Instance.new("SurfaceGui")
    canvas.Name = "HollowImpactOutline"
    canvas.Face = Enum.NormalId.Top
    canvas.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    canvas.PixelsPerStud = 32
    canvas.LightInfluence = 0
    canvas.AlwaysOnTop = false
    canvas.Parent = carrier

    local outer = addContour(canvas, "PrimaryHollowContour", 0.93, palette[1], 4, 0.22)
    local inner = addContour(canvas, "SecondaryHollowContour", 0.80, palette[2], 2, 0.62)
    local ticks = {}
    for index = 1, 4 do
        local angle = math.rad((index - 1) * 90 + (kind == "Meteor" and 45 or 0))
        local tick = Instance.new("Frame")
        tick.Name = "ImpactBearing" .. index
        tick.AnchorPoint = Vector2.new(0.5, 0.5)
        tick.Position = UDim2.fromScale(
            0.5 + math.cos(angle) * 0.455, 0.5 + math.sin(angle) * 0.455
        )
        tick.Size = UDim2.fromScale(0.115, 0.012)
        tick.Rotation = math.deg(angle) + 90
        tick.BackgroundColor3 = palette[2]
        tick.BackgroundTransparency = 0.14
        tick.BorderSizePixel = 0
        tick.Visible = false
        tick.Parent = canvas
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = tick
        ticks[index] = tick
    end

    carrier.Parent = parent
    return {part = carrier, canvas = canvas, outer = outer, inner = inner, ticks = ticks}
end

function Kit.update(visual, worldPosition, diameter, progress, reduced, pulse, tier)
    if not visual or not visual.part or not visual.part.Parent
        or typeof(worldPosition) ~= "Vector3" then
        return
    end
    local kind = string.match(visual.part.Name, "^(%a+)WarningOutlineLocal$")
    local recipe = Kit.recipe(kind, diameter, progress, reduced, pulse, tier)
    if not recipe then return end
    visual.part.Size = Vector3.new(recipe.Diameter, 0.08, recipe.Diameter)
    visual.part.CFrame = CFrame.new(worldPosition + Vector3.new(0, 0.08, 0))
    visual.outer.Thickness = recipe.Thickness
    visual.outer.Transparency = recipe.OuterTransparency
    visual.inner.Enabled = recipe.InnerVisible
    visual.inner.Transparency = recipe.InnerTransparency
    for _, tick in ipairs(visual.ticks) do
        tick.Visible = recipe.TicksVisible
    end
end

function Kit.destroy(visual)
    if visual and visual.part then visual.part:Destroy() end
end

return Kit
