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
        -- The dangerous footprint must become MORE legible as impact
        -- approaches. The old contour faded at the worst possible moment.
        -- Reduced-motion stays fixed and never pulses.
        -- Reduce opacity as the blast approaches: the old recipe added
        -- transparency near detonation, hiding the most urgent border on
        -- small screens. No extra flashes, parts or render updates.
        OuterTransparency = reduced and 0.25
            or math.clamp(0.34 - alpha * 0.16 + wave * 0.018, 0.16, 0.36),
        InnerTransparency = reduced and 0.56
            or math.clamp(0.62 - alpha * 0.13, 0.47, 0.64),
        Thickness = tier == "Low" and 3 or (tier == "High" and 6 or 5),
        InnerVisible = tier ~= "Low",
        -- Medium phones get directional ticks only near impact; High
        -- retains the authored full-time bearings.
        TicksVisible = not reduced
            and (tier == "High" or (tier == "Medium" and alpha >= 0.58)),
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

-- Hollow outlines are optional local cosmetics. The server warning marker,
-- full blast diameter and the close-range escape HUD never get culled.
-- A small hysteresis band keeps distant Android GUI layers from flashing
-- on/off whenever the camera skims a distance boundary.
local DISTANCE_BUDGET = {Low = 92, Medium = 132, High = 180}

function Kit.inRange(tier, distance, wasVisible)
    if distance == nil then return true end
    if type(distance) ~= "number" or distance ~= distance
        or distance < 0 or math.abs(distance) == math.huge then
        return false
    end
    local maximum = DISTANCE_BUDGET[tier] or DISTANCE_BUDGET.Low
    return distance <= maximum + (wasVisible == true and 12 or 0)
end

function Kit.syncVisibility(visual, tier, distance)
    if not visual or not visual.canvas or not visual.canvas.Parent then
        return false
    end
    local visible = Kit.inRange(tier, distance, visual.visible)
    if visual.visible ~= visible or visual.canvas.Enabled ~= visible then
        visual.canvas.Enabled = visible
    end
    visual.visible = visible
    return visible
end

-- Keep the 3D footprint and four UI-bearing ticks in sync, but do not
-- rewrite identical geometry/colors every 30 Hz in ReduceMotion or when
-- an impact marker is stationary. Cache *recipes*, not server hitboxes.
function Kit.update(visual, worldPosition, diameter, progress, reduced, pulse, tier)
    if not visual or not visual.part or not visual.part.Parent
        or typeof(worldPosition) ~= "Vector3" then
        return
    end
    local kind = string.match(visual.part.Name, "^(%a+)WarningOutlineLocal$")
    local recipe = Kit.recipe(kind, diameter, progress, reduced, pulse, tier)
    if not recipe then return end

    local newSize = Vector3.new(recipe.Diameter, 0.08, recipe.Diameter)
    if visual.lastSize ~= newSize then
        visual.part.Size = newSize
        visual.lastSize = newSize
    end
    local newFrame = CFrame.new(worldPosition + Vector3.new(0, 0.08, 0))
    if visual.lastFrame ~= newFrame then
        visual.part.CFrame = newFrame
        visual.lastFrame = newFrame
    end
    local previous = visual.lastRecipe
    if not previous or previous.Thickness ~= recipe.Thickness then
        visual.outer.Thickness = recipe.Thickness
    end
    if not previous or math.abs(previous.OuterTransparency - recipe.OuterTransparency) > 0.0001 then
        visual.outer.Transparency = recipe.OuterTransparency
    end
    if not previous or previous.InnerVisible ~= recipe.InnerVisible then
        visual.inner.Enabled = recipe.InnerVisible
    end
    if not previous or math.abs(previous.InnerTransparency - recipe.InnerTransparency) > 0.0001 then
        visual.inner.Transparency = recipe.InnerTransparency
    end
    if not previous or previous.TicksVisible ~= recipe.TicksVisible then
        for _, tick in ipairs(visual.ticks) do
            tick.Visible = recipe.TicksVisible
        end
    end
    visual.lastRecipe = recipe
end

function Kit.destroy(visual)
    if visual and visual.part then visual.part:Destroy() end
end

return Kit
