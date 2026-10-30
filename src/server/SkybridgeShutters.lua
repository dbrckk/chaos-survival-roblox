-- TOWER RUN / RISING SKYBRIDGE SHUTTERS
-- Genuine timed collision obstacle, not a decorative moving prop. A player
-- must hop over its short metal sill or wait for the lane to reopen.
-- One gate at a time, the other three real skybridges remain traversable.
-- Works only in veteran, single-hazard rounds already eligible for the
-- existing Skybridge Pressure mechanic; never stacks with that outage.
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local SkybridgePressure = require(script.Parent.SkybridgePressure)

local SkybridgeShutters = {}

SkybridgeShutters.WarningSeconds = 2.6
SkybridgeShutters.RiseSeconds = 0.32
SkybridgeShutters.RaisedSeconds = 1.8
SkybridgeShutters.BetweenSeconds = 5.6
SkybridgeShutters.Height = 2.05

function SkybridgeShutters.allowed(ctx)
    return SkybridgePressure.allowed(ctx)
end

function SkybridgeShutters.canComplete(ctx, now)
    local deadline = tonumber(ctx and ctx.RoundEndsAt)
    if not deadline then return true end
    return (tonumber(now) or 0)
        + SkybridgeShutters.WarningSeconds
        + SkybridgeShutters.RiseSeconds
        + SkybridgeShutters.RaisedSeconds + 2 <= deadline
end

function SkybridgeShutters.gateFor(bridge, folder)
    if typeof(bridge) ~= "Instance" or not bridge:IsA("BasePart")
        or bridge:GetAttribute("ChaosSkybridge") ~= true
        or not bridge.CanCollide or not folder then
        return nil
    end

    local alongX = bridge.Size.X > bridge.Size.Z
    local width = math.min(bridge.Size.X, bridge.Size.Z) - 0.12
    if width < 3.5 then return nil end

    local gate = Instance.new("Part")
    gate.Name = "BridgeShutter" .. bridge.Name
    gate.Size = alongX
        and Vector3.new(0.85, SkybridgeShutters.Height, width)
        or Vector3.new(width, SkybridgeShutters.Height, 0.85)
    gate.CFrame = bridge.CFrame * CFrame.new(
        0, bridge.Size.Y * 0.5 + SkybridgeShutters.Height * 0.5, 0
    )
    gate.Anchored = true
    gate.CanCollide = false
    gate.CanTouch = false
    gate.CanQuery = false
    gate.CastShadow = false
    gate.Material = Enum.Material.Metal
    gate.Color = Color3.fromRGB(192, 144, 81)
    gate.Transparency = 1
    gate.TopSurface = Enum.SurfaceType.Smooth
    gate.BottomSurface = Enum.SurfaceType.Smooth
    gate:SetAttribute("BridgeShutter", true)
    gate:SetAttribute("BridgeName", bridge.Name)
    gate:SetAttribute("ShutterPhase", "Idle")
    gate.Parent = folder
    -- Client-only locale/accessibility notice follows this real object.
    -- Tags replicate with streamed-in gates; no descendant polling.
    CollectionService:AddTag(gate, "TowerSkybridgeShutter")
    return {
        bridge = bridge,
        gate = gate,
        raised = gate.CFrame,
        lowered = gate.CFrame * CFrame.new(0, -SkybridgeShutters.Height, 0),
    }
end

function SkybridgeShutters.setPhase(state, phase, timestamp)
    if not state or not state.gate or not state.gate.Parent then
        return false
    end
    local gate = state.gate
    -- Put collision behind the visible status transition so observers
    -- never get struck by a gate which still appears to be inactive.
    gate.CanCollide = false
    gate.CanQuery = false
    if phase == "Warning" then
        gate.CFrame = state.lowered
        gate.Color = Color3.fromRGB(233, 180, 72)
        gate.Transparency = 0.28
        gate:SetAttribute("ShutterWarningAt", timestamp)
    elseif phase == "Raising" then
        gate.Color = Color3.fromRGB(225, 159, 71)
        gate.Transparency = 0.16
    elseif phase == "Raised" then
        gate.CFrame = state.raised
        gate.Color = Color3.fromRGB(190, 117, 67)
        gate.Transparency = 0.08
        gate.CanQuery = true
        gate.CanCollide = true
    else
        phase = "Idle"
        gate.CFrame = state.lowered
        gate.Transparency = 1
        gate:SetAttribute("ShutterWarningAt", nil)
    end
    gate:SetAttribute("ShutterPhase", phase)
    -- Skyrail boosts must not throw a runner toward a forming barrier.
    if state.bridge and state.bridge.Parent then
        state.bridge:SetAttribute("BridgeShutterPhase", phase)
    end
    return true
end

-- Don't create real collision on top of a player or bot. Accessory parts
-- never count as a character; inspect the actual root in gate-local space.
-- This check is used JUST BEFORE collision activates, not per frame.
function SkybridgeShutters.occupied(state, contestants, isActive)
    if not state or not state.gate or type(contestants) ~= "table" then
        return false
    end
    local gate = state.gate
    if not gate.Parent then return false end
    for _, subject in ipairs(contestants) do
        local character = subject and subject.Character
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local eligible = type(isActive) ~= "function" or isActive(subject) == true
        if eligible and hum and hum.Health > 0
            and root and root:IsA("BasePart") then
            local pos = state.raised:PointToObjectSpace(root.Position)
            if math.abs(pos.X) <= gate.Size.X * 0.5 + 2.5
                and math.abs(pos.Z) <= gate.Size.Z * 0.5 + 2.5
                and pos.Y >= -3.2 and pos.Y <= 6.5 then
                return true
            end
        end
    end
    return false
end

function SkybridgeShutters.start(ctx, arena)
    if not SkybridgeShutters.allowed(ctx) or not arena then return false end
    local platforms = arena:FindFirstChild("Platforms")
    local mechanics = arena:FindFirstChild("Mechanics")
    if not platforms or not mechanics then return false end
    local bridges = SkybridgePressure.bridges(platforms)
    if #bridges ~= 4 then return false end
    local folder = Instance.new("Folder")
    folder.Name = "SkybridgeShutters"
    folder.Parent = mechanics
    local states = {}
    for _, bridge in ipairs(bridges) do
        local state = SkybridgeShutters.gateFor(bridge, folder)
        if not state then
            folder:Destroy()
            return false
        end
        states[#states + 1] = state
    end

    local active = true
    local current = nil
    local function restore()
        if current then
            SkybridgeShutters.setPhase(current, "Idle")
            current = nil
        end
    end
    ctx.OnCleanup[#ctx.OnCleanup + 1] = function()
        active = false
        restore()
        folder:Destroy()
    end

    task.spawn(function()
        task.wait(5.4)
        local cycle = 0
        local round = math.max(1, math.floor(tonumber(ctx.RoundNumber) or 1))
        while active and ctx.Active()
            and arena.Parent and platforms.Parent and folder.Parent do
            if not SkybridgeShutters.canComplete(ctx, os.clock()) then break end
            cycle += 1
            local selected = states[((round + cycle - 2) % #states) + 1]
            if not selected.bridge.Parent
                or not selected.bridge.CanCollide then break end
            current = selected
            SkybridgeShutters.setPhase(
                current, "Warning", workspace:GetServerTimeNow()
            )
            task.wait(SkybridgeShutters.WarningSeconds)
            if not active or not ctx.Active()
                or not selected.bridge.Parent or not selected.bridge.CanCollide then
                restore()
                break
            end

            -- The visible warning becomes an actual rising metal hurdle,
            -- rather than a blinking prompt or a scripted character push.
            SkybridgeShutters.setPhase(current, "Raising")
            local tween = TweenService:Create(
                current.gate,
                TweenInfo.new(
                    SkybridgeShutters.RiseSeconds,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                ),
                {CFrame = current.raised}
            )
            tween:Play()
            task.wait(SkybridgeShutters.RiseSeconds)
            if not active or not ctx.Active() or not current
                or not selected.bridge.Parent or not selected.bridge.CanCollide then
                tween:Cancel()
                restore()
                break
            end
            -- A late arrival in the exact shutter volume cancels closure.
            -- Waiting is always safe; no unavoidable forced collision.
            if not SkybridgeShutters.occupied(
                current, ctx.HazardContestants or ctx.Contestants or {},
                ctx.IsContestantActive
            ) then
                SkybridgeShutters.setPhase(current, "Raised")
                task.wait(SkybridgeShutters.RaisedSeconds)
            end
            restore()
            if not active or not ctx.Active() then break end
            task.wait(SkybridgeShutters.BetweenSeconds)
        end
        restore()
    end)
    return true
end

return SkybridgeShutters
