local D = {Name = "DISAPPEARING PLATFORMS", Hint = "DON'T TRUST THE FLOOR!"}

function D.start(ctx)
    local folder = workspace.GeneratedMap.Arena.Platforms
    task.spawn(function()
        while ctx.Active() do
            local parts = folder:GetChildren()
            if #parts > 0 then
                local p = parts[math.random(1, #parts)]
                if p:IsA("BasePart") then
                    local oldTransparency = p.Transparency
                    local oldCanCollide = p.CanCollide
                    p.Transparency = 1
                    p.CanCollide = false
                    task.delay(2.5, function()
                        if p and p.Parent then
                            p.Transparency = oldTransparency
                            p.CanCollide = oldCanCollide
                        end
                    end)
                end
            end
            task.wait(1.3)
        end
    end)
end

return D
