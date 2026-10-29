--!strict
-- Fast, optional floor-level transport for the 320 x 320 mega-arenas.
-- Native Roblox prompts work on touch, keyboard and gamepad. Every move is
-- server-validated: no RemoteEvents, paid boosts or client-side teleport.
-- Disabled during protected newcomer rounds and Shrinking Arena.
local Players = game:GetService("Players")
local SpawnSafety = if script
    then require(script.Parent.SpawnSafety)
    else require("./SpawnSafety")

local ArenaDistrictTransit = {}

ArenaDistrictTransit.ReuseSeconds = 6
ArenaDistrictTransit.PromptDistance = 9
ArenaDistrictTransit.PromptHold = 0.55
ArenaDistrictTransit.InnerX = 36
ArenaDistrictTransit.InnerZ = 66
ArenaDistrictTransit.OuterX = 123
ArenaDistrictTransit.OuterZ = 113

local SIGNS = {
    {-1, -1}, {1, -1}, {-1, 1}, {1, 1},
}
local ROUTE_COLOR = {
    Color3.fromRGB(89, 219, 254),
    Color3.fromRGB(255, 191, 86),
    Color3.fromRGB(185, 142, 255),
    Color3.fromRGB(102, 243, 178),
}

function ArenaDistrictTransit.allowed(ctx)
    return type(ctx) == "table"
        and ctx.EnableDistrictTransit == true
        and type(ctx.Active) == "function"
        and ctx.Active() == true
        and type(ctx.IsContestantActive) == "function"
        and not (ctx.ActiveDisasters
            and ctx.ActiveDisasters.ShrinkingArena == true)
end

function ArenaDistrictTransit.stationOffset(route, outer, floorWidth, variantId)
    local signs = SIGNS[route]
    if not signs then return nil end
    -- The stations remain inside the floor, even for a smaller future
    -- arena; a map below 280 studs does not support this feature.
    if type(floorWidth) ~= "number" or floorWidth < 280 then
        return nil
    end
    local sx, sz = signs[1], signs[2]
    if outer then
        -- Harbor's raised side branch occupies the old ±110/±98
        -- arrival strip. Move its return terminals to the open quay
        -- corners instead of teleporting into a solid support column.
        if variantId == "Harbor" then
            return Vector3.new(sx * 139, 0, sz * 139)
        end
        return Vector3.new(sx * ArenaDistrictTransit.OuterX,
            0, sz * ArenaDistrictTransit.OuterZ)
    end
    return Vector3.new(sx * ArenaDistrictTransit.InnerX,
        0, sz * ArenaDistrictTransit.InnerZ)
end

-- Places a destination clear of the paired transit frame, the real
-- parkour decks and the map's current solid collision geometry.
function ArenaDistrictTransit.arrival(arena, base, route, outer, humanoid, root)
    local target = ArenaDistrictTransit.stationOffset(
        route, outer, math.min(base.Size.X, base.Size.Z),
        arena:GetAttribute("VariantId")
    )
    if not target then return nil end
    local sx, sz = SIGNS[route][1], SIGNS[route][2]
    local floorY = base.Position.Y + base.Size.Y * 0.5
    local height = math.max(3.6,
        humanoid.HipHeight + root.Size.Y * 0.5 + 0.75)
    for _, offset in ipairs({
        Vector3.new(-sx * 10, 0, -sz * 10),
        Vector3.new(-sx * 15, 0, -sz * 10),
        Vector3.new(-sx * 10, 0, -sz * 15),
        Vector3.new(-sx * 18, 0, -sz * 18),
    }) do
        local flat = base.Position + target + offset
        if SpawnSafety.clearAt(arena, flat) then
            return Vector3.new(flat.X, floorY + height, flat.Z)
        end
    end
    return nil
end

local function part(parent, name, size, cf, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = material or Enum.Material.Metal
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = parent
    return p
end

local function station(folder, base, route, outer, variantId)
    local offset = ArenaDistrictTransit.stationOffset(
        route, outer, math.min(base.Size.X, base.Size.Z),
        variantId
    )
    if not offset then return nil end
    local color = ROUTE_COLOR[route]
    local floorTop = base.Position.Y + base.Size.Y * 0.5
    local position = base.Position + offset
        + Vector3.new(0, floorTop - base.Position.Y, 0)
    local frame = CFrame.new(position)
    local name = "Transit" .. route .. (outer and "Outer" or "Hub")
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("DistrictTransit", true)
    model:SetAttribute("TransitRoute", route)
    model:SetAttribute("TransitOuter", outer)
    model:SetAttribute("TransitFree", true)
    model:SetAttribute("CosmeticOnly", true)
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

    part(model, "ArrivalFloorIndicator",
        Vector3.new(7.4, 0.12, 5.4),
        frame * CFrame.new(0, 0.075, 0),
        Color3.fromRGB(34, 52, 67), Enum.Material.Metal)
    for side = -1, 1, 2 do
        part(model, "GantryPost" .. side,
            Vector3.new(0.85, 7.8, 1.15),
            frame * CFrame.new(side * 3.15, 4.0, 0),
            Color3.fromRGB(67, 92, 114))
        part(model, "SignalStripe" .. side,
            Vector3.new(0.16, 5.0, 0.19),
            frame * CFrame.new(side * 3.15, 4.0, -0.68),
            color, Enum.Material.Neon).Transparency = 0.26
    end
    local header = part(model, "TransitHeader",
        Vector3.new(7.5, 1.05, 2.4),
        frame * CFrame.new(0, 8.15, 0),
        Color3.fromRGB(31, 49, 66))
    part(model, "TransitSignal",
        Vector3.new(5.6, 0.5, 0.22),
        frame * CFrame.new(0, 8.25, -1.26),
        color, Enum.Material.Neon).Transparency = 0.2

    -- Distinct silhouettes for the four arenas; these stay decorative.
    -- Only 2-4 extra low-poly parts per station, no active lights/VFX.
    if variantId == "Classic" then
        local dish = part(model, "MeteorDish",
            Vector3.new(0.65, 4.2, 4.2),
            frame * CFrame.new(0, 10.2, 0)
                * CFrame.Angles(0, 0, math.rad(30)),
            Color3.fromRGB(87, 121, 146))
        dish.Shape = Enum.PartType.Cylinder
        local lens = part(model, "ScannerEye",
            Vector3.new(1.35, 1.35, 1.35),
            frame * CFrame.new(0, 10.3, -0.52),
            color, Enum.Material.Glass)
        lens.Shape = Enum.PartType.Ball
    elseif variantId == "Towers" then
        part(model, "TransitCanopy",
            Vector3.new(10, 0.8, 3.7),
            frame * CFrame.new(0, 10.3, 0),
            Color3.fromRGB(88, 108, 123))
        part(model, "SuspendedCabin",
            Vector3.new(3.6, 2.4, 2.5),
            frame * CFrame.new(0, 12, 0),
            Color3.fromRGB(34, 58, 80))
        part(model, "CabinGlazing",
            Vector3.new(2.6, 0.76, 0.15),
            frame * CFrame.new(0, 12.1, -1.35),
            color, Enum.Material.Glass).Transparency = 0.24
    elseif variantId == "Crossroads" then
        for side = -1, 1, 2 do
            local arrow = part(model, "SwitchyardSignal" .. side,
                Vector3.new(3.7, 2.4, 1.4),
                frame * CFrame.new(side * 2.3, 10.8, 0)
                    * CFrame.Angles(0, side < 0 and math.pi or 0, 0),
                color, Enum.Material.Metal)
            arrow.Shape = Enum.PartType.Block
        end
    elseif variantId == "Harbor" then
        -- Compact port-hoist silhouette rather than generic archway.
        -- Optical machinery only; the ProximityPrompt below stays the
        -- sole server-authoritative free transport interaction.
        part(model, "HarborSignalHoist", Vector3.new(7.5, 1.2, 2.2),
            frame * CFrame.new(0, 10.4, 0),
            Color3.fromRGB(88, 142, 156))
        part(model, "HarborTrolley", Vector3.new(2.3, 2.5, 2.2),
            frame * CFrame.new(1.8, 11.4, 0),
            color, Enum.Material.Metal)
        part(model, "HarborCable", Vector3.new(0.25, 2.5, 0.25),
            frame * CFrame.new(1.8, 8.9, -0.2),
            Color3.fromRGB(105, 156, 165))
    elseif variantId == "Orbital" then
        local hub = part(model, "OrbitReceiver",
            Vector3.new(3.1, 3.1, 3.1),
            frame * CFrame.new(0, 10.5, 0),
            color, Enum.Material.Glass)
        hub.Shape = Enum.PartType.Ball
        local collar = part(model, "OrbitCollar",
            Vector3.new(0.65, 5.2, 5.2),
            frame * CFrame.new(0, 10.5, 0)
                * CFrame.Angles(0, 0, math.pi * 0.5),
            Color3.fromRGB(97, 127, 155))
        collar.Shape = Enum.PartType.Cylinder
    end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "Travel" .. (outer and "ToHub" or "ToDistrict")
    prompt.ActionText = outer and "RETURN TO HUB" or "TRAVEL TO DISTRICT"
    prompt.ObjectText = "FREE TRANSIT " .. tostring(route)
    prompt.HoldDuration = ArenaDistrictTransit.PromptHold
    prompt.MaxActivationDistance = ArenaDistrictTransit.PromptDistance
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.Parent = header

    local gui = Instance.new("BillboardGui")
    gui.Name = "TransitWayfinding"
    gui.Size = UDim2.fromOffset(184, 49)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
    gui.MaxDistance = 88
    gui.AlwaysOnTop = false
    gui.Adornee = header
    gui.Parent = header
    local label = Instance.new("TextLabel")
    label.Name = "TransitDestination"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(14, 25, 39)
    label.BackgroundTransparency = 0.2
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextWrapped = true
    label.TextColor3 = color
    label.Text = outer and "CLIMB FOR SUPPLY\nRETURN TO CENTER"
        or "FREE FAST TRAVEL\nOUTER DISTRICT"
    label.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label

    model.Parent = folder
    return {model = model, trigger = header, prompt = prompt, route = route,
        outer = outer, floor = position}
end

function ArenaDistrictTransit.start(ctx)
    if not ArenaDistrictTransit.allowed(ctx) then
        return 0
    end
    local map = workspace:FindFirstChild("GeneratedMap")
    local arena = map and map:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not arena or not base or not base:IsA("BasePart")
        or not base.CanCollide
        or math.min(base.Size.X, base.Size.Z) < 280 then
        return 0
    end

    local existing = arena:FindFirstChild("DistrictTransit")
    if existing then existing:Destroy() end
    local folder = Instance.new("Folder")
    folder.Name = "DistrictTransit"
    folder:SetAttribute("ServerAuthoritative", true)
    folder.Parent = arena
    table.insert(ctx.Cleanup, folder)

    local cooldowns = {}
    local built = 0
    local variantId = tostring(arena:GetAttribute("VariantId") or "Classic")
    for route = 1, 4 do
        local hub = station(folder, base, route, false, variantId)
        local outer = station(folder, base, route, true, variantId)
        if hub and outer then
            built += 2
            for _, entry in ipairs({hub, outer}) do
                local destinationIsOuter = not entry.outer
                entry.prompt.Triggered:Connect(function(player)
                    if not ArenaDistrictTransit.allowed(ctx)
                        or ctx.FinalRush and ctx.FinalRush()
                        or not player or player.Parent ~= Players
                        or player:GetAttribute("DataLoaded") ~= true
                        or not ctx.IsContestantActive(player)
                    then return end
                    local character = player.Character
                    local humanoid = character
                        and character:FindFirstChildOfClass("Humanoid")
                    local root = character
                        and character:FindFirstChild("HumanoidRootPart")
                    if not humanoid or humanoid.Health <= 0
                        or humanoid.SeatPart ~= nil
                        or not root or not root:IsA("BasePart")
                        or (root.Position - entry.trigger.Position).Magnitude
                            > ArenaDistrictTransit.PromptDistance + 3
                    then return end
                    local now = os.clock()
                    if (cooldowns[player.UserId] or 0) > now then
                        return
                    end
                    local destination = ArenaDistrictTransit.arrival(
                        arena, base, route, destinationIsOuter,
                        humanoid, root)
                    if not destination then
                        return
                    end
                    -- A claimed move consumes cooldown before teleporting;
                    -- prevents chained E presses, repeated prompt exploits.
                    cooldowns[player.UserId] = now
                        + ArenaDistrictTransit.ReuseSeconds
                    local signX, signZ = SIGNS[route][1], SIGNS[route][2]
                    local facing = Vector3.new(signX, 0, signZ)
                        * (destinationIsOuter and 1 or -1)
                    character:PivotTo(CFrame.lookAt(
                        destination, destination + facing))
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    if ctx.OnDistrictTransitUsed then
                        pcall(ctx.OnDistrictTransitUsed, player, route,
                            destinationIsOuter)
                    end
                end)
            end
        end
    end
    folder:SetAttribute("TransitStationCount", built)
    return built
end

return ArenaDistrictTransit
