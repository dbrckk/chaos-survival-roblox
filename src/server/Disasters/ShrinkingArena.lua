local D = {Name = "SHRINKING ARENA", Hint = "STAY NEAR THE CENTER!"}

function D.start(ctx)
    local base = workspace.GeneratedMap.Arena.Base
    local originalSize = base.Size
    local originalCFrame = base.CFrame

    task.spawn(function()
        local started = os.clock()
        while ctx.Active() and base.Parent do
            local a = math.clamp((os.clock() - started) / ctx.Config.RoundSeconds, 0, 1)
            local scale = 1 - 0.55 * a
            base.Size = Vector3.new(originalSize.X * scale, originalSize.Y, originalSize.Z * scale)
            base.CFrame = originalCFrame
            task.wait(0.15)
        end
    end)

    ctx.OnCleanup[#ctx.OnCleanup+1] = function()
        if base and base.Parent then
            base.Size = originalSize
            base.CFrame = originalCFrame
        end
    end
end

return D
