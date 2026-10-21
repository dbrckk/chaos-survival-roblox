-- Eight inclined, physically traversable routes between the outer and
-- inner rings of Orbital. No moving collision or per-frame server physics.
local Players = game:GetService("Players")
local movementModule = script and script.Parent:FindFirstChild("MovementSafety")
local MovementSafety = if movementModule
    then require(movementModule) else require("./MovementSafety")
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


-- Physical access links make the eight outer decks and central reactor
-- playable without paid mobility or an unusually powerful avatar jump.
-- Entry starts ON the floor; core links start at the OUTER edge of each
-- inner deck. Endpoints meet the exact exposed edge of the solid target.
function OrbitalHelix.accessRoute(variant, center, index, kind)
    if not variant or variant.Id ~= "Orbital"
        or type(index) ~= "number"
        or index < 1 or index > OrbitalHelix.Count
        or (kind ~= "Entry" and kind ~= "Core")
    then return nil end
    local hub = typeof(center) == "Vector3" and center or Vector3.zero
    local outer = variant.Platforms[index]
    local inner = variant.Platforms[index + OrbitalHelix.Count]
    local crown = variant.Platforms[18]
    if not outer or not inner or not crown then return nil end

    local angle = math.rad((index - 1) * 45)
    local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
    local start, finish
    if kind == "Entry" then
        local reach = outer.size.X * 0.5
            / math.max(math.abs(outward.X), math.abs(outward.Z))
        local distance = Vector3.new(outer.offset.X, 0, outer.offset.Z).Magnitude
        local lip = distance + reach - 0.35
        if lip >= 46.5 then return nil end
        start = hub + outward * 47
            + Vector3.new(0, variant.BaseSize.Y * 0.5 - 0.35, 0)
        finish = hub + outward * lip
            + Vector3.new(0, outer.offset.Y + outer.size.Y * 0.5 - 0.35, 0)
    else
        -- The inner platforms rotate half a sector relative to the outer.
        local flat = Vector3.new(inner.offset.X, 0, inner.offset.Z)
        if flat.Magnitude < 0.1 then return nil end
        local axis = flat.Unit
        local extent = math.min(inner.size.X, inner.size.Z) * 0.5
            / math.max(math.abs(axis.X), math.abs(axis.Z))
        local innerDistance = flat.Magnitude
        local coreReach = math.min(crown.size.X, crown.size.Z) * 0.5
            / math.max(math.abs(axis.X), math.abs(axis.Z))
        start = hub + axis * (innerDistance + extent - 0.35)
            + Vector3.new(0, inner.offset.Y + inner.size.Y * 0.5 - 0.35, 0)
        finish = hub + axis * (coreReach - 0.35)
            + Vector3.new(0, crown.offset.Y + crown.size.Y * 0.5 - 0.35, 0)
    end
    local delta = finish - start
    if delta.Magnitude < 2 then return nil end
    return {
        CFrame = CFrame.lookAt((start + finish) * 0.5, finish, Vector3.yAxis),
        Size = Vector3.new(kind == "Entry" and 5.4 or 4.6, 0.92, delta.Magnitude + 0.65),
        Start = start,
        Finish = finish,
    }
end

local function buildAccessRamp(folder, route, index, kind, theme)
    if not route then return end
    local group = kind .. tostring(index)
    local entrance = kind == "Entry"
    local ramp = physicalPart(
        folder, kind .. "Ramp" .. index,
        route.Size, route.CFrame,
        theme.Structure:Lerp(theme.Detail, entrance and 0.20 or 0.40),
        Enum.Material.DiamondPlate, true
    )
    ramp:SetAttribute("OrbitRouteGroup", group)
    ramp:SetAttribute(entrance and "OrbitalAccessRamp" or "OrbitalCoreRamp", true)
    ramp:SetAttribute("HelixStart", route.Start)
    ramp:SetAttribute("HelixFinish", route.Finish)
    ramp:SetAttribute("OrbitalRouteTier", entrance and 1 or 4)

    for side = -1, 1, 2 do
        local sideLine = physicalPart(
            folder, kind .. "Signal" .. index .. "_" .. tostring(side),
            Vector3.new(0.16, 0.07, route.Size.Z - 0.24),
            route.CFrame * CFrame.new(
                side * (route.Size.X * 0.5 - 0.22), 0.49, 0
            ),
            side < 0 and theme.Accent or theme.Secondary,
            Enum.Material.Neon, false
        )
        sideLine.Transparency = entrance and 0.28 or 0.18
        sideLine:SetAttribute("OrbitRouteGroup", group)
    end

    local spine = physicalPart(
        folder, kind .. "Spine" .. index,
        Vector3.new(0.26, 0.07, route.Size.Z - 0.35),
        route.CFrame * CFrame.new(0, 0.50, 0),
        entrance and theme.Accent or theme.Secondary,
        Enum.Material.Neon, false
    )
    spine.Transparency = 0.5
    spine:SetAttribute("OrbitRouteGroup", group)

    local chassis = physicalPart(
        folder, kind .. "Chassis" .. index,
        Vector3.new(route.Size.X - 0.38, 0.22, route.Size.Z - 0.45),
        route.CFrame * CFrame.new(0, -0.58, 0),
        theme.Structure, Enum.Material.Metal, false
    )
    chassis.Transparency = 0.14
    chassis:SetAttribute("OrbitRouteGroup", group)
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
            bridge:SetAttribute("OrbitRouteGroup", "Helix" .. index)
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
            lip:SetAttribute("OrbitRouteGroup", "Helix" .. index)

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
                rail:SetAttribute("OrbitRouteGroup", "Helix" .. index)

                local frame = physicalPart(
                    folder, "HelixUnderframe" .. index .. "_" .. side,
                    Vector3.new(0.34, 0.26, route.Size.Z - 0.70),
                    route.CFrame * CFrame.new(side * (route.Size.X * 0.5 - 0.45), -0.65, 0),
                    theme.Structure, Enum.Material.Metal, false
                )
                frame.Transparency = 0.08
                frame:SetAttribute("HelixLane", index)
                frame:SetAttribute("OrbitRouteGroup", "Helix" .. index)
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
                brace:SetAttribute("OrbitRouteGroup", "Helix" .. index)
            end
        end
    end

    -- Entry, flow and final reactor spokes form one continuous set of
    -- physical routes. All are captured/restored by the same shrinking
    -- arena routine; cosmetic rails stay welded to each route's transform.
    for index = 1, OrbitalHelix.Count do
        buildAccessRamp(folder,
            OrbitalHelix.accessRoute(variant, center, index, "Entry"),
            index, "Entry", theme)
        buildAccessRamp(folder,
            OrbitalHelix.accessRoute(variant, center, index, "Core"),
            index, "Core", theme)
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
        if ramp:IsA("BasePart") and (
            ramp:GetAttribute("OrbitalHelixRamp") == true
            or ramp:GetAttribute("OrbitalAccessRamp") == true
            or ramp:GetAttribute("OrbitalCoreRamp") == true
        ) then
            local from = ramp:GetAttribute("HelixStart")
            local to = ramp:GetAttribute("HelixFinish")
            local group = ramp:GetAttribute("OrbitRouteGroup")
            if typeof(from) == "Vector3" and typeof(to) == "Vector3"
                and type(group) == "string" and group ~= ""
            then
                local entry = {
                    ramp = ramp,
                    from = from,
                    to = to,
                    originalCFrame = ramp.CFrame,
                    originalSize = ramp.Size,
                    padding = ramp.Size.Z - (to - from).Magnitude,
                    compact = ramp:GetAttribute("OrbitalHelixRamp") ~= true,
                    decorations = {},
                }
                for _, piece in ipairs(circuit:GetChildren()) do
                    if piece:IsA("BasePart") and piece ~= ramp
                        and piece:GetAttribute("OrbitRouteGroup") == group
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
            local length = (to - from).Magnitude + entry.padding
            local prior = entry.originalSize.Z
            local width = entry.compact
                and math.max(2.4, entry.originalSize.X * factor)
                or entry.originalSize.X
            local lateralScale = width / entry.originalSize.X
            ramp.CFrame = cf
            ramp.Size = Vector3.new(width, entry.originalSize.Y, length)

            for _, d in ipairs(entry.decorations) do
                if d.part and d.part.Parent then
                    local localCf = d.localCFrame
                    local p = localCf.Position
                    local rotationOnly = localCf - p
                    d.part.CFrame = cf
                        * CFrame.new(p.X * lateralScale, p.Y, p.Z * (length / prior))
                        * rotationOnly
                    local dz = d.originalSize.Z
                    -- Rails and spines extend with the ramp; short transverse
                    -- braces keep their engineered dimensions unchanged.
                    if dz > 2 then
                        dz = math.max(0.25, dz + length - prior)
                    end
                    d.part.Size = Vector3.new(
                        d.originalSize.X > 1
                            and d.originalSize.X * lateralScale or d.originalSize.X,
                        d.originalSize.Y, dz
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
OrbitalHelix.ChainWindow = 18
OrbitalHelix.ChainCap = 3

-- Orbital Pulse: two opposing ramps charge at once, changing every eight
-- seconds. All eight solid ramps stay walkable, even when not charged.
OrbitalHelix.PulsePairSeconds = 8
OrbitalHelix.PulseBoost = 7
OrbitalHelix.PulseSpeedCap = 42

-- Helix ramps are permanently traversable. Only the optional pulse bonus
-- is suspended in rounds where unrelated physics can force a crossing or
-- where a shove is hard to control on mobile.
local PULSE_CONFLICTS = {
    Tornado = true,
    JumpShock = true,
    Freeze = true,
    LowGravity = true,
    RisingLava = true,
    SpeedSurge = true,
}

function OrbitalHelix.pulseAllowed(ctx)
    if type(ctx) ~= "table" or ctx.EnableOrbitalPulse ~= true
        or type(ctx.Active) ~= "function"
        or type(ctx.OnCleanup) ~= "table"
    then return false end
    for name in pairs(ctx.ActiveDisasters or {}) do
        if PULSE_CONFLICTS[name] then return false end
    end
    return true
end

function OrbitalHelix.pulsePair(roundNumber, cycle)
    local round = math.max(1, math.floor(tonumber(roundNumber) or 1))
    local step = math.max(0, math.floor(tonumber(cycle) or 0))
    return ((round - 1 + step) % 4) + 1
end

function OrbitalHelix.pulseActive(lane, pair)
    local id = tonumber(lane)
    local selected = tonumber(pair)
    return id ~= nil and selected ~= nil
        and id % 1 == 0 and selected % 1 == 0
        and selected >= 1 and selected <= 4
        and (id == selected or id == selected + 4)
end

function OrbitalHelix.pulseVelocity(velocity, inward)
    if typeof(inward) ~= "Vector3" then return velocity end
    local flat = Vector3.new(inward.X, 0, inward.Z)
    if flat.Magnitude <= 0.01 then return velocity end
    return MovementSafety.addImpulse(
        velocity, flat.Unit * OrbitalHelix.PulseBoost,
        OrbitalHelix.PulseSpeedCap, -52, 58
    )
end

-- A new lane inside the time window advances a skill chain, while
-- revisiting the same ramp cannot farm consecutive mastery ranks.
-- State is held only for a round by startFlow and keyed weakly by rig.
function OrbitalHelix.advanceChain(last, lane, now)
    local index = tonumber(lane)
    local at = tonumber(now)
    if not index or index < 1 or index > OrbitalHelix.Count
        or index % 1 ~= 0 or not at
    then
        return {tier = 0, lane = 0, at = 0}
    end

    local previous = type(last) == "table" and last or nil
    local earlier = previous and tonumber(previous.at) or nil
    local previousLane = previous and tonumber(previous.lane) or nil
    local previousTier = previous and tonumber(previous.tier) or 0

    if earlier and at >= earlier
        and at - earlier <= OrbitalHelix.ChainWindow
        and previousLane == index
    then
        -- Same lane isn't a new skill achievement; refresh no timer.
        return {tier = math.clamp(previousTier, 1, OrbitalHelix.ChainCap),
            lane = index, at = earlier}
    end

    local tier = 1
    if earlier and at >= earlier and at - earlier <= OrbitalHelix.ChainWindow
        and previousLane ~= index
    then
        tier = math.min(OrbitalHelix.ChainCap, previousTier + 1)
    end

    return {tier = tier, lane = index, at = at}
end

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
    local lane = sensor:GetAttribute("HelixLane")
    local chainState = ctx.HelixChains
    local oldChain = type(chainState) == "table" and chainState[rig] or nil
    local newChain = OrbitalHelix.advanceChain(oldChain, lane, now)
    if newChain.tier == 0 then return false end
    local advanced = oldChain == nil or newChain.tier > oldChain.tier
        or newChain.at > (oldChain.at or 0)
    if type(chainState) == "table" then
        chainState[rig] = newChain
    end

    -- Pulse boosts are earned by an intentional inward crossing, only on
    -- the two currently charged lanes. Once per rig/lane per round prevents
    -- standing at a sensor and farming the acceleration or celebration.
    local pulsed = false
    if OrbitalHelix.pulseAllowed(ctx)
        and sensor:GetAttribute("HelixPulseActive") == true
        and type(ctx.HelixPulseClaims) == "table"
    then
        local claimed = ctx.HelixPulseClaims[rig]
        if not claimed or not claimed[lane] then
            if not claimed then
                claimed = {}
                ctx.HelixPulseClaims[rig] = claimed
            end
            claimed[lane] = true
            root.AssemblyLinearVelocity = OrbitalHelix.pulseVelocity(
                root.AssemblyLinearVelocity, sensor.CFrame.LookVector
            )
            pulsed = true
        end
    end

    -- The server owns the rank; replicated attributes drive the exact same
    -- celebration for nearby spectators and bots.
    sensor:SetAttribute("HelixFlowTier", newChain.tier)
    sensor:SetAttribute("HelixPulseAward", pulsed)
    sensor:SetAttribute("HelixFlowAt", workspace:GetServerTimeNow())
    if player then
        player:SetAttribute("RoundHelixFlowChain", newChain.tier)
        player:SetAttribute("RoundHelixFlowBest", math.max(
            tonumber(player:GetAttribute("RoundHelixFlowBest")) or 0,
            newChain.tier
        ))
        if ctx.OnArenaMechanicUsed and (advanced or pulsed) then
            local title = (newChain.tier == 3 and advanced)
                and "ORBIT MASTER"
                or (pulsed and "ORBIT PULSE"
                    or (newChain.tier == 2 and "HELIX CHAIN x2"
                        or "HELIX FLOW"))
            pcall(ctx.OnArenaMechanicUsed, player, "Orbital", title, false)
        end
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
    ctx.HelixChains = setmetatable({}, {__mode = "k"})
    local laneRamps = {}
    local laneSensors = {}

    for _, ramp in ipairs(circuit:GetChildren()) do
        if ramp:IsA("BasePart")
            and ramp:GetAttribute("OrbitalHelixRamp") == true
        then
            local trigger = Instance.new("Part")
            trigger.Name = "HelixFlowTrigger" .. tostring(
                ramp:GetAttribute("HelixLane") or "Unknown"
            )
            -- Weld to the solid ramp, so Shrinking Arena carries the
            -- invisible checkpoint with the moving/tilting Helix deck.
            trigger.Anchored = false
            trigger.Massless = true
            trigger.Transparency = 1
            trigger.CanCollide = false
            trigger.CanQuery = false
            trigger.CanTouch = true
            trigger.CastShadow = false
            trigger.Size = Vector3.new(ramp.Size.X + 1, 4.2, 2.6)
            trigger.CFrame = ramp.CFrame * CFrame.new(0, 2.1, 0)
            local lane = ramp:GetAttribute("HelixLane")
            trigger:SetAttribute("HelixLane", lane)
            trigger.Parent = folder
            if type(lane) == "number" then
                laneRamps[lane] = ramp
                laneSensors[lane] = trigger
            end
            local weld = Instance.new("WeldConstraint")
            weld.Name = "HelixFlowFollowRamp"
            weld.Part0 = ramp
            weld.Part1 = trigger
            weld.Parent = trigger
            trigger.Touched:Connect(function(hit)
                OrbitalHelix.tryFlow(ctx, trigger, hit, ready, os.clock())
            end)
        end
    end

    if OrbitalHelix.pulseAllowed(ctx)
        and #laneRamps == OrbitalHelix.Count
    then
        ctx.HelixPulseClaims = setmetatable({}, {__mode = "k"})
        local originalSignals = {}
        for _, part in ipairs(circuit:GetChildren()) do
            if part:IsA("BasePart")
                and type(part:GetAttribute("HelixLane")) == "number"
                and (part.Name:match("^HelixEdgeSignal")
                    or part.Name:match("^HelixCenterGrain"))
            then
                originalSignals[#originalSignals + 1] = {
                    part = part,
                    lane = part:GetAttribute("HelixLane"),
                    color = part.Color,
                    transparency = part.Transparency,
                }
            end
        end

        local alive = true
        local cycle = 0
        local gold = Color3.fromRGB(255, 205, 95)
        local function paint(pair)
            for lane = 1, OrbitalHelix.Count do
                local charged = OrbitalHelix.pulseActive(lane, pair)
                local ramp, sensor = laneRamps[lane], laneSensors[lane]
                if ramp and ramp.Parent then
                    ramp:SetAttribute("HelixPulseActive", charged)
                end
                if sensor and sensor.Parent then
                    sensor:SetAttribute("HelixPulseActive", charged)
                end
            end
            -- The original server-authored rail signals remain visible on
            -- Low-tier Android; no extra geometry, light or render loop.
            for _, entry in ipairs(originalSignals) do
                if entry.part.Parent then
                    local charged = OrbitalHelix.pulseActive(entry.lane, pair)
                    entry.part.Color = charged and gold or entry.color
                    entry.part.Transparency = charged
                        and math.min(entry.transparency, 0.08)
                        or entry.transparency
                end
            end
        end

        paint(OrbitalHelix.pulsePair(ctx.RoundNumber, cycle))
        ctx.OnCleanup[#ctx.OnCleanup + 1] = function()
            alive = false
            for lane = 1, OrbitalHelix.Count do
                if laneRamps[lane] and laneRamps[lane].Parent then
                    laneRamps[lane]:SetAttribute("HelixPulseActive", nil)
                end
                if laneSensors[lane] and laneSensors[lane].Parent then
                    laneSensors[lane]:SetAttribute("HelixPulseActive", nil)
                end
            end
            for _, entry in ipairs(originalSignals) do
                if entry.part.Parent then
                    entry.part.Color = entry.color
                    entry.part.Transparency = entry.transparency
                end
            end
        end
        task.spawn(function()
            while alive and ctx.Active() and circuit.Parent and folder.Parent do
                task.wait(OrbitalHelix.PulsePairSeconds)
                if not alive or not ctx.Active()
                    or not circuit.Parent or not folder.Parent then break end
                cycle += 1
                paint(OrbitalHelix.pulsePair(ctx.RoundNumber, cycle))
            end
        end)
    end

    return folder
end


return OrbitalHelix
