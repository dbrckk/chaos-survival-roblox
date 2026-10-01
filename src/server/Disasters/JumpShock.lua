local MovementSafety = if script then require(script.Parent.Parent.MovementSafety) else require("../MovementSafety")
local HazardWarning = if script then require(script.Parent.Parent.HazardWarning) else require("../HazardWarning")
local D = {Name = "JUMP SHOCK", Hint = "WATCH THE BLUE SHOCKWAVE!"}

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
    ring.Transparency = 0.30
    ring.Parent = workspace
    ctx.Cleanup[#ctx.Cleanup+1] = ring
    return ring
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
            local warningSeconds = 0.65
            local warningDiameter = HazardWarning.arenaCoverageDiameter(150)
            HazardWarning.configure(warning, "JumpShock", warningSeconds, 8, warningDiameter)
            task.wait(warningSeconds)

            if warning.Parent then
                warning:Destroy()
            end

            if not ctx.Active() then break end

            for _, p in ipairs(ctx.Contestants or {}) do
                if ctx.IsContestantActive and not ctx.IsContestantActive(p) then
                    continue
                end
                local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    root.AssemblyLinearVelocity = MovementSafety.addImpulse(
                        root.AssemblyLinearVelocity,
                        Vector3.new(
                            math.random(-horizontal,horizontal),
                            math.random(34,46),
                            math.random(-horizontal,horizontal)
                        ),
                        62,
                        -55,
                        58
                    )
                end
            end
        end
    end)
end

return D
