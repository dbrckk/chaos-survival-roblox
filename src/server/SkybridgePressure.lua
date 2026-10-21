-- TOWER RUN / SKYBRIDGE PRESSURE
-- One warning -> one short physical outage -> restoration. The three other
-- bridges stay solid. Server-owned collision and server-authored warning state;
-- existing client CollapsePhase visuals scale to Android quality settings.
local SkybridgePressure = {}

SkybridgePressure.InitialDelay = 6.5
SkybridgePressure.WarningSeconds = 2.6
SkybridgePressure.OutageSeconds = 1.8
SkybridgePressure.BetweenEvents = 6.0

-- Prevent unfair stacking with hazards which already remove the floor, rise
-- underneath the bridges, or change all platform geometry.
local CONFLICTS = {
    DisappearingPlatforms = true,
    ShrinkingArena = true,
    RisingLava = true,
    Freeze = true,
    -- Forced lateral/vertical motion can strand a player after an otherwise
    -- fair warning. These disaster-only rounds keep all bridges available.
    Tornado = true,
    JumpShock = true,
    LowGravity = true,
    SpeedSurge = true,
}

function SkybridgePressure.allowed(ctx)
    if type(ctx) ~= "table" or ctx.EnableSkybridgePressure ~= true
        or type(ctx.Active) ~= "function"
        or type(ctx.OnCleanup) ~= "table" then
        return false
    end
    for id in pairs(ctx.ActiveDisasters or {}) do
        if CONFLICTS[id] then return false end
    end
    return true
end

function SkybridgePressure.bridges(platforms)
    local result = {}
    if not platforms then return result end
    for _, child in ipairs(platforms:GetChildren()) do
        if child:IsA("BasePart")
            and child:GetAttribute("ChaosSkybridge") == true
            and child.CanCollide then
            result[#result + 1] = child
        end
    end
    table.sort(result, function(a, b) return a.Name < b.Name end)
    return result
end

-- MapBuilder decor includes the platform skin, structural subframe, long
-- SkybridgeRails and under-deck ribs. No visible collisionless phantom path.
function SkybridgePressure.decorFor(decor, bridge)
    local index = bridge and bridge.Name:match("^Skybridge(%d+)$")
    if not index or not decor then return {} end
    local parts = {}
    for _, piece in ipairs(decor:GetChildren()) do
        if piece:IsA("BasePart") then
            local suffix = piece.Name:match("^SkybridgeRail(%d+)_")
                or piece.Name:match("^SkybridgeRib(%d+)_")
                or piece.Name:match("^PlatformGlow(%d+)$")
                or piece.Name:match("^PlatformPanel(%d+)$")
                or piece.Name:match("^PlatformUnderFrame(%d+)$")
                or piece.Name:match("^PlatformCoreGlow(%d+)$")
                or piece.Name:match("^PlatformSupport(%d+)_")
                or piece.Name:match("^PlatformBevel(%d+)_")
            if suffix == index then
                parts[#parts + 1] = {
                    part = piece,
                    transparency = piece.Transparency,
                }
            end
        end
    end
    return parts
end

function SkybridgePressure.snapshot(bridge, decor)
    return {
        bridge = bridge,
        transparency = bridge.Transparency,
        canCollide = bridge.CanCollide,
        color = bridge.Color,
        material = bridge.Material,
        details = SkybridgePressure.decorFor(decor, bridge),
    }
end

function SkybridgePressure.setPhase(state, phase, now)
    local part = state and state.bridge
    if not part or not part.Parent then return end
    if phase == "Warning" then
        -- Write the start timestamp BEFORE the phase for clients which bind
        -- phase changes and compute a visible, synchronized warning interval.
        part:SetAttribute("CollapseWarningStartedAt", now)
        part.Color = Color3.fromRGB(255, 187, 56)
        part.Material = Enum.Material.Neon
        part.Transparency = math.min(state.transparency, 0.16)
        part.CanCollide = state.canCollide
    elseif phase == "Gone" then
        part.Transparency = 1
        part.CanCollide = false
    else
        part.Color = state.color
        part.Material = state.material
        part.Transparency = state.transparency
        part.CanCollide = state.canCollide
        part:SetAttribute("CollapseWarningStartedAt", nil)
    end
    for _, entry in ipairs(state.details) do
        if entry.part.Parent then
            if phase == "Gone" then
                entry.part.Transparency = 1
            elseif phase == "Warning" then
                local topPanel = entry.part.Name:match("^PlatformPanel") ~= nil
                entry.part.Transparency = math.max(
                    entry.transparency, topPanel and 0.84 or 0.65
                )
            else
                entry.part.Transparency = entry.transparency
            end
        end
    end
    part:SetAttribute("CollapsePhase", phase)
end

function SkybridgePressure.start(ctx, arena)
    if not SkybridgePressure.allowed(ctx) or not arena then return false end
    local platforms = arena:FindFirstChild("Platforms")
    local bridges = SkybridgePressure.bridges(platforms)
    if #bridges ~= 4 then return false end

    local decor = arena:FindFirstChild("Decor")
    local active = true
    local current = nil
    local sequence = 0
    local seed = math.max(0, math.floor(tonumber(ctx.RoundNumber) or 0))

    local function restore()
        if current then
            SkybridgePressure.setPhase(current, nil)
            current = nil
        end
    end
    ctx.OnCleanup[#ctx.OnCleanup + 1] = function()
        active = false
        restore()
    end

    task.spawn(function()
        task.wait(SkybridgePressure.InitialDelay)
        while active and ctx.Active() and arena.Parent and platforms.Parent do
            -- Visit all four links in a changing order across rounds, never
            -- taking two simultaneous shortcuts away from a player.
            local index = ((seed + sequence) % #bridges) + 1
            sequence += 1
            local bridge = bridges[index]
            if not bridge or not bridge.Parent then break end
            current = SkybridgePressure.snapshot(bridge, decor)
            SkybridgePressure.setPhase(
                current, "Warning", workspace:GetServerTimeNow()
            )
            task.wait(SkybridgePressure.WarningSeconds)
            if not active or not ctx.Active() or not bridge.Parent then
                restore()
                break
            end
            SkybridgePressure.setPhase(current, "Gone")
            task.wait(SkybridgePressure.OutageSeconds)
            restore()
            if not active or not ctx.Active() then break end
            task.wait(SkybridgePressure.BetweenEvents)
        end
        restore()
    end)
    return true
end

return SkybridgePressure
