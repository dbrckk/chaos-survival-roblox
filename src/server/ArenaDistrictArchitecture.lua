--!strict
-- Twelve creator-authored 3D district structures make the LARGE arena
-- readable at player height. Unlike a billboard facade, each has a
-- volumetric foundation, pitched metal, layered housing and a landmark top.
-- All pieces are inert scenery: no collisions, touch, queries, scripts,
-- physics ownership, particles or lights. Client LOD controls mobile cost.
local ArenaDistrictArchitecture = {}

local function element(model, origin, name, kind, size, localFrame, color, material)
    local piece = Instance.new(kind or "Part")
    piece.Name = name
    piece.Size = size
    piece.CFrame = origin * localFrame
    piece.Color = color
    piece.Material = material or Enum.Material.Metal
    piece.Anchored = true
    piece.CanCollide = false
    piece.CanTouch = false
    piece.CanQuery = false
    piece.CastShadow = false
    piece.Parent = model
    return piece
end

local function fixture(folder, base, variantId, theme, side, slot, number)
    local tangent = (slot - 2) * 92
    local outward = base.Size.X * 0.5 - 42
    local x, z, yaw
    if side == "North" then
        x, z, yaw = tangent, -outward, math.pi
    elseif side == "South" then
        x, z, yaw = tangent, outward, 0
    elseif side == "East" then
        x, z, yaw = outward, tangent, math.pi * 0.5
    else
        x, z, yaw = -outward, tangent, -math.pi * 0.5
    end

    local model = Instance.new("Model")
    model.Name = "District" .. side .. slot
    model:SetAttribute("ArenaDistrictArchitecture", true)
    model:SetAttribute("SourceIsOriginal", true)
    model:SetAttribute("CosmeticOnly", true)
    model:SetAttribute("DistrictIndex", number)
    local surface = base.Position.Y + base.Size.Y * 0.5
    local origin = CFrame.new(base.Position.X + x, surface,
        base.Position.Z + z) * CFrame.Angles(0, yaw, 0)
    local steel = theme.Structure:Lerp(theme.Detail, 0.23)
    local dark = theme.Structure:Lerp(Color3.fromRGB(11, 19, 30), 0.42)
    local alloy = theme.Detail:Lerp(theme.Secondary, 0.16)
    local accent = slot % 2 == 0 and theme.Secondary or theme.Accent

    local function make(name, kind, size, localFrame, color, material)
        return element(model, origin, name, kind, size, localFrame,
            color or steel, material)
    end

    -- Full 3D massing: recessed disc, four sculpted supports and an elevated
    -- roof. Narrow x/z footprint leaves generous escape and hazard lanes.
    make("BasaltFoundation", "Part", Vector3.new(0.7, 15.5, 15.5),
        CFrame.new(0, 0.35, 0) * CFrame.Angles(0, 0, math.pi / 2),
        dark, Enum.Material.Slate)
    make("FoundationRim", "Part", Vector3.new(0.22, 13.8, 13.8),
        CFrame.new(0, 0.77, 0) * CFrame.Angles(0, 0, math.pi / 2),
        alloy, Enum.Material.Metal)
    for _, direction in ipairs({-1, 1}) do
        local suffix = direction < 0 and "L" or "R"
        make("ArmoredSupport" .. suffix, "Part",
            Vector3.new(1.4, 12.6, 2.3),
            CFrame.new(direction * 4.4, 7.1, 1.8), steel)
        make("AngledRoof" .. suffix, "WedgePart",
            Vector3.new(4.3, 2.1, 6.0),
            CFrame.new(direction * 3.0, 13.3, -0.8)
                * CFrame.Angles(0, direction < 0 and math.pi or 0, 0), alloy)
        local vane = make("DataVane" .. suffix, "Part",
            Vector3.new(0.16, 4.7, 2.9),
            CFrame.new(direction * 5.25, 8.8, 1.5), accent,
            Enum.Material.Glass)
        vane.Transparency = 0.24
    end
    make("ServiceCore", "Part", Vector3.new(6.8, 7.3, 6.8),
        CFrame.new(0, 8.4, 0), dark)
    local window = make("RecessedSignal", "Part",
        Vector3.new(4.5, 2.8, 0.17), CFrame.new(0, 9.2, -3.5),
        accent, Enum.Material.Glass)
    window.Transparency = 0.32

    if variantId == "Towers" then
        -- Tall suspension head with an actual overhead transit cab.
        make("GantryArch", "Part", Vector3.new(12.5, 1.15, 1.9),
            CFrame.new(0, 18.5, 0), alloy)
        make("TransitCab", "Part", Vector3.new(4.5, 3.1, 3.5),
            CFrame.new(0, 16.4, -1), steel)
        make("TransitGlazing", "Part", Vector3.new(3.5, 1.1, 0.18),
            CFrame.new(0, 16.6, -2.83), accent, Enum.Material.Glass)
    elseif variantId == "Orbital" then
        local ring = make("HaloReceiver", "Part", Vector3.new(0.7, 9, 9),
            CFrame.new(0, 19, 0) * CFrame.Angles(0, 0, math.pi / 2),
            alloy)
        ring.Shape = Enum.PartType.Cylinder
        local heart = make("ReactorSphere", "Part", Vector3.new(4.2, 4.2, 4.2),
            CFrame.new(0, 19.8, 0), accent)
        heart.Shape = Enum.PartType.Ball
        make("ReactorCap", "WedgePart", Vector3.new(5.4, 2, 4),
            CFrame.new(0, 23.0, 0), dark)
    elseif variantId == "Crossroads" then
        make("SwitchArm", "Part", Vector3.new(13, 1.2, 2),
            CFrame.new(0, 18, 0) * CFrame.Angles(0, math.rad(18), 0), alloy)
        for _, direction in ipairs({-1, 1}) do
            make("SwitchPod" .. tostring(direction), "WedgePart",
                Vector3.new(3.1, 2.3, 3.8),
                CFrame.new(direction * 5, 19.5, 0)
                    * CFrame.Angles(0, direction < 0 and math.pi or 0, 0),
                accent)
        end
    else
        make("ObservatoryColumn", "Part", Vector3.new(2.6, 8, 2.6),
            CFrame.new(0, 18.7, 0), alloy)
        local lens = make("StormSensor", "Part", Vector3.new(5, 5, 5),
            CFrame.new(0, 23.9, 0), accent, Enum.Material.Glass)
        lens.Shape = Enum.PartType.Ball
        lens.Transparency = 0.18
        make("LightningTip", "Part", Vector3.new(0.45, 4.2, 0.45),
            CFrame.new(0, 28.3, 0), steel)
    end

    model.Parent = folder
    return model
end

function ArenaDistrictArchitecture.build(decor, base, variantId, theme)
    if not decor or not base or not base:IsA("BasePart")
        or type(variantId) ~= "string" or type(theme) ~= "table" then
        return nil
    end
    local folder = Instance.new("Folder")
    folder.Name = "ArenaDistrictArchitecture3D"
    folder:SetAttribute("CosmeticOnly", true)
    folder.Parent = decor

    local count = 0
    for _, side in ipairs({"North", "East", "South", "West"}) do
        for slot = 1, 3 do
            count += 1
            fixture(folder, base, variantId, theme, side, slot, count)
        end
    end
    folder:SetAttribute("District3DCount", count)
    return folder
end

return ArenaDistrictArchitecture
