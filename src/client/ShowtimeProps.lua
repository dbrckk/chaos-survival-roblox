-- Procedural 3D prop kit for Chaos Showtime.
-- Works with standard Roblox primitives: no uploaded mesh IDs, no collisions and
-- no independent animation loop. The owning Showtime script drives all motion.
local UITheme = require(game:GetService("ReplicatedStorage").Shared.UITheme)

local ShowtimeProps = {}

local function primitive(parent, name, cf, size, color, material, transparency, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.CFrame = cf
    p.Size = size
    p.Color = color
    p.Material = material or Enum.Material.Metal
    p.Transparency = transparency or 0
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    if shape then
        p.Shape = shape
    end
    p:SetAttribute("ShowtimeDefaultTransparency", p.Transparency)
    p.Parent = parent
    return p
end

local function faceLabel(parent, text, face, color)
    local surface = Instance.new("SurfaceGui")
    surface.Name = "ShowtimePrintedDecal"
    surface.Face = face
    surface.LightInfluence = 0
    surface.AlwaysOnTop = false
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.PixelsPerStud = 30
    surface.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBlack
    label.Text = text
    label.TextColor3 = color
    label.TextStrokeColor3 = Color3.fromRGB(5, 8, 14)
    label.TextStrokeTransparency = 0.35
    label.TextScaled = true
    label.Parent = surface
end

local function buildSpeaker(folder, baseCF, index, options)
    local side = index == 1 and -1 or 1
    local stackCF = baseCF * CFrame.new(side * 8.0, 2.35, -3.9)
        * CFrame.Angles(0, math.rad(side * 12), 0)
    local metal = Color3.fromRGB(23, 29, 45)
    local accent = side == -1 and UITheme.Colors.Cyan or UITheme.Colors.Magenta

    primitive(folder, "ShowtimeSpeakerHousing" .. index, stackCF,
        Vector3.new(2.0, 4.5, 1.6), metal, Enum.Material.Metal, 0.02)
    local baffle = primitive(folder, "ShowtimeSpeakerBaffle" .. index,
        stackCF * CFrame.new(0, 0, 0.85),
        Vector3.new(1.80, 4.1, 0.10),
        Color3.fromRGB(7, 13, 23), Enum.Material.SmoothPlastic)
    faceLabel(baffle, "CHAOS  /  LIVE", Enum.NormalId.Back, accent)

    local lowCone = primitive(folder, "ShowtimeBassCone" .. index,
        stackCF * CFrame.new(0, -0.91, 0.94)
            * CFrame.Angles(math.rad(90), 0, 0),
        Vector3.new(1.33, 0.13, 1.33),
        Color3.fromRGB(42, 57, 78), Enum.Material.SmoothPlastic, 0, Enum.PartType.Cylinder)
    lowCone:SetAttribute("ShowtimeCone", true)
    primitive(folder, "ShowtimeBassCore" .. index,
        stackCF * CFrame.new(0, -0.91, 1.05) * CFrame.Angles(math.rad(90), 0, 0),
        Vector3.new(0.48, 0.15, 0.48), accent, Enum.Material.Neon, 0.13, Enum.PartType.Cylinder)
    if options.Detail then
        primitive(folder, "ShowtimeTrebleCone" .. index,
            stackCF * CFrame.new(0, 0.94, 0.94) * CFrame.Angles(math.rad(90), 0, 0),
            Vector3.new(0.84, 0.13, 0.84),
            Color3.fromRGB(54, 75, 100), Enum.Material.SmoothPlastic, 0, Enum.PartType.Cylinder)
        primitive(folder, "ShowtimeSpeakerTrim" .. index,
            stackCF * CFrame.new(0, 2.05, 0.87),
            Vector3.new(1.70, 0.12, 0.15), accent, Enum.Material.Neon, 0.09)
    end
end

local function buildConsole(folder, baseCF, tier)
    local bodyCF = baseCF * CFrame.new(0, 1.3, -6.35)
    local dark = Color3.fromRGB(20, 27, 43)
    primitive(folder, "ShowtimeDJBooth", bodyCF, Vector3.new(5.2, 1.9, 1.75),
        dark, Enum.Material.Metal, 0.03)
    local front = primitive(folder, "ShowtimeBoothFront", bodyCF * CFrame.new(0, 0, 0.89),
        Vector3.new(4.95, 1.42, 0.08),
        Color3.fromRGB(30, 43, 67), Enum.Material.Metal, 0.04)
    faceLabel(front, "C  H  A  O  S", Enum.NormalId.Back, UITheme.Colors.Cyan)

    primitive(folder, "ShowtimeMixDeck", bodyCF * CFrame.new(0, 1.00, 0),
        Vector3.new(4.8, 0.13, 1.67), dark, Enum.Material.SmoothPlastic)
    for i = 1, 2 do
        local side = i == 1 and -1 or 1
        primitive(folder, "ShowtimeTurntable" .. i,
            bodyCF * CFrame.new(side * 1.27, 1.085, 0.03),
            Vector3.new(1.20, 0.10, 1.20), Color3.fromRGB(60, 73, 101),
            Enum.Material.SmoothPlastic, 0, Enum.PartType.Cylinder)
        primitive(folder, "ShowtimeRecord" .. i,
            bodyCF * CFrame.new(side * 1.27, 1.15, 0.03),
            Vector3.new(0.75, 0.07, 0.75), UITheme.Colors.Violet,
            Enum.Material.Neon, 0.18, Enum.PartType.Cylinder)
    end
    if tier ~= "Low" then
        for i = 1, 5 do
            primitive(folder, "ShowtimeMixerFader" .. i,
                bodyCF * CFrame.new((i - 3) * 0.18, 1.13, -0.12),
                Vector3.new(0.075, 0.09, 0.50),
                i % 2 == 0 and UITheme.Colors.Cyan or UITheme.Colors.Magenta,
                Enum.Material.Neon, 0.16)
        end
    end
end

local function buildTruss(folder, baseCF, tier)
    local metal = Color3.fromRGB(67, 78, 100)
    local accent = UITheme.Colors.Violet
    for side = -1, 1, 2 do
        primitive(folder, "ShowtimeTrussLeg" .. tostring(side),
            baseCF * CFrame.new(side * 8.0, 4.15, -7.1),
            Vector3.new(0.24, 8.0, 0.24), metal, Enum.Material.Metal, 0.04)
        primitive(folder, "ShowtimeTrussLight" .. tostring(side),
            baseCF * CFrame.new(side * 8.0, 8.4, -7.1),
            Vector3.new(0.56, 0.45, 0.56), accent, Enum.Material.Neon, 0.20)
    end
    primitive(folder, "ShowtimeTrussCrossbar", baseCF * CFrame.new(0, 8.20, -7.1),
        Vector3.new(16.3, 0.32, 0.32), metal, Enum.Material.Metal)
    if tier == "High" then
        for i = 1, 5 do
            primitive(folder, "ShowtimeTrussAccent" .. i,
                baseCF * CFrame.new((i - 3) * 2.4, 8.13, -6.85),
                Vector3.new(0.85, 0.15, 0.15),
                i % 2 == 0 and UITheme.Colors.Cyan or UITheme.Colors.Magenta,
                Enum.Material.Neon, 0.12)
        end
    end
end

-- A faceted prismatic crown suspended over the DJ desk. Segmented rings
-- make a distinct 3D hero silhouette without any mesh upload or external IDs.
-- Segments are created once and only their CFrames are updated in a calm phase.
local function buildPrismaticCrown(folder, baseCF, tier)
    local center = baseCF * CFrame.new(0, 6.8, -3.7)
    local ringCount = tier == "High" and 14 or (tier == "Medium" and 10 or 6)
    local ringLayers = tier == "High" and 2 or 1
    local orbit = {}
    local crystal = primitive(folder, "ShowtimeCrownCrystal", center,
        Vector3.new(1.25, 1.25, 1.25),
        UITheme.Colors.Cyan, Enum.Material.Glass, 0.23, Enum.PartType.Ball)
    local heart = primitive(folder, "ShowtimeCrownHeart", center,
        Vector3.new(0.58, 0.58, 0.58),
        UITheme.Colors.Magenta, Enum.Material.Neon, 0.16, Enum.PartType.Ball)

    for layer = 1, ringLayers do
        local radius = layer == 1 and 2.06 or 2.55
        local color = layer == 1 and UITheme.Colors.Violet or UITheme.Colors.Cyan
        for i = 1, ringCount do
            local angle = ((i - 1) / ringCount) * math.pi * 2
            local localCF = CFrame.new(
                math.cos(angle) * radius,
                math.sin(angle) * radius,
                0
            ) * CFrame.Angles(0, 0, angle + math.pi * 0.5)
            local segment = primitive(folder,
                "ShowtimeCrownRing" .. layer .. "_" .. i,
                center * localCF,
                Vector3.new(2 * math.pi * radius / ringCount * 0.82, 0.11, 0.15),
                color, Enum.Material.Neon, layer == 1 and 0.18 or 0.31)
            table.insert(orbit, {
                part = segment,
                localCF = localCF,
                layer = layer,
            })
        end
    end

    -- Two bottom anchors visually connect the suspended centerpiece to the
    -- stage without placing any blocking geometry in the player's path.
    local anchorCount = tier == "Low" and 0 or 2
    for i = 1, anchorCount do
        local side = i == 1 and -1 or 1
        primitive(folder, "ShowtimeCrownAnchor" .. i,
            baseCF * CFrame.new(side * 2.6, 5.9, -3.9)
                * CFrame.Angles(0, 0, math.rad(side * 22)),
            Vector3.new(0.24, 1.0, 0.24),
            UITheme.Colors.Cyan, Enum.Material.Glass, 0.22)
    end

    return {
        center = center,
        crystal = crystal,
        heart = heart,
        orbit = orbit,
    }
end

-- Returns references only to the truly animated pieces. Everything else is
-- static and inexpensive in the client, built once per graphics-tier change.
function ShowtimeProps.build(parent, baseCF, tier)
    local holder = Instance.new("Folder")
    holder.Name = "Showtime3DAssets"
    holder.Parent = parent
    local settings = {Detail = tier ~= "Low"}
    buildSpeaker(holder, baseCF, 1, settings)
    buildSpeaker(holder, baseCF, 2, settings)
    buildConsole(holder, baseCF, tier)
    buildTruss(holder, baseCF, tier)
    local crown = buildPrismaticCrown(holder, baseCF, tier)

    local equalizer = {}
    local count = tier == "Low" and 3 or (tier == "Medium" and 5 or 8)
    for i = 1, count do
        local x = (i - (count + 1) / 2) * (tier == "High" and 0.48 or 0.62)
        local height = 0.42
        local part = primitive(holder, "ShowtimeEqualizer" .. i,
            baseCF * CFrame.new(x, 3.03, -5.40),
            Vector3.new(0.26, height, 0.18),
            i % 2 == 0 and UITheme.Colors.Cyan or UITheme.Colors.Magenta,
            Enum.Material.Neon, 0.22)
        table.insert(equalizer, {part = part, x = x, offset = i * 0.77})
    end

    return {
        folder = holder,
        baseCF = baseCF,
        equalizer = equalizer,
        crown = crown,
        props = holder:GetDescendants(),
    }
end

function ShowtimeProps.update(asset, now, enabled, reduceMotion, audience)
    if not asset or not asset.folder.Parent then
        return
    end
    if asset.visible ~= enabled then
        asset.visible = enabled
        for _, descendant in ipairs(asset.props) do
            if descendant:IsA("BasePart") then
                if enabled then
                    descendant.Transparency = descendant:GetAttribute("ShowtimeDefaultTransparency") or 0
                else
                    descendant.Transparency = 1
                end
            elseif descendant:IsA("SurfaceGui") then
                descendant.Enabled = enabled
            end
        end
    end
    if not enabled then
        return
    end
    for _, bar in ipairs(asset.equalizer) do
        local height = reduceMotion and 0.38 or
            (0.35 + 1.10 * (0.5 + 0.5 * math.sin(now * 3.3 + bar.offset)))
                * (0.85 + math.min(4, audience or 0) * 0.08)
        bar.part.Size = Vector3.new(0.26, height, 0.18)
        bar.part.CFrame = asset.baseCF * CFrame.new(
            bar.x, 2.8 + height * 0.5, -5.40
        )
    end

    local crown = asset.crown
    if crown then
        local crowd = math.clamp(tonumber(audience) or 0, 0, 4)
        local time = reduceMotion and 0 or (tonumber(now) or 0)
        local attitude = CFrame.Angles(
            math.rad(22) + time * 0.14,
            time * (0.24 + crowd * 0.035),
            math.rad(36)
        )
        crown.crystal.CFrame = crown.center * attitude
        crown.heart.CFrame = crown.center * attitude
        for _, ring in ipairs(crown.orbit) do
            local layerSpin = ring.layer == 1 and time * 0.33 or -time * 0.23
            local ringAttitude = attitude * CFrame.Angles(
                layerSpin * 0.65,
                0,
                layerSpin
            )
            ring.part.CFrame = crown.center * ringAttitude * ring.localCF
        end
        -- A restrained highlight makes group emotes feel responsive without
        -- any extra particle emitters, dynamic lights or surface scans.
        crown.heart.Transparency = reduceMotion and 0.16
            or math.clamp(0.27 - crowd * 0.035 - math.sin(time * 2.2) * 0.055, 0.06, 0.32)
    end
end

return ShowtimeProps
