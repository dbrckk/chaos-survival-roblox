--!strict
-- Creator-authored 3D industrial deck finish for the REAL 320-stud arena.
-- Only decorative, thin, non-colliding sections: collision, warning telegraphs,
-- spawn pads, AI ground pathfinding and shrink geometry remain authoritative.
-- Original licensed MaterialService textures are selected by the existing
-- camera-budgeted PBR client; no external mesh/texture IDs are requested.
local ArenaGroundArchitecture = {}

local PROFILES = {
    Classic = {
        panel = Enum.Material.DiamondPlate,
        detail = Enum.Material.CorrodedMetal,
        tint = 0.53,
    },
    Towers = {
        panel = Enum.Material.Foil,
        detail = Enum.Material.DiamondPlate,
        tint = 0.55,
    },
    Crossroads = {
        panel = Enum.Material.CorrodedMetal,
        detail = Enum.Material.DiamondPlate,
        tint = 0.51,
    },
    Orbital = {
        panel = Enum.Material.CeramicTiles,
        detail = Enum.Material.Foil,
        tint = 0.57,
    },
    Harbor = {
        panel = Enum.Material.CorrodedMetal,
        detail = Enum.Material.DiamondPlate,
        tint = 0.55,
    },
}

local function part(decor, name, kind, frame, size, tone, material, alpha, pbr)
    local instance = Instance.new(kind)
    instance.Name = name
    instance.Size = size
    instance.CFrame = frame
    instance.Color = tone
    instance.Material = material
    instance.Transparency = alpha
    instance.Anchored = true
    instance.CanCollide = false
    instance.CanTouch = false
    instance.CanQuery = false
    instance.CastShadow = false
    instance.TopSurface = Enum.SurfaceType.Smooth
    instance.BottomSurface = Enum.SurfaceType.Smooth
    if pbr then
        instance:SetAttribute("PremiumArchitecturalSurface", true)
    end
    instance.Parent = decor
    return instance
end

function ArenaGroundArchitecture.build(decor, base, variantId, theme)
    if not decor or not base or not base:IsA("BasePart") or not theme then
        return 0
    end
    local profile = PROFILES[variantId]
    if not profile then return 0 end
    if base.Size.X < 160 or base.Size.Z < 160 then return 0 end

    -- Six broad *original* material panels per axis replace the single
    -- featureless floor in close views. A fixed 9-stud inset from the real
    -- base edge and 1.2-stud low-contrast joints prevent phantom walkways.
    -- Old arena labels and chevrons are at y ~= physicalTop+0.19/0.20;
    -- this thin surface finishes at +0.171, BELOW their visible top faces.
    local rows = 6
    local cellX = (base.Size.X - 18) / rows
    local cellZ = (base.Size.Z - 18) / rows
    local top = base.Size.Y * 0.5
    local finishY = top + 0.153
    local origin = base.CFrame
    local count = 0
    for ix = 1, rows do
        for iz = 1, rows do
            local index = (ix - 1) * rows + iz
            local x = (ix - (rows + 1) * 0.5) * cellX
            local z = (iz - (rows + 1) * 0.5) * cellZ
            local offset = (ix * 7 + iz * 11) % 5
            -- Near-midtone finish. Avoid red/orange disaster warning colors,
            -- mirror-like neon, distracting checkerboard or a dark floor.
            local finish = theme.Surface:Lerp(
                theme.Detail, profile.tint + (offset - 2) * 0.018)
            local tile = part(decor,
                "PremiumGroundModule" .. index, "Part",
                origin * CFrame.new(x, finishY, z),
                Vector3.new(cellX - 1.2, 0.035, cellZ - 1.2),
                finish, profile.panel, 0.035, true)
            tile:SetAttribute("OriginalGroundFinish", true)
            count += 1

            -- Recessed maintenance slot every third tile. Its tiny height
            -- cannot turn into a physical obstacle or false jumping hint.
            if (ix + iz) % 3 == 0 then
                local mark = theme.Detail:Lerp(theme.Structure, 0.46)
                part(decor, "PremiumGroundServiceInlay" .. index, "Part",
                    origin * CFrame.new(
                        x + cellX * 0.19, finishY + 0.024, z - cellZ * 0.16),
                    Vector3.new(cellX * 0.29, 0.016, 0.27),
                    mark, profile.detail, 0.14, false)
                count += 1
            end

            -- Three-dimensional, flush, angled corner mounts on only one
            -- tile per four. An original WedgePart breaks the blockout
            -- silhouette without creating a walkable raised surface.
            if (ix + iz) % 4 == 0 then
                part(decor, "PremiumGroundGusset" .. index, "WedgePart",
                    origin * CFrame.new(
                        x - cellX * 0.33, finishY + 0.015,
                        z + cellZ * 0.32),
                    Vector3.new(2.4, 0.045, 2.4),
                    theme.Structure:Lerp(theme.Detail, 0.32),
                    profile.detail, 0.065, false)
                count += 1
            end
        end
    end

    -- Eight structural fins cut real depth into the already existing
    -- undercarriage silhouette. They are BELOW the real survival floor,
    -- not a new deck, railing, collider or false supported route.
    local insetX = base.Size.X * 0.5 - 2.8
    local insetZ = base.Size.Z * 0.5 - 2.8
    for axis = 1, 2 do
        for side = -1, 1, 2 do
            for slot = -1, 1, 2 do
                local along = slot * (axis == 1 and base.Size.Z or base.Size.X) * 0.27
                local frame = axis == 1
                    and CFrame.new(side * insetX, -2.9, along)
                        * CFrame.Angles(0, math.rad(90), 0)
                    or CFrame.new(along, -2.9, side * insetZ)
                part(decor,
                    "PremiumGroundUndergirder" .. axis .. "_"
                        .. tostring(side) .. "_" .. tostring(slot),
                    "WedgePart", origin * frame,
                    Vector3.new(3.8, 2.0, 15.0),
                    theme.Structure:Lerp(theme.Detail, 0.34),
                    profile.detail, 0.06, false)
                count += 1
            end
        end
    end

    return count
end

return ArenaGroundArchitecture
