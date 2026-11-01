-- SKYLINE EMERGENCY SHIELD NETWORK
-- Four large, genuinely interactive cooperative storm generators in each
-- arena during Meteor/Bomb rounds. Server-authoritative prompt, timed
-- protective volume and actual blast damage reduction for humans + bots.
-- No new RemoteEvents, monetization, client hit checks or render loops.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VisualTheme = require("../shared/VisualTheme")

local Shield = {}
Shield.Radius = 24
Shield.Height = 24
Shield.Duration = 8
Shield.Cooldown = 21
Shield.HoldSeconds = 0.65
Shield.PromptDistance = 10
Shield.DamageMultiplier = 0.42
Shield.Offsets = {
    Vector3.new(-53, 0, -17),
    Vector3.new(53, 0, 17),
    Vector3.new(-17, 0, 53),
    Vector3.new(17, 0, -53),
}

function Shield.enabled(ctx)
    return type(ctx) == "table"
        and type(ctx.Active) == "function"
        and type(ctx.IsContestantActive) == "function"
        and type(ctx.OnCleanup) == "table"
        and type(ctx.Cleanup) == "table"
        and (ctx.ActiveDisasters or {}).Meteors == true
            or type(ctx) == "table"
            and type(ctx.Active) == "function"
            and type(ctx.IsContestantActive) == "function"
            and type(ctx.OnCleanup) == "table"
            and type(ctx.Cleanup) == "table"
            and (ctx.ActiveDisasters or {}).Bombs == true
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
        Vector3.new(52, 52, 52),
        base * CFrame.new(0, 10, 0),
        theme.Accent:Lerp(Color3.fromRGB(210, 242, 255), 0.28),
        Enum.Material.Glass, 1)
    dome.Shape = Enum.PartType.Ball
    local ring = visual(model, "ActiveFieldCrown",
        Vector3.new(0.20, 49, 49),
        base * CFrame.new(0, 10, 0) * CFrame.Angles(0, 0, math.pi * 0.5),
        theme.Secondary, Enum.Material.Glass, 1)
    ring.Shape = Enum.PartType.Cylinder
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
        prompt = prompt, label = label, center = ground,
        activeUntil = 0, readyAt = 0, generation = 0,
        theme = theme, groundY = ground.Y,
    }
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
    local floorY = base.Position.Y + base.Size.Y * 0.5
    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local active = true
    ctx.OnCleanup[#ctx.OnCleanup + 1] = function()
        active = false
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
            if not withinFloor() then
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
        entry.prompt.Triggered:Connect(function(player)
            if not active or not ctx.Active() or not withinFloor()
                or not entry.prompt.Enabled or player.Parent ~= Players
                or player:GetAttribute("DataLoaded") ~= true
                or not ctx.IsContestantActive(player)
                or os.clock() < entry.readyAt then return end
            local character = player.Character
            local hum = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not hum or hum.Health <= 0 or not root
                or not root:IsA("BasePart")
                or (root.Position - entry.core.Position).Magnitude
                    > Shield.PromptDistance + 3 then return end
            local now = os.clock()
            entry.generation += 1
            local ticket = entry.generation
            entry.activeUntil = now + Shield.Duration
            entry.readyAt = now + Shield.Cooldown
            entry.model:SetAttribute("ShieldActiveUntil",
                workspace:GetServerTimeNow() + Shield.Duration)
            entry.model:SetAttribute("ShieldReadyAt",
                workspace:GetServerTimeNow() + Shield.Cooldown)
            entry.label.Text = "TEAM SHIELD\nPROTECTED"
            entry.label.TextColor3 = entry.theme.Secondary
            entry.dome.Transparency = 1
            entry.ring.Transparency = 1
            TweenService:Create(entry.dome, TweenInfo.new(0.3),
                {Transparency = 0.91}):Play()
            TweenService:Create(entry.ring, TweenInfo.new(0.3),
                {Transparency = 0.74}):Play()
            refresh()
            task.delay(Shield.Duration, function()
                if not active or ticket ~= entry.generation
                    or not entry.model.Parent then return end
                entry.dome.Transparency = 1
                entry.ring.Transparency = 1
                entry.label.Text = "TEAM SHIELD\nRECHARGING"
                entry.label.TextColor3 = entry.theme.Detail
                refresh()
            end)
            task.delay(Shield.Cooldown, function()
                if not active or ticket ~= entry.generation
                    or not entry.model.Parent then return end
                entry.label.Text = "TEAM SHIELD\nHOLD TO ACTIVATE"
                entry.label.TextColor3 = entry.theme.Accent
                refresh()
            end)
        end)
        refresh()
    end
    folder:SetAttribute("ShieldStationCount", #stations)

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
            if entry.model.Parent and now < entry.activeUntil
                and Shield.contains(entry.center, position, entry.groundY)
            then
                return Shield.damageAfterProtection(damage)
            end
        end
        return damage
    end
end

return Shield
