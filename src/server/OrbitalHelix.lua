-- Eight inclined, physically traversable routes between the outer and
-- inner rings of Orbital. No moving collision or per-frame server physics.
local OrbitalHelix = {}

OrbitalHelix.Count = 8
OrbitalHelix.Width = 5.4

local function physicalPart(parent, name, size, cf, color, material, solid)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = material
    p.Anchored = true
    p.CanCollide = solid == true
    p.CanTouch = solid == true
    p.CanQuery = solid == true
    p.CastShadow = solid == true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

function OrbitalHelix.route(variant, center, index)
    if not variant or variant.Id ~= "Orbital"
        or type(index) ~= "number"
        or index < 1 or index > OrbitalHelix.Count then
        return nil
    end
    local outer = variant.Platforms[index]
    local inner = variant.Platforms[index + OrbitalHelix.Count]
    if not outer or not inner then return nil end
    local hub = typeof(center) == "Vector3" and center or Vector3.zero
    local start = hub + outer.offset
        + Vector3.new(0, outer.size.Y * 0.5 - 0.15, 0)
    local finish = hub + inner.offset
        + Vector3.new(0, inner.size.Y * 0.5 - 0.15, 0)
    local delta = finish - start
    if delta.Magnitude < 2 then return nil end
    local cf = CFrame.lookAt((start + finish) * 0.5, finish, Vector3.yAxis)
    return {
        CFrame = cf,
        Size = Vector3.new(OrbitalHelix.Width, 0.92, delta.Magnitude + 4.4),
        Start = start,
        Finish = finish,
    }
end

function OrbitalHelix.build(arena, variant, center, theme)
    if not arena or not variant or variant.Id ~= "Orbital"
        or typeof(center) ~= "Vector3" or not theme then
        return nil
    end
    local old = arena:FindFirstChild("HelixCircuit")
    if old then old:Destroy() end

    local folder = Instance.new("Folder")
    folder.Name = "HelixCircuit"
    folder.Parent = arena

    for index = 1, OrbitalHelix.Count do
        local route = OrbitalHelix.route(variant, center, index)
        if route then
            local bridge = physicalPart(
                folder, "HelixRamp" .. index,
                route.Size, route.CFrame,
                theme.Structure:Lerp(theme.Detail, 0.14),
                Enum.Material.DiamondPlate, true
            )
            bridge:SetAttribute("OrbitalHelixRamp", true)
            bridge:SetAttribute("HelixLane", index)

            local lip = physicalPart(
                folder, "HelixCenterGrain" .. index,
                Vector3.new(0.45, 0.06, route.Size.Z - 0.50),
                route.CFrame * CFrame.new(0, 0.51, 0),
                theme.Detail, Enum.Material.Metal, false
            )
            lip.Transparency = 0.38

            for side = -1, 1, 2 do
                local rail = physicalPart(
                    folder, "HelixEdgeSignal" .. index .. "_" .. side,
                    Vector3.new(0.14, 0.055, route.Size.Z - 0.35),
                    route.CFrame * CFrame.new(side * (route.Size.X * 0.5 - 0.21), 0.52, 0),
                    side < 0 and theme.Accent or theme.Secondary,
                    Enum.Material.Neon, false
                )
                rail.Transparency = 0.22

                local frame = physicalPart(
                    folder, "HelixUnderframe" .. index .. "_" .. side,
                    Vector3.new(0.34, 0.26, route.Size.Z - 0.70),
                    route.CFrame * CFrame.new(side * (route.Size.X * 0.5 - 0.45), -0.65, 0),
                    theme.Structure, Enum.Material.Metal, false
                )
                frame.Transparency = 0.08
            end

            for braceIndex = -1, 1 do
                local brace = physicalPart(
                    folder, "HelixSpineBrace" .. index .. "_" .. braceIndex,
                    Vector3.new(route.Size.X + 0.25, 0.23, 0.45),
                    route.CFrame * CFrame.new(0, -0.62, braceIndex * route.Size.Z * 0.28),
                    theme.Detail, Enum.Material.Metal, false
                )
                brace.Transparency = 0.22
            end
        end
    end

    return folder
end

return OrbitalHelix
