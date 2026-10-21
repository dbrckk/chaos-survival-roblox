-- Client-only, surface-bound orbital navigation signs.
-- SurfaceGui follows the *real* collidable ramp through Shrinking Arena,
-- without welded parts, extra render loops, or additional physics.
local OrbitalRouteSignKit = {}

local COPY = {
    en = {
        Entry = {"ASCEND", "OUTER RING"},
        Core = {"REACTOR", "FINAL ASCENT"},
    },
    fr = {
        Entry = {"MONTER", "ANNEAU EXT."},
        Core = {"RÉACTEUR", "DERNIER PALIER"},
    },
}

local SIGNAL = {
    Entry = Color3.fromRGB(88, 235, 222),
    Core = Color3.fromRGB(255, 213, 118),
}

function OrbitalRouteSignKit.kind(ramp)
    if not ramp or not ramp:IsA("BasePart") then return nil end
    -- Nine central walkways can coexist with eight scored Helix lanes:
    -- HelixRamp9 is the preserved transit-only reactor connection.
    if ramp:GetAttribute("OrbitalAccessRamp") == true then
        return "Entry"
    end
    if ramp:GetAttribute("OrbitalCoreRamp") == true then
        return "Core"
    end
    return nil
end

function OrbitalRouteSignKit.copy(kind, locale)
    local language = tostring(locale or "en"):sub(1, 2):lower()
    local text = COPY[language] or COPY.en
    return text[kind]
end

-- Signs communicate essential routes even on Low or ReduceMotion.
-- A single flat SurfaceGui uses no extra moving parts or emissive lights.
function OrbitalRouteSignKit.create(ramp, parent, tierName, locale)
    local kind = OrbitalRouteSignKit.kind(ramp)
    if not kind or not parent then return nil end

    local tier = tierName == "High" and "High"
        or (tierName == "Medium" and "Medium" or "Low")
    local copy = OrbitalRouteSignKit.copy(kind, locale)
    local accent = SIGNAL[kind]

    local gui = Instance.new("SurfaceGui")
    gui.Name = "Orbital" .. kind .. "Navigation"
    gui.Adornee = ramp
    gui.Face = Enum.NormalId.Top
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = tier == "Low" and 16 or 22
    gui.MaxDistance = tier == "High" and 115 or 90
    gui.AlwaysOnTop = false
    gui.LightInfluence = 0.12
    gui.ZOffset = 0.03
    gui:SetAttribute("OrbitRouteKind", kind)
    gui.Parent = parent

    local panel = Instance.new("Frame")
    panel.Name = "EtchedWayfindingPlate"
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.48)
    panel.Size = UDim2.fromScale(0.85, 0.30)
    panel.BackgroundColor3 = Color3.fromRGB(9, 24, 34)
    panel.BackgroundTransparency = tier == "Low" and 0.22 or 0.42
    panel.BorderSizePixel = 0
    panel.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Name = "SignalOutline"
    stroke.Color = accent
    stroke.Transparency = tier == "High" and 0.18 or 0.36
    stroke.Thickness = tier == "High" and 1.8 or 1.3
    stroke.Parent = panel

    local accentRule = Instance.new("Frame")
    accentRule.Name = "DirectionalIndex"
    accentRule.Size = UDim2.fromScale(0.80, 0.075)
    accentRule.Position = UDim2.fromScale(0.10, 0.08)
    accentRule.BorderSizePixel = 0
    accentRule.BackgroundColor3 = accent
    accentRule.BackgroundTransparency = tier == "Low" and 0.12 or 0.28
    accentRule.Parent = panel

    local name = Instance.new("TextLabel")
    name.Name = "RouteName"
    name.AnchorPoint = Vector2.new(0.5, 0.5)
    name.Position = UDim2.fromScale(0.5, tier == "High" and 0.46 or 0.55)
    name.Size = UDim2.fromScale(0.94, tier == "High" and 0.46 or 0.66)
    name.BackgroundTransparency = 1
    name.Font = Enum.Font.GothamBlack
    name.TextScaled = true
    name.TextColor3 = accent
    name.TextStrokeColor3 = Color3.fromRGB(2, 10, 15)
    name.TextStrokeTransparency = 0.70
    name.Text = copy[1]
    name.Parent = panel

    local textConstraint = Instance.new("UITextSizeConstraint")
    textConstraint.MinTextSize = 8
    textConstraint.MaxTextSize = tier == "Low" and 16 or 22
    textConstraint.Parent = name

    if tier == "High" then
        local detail = Instance.new("TextLabel")
        detail.Name = "DestinationHint"
        detail.AnchorPoint = Vector2.new(0.5, 0.5)
        detail.Position = UDim2.fromScale(0.5, 0.79)
        detail.Size = UDim2.fromScale(0.95, 0.20)
        detail.BackgroundTransparency = 1
        detail.Font = Enum.Font.GothamBold
        detail.TextScaled = true
        detail.TextColor3 = Color3.fromRGB(218, 234, 243)
        detail.Text = copy[2]
        detail.Parent = panel
        local cap = Instance.new("UITextSizeConstraint")
        cap.MinTextSize = 7
        cap.MaxTextSize = 13
        cap.Parent = detail
    end

    return gui
end

return OrbitalRouteSignKit
