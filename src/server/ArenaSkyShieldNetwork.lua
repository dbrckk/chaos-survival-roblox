-- SKYLINE EMERGENCY SHIELD NETWORK
-- Four large, genuinely interactive cooperative storm generators in each
-- arena during Meteor/Bomb rounds. Server-authoritative prompt, timed
-- protective volume and actual blast damage reduction for humans + bots.
-- No new RemoteEvents, monetization, client hit checks or render loops.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
-- Published Roblox places use the actual shared ModuleScript. Engine source
-- specs may load this repo before the published place contains new modules.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:FindFirstChild("Shared")
local visualThemeModule = shared and shared:FindFirstChild("VisualTheme")
local VisualTheme = if visualThemeModule
    then require(visualThemeModule)
    else require("../shared/VisualTheme")

local Shield = {}
Shield.Radius = 24
Shield.Height = 24
Shield.LinkHalfWidth = 9
Shield.MaxLinkedStations = 4
Shield.Duration = 8
Shield.Cooldown = 21
Shield.HoldSeconds = 0.65
Shield.PromptDistance = 10
Shield.DamageMultiplier = 0.42
Shield.BotApproachRadius = 74
Shield.BotReach = 7.5
local activeRound = nil
Shield.Offsets = {
    -- Visible from the initial eight spawn pads: every first-minute
    -- participant is within 24 studs of at least one real defense zone.
    Vector3.new(-48, 0, -16),
    Vector3.new(48, 0, 16),
    Vector3.new(-16, 0, 48),
    Vector3.new(16, 0, -48),
}

function Shield.enabled(ctx)
    if type(ctx) ~= "table"
        or type(ctx.Active) ~= "function"
        or type(ctx.IsContestantActive) ~= "function"
        or type(ctx.OnCleanup) ~= "table"
        or type(ctx.Cleanup) ~= "table" then return false end
    local active = ctx.ActiveDisasters
    return type(active) == "table"
        and (active.Meteors == true or active.Bombs == true)
end

-- Pure server geometry: only the energy volume which is currently
-- visible on the map can reduce a real blast's delivered damage.
function Shield.contains(center, position, floorY)
    if typeof(center) ~= "Vector3" or typeof(position) ~= "Vector3"
        or type(floorY) ~= "number" then return false end
    local dx, dz = position.X - center.X, position.Z - center.Z
    return dx * dx + dz * dz <= Shield.Radius * Shield.Radius
        and position.Y >= floorY - 2
        and position.Y <= floorY + Shield.Height
end

-- When two different players (or an AI helper) activate separate
-- generators, the interval between their fields becomes a real tactical
-- safe corridor. This geometry is shared by every real human AND AI bot.
-- It never extends beyond either live endpoint or above the server's
-- 24-stud shield ceiling; no client can declare a protected position.
function Shield.linkContains(a, b, position, groundY)
    if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3"
        or typeof(position) ~= "Vector3"
        or type(groundY) ~= "number"
        or position.Y < groundY - 2
        or position.Y > groundY + Shield.Height then return false end
    local dx, dz = b.X - a.X, b.Z - a.Z
    local span2 = dx * dx + dz * dz
    if span2 < 64 or span2 ~= span2 then return false end
    local along = ((position.X - a.X) * dx
        + (position.Z - a.Z) * dz) / span2
    if along < 0 or along > 1 then return false end
    local px, pz = a.X + dx * along, a.Z + dz * along
    local ox, oz = position.X - px, position.Z - pz
    return ox * ox + oz * oz
        <= Shield.LinkHalfWidth * Shield.LinkHalfWidth
end

function Shield.damageAfterProtection(damage)
    local n = tonumber(damage)
    if not n or n <= 0 or n ~= n or n == math.huge then return damage end
    return math.max(1, math.floor(n * Shield.DamageMultiplier + 0.5))
end

local function visual(parent, name, size, frame, color, material, alpha)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = frame
    p.Color = color
    p.Material = material
    p.Transparency = alpha or 0
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Parent = parent
    return p
end

-- Four large defensive machines can create up to SIX real, temporary
-- corridors as teammates coordinate. These are world-scaled volumetric
-- links, not fullscreen HUD tricks. All sections are anchored and inert.
local function makeLink(folder, from, to, variant)
    local delta = to.center - from.center
    local flat = Vector3.new(delta.X, 0, delta.Z)
    local span = flat.Magnitude
    local theme = VisualTheme.arena(variant)
    local center = (from.center + to.center) * 0.5
    local frame = CFrame.lookAt(
        center + Vector3.new(0, 0.34, 0),
        center + Vector3.new(0, 0.34, 0) + flat.Unit)
    local model = Instance.new("Model")
    model.Name = "ShieldCorridor" .. from.index .. "_" .. to.index
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model:SetAttribute("ShieldCorridor", true)
    model:SetAttribute("LinkedStations", 2)
    model:SetAttribute("ShieldCorridorActive", false)
    model:SetAttribute("ShieldAbsorbedDamage", 0)
    model:SetAttribute("ShieldActiveUntil", 0)
    local sections = {}
    for side = -1, 1, 2 do
        sections[#sections + 1] = visual(
            model, "ProtectiveGroundRail" .. side,
            Vector3.new(0.38, 0.24, span),
            frame * CFrame.new(side * Shield.LinkHalfWidth, 0, 0),
            theme.Accent, Enum.Material.Neon, 1)
        sections[#sections + 1] = visual(
            model, "ProtectiveUpperRail" .. side,
            Vector3.new(0.22, 0.22, span),
            frame * CFrame.new(side * Shield.LinkHalfWidth, 11, 0),
            theme.Secondary, Enum.Material.Neon, 1)
    end
    for quarter = 1, 3 do
        sections[#sections + 1] = visual(
            model, "CrossingBeacon" .. quarter,
            Vector3.new(Shield.LinkHalfWidth * 2, 0.14, 0.36),
            frame * CFrame.new(0, 0, (quarter - 2) * span * 0.25),
            theme.Detail, Enum.Material.Neon, 1)
    end
    model.Parent = folder
    return {from = from, to = to, model = model, sections = sections,
        live = false, deadline = 0, generation = 0, absorbed = 0}
end

local function build(folder, ground, index, variant)
    local theme = VisualTheme.arena(variant)
    local model = Instance.new("Model")
    model.Name = "EmergencySkyShield" .. index
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model:SetAttribute("EmergencyTeamShield", true)
    model:SetAttribute("ShieldIndex", index)
    model:SetAttribute("ShieldPhase", "Ready")
    model:SetAttribute("ShieldActiveUntil", 0)
    model:SetAttribute("ShieldReadyAt", 0)
    model:SetAttribute("ShieldAbsorbedDamage", 0)
    model:SetAttribute("ShieldProtections", 0)
    model:SetAttribute("ShieldActivatedByBot", false)
    local base = CFrame.new(ground)
    local structure = theme.Structure:Lerp(theme.Detail, 0.35)
    visual(model, "Foundation", Vector3.new(8, 0.28, 8),
        base * CFrame.new(0, 0.14, 0), structure, Enum.Material.DiamondPlate)
    for side = -1, 1, 2 do
        visual(model, "LoadPier" .. side, Vector3.new(1.5, 9.3, 2.1),
            base * CFrame.new(side * 4.0, 4.75, 0),
            structure, Enum.Material.Metal)
        visual(model, "EnergyBus" .. side, Vector3.new(0.5, 6, 0.7),
            base * CFrame.new(side * 4.25, 5.0, -1.2),
            theme.Secondary, Enum.Material.Neon, 0.30)
    end
    local core = visual(model, "ShieldGeneratorCore",
        Vector3.new(3.7, 3.7, 3.7), base * CFrame.new(0, 4.3, 0),
        theme.Accent, Enum.Material.Glass, 0.18)
    core.Shape = Enum.PartType.Ball
    visual(model, "OverheadCrossbeam", Vector3.new(8.5, 1.1, 2.0),
        base * CFrame.new(0, 9.9, 0), structure, Enum.Material.Metal)
    visual(model, "SkylineAntenna", Vector3.new(0.42, 5.0, 0.42),
        base * CFrame.new(0, 12.85, 0),
        theme.Detail, Enum.Material.Metal)

    -- Each universe gets recognizably different equipment on the same
    -- original, physical player interaction point.
    if variant == "Classic" then
        local dish = visual(model, "RadarDish", Vector3.new(0.5, 5.8, 5.8),
            base * CFrame.new(0, 15.3, 0) * CFrame.Angles(0, 0, 0.25),
            theme.Secondary, Enum.Material.Metal, 0.12)
        dish.Shape = Enum.PartType.Cylinder
    elseif variant == "Towers" then
        visual(model, "FreightShuttle", Vector3.new(5.8, 2.5, 3.5),
            base * CFrame.new(0, 15.4, 0), theme.Secondary,
            Enum.Material.CorrodedMetal)
    elseif variant == "Crossroads" then
        for side = -1, 1, 2 do
            visual(model, "SwitchFin" .. side, Vector3.new(3.5, 2.2, 0.75),
                base * CFrame.new(side * 2.7, 15.2, 0)
                    * CFrame.Angles(0, 0, math.rad(side * 25)),
                theme.Secondary, Enum.Material.Metal)
        end
    elseif variant == "Orbital" then
        local halo = visual(model, "ContainmentHalo", Vector3.new(0.5, 7.5, 7.5),
            base * CFrame.new(0, 15.7, 0)
                * CFrame.Angles(0, 0, math.pi * 0.5),
            theme.Secondary, Enum.Material.CeramicTiles, 0.2)
        halo.Shape = Enum.PartType.Cylinder
    elseif variant == "Harbor" then
        visual(model, "FreightCrane", Vector3.new(8.3, 0.9, 2.1),
            base * CFrame.new(1.2, 15.3, 0),
            theme.Secondary, Enum.Material.CorrodedMetal)
        visual(model, "SuspendedLoad", Vector3.new(2.2, 2.4, 2.4),
            base * CFrame.new(4.0, 12.6, 0),
            theme.Detail, Enum.Material.WoodPlanks)
    end

    -- The translucent protective volume is genuinely large, but doesn't
    -- become a fake solid ceiling or hide Roblox damage telegraphs.
    local dome = visual(model, "ActiveProtectiveField",
        -- Cylinder's axis is local X: rotate 90 degrees to make a REAL
        -- 48-stud-wide vertical enclosure matching the server's area.
        Vector3.new(Shield.Height + 2, Shield.Radius * 2, Shield.Radius * 2),
        base * CFrame.new(0, Shield.Height * 0.5 - 1, 0)
            * CFrame.Angles(0, 0, math.pi * 0.5),
        theme.Accent:Lerp(Color3.fromRGB(210, 242, 255), 0.28),
        Enum.Material.Glass, 1)
    dome.Shape = Enum.PartType.Cylinder
    local ring = visual(model, "ActiveFieldCrown",
        -- A compact overhead crown rather than an opaque floor disk:
        -- warning circles must remain legible through the shield.
        Vector3.new(0.20, 8, 8),
        base * CFrame.new(0, 10.25, 0)
            * CFrame.Angles(0, 0, math.pi * 0.5),
        theme.Secondary, Enum.Material.Glass, 1)
    ring.Shape = Enum.PartType.Cylinder
    -- Eight thin perimeter edges instead of a floor-covering warning disc.
    -- Shield effects never obscure real meteor impact circles.
    local boundary = {}
    for sector = 1, 8 do
        local angle = (sector - 1) * math.pi * 0.25
        local x = math.cos(angle) * Shield.Radius
        local z = math.sin(angle) * Shield.Radius
        local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
        local point = ground + Vector3.new(x, 0.25, z)
        boundary[#boundary + 1] = visual(
            model, "ShieldPerimeter" .. sector,
            Vector3.new(0.34, 0.32, 17.5),
            CFrame.lookAt(point, point + tangent),
            theme.Accent:Lerp(theme.Secondary, 0.28),
            Enum.Material.Neon, 1
        )
    end
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "ActivateEmergencyShield"
    prompt.ActionText = "PROTECT TEAM"
    prompt.ObjectText = "SKYLINE SHIELD"
    prompt.HoldDuration = Shield.HoldSeconds
    prompt.MaxActivationDistance = Shield.PromptDistance
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.Parent = core

    local tag = Instance.new("BillboardGui")
    tag.Name = "EmergencyShieldLabel"
    tag.Adornee = core
    tag.Size = UDim2.fromOffset(170, 46)
    tag.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
    tag.MaxDistance = 90
    tag.AlwaysOnTop = false
    tag.Parent = core
    local label = Instance.new("TextLabel")
    label.Name = "State"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(15, 29, 41)
    label.BackgroundTransparency = 0.22
    label.BorderSizePixel = 0
    label.TextScaled = true
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = theme.Accent
    label.Text = "TEAM SHIELD\nHOLD TO ACTIVATE"
    label.Parent = tag
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label
    model.Parent = folder
    return {
        model = model, core = core, dome = dome, ring = ring,
        boundary = boundary, prompt = prompt, label = label, center = ground,
        activeUntil = 0, readyAt = 0, generation = 0,
        theme = theme, groundY = ground.Y,
        floorValid = true, guard = false,
        domeTween = nil, crownTween = nil,
        absorbed = 0, protections = 0, lastImpactAt = -math.huge,
        claim = nil, claimUntil = 0,
    }
end

-- Real AI participants can operate the SAME non-colliding prompt station
-- as a human, but only to protect a live human beneficiary nearby. One
-- bounded reservation per structure prevents 7 bots swarming the console.
local function botRoot(model)
    local folder = workspace:FindFirstChild("AISurvivors")
    if typeof(model) ~= "Instance" or not model:IsA("Model")
        or not folder or model.Parent ~= folder
        or model:GetAttribute("AISurvivor") ~= true
        or model:GetAttribute("AISurvivorInRound") ~= true
    then return nil end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or not root
        or not root:IsA("BasePart")
        or not root:IsDescendantOf(workspace) then return nil end
    return root, hum
end

local function humanBeneficiary(round, entry)
    for _, player in ipairs(round.ctx.Contestants or {}) do
        if player.Parent == Players
            and player:GetAttribute("DataLoaded") == true
            and round.ctx.IsContestantActive(player) then
            local character = player.Character
            local hum = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root and root:IsA("BasePart")
                and Shield.contains(entry.center, root.Position, entry.groundY)
            then return true end
        end
    end
    return false
end

function Shield.releaseBot(model)
    local round = activeRound
    if not round then return end
    for _, entry in ipairs(round.stations) do
        if entry.claim == model then
            entry.claim = nil
            entry.claimUntil = 0
        end
    end
end

function Shield.botOpportunity(model, now, preferred)
    local round = activeRound
    local root = botRoot(model)
    if not round or not round.active() or not round.ctx.Active()
        or not root or type(now) ~= "number"
        or not round.folder.Parent then return nil end
    local chosen, nearest = nil, Shield.BotApproachRadius
    for _, entry in ipairs(round.stations) do
        local delta = entry.core.Position - root.Position
        local flat = Vector3.new(delta.X, 0, delta.Z).Magnitude
        local reserved = entry.claim and entry.claim ~= model
            and (entry.claimUntil or 0) > now
        if entry.model.Parent == round.folder
            and entry.floorValid and entry.prompt.Enabled
            and now >= entry.readyAt
            and not entry.guard and not reserved
            and math.abs(delta.Y) < 8
            and flat <= nearest
            and (preferred == nil or preferred == entry.core)
            and humanBeneficiary(round, entry) then
            chosen, nearest = entry, flat
        end
    end
    if not chosen then return nil end
    chosen.claim, chosen.claimUntil = model, now + 5
    return Vector3.new(chosen.core.Position.X, root.Position.Y,
        chosen.core.Position.Z), chosen.core
end

-- The ONE authoritative activation path for human prompts and AI agency.
-- Bots cannot spoof ProximityPrompt.Triggered or bypass the normal hold
-- time; their AI brain performs its own physical approach and hold.
function Shield.activate(entry, actor, fromBot)
    local round = activeRound
    if not round or not round.active() or not round.ctx.Active()
        or not entry or entry.model.Parent ~= round.folder
        or not entry.floorValid or not entry.prompt.Enabled
        or entry.guard or os.clock() < entry.readyAt then return false end

    local root
    if fromBot then
        local hum
        root, hum = botRoot(actor)
        if not root or hum.FloorMaterial == Enum.Material.Air
            or (root.Position - entry.core.Position).Magnitude > Shield.BotReach
            or not humanBeneficiary(round, entry) then
            return false
        end
    else
        if not actor or actor.Parent ~= Players
            or actor:GetAttribute("DataLoaded") ~= true
            or not round.ctx.IsContestantActive(actor) then return false end
        local character = actor.Character
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        root = character and character:FindFirstChild("HumanoidRootPart")
        if not hum or hum.Health <= 0 or not root
            or not root:IsA("BasePart")
            or not root:IsDescendantOf(workspace)
            or (root.Position - entry.core.Position).Magnitude
                > Shield.PromptDistance + 3 then return false end
    end

    entry.guard = true
    local now = os.clock()
    entry.generation += 1
    local ticket = entry.generation
    entry.activeUntil = now + Shield.Duration
    entry.readyAt = now + Shield.Cooldown
    entry.absorbed = 0
    entry.protections = 0
    entry.lastImpactAt = -math.huge
    entry.model:SetAttribute("ShieldAbsorbedDamage", 0)
    entry.model:SetAttribute("ShieldProtections", 0)
    entry.model:SetAttribute("ShieldActivatedByBot", fromBot == true)
    entry.model:SetAttribute("ShieldActiveUntil",
        workspace:GetServerTimeNow() + Shield.Duration)
    entry.model:SetAttribute("ShieldReadyAt",
        workspace:GetServerTimeNow() + Shield.Cooldown)
    entry.label.Text = fromBot
        and "ALLY ACTIVATED\nSHIELD ACTIVE"
        or "TEAM SHIELD\nPROTECTED"
    entry.label.TextColor3 = entry.theme.Secondary
    entry.dome.Transparency = 1
    entry.ring.Transparency = 1
    for _, segment in ipairs(entry.boundary) do
        segment.Transparency = 0.22
    end
    if entry.domeTween then entry.domeTween:Cancel() end
    if entry.crownTween then entry.crownTween:Cancel() end
    entry.domeTween = TweenService:Create(entry.dome, TweenInfo.new(0.30),
        {Transparency = 0.91})
    entry.crownTween = TweenService:Create(entry.ring, TweenInfo.new(0.30),
        {Transparency = 0.54})
    entry.domeTween:Play()
    entry.crownTween:Play()
    entry.refresh()

    task.delay(Shield.Duration, function()
        if not round.active() or ticket ~= entry.generation
            or not entry.model.Parent then return end
        if entry.domeTween then entry.domeTween:Cancel() end
        if entry.crownTween then entry.crownTween:Cancel() end
        entry.dome.Transparency = 1
        entry.ring.Transparency = 1
        for _, segment in ipairs(entry.boundary) do
            segment.Transparency = 1
        end
        entry.label.Text = "TEAM SHIELD\nRECHARGING"
        entry.label.TextColor3 = entry.theme.Detail
        entry.refresh()
    end)
    task.delay(Shield.Cooldown, function()
        if not round.active() or ticket ~= entry.generation
            or not entry.model.Parent then return end
        entry.label.Text = "TEAM SHIELD\nHOLD TO ACTIVATE"
        entry.label.TextColor3 = entry.theme.Accent
        entry.refresh()
    end)
    entry.guard = false
    return true
end

function Shield.activateBot(model, now, preferred)
    local _, core = Shield.botOpportunity(model, now, preferred)
    if not core then return false end
    local round = activeRound
    if not round then return false end
    for _, entry in ipairs(round.stations) do
        if entry.core == core then
            local ok = Shield.activate(entry, model, true)
            if ok then Shield.releaseBot(model) end
            return ok
        end
    end
    return false
end

function Shield.start(ctx)
    if not Shield.enabled(ctx) or not ctx.Active() then return nil end
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") or not base.CanCollide
        or math.min(base.Size.X, base.Size.Z) < 280 then return nil end
    local folder = Instance.new("Folder")
    folder.Name = "EmergencySkyShields"
    folder:SetAttribute("ServerAuthoritative", true)
    folder.Parent = arena
    ctx.Cleanup[#ctx.Cleanup + 1] = folder
    local stations = {}
    local links = {}
    local floorY = base.Position.Y + base.Size.Y * 0.5
    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local active = true
    local round = {ctx = ctx, folder = folder, stations = stations,
        base = base, active = function() return active end}
    activeRound = round
    ctx.OnCleanup[#ctx.OnCleanup + 1] = function()
        if activeRound == round then activeRound = nil end
        active = false
        for _, link in pairs(links) do
            link.generation += 1
            link.live = false
            if link.model.Parent then
                link.model:SetAttribute("ShieldCorridorActive", false)
                link.model:SetAttribute("ShieldActiveUntil", 0)
            end
        end
        for _, entry in ipairs(stations) do
            entry.generation += 1
            entry.prompt.Enabled = false
            if entry.model.Parent then
                entry.model:SetAttribute("ShieldPhase", "Offline")
            end
        end
    end

    for i, offset in ipairs(Shield.Offsets) do
        local localPoint = base.CFrame * CFrame.new(
            offset.X, base.Size.Y * 0.5, offset.Z)
        local position = Vector3.new(localPoint.X, floorY, localPoint.Z)
        local entry = build(folder, position, i, variant)
        stations[#stations + 1] = entry
        local function withinFloor()
            local localP = base.CFrame:PointToObjectSpace(entry.center)
            return math.abs(localP.X) + 7 < base.Size.X * 0.5
                and math.abs(localP.Z) + 7 < base.Size.Z * 0.5
        end

        local function refresh()
            if not active or not entry.model.Parent then return end
            local now = os.clock()
            entry.floorValid = withinFloor()
            if not entry.floorValid then
                -- Shrinking can retract the floor from a live generator.
                -- Never leave a visible shield or residual damage benefit
                -- floating above the void.
                entry.activeUntil = 0
                entry.model:SetAttribute("ShieldActiveUntil", 0)
                entry.label.Text = "SHIELD OFFLINE\nUNSAFE FLOOR"
                entry.label.TextColor3 = entry.theme.Detail
                if entry.domeTween then entry.domeTween:Cancel() end
                if entry.crownTween then entry.crownTween:Cancel() end
                entry.dome.Transparency = 1
                entry.ring.Transparency = 1
                for _, segment in ipairs(entry.boundary) do
                    segment.Transparency = 1
                end
                entry.prompt.Enabled = false
                entry.model:SetAttribute("ShieldPhase", "Offline")
            elseif now < entry.activeUntil then
                entry.prompt.Enabled = false
                entry.model:SetAttribute("ShieldPhase", "Protected")
            elseif now < entry.readyAt then
                entry.prompt.Enabled = false
                entry.model:SetAttribute("ShieldPhase", "Recharging")
            else
                entry.prompt.Enabled = ctx.Active()
                entry.model:SetAttribute("ShieldPhase",
                    ctx.Active() and "Ready" or "Offline")
            end
        end

        local connection = base:GetPropertyChangedSignal("Size"):Connect(refresh)
        ctx.OnCleanup[#ctx.OnCleanup + 1] = function()
            connection:Disconnect()
        end
        entry.refresh = refresh
        entry.prompt.Triggered:Connect(function(player)
            Shield.activate(entry, player, false)
        end)
        refresh()
    end
    folder:SetAttribute("ShieldStationCount", #stations)

    -- Exactly one bounded event-driven update per activation, expiry or
    -- collapsing-floor Size change; NO permanent server or client loop.
    local function refreshLinks()
        if not active or not ctx.Active() or not folder.Parent then return end
        local now = os.clock()
        local activeCount = 0
        for index = 1, math.min(#stations, Shield.MaxLinkedStations) do
            if stations[index].floorValid and now < stations[index].activeUntil then
                activeCount += 1
            end
        end
        folder:SetAttribute("ActiveShieldGenerators", activeCount)
        local linkedCount = 0
        for i = 1, math.min(#stations, Shield.MaxLinkedStations) do
            for j = i + 1, math.min(#stations, Shield.MaxLinkedStations) do
                local from, to = stations[i], stations[j]
                local deadline = math.min(from.activeUntil, to.activeUntil)
                local shouldLink = from.floorValid and to.floorValid
                    and from.model.Parent and to.model.Parent
                    and now < deadline
                local key = tostring(i) .. "_" .. tostring(j)
                local link = links[key]
                if shouldLink and not link then
                    link = makeLink(folder, from, to, variant)
                    links[key] = link
                end
                if link then
                    if shouldLink then
                        linkedCount += 1
                        if not link.live then
                            link.live = true
                            link.absorbed = 0
                            link.model:SetAttribute("ShieldAbsorbedDamage", 0)
                            link.model:SetAttribute("ShieldCorridorActive", true)
                            for _, section in ipairs(link.sections) do
                                section.Transparency = section.Name:find("Upper")
                                    and 0.52 or 0.18
                            end
                        end
                        if math.abs(link.deadline - deadline) > 0.01 then
                            link.deadline = deadline
                            link.generation += 1
                            local generation = link.generation
                            link.model:SetAttribute("ShieldActiveUntil",
                                workspace:GetServerTimeNow()
                                    + math.max(0, deadline - now))
                            task.delay(math.max(0.02, deadline - now), function()
                                if active and link.generation == generation then
                                    refreshLinks()
                                end
                            end)
                        end
                    elseif link.live then
                        link.live = false
                        link.deadline = 0
                        link.generation += 1
                        link.model:SetAttribute("ShieldCorridorActive", false)
                        link.model:SetAttribute("ShieldActiveUntil", 0)
                        for _, section in ipairs(link.sections) do
                            section.Transparency = 1
                        end
                    end
                end
            end
        end
        folder:SetAttribute("ActiveShieldCorridors", linkedCount)
    end
    round.refreshLinks = refreshLinks
    refreshLinks()

    -- The exact damage pass in DisasterImpact is authoritative.  No
    -- client-reported world position or instant-dodge privilege exists.
    return function(position, kind, damage)
        if not active or not ctx.Active() or not arena.Parent
            or kind ~= "Meteor" and kind ~= "Bomb"
            or typeof(position) ~= "Vector3" then
            return damage
        end
        local now = os.clock()
        for _, entry in ipairs(stations) do
            if entry.model.Parent and entry.floorValid
                and now < entry.activeUntil
                and Shield.contains(entry.center, position, entry.groundY) then
                local reduced = Shield.damageAfterProtection(damage)
                local saved = math.max(0, damage - reduced)
                if saved > 0 then
                    entry.absorbed += saved
                    entry.protections += 1
                    entry.model:SetAttribute("ShieldAbsorbedDamage",
                        math.floor(entry.absorbed))
                    entry.model:SetAttribute("ShieldProtections",
                        entry.protections)
                    entry.label.Text = "SHIELD ACTIVE\n"
                        .. tostring(math.floor(entry.absorbed)) .. " HP SAVED"
                    -- An actual absorbed hit physically ripples the
                    -- 3D generator crown, rather than inventing a red
                    -- warning or changing any gameplay collision.
                    if now - entry.lastImpactAt >= 0.35 then
                        entry.lastImpactAt = now
                        entry.ring.Size = Vector3.new(0.2, 8, 8)
                        entry.ring.Transparency = 0.36
                        if entry.crownTween then
                            entry.crownTween:Cancel()
                        end
                        entry.crownTween = TweenService:Create(entry.ring,
                            TweenInfo.new(0.42, Enum.EasingStyle.Quad,
                                Enum.EasingDirection.Out),
                            {Size = Vector3.new(0.2, 15, 15),
                                Transparency = 0.54})
                        entry.crownTween:Play()
                    end
                end
                return reduced
            end
        end
        return damage
    end
end

return Shield
