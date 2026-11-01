-- Four original, sharply readable miniature dry-dock silhouettes.
-- Owned by the EXISTING arena-platform-identity rebuild and its welded
-- shrink/collapse lifecycle; never starts a new heartbeat or render loop.
-- No collision, touch/query, paid assets, lights or external packages.
local HarborOutpostKit = {}

local PROFILES = {
    [1] = {name = "StormRadar", yaw = 0, shape = Enum.PartType.Cylinder,
        span = 6.1, height = 4.5, legX = 2.7},
    [2] = {name = "CargoHoist", yaw = -math.pi * 0.5,
        shape = Enum.PartType.Cylinder, span = 7.4, height = 3.3, legX = 3.25},
    [3] = {name = "TidalBeacon", yaw = math.pi, shape = Enum.PartType.Ball,
        span = 5.7, height = 4.0, legX = 2.5},
    [4] = {name = "SignalArray", yaw = math.pi * 0.5,
        shape = Enum.PartType.Cylinder, span = 6.7, height = 5.0, legX = 2.95},
}

function HarborOutpostKit.count(tier)
    if tier == "High" then return 9 end
    if tier == "Medium" then return 5 end
    return 0
end

-- `makePart` is the scene's existing factory: it registers each cosmetic
-- with the real platform, assigns ChaosBaseTransparency and creates an
-- adjustable PlatformIdentityWeld. The owner then applies one shared
-- shrink-footprint and CollapsePhase policy to ALL of these pieces.
function HarborOutpostKit.build(makePart, platform, index, theme, tier)
    if type(makePart) ~= "function" or not platform
        or not platform:IsA("BasePart") or not theme then
        return 0
    end
    local route = platform:GetAttribute("HarborSpokeRoute")
    local step = platform:GetAttribute("HarborSpokeStep")
    local profile = PROFILES[route]
    local budget = HarborOutpostKit.count(tier)
    if not profile or step ~= 4 or budget == 0
        or math.min(platform.Size.X, platform.Size.Z) < 6 then
        return 0
    end

    -- All above-surface hardware sits at the OUTWARD edge of the real
    -- final deck; the centre landing remains visually open. A worn keel
    -- projects UNDER the deck, never suggesting a false walkable ledge.
    local frame = platform.CFrame * CFrame.Angles(0, profile.yaw, 0)
    local top = platform.Size.Y * 0.5
    local rear = -math.min(platform.Size.Z * 0.34, 3.6)
    local mastHeight = profile.height
    local spread = profile.legX
    local steel = theme.Structure:Lerp(theme.Detail, 0.25)
    local trim = theme.Detail:Lerp(theme.Secondary, 0.23)
    local muted = theme.Structure:Lerp(Color3.fromRGB(72, 91, 104), 0.30)
    local signature = ({
        [1] = Color3.fromRGB(169, 197, 201),
        [2] = Color3.fromRGB(199, 161, 118),
        [3] = Color3.fromRGB(171, 174, 148),
        [4] = Color3.fromRGB(149, 174, 197),
    })[route]
    local made = 0
    local function add(suffix, size, localFrame, color, material, alpha, shape)
        local part = makePart(
            "Harbor" .. profile.name .. suffix .. tostring(index),
            size, frame * localFrame, color, material, alpha, platform
        )
        if part and shape then
            part.Shape = shape
        end
        made += 1
    end

    -- Medium: exactly five pieces per outpost; 20 across Harbor.
    add("Keel", Vector3.new(profile.span + 0.35, 0.44, 1.05),
        CFrame.new(0, -top - 0.38, rear),
        muted, Enum.Material.CorrodedMetal, 0.08)
    for _, side in ipairs({-1, 1}) do
        add(side < 0 and "PortLeg" or "StarboardLeg",
            Vector3.new(0.65, mastHeight, 0.65),
            CFrame.new(side * spread, top + mastHeight * 0.5, rear),
            steel, Enum.Material.Metal, 0.06)
    end
    add("Gantry", Vector3.new(profile.span, 0.48, 0.84),
        CFrame.new(0, top + mastHeight + 0.15, rear),
        trim, Enum.Material.CorrodedMetal, 0.05)

    local instrumentSize = route == 3
        and Vector3.new(1.75, 1.75, 1.75)
        or (route == 2 and Vector3.new(1.30, 1.85, 1.85)
            or Vector3.new(0.85, 2.15, 2.15))
    add("Instrument", instrumentSize,
        CFrame.new(0, top + mastHeight - 0.15, rear - 0.15)
            * CFrame.Angles(0, 0, route == 4 and math.rad(20) or 0),
        signature, route == 3 and Enum.Material.Slate
            or Enum.Material.CorrodedMetal,
        0.10, profile.shape)

    if tier == "High" then
        -- Add only four machined details per endpoint (36 total in High).
        -- These are close-range accents, not lights, beams or warning glyphs.
        for _, side in ipairs({-1, 1}) do
            add(side < 0 and "PortKnee" or "StarboardKnee",
                Vector3.new(0.28, 2.25, 0.43),
                CFrame.new(side * (spread - 0.55), top + 1.1, rear)
                    * CFrame.Angles(0, 0, side * math.rad(32)),
                muted, Enum.Material.Metal, 0.12)
        end
        for _, side in ipairs({-1, 1}) do
            add(side < 0 and "PortVane" or "StarboardVane",
                Vector3.new(1.05, 0.30, 1.4),
                CFrame.new(side * (spread * 0.5), top + mastHeight + 0.55, rear - 0.45)
                    * CFrame.Angles(0, side * math.rad(16), 0),
                signature:Lerp(steel, 0.55),
                Enum.Material.CorrodedMetal, 0.16)
        end
    end
    return made
end

return HarborOutpostKit
