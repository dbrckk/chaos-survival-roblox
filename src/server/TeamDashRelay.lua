-- Genuine cooperative environment interaction for EVERY arena.
-- Two compact server-owned consoles per round; press/hold on Android,
-- keyboard or controller to replenish nearby living human survivors' DASH.
-- A ready survivor receives exactly ONE future emergency follow-up DASH.
-- No clients can choose recipients or rewards. No per-frame update loops.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SpawnSafety = if script
    then require(script.Parent.SpawnSafety)
    else require("./SpawnSafety")

local TeamDashRelay = {}

TeamDashRelay.PromptDistance = 9
TeamDashRelay.Radius = 29
TeamDashRelay.HoldSeconds = 0.65
TeamDashRelay.MinRoundSeconds = 20
TeamDashRelay.BotApproachRadius = 68
TeamDashRelay.BotReach = 7.5

-- The server owns both the human prompt and the bot activation path.
-- No client remote can impersonate an NPC or choose human beneficiaries.
local activeRound = nil

local OFFSETS = {
    {
        Vector3.new(-68, 0, 45),
        Vector3.new(-83, 0, 56),
        Vector3.new(-57, 0, 72),
        Vector3.new(-92, 0, 33),
    },
    {
        Vector3.new(68, 0, -45),
        Vector3.new(83, 0, -56),
        Vector3.new(57, 0, -72),
        Vector3.new(92, 0, -33),
    },
}

local function validCharacter(player)
    if not player or player.Parent ~= Players then return nil end
    local character = player.Character
    local human = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not human or human.Health <= 0 or not root
        or not root:IsA("BasePart")
        or not root:IsDescendantOf(workspace) then
        return nil
    end
    return root
end

function TeamDashRelay.canUse(ctx, base, source, player, now)
    if not ctx or type(ctx.Active) ~= "function" or not ctx.Active()
        or type(ctx.IsContestantActive) ~= "function"
        or type(ctx.OnTeamDashCharge) ~= "function"
        or not player or player.Parent ~= Players
        or player:GetAttribute("DataLoaded") ~= true
        or not ctx.IsContestantActive(player)
        or not source or not source.Parent or not base or not base.Parent
        or not base.CanCollide
        or type(now) ~= "number" then
        return false
    end
    local root = validCharacter(player)
    if not root then return false end
    if (root.Position - source.Position).Magnitude
        > TeamDashRelay.PromptDistance + 3 then return false end
    -- Shrinking Arena can pull the live floor away from an earlier
    -- station. Never sell/activate help over void just because the
    -- noncolliding decorative console is still visible.
    local delta = source.Position - base.Position
    return math.abs(delta.X) + 7 < base.Size.X * 0.5
        and math.abs(delta.Z) + 7 < base.Size.Z * 0.5
end

local function botRoot(model)
    local folder = workspace:FindFirstChild("AISurvivors")
    if typeof(model) ~= "Instance" or not model:IsA("Model")
        or not folder or model.Parent ~= folder
        or model:GetAttribute("AISurvivor") ~= true
        or model:GetAttribute("AISurvivorInRound") ~= true then
        return nil
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0
        or not root or not root:IsA("BasePart")
        or not root:IsDescendantOf(workspace) then
        return nil
    end
    return root
end

local function withinLiveFloor(base, source)
    if not base or not base.Parent or not base.CanCollide
        or not source or not source.Parent then return false end
    local delta = source.Position - base.Position
    return math.abs(delta.X) + 7 < base.Size.X * 0.5
        and math.abs(delta.Z) + 7 < base.Size.Z * 0.5
end

-- Only real humans can benefit from a bot's shared-DASH interaction.
-- This check is repeated at activation, never trusted from path planning.
local function humanNearby(round, station)
    for _, player in ipairs(round.ctx.Contestants or {}) do
        if player:GetAttribute("DataLoaded") == true
            and round.ctx.IsContestantActive(player) then
            local root = validCharacter(player)
            if root and (root.Position - station.core.Position).Magnitude
                <= TeamDashRelay.Radius then
                return true
            end
        end
    end
    return false
end

function TeamDashRelay.botOpportunity(model, now, preferred)
    local round = activeRound
    local root = botRoot(model)
    if not round or not root or not round.ctx.Active()
        or type(now) ~= "number"
        or not round.folder.Parent then return nil end
    local best, distance = nil, TeamDashRelay.BotApproachRadius
    for _, station in ipairs(round.entries) do
        local core = station.core
        local delta = core.Position - root.Position
        local flat = Vector3.new(delta.X, 0, delta.Z).Magnitude
        local claimedByOther = station.claim and station.claim ~= model
            and (station.claimUntil or 0) > now
        if not station.used and not station.guard
            and station.prompt.Enabled
            and withinLiveFloor(round.base, core)
            and math.abs(delta.Y) <= 6.5
            and flat <= distance
            and not claimedByOther
            and (preferred == nil or core == preferred)
            and humanNearby(round, station) then
            best, distance = station, flat
        end
    end
    if not best then return nil end
    best.claim, best.claimUntil = model, now + 5.0
    return Vector3.new(best.core.Position.X, root.Position.Y,
        best.core.Position.Z), best.core
end

function TeamDashRelay.releaseBot(model)
    local round = activeRound
    if not round then return end
    for _, station in ipairs(round.entries) do
        if station.claim == model then
            station.claim = nil
            station.claimUntil = 0
        end
    end
end

local function part(model, name, size, cframe, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Color = color
    p.Material = material
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = model
    return p
end

local function build(folder, position, index, color)
    local model = Instance.new("Model")
    model.Name = "TeamDashRelay" .. index
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model:SetAttribute("TeamDashRelay", true)
    model:SetAttribute("RelayIndex", index)
    model:SetAttribute("RelayUsed", false)
    model:SetAttribute("TeamBeneficiaries", 0)
    local frame = CFrame.new(position)
    part(model, "GroundPlate", Vector3.new(5.6, 0.20, 5.6),
        frame * CFrame.new(0, 0.12, 0),
        Color3.fromRGB(34, 57, 68), Enum.Material.DiamondPlate)
    part(model, "ControlStand", Vector3.new(2.3, 3.5, 2.3),
        frame * CFrame.new(0, 1.9, 0),
        Color3.fromRGB(54, 82, 95), Enum.Material.CorrodedMetal)
    local head = part(model, "SharedChargeCore", Vector3.new(2.6, 0.65, 2.6),
        frame * CFrame.new(0, 3.9, 0),
        color, Enum.Material.Metal)
    local pulse = part(model, "TeamChargePulse",
        Vector3.new(5.5, 5.5, 5.5),
        frame * CFrame.new(0, 3.9, 0),
        color, Enum.Material.Neon)
    pulse.Shape = Enum.PartType.Ball
    pulse.Transparency = 1
    for side = -1, 1, 2 do
        part(model, "CouplingArm" .. tostring(side),
            Vector3.new(0.36, 2.8, 0.55),
            frame * CFrame.new(side * 1.56, 2.15, 0),
            Color3.fromRGB(78, 113, 126), Enum.Material.Metal)
    end
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "ShareDashCharge"
    prompt.ActionText = "RECHARGE TEAM DASH"
    prompt.ObjectText = index == 1 and "TEAM RELAY A" or "TEAM RELAY B"
    prompt.HoldDuration = TeamDashRelay.HoldSeconds
    prompt.MaxActivationDistance = TeamDashRelay.PromptDistance
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.Parent = head

    local label = Instance.new("BillboardGui")
    label.Name = "RelayStatus"
    label.Adornee = head
    label.Size = UDim2.fromOffset(158, 36)
    label.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
    -- The stations sit ~82 studs from the hub. The label must be seen
    -- from that hub, otherwise the feature exists but is undiscoverable.
    -- Only two small, occlusion-aware (AlwaysOnTop=false) tags per arena.
    label.MaxDistance = 110
    label.AlwaysOnTop = false
    label.Parent = head
    local text = Instance.new("TextLabel")
    text.Name = "Status"
    text.BackgroundColor3 = Color3.fromRGB(15, 30, 43)
    text.BackgroundTransparency = 0.25
    text.Size = UDim2.fromScale(1, 1)
    text.BorderSizePixel = 0
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.TextColor3 = color
    text.Text = "TEAM DASH\nHOLD TO SHARE"
    text.Parent = label
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = text
    model.Parent = folder
    return {model = model, prompt = prompt, core = head,
        pulse = pulse, label = text}
end

-- Both physical player interaction and real server-driven AI action go
-- through this single, bounded, atomic station state transition.
function TeamDashRelay.activate(entry, actor, fromBot)
    local round = activeRound
    if not round or not round.ctx.Active()
        or not entry or entry.used or entry.guard
        or not entry.prompt.Enabled
        or entry.model.Parent ~= round.folder
        or not withinLiveFloor(round.base, entry.core)
        then return false end
    if fromBot then
        local root = botRoot(actor)
        if not root or (root.Position - entry.core.Position).Magnitude
            > TeamDashRelay.BotReach
            or not humanNearby(round, entry) then
            return false
        end
    elseif not TeamDashRelay.canUse(
        round.ctx, round.base, entry.core, actor, os.clock()
    ) then
        return false
    end

    entry.guard = true
    local helped = {}
    for _, target in ipairs(round.ctx.Contestants or {}) do
        if round.ctx.IsContestantActive(target) then
            local root = validCharacter(target)
            if root and (root.Position - entry.core.Position).Magnitude
                <= TeamDashRelay.Radius then
                local ok, received, kind = pcall(
                    round.ctx.OnTeamDashCharge, target
                )
                if ok and received == true then
                    helped[#helped + 1] = {player = target, kind = kind}
                end
            end
        end
    end
    if #helped > 0 then
        entry.used = true
        entry.model:SetAttribute("RelayUsed", true)
        entry.model:SetAttribute("TeamBeneficiaries", #helped)
        entry.model:SetAttribute("BotActivated", fromBot == true)
        entry.core.Color = Color3.fromRGB(66, 97, 106)
        entry.pulse.Transparency = 0.86
        local tween = TweenService:Create(entry.pulse,
            TweenInfo.new(0.7, Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out), {Transparency = 1})
        tween:Play()
        tween.Completed:Once(function() tween:Destroy() end)
        entry.label.Text = fromBot
            and "TEAM DASH\nBOT HELPED"
            or "TEAM DASH\nRELAY USED"
        entry.label.TextColor3 = Color3.fromRGB(151, 179, 188)
        entry.refresh()
        if fromBot and type(round.ctx.OnTeamDashBotUsed) == "function" then
            pcall(round.ctx.OnTeamDashBotUsed, actor, entry.index, helped)
        elseif not fromBot
            and type(round.ctx.OnTeamDashUsed) == "function" then
            pcall(round.ctx.OnTeamDashUsed, actor, entry.index, helped)
        end
    end
    entry.guard = false
    return #helped > 0, #helped
end

function TeamDashRelay.activateBot(model, now)
    local _, station = TeamDashRelay.botOpportunity(model, now)
    if not station then return false end
    local round = activeRound
    if not round then return false end
    for _, entry in ipairs(round.entries) do
        if entry.core == station then
            local ok, count = TeamDashRelay.activate(entry, model, true)
            if ok then TeamDashRelay.releaseBot(model) end
            return ok, count
        end
    end
    return false
end

function TeamDashRelay.start(ctx)
    if not ctx or type(ctx.Active) ~= "function" or not ctx.Active()
        or type(ctx.OnTeamDashCharge) ~= "function"
        or type(ctx.IsContestantActive) ~= "function"
        or (tonumber(ctx.RoundSeconds) or 0) < TeamDashRelay.MinRoundSeconds then
        return 0
    end
    local map = workspace:FindFirstChild("GeneratedMap")
    local arena = map and map:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not arena or not base or not base:IsA("BasePart")
        or not base.CanCollide or math.min(base.Size.X, base.Size.Z) < 280 then
        return 0
    end
    local folder = Instance.new("Folder")
    folder.Name = "TeamDashRelays"
    folder:SetAttribute("ServerAuthoritative", true)
    folder.Parent = arena
    table.insert(ctx.Cleanup, folder)
    local round = {ctx = ctx, base = base, folder = folder, entries = {}}
    activeRound = round
    folder.Destroying:Connect(function()
        if activeRound == round then activeRound = nil end
    end)

    local floorTop = base.Position.Y + base.Size.Y * 0.5
    local color = Color3.fromRGB(109, 220, 190)
    local built = 0
    for index, candidates in ipairs(OFFSETS) do
        local position = nil
        for _, offset in ipairs(candidates) do
            local flat = base.Position + offset
            if SpawnSafety.clearAt(arena, flat) then
                position = Vector3.new(flat.X, floorTop, flat.Z)
                break
            end
        end
        if position then
            local entry = build(folder, position, index, color)
            built += 1
            entry.index = index
            entry.used = false
            entry.guard = false
            entry.claim = nil
            entry.claimUntil = 0
            table.insert(round.entries, entry)
            local function refresh()
                entry.prompt.Enabled = not entry.used and ctx.Active()
                    and withinLiveFloor(base, entry.core)
            end
            entry.refresh = refresh
            local shrink = base:GetPropertyChangedSignal("Size"):Connect(refresh)
            entry.model.Destroying:Connect(function()
                shrink:Disconnect()
            end)
            refresh()

            entry.prompt.Triggered:Connect(function(player)
                if entry.guard or entry.used or not entry.prompt.Enabled
                    or not TeamDashRelay.canUse(
                        ctx, base, entry.core, player, os.clock()
                    ) then return end
                TeamDashRelay.activate(entry, player, false)
            end)
        end
    end
    folder:SetAttribute("RelayCount", built)
    return built
end

return TeamDashRelay
