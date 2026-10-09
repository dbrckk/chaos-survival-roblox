-- Eight inclined, physically traversable routes between the outer and
-- inner rings of Orbital. No moving collision or per-frame server physics.
local Players = game:GetService("Players")
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
            bridge:SetAttribute("HelixStart", route.Start)
            bridge:SetAttribute("HelixFinish", route.Finish)

            local lip = physicalPart(
                folder, "HelixCenterGrain" .. index,
                Vector3.new(0.45, 0.06, route.Size.Z - 0.50),
                route.CFrame * CFrame.new(0, 0.51, 0),
                theme.Detail, Enum.Material.Metal, false
            )
            lip.Transparency = 0.38
            lip:SetAttribute("HelixLane", index)

            for side = -1, 1, 2 do
                local rail = physicalPart(
                    folder, "HelixEdgeSignal" .. index .. "_" .. side,
                    Vector3.new(0.14, 0.055, route.Size.Z - 0.35),
                    route.CFrame * CFrame.new(side * (route.Size.X * 0.5 - 0.21), 0.52, 0),
                    side < 0 and theme.Accent or theme.Secondary,
                    Enum.Material.Neon, false
                )
                rail.Transparency = 0.22
                rail:SetAttribute("HelixLane", index)

                local frame = physicalPart(
                    folder, "HelixUnderframe" .. index .. "_" .. side,
                    Vector3.new(0.34, 0.26, route.Size.Z - 0.70),
                    route.CFrame * CFrame.new(side * (route.Size.X * 0.5 - 0.45), -0.65, 0),
                    theme.Structure, Enum.Material.Metal, false
                )
                frame.Transparency = 0.08
                frame:SetAttribute("HelixLane", index)
            end

            for braceIndex = -1, 1 do
                local brace = physicalPart(
                    folder, "HelixSpineBrace" .. index .. "_" .. braceIndex,
                    Vector3.new(route.Size.X + 0.25, 0.23, 0.45),
                    route.CFrame * CFrame.new(0, -0.62, braceIndex * route.Size.Z * 0.28),
                    theme.Detail, Enum.Material.Metal, false
                )
                brace.Transparency = 0.22
                brace:SetAttribute("HelixLane", index)
            end
        end
    end

    return folder
end


-- Snapshot the complete engineered circuit once per shrinking round.
-- Relative coordinates preserve every light rail, rib and inset while the
-- solid inclined ramp changes length and tilt to follow its two decks.
function OrbitalHelix.capture(circuit)
    local snapshot = {}
    if not circuit then return snapshot end
    for _, ramp in ipairs(circuit:GetChildren()) do
        if ramp:IsA("BasePart") and ramp:GetAttribute("OrbitalHelixRamp") == true then
            local from = ramp:GetAttribute("HelixStart")
            local to = ramp:GetAttribute("HelixFinish")
            local lane = ramp:GetAttribute("HelixLane")
            if typeof(from) == "Vector3" and typeof(to) == "Vector3"
                and type(lane) == "number"
            then
                local entry = {
                    ramp = ramp,
                    from = from,
                    to = to,
                    originalCFrame = ramp.CFrame,
                    originalSize = ramp.Size,
                    decorations = {},
                }
                for _, piece in ipairs(circuit:GetChildren()) do
                    if piece:IsA("BasePart") and piece ~= ramp
                        and piece:GetAttribute("HelixLane") == lane
                    then
                        table.insert(entry.decorations, {
                            part = piece,
                            originalCFrame = piece.CFrame,
                            originalSize = piece.Size,
                            localCFrame = ramp.CFrame:ToObjectSpace(piece.CFrame),
                        })
                    end
                end
                table.insert(snapshot, entry)
            end
        end
    end
    return snapshot
end

function OrbitalHelix.scale(snapshot, center, amount)
    if typeof(center) ~= "Vector3" then return end
    local factor = math.clamp(tonumber(amount) or 1, 0.05, 1)
    local function move(point)
        local d = point - center
        return center + Vector3.new(d.X * factor, d.Y, d.Z * factor)
    end

    for _, entry in ipairs(snapshot or {}) do
        local ramp = entry.ramp
        if ramp and ramp.Parent then
            local from = move(entry.from)
            local to = move(entry.to)
            local cf = CFrame.lookAt((from + to) * 0.5, to, Vector3.yAxis)
            local length = (to - from).Magnitude + 4.4
            local prior = entry.originalSize.Z
            ramp.CFrame = cf
            ramp.Size = Vector3.new(entry.originalSize.X, entry.originalSize.Y, length)

            for _, d in ipairs(entry.decorations) do
                if d.part and d.part.Parent then
                    local localCf = d.localCFrame
                    local p = localCf.Position
                    local rotationOnly = localCf - p
                    d.part.CFrame = cf
                        * CFrame.new(p.X, p.Y, p.Z * (length / prior))
                        * rotationOnly
                    local dz = d.originalSize.Z
                    -- Rails and spines extend with the ramp; short transverse
                    -- braces keep their engineered dimensions unchanged.
                    if dz > 2 then
                        dz = math.max(0.25, dz + length - prior)
                    end
                    d.part.Size = Vector3.new(
                        d.originalSize.X, d.originalSize.Y, dz
                    )
                end
            end
        end
    end
end

function OrbitalHelix.restore(snapshot)
    for _, entry in ipairs(snapshot or {}) do
        if entry.ramp and entry.ramp.Parent then
            entry.ramp.Size = entry.originalSize
            entry.ramp.CFrame = entry.originalCFrame
        end
        for _, d in ipairs(entry.decorations) do
            if d.part and d.part.Parent then
                d.part.Size = d.originalSize
                d.part.CFrame = d.originalCFrame
            end
        end
    end
end


-- HELIX FLOW: a traversal skill cue, not an automated movement power.
-- The server acknowledges intentional inward crossings. No coins, damage,
-- speed boost, asset requirement, or client-provided success event.
OrbitalHelix.FlowCooldown = 4.2

function OrbitalHelix.inwardFlow(velocity, look)
    if typeof(velocity) ~= "Vector3" or typeof(look) ~= "Vector3" then
        return false
    end
    local v = Vector3.new(velocity.X, 0, velocity.Z)
    local inward = Vector3.new(look.X, 0, look.Z)
    if inward.Magnitude < 0.01 then return false end
    return v:Dot(inward.Unit) >= 8
end

local function rigFromHit(hit)
    local node = hit
    while node and node ~= workspace do
        if node:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(node)
            local bot = node:GetAttribute("AISurvivor") == true
                and node:GetAttribute("AISurvivorInRound") == true
            if player or bot then
                local hum = node:FindFirstChildOfClass("Humanoid")
                local root = node:FindFirstChild("HumanoidRootPart")
                if hum and root and root:IsA("BasePart") then
                    return node, hum, root, player, bot
                end
                return nil
            end
        end
        node = node.Parent
    end
    return nil
end

function OrbitalHelix.tryFlow(ctx, sensor, hit, ready, now)
    if not sensor or not sensor.Parent or not ctx
        or type(ctx.Active) ~= "function" or not ctx.Active()
    then
        return false
    end

    local rig, hum, root, player, bot = rigFromHit(hit)
    if not rig or hum.Health <= 0 then return false end
    local eligible = bot == true or (player ~= nil
        and type(ctx.IsContestantActive) == "function"
        and ctx.IsContestantActive(player) == true)
    if not eligible or (ready[rig] or -math.huge) > now then
        return false
    end

    local delta = sensor.CFrame:PointToObjectSpace(root.Position)
    if math.abs(delta.X) > sensor.Size.X * 0.5 + 0.8
        or math.abs(delta.Y) > sensor.Size.Y * 0.5 + 0.8
        or math.abs(delta.Z) > sensor.Size.Z * 0.5 + 1.1
        or not OrbitalHelix.inwardFlow(
            root.AssemblyLinearVelocity, sensor.CFrame.LookVector
        )
    then
        return false
    end

    ready[rig] = now + OrbitalHelix.FlowCooldown
    -- A replicated single-source hit timestamp supports client visuals for
    -- humans and bots without broadcasting an arbitrary client event.
    sensor:SetAttribute("HelixFlowAt", workspace:GetServerTimeNow())
    if player and ctx.OnArenaMechanicUsed then
        pcall(ctx.OnArenaMechanicUsed, player, "Orbital", "HELIX FLOW", false)
    end
    return true
end

function OrbitalHelix.startFlow(ctx, mechanics, arena)
    local circuit = arena and arena:FindFirstChild("HelixCircuit")
    if not mechanics or not circuit then return nil end
    local folder = Instance.new("Folder")
    folder.Name = "HelixFlow"
    folder.Parent = mechanics
    local ready = setmetatable({}, {__mode = "k"})

    for _, ramp in ipairs(circuit:GetChildren()) do
        if ramp:IsA("BasePart")
            and ramp:GetAttribute("OrbitalHelixRamp") == true
        then
            local trigger = Instance.new("Part")
            trigger.Name = "HelixFlowTrigger" .. tostring(
                ramp:GetAttribute("HelixLane") or "Unknown"
            )
            trigger.Anchored = true
            trigger.Transparency = 1
            trigger.CanCollide = false
            trigger.CanQuery = false
            trigger.CanTouch = true
            trigger.CastShadow = false
            trigger.Size = Vector3.new(ramp.Size.X + 1, 4.2, 2.6)
            trigger.CFrame = ramp.CFrame * CFrame.new(0, 2.1, 0)
            trigger:SetAttribute("HelixLane", ramp:GetAttribute("HelixLane"))
            trigger.Parent = folder
            trigger.Touched:Connect(function(hit)
                OrbitalHelix.tryFlow(ctx, trigger, hit, ready, os.clock())
            end)
        end
    end
    return folder
end


return OrbitalHelix
