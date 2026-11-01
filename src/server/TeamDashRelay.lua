-- Genuine cooperative environment interaction for EVERY arena.
-- Two compact server-owned consoles per round; press/hold on Android,
-- keyboard or controller to replenish nearby living human survivors' DASH.
-- A ready survivor receives exactly ONE future emergency follow-up DASH.
-- No clients can choose recipients or rewards. No per-frame update loops.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SpawnSafety = require(script.Parent.SpawnSafety)

local TeamDashRelay = {}

TeamDashRelay.PromptDistance = 9
TeamDashRelay.Radius = 29
TeamDashRelay.HoldSeconds = 0.65
TeamDashRelay.MinRoundSeconds = 20

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
    label.MaxDistance = 65
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
            local used = false
            local guard = false
            local function refresh()
                local delta = entry.core.Position - base.Position
                entry.prompt.Enabled = not used and ctx.Active()
                    and base.CanCollide
                    and math.abs(delta.X) + 7 < base.Size.X * 0.5
                    and math.abs(delta.Z) + 7 < base.Size.Z * 0.5
            end
            local shrink = base:GetPropertyChangedSignal("Size"):Connect(refresh)
            entry.model.Destroying:Connect(function()
                shrink:Disconnect()
            end)
            refresh()

            entry.prompt.Triggered:Connect(function(player)
                if guard or used or not entry.prompt.Enabled
                    or not TeamDashRelay.canUse(
                        ctx, base, entry.core, player, os.clock()
                    ) then return end
                guard = true
                local helped = {}
                for _, target in ipairs(ctx.Contestants or {}) do
                    if ctx.IsContestantActive(target) then
                        local root = validCharacter(target)
                        if root and (root.Position - entry.core.Position).Magnitude
                            <= TeamDashRelay.Radius then
                            -- A failing benefit callback must not leave a
                            -- station permanently locked or prevent others
                            -- from receiving their own valid server charge.
                            local ok, success, kind = pcall(
                                ctx.OnTeamDashCharge, target
                            )
                            if ok and success == true then
                                helped[#helped + 1] = {
                                    player = target, kind = kind
                                }
                            end
                        end
                    end
                end
                if #helped > 0 then
                    used = true
                    entry.model:SetAttribute("RelayUsed", true)
                    entry.model:SetAttribute("TeamBeneficiaries", #helped)
                    entry.core.Color = Color3.fromRGB(66, 97, 106)
                    -- One short shared environmental reaction; clients
                    -- see that a teammate used the physical console, but
                    -- hazard warning red/orange keeps higher visual priority.
                    entry.pulse.Transparency = 0.86
                    local pulseTween = TweenService:Create(entry.pulse,
                        TweenInfo.new(0.7, Enum.EasingStyle.Quad,
                            Enum.EasingDirection.Out),
                        {Transparency = 1})
                    pulseTween:Play()
                    pulseTween.Completed:Once(function()
                        pulseTween:Destroy()
                    end)
                    entry.label.Text = "TEAM DASH\nRELAY USED"
                    entry.label.TextColor3 = Color3.fromRGB(151, 179, 188)
                    refresh()
                    if type(ctx.OnTeamDashUsed) == "function" then
                        pcall(ctx.OnTeamDashUsed, player, index, helped)
                    end
                end
                guard = false
            end)
        end
    end
    folder:SetAttribute("RelayCount", built)
    return built
end

return TeamDashRelay
