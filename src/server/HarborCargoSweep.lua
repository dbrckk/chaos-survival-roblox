-- STORM HARBOR / CARGO SWEEP
-- An original port hazard: a visible, rotating crane-service lane turns
-- amber (2.6s), pulses red (0.9s), and nudges runners toward the SAFE
-- middle of the arena. The floor never disappears and every elevated
-- cargo route remains safe. Players and R15 bots use the SAME check.
-- Four anchored, non-colliding bands; no damage, RemoteEvents, physics
-- constraints, RenderStepped or new per-frame client work.
local movementModule = script and script.Parent:FindFirstChild("MovementSafety")
local MovementSafety = if movementModule
    then require(movementModule) else require("./MovementSafety")

local HarborCargoSweep = {}

HarborCargoSweep.InitialDelay = 7
HarborCargoSweep.WarningSeconds = 2.6
HarborCargoSweep.PulseSeconds = 0.9
HarborCargoSweep.BetweenEvents = 7.0
HarborCargoSweep.SampleSeconds = 0.15
HarborCargoSweep.Push = 17

local CONFLICTS = {
    -- Never compound forced motion, floor loss or a rising kill plane.
    DisappearingPlatforms = true,
    ShrinkingArena = true,
    RisingLava = true,
    Freeze = true,
    Tornado = true,
    JumpShock = true,
    LowGravity = true,
    SpeedSurge = true,
}

function HarborCargoSweep.allowed(ctx)
    if type(ctx) ~= "table" or ctx.EnableHarborCargoSweep ~= true
        or type(ctx.Active) ~= "function"
        or type(ctx.OnCleanup) ~= "table"
    then return false end
    for id in pairs(ctx.ActiveDisasters or {}) do
        if CONFLICTS[id] then return false end
    end
    return true
end

function HarborCargoSweep.canComplete(ctx, now)
    local deadline = tonumber(ctx and ctx.RoundEndsAt)
    if not deadline then return true end
    local clock = tonumber(now)
    if not clock or clock ~= clock or clock == math.huge then
        return false
    end
    return clock + HarborCargoSweep.WarningSeconds
        + HarborCargoSweep.PulseSeconds + 2 <= deadline
end

-- Alternate the four port service lanes across consecutive waves and
-- rounds: never strike the same lane twice in a row within a round.
function HarborCargoSweep.laneIndex(roundNumber, wave)
    local round = math.max(1, math.floor(tonumber(roundNumber) or 1))
    local count = math.max(0, math.floor(tonumber(wave) or 0))
    return ((round - 1 + count) % 4) + 1
end

-- Require the R15/R6 HumanoidRootPart to be near the floor in the
-- *actual* footprint. A well-timed jump or high cargo platform is safe.
function HarborCargoSweep.inside(position, band)
    if typeof(position) ~= "Vector3" or not band
        or not band:IsA("BasePart") then return false end
    local localPoint = band.CFrame:PointToObjectSpace(position)
    return math.abs(localPoint.X) <= band.Size.X * 0.5 + 0.3
        and math.abs(localPoint.Z) <= band.Size.Z * 0.5 + 0.3
        and localPoint.Y >= 1 and localPoint.Y <= 5.1
end

-- Push TOWARD the middle of the 320-stud harbor, never off an edge.
-- Existing speed caps make this a displacement choice rather than an
-- execution; only one short pulse per subject per wave.
function HarborCargoSweep.velocity(previous, band, center)
    if not band or not band:IsA("BasePart")
        or typeof(center) ~= "Vector3" then return previous end
    local acrossX = band.Size.X < band.Size.Z
    local inward
    if acrossX then
        inward = Vector3.new(band.Position.X >= center.X and -1 or 1, 0, 0)
    else
        inward = Vector3.new(0, 0, band.Position.Z >= center.Z and -1 or 1)
    end
    return MovementSafety.addImpulse(
        previous, inward * HarborCargoSweep.Push, 42, -52, 58
    )
end

function HarborCargoSweep.apply(ctx, band, subject, hitOnce, center)
    if not ctx or type(ctx.Active) ~= "function" or not ctx.Active()
        or not band or not band.Parent
        or band:GetAttribute("HarborSweepPhase") ~= "Pulse"
        or not subject or hitOnce[subject]
        or type(ctx.IsContestantActive) ~= "function"
        or ctx.IsContestantActive(subject) ~= true
    then return false end
    -- AI survivor proxy tables have Character, exactly like Player;
    -- no bot-only immunity or privileged teleport is permitted.
    local character = subject.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not root:IsA("BasePart") or not humanoid
        or humanoid.Health <= 0
        or not HarborCargoSweep.inside(root.Position, band)
    then return false end
    if not ctx.Active() then return false end

    hitOnce[subject] = true
    root.AssemblyLinearVelocity = HarborCargoSweep.velocity(
        root.AssemblyLinearVelocity, band, center
    )
    return true
end

local function createBand(folder, base, index)
    local alongX = index == 1 or index == 2
    local offset = index == 1 and -32
        or (index == 2 and 32 or (index == 3 and -32 or 32))
    local p = Instance.new("Part")
    p.Name = "HarborSweepLane" .. index
    p.Size = alongX and Vector3.new(7.5, 0.1, 68)
        or Vector3.new(68, 0.1, 7.5)
    p.CFrame = base.CFrame * CFrame.new(
        alongX and offset or 0,
        base.Size.Y * 0.5 + 0.29,
        alongX and 0 or offset
    )
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Material = Enum.Material.Neon
    p.Color = Color3.fromRGB(67, 133, 156)
    p.Transparency = 0.94
    p:SetAttribute("HarborSweepIndex", index)
    p:SetAttribute("HarborSweepPhase", "Idle")
    p.Parent = folder

    -- Text + colour warn together for accessibility; the caption is
    -- depth-tested and appears only during the announced danger.
    local marker = Instance.new("BillboardGui")
    marker.Name = "HarborSweepNotice" .. index
    marker.Adornee = p
    marker.AlwaysOnTop = false
    marker.Size = UDim2.fromOffset(185, 34)
    marker.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
    marker.MaxDistance = 85
    marker.Enabled = false
    marker.Parent = folder

    local label = Instance.new("TextLabel")
    label.Name = "HarborSweepText"
    label.BackgroundColor3 = Color3.fromRGB(38, 36, 32)
    label.BackgroundTransparency = 0.15
    label.BorderSizePixel = 0
    label.TextColor3 = Color3.fromRGB(255, 222, 126)
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.Text = "CARGO SWEEP  •  JUMP!"
    label.Size = UDim2.fromScale(1, 1)
    label.Parent = marker
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = label

    return p, marker, label
end

function HarborCargoSweep.setPhase(band, marker, label, phase, now)
    if not band or not band.Parent then return end
    if phase == "Warning" then
        band:SetAttribute("HarborSweepWarningAt", now)
        band.Color = Color3.fromRGB(255, 186, 76)
        band.Transparency = 0.20
        label.TextColor3 = Color3.fromRGB(255, 222, 126)
        label.Text = "CARGO SWEEP  •  JUMP!"
        marker.Enabled = true
    elseif phase == "Pulse" then
        band.Color = Color3.fromRGB(255, 86, 93)
        band.Transparency = 0.08
        label.TextColor3 = Color3.fromRGB(255, 155, 157)
        label.Text = "SWEEP ACTIVE  •  MOVE!"
        marker.Enabled = true
    else
        band.Color = Color3.fromRGB(67, 133, 156)
        band.Transparency = 0.94
        band:SetAttribute("HarborSweepWarningAt", nil)
        marker.Enabled = false
    end
    band:SetAttribute("HarborSweepPhase", phase or "Idle")
end

function HarborCargoSweep.start(ctx, arena)
    if not HarborCargoSweep.allowed(ctx) or not arena
        or arena:GetAttribute("VariantId") ~= "Harbor" then return nil end
    local base = arena:FindFirstChild("Base")
    local mechanics = arena:FindFirstChild("Mechanics")
    if not base or not base:IsA("BasePart") or not mechanics then
        return nil
    end

    local folder = Instance.new("Folder")
    folder.Name = "HarborCargoSweep"
    folder.Parent = mechanics
    local lanes = {}
    for i = 1, 4 do
        local band, marker, label = createBand(folder, base, i)
        lanes[i] = {band = band, marker = marker, label = label}
    end

    local active = true
    local current = nil
    local function restore()
        if current then
            HarborCargoSweep.setPhase(
                current.band, current.marker, current.label, "Idle")
            current = nil
        end
    end
    ctx.OnCleanup[#ctx.OnCleanup + 1] = function()
        active = false
        restore()
    end

    task.spawn(function()
        task.wait(HarborCargoSweep.InitialDelay)
        local wave = 0
        while active and ctx.Active() and arena.Parent and folder.Parent do
            if not HarborCargoSweep.canComplete(ctx, os.clock()) then
                break
            end
            current = lanes[HarborCargoSweep.laneIndex(ctx.RoundNumber, wave)]
            if not current or not current.band.Parent then break end
            HarborCargoSweep.setPhase(
                current.band, current.marker, current.label,
                "Warning", workspace:GetServerTimeNow()
            )
            task.wait(HarborCargoSweep.WarningSeconds)
            if not active or not ctx.Active() or not current.band.Parent then
                restore()
                break
            end
            HarborCargoSweep.setPhase(
                current.band, current.marker, current.label, "Pulse"
            )
            local hitOnce = setmetatable({}, {__mode = "k"})
            local elapsed = 0
            while active and ctx.Active()
                and elapsed < HarborCargoSweep.PulseSeconds do
                for _, subject in ipairs(
                    ctx.HazardContestants or ctx.Contestants or {}
                ) do
                    if not active or not ctx.Active() then break end
                    HarborCargoSweep.apply(
                        ctx, current.band, subject, hitOnce, base.Position
                    )
                end
                task.wait(HarborCargoSweep.SampleSeconds)
                elapsed += HarborCargoSweep.SampleSeconds
            end
            restore()
            if not active or not ctx.Active() then break end
            wave += 1
            task.wait(HarborCargoSweep.BetweenEvents)
        end
        restore()
    end)
    return folder
end

return HarborCargoSweep
