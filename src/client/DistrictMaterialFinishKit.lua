-- Original, asset-free industrial markings for the four interactive-scale
-- district scenes. SurfaceGui paints ONLY on existing cosmetic Parts.
-- Unlike fake rbxassetid textures, this finish renders immediately after
-- Rojo build: rusted metal / diamond plate are Roblox native materials,
-- while registration marks and service stripes are deterministic 2D art.
-- Never parents scripts, projectors, lights or physics objects to the map.
local DistrictMaterialFinishKit = {}

local function rect(parent, name, size, position, color, transparency)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BorderSizePixel = 0
    frame.BackgroundColor3 = color
    frame.BackgroundTransparency = transparency or 0
    frame.Parent = parent
    return frame
end

-- No image asset uploads, textures with unverifiable IDs, or painted
-- planes in space. Markings are real surface-attached Roblox UI.
function DistrictMaterialFinishKit.stencil(surface, serial, accent, tier, style)
    if not surface or not surface:IsA("BasePart")
        or tier == "Low" then
        return nil
    end

    local gui = Instance.new("SurfaceGui")
    gui.Name = "AuthoredIndustrialFinish"
    gui.Face = Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = tier == "High" and 24 or 16
    gui.LightInfluence = 0.70
    gui.AlwaysOnTop = false
    gui.ZOffset = 0.02
    gui.Parent = surface

    local dark = Color3.fromRGB(12, 21, 31)
    local pale = Color3.fromRGB(199, 214, 223)

    -- Large quiet opaque coating, not a fully luminous flat billboard.
    local coating = rect(gui, "EtchedPanel", UDim2.fromScale(1, 1),
        UDim2.fromScale(0, 0), dark, 0.18)
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 90
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(44, 55, 68)),
        ColorSequenceKeypoint.new(0.46, Color3.fromRGB(25, 34, 46)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 23, 35)),
    })
    gradient.Parent = coating

    rect(coating, "UpperRegistration", UDim2.new(0.84, 0, 0, 3),
        UDim2.fromScale(0.08, 0.08), accent, 0.12)
    rect(coating, "LowerSteelEdge", UDim2.new(0.84, 0, 0, 2),
        UDim2.fromScale(0.08, 0.89), pale, 0.54)

    local title = Instance.new("TextLabel")
    title.Name = "StampedEquipmentSerial"
    title.BackgroundTransparency = 1
    title.Size = UDim2.fromScale(0.76, 0.34)
    title.Position = UDim2.fromScale(0.12, 0.22)
    title.Font = Enum.Font.GothamBold
    title.Text = serial
    title.TextColor3 = pale
    title.TextScaled = true
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextStrokeTransparency = 0.86
    title.Parent = coating

    for i = 1, (tier == "High" and 5 or 3) do
        rect(coating, "SensorTick" .. i,
            UDim2.new(0.09 + (i % 2) * 0.06, 0, 0.025, 0),
            UDim2.fromScale(0.11 + (i - 1) * 0.155, 0.70),
            i == 1 and accent or pale,
            i == 1 and 0.04 or 0.46)
    end

    if style == "hazard" then
        local safety = rect(coating, "CautionBar",
            UDim2.fromScale(0.84, 0.17),
            UDim2.fromScale(0.08, 0.78),
            Color3.fromRGB(198, 140, 58), 0.12)
        safety.ClipsDescendants = true
        for i = 0, (tier == "High" and 7 or 4) do
            local stripe = rect(safety, "DiagonalStripe" .. i,
                UDim2.fromScale(0.055, 2),
                UDim2.fromScale(i * 0.17 - 0.07, -0.5),
                Color3.fromRGB(20, 25, 29), 0.06)
            stripe.Rotation = -30
        end
    else
        -- Narrow telemetry bars look engraved, not like world neon.
        rect(coating, "SystemReadout", UDim2.fromScale(0.37, 0.035),
            UDim2.fromScale(0.55, 0.60), accent, 0.36)
    end
    return gui
end

return DistrictMaterialFinishKit
