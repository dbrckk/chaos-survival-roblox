local Players = game:GetService("Players")

local D = {Name = "RISING LAVA", Hint = "GET HIGH!"}

function D.isActiveContestant(player, ctx)
    if not player then
        return false
    end

    if ctx.IsContestantActive then
        return ctx.IsContestantActive(player) == true
    end

    for _, contestant in ipairs(ctx.Contestants or {}) do
        if contestant == player then
            return true
        end
    end

    return false
end

function D.start(ctx)
    local lava = Instance.new("Part")
    lava.Name = "RoundLava"
    lava.Size = Vector3.new(110, 4, 110)
    lava.Position = ctx.Config.ArenaCenter + Vector3.new(0, -8, 0)
    lava.Anchored = true
    lava.Material = Enum.Material.Neon
    lava.Color = Color3.fromRGB(255, 85, 0)
    lava.Parent = workspace

    lava.Touched:Connect(function(hit)
        local character = hit and hit.Parent
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        local player = character and Players:GetPlayerFromCharacter(character)

        if hum and hum.Health > 0 and D.isActiveContestant(player, ctx) then
            hum.Health = 0
        end
    end)

    local startY = lava.Position.Y
    local duration = math.max(
        0.1,
        tonumber(ctx.RoundSeconds or ctx.Config.RoundSeconds) or 1
    )

    ctx.Cleanup[#ctx.Cleanup+1] = lava

    task.spawn(function()
        local started = os.clock()
        while ctx.Active() and lava.Parent do
            local alpha = math.clamp((os.clock() - started) / duration, 0, 1)
            lava.Position = Vector3.new(lava.Position.X, startY + alpha * 25, lava.Position.Z)
            task.wait(0.1)
        end
    end)
end

return D
