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
end

return ShowtimeProps
