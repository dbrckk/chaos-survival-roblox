local D = {Name = "MOON GRAVITY", Hint = "PLAN YOUR JUMPS AND LANDINGS!"}

-- Long, veteran-only rounds have two smoothly connected gravity windows.
-- Normal gravity remains unchanged for the lobby and all noncontestants.
-- The shift is announced before it changes player physics.
D.FloatGravity = 55
D.PullGravity = 120
D.CycleSeconds = 14

function D.tideAt(elapsedSeconds, enabled)
    if enabled ~= true then return D.FloatGravity, "Float", math.huge end
    local elapsed = tonumber(elapsedSeconds) or 0
    if elapsed ~= elapsed or elapsed == math.huge or elapsed == -math.huge then
        elapsed = 0
    end
    local t = math.max(0, elapsed) % D.CycleSeconds
    if t < 6.5 then
        return D.FloatGravity, "Float", 6.5 - t
    elseif t < 8 then
        local alpha = (t - 6.5) / 1.5
        return D.FloatGravity + (D.PullGravity - D.FloatGravity) * alpha,
            "PullRising", 8 - t
    elseif t < 12.5 then
        return D.PullGravity, "Pull", 12.5 - t
    end
    local alpha = (t - 12.5) / 1.5
    return D.PullGravity - (D.PullGravity - D.FloatGravity) * alpha,
        "FloatReturning", 14 - t
end

function D.tideCue(stage, remaining)
    if stage == "PullRising" then return "PULL RISING • LAND NOW" end
    if stage == "FloatReturning" then return "FLOAT RETURNING • GET READY" end
    if stage == "Pull" then
        if remaining <= 2 then
            return "FLOAT IN " .. tostring(math.ceil(remaining)) .. "s"
        end
        return "PULL • SHORTER JUMPS"
    end
    if remaining <= 2 then
        return "PULL IN " .. tostring(math.ceil(remaining)) .. "s"
    end
    return "FLOAT • LONGER JUMPS"
end

local function makeTideBeacon(ctx)
    local beacon = Instance.new("Part")
    beacon.Name = "MoonGravityBeacon"
    beacon.Shape = Enum.PartType.Ball
    beacon.Size = Vector3.new(2.4, 2.4, 2.4)
    beacon.Position = ctx.Config.ArenaCenter + Vector3.new(0, 13, 0)
    beacon.Anchored = true
    beacon.CanCollide = false
    beacon.CanTouch = false
    beacon.CanQuery = false
    beacon.CastShadow = false
    beacon.Material = Enum.Material.Neon
    beacon.Color = Color3.fromRGB(120, 205, 255)

    local gui = Instance.new("BillboardGui")
    gui.Name = "GravityTideSignal"
    gui.AlwaysOnTop = true
    gui.Size = UDim2.fromOffset(240, 64)
    gui.MaxDistance = 190
    gui.StudsOffsetWorldSpace = Vector3.new(0, 3.3, 0)
    gui.Parent = beacon

    local text = Instance.new("TextLabel")
    text.Name = "GravityTideText"
    text.Size = UDim2.fromScale(1, 1)
    text.Text = "GRAVITY TIDE\nFLOAT • LONGER JUMPS"
    text.TextColor3 = Color3.fromRGB(245, 250, 255)
    text.BackgroundColor3 = Color3.fromRGB(13, 23, 46)
    text.BackgroundTransparency = 0.15
    text.BorderSizePixel = 0
    text.TextScaled = true
    text.TextWrapped = true
    text.Font = Enum.Font.GothamBold
    text.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = text

    local light = Instance.new("PointLight")
    light.Color = beacon.Color
    light.Range = 12
    light.Brightness = 0.7
    light.Shadows = false
    light.Parent = beacon

    beacon.Parent = workspace
    ctx.Cleanup[#ctx.Cleanup + 1] = beacon
    return beacon, text, light
end

function D.compensationForce(mass, worldGravity, targetGravity)
    local safeMass = math.max(0, tonumber(mass) or 0)
    local world = math.max(0, tonumber(worldGravity) or 0)
    local target = math.max(0, tonumber(targetGravity) or 0)

    return math.max(0, safeMass * (world - target))
end

function D.start(ctx)
    local tidesEnabled = ctx.EnableGravityTides == true
    local targetGravity = D.FloatGravity
    local worldGravity = workspace.Gravity
    local startedAt = tonumber(ctx.RoundStartedAt) or os.clock()
    local beacon, beaconText, beaconLight
    if tidesEnabled then
        beacon, beaconText, beaconLight = makeTideBeacon(ctx)
        -- Use the existing once-per-second authoritative RoundState feed.
        -- No new remote or polling loop on mobile devices.
        local _, initialStage = D.tideAt(os.clock() - startedAt, true)
        ctx.GravityTideStage = initialStage
        if type(ctx.OnCleanup) == "table" then
            ctx.OnCleanup[#ctx.OnCleanup + 1] = function()
                ctx.GravityTideStage = nil
            end
        end
    end
    local activeForces = {}

    for _, player in ipairs(ctx.HazardContestants or ctx.Contestants or {}) do
        if ctx.IsContestantActive and not ctx.IsContestantActive(player) then
            continue
        end

        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

        if root and root:IsA("BasePart") and hum and hum.Health > 0 then
            local attachment = Instance.new("Attachment")
            attachment.Name = "MoonGravityAttachment"
            attachment.Parent = root

            local force = Instance.new("VectorForce")
            force.Name = "MoonGravityForce"
            force.Attachment0 = attachment
            force.RelativeTo = Enum.ActuatorRelativeTo.World
            force.ApplyAtCenterOfMass = true
            force.Force = Vector3.new(
                0,
                D.compensationForce(root.AssemblyMass, worldGravity, targetGravity),
                0
            )
            force.Parent = root

            activeForces[#activeForces+1] = {
                player = player,
                root = root,
                force = force,
            }

            ctx.Cleanup[#ctx.Cleanup+1] = force
            ctx.Cleanup[#ctx.Cleanup+1] = attachment
        end
    end

    task.spawn(function()
        local lastCue = nil
        local lastPullStage = nil
        while ctx.Active() do
            if tidesEnabled then
                local stage, remaining
                targetGravity, stage, remaining = D.tideAt(
                    os.clock() - startedAt, true
                )
                ctx.GravityTideStage = stage
                if beacon and beacon.Parent then
                    local cue = D.tideCue(stage, remaining)
                    if cue ~= lastCue then
                        beaconText.Text = "GRAVITY TIDE\n" .. cue
                        lastCue = cue
                    end
                    local pullStage = stage == "Pull" or stage == "PullRising"
                    if pullStage ~= lastPullStage then
                        beacon.Color = pullStage
                            and Color3.fromRGB(235, 136, 255)
                            or Color3.fromRGB(120, 205, 255)
                        beaconLight.Color = beacon.Color
                        lastPullStage = pullStage
                    end
                end
            end
            for _, state in ipairs(activeForces) do
                local root = state.root
                local force = state.force
                local player = state.player

                if root.Parent
                    and force.Parent
                    and (not ctx.IsContestantActive or ctx.IsContestantActive(player))
                then
                    force.Force = Vector3.new(
                        0,
                        D.compensationForce(root.AssemblyMass, workspace.Gravity, targetGravity),
                        0
                    )
                end
            end
            task.wait(0.25)
        end
    end)
end

return D
