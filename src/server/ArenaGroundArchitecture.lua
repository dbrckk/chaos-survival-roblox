--!strict
-- Creator-authored 3D industrial deck finish for the REAL 320-stud arena.
-- Only decorative, thin, non-colliding sections: collision, warning telegraphs,
-- spawn pads, AI ground pathfinding and shrink geometry remain authoritative.
-- Original licensed MaterialService textures are selected by the existing
-- camera-budgeted PBR client. Floor details, cladding and underfloor girders
-- can reuse approved mesh profiles supplied by MapBuilder.
local RouteSignalGeometry = require("./RouteSignalGeometry")
local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
local presentationModule = shared and shared:FindFirstChild("ArenaPresentation")
local ArenaPresentation = if presentationModule then require(presentationModule)
    else require("../shared/ArenaPresentation")

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

local function part(decor, name, kind, frame, size, tone, material, alpha, pbr, meshProfile: MeshPart?, alongX: boolean?, groundBay: boolean?)
    local instance = RouteSignalGeometry.fit(meshProfile, frame, size, nil, alongX)
    if not instance then
        instance = Instance.new(kind)
        instance.Size = size
        instance.CFrame = frame
        instance.TopSurface = Enum.SurfaceType.Smooth
        instance.BottomSurface = Enum.SurfaceType.Smooth
    end
    instance.Name = name
    instance.Color = tone
    instance.Material = material
    instance.Transparency = alpha
    instance.Anchored = true
    instance.CanCollide = false
    instance.CanTouch = false
    instance.CanQuery = false
    instance.CastShadow = false
    if pbr then
        instance:SetAttribute("PremiumArchitecturalSurface", true)
    end
    if groundBay then
        instance:SetAttribute("OriginalGroundFinish", true)
        if instance:IsA("MeshPart") then
            instance:SetAttribute("Original3DAssetId", ArenaPresentation.GroundBayAssetId)
        end
    end
    instance.Parent = decor
    return instance
end

function ArenaGroundArchitecture.build(decor, base, variantId, theme, lattice: MeshPart?,
    sweptProfile: MeshPart?, castProfile: MeshPart?, bayProfile: MeshPart?)
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
    local finishY = top + ArenaPresentation.GroundBayCenter
    local baySize = Vector3.new(cellX - 1.2, ArenaPresentation.GroundBayThickness, cellZ - 1.2)
    local baySource = if bayProfile and bayProfile.MeshId ~= "" then bayProfile else nil
    -- The single closed bevel fits the square envelope. Retain the bay's
    -- axes so the local tile, thin PBR finish and shrink ledger align.
    local bayAlongX = baySource and baySource.Size.X > baySource.Size.Z
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
            part(decor,
                "PremiumGroundModule" .. index, "Part",
                origin * CFrame.new(x, finishY, z),
                baySize, finish, profile.panel, 0.035, true, baySource, bayAlongX, true)
            count += 1

            -- Recessed maintenance slot every third tile. Its tiny height
            -- cannot turn into a physical obstacle or false jumping hint.
            if (ix + iz) % 3 == 0 then
                local mark = theme.Detail:Lerp(theme.Structure, 0.46)
                part(decor, "PremiumGroundServiceInlay" .. index, "Part",
                    origin * CFrame.new(
                        x + cellX * 0.19, finishY + 0.024, z - cellZ * 0.16),
                    Vector3.new(cellX * 0.29, 0.016, 0.27),
                    mark, profile.detail, 0.14, false, sweptProfile)
                count += 1
            end

            -- Keep the cast corner mounts shallow and tied to their tile slot.
            if (ix + iz) % 4 == 0 then
                part(decor, "PremiumGroundGusset" .. index, "WedgePart",
                    origin * CFrame.new(
                        x - cellX * 0.33, finishY + 0.015,
                        z + cellZ * 0.32),
                    Vector3.new(2.4, 0.045, 2.4),
                    theme.Structure:Lerp(theme.Detail, 0.32),
                    profile.detail, 0.065, false, castProfile)
                count += 1
            end
        end
    end

    -- Original 6x6 modules stop 9.6 studs short of every physical edge.
    -- The previously exposed border was still the default-looking base.
    -- Close it with fitted metal/ceramic apron casings, flush with the
    -- existing original modules. No overhang beyond the authoritative
    -- collider and no extra material/texture allocation on Android.
    local innerX = base.Size.X - 19.2
    local innerZ = base.Size.Z - 19.2
    local apronX = (base.Size.X - innerX) * 0.5
    local apronZ = (base.Size.Z - innerZ) * 0.5
    local armorTone = theme.Surface:Lerp(theme.Detail, profile.tint + 0.06)
    local outerTone = theme.Structure:Lerp(theme.Detail, 0.38)
    for side = -1, 1, 2 do
        local x = side * (innerX * 0.5 + apronX * 0.5)
        local z = side * (innerZ * 0.5 + apronZ * 0.5)
        -- Keep the full-length castings inside the original flush apron envelope.
        part(decor, "PremiumGroundApronX" .. tostring(side), "Part",
            origin * CFrame.new(x, finishY, 0),
            Vector3.new(apronX - 0.08, 0.035, innerZ),
            armorTone, profile.panel, 0.035, false, sweptProfile)
        part(decor, "PremiumGroundApronZ" .. tostring(side), "Part",
            origin * CFrame.new(0, finishY, z),
            Vector3.new(innerX, 0.035, apronZ - 0.08),
            armorTone, profile.panel, 0.035, false, sweptProfile)
        count += 2
    end
    for sx = -1, 1, 2 do
        for sz = -1, 1, 2 do
            local cornerX = sx * (innerX * 0.5 + apronX * 0.5)
            local cornerZ = sz * (innerZ * 0.5 + apronZ * 0.5)
            part(decor, "PremiumGroundCorner" .. tostring(sx)
                    .. "_" .. tostring(sz), "Part",
                origin * CFrame.new(cornerX, finishY, cornerZ),
                Vector3.new(apronX - 0.08, 0.035, apronZ - 0.08),
                outerTone, profile.detail, 0.045, false, castProfile)
            count += 1
        end
    end

    -- Eight cross girders meet the undercarriage and end just inside the floor lip.
    local girderSize = Vector3.new(3.8, 1.2, 15)
    local inset = girderSize.Z * 0.5 + 0.15
    local insetX = base.Size.X * 0.5 - inset
    local insetZ = base.Size.Z * 0.5 - inset
    local girderY = -top - 2.2
    local girderTone = theme.Structure:Lerp(theme.Detail, 0.34)
    for axis = 1, 2 do
        for side = -1, 1, 2 do
            for slot = -1, 1, 2 do
                local along = slot * (axis == 1 and base.Size.Z or base.Size.X) * 0.27
                local frame = axis == 1
                    and CFrame.new(side * insetX, girderY, along)
                        * CFrame.Angles(0, math.rad(90), 0)
                    or CFrame.new(along, girderY, side * insetZ)
                local name = "PremiumGroundUndergirder" .. axis .. "_" .. side .. "_" .. slot
                local girder = RouteSignalGeometry.fit(lattice, origin * frame, girderSize)
                if girder then
                    girder.Name = name
                    girder.Color = girderTone
                    girder.Material = profile.detail
                    girder.Transparency = 0.06
                    girder.Parent = decor
                else
                    part(decor, name, "WedgePart", origin * (frame + Vector3.new(0, 0.3, 0)),
                        Vector3.new(girderSize.X, 2, girderSize.Z), girderTone, profile.detail, 0.06, false)
                end
                count += 1
            end
        end
    end

    return count
end

return ArenaGroundArchitecture
