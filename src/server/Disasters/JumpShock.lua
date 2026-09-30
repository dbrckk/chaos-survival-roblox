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
            task.wait(math.random(4,6))
            if not ctx.Active() then break end

            local warning = makeWarning(ctx)
            local started = os.clock()
            local warningSeconds = 0.65

            while ctx.Active() and warning.Parent do
                local alpha = math.clamp((os.clock() - started) / warningSeconds, 0, 1)
                local diameter = 8 + (64 * alpha)
                warning.Size = Vector3.new(0.15, diameter, diameter)
                warning.Transparency = 0.30 + (0.58 * alpha)

                if alpha >= 1 then
                    break
                end
                task.wait(0.04)
            end

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
                    root.AssemblyLinearVelocity += Vector3.new(
                        math.random(-horizontal,horizontal),
                        math.random(34,46),
                        math.random(-horizontal,horizontal)
                    )
                end
            end
        end
    end)
end

return D
