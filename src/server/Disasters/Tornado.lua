local D = {Name = "TORNADO", Hint = "KEEP YOUR DISTANCE!"}

local function tornadoPart(parent, name, size, position, color, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Shape = Enum.PartType.Cylinder
    part.Size = size
    part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = transparency
    part.Parent = parent
    return part
end

function D.start(ctx)
    local profile = ctx.BalanceProfile or {}
    local force = profile.TornadoForce or 17
    local center = ctx.Config.ArenaCenter

    local visual = Instance.new("Model")
    visual.Name = "RoundTornado"
    visual.Parent = workspace
    ctx.Cleanup[#ctx.Cleanup+1] = visual

    local dangerZone = tornadoPart(
        visual,
        "DangerZone",
        Vector3.new(0.18, 84, 84),
        center + Vector3.new(0, 1.12, 0),
        Color3.fromRGB(80, 210, 215),
        0.90
    )

    local lower = tornadoPart(
        visual,
        "LowerFunnel",
        Vector3.new(2.0, 7, 7),
        center + Vector3.new(0, 3, 0),
        Color3.fromRGB(115, 235, 235),
        0.38
    )

    local middle = tornadoPart(
        visual,
        "MiddleFunnel",
        Vector3.new(3.5, 12, 12),
        center + Vector3.new(0, 7, 0),
        Color3.fromRGB(95, 220, 225),
        0.48
    )

    local upper = tornadoPart(
        visual,
        "UpperFunnel",
        Vector3.new(5.0, 18, 18),
        center + Vector3.new(0, 12, 0),
        Color3.fromRGB(75, 195, 205),
        0.58
    )

    local light = Instance.new("PointLight")
    light.Name = "TornadoGlow"
    light.Color = Color3.fromRGB(90, 220, 225)
    light.Brightness = 1.3
    light.Range = 26
    light.Shadows = false
    light.Parent = middle

    task.spawn(function()
        local clock = 0
        while ctx.Active() and visual.Parent do
            clock += 0.08
            local pulse = (math.sin(clock * 4) + 1) * 0.5

            dangerZone.Transparency = 0.88 + pulse * 0.07
            lower.Transparency = 0.30 + pulse * 0.16
            middle.Transparency = 0.40 + pulse * 0.15
            upper.Transparency = 0.50 + pulse * 0.14
            light.Brightness = 1.0 + pulse * 0.9

            task.wait(0.08)
        end
    end)

    task.spawn(function()
        while ctx.Active() do
            for _, player in ipairs(ctx.Contestants or {}) do
                if ctx.IsContestantActive and not ctx.IsContestantActive(player) then
                    continue
                end
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local delta = root.Position - center
                    local horizontal = Vector3.new(delta.X, 0, delta.Z)
                    local dist = horizontal.Magnitude
                    if dist < 42 and dist > 2 then
                        local tangent = Vector3.new(-horizontal.Z, 0, horizontal.X).Unit
                        local strength = math.clamp((42 - dist) / 42, 0, 1)
                        root.AssemblyLinearVelocity += tangent * force * strength + Vector3.new(0, 10 * strength, 0)
                    end
                end
            end
            task.wait(0.25)
        end
    end)
end

return D
