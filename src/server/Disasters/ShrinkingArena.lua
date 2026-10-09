-- Keep newly authored connecting geometry attached to its moving decks.
-- Cloud source tests run before unpublished place modules exist.
local helixModule = script and script.Parent.Parent:FindFirstChild("OrbitalHelix")
local OrbitalHelix = if helixModule
    then require(helixModule)
    else require("../OrbitalHelix")

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

-- Towers' four permanent skybridges originally span the inner edges of
-- towers 56 studs apart with 7 studs total endpoint overlap.
-- During shrink their endpoints must remain attached to the moving
-- middle decks, rather than retaining their pre-shrink 49-stud span.
function D.skybridgeSpan(originalSpan, scale)
    local span = math.max(1, tonumber(originalSpan) or 49)
    local safeScale = math.clamp(tonumber(scale) or 1, 0.05, 1)
    return math.max(4, (span + 7) * safeScale - 7)
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

    -- Engineered Skybridge detail is a local assembly relative to the
    -- physical bridge, not a generic independent floor decoration.
    local bridgeStates = {}
    for _, state in ipairs(movableParts) do
        local index = tonumber(state.part.Name:match("^Skybridge(%d+)$"))
        if index and state.part:GetAttribute("ChaosSkybridge") == true then
            state.bridgeSpan = math.max(state.part.Size.X, state.part.Size.Z)
            state.alongX = state.part.Size.X > state.part.Size.Z
            bridgeStates[index] = state
        end
    end

    local bridgeDetails = {}
    if decor then
        for _, item in ipairs(decor:GetChildren()) do
            if item:IsA("BasePart") then
                local index = tonumber(
                    item.Name:match("^SkybridgeRail(%d+)_")
                    or item.Name:match("^SkybridgeRib(%d+)_")
                    or item.Name:match("^PlatformGlow(%d+)$")
                    or item.Name:match("^PlatformPanel(%d+)$")
                    or item.Name:match("^PlatformUnderFrame(%d+)$")
                    or item.Name:match("^PlatformCoreGlow(%d+)$")
                    or item.Name:match("^PlatformSupport(%d+)_")
                )
                local bridge = index and bridgeStates[index]
                if bridge then
                    table.insert(bridgeDetails, {
                        part = item,
                        bridge = bridge,
                        size = item.Size,
                        cframe = item.CFrame,
                        localCFrame = bridge.part.CFrame:ToObjectSpace(item.CFrame),
                    })
                elseif item.Name:match("^PlatformGlow%d+$") then
                    movableParts[#movableParts+1] = {
                        part = item,
                        cframe = item.CFrame,
                        localCFrame = originalCFrame:ToObjectSpace(item.CFrame),
                        localPosition = originalCFrame:PointToObjectSpace(item.Position),
                    }
                end
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
                    impulse = Vector3.new(
                        tonumber(item:GetAttribute("ImpulseX")) or 0,
                        tonumber(item:GetAttribute("ImpulseY")) or 0,
                        tonumber(item:GetAttribute("ImpulseZ")) or 0
                    ),
                }
            end
        end
    end

    local helix = arena:FindFirstChild("HelixCircuit")
    local helixSnapshot = OrbitalHelix.capture(helix)

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

                    if state.bridgeSpan then
                        local span = D.skybridgeSpan(state.bridgeSpan, scale)
                        part.Size = state.alongX
                            and Vector3.new(span, part.Size.Y, part.Size.Z)
                            or Vector3.new(part.Size.X, part.Size.Y, span)
                    end

                    if state.impulse then
                        local scaledImpulse = D.scaledImpulse(state.impulse, scale)
                        part:SetAttribute("ImpulseX", scaledImpulse.X)
                        part:SetAttribute("ImpulseY", scaledImpulse.Y)
                        part:SetAttribute("ImpulseZ", scaledImpulse.Z)
                    end
                end
            end

            -- Rails, glow panels, armor ribs and supports maintain their
            -- engineering offsets from the rescaled physical deck.
            for _, detail in ipairs(bridgeDetails) do
                local piece = detail.part
                local bridge = detail.bridge
                if piece.Parent and bridge.part.Parent then
                    local span = D.skybridgeSpan(bridge.bridgeSpan, scale)
                    local ratio = span / bridge.bridgeSpan
                    local p = detail.localCFrame.Position
                    local rotationOnly = detail.localCFrame - p
                    local relative = bridge.alongX
                        and Vector3.new(p.X * ratio, p.Y, p.Z)
                        or Vector3.new(p.X, p.Y, p.Z * ratio)
                    piece.CFrame = bridge.part.CFrame
                        * CFrame.new(relative) * rotationOnly
                    local size = detail.size
                    piece.Size = bridge.alongX
                        and Vector3.new(
                            size.X > 2.2 and size.X * ratio or size.X,
                            size.Y, size.Z)
                        or Vector3.new(size.X, size.Y,
                            size.Z > 2.2 and size.Z * ratio or size.Z)
                end
            end

            if #helixSnapshot > 0 then
                OrbitalHelix.scale(helixSnapshot, originalCFrame.Position, scale)
            end

            task.wait(0.15)
        end
    end)

    ctx.OnCleanup[#ctx.OnCleanup+1] = function()
        OrbitalHelix.restore(helixSnapshot)
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
                if state.bridgeSpan then
                    part.Size = state.alongX
                        and Vector3.new(state.bridgeSpan, part.Size.Y, part.Size.Z)
                        or Vector3.new(part.Size.X, part.Size.Y, state.bridgeSpan)
                end
                if state.impulse then
                    part:SetAttribute("ImpulseX", state.impulse.X)
                    part:SetAttribute("ImpulseY", state.impulse.Y)
                    part:SetAttribute("ImpulseZ", state.impulse.Z)
                end
            end
        end

        for _, detail in ipairs(bridgeDetails) do
            if detail.part and detail.part.Parent then
                detail.part.Size = detail.size
                detail.part.CFrame = detail.cframe
            end
        end
    end
end

return D
