local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "ArenaNavigationLanguageLocal"
folder.Parent = workspace

local dynamicIndicators = {}
local shrinkingActive = false

local function clear()
    folder:ClearAllChildren()
    table.clear(dynamicIndicators)
end

local function makePart(name, size, cframe, color, material, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = material
    part.Color = color
    part.Transparency = transparency
    part.Parent = folder
    return part
end

local function padImpulse(pad)
    return Vector3.new(
        tonumber(pad:GetAttribute("ImpulseX")) or 0,
        tonumber(pad:GetAttribute("ImpulseY")) or 0,
        tonumber(pad:GetAttribute("ImpulseZ")) or 0
    )
end

local function flattenedUnit(v)
    local flat = Vector3.new(v.X, 0, v.Z)
    if flat.Magnitude < 0.01 then
        return Vector3.zero
    end
    return flat.Unit
end

local function addGroundChevron(position, direction, color, alpha, index)
    if direction.Magnitude < 0.01 then
        return
    end

    local yaw = math.atan2(-direction.X, -direction.Z)
    local lateral = Vector3.new(direction.Z, 0, -direction.X)
    local back = -direction

    local left = position + back * 0.65 - lateral * 0.58
    local right = position + back * 0.65 + lateral * 0.58

    local leftPart = makePart(
        "RouteChevronL" .. index,
        Vector3.new(1.7, 0.05, 0.18),
        CFrame.new(left) * CFrame.Angles(0, yaw + math.rad(38), 0),
        color,
        Enum.Material.Neon,
        alpha
    )

    local rightPart = makePart(
        "RouteChevronR" .. index,
        Vector3.new(1.7, 0.05, 0.18),
        CFrame.new(right) * CFrame.Angles(0, yaw - math.rad(38), 0),
        color,
        Enum.Material.Neon,
        alpha
    )

    return leftPart, rightPart
end

local function addVerticalBeacon(pad, color, tier, index)
    local height = tier.Name == "High" and 7.5 or 5.2
    local beam = makePart(
        "VerticalRouteBeacon" .. index,
        Vector3.new(0.18, height, 0.18),
        CFrame.new(pad.Position + Vector3.new(0, height * 0.5 + 0.4, 0)),
        color,
        Enum.Material.Neon,
        tier.Name == "High" and 0.48 or 0.62
    )
    beam:SetAttribute("NavBaseTransparency", beam.Transparency)

    local cap = makePart(
        "VerticalRouteCap" .. index,
        Vector3.new(1.35, 0.10, 1.35),
        CFrame.new(pad.Position + Vector3.new(0, height + 0.4, 0)),
        color:Lerp(Color3.new(1, 1, 1), 0.28),
        Enum.Material.Neon,
        tier.Name == "High" and 0.36 or 0.52
    )

    return beam, cap, height
end

local function addCenterLandmark(base, theme, variant, tier)
    local center = base.Position + Vector3.new(0, base.Size.Y * 0.5 + 0.045, 0)
    local span = math.min(base.Size.X, base.Size.Z)

    if variant == "Orbital" then
        local segments = tier.Name == "High" and 12 or 8
        local radius = span * 0.12
        for i = 1, segments do
            local angle = ((i - 1) / segments) * math.pi * 2
            local tangent = angle + math.pi * 0.5
            local pos = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
            makePart(
                "CenterOrbitMark" .. i,
                Vector3.new(2.6, 0.05, 0.16),
                CFrame.new(pos) * CFrame.Angles(0, -tangent, 0),
                i % 3 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                0.62
            )
        end
    elseif variant == "Crossroads" then
        local arm = span * 0.18
        makePart(
            "CenterCrossX",
            Vector3.new(arm, 0.05, 0.22),
            CFrame.new(center),
            theme.Accent,
            Enum.Material.Neon,
            0.62
        )
        makePart(
            "CenterCrossZ",
            Vector3.new(0.22, 0.05, arm),
            CFrame.new(center),
            theme.Secondary,
            Enum.Material.Neon,
            0.62
        )
    elseif variant == "Towers" then
        local radius = span * 0.10
        for i = 1, 4 do
            local angle = math.rad(45 + (i - 1) * 90)
            local pos = center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
            makePart(
                "CenterTowerAnchor" .. i,
                Vector3.new(1.6, 0.05, 1.6),
                CFrame.new(pos) * CFrame.Angles(0, -angle, 0),
                i % 2 == 0 and theme.Secondary or theme.Accent,
                Enum.Material.Neon,
                0.62
            )
        end
    else
        local half = span * 0.11
        makePart(
            "CenterGridX",
            Vector3.new(half * 2, 0.05, 0.18),
            CFrame.new(center),
            theme.Accent,
            Enum.Material.Neon,
            0.66
        )
        makePart(
            "CenterGridZ",
            Vector3.new(0.18, 0.05, half * 2),
            CFrame.new(center),
            theme.Secondary,
            Enum.Material.Neon,
            0.66
        )
    end
end

local function rebuild()
    clear()

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    local mechanics = arena and arena:FindFirstChild("Mechanics")
    if not arena or not base or not base:IsA("BasePart") or not mechanics then
        return
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local theme = VisualTheme.arena(variant)
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local low = tier.Name == "Low"

    addCenterLandmark(base, theme, variant, tier)

    local pads = {}
    for _, child in ipairs(mechanics:GetChildren()) do
        if child:IsA("BasePart") and child:GetAttribute("ArenaMobilityPad") == true then
            table.insert(pads, child)
        end
    end
    table.sort(pads, function(a, b)
        return a.Name < b.Name
    end)

    for index, pad in ipairs(pads) do
        local impulse = padImpulse(pad)
        local direction = flattenedUnit(impulse)
        local routeColor = index % 2 == 0 and theme.Secondary or theme.Accent

        if variant == "Towers" then
            if not low then
                local beam, cap, height = addVerticalBeacon(pad, routeColor, tier, index)
                table.insert(dynamicIndicators, {
                    kind = "vertical",
                    pad = pad,
                    beam = beam,
                    cap = cap,
                    height = height,
                })
            end
        elseif direction.Magnitude > 0.01 then
            local steps = low and 1 or (tier.Name == "Medium" and 2 or 3)
            for step = 1, steps do
                local distance = 4 + (step - 1) * 3.1
                local pos = pad.Position - direction * distance + Vector3.new(0, pad.Size.Y * 0.5 + 0.08, 0)
                local left, right = addGroundChevron(
                    pos,
                    direction,
                    routeColor,
                    low and 0.72 or (0.58 + (step - 1) * 0.06),
                    index * 10 + step
                )
                table.insert(dynamicIndicators, {
                    kind = "chevron",
                    pad = pad,
                    direction = direction,
                    step = step,
                    left = left,
                    right = right,
                })
            end
        end
    end
end

local function updateDynamicIndicators()
    for _, state in ipairs(dynamicIndicators) do
        local pad = state.pad
        if not pad or not pad.Parent then
            continue
        end

        if state.kind == "vertical" then
            local height = state.height
            if state.beam and state.beam.Parent then
                state.beam.CFrame = CFrame.new(pad.Position + Vector3.new(0, height * 0.5 + 0.4, 0))
            end
            if state.cap and state.cap.Parent then
                state.cap.CFrame = CFrame.new(pad.Position + Vector3.new(0, height + 0.4, 0))
            end
        elseif state.kind == "chevron" then
            local direction = state.direction
            local step = state.step
            local distance = 4 + (step - 1) * 3.1
            local position = pad.Position - direction * distance + Vector3.new(0, pad.Size.Y * 0.5 + 0.08, 0)
            local yaw = math.atan2(-direction.X, -direction.Z)
            local lateral = Vector3.new(direction.Z, 0, -direction.X)
            local back = -direction
            local left = position + back * 0.65 - lateral * 0.58
            local right = position + back * 0.65 + lateral * 0.58

            if state.left and state.left.Parent then
                state.left.CFrame = CFrame.new(left) * CFrame.Angles(0, yaw + math.rad(38), 0)
            end
            if state.right and state.right.Parent then
                state.right.CFrame = CFrame.new(right) * CFrame.Angles(0, yaw - math.rad(38), 0)
            end
        end
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    shrinkingActive = state
        and state.phase == "round"
        and table.find(state.disasterIds or {}, "ShrinkingArena") ~= nil
end)

task.spawn(function()
    while true do
        if shrinkingActive and #dynamicIndicators > 0 then
            updateDynamicIndicators()
            task.wait(0.12)
        else
            task.wait(0.5)
        end
    end
end)

local function bindArena(arena)
    if not arena then
        return
    end

    local mechanics = arena:FindFirstChild("Mechanics")
    if mechanics then
        task.defer(rebuild)
    end

    arena.ChildAdded:Connect(function(child)
        if child.Name == "Mechanics" then
            task.defer(rebuild)
        end
    end)

    arena.ChildRemoved:Connect(function(child)
        if child.Name == "Mechanics" then
            clear()
        end
    end)
end

local function bindGeneratedMap(root)
    local arena = root:FindFirstChild("Arena")
    if arena then
        bindArena(arena)
    end

    root.ChildAdded:Connect(function(child)
        if child.Name == "Arena" then
            bindArena(child)
        end
    end)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        task.defer(bindGeneratedMap, child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clear()
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    task.defer(rebuild)
end)

local existing = workspace:FindFirstChild("GeneratedMap")
if existing then
    task.defer(bindGeneratedMap, existing)
end
