local D = {Name = "FREEZE PULSE", Hint = "BLUE FLASH = FREEZE INCOMING!"}

local function createWarning(ctx)
    local warning = Instance.new("Part")
    warning.Name = "FreezeWarning"
    warning.Shape = Enum.PartType.Cylinder
    warning.Size = Vector3.new(0.16, 86, 86)
    warning.CFrame = CFrame.new(ctx.Config.ArenaCenter + Vector3.new(0, 1.16, 0))
        * CFrame.Angles(0, 0, math.rad(90))
    warning.Anchored = true
    warning.CanCollide = false
    warning.CanTouch = false
    warning.CanQuery = false
    warning.Material = Enum.Material.Neon
    warning.Color = Color3.fromRGB(100, 205, 255)
    warning.Transparency = 0.78
    warning.Parent = workspace
    ctx.Cleanup[#ctx.Cleanup+1] = warning
    return warning
end

function D.start(ctx)
    local profile = ctx.BalanceProfile or {}
    local freezeSeconds = profile.FreezeSeconds or 1.1
    local warningSeconds = 0.7

    task.spawn(function()
        while ctx.Active() do
            task.wait(math.random(5, 7))
            if not ctx.Active() then break end

            local warning = createWarning(ctx)
            local started = os.clock()

            while ctx.Active() and warning.Parent do
                local alpha = math.clamp((os.clock() - started) / warningSeconds, 0, 1)
                warning.Transparency = 0.78 - (0.30 * math.sin(alpha * math.pi))
                if alpha >= 1 then break end
                task.wait(0.04)
            end

            if warning.Parent then
                warning:Destroy()
            end
            if not ctx.Active() then break end

            for _, player in ipairs(ctx.Contestants or {}) do
                if ctx.IsContestantActive and not ctx.IsContestantActive(player) then
                    continue
                end
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local oldSpeed = hum.WalkSpeed
                    local oldJump = hum.JumpPower
                    hum.WalkSpeed = 4
                    hum.JumpPower = 0
                    task.delay(freezeSeconds, function()
                        if hum and hum.Parent and hum.Health > 0 then
                            hum.WalkSpeed = oldSpeed
                            hum.JumpPower = oldJump
                        end
                    end)
                end
            end
        end
    end)
end

return D
