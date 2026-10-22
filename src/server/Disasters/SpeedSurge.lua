local D = {Name = "SPEED SURGE", Hint = "FOLLOW THE SPEED RHYTHM!"}

-- Veteran solo-disaster rounds alternate a readable fast/controlled tempo.
-- Beginner and Double Chaos rounds keep the original steady movement.
D.CycleSeconds = 12
function D.tempoAt(elapsed, enabled)
    if enabled ~= true then return "Surge", math.huge end
    local value = tonumber(elapsed) or 0
    if value ~= value or math.abs(value) == math.huge then value = 0 end
    local time = math.max(0, value) % D.CycleSeconds
    if time < 7 then return "Surge", 7 - time end
    return "Recover", D.CycleSeconds - time
end

function D.start(ctx)
    local profile = ctx.BalanceProfile or {}
    local multiplier = profile.SpeedMultiplier or 1.5
    local tempoEnabled = ctx.EnableSpeedTempo == true
    local startedAt = tonumber(ctx.RoundStartedAt) or os.clock()

    local previous = {}
    for _, p in ipairs(ctx.HazardContestants or ctx.Contestants or {}) do
        if ctx.IsContestantActive and not ctx.IsContestantActive(p) then
            continue
        end

        local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            local original = hum.WalkSpeed
            local applied = math.min(26, math.max(22, original * multiplier))
            previous[hum] = {
                original = original,
                applied = applied,
                current = applied,
            }
            hum.WalkSpeed = applied
        end
    end

    local beacon, label
    if tempoEnabled then
        beacon = Instance.new("Part")
        beacon.Name = "SpeedTempoBeacon"
        beacon.Size = Vector3.new(2.4, 2.4, 2.4)
        beacon.Shape = Enum.PartType.Ball
        beacon.Position = ctx.Config.ArenaCenter + Vector3.new(0, 13, 0)
        beacon.Anchored = true
        beacon.CanCollide = false
        beacon.CanTouch = false
        beacon.CanQuery = false
        beacon.Material = Enum.Material.Neon
        beacon.Color = Color3.fromRGB(255, 95, 190)
        local gui = Instance.new("BillboardGui")
        gui.Name = "SpeedTempoSignal"
        gui.AlwaysOnTop = true
        gui.Size = UDim2.fromOffset(220, 58)
        gui.MaxDistance = 190
        gui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
        gui.Parent = beacon
        label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundColor3 = Color3.fromRGB(25, 15, 40)
        label.BackgroundTransparency = 0.12
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextScaled = true
        label.TextWrapped = true
        label.Font = Enum.Font.GothamBold
        label.Text = "SPEED SURGE"
        label.Parent = gui
        beacon.Parent = workspace
        ctx.Cleanup[#ctx.Cleanup+1] = beacon
    end

    ctx.OnCleanup[#ctx.OnCleanup+1] = function()
        ctx.SpeedTempoPhase = nil
        for hum, state in pairs(previous) do
            if hum and hum.Parent and hum.WalkSpeed == state.current then
                hum.WalkSpeed = state.original
            end
        end
        table.clear(previous)
    end

    if tempoEnabled then
        ctx.SpeedTempoPhase = "Surge"
        task.spawn(function()
            local lastText
            while ctx.Active() and beacon.Parent do
                local phase, remaining = D.tempoAt(os.clock() - startedAt, true)
                ctx.SpeedTempoPhase = phase
                local text = phase == "Surge"
                    and ("FAST • CONTROL IN " .. math.ceil(remaining) .. "s")
                    or ("CONTROL • BOOST IN " .. math.ceil(remaining) .. "s")
                if text ~= lastText then
                    label.Text = "SPEED RHYTHM\n" .. text
                    lastText = text
                end
                beacon.Color = phase == "Surge"
                    and Color3.fromRGB(255, 95, 190)
                    or Color3.fromRGB(90, 205, 235)
                for hum, state in pairs(previous) do
                    if hum.Parent and hum.Health > 0
                        and hum.WalkSpeed == state.current then
                        local target = phase == "Surge"
                            and state.applied or state.original
                        hum.WalkSpeed = target
                        state.current = target
                    end
                end
                task.wait(0.25)
            end
        end)
    end
end

return D
