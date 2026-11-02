--!strict
-- Original volumetric cladding of the four existing structural corner columns.
-- No remote meshes, fabricated asset IDs, physics, contacts or fake walkable
-- geometry. Native geometry is always available while licensed 2K PBR
-- MaterialVariants are owned by the existing camera-budgeted client selector.
local ArchitecturalCladding = {}

local MATERIALS = {
    Classic = {shell = Enum.Material.DiamondPlate, inset = Enum.Material.CorrodedMetal},
    Towers = {shell = Enum.Material.Foil, inset = Enum.Material.DiamondPlate},
    Crossroads = {shell = Enum.Material.CorrodedMetal, inset = Enum.Material.DiamondPlate},
    Orbital = {shell = Enum.Material.CeramicTiles, inset = Enum.Material.Foil},
    Harbor = {shell = Enum.Material.CorrodedMetal, inset = Enum.Material.DiamondPlate},
}

local function piece(model, origin, name, kind, size, frame, color, material, alpha)
    local p = Instance.new(kind)
    p.Name = name
    p.Size = size
    p.CFrame = origin * frame
    p.Color = color
    p.Material = material
    p.Transparency = alpha or 0
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = model
    return p
end

local function beam(model, origin, name, from, to, thick, tone, material)
    local delta = to - from
    return piece(model, origin, name, "Part",
        Vector3.new(thick, thick, delta.Magnitude),
        CFrame.lookAt((from + to) * 0.5, to), tone, material, 0.05)
end

function ArchitecturalCladding.build(decor, base, variantId, theme)
    if not decor or not base or not base:IsA("BasePart") then return 0 end
    local finish = MATERIALS[variantId]
    if not finish or not theme then return 0 end

    local group = Instance.new("Folder")
    group.Name = "OriginalPremiumColumnCladding"
    group.Parent = decor

    -- Match the four original FrameColumn1..4 centers from MapBuilder,
    -- rather than placing unrelated buildings in the active parkour path.
    local x, z = base.Size.X * 0.32, base.Size.Z * 0.32
    local corners = {
        Vector3.new(-x, 0, -z), Vector3.new(x, 0, -z),
        Vector3.new(-x, 0, z), Vector3.new(x, 0, z),
    }
    local count = 0
    for index, offset in ipairs(corners) do
        local casing = Instance.new("Model")
        casing.Name = variantId .. "ArchitecturalCasing" .. index
        casing:SetAttribute("OriginalFrameCladding", true)
        casing:SetAttribute("SourceIsOriginal", true)
        casing:SetAttribute("CosmeticOnly", true)
        casing:SetAttribute("FrameColumnIndex", index)
        casing.Parent = group

        local facing = (index == 1 or index == 4) and 1 or -1
        local origin = base.CFrame * CFrame.new(offset + Vector3.new(0, 4.2, 0))
            * CFrame.Angles(0, math.rad(45 * facing), 0)
        local shell = theme.Structure:Lerp(theme.Surface, 0.28)
        local dark = theme.Surface:Lerp(Color3.fromRGB(23, 29, 38), 0.38)
        local machined = theme.Detail:Lerp(theme.Structure, 0.48)

        -- Architectural mass, not a single unsupported straight cuboid.
        piece(casing, origin, "FoundationFoot", "Part",
            Vector3.new(5.5, 1.0, 5.5),
            CFrame.new(0, -3.55, 0), dark, finish.shell, 0.03)
        piece(casing, origin, "ArmoredFrontShell", "Part",
            Vector3.new(3.35, 6.4, 0.65),
            CFrame.new(0, 0, -1.7), shell, finish.shell, 0.04)
        piece(casing, origin, "ArmoredRearShell", "Part",
            Vector3.new(3.1, 5.7, 0.55),
            CFrame.new(0, 0.18, 1.65), machined, finish.inset, 0.05)
        for side = -1, 1, 2 do
            piece(casing, origin, "AngledArmorFin" .. tostring(side), "WedgePart",
                Vector3.new(1.35, 5.8, 2.0),
                CFrame.new(side * 2.05, -0.12, 0)
                    * CFrame.Angles(0, side * 0.14, 0),
                shell:Lerp(machined, 0.28), finish.inset, 0.05)
            beam(casing, origin, "DiagonalLoadSpar" .. tostring(side),
                Vector3.new(side * 2.2, -3.3, -1.15),
                Vector3.new(side * 0.85, 3.15, -1.15),
                0.36, machined, finish.shell)
        end
        piece(casing, origin, "MachinedUpperCollar", "Part",
            Vector3.new(5.9, 0.65, 5.0), CFrame.new(0, 4.15, 0),
            machined, finish.shell, 0.02)
        piece(casing, origin, "RecessedCrown", "Part",
            Vector3.new(4.5, 0.42, 3.8), CFrame.new(0, 4.58, 0),
            dark, finish.inset, 0.04)
        -- The arena-specific upper silhouette reads even at mobile distance.
        local reach = variantId == "Towers" and 8.8
            or (variantId == "Harbor" and 7.8 or 6.7)
        for side = -1, 1, 2 do
            beam(casing, origin, "AerialCantilever" .. tostring(side),
                Vector3.new(side * 1.1, 4.65, 0),
                Vector3.new(side * reach * 0.63, 6.4, -2.1),
                variantId == "Harbor" and 0.70 or 0.43,
                machined, finish.shell)
        end
        local crown = piece(casing, origin, "LandmarkNavigationHead", "Part",
            Vector3.new(1.55, 1.55, 1.55), CFrame.new(0, 6.8, 0),
            theme.Detail:Lerp(theme.Accent, 0.24),
            variantId == "Orbital" and Enum.Material.CeramicTiles
                or finish.shell, 0.06)
        crown.Shape = variantId == "Orbital"
            and Enum.PartType.Ball or Enum.PartType.Cylinder
        -- Fine mechanical seams remain reflective, but NEVER red/orange
        -- warning colors, blinking lights or a fake entry/exit cue.
        piece(casing, origin, "CrownInstrumentSpine", "Part",
            Vector3.new(2.4, 0.16, 0.28), CFrame.new(0, 5.1, -1.7),
            theme.Secondary:Lerp(theme.Detail, 0.55),
            Enum.Material.Metal, 0.18)
        count += #casing:GetChildren()
    end
    return count
end

return ArchitecturalCladding
