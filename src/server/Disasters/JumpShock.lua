local MovementSafety = if script then require(script.Parent.Parent.MovementSafety) else require("../MovementSafety")
local HazardWarning = if script then require(script.Parent.Parent.HazardWarning) else require("../HazardWarning")
local D = {Name = "JUMP SHOCK", Hint = "JUMP OVER THE BLUE SHOCKWAVE!"}
D.WarningSeconds = 1.05

-- A timed jump now avoids the shock. The server checks the actual rising
-- avatar, not a client-sent dodge event, and keeps identical rules for AI.
-- Falling off a ledge or merely walking in the air is not a free dodge.
function D.dodgedByJump(humanoidState, velocityY, heightAboveGround, floorAirborne)
    local rising = tonumber(velocityY)
    local clearance = tonumber(heightAboveGround)
    if not rising or not clearance or rising ~= rising
        or clearance ~= clearance then
        return false
    end
    -- Client-owned humanoid state can lag on the server. FloorMaterial is
    -- an additional *server-observed* airborne signal, never a remote claim.
    -- Rising velocity and real ground clearance remain mandatory either way.
    local jumpingState = humanoidState == Enum.HumanoidStateType.Jumping
        or humanoidState == Enum.HumanoidStateType.Freefall
    return (jumpingState or floorAirborne == true)
        and rising > 3 and clearance >= 4.5
end

-- A successful timed dodge is a legitimate skilled near miss.
-- Use the existing server-authoritative reward/event pipeline, which
-- rate-limits human progress, ignores bots and drives near-miss SFX/VFX.
-- No new client remote, currency or gameplay advantage is introduced.
function D.rewardDodge(ctx, subject)
    if type(ctx) ~= "table" or type(ctx.OnHazardNearMiss) ~= "function"
        or (type(ctx.Active) == "function" and not ctx.Active()) then
        return false
    end
    return pcall(ctx.OnHazardNearMiss, subject, "JumpShock", nil, nil)
end

local function makeWarning(ctx)
    local ring = Instance.new("Part")
    ring.Name = "JumpShockWarning"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.15, 8, 8)
    ring.CFrame = CFrame.new(ctx.Config.ArenaCenter + Vector3.new(0, 1.15, 0))
        * CFrame.Angles(0, 0, math.rad(90))
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.Material = Enum.Material.Neon
    ring.Color = Color3.fromRGB(80, 155, 255)
    ring.Transparency = 0.62
    ring.Parent = workspace
    ctx.Cleanup[#ctx.Cleanup+1] = ring
    return ring
end

function D.applyShock(ctx, subject, horizontalForce)
    -- The warning callback or a previous shock recipient may have ended
    -- the round. Refuse stale impulses even when invoked directly.
    if type(ctx.Active) == "function" and not ctx.Active() then
        return false
    end
    if ctx.IsContestantActive and not ctx.IsContestantActive(subject) then
        return false
    end
    if type(ctx.Active) == "function" and not ctx.Active() then
        return false
    end

    local root = subject.Character and subject.Character:FindFirstChild("HumanoidRootPart")
    local hum = subject.Character and subject.Character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then
        return false
    end

    -- Raycast below the current character to verify meaningful clearance.
    -- Only world collision can supply a ground reference; ignore the
    -- character itself. If no ground is found, do not grant a free dodge.
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.RespectCanCollide = true
    rayParams.FilterDescendantsInstances = {subject.Character}
    -- A high jump on Towers/Orbital may be over fourteen studs above its
    -- landing deck; missing that deck must not cancel an earned dodge.
    local ground = workspace:Raycast(
        root.Position, Vector3.new(0, -24, 0), rayParams
    )
    local clearance = ground and (root.Position.Y - ground.Position.Y) or 0
    if D.dodgedByJump(
        hum:GetState(), root.AssemblyLinearVelocity.Y, clearance,
        hum.FloorMaterial == Enum.Material.Air
    ) then
        D.rewardDodge(ctx, subject)
        return false
    end

    local horizontal = math.max(0, tonumber(horizontalForce) or 0)
    root.AssemblyLinearVelocity = MovementSafety.addImpulse(
        root.AssemblyLinearVelocity,
        Vector3.new(
            math.random(-horizontal, horizontal),
            math.random(34, 46),
            math.random(-horizontal, horizontal)
        ),
        62,
        -55,
        58
    )

    if ctx.OnHazardContact then
        pcall(ctx.OnHazardContact, subject, "JumpShock")
    end

    return true
end

function D.start(ctx)
    local profile = ctx.BalanceProfile or {}
    local horizontal = profile.JumpHorizontalForce or 8

    task.spawn(function()
        while ctx.Active() do
            local intensity = ctx.Intensity and ctx.Intensity() or 1
            task.wait(math.max(3.2, math.random(4,6) / intensity))
            if not ctx.Active() then break end

            local warning = makeWarning(ctx)
            local warningSeconds = D.WarningSeconds
            local warningDiameter = HazardWarning.arenaCoverageDiameter(150)
            HazardWarning.configure(warning, "JumpShock", warningSeconds, 8, warningDiameter)
            task.wait(warningSeconds)

            if warning.Parent then
                warning:Destroy()
            end

            if not ctx.Active() then break end

            if ctx.OnHazardImpact then
                pcall(
                    ctx.OnHazardImpact,
                    ctx.Config.ArenaCenter + Vector3.new(0, 1, 0),
                    Color3.fromRGB(80, 155, 255),
                    warningDiameter * 0.5,
                    "JumpShock"
                )
            end

            -- An impact notification can close the round synchronously.
            -- Never apply the wave after that phase transition.
            if not ctx.Active() then break end
            for _, p in ipairs(ctx.HazardContestants or ctx.Contestants or {}) do
                if not ctx.Active() then break end
                D.applyShock(ctx, p, horizontal)
            end
        end
    end)
end

return D
