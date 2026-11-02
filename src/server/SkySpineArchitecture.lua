-- 200+ stud SKY SPINE interchange / five original 3D identities.
-- Every piece here is DECORATIVE. The real physical ten-deck route is
-- owned exclusively by ArenaVariants/MapBuilder and by ordinary player
-- collision; none of these pieces can create fake bridges or trap avatars.
local SkySpineArchitecture = {}

local function detail(decor, deck, index, name, size, cf, color, material, kind)
    local item = Instance.new(kind or "Part")
    item.Name = "SkySpine" .. index .. "_" .. name
    item.Size = size
    item.CFrame = deck.CFrame * cf
    item.Color = color
    item.Material = material or Enum.Material.Metal
    item.Anchored = true
    item.CanCollide = false
    item.CanTouch = false
    item.CanQuery = false
    item.CastShadow = false
    item.TopSurface = Enum.SurfaceType.Smooth
    item.BottomSurface = Enum.SurfaceType.Smooth
    item:SetAttribute("PerimeterPlatformIndex", index)
    item:SetAttribute("SkySpineDecor", true)
    item.Parent = decor
    return item
end

function SkySpineArchitecture.decorate(decor, deck, index, def, variant, theme)
    if not decor or not deck or not deck:IsA("BasePart")
        or type(def) ~= "table" or type(theme) ~= "table"
        or not def.SkySpineStep then return 0 end
    local step = def.SkySpineStep
    local top = deck.Size.Y * 0.5
    local accent = theme.Accent:Lerp(theme.Detail, 0.28)
    local secondary = theme.Secondary:Lerp(theme.Structure, 0.32)
    local metal = theme.Structure:Lerp(theme.Detail, 0.38)
    local count = 0
    local function add(name, size, cf, color, material, kind)
        count += 1
        return detail(decor, deck, index, name, size,
            cf, color, material, kind)
    end

    -- Actual cross-arena silhouette: repeated, thin surface borders and
    -- a mechanical underslung girder. All rails have zero collision.
    for side = -1, 1, 2 do
        local rail = add("LightedEdge" .. side,
            Vector3.new(0.26, 0.17, deck.Size.Z - 1.1),
            CFrame.new(side * (deck.Size.X * 0.5 - 0.32),
                top + 0.12, 0),
            side < 0 and accent or secondary, Enum.Material.Neon)
        rail.Transparency = 0.36
        add("Undercarriage" .. side,
            Vector3.new(0.66, 0.6, deck.Size.Z - 0.8),
            CFrame.new(side * 3.9, -top - 0.28, 0),
            metal, Enum.Material.CorrodedMetal)
    end
    add("CrossStiffener", Vector3.new(deck.Size.X + 0.6, 0.48, 0.64),
        CFrame.new(0, -top - 0.42, 0),
        secondary, Enum.Material.Metal)

    -- A rhythm of tall roof-height navigational frames makes the third
    -- high bridge recognizable from the 320x320 combat floor. Their
    -- pylons remain OUTSIDE the true 12-stud-wide walking footprint.
    if step == 2 or step == 5 or step == 6 or step == 9 then
        for side = -1, 1, 2 do
            add("MonumentalPylon" .. side,
                Vector3.new(1.5, 12.2, 1.7),
                CFrame.new(side * 8, top + 6.1, 0),
                metal, Enum.Material.Metal)
            add("SignalInlay" .. side,
                Vector3.new(0.30, 7.5, 0.42),
                CFrame.new(side * 8.5, top + 6.4, 0),
                accent, Enum.Material.Neon).Transparency = 0.24
        end
        add("InterchangeCrown", Vector3.new(17.2, 1.4, 2.5),
            CFrame.new(0, top + 13, 0), metal, Enum.Material.Metal)
        add("OverheadPulse", Vector3.new(13, 0.35, 0.7),
            CFrame.new(0, top + 12.7, -0.58),
            accent, Enum.Material.Neon).Transparency = 0.22
    end

    -- Five original sky-fortress signatures at the two centre decks,
    -- rather than the same unthemed recolored arch on every map.
    if step == 5 or step == 6 then
        if variant == "Classic" then
            local radar = add("CommandRadar",
                Vector3.new(0.8, 6.8, 6.8),
                CFrame.new(0, top + 17.0, 0)
                    * CFrame.Angles(0, 0, math.rad(24)),
                secondary, Enum.Material.Metal)
            radar.Shape = Enum.PartType.Cylinder
            add("SurveyBeacon", Vector3.new(1.7, 2.2, 1.7),
                CFrame.new(0, top + 18.1, -0.35),
                accent, Enum.Material.Glass)
        elseif variant == "Towers" then
            add("CargoOverpass", Vector3.new(14, 2.2, 3.7),
                CFrame.new(0, top + 17.3, 0),
                secondary, Enum.Material.DiamondPlate)
            add("HangingTransitCabin", Vector3.new(3.8, 3.8, 3.2),
                CFrame.new(0, top + 14.0, 0),
                accent, Enum.Material.Metal)
        elseif variant == "Crossroads" then
            for side = -1, 1, 2 do
                add("RoutingAileron" .. side,
                    Vector3.new(6.8, 2.1, 1.0),
                    CFrame.new(side * 4.1, top + 16.8, 0)
                        * CFrame.Angles(0, 0, math.rad(side * 26)),
                    accent, Enum.Material.Metal, "WedgePart")
            end
        elseif variant == "Orbital" then
            local reactor = add("OrbitalPowerOrb",
                Vector3.new(5.8, 5.8, 5.8),
                CFrame.new(0, top + 17.3, 0),
                accent, Enum.Material.Glass)
            reactor.Shape = Enum.PartType.Ball
            local gyroscope = add("OrbitRing",
                Vector3.new(0.55, 8.4, 8.4),
                CFrame.new(0, top + 17.3, 0)
                    * CFrame.Angles(0, 0, math.pi * 0.5),
                secondary, Enum.Material.CeramicTiles)
            gyroscope.Shape = Enum.PartType.Cylinder
        elseif variant == "Harbor" then
            add("DryDockHighCrane",
                Vector3.new(16, 1.7, 2.9),
                CFrame.new(3, top + 17.3, 0),
                secondary, Enum.Material.CorrodedMetal)
            add("CableLift", Vector3.new(0.36, 4.6, 0.36),
                CFrame.new(9.1, top + 14.2, 0),
                metal, Enum.Material.Metal)
            add("FreightPod", Vector3.new(4.1, 3.1, 3.5),
                CFrame.new(9.1, top + 10.4, 0),
                accent, Enum.Material.WoodPlanks)
        end
    end
    -- No light, particle emitter, RenderStepped listener or active physics.
    assert(count <= 14, "Sky Spine decorative part budget exceeded")
    return count
end

return SkySpineArchitecture
