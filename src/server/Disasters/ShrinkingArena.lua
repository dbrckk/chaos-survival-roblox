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
-- Flat decals and panel insets are decoration, not collision geometry.
-- Scale their footprint with the base so they never show a ghost floor
-- beyond the shrinking walkable surface.
function D.scaledFloorTransform(originalSize, localPosition, scale)
    local safeScale = math.clamp(tonumber(scale) or 1, 0.05, 1)
    local size = typeof(originalSize) == "Vector3" and originalSize or Vector3.one
    return Vector3.new(
        math.max(0.05, size.X * safeScale),
        size.Y,
        math.max(0.05, size.Z * safeScale)
    ), D.scaledLocalPosition(localPosition, safeScale)
end

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

    local floorDetails = {}
    if decor then
        for _, item in ipairs(decor:GetChildren()) do
            if item:IsA("BasePart") then
                local name = item.Name
                local floorArt = name == "ArenaDeckInset"
                    or name == "DeckLineNorth" or name == "DeckLineSouth"
                    or name == "DeckLineEast" or name == "DeckLineWest"
                    or name:match("^ClassicGrid[XZ]%-?%d+$")
                    or name:match("^ClassicEntryChevron%d+_%-?%d+$")
                    or name:match("^TowerGroundPlate%d+$")
                    or name:match("^TowerGroundCore%d+$")
                    or name:match("^TowerAscentChevron%d+_%-?%d+$")
                    or name:match("^CrossroadLaneFill%d+$")
                    or name:match("^FluxRouteChevron%d+_%d+_%-?%d+$")
                    -- Keep 320-stud district navigation markings on the
                    -- contracting floor, not floating beyond lethal edges.
                    or name:match("^DistrictArrow%d+_%d+_%-?%d+$")
                if floorArt then
                    floorDetails[#floorDetails+1] = {
                        part = item,
                        size = item.Size,
                        cframe = item.CFrame,
                        localCFrame = originalCFrame:ToObjectSpace(item.CFrame),
                        localPosition = originalCFrame:PointToObjectSpace(item.Position),
                    }
                end
            end
        end
    end

    local movableParts = {}
    local platformStates = {}
    local platforms = arena:FindFirstChild("Platforms")
    if platforms then
        for _, platform in ipairs(platforms:GetChildren()) do
            if platform:IsA("BasePart") then
                local state = {
                    part = platform,
                    cframe = platform.CFrame,
                    localCFrame = originalCFrame:ToObjectSpace(platform.CFrame),
                    localPosition = originalCFrame:PointToObjectSpace(platform.Position),
                    size = platform.Size,
                    -- Classic's authored routes cannot preserve safe jump
                    -- gaps during a 55% inward shrink if their 10-stud
                    -- footprints remain unscaled; they must contract too.
                    compactRoute = tonumber(platform:GetAttribute("RouteTier")) ~= nil,
                }
                movableParts[#movableParts+1] = state
                local index = tonumber(platform.Name:match("^Platform(%d+)$"))
                if index then
                    platformStates[index] = state
                end
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

    -- Every visible trim belongs to a physical deck, not to the arena
    -- origin. Ordinary platforms translate intact while Tower skybridges
    -- both translate AND contract. Moving only PlatformGlow left the bevel,
    -- surface, frame and supports suspended at their original locations.
    local bridgeDetails = {}
    local platformDetails = {}
    if decor then
        for _, item in ipairs(decor:GetChildren()) do
            if item:IsA("BasePart") then
                local bridgeIndex = tonumber(
                    item.Name:match("^SkybridgeRail(%d+)_")
                    or item.Name:match("^SkybridgeRib(%d+)_")
                )
                local platformIndex = tonumber(
                    item.Name:match("^PlatformGlow(%d+)$")
                    or item.Name:match("^PlatformPanel(%d+)$")
                    or item.Name:match("^PlatformUnderFrame(%d+)$")
                    or item.Name:match("^PlatformCoreGlow(%d+)$")
                    or item.Name:match("^PlatformSupport(%d+)_%d+$")
                    or item.Name:match("^PlatformBevel(%d+)_%d+$")
                    -- Original outer-route facades are linked by an
                    -- explicit owning deck, not guessed from an art name.
                    or item:GetAttribute("PerimeterPlatformIndex")
                )
                local bridge = bridgeStates[bridgeIndex or platformIndex]
                local deck = platformIndex and platformStates[platformIndex]
                if bridge then
                    table.insert(bridgeDetails, {
                        part = item,
                        bridge = bridge,
                        size = item.Size,
                        cframe = item.CFrame,
                        localCFrame = bridge.part.CFrame:ToObjectSpace(item.CFrame),
                    })
                elseif deck then
                    table.insert(platformDetails, {
                        part = item,
                        deck = deck,
                        size = item.Size,
                        cframe = item.CFrame,
                        localCFrame = deck.part.CFrame:ToObjectSpace(item.CFrame),
                    })
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

        -- Unlike Tower Skyrail and Orbital Helix, Flux Relays are fixed
        -- world checkpoints. During a shrinking-floor round their gates
        -- must stay over the walkable base, not hang beyond its new edge.
        local relays = mechanics:FindFirstChild("FluxRelays")
        if relays then
            for _, item in ipairs(relays:GetChildren()) do
                if item:IsA("BasePart")
                    and type(item:GetAttribute("FluxRelayIndex")) == "number"
                then
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

            -- Shrink painted routes, low-profile floor panels and arena
            -- seams with the base, but never resize gameplay geometry.
            for _, state in ipairs(floorDetails) do
                local floorArt = state.part
                if floorArt.Parent then
                    local size, position = D.scaledFloorTransform(
                        state.size, state.localPosition, scale
                    )
                    local rotationOnly = state.localCFrame - state.localCFrame.Position
                    floorArt.Size = size
                    floorArt.CFrame = (originalCFrame * CFrame.new(position)) * rotationOnly
                end
            end

            for _, state in ipairs(movableParts) do
                local part = state.part
                if part.Parent then
                    local localPosition = D.scaledLocalPosition(state.localPosition, scale)
                    local rotationOnly = state.localCFrame - state.localCFrame.Position
                    part.CFrame = (originalCFrame * CFrame.new(localPosition)) * rotationOnly

                    if state.compactRoute then
                        part.Size = Vector3.new(
                            math.max(0.05, state.size.X * scale),
                            state.size.Y,
                            math.max(0.05, state.size.Z * scale)
                        )
                    end

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

            -- Decorative assemblies follow the exact physical platform
            -- CFrame: no ghost panels/frames/bevels outside the shrinking deck.
            for _, detail in ipairs(platformDetails) do
                if detail.part.Parent and detail.deck.part.Parent then
                    if detail.deck.compactRoute then
                        local p = detail.localCFrame.Position
                        local rotationOnly = detail.localCFrame - p
                        detail.part.CFrame = detail.deck.part.CFrame
                            * CFrame.new(p.X * scale, p.Y, p.Z * scale)
                            * rotationOnly
                        detail.part.Size = Vector3.new(
                            math.max(0.05, detail.size.X * scale),
                            detail.size.Y,
                            math.max(0.05, detail.size.Z * scale)
                        )
                    else
                        detail.part.CFrame = detail.deck.part.CFrame * detail.localCFrame
                    end
                end
            end

            -- Skybridge spans shorten with the supporting tower spacing.
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

        for _, state in ipairs(floorDetails) do
            if state.part and state.part.Parent then
                state.part.Size = state.size
                state.part.CFrame = state.cframe
            end
        end

        for _, state in ipairs(movableParts) do
            local part = state.part
            if part and part.Parent then
                part.CFrame = state.cframe
                if state.compactRoute then
                    part.Size = state.size
                end
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

        for _, detail in ipairs(platformDetails) do
            if detail.part and detail.part.Parent then
                detail.part.CFrame = detail.cframe
                if detail.deck.compactRoute then
                    detail.part.Size = detail.size
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
