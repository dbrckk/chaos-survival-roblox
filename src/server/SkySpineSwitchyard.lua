-- Cooperative SKY NETWORK SWITCHYARD: one live player or nearby bot can
-- bridge 9 gaps on the transverse Sky Spine AND 14 gaps on the two genuine
-- promenades, making three huge elevated routes continuously walkable.
-- All 26 original solid decks remain server-owned and collision-authoritative.
-- One shared activation / no new remotes / no paid reward / no client trust.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:FindFirstChild("Shared")
local themeModule = shared and shared:FindFirstChild("VisualTheme")
local VisualTheme = if themeModule
    then require(themeModule)
    else require("../shared/VisualTheme")
local SkySpineSwitchyard = {}

SkySpineSwitchyard.HoldSeconds = 0.7
SkySpineSwitchyard.PromptDistance = 10
SkySpineSwitchyard.BotReach = 7.5
SkySpineSwitchyard.MinRoundSeconds = 20
local activeRound = nil

function SkySpineSwitchyard.allowed(ctx)
    return type(ctx) == "table"
        and type(ctx.Active) == "function"
        and type(ctx.IsContestantActive) == "function"
        and type(ctx.Cleanup) == "table"
        and type(ctx.OnCleanup) == "table"
        and ctx.Active() == true
        and (tonumber(ctx.RoundSeconds) or 0)
            >= SkySpineSwitchyard.MinRoundSeconds
        -- Shrinking Arena moves every PlatformN. Temporary gap fillers
        -- do not follow those moving decks and must NEVER appear as
        -- ghost solid floors during this particular disaster.
        and (ctx.ActiveDisasters or {}).ShrinkingArena ~= true
end

local function visual(folder, name, size, frame, color, material, translucent)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = frame
    p.Color = color
    p.Material = material or Enum.Material.Metal
    p.Transparency = translucent or 0
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = folder
    return p
end

-- The server can only turn an actual physical *gap* into live support.
-- Don't invent a long floor between unrelated platforms.
function SkySpineSwitchyard.gapBetween(first, second)
    if typeof(first) ~= "Instance" or typeof(second) ~= "Instance"
        or not first:IsA("BasePart") or not second:IsA("BasePart")
        or first.Parent ~= second.Parent or not first.CanCollide
        or not second.CanCollide
        or first:GetAttribute("SkySpineInterchange") ~= true
        or second:GetAttribute("SkySpineInterchange") ~= true
        or second:GetAttribute("SkySpineStep")
            ~= (tonumber(first:GetAttribute("SkySpineStep")) or -100) + 1
    then return nil end
    local topA = first.Position.Y + first.Size.Y * 0.5
    local topB = second.Position.Y + second.Size.Y * 0.5
    local dz = math.abs(second.Position.Z - first.Position.Z)
    local gap = dz - (first.Size.Z + second.Size.Z) * 0.5
    if math.abs(first.Position.X - second.Position.X) > 0.01
        or math.abs(topA - topB) > 0.01
        or gap < 1.8 or gap > 3.0 then return nil end
    return Vector3.new(
        (first.Position.X + second.Position.X) * 0.5,
        topA - 0.32,
        (first.Position.Z + second.Position.Z) * 0.5
    ), Vector3.new(math.min(first.Size.X, second.Size.X) - 1.2,
        0.64, gap + 0.8)
end

-- The two north/south promenade lanes are already real eight-deck
-- horizontal server routes. Only bridge their ORIGINAL 2.4-stud gaps,
-- never a fake jump from a disconnected wall, a streamed visual or a
-- collapsing/moving platform. All bridge parts are visual-only until
-- a verified survivor physically activates the shared switchyard.
function SkySpineSwitchyard.promenadeGapBetween(first, second)
    if typeof(first) ~= "Instance" or typeof(second) ~= "Instance"
        or not first:IsA("BasePart") or not second:IsA("BasePart")
        or not first.Name:match("^Platform%d+$")
        or not second.Name:match("^Platform%d+$")
        or first.Parent ~= second.Parent
        or not first.Anchored or not second.Anchored
        or not first.CanCollide or not second.CanCollide
        or first.Transparency >= 0.75 or second.Transparency >= 0.75
        or first:GetAttribute("ChaosPermanentRoute") ~= true
        or second:GetAttribute("ChaosPermanentRoute") ~= true
        or (first:GetAttribute("CollapsePhase") ~= nil
            and first:GetAttribute("CollapsePhase") ~= "Normal"
            and first:GetAttribute("CollapsePhase") ~= "Safe")
        or (second:GetAttribute("CollapsePhase") ~= nil
            and second:GetAttribute("CollapsePhase") ~= "Normal"
            and second:GetAttribute("CollapsePhase") ~= "Safe")
        or first:GetAttribute("PromenadeLane")
            ~= second:GetAttribute("PromenadeLane")
        or second:GetAttribute("PromenadeStep")
            ~= (tonumber(first:GetAttribute("PromenadeStep")) or -100) + 1
    then return nil end
    local lane = first:GetAttribute("PromenadeLane")
    local step = first:GetAttribute("PromenadeStep")
    if (lane ~= 1 and lane ~= 2)
        or type(step) ~= "number" or step % 1 ~= 0
        or step < 1 or step > 7 then return nil end
    local topA = first.Position.Y + first.Size.Y * 0.5
    local topB = second.Position.Y + second.Size.Y * 0.5
    local dx = math.abs(second.Position.X - first.Position.X)
    local gap = dx - (first.Size.X + second.Size.X) * 0.5
    if math.abs(first.Position.Z - second.Position.Z) > 0.01
        or math.abs(topA - topB) > 0.01
        or gap < 1.8 or gap > 3.0
        or math.min(first.Size.Z, second.Size.Z) < 10.5
        or math.abs(first.CFrame.RightVector:Dot(
            second.CFrame.RightVector)) < 0.999 then return nil end
    return Vector3.new(
        (first.Position.X + second.Position.X) * 0.5,
        topA - 0.32,
        (first.Position.Z + second.Position.Z) * 0.5
    ), Vector3.new(gap + 0.8, 0.64,
        math.min(first.Size.Z, second.Size.Z) - 1.2)
end

local function station(folder, deck, step, theme)
    local center = deck.Position
        + Vector3.new(0, deck.Size.Y * 0.5, 0)
    local model = Instance.new("Model")
    model.Name = "SkySpineCommand" .. step
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model:SetAttribute("CooperativeSpineControl", true)
    model:SetAttribute("CommandStep", step)
    model.Parent = folder
    local frame = CFrame.new(center)
    visual(model, "CommandPedestal",
        Vector3.new(5.2, 0.34, 5.2),
        frame * CFrame.new(0, 0.17, 0),
        theme.Structure, Enum.Material.DiamondPlate)
    for side = -1, 1, 2 do
        visual(model, "Cantilever" .. side,
            Vector3.new(1.2, 5.6, 1.5),
            frame * CFrame.new(side * 3.2, 2.9, 0),
            theme.Structure, Enum.Material.Metal)
        visual(model, "PowerTrace" .. side,
            Vector3.new(0.26, 4.3, 0.32),
            frame * CFrame.new(side * 3.5, 3.0, 0),
            theme.Accent, Enum.Material.Neon, 0.28)
    end
    local core = visual(model, "CommandCore",
        Vector3.new(2.3, 2.3, 2.3),
        frame * CFrame.new(0, 3.1, 0),
        theme.Secondary, Enum.Material.Glass, 0.16)
    core.Shape = Enum.PartType.Ball
    visual(model, "CommandCrosshead",
        Vector3.new(7.1, 0.85, 1.35),
        frame * CFrame.new(0, 6, 0),
        theme.Structure, Enum.Material.Metal)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "ConnectSkySpine"
    prompt.ActionText = "CONNECT 3 SKY ROUTES"
    prompt.ObjectText = "TEAM SKY NETWORK"
    prompt.HoldDuration = SkySpineSwitchyard.HoldSeconds
    prompt.MaxActivationDistance = SkySpineSwitchyard.PromptDistance
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.Parent = core
    local gui = Instance.new("BillboardGui")
    gui.Name = "SkySpineSwitchyardStatus"
    gui.Size = UDim2.fromOffset(160, 38)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
    gui.MaxDistance = 48
    gui.Adornee = core
    gui.AlwaysOnTop = false
    gui.Parent = core
    local label = Instance.new("TextLabel")
    label.Name = "Status"
    label.BackgroundColor3 = Color3.fromRGB(14, 25, 41)
    label.BackgroundTransparency = 0.16
    label.BorderSizePixel = 0
    label.Size = UDim2.fromScale(1, 1)
    label.TextScaled = true
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = theme.Accent
    label.Text = "3 SKY ROUTES\nHOLD TO LINK"
    label.Parent = gui
    local rounded = Instance.new("UICorner")
    rounded.CornerRadius = UDim.new(0, 8)
    rounded.Parent = label
    return {model = model, prompt = prompt, core = core, label = label}
end

function SkySpineSwitchyard.start(ctx)
    if not SkySpineSwitchyard.allowed(ctx) then return 0 end
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local platforms = arena and arena:FindFirstChild("Platforms")
    if not arena or not platforms then return 0 end
    local decks, promenade = {}, {{}, {}}
    for _, part in ipairs(platforms:GetChildren()) do
        if part:IsA("BasePart") and part.CanCollide then
            if part:GetAttribute("SkySpineInterchange") == true then
                local index = tonumber(part:GetAttribute("SkySpineStep"))
                if index and index >= 1 and index <= 10
                    and index == math.floor(index) and not decks[index] then
                    decks[index] = part
                end
            end
            local lane = tonumber(part:GetAttribute("PromenadeLane"))
            local step = tonumber(part:GetAttribute("PromenadeStep"))
            if lane and step and (lane == 1 or lane == 2)
                and step >= 1 and step <= 8 and step == math.floor(step)
                and not promenade[lane][step] then
                promenade[lane][step] = part
            end
        end
    end
    for i = 1, 10 do if not decks[i] then return 0 end end
    local gaps, gapPairs, promenadeGaps = {}, {}, {}
    for i = 1, 9 do
        local center, size = SkySpineSwitchyard.gapBetween(
            decks[i], decks[i + 1])
        if not center or not size then return 0 end
        gaps[#gaps + 1] = {center = center, size = size}
        gapPairs[#gapPairs + 1] = {
            first = decks[i], second = decks[i + 1], spine = true,
            center = center, size = size,
        }
    end
    for lane = 1, 2 do
        for step = 1, 8 do
            if not promenade[lane][step] then return 0 end
        end
        for step = 1, 7 do
            local first, second =
                promenade[lane][step], promenade[lane][step + 1]
            local center, size =
                SkySpineSwitchyard.promenadeGapBetween(first, second)
            if not center or not size then return 0 end
            promenadeGaps[#promenadeGaps + 1] = {
                lane = lane, step = step, center = center, size = size,
            }
            gapPairs[#gapPairs + 1] = {
                first = first, second = second, spine = false,
                center = center, size = size,
            }
        end
    end
    local folder = Instance.new("Folder")
    folder.Name = "SkySpineSwitchyard"
    folder:SetAttribute("ServerAuthoritative", true)
    folder:SetAttribute("SkySpineConnected", false)
    folder:SetAttribute("SkyNetworkConnected", false)
    folder:SetAttribute("SkySpineGapCount", #gaps)
    folder:SetAttribute("SkyPromenadeGapCount", #promenadeGaps)
    folder:SetAttribute("SkyNetworkGapCount", #gapPairs)
    folder.Parent = arena
    table.insert(ctx.Cleanup, folder)
    local theme = VisualTheme.arena(
        tostring(arena:GetAttribute("VariantId") or "Classic"))
    local bridges = {}
    for i, gap in ipairs(gaps) do
        local bridge = visual(folder, "SpineGapBridge" .. i,
            gap.size, CFrame.new(gap.center),
            theme.Accent:Lerp(theme.Structure, 0.34),
            theme.PanelMaterial or Enum.Material.Metal, 1)
        bridge:SetAttribute("SkySpineGap", i)
        bridge:SetAttribute("SkySpineRescueBridge", true)
        bridge:SetAttribute("ChaosPermanentRoute", true)
        bridges[#bridges + 1] = bridge
        -- Two elegant secondary luminous rails on the REAL solid
        -- rescue connector. They only appear when it becomes traversable.
        for side = -1, 1, 2 do
            local lip = visual(folder,
                "SpineGapEdge" .. i .. "_" .. tostring(side),
                Vector3.new(0.24, 0.15, gap.size.Z),
                CFrame.new(gap.center) * CFrame.new(
                    side * (gap.size.X * 0.5 - 0.3),
                    gap.size.Y * 0.5 + 0.07, 0),
                theme.Secondary, Enum.Material.Neon, 1)
            bridge:SetAttribute("SkySpineGapEdgeCount", 2)
            lip:SetAttribute("SkySpineGapEdge", i)
        end
    end
    -- Both other corridors get the same instant physical rescue.
    -- No extra user action is needed after any one real switch is held.
    for _, gap in ipairs(promenadeGaps) do
        local id = tostring(gap.lane) .. "_" .. tostring(gap.step)
        local bridge = visual(folder, "PromenadeGapBridge" .. id,
            gap.size, CFrame.new(gap.center),
            theme.Accent:Lerp(theme.Structure, 0.34),
            theme.PanelMaterial or Enum.Material.Metal, 1)
        bridge:SetAttribute("SkyPromenadeGapLane", gap.lane)
        bridge:SetAttribute("SkyPromenadeGapStep", gap.step)
        bridge:SetAttribute("SkyPromenadeRescueBridge", true)
        bridge:SetAttribute("ChaosPermanentRoute", true)
        bridges[#bridges + 1] = bridge
        for side = -1, 1, 2 do
            local lip = visual(folder,
                "PromenadeGapEdge" .. id .. "_" .. tostring(side),
                Vector3.new(gap.size.X, 0.15, 0.24),
                CFrame.new(gap.center) * CFrame.new(
                    0, gap.size.Y * 0.5 + 0.07,
                    side * (gap.size.Z * 0.5 - 0.3)),
                theme.Secondary, Enum.Material.Neon, 1)
            lip:SetAttribute("SkyPromenadeGapEdge", true)
        end
    end
    -- Two existing genuine high-route intersections now also have a
    -- physical co-op command. A bot or human can help from any corridor.
    local commands = {
        station(folder, decks[3], 3, theme),
        station(folder, decks[8], 8, theme),
        station(folder, promenade[1][4], "North", theme),
        station(folder, promenade[2][4], "South", theme),
    }
    local round = {active = true, joined = false,
        folder = folder, ctx = ctx, commands = commands, decks = decks,
        gapPairs = gapPairs, bridges = bridges}
    activeRound = round
    local function current()
        return activeRound == round and round.active
            and folder.Parent == arena and ctx.Active()
    end
    local function validActor(actor, fromBot, command)
        if not current() or round.joined or not actor then return false end
        local root, human
        if fromBot then
            local bots = workspace:FindFirstChild("AISurvivors")
            if not bots or actor.Parent ~= bots or not actor:IsA("Model")
                or actor:GetAttribute("AISurvivor") ~= true
                or actor:GetAttribute("AISurvivorInRound") ~= true
                then return false end
            root = actor:FindFirstChild("HumanoidRootPart")
            human = actor:FindFirstChildOfClass("Humanoid")
            if not human or human.FloorMaterial == Enum.Material.Air then
                return false end
        else
            if actor.Parent ~= Players
                or actor:GetAttribute("DataLoaded") ~= true
                or not ctx.IsContestantActive(actor) then return false end
            local character = actor.Character
            root = character and character:FindFirstChild("HumanoidRootPart")
            human = character and character:FindFirstChildOfClass("Humanoid")
            if human and human.SeatPart then return false end
        end
        if not root or not root:IsA("BasePart") or not human
            or human.Health <= 0 or not root:IsDescendantOf(workspace)
            or (root.Position - command.core.Position).Magnitude
                > (fromBot and SkySpineSwitchyard.BotReach
                    or SkySpineSwitchyard.PromptDistance + 3) then
            return false
        end
        return true
    end

    local function activate(actor, fromBot, command)
        if not current() or not command.prompt.Enabled
            or not validActor(actor, fromBot, command)
            or ctx.FinalRush and ctx.FinalRush() then return false end
        -- Recheck every real 2.4-stud corridor gap immediately before
        -- making ANY bridge solid. A shrinking/moved/collapsing deck can
        -- never leave a floating collision strip behind, even if an
        -- unexpected disaster is activated after this round was built.
        for _, pair in ipairs(gapPairs) do
            local center, size = if pair.spine
                then SkySpineSwitchyard.gapBetween(
                    pair.first, pair.second)
                else SkySpineSwitchyard.promenadeGapBetween(
                    pair.first, pair.second)
            if not center or not size
                or (center - pair.center).Magnitude > 0.05
                or (size - pair.size).Magnitude > 0.05 then
                return false
            end
        end
        -- Atomic one-way transformation: once any survivor opens the
        -- passage the bridges NEVER vanish during the round. Other
        -- humans/bots cannot repeatedly activate or duplicate a reward.
        round.joined = true
        folder:SetAttribute("SkySpineConnected", true)
        folder:SetAttribute("SkyNetworkConnected", true)
        folder:SetAttribute("SkySpineActivatedByBot", fromBot == true)
        folder:SetAttribute("SkySpineActivatedAt",
            workspace:GetServerTimeNow())
        for _, bridge in ipairs(bridges) do
            bridge.CanCollide = true
            bridge.CanQuery = true
            bridge.Transparency = 0.04
        end
        for _, item in ipairs(folder:GetChildren()) do
            if item:IsA("BasePart")
                and (item:GetAttribute("SkySpineGapEdge")
                    or item:GetAttribute("SkyPromenadeGapEdge")) then
                item.Transparency = 0.20
            end
        end
        for _, control in ipairs(commands) do
            control.prompt.Enabled = false
            control.label.Text = fromBot
                and "ALLY LINKED\n3 SKY ROUTES"
                or "NETWORK LINKED\n3 SKY ROUTES"
            control.label.TextColor3 = theme.Secondary
            control.model:SetAttribute("SkySpineLinked", true)
        end
        return true
    end

    for _, command in ipairs(commands) do
        command.prompt.Triggered:Connect(function(player)
            activate(player, false, command)
        end)
    end
    round.activate = activate
    ctx.OnCleanup[#ctx.OnCleanup + 1] = function()
        round.active = false
        if activeRound == round then activeRound = nil end
        for _, command in ipairs(commands) do
            command.prompt.Enabled = false
        end
    end
    return 9
end

-- Bots already on a physically reached sky deck may operate a REAL
-- 0.7s cooperative switch, without pathfinding privilege or teleport.
-- These stable API methods exist before and after any round starts.
function SkySpineSwitchyard.botOpportunity(model, now)
    local round = activeRound
    if not round or not round.active or round.joined
        or not round.folder.Parent or not round.ctx.Active()
        or type(now) ~= "number"
        or typeof(model) ~= "Instance" or not model:IsA("Model") then
        return nil
    end
    local bots = workspace:FindFirstChild("AISurvivors")
    if not bots or model.Parent ~= bots
        or model:GetAttribute("AISurvivor") ~= true
        or model:GetAttribute("AISurvivorInRound") ~= true then
        return nil
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not root or not root:IsA("BasePart")
        or not root:IsDescendantOf(workspace)
        or not hum or hum.Health <= 0
        or hum.FloorMaterial == Enum.Material.Air then return nil end
    local best, distance = nil, SkySpineSwitchyard.BotReach
    for _, command in ipairs(round.commands) do
        if command.prompt.Enabled then
            local d = (root.Position - command.core.Position).Magnitude
            if d <= distance then
                best, distance = command, d
            end
        end
    end
    return best and best.core or nil
end

function SkySpineSwitchyard.activateBot(model, core)
    local round = activeRound
    if not round or not round.active or round.joined
        or not round.ctx.Active() or not round.folder.Parent then
        return false
    end
    if SkySpineSwitchyard.botOpportunity(model, os.clock()) ~= core then
        return false
    end
    for _, command in ipairs(round.commands) do
        if command.core == core then
            return round.activate(model, true, command)
        end
    end
    return false
end

return SkySpineSwitchyard
