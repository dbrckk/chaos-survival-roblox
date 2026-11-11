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

-- The same close-up service doors exist in five radically different
-- environments. These small surface stencils are locally authored,
-- transparent overlays, NOT unmoderated image assets or fake PBR maps.
-- Existing 2K MaterialVariants retain ownership of the actual geometry.
local DOOR_FINISH = {
    Classic = {
        label = "SURVEY / GRID",
        metal = Color3.fromRGB(40, 58, 76),
        highlight = Color3.fromRGB(166, 202, 219),
        lowlight = Color3.fromRGB(26, 38, 54),
    },
    Towers = {
        label = "LIFT / LOAD",
        metal = Color3.fromRGB(42, 61, 65),
        highlight = Color3.fromRGB(156, 192, 198),
        lowlight = Color3.fromRGB(26, 43, 47),
    },
    Crossroads = {
        label = "ROUTE / XFER",
        metal = Color3.fromRGB(65, 47, 76),
        highlight = Color3.fromRGB(199, 166, 205),
        lowlight = Color3.fromRGB(42, 30, 52),
    },
    Orbital = {
        label = "REACTOR / SEAL",
        metal = Color3.fromRGB(45, 72, 67),
        highlight = Color3.fromRGB(164, 207, 195),
        lowlight = Color3.fromRGB(25, 48, 45),
    },
    Harbor = {
        label = "QUAY / HATCH",
        metal = Color3.fromRGB(48, 69, 72),
        highlight = Color3.fromRGB(180, 196, 181),
        lowlight = Color3.fromRGB(33, 47, 52),
    },
}

-- No image asset uploads, textures with unverifiable IDs, or painted
-- planes in space. Markings are real surface-attached Roblox UI.
function DistrictMaterialFinishKit.stencil(surface, serial, accent, tier, style, face, variant)
    if not surface or not surface:IsA("BasePart")
        or tier == "Low" then
        return nil
    end

    local gui = Instance.new("SurfaceGui")
    gui.Name = "AuthoredIndustrialFinish"
    gui.Face = face or Enum.NormalId.Front
    gui.MaxDistance = tier == "High" and 145 or 115
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = tier == "High" and 24 or 16
    gui.LightInfluence = 0.70
    gui.AlwaysOnTop = false
    gui.ZOffset = 0
    gui.Parent = surface

    local dark = Color3.fromRGB(12, 21, 31)
    local pale = Color3.fromRGB(199, 214, 223)

    -- The front service-door ID is a small upper metal stencil, not an
    -- opaque fullscreen facade decal. It preserves the original native
    -- relief and any approved, budgeted PBR material beneath.
    if style == "service-door" then
        local plate = rect(gui, "ServiceDoorNumberPlate",
            UDim2.fromScale(0.84, 0.25),
            UDim2.fromScale(0.08, 0.07), dark, 0.08)
        rect(plate, "SectorIdentityEdge",
            UDim2.fromScale(1, 0.09),
            UDim2.fromScale(0, 0), accent, 0.12)
        local stamp = Instance.new("TextLabel")
        stamp.Name = "StampedDoorIdentity"
        stamp.Size = UDim2.fromScale(0.91, 0.74)
        stamp.Position = UDim2.fromScale(0.045, 0.18)
        stamp.BackgroundTransparency = 1
        stamp.Font = Enum.Font.GothamBold
        stamp.Text = serial
        stamp.TextColor3 = pale
        stamp.TextScaled = true
        stamp.TextStrokeTransparency = 0.85
        stamp.TextXAlignment = Enum.TextXAlignment.Center
        stamp.Parent = plate

        -- Deep, map-specific, camera-readable industrial registration.
        -- Max 16 High / 8 Medium SurfaceGuis already enforced by the
        -- caller; all detail is flat UI on the EXISTING 4.65-stud door.
        -- Transparent metal inlay keeps its approved PBR texture visible.
        local identity = DOOR_FINISH[variant] or DOOR_FINISH.Classic
        local high = tier == "High"
        local darkMetal = rect(gui, "ForgedDoorRecess",
            UDim2.fromScale(0.86, 0.47),
            UDim2.fromScale(0.07, 0.39),
            identity.metal, 0.68)
        local direction = Instance.new("UIGradient")
        direction.Name = "ForgedDirectionalGrain"
        direction.Rotation = 94
        direction.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, identity.lowlight),
            ColorSequenceKeypoint.new(0.33, identity.metal),
            ColorSequenceKeypoint.new(0.70, identity.highlight),
            ColorSequenceKeypoint.new(1, identity.lowlight),
        })
        direction.Parent = darkMetal

        -- Inset-edge highlights, a recessed central joint and real
        -- registration hardware instead of an opaque full-door billboard.
        rect(darkMetal, "UpperMachinedLip",
            UDim2.fromScale(0.92, 0.025), UDim2.fromScale(0.04, 0.10),
            identity.highlight, 0.40)
        rect(darkMetal, "LowerMachinedLip",
            UDim2.fromScale(0.92, 0.025), UDim2.fromScale(0.04, 0.89),
            identity.lowlight, 0.22)
        rect(darkMetal, "CentralManufacturingSeam",
            UDim2.fromScale(0.012, 0.65), UDim2.fromScale(0.50, 0.17),
            identity.lowlight, 0.32)
        local fastenerCount = high and 4 or 2
        for n = 1, fastenerCount do
            local left = n % 2 == 1
            local upper = n <= 2
            local fastener = rect(darkMetal, "ForgedFastener" .. n,
                UDim2.fromScale(0.035, 0.072),
                UDim2.fromScale(left and 0.058 or 0.907,
                    upper and 0.18 or 0.76),
                identity.highlight, 0.20)
            local rounded = Instance.new("UICorner")
            rounded.CornerRadius = UDim.new(1, 0)
            rounded.Parent = fastener
        end

        local location = rect(gui, "DistrictTechnicalBand",
            UDim2.fromScale(0.76, 0.075),
            UDim2.fromScale(0.12, 0.88),
            identity.lowlight, 0.57)
        local tag = Instance.new("TextLabel")
        tag.Name = "IndustrialFamilyMark"
        tag.Size = UDim2.fromScale(0.98, 1)
        tag.Position = UDim2.fromScale(0.01, 0)
        tag.BackgroundTransparency = 1
        tag.Font = Enum.Font.GothamBold
        tag.Text = identity.label
        tag.TextScaled = true
        tag.TextColor3 = identity.highlight
        tag.TextTransparency = 0.12
        tag.Parent = location

        if variant == "Classic" or variant == nil then
            -- Survey calibration rack: fine datum marks rather than
            -- hazard chevrons or a second luminous gameplay arrow.
            for n = 1, high and 6 or 3 do
                rect(darkMetal, "SurveyGauge" .. n,
                    UDim2.fromScale(n % 2 == 0 and 0.10 or 0.06, 0.013),
                    UDim2.fromScale(0.10,
                        0.26 + (n - 1) * (high and 0.085 or 0.17)),
                    identity.highlight, 0.28)
            end
        elseif variant == "Towers" then
            -- Repeated steel reinforcement ribs make industrial
            -- loading machinery visually distinct from survey stations.
            for n = 1, high and 4 or 2 do
                local rib = rect(darkMetal, "HoistReinforcement" .. n,
                    UDim2.fromScale(0.11, 0.37),
                    UDim2.fromScale(0.24 + (n - 1) * (high and 0.15 or 0.29), 0.34),
                    identity.highlight, 0.57)
                rib.Rotation = n % 2 == 0 and 12 or -12
            end
        elseif variant == "Crossroads" then
            -- Parallel switchyard wiring with one orthogonal crossover,
            -- not orange/red hazard markings or an interactive button.
            for n = 1, high and 4 or 2 do
                rect(darkMetal, "ExchangeRoute" .. n,
                    UDim2.fromScale(0.60, 0.016),
                    UDim2.fromScale(0.21, 0.25 + n * (high and 0.13 or 0.22)),
                    identity.highlight, 0.49)
            end
            rect(darkMetal, "ExchangeCrossConnect",
                UDim2.fromScale(0.018, 0.58),
                UDim2.fromScale(0.67, 0.22),
                identity.highlight, 0.53)
        elseif variant == "Orbital" then
            -- Ceramic containment collars, circular rather than
            -- Classic's square calibration segments.
            for n = 1, high and 2 or 1 do
                local ring = rect(darkMetal, "ContainmentCollar" .. n,
                    UDim2.fromScale(0.24 - (n - 1) * 0.08,
                        0.43 - (n - 1) * 0.14),
                    UDim2.fromScale(0.38 + (n - 1) * 0.04,
                        0.30 + (n - 1) * 0.07),
                    identity.metal, 1)
                local rounded = Instance.new("UICorner")
                rounded.CornerRadius = UDim.new(1, 0)
                rounded.Parent = ring
                local outline = Instance.new("UIStroke")
                outline.Color = identity.highlight
                outline.Thickness = 1
                outline.Transparency = 0.40 + (n - 1) * 0.16
                outline.Parent = ring
            end
        elseif variant == "Harbor" then
            -- Salt-worn hatch seams and bolted horizontal plating,
            -- with cool colors that do not mimic lava/fire warnings.
            for n = 1, high and 5 or 3 do
                rect(darkMetal, "QuayHatchRib" .. n,
                    UDim2.fromScale(0.65, 0.019),
                    UDim2.fromScale(0.19, 0.19 + n * (high and 0.11 or 0.17)),
                    n % 2 == 0 and identity.lowlight or identity.highlight,
                    n % 2 == 0 and 0.18 or 0.56)
            end
        end
        return gui
    end

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
