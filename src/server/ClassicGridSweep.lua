-- CLASSIC GRID / FLOOR SWEEP
-- Predictable, nonlethal horizontal pulse bands. One row is announced well
-- before impact; a jump or a lane change avoids it. All floor collision stays
-- intact. Only a small part of the floor is affected in each event.
local safetyModule = script and script.Parent:FindFirstChild("MovementSafety")
local MovementSafety = if safetyModule
    then require(safetyModule) else require("./MovementSafety")

local ClassicGridSweep = {}

ClassicGridSweep.InitialDelay = 6
ClassicGridSweep.WarningSeconds = 2.6
ClassicGridSweep.PulseSeconds = 0.9
ClassicGridSweep.GapSeconds = 6
ClassicGridSweep.SampleSeconds = 0.15
ClassicGridSweep.Push = 17

local CONFLICTS = {
    DisappearingPlatforms = true,
    ShrinkingArena = true,
    RisingLava = true,
    Freeze = true,
    Tornado = true,
    JumpShock = true,
    LowGravity = true,
}

function ClassicGridSweep.allowed(ctx)
    if type(ctx) ~= "table" or ctx.EnableClassicGridSweep ~= true
        or type(ctx.Active) ~= "function"
        or type(ctx.OnCleanup) ~= "table"
    then return false end
    for disasterId in pairs(ctx.ActiveDisasters or {}) do
        if CONFLICTS[disasterId] then return false end
    end
    return true
end

function ClassicGridSweep.indexFor(roundNumber, sequence)
    local round = math.max(1, math.floor(tonumber(roundNumber) or 1))
    local count = math.max(0, math.floor(tonumber(sequence) or 0))
    return ((round - 1 + count) % 4) + 1
end

function ClassicGridSweep.inside(position, band)
    if typeof(position) ~= "Vector3"
        or not band or not band:IsA("BasePart") then return false end
    local point = band.CFrame:PointToObjectSpace(position)
    -- Only contestants standing on the LOW base floor; elevated platforms
    -- and successfully timed jumps are completely exempt.
    return math.abs(point.X) <= band.Size.X * 0.5 + 0.3
        and math.abs(point.Z) <= band.Size.Z * 0.5 + 0.3
        and point.Y >= 1.0 and point.Y <= 5.1
end

function ClassicGridSweep.velocity(previous, band)
    if not band or not band:IsA("BasePart") then return previous end
    local axis = band.Size.X < band.Size.Z and Vector3.xAxis
        or Vector3.zAxis
    -- Always shove toward the arena centre, never toward the kill plane.
    local sign = axis == Vector3.xAxis and band.Position.X >= 0
        or axis == Vector3.zAxis and band.Position.Z >= 0
    local inward = axis * (sign and -1 or 1)
    return MovementSafety.addImpulse(
        previous, inward * ClassicGridSweep.Push, 42, -52, 58
    )
end

function ClassicGridSweep.apply(ctx, band, subject, hitOnce)
    if not ctx or type(ctx.Active) ~= "function" or not ctx.Active()
        or not band or not band.Parent
        or band:GetAttribute("GridSweepPhase") ~= "Pulse"
        or not subject or hitOnce[subject]
        or type(ctx.IsContestantActive) ~= "function"
        or ctx.IsContestantActive(subject) ~= true
    then return false end
    local character = subject.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not root:IsA("BasePart") or not hum or hum.Health <= 0
        or not ClassicGridSweep.inside(root.Position, band)
    then return false end
    -- All validation precedes claiming and velocity mutation.
    if not ctx.Active() then return false end
    hitOnce[subject] = true
    root.AssemblyLinearVelocity = ClassicGridSweep.velocity(
        root.AssemblyLinearVelocity, band
    )
    return true
end

local function makeBand(folder, base, index)
    local alongX = index == 1 or index == 3
    local laneOffset = index == 1 and -15 or (index == 3 and 15
        or (index == 2 and -15 or 15))
    local band = Instance.new("Part")
    band.Name = "GridSweepBand" .. index
    band.Size = alongX and Vector3.new(7.8, 0.10, 64)
        or Vector3.new(64, 0.10, 7.8)
    band.Position = base.Position + Vector3.new(
        alongX and laneOffset or 0,
        base.Size.Y * 0.5 + 0.29,
        alongX and 0 or laneOffset
    )
    band.Anchored = true
    band.CanCollide = false
    band.CanTouch = false
    band.CanQuery = false
    band.CastShadow = false
    band.Material = Enum.Material.Neon
    band.Color = Color3.fromRGB(75, 151, 190)
    band.Transparency = 0.92
    band:SetAttribute("GridSweepIndex", index)
    band.Parent = folder
    return band
end

function ClassicGridSweep.setPhase(band, phase, at)
    if not band or not band.Parent then return end
    if phase == "Warning" then
        band:SetAttribute("GridSweepWarningAt", at)
        band.Color = Color3.fromRGB(255, 191, 76)
        band.Transparency = 0.24
    elseif phase == "Pulse" then
        band.Color = Color3.fromRGB(255, 100, 102)
        band.Transparency = 0.08
    else
        band.Color = Color3.fromRGB(75, 151, 190)
        band.Transparency = 0.92
        band:SetAttribute("GridSweepWarningAt", nil)
    end
    band:SetAttribute("GridSweepPhase", phase)
end

function ClassicGridSweep.start(ctx, arena)
    if not ClassicGridSweep.allowed(ctx) or not arena then return nil end
    local base = arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") then return nil end

    local mechanics = arena:FindFirstChild("Mechanics")
    if not mechanics then return nil end
    local folder = Instance.new("Folder")
    folder.Name = "GridSweep"
    folder.Parent = mechanics
    local bands = {}
    for index = 1, 4 do
        bands[index] = makeBand(folder, base, index)
    end

    local active = true
    local current = nil
    ctx.OnCleanup[#ctx.OnCleanup + 1] = function()
        active = false
        if current then ClassicGridSweep.setPhase(current, nil) end
        for _, band in ipairs(bands) do
            ClassicGridSweep.setPhase(band, nil)
        end
    end

    task.spawn(function()
        task.wait(ClassicGridSweep.InitialDelay)
        local event = 0
        while active and ctx.Active() and folder.Parent and arena.Parent do
            local index = ClassicGridSweep.indexFor(ctx.RoundNumber, event)
            current = bands[index]
            if not current or not current.Parent then break end
            ClassicGridSweep.setPhase(
                current, "Warning", workspace:GetServerTimeNow()
            )
            task.wait(ClassicGridSweep.WarningSeconds)
            if not active or not ctx.Active() or not current.Parent then break end
            ClassicGridSweep.setPhase(current, "Pulse")
            local impacted = setmetatable({}, {__mode = "k"})
            local elapsed = 0
            while active and ctx.Active() and elapsed < ClassicGridSweep.PulseSeconds do
                for _, subject in ipairs(ctx.HazardContestants or ctx.Contestants or {}) do
                    if not active or not ctx.Active() then break end
                    ClassicGridSweep.apply(ctx, current, subject, impacted)
                end
                task.wait(ClassicGridSweep.SampleSeconds)
                elapsed += ClassicGridSweep.SampleSeconds
            end
            ClassicGridSweep.setPhase(current, nil)
            current = nil
            if not active or not ctx.Active() then break end
            event += 1
            task.wait(ClassicGridSweep.GapSeconds)
        end
        if current then ClassicGridSweep.setPhase(current, nil) end
    end)
    return folder
end

return ClassicGridSweep
