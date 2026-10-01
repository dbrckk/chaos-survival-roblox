local D = {Name = "SHRINKING ARENA", Hint = "STAY NEAR THE CENTER!"}

function D.scaledEdgeTransform(originalSize, localPosition, scale)
    local safeScale = math.clamp(tonumber(scale) or 1, 0.05, 1)
    local size = typeof(originalSize) == "Vector3" and originalSize or Vector3.one
    local offset = typeof(localPosition) == "Vector3" and localPosition or Vector3.zero

    local scaledX = size.X > 1 and (size.X * safeScale) or size.X
    local scaledZ = size.Z > 1 and (size.Z * safeScale) or size.Z

    return Vector3.new(scaledX, size.Y, scaledZ), Vector3.new(
        offset.X * safeScale,
        offset.Y,
        offset.Z * safeScale
    )
end

function D.start(ctx)
    local generatedMap = workspace:FindFirstChild("GeneratedMap")
    local arena = generatedMap and generatedMap:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") then
        return
    end

    local originalSize = base.Size
    local originalCFrame = base.CFrame

    local edges = {}
    local decor = arena:FindFirstChild("Decor")
    if decor then
        for _, name in ipairs({"EdgeNorth", "EdgeSouth", "EdgeWest", "EdgeEast"}) do
            local edge = decor:FindFirstChild(name)
            if edge and edge:IsA("BasePart") then
                edges[#edges+1] = {
                    part = edge,
                    size = edge.Size,
                    cframe = edge.CFrame,
                    localPosition = originalCFrame:PointToObjectSpace(edge.Position),
                }
            end
        end
    end

    local duration = math.max(
        0.1,
        tonumber(ctx.RoundSeconds or ctx.Config.RoundSeconds) or 1
    )

    task.spawn(function()
        local started = os.clock()
        while ctx.Active() and base.Parent do
            local a = math.clamp((os.clock() - started) / duration, 0, 1)
            local scale = 1 - 0.55 * a
            base.Size = Vector3.new(originalSize.X * scale, originalSize.Y, originalSize.Z * scale)
            base.CFrame = originalCFrame

            for _, state in ipairs(edges) do
                local edge = state.part
                if edge.Parent then
                    local size, localPosition = D.scaledEdgeTransform(
                        state.size,
                        state.localPosition,
                        scale
                    )
                    edge.Size = size
                    edge.CFrame = originalCFrame * CFrame.new(localPosition)
                end
            end

            task.wait(0.15)
        end
    end)

    ctx.OnCleanup[#ctx.OnCleanup+1] = function()
        if base and base.Parent then
            base.Size = originalSize
            base.CFrame = originalCFrame
        end

        for _, state in ipairs(edges) do
            local edge = state.part
            if edge and edge.Parent then
                edge.Size = state.size
                edge.CFrame = state.cframe
            end
        end
    end
end

return D
