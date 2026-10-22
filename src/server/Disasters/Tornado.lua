local MovementSafety = if script then require(script.Parent.Parent.MovementSafety) else require("../MovementSafety")
local D = {Name = "TORNADO", Hint = "ESCAPE THE FUNNEL — HIGH GROUND HELPS!"}

-- The physical funnel is 12 studs high. Above its influence band,
-- Tower/Orbital upper routes offer a real positioning counterplay.
-- Keep full force near ground and fade smoothly across the upper decks.
function D.verticalExposure(height)
    local altitude = tonumber(height)
    if not altitude or altitude ~= altitude then return 0 end
    if altitude <= 12 then return 1 end
    return math.clamp((28 - altitude) / 16, 0, 1)
end

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

-- The old dist > 2 guard created a safe pocket at the center of
-- the tornado. Select a deterministic horizontal direction at zero
-- distance, while keeping the same 42-stud falloff and velocity cap.
function D.impulseAt(rootPosition, center, force, intensity)
    if typeof(rootPosition) ~= "Vector3" or typeof(center) ~= "Vector3" then
        return nil, 0
    end

    local delta = rootPosition - center
    local horizontal = Vector3.new(delta.X, 0, delta.Z)
    local dist = horizontal.Magnitude
    local exposure = D.verticalExposure(rootPosition.Y - center.Y)
    if dist ~= dist or dist >= 42 or exposure <= 0 then
        return nil, 0
    end

    local tangent = if dist > 0.001
        then Vector3.new(-horizontal.Z, 0, horizontal.X) / dist
        else Vector3.xAxis
    local strength = math.clamp((42 - dist) / 42, 0, 1) * exposure
    return tangent * force * intensity * strength
        + Vector3.new(0, 10 * intensity * strength, 0), strength
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
        0.965
    )

    local lower = tornadoPart(
        visual,
        "LowerFunnel",
        Vector3.new(2.0, 7, 7),
        center + Vector3.new(0, 3, 0),
        Color3.fromRGB(139, 194, 199),
        0.40
    )

    local middle = tornadoPart(
        visual,
        "MiddleFunnel",
        Vector3.new(3.5, 12, 12),
        center + Vector3.new(0, 7, 0),
        Color3.fromRGB(122, 172, 179),
        0.48
    )

    local upper = tornadoPart(
        visual,
        "UpperFunnel",
        Vector3.new(5.0, 18, 18),
        center + Vector3.new(0, 12, 0),
        Color3.fromRGB(96, 149, 159),
        0.56
    )

    local light = Instance.new("PointLight")
    light.Name = "TornadoGlow"
    light.Color = Color3.fromRGB(90, 220, 225)
    light.Brightness = 0.90
    light.Range = 26
    light.Shadows = false
    light.Parent = middle

    task.spawn(function()
        while ctx.Active() do
            local intensity = ctx.Intensity and ctx.Intensity() or 1
            for _, player in ipairs(ctx.HazardContestants or ctx.Contestants or {}) do
                -- A round can end while an expensive contact callback runs.
                -- Never apply stale physics to the next round/lobby.
                if not ctx.Active() then break end
                if ctx.IsContestantActive and not ctx.IsContestantActive(player) then
                    continue
                end
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local impulse, strength = D.impulseAt(
                        root.Position, center, force, intensity
                    )
                    if impulse then
                        root.AssemblyLinearVelocity = MovementSafety.addImpulse(
                            root.AssemblyLinearVelocity, impulse, 62, -55, 58
                        )
                        if strength >= 0.12 and ctx.OnHazardContact then
                            pcall(ctx.OnHazardContact, player, "Tornado")
                        end
                    end
                end
            end
            task.wait(0.25)
        end
    end)
end

return D
