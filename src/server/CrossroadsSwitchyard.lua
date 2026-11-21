-- CROSSROADS / SWITCHYARD
-- Intentional lateral lane changes, not another inward Flux Relay.
-- Four noncolliding central junction pads; two opposing pads charge at
-- once. Routes and collisions stay open whether or not the skill is active.
local Players = game:GetService("Players")
local RoundEquipmentArt = require("./RoundEquipmentArt")
local movementModule = script and script.Parent:FindFirstChild("MovementSafety")
local MovementSafety = if movementModule
    then require(movementModule) else require("./MovementSafety")

local CrossroadsSwitchyard = {}

CrossroadsSwitchyard.PairSeconds = 9
CrossroadsSwitchyard.Cooldown = 4
CrossroadsSwitchyard.Offset = 13
CrossroadsSwitchyard.SideImpulse = 20
CrossroadsSwitchyard.MasterSideImpulse = 26

-- A forced spin, freeze or arena deformation makes a lateral cut look
-- deliberate when it is not. Keep Flux Relays and all normal paths active.
local CONFLICTS = {
    RisingLava = true,
    ShrinkingArena = true,
    Freeze = true,
    Tornado = true,
    JumpShock = true,
    LowGravity = true,
    SpeedSurge = true,
}

function CrossroadsSwitchyard.allowed(ctx)
    if type(ctx) ~= "table" or ctx.EnableJunctionSwitchyard ~= true
        or type(ctx.Active) ~= "function"
        or type(ctx.OnCleanup) ~= "table"
    then return false end
    for name in pairs(ctx.ActiveDisasters or {}) do
        if CONFLICTS[name] then return false end
    end
    return true
end

local OFFSETS = {
    Vector3.new(1, 0, 0),
    Vector3.new(0, 0, 1),
    Vector3.new(-1, 0, 0),
    Vector3.new(0, 0, -1),
}

function CrossroadsSwitchyard.pair(roundNumber, cycle)
    local round = math.max(1, math.floor(tonumber(roundNumber) or 1))
    local step = math.max(0, math.floor(tonumber(cycle) or 0))
    return (round + step) % 2
end

function CrossroadsSwitchyard.activeLane(index, pair)
    local lane, selected = tonumber(index), tonumber(pair)
    return lane ~= nil and lane % 1 == 0 and lane >= 1 and lane <= 4
        and (selected == 0 or selected == 1)
        and lane % 2 == selected
end

-- A straight return from an outer Flux Relay should NOT accidentally
-- trigger a sideways launch. The runner must already be steering across
-- lanes with an unmistakable tangential velocity component.
function CrossroadsSwitchyard.tangentVelocity(velocity, outward)
    if typeof(velocity) ~= "Vector3"
        or typeof(outward) ~= "Vector3" then return nil end
    local radial = Vector3.new(outward.X, 0, outward.Z)
    if radial.Magnitude < 0.1 then return nil end
    local along = Vector3.new(-radial.Z, 0, radial.X).Unit
    local motion = Vector3.new(velocity.X, 0, velocity.Z)
    local sideways = motion:Dot(along)
    if motion.Magnitude < 9 or math.abs(sideways) < 6
        or math.abs(sideways) / motion.Magnitude < 0.38
    then return nil end
    return along * math.sign(sideways)
end

function CrossroadsSwitchyard.velocity(current, tangent, masterBoost)
    if typeof(tangent) ~= "Vector3" then return current end
    -- Same ordinary physics cap, but one noticeably stronger lateral cut
    -- earned by completing a real three-gate Flux Weave sequence.
    local impulse = masterBoost == true
        and CrossroadsSwitchyard.MasterSideImpulse
        or CrossroadsSwitchyard.SideImpulse
    return MovementSafety.addImpulse(
        current, tangent * impulse, 48, -52, 58
    )
end

local function subjectFromHit(hit)
    local node = hit
    while node and node ~= workspace do
        if node:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(node)
            local bot = node:GetAttribute("AISurvivor") == true
                and node:GetAttribute("AISurvivorInRound") == true
            if player or bot then
                local humanoid = node:FindFirstChildOfClass("Humanoid")
                local root = node:FindFirstChild("HumanoidRootPart")
                if humanoid and root and root:IsA("BasePart") then
                    return node, player, bot, humanoid, root
                end
                return nil
            end
        end
        node = node.Parent
    end
    return nil
end

function CrossroadsSwitchyard.tryTrigger(ctx, pad, hit, ready, claimed, now)
    if not ctx or type(ctx.Active) ~= "function" or not ctx.Active()
        or not pad or not pad.Parent
        or pad:GetAttribute("JunctionActive") ~= true
    then return false end
    local character, player, bot, humanoid, root = subjectFromHit(hit)
    if not character or humanoid.Health <= 0 then return false end
    if not bot and (not player
        or type(ctx.IsContestantActive) ~= "function"
        or ctx.IsContestantActive(player) ~= true)
    then return false end

    -- Accessory hits must never launch characters from across the arena.
    local delta = root.Position - pad.Position
    if math.abs(delta.X) > 5 or math.abs(delta.Y) > 4.5
        or math.abs(delta.Z) > 5 then return false end

    local index = pad:GetAttribute("JunctionIndex")
    local offset = OFFSETS[index]
    if not offset then return false end
    local direction = CrossroadsSwitchyard.tangentVelocity(
        root.AssemblyLinearVelocity, offset
    )
    if not direction or (ready[character] or -math.huge) > now
        or (claimed[character] and claimed[character][index])
    then return false end
    -- The charge can change at the exact moment eligibility was checked.
    if not ctx.Active() or pad:GetAttribute("JunctionActive") ~= true
    then return false end

    -- No boost is consumed by a disabled pad, invalid accessory touch,
    -- missed sideways run, wrong parity or junction cooldown: all of
    -- those were rejected above. Humans and NPCs use identical caps.
    local boostReady = false
    if player then
        boostReady = player:GetAttribute("RoundFluxJunctionBoostReady") == true
    else
        boostReady = character:GetAttribute("FluxJunctionBoostReady") == true
    end
    ready[character] = now + CrossroadsSwitchyard.Cooldown
    if not claimed[character] then claimed[character] = {} end
    claimed[character][index] = true
    root.AssemblyLinearVelocity = CrossroadsSwitchyard.velocity(
        root.AssemblyLinearVelocity, direction, boostReady
    )
    if boostReady then
        if player then
            player:SetAttribute("RoundFluxJunctionBoostReady", false)
        else
            character:SetAttribute("FluxJunctionBoostReady", false)
        end
    end
    pad:SetAttribute("JunctionTravelSign", direction:Dot(
        Vector3.new(-offset.Z, 0, offset.X)
    ) >= 0 and 1 or -1)
    pad:SetAttribute("JunctionTriggeredAt", workspace:GetServerTimeNow())
    if player and ctx.OnArenaMechanicUsed then
        pcall(ctx.OnArenaMechanicUsed, player, "Crossroads",
            boostReady and "MASTER JUNCTION CUT" or "JUNCTION CUT", false)
    end
    return true
end

local function addChevron(pieces, folder, pad, name, direction, color, profile)
    local frame = CFrame.lookAt(pad.Position, pad.Position + direction)
    -- Keep the arrow above the arena finish and the optional local housing
    -- while staying well inside the original six-stud trigger footprint.
    local tip = frame * Vector3.new(0, -1.81, -1.34)
    for side = -1, 1, 2 do
        local tail = frame * Vector3.new(side * 0.71, -1.81, -0.28)
        local leg = CFrame.lookAt((tip + tail) * 0.5, tip)
        pieces[#pieces + 1] = RoundEquipmentArt.create(folder,
            name .. (side == 1 and "Outer" or ""),
            Vector3.new(0.24, 0.075, (tip - tail).Magnitude + 0.05),
            leg, color, Enum.Material.Neon, 0.68, profile)
    end
end

function CrossroadsSwitchyard.start(ctx, mechanics, center)
    if not CrossroadsSwitchyard.allowed(ctx)
        or not mechanics or typeof(center) ~= "Vector3"
    then return nil end

    local folder = Instance.new("Folder")
    folder.Name = "JunctionSwitchyard"
    folder.Parent = mechanics
    local ready = setmetatable({}, {__mode = "k"})
    local claimed = setmetatable({}, {__mode = "k"})
    local pads = {}
    local signalSets = {}

    local idle = Color3.fromRGB(122, 104, 174)
    local charged = Color3.fromRGB(255, 203, 99)
    local profile = RoundEquipmentArt.profiles("Crossroads").beam
    for index, outward in ipairs(OFFSETS) do
        local pad = Instance.new("Part")
        pad.Name = "JunctionSwitch" .. tostring(index)
        pad.Size = Vector3.new(6.2, 4.8, 6.2)
        pad.Position = center + outward * CrossroadsSwitchyard.Offset
            + Vector3.new(0, 3.15, 0)
        pad.Anchored = true
        pad.CanCollide = false
        pad.CanTouch = true
        pad.CanQuery = false
        pad.CastShadow = false
        pad.Transparency = 1
        pad:SetAttribute("JunctionIndex", index)
        pad.Parent = folder
        pads[index] = pad

        -- The arrows point along the two real directions of the cut.
        local tangent = Vector3.new(-outward.Z, 0, outward.X)
        local signals = {}
        addChevron(signals, folder, pad, "JunctionChevron" .. index .. "A", tangent, idle, profile)
        addChevron(signals, folder, pad, "JunctionChevron" .. index .. "B", -tangent, idle, profile)
        signalSets[index] = signals
        -- A compact in-world label is visible without a new HUD or any
        -- quality-tier dependent particles. Only charged stations show it.
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "JunctionRouteSign" .. index
        billboard.Adornee = pad
        billboard.Size = UDim2.fromOffset(140, 30)
        billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
        billboard.MaxDistance = 55
        billboard.AlwaysOnTop = false
        billboard.Enabled = false
        billboard.Parent = folder
        local signText = Instance.new("TextLabel")
        signText.Name = "JunctionRouteText"
        signText.BackgroundColor3 = Color3.fromRGB(31, 28, 50)
        signText.BackgroundTransparency = 0.20
        signText.BorderSizePixel = 0
        signText.Size = UDim2.fromScale(1, 1)
        signText.Font = Enum.Font.GothamBold
        signText.TextColor3 = charged
        signText.TextScaled = true
        signText.Text = "↔ TURN TO BOOST"
        signText.Parent = billboard
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = signText
        signalSets[index].billboard = billboard
        pad.Touched:Connect(function(hit)
            CrossroadsSwitchyard.tryTrigger(
                ctx, pad, hit, ready, claimed, os.clock()
            )
        end)
    end

    local active = true
    local cycle = 0
    local function paint()
        local pair = CrossroadsSwitchyard.pair(ctx.RoundNumber, cycle)
        for index, pad in ipairs(pads) do
            local on = CrossroadsSwitchyard.activeLane(index, pair)
            pad:SetAttribute("JunctionActive", on)
            for _, piece in ipairs(signalSets[index]) do
                piece.Color = on and charged or idle
                piece.Transparency = on and 0.07 or 0.68
            end
            signalSets[index].billboard.Enabled = on
        end
    end
    paint()
    ctx.OnCleanup[#ctx.OnCleanup + 1] = function()
        active = false
        for index, pad in ipairs(pads) do
            if pad.Parent then
                pad:SetAttribute("JunctionActive", nil)
            end
            for _, piece in ipairs(signalSets[index]) do
                if piece.Parent then
                    piece.Color = idle
                    piece.Transparency = 0.68
                end
            end
            signalSets[index].billboard.Enabled = false
        end
    end

    task.spawn(function()
        while active and ctx.Active() and folder.Parent do
            task.wait(CrossroadsSwitchyard.PairSeconds)
            if not active or not ctx.Active() or not folder.Parent then
                break
            end
            cycle += 1
            -- A junction may be used once per charged window, not once
            -- for the entire round. Reset per-character lane claims when
            -- the active pair rotates; retain the independent 4s cooldown.
            -- This restores repeatable tactical lane changes on 45s rounds
            -- without allowing repeated Touched impulses in one window.
            claimed = setmetatable({}, {__mode = "k"})
            paint()
        end
    end)

    return folder
end

return CrossroadsSwitchyard
