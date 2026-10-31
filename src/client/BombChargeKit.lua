-- Client-only Bomb Rain charge. All parts are anchored, collisionless,
-- unqueryable and recycled in-place throughout the authoritative warning.
local BombChargeKit = {}

local function clearPieces(state)
    for _, piece in ipairs(state.parts or {}) do
        if piece then piece:Destroy() end
    end
    state.parts = {}
    state.source = nil
    state.staticPosition = nil
    state.staticTier = nil
    state.staticCount = nil
end

function BombChargeKit.clear(state)
    if type(state) ~= "table" then return end
    clearPieces(state)
end

function BombChargeKit.sync(state, warning, parent, tier, reduced,
        progress, viewerPosition, slot, rules)
    if type(state) ~= "table" or type(rules) ~= "table" then return end
    local valid = typeof(warning) == "Instance"
        and warning:IsA("BasePart") and warning.Parent == workspace
        and warning.Name == "BombWarning"
        and typeof(parent) == "Instance" and parent.Parent ~= nil
        and typeof(viewerPosition) == "Vector3"
    if not valid then
        BombChargeKit.clear(state)
        return
    end

    local distance = (viewerPosition - warning.Position).Magnitude
    if not rules.visible(tier, distance, slot) then
        BombChargeKit.clear(state)
        return
    end

    local count = rules.profile(tier, reduced).Count
    if state.source ~= warning then
        clearPieces(state)
        state.source = warning
    end
    local parts = state.parts or {}
    state.parts = parts
    while #parts > count do
        local extra = table.remove(parts)
        if extra then extra:Destroy() end
    end

    -- ReduceMotion produces a fixed authored charge (no animation based
    -- on countdown progress). Avoid regenerating five recipes and writing
    -- the same Part properties at 30Hz, unless its warning actually moves,
    -- its tier/count changes or any locally owned Part is removed.
    local position = warning.Position
    if reduced == true and state.staticTier == tier
        and state.staticCount == count
        and state.staticPosition == position then
        local allLive = true
        for index = 1, count do
            local piece = parts[index]
            if not piece or piece.Parent ~= parent then
                allLive = false
                break
            end
        end
        if allLive then return end
    end

    local alpha = math.clamp(tonumber(progress) or 0, 0, 1)
    for index = 1, count do
        local recipe = rules.recipe(index, count, alpha, reduced)
        if recipe then
            local piece = parts[index]
            if not piece then
                piece = recipe.Shape == "Wedge" and Instance.new("WedgePart")
                    or Instance.new("Part")
                piece.Name = "LocalBombCharge" .. index
                piece.Anchored = true
                piece.CanCollide = false
                piece.CanTouch = false
                piece.CanQuery = false
                piece.CastShadow = false
                piece.Parent = parent
                parts[index] = piece
            end
            if recipe.Shape == "Ball" and piece.Shape ~= Enum.PartType.Ball then
                piece.Shape = Enum.PartType.Ball
            end
            if piece.Size ~= recipe.Size then piece.Size = recipe.Size end
            local frame = CFrame.new(position) * recipe.Transform
            if piece.CFrame ~= frame then piece.CFrame = frame end
            if piece.Material ~= recipe.Material then
                piece.Material = recipe.Material
            end
            if piece.Color ~= recipe.Color then piece.Color = recipe.Color end
            if piece.Transparency ~= recipe.Transparency then
                piece.Transparency = recipe.Transparency
            end
        end
    end

    -- Reusing a cached static pose is safe only while the visual remains
    -- in reduced-motion mode. Animated frames invalidate the cache.
    state.staticTier = reduced == true and tier or nil
    state.staticCount = reduced == true and count or nil
    state.staticPosition = reduced == true and position or nil
end

return BombChargeKit
