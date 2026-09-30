local D = {Name = "DISAPPEARING PLATFORMS", Hint = "YELLOW MEANS MOVE!"}

function D.start(ctx)
    local folder = workspace.GeneratedMap.Arena.Platforms

    task.spawn(function()
        while ctx.Active() do
            local parts = folder:GetChildren()
            if #parts > 0 then
                local p = parts[math.random(1, #parts)]
                if p:IsA("BasePart") and p.CanCollide then
                    local oldTransparency = p.Transparency
                    local oldCanCollide = p.CanCollide
                    local oldColor = p.Color
                    local oldMaterial = p.Material

                    p.Color = Color3.fromRGB(255, 205, 70)
                    p.Material = Enum.Material.Neon

                    task.wait(0.75)
                    if ctx.Active() and p and p.Parent then
                        p.Transparency = 1
                        p.CanCollide = false

                        task.delay(2.0, function()
                            if p and p.Parent then
                                p.Transparency = oldTransparency
                                p.CanCollide = oldCanCollide
                                p.Color = oldColor
                                p.Material = oldMaterial
                            end
                        end)
                    elseif p and p.Parent then
                        p.Color = oldColor
                        p.Material = oldMaterial
                    end
                end
            end

            local intensity = ctx.Intensity and ctx.Intensity() or 1
            task.wait(math.max(0.95, 1.4 / intensity))
        end
    end)
end

return D
