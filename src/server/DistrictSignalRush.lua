--!strict
-- District signal rush: a server-authoritative, optional moving objective.
-- Two different outside sectors activate at different moments each veteran
-- round. Claiming a signal requires visiting it in person (touch/keyboard/
-- gamepad ProximityPrompt), not a client-supplied position or remote request.
-- Each player can win at most one modest signal reward per round.
local Players = game:GetService("Players")

local DistrictSignalRush = {}

DistrictSignalRush.Reward = 2
DistrictSignalRush.Range = 10
DistrictSignalRush.StartDelay = 4
DistrictSignalRush.Window = 12
DistrictSignalRush.BetweenWaves = 5

local ROUTE_SIGNS = {
    {-1, -1}, {1, -1}, {-1, 1}, {1, 1},
}

local ROUTE_COLORS = {
    Color3.fromRGB(100, 211, 245),
    Color3.fromRGB(255, 199, 90),
    Color3.fromRGB(185, 146, 255),
    Color3.fromRGB(110, 245, 178),
}

function DistrictSignalRush.allowed(ctx, base)
    return type(ctx) == "table"
        and ctx.EnableDistrictSignals == true
        and type(ctx.Active) == "function"
        and ctx.Active() == true
        and type(ctx.IsContestantActive) == "function"
        and type(ctx.OnDistrictSignalClaimed) == "function"
        and (tonumber(ctx.RoundSeconds) or 0) >= 28
        and typeof(base) == "Instance" and base:IsA("BasePart")
        and math.min(base.Size.X, base.Size.Z) >= 280
        and not (ctx.ActiveDisasters
            and ctx.ActiveDisasters.ShrinkingArena == true)
end

local function part(model, name, size, cf, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Color = color
    p.Material = material or Enum.Material.Metal
    p.Parent = model
    return p
end

local function construct(folder, base, route, variantId)
    local signs = ROUTE_SIGNS[route]
    local color = ROUTE_COLORS[route]
    local groundY = base.Position.Y + base.Size.Y * 0.5
    -- Kept away from raised branch decks (around X=100, Z=50-110),
    -- and beyond the south/north transit gates (X=123, Z=113).
    local center = Vector3.new(
        base.Position.X + signs[1] * (base.Size.X * 0.5 - 23),
        groundY,
        base.Position.Z + signs[2] * (base.Size.Z * 0.5 - 77)
    )
    local frame = CFrame.new(center)
    local model = Instance.new("Model")
    model.Name = "SignalStation" .. tostring(route)
    model:SetAttribute("DistrictSignalStation", true)
    model:SetAttribute("SignalRoute", route)
    model:SetAttribute("SignalActive", false)
    model:SetAttribute("SignalClaimed", false)
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model.Parent = folder

    local dark = Color3.fromRGB(24, 40, 59)
    local alloy = Color3.fromRGB(91, 117, 139)
    part(model, "Foundation", Vector3.new(7.4, 0.42, 7.4),
        frame * CFrame.new(0, 0.21, 0), dark)
    part(model, "Housing", Vector3.new(4.4, 3.2, 4.4),
        frame * CFrame.new(0, 1.9, 0), alloy)
    for side = -1, 1, 2 do
        part(model, "AntennaLeg" .. tostring(side),
            Vector3.new(0.65, 8.8, 0.65),
            frame * CFrame.new(side * 2.35, 5.6, 0), dark)
        part(model, "SignalFin" .. tostring(side),
            Vector3.new(2.8, 0.40, 1.3),
            frame * CFrame.new(side * 2.15, 9.45, 0), alloy)
    end
    local emitter = part(model, "PulseCore",
        Vector3.new(2.8, 2.8, 2.8),
        frame * CFrame.new(0, 8.9, 0),
        color, Enum.Material.Neon)
    emitter.Shape = Enum.PartType.Ball
    emitter.Transparency = 0.68
    local pole = part(model, "BeaconSpine",
        Vector3.new(0.65, 6.8, 0.65),
        frame * CFrame.new(0, 5.6, 0), dark)

    -- Four arena families use different original silhouettes, not
    -- recolored copies. Geometry stays entirely decorative and below
    -- the 3D/Android detail budget: no lights or animated physics.
    if variantId == "Classic" then
        local dish = part(model, "WeatherReceiver",
            Vector3.new(0.7, 5.6, 5.6),
            frame * CFrame.new(0, 13, 0)
                * CFrame.Angles(0, 0, math.rad(25)),
            alloy)
        dish.Shape = Enum.PartType.Cylinder
        local eye = part(model, "StormEye",
            Vector3.new(1.7, 1.7, 1.7),
            frame * CFrame.new(0, 13.2, -0.60),
            color, Enum.Material.Glass)
        eye.Shape = Enum.PartType.Ball
        eye.Transparency = 0.20
    elseif variantId == "Towers" then
        part(model, "SuspensionGantry",
            Vector3.new(10.2, 1.15, 3.1),
            frame * CFrame.new(0, 12.2, 0), alloy)
        part(model, "TransitSignalCab",
            Vector3.new(4.6, 2.8, 3.0),
            frame * CFrame.new(0, 14.3, 0), dark)
        local pane = part(model, "CabinWindow",
            Vector3.new(3.8, 1.2, 0.19),
            frame * CFrame.new(0, 14.4, -1.6),
            color, Enum.Material.Glass)
        pane.Transparency = 0.27
    elseif variantId == "Crossroads" then
        for side = -1, 1, 2 do
            part(model, "ExchangeBlade" .. tostring(side),
                Vector3.new(3.0, 5.8, 1.1),
                frame * CFrame.new(side * 3.25, 12.7, 0)
                    * CFrame.Angles(0, math.rad(18 * side), 0),
                alloy)
        end
        part(model, "RoutingHeader",
            Vector3.new(9.5, 0.85, 1.6),
            frame * CFrame.new(0, 16.0, 0),
            color)
    elseif variantId == "Orbital" then
        local radius, segments = 4.3, 8
        for index = 1, segments do
            local a1 = 2 * math.pi * (index - 1) / segments
            local a2 = 2 * math.pi * index / segments
            local first = Vector3.new(math.cos(a1) * radius,
                14 + math.sin(a1) * radius, 0)
            local second = Vector3.new(math.cos(a2) * radius,
                14 + math.sin(a2) * radius, 0)
            local length = (second - first).Magnitude
            part(model, "ReceiverHaloSegment" .. index,
                Vector3.new(0.55, length, 0.55),
                frame * CFrame.lookAt((first + second) * 0.5, second)
                    * CFrame.Angles(math.pi * 0.5, 0, 0),
                alloy)
        end
    end

    -- Temporary luminous floor guidance connects the REAL outer
    -- transit arrival to this signal. Inactive cues are almost invisible
    -- to avoid drawing players toward a dormant optional objective.
    local from = Vector3.new(
        base.Position.X + signs[1] * (base.Size.X * 0.5 - 37),
        groundY + 0.08,
        base.Position.Z + signs[2] * (base.Size.Z * 0.5 - 47)
    )
    local planar = Vector3.new(center.X - from.X, 0, center.Z - from.Z)
    local direction = planar.Unit
    local arrows = {}
    for step = 1, 3 do
        local marker = from + planar * (step / 4)
        local facing = CFrame.lookAt(marker, marker + direction)
        for side = -1, 1, 2 do
            local cue = part(model,
                "LiveRouteChevron" .. step .. "_" .. tostring(side),
                Vector3.new(0.25, 0.07, 2.15),
                facing * CFrame.new(side * 0.48, 0, 0)
                    * CFrame.Angles(0, math.rad(side * 34), 0),
                color, Enum.Material.Neon)
            cue.Transparency = 0.94
            arrows[#arrows + 1] = cue
        end
    end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "SecureDistrictSignal"
    prompt.ActionText = "SECURE +2 COINS"
    prompt.ObjectText = "OPTIONAL SIGNAL"
    prompt.HoldDuration = 0.32
    prompt.MaxActivationDistance = DistrictSignalRush.Range
    prompt.RequiresLineOfSight = false
    prompt.Enabled = false
    prompt.Parent = pole

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SignalObjective"
    billboard.Adornee = emitter
    billboard.Size = UDim2.fromOffset(200, 48)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.7, 0)
    billboard.MaxDistance = 145
    billboard.AlwaysOnTop = false
    billboard.Enabled = false
    billboard.Parent = emitter

    local label = Instance.new("TextLabel")
    label.Name = "SignalStatus"
    label.BackgroundColor3 = dark
    label.BackgroundTransparency = 0.13
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.Size = UDim2.fromScale(1, 1)
    label.TextColor3 = color
    label.Text = "ACTIVE SIGNAL\nOPTIONAL +2 COINS"
    label.Parent = billboard
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = label
    local border = Instance.new("UIStroke")
    border.Color = color
    border.Thickness = 1.5
    border.Parent = label

    local function setActive(active, claimed, wave)
        model:SetAttribute("SignalActive", active)
        model:SetAttribute("SignalClaimed", claimed == true)
        model:SetAttribute("SignalWave", wave or 0)
        emitter.Transparency = active and 0.05 or 0.68
        for _, cue in ipairs(arrows) do
            cue.Transparency = active and 0.18 or 0.94
        end
        billboard.Enabled = active
        prompt.Enabled = active
    end

    return {
        model = model,
        prompt = prompt,
        spine = pole,
        core = emitter,
        setActive = setActive,
        route = route,
    }
end

function DistrictSignalRush.start(ctx)
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not DistrictSignalRush.allowed(ctx, base) then
        return 0
    end

    local previous = arena:FindFirstChild("DistrictSignalRush")
    if previous then previous:Destroy() end
    local folder = Instance.new("Folder")
    folder.Name = "DistrictSignalRush"
    folder:SetAttribute("SignalReward", DistrictSignalRush.Reward)
    folder:SetAttribute("SignalRoute", 0)
    folder:SetAttribute("SignalWave", 0)
    folder.Parent = arena
    table.insert(ctx.Cleanup, folder)

    local nodes = {}
    local variantId = tostring(arena:GetAttribute("VariantId") or "Classic")
    for route = 1, 4 do
        nodes[route] = construct(folder, base, route, variantId)
    end

    local claimedPlayers = {}
    local activeNode = nil
    local activeClaimed = false
    local waveIndex = 0

    for _, node in ipairs(nodes) do
        node.prompt.Triggered:Connect(function(player)
            if not ctx.Active() or ctx.FinalRush and ctx.FinalRush()
                or activeNode ~= node or activeClaimed
                or not player or player.Parent ~= Players
                or player:GetAttribute("DataLoaded") ~= true
                or claimedPlayers[player.UserId]
                or not ctx.IsContestantActive(player)
            then return end
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not humanoid or humanoid.Health <= 0
                or humanoid.SeatPart ~= nil
                or not root or not root:IsA("BasePart")
                or (root.Position - node.spine.Position).Magnitude
                    > DistrictSignalRush.Range + 3
            then return end

            -- Claim before calling payout, protecting against repeated
            -- server prompt events while a persistence operation yields.
            activeClaimed = true
            claimedPlayers[player.UserId] = true
            node.setActive(false, true, waveIndex)
            folder:SetAttribute("SignalRoute", 0)
            local ok, paid = pcall(
                ctx.OnDistrictSignalClaimed,
                player, DistrictSignalRush.Reward,
                node.core.Position, node.route, waveIndex
            )
            if not ok or paid ~= true then
                claimedPlayers[player.UserId] = nil
                -- If payout fails, never grant another claim on the same
                -- station: a partially committed transaction must not
                -- trigger a second write or duplicate player rewards.
                warn("District signal payout was not confirmed:", paid)
            end
        end)
    end

    local first = math.random(1, 4)
    local second = ((first + math.random(1, 3) - 1) % 4) + 1
    task.spawn(function()
        for wave, route in ipairs({first, second}) do
            task.wait(wave == 1 and DistrictSignalRush.StartDelay
                or DistrictSignalRush.BetweenWaves)
            if not folder.Parent or not ctx.Active()
                or ctx.FinalRush and ctx.FinalRush()
            then break end
            waveIndex = wave
            activeClaimed = false
            local node = nodes[route]
            activeNode = node
            node.setActive(true, false, wave)
            folder:SetAttribute("SignalRoute", route)
            folder:SetAttribute("SignalWave", wave)

            -- Exactly two brief active windows; the safe server sleep
            -- avoids render loops or per-second allocations on Android.
            task.wait(DistrictSignalRush.Window)
            if not folder.Parent then break end
            node.setActive(false, activeClaimed, wave)
            activeNode = nil
            folder:SetAttribute("SignalRoute", 0)
        end
    end)

    return #nodes
end

return DistrictSignalRush
