local HazardWarning = if script then require(script.Parent.Parent.HazardWarning) else require("../HazardWarning")
local D = {Name = "FREEZE PULSE", Hint = "BLUE FLASH = FREEZE INCOMING!"}

local function createWarning(ctx, diameter)
    local warning = Instance.new("Part")
    warning.Name = "FreezeWarning"
    warning.Shape = Enum.PartType.Cylinder
    warning.Size = Vector3.new(0.16, diameter, diameter)
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
    local frozen = {}
    local generation = 0

    local function restore(humanoid)
        local state = frozen[humanoid]
        if not state then
            return
        end

        frozen[humanoid] = nil
        if humanoid and humanoid.Parent then
            humanoid:SetAttribute("ChaosFrozen", false)
            if humanoid.WalkSpeed == state.appliedWalkSpeed then
                humanoid.WalkSpeed = state.walkSpeed
            end
            if humanoid.JumpPower == state.appliedJumpPower then
                humanoid.JumpPower = state.jumpPower
            end
            if humanoid.JumpHeight == state.appliedJumpHeight then
                humanoid.JumpHeight = state.jumpHeight
            end
        end
    end

    ctx.OnCleanup[#ctx.OnCleanup+1] = function()
        generation += 1
        local targets = {}
        for humanoid in pairs(frozen) do
            table.insert(targets, humanoid)
        end
        for _, humanoid in ipairs(targets) do
            restore(humanoid)
        end
    end

    task.spawn(function()
        while ctx.Active() do
            local intensity = ctx.Intensity and ctx.Intensity() or 1
            task.wait(math.max(3.8, math.random(5, 7) / intensity))
            if not ctx.Active() then break end

            local warningDiameter = HazardWarning.arenaCoverageDiameter(150)
            local warning = createWarning(ctx, warningDiameter)
            HazardWarning.configure(warning, "Freeze", warningSeconds, warningDiameter, warningDiameter)
            task.wait(warningSeconds)

            if warning.Parent then
                warning:Destroy()
            end
            if not ctx.Active() then break end

            generation += 1
            local pulseGeneration = generation

            for _, player in ipairs(ctx.HazardContestants or ctx.Contestants or {}) do
                if ctx.IsContestantActive and not ctx.IsContestantActive(player) then
                    continue
                end

                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    restore(hum)
                    local appliedWalkSpeed = 4
                    local appliedJumpPower = 0
                    local appliedJumpHeight = 0
                    frozen[hum] = {
                        walkSpeed = hum.WalkSpeed,
                        jumpPower = hum.JumpPower,
                        jumpHeight = hum.JumpHeight,
                        appliedWalkSpeed = appliedWalkSpeed,
                        appliedJumpPower = appliedJumpPower,
                        appliedJumpHeight = appliedJumpHeight,
                        generation = pulseGeneration,
                    }
                    hum:SetAttribute("ChaosFrozen", true)
                    hum.WalkSpeed = appliedWalkSpeed
                    hum.JumpPower = appliedJumpPower
                    hum.JumpHeight = appliedJumpHeight

                    task.delay(freezeSeconds, function()
                        local state = frozen[hum]
                        if state and state.generation == pulseGeneration then
                            restore(hum)
                        end
                    end)
                end
            end
        end
    end)
end

return D
