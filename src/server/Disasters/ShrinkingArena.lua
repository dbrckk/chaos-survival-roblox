local D = {Name = "SHRINKING ARENA", Hint = "STAY NEAR THE CENTER!"}

function D.scaledLocalPosition(localPosition, scale)
    local safeScale = math.clamp(tonumber(scale) or 1, 0.05, 1)
    local offset = typeof(localPosition) == "Vector3" and localPosition or Vector3.zero
    return Vector3.new(offset.X * safeScale, offset.Y, offset.Z * safeScale)
end

function D.scaledImpulse(originalImpulse, scale)
    local safeScale = math.clamp(tonumber(scale) or 1, 0.05, 1)
    local impulse = typeof(originalImpulse) == "Vector3" and originalImpulse or Vector3.zero
    return Vector3.new(impulse.X * safeScale, impulse.Y, impulse.Z * safeScale)
end

function D.scaledEdgeTransform(originalSize, localPosition, scale)
    local safeScale = math.clamp(tonumber(scale) or 1, 0.05, 1)
    local size = typeof(originalSize) == "Vector3" and originalSize or Vector3.one
    local offset = typeof(localPosition) == "Vector3" and localPosition or Vector3.zero

    local scaledX = size.X > 1 and (size.X * safeScale) or size.X
    local scaledZ = size.Z > 1 and (size.Z * safeScale) or size.Z

    return Vector3.new(scaledX, size.Y, scaledZ), D.scaledLocalPosition(offset, safeScale)
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
                    localCFrame = originalCFrame:ToObjectSpace(edge.CFrame),
                    localPosition = originalCFrame:PointToObjectSpace(edge.Position),
                }
            end
        end
    end

    local movableParts = {}
    local platforms = arena:FindFirstChild("Platforms")
    if platforms then
        for _, platform in ipairs(platforms:GetChildren()) do
            if platform:IsA("BasePart") then
                movableParts[#movableParts+1] = {
                    part = platform,
                    cframe = platform.CFrame,
                    localCFrame = originalCFrame:ToObjectSpace(platform.CFrame),
                    localPosition = originalCFrame:PointToObjectSpace(platform.Position),
                }
            end
        end
    end

    if decor then
        for _, item in ipairs(decor:GetChildren()) do
            if item:IsA("BasePart") and string.match(item.Name, "^PlatformGlow%d+$") then
                movableParts[#movableParts+1] = {
                    part = item,
                    cframe = item.CFrame,
                    localCFrame = originalCFrame:ToObjectSpace(item.CFrame),
                    localPosition = originalCFrame:PointToObjectSpace(item.Position),
                    impulse = Vector3.new(
                        tonumber(item:GetAttribute("ImpulseX")) or 0,
                        tonumber(item:GetAttribute("ImpulseY")) or 0,
                        tonumber(item:GetAttribute("ImpulseZ")) or 0
                    ),
                }
            end
        end
    end

    local mechanics = arena:FindFirstChild("Mechanics")
    if mechanics then
        for _, item in ipairs(mechanics:GetChildren()) do
            if item:IsA("BasePart") and item:GetAttribute("ArenaMobilityPad") == true then
                movableParts[#movableParts+1] = {
                    part = item,
                    cframe = item.CFrame,
                    localCFrame = originalCFrame:ToObjectSpace(item.CFrame),
                    localPosition = originalCFrame:PointToObjectSpace(item.Position),
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
                    local rotationOnly = state.localCFrame - state.localCFrame.Position
                    edge.CFrame = (originalCFrame * CFrame.new(localPosition)) * rotationOnly
                end
            end

            for _, state in ipairs(movableParts) do
                local part = state.part
                if part.Parent then
                    local localPosition = D.scaledLocalPosition(state.localPosition, scale)
                    local rotationOnly = state.localCFrame - state.localCFrame.Position
                    part.CFrame = (originalCFrame * CFrame.new(localPosition)) * rotationOnly

                    if state.impulse then
                        local scaledImpulse = D.scaledImpulse(state.impulse, scale)
                        part:SetAttribute("ImpulseX", scaledImpulse.X)
                        part:SetAttribute("ImpulseY", scaledImpulse.Y)
                        part:SetAttribute("ImpulseZ", scaledImpulse.Z)
                    end
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

        for _, state in ipairs(movableParts) do
            local part = state.part
            if part and part.Parent then
                part.CFrame = state.cframe
                if state.impulse then
                    part:SetAttribute("ImpulseX", state.impulse.X)
                    part:SetAttribute("ImpulseY", state.impulse.Y)
                    part:SetAttribute("ImpulseZ", state.impulse.Z)
                end
            end
        end
    end
end

return D
