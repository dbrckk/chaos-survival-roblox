local D = {Name = "RISING LAVA", Hint = "GET HIGH!"}

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
        local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end)

    local startY = lava.Position.Y
    ctx.Cleanup[#ctx.Cleanup+1] = lava

    task.spawn(function()
        local started = os.clock()
        while ctx.Active() do
            local a = math.clamp((os.clock()-started) / ctx.RoundSeconds or ctx.Config.RoundSeconds, 0, 1)
            lava.Position = Vector3.new(lava.Position.X, startY + a * 25, lava.Position.Z)
            task.wait(0.1)
        end
    end)
end

return D
