-- Paint belongs to the physical links signed by MapBuilder. Reuse the
-- scenery pass and hazard notifications for the replicated chevron pairs.
local CollectionService = game:GetService("CollectionService")
local Shared = game:GetService("ReplicatedStorage").Shared
local JumpRouteCueRules = require(Shared.JumpRouteCueRules)
local JumpRouteHazards = require(Shared.JumpRouteHazards)

local Paint = {}
local TAG = "ChaosPerimeterGuide"
local candidates, observedDecks = {}, {}
local lastArena, lastCameraPoint

local refreshQueued = false

local function refresh()
    if refreshQueued or not lastArena then return end
    refreshQueued = true
    task.defer(function()
        refreshQueued = false
        Paint.sync(lastArena, lastCameraPoint)
    end)
end

local function observeDecks(nearby)
    for deck, connections in pairs(observedDecks) do
        if not nearby[deck] then
            for _, connection in ipairs(connections) do connection:Disconnect() end
            observedDecks[deck] = nil
        end
    end
    for deck in pairs(nearby) do
        if observedDecks[deck] then continue end
        local connections = {
            deck.AncestryChanged:Connect(refresh),
            deck:GetAttributeChangedSignal("CollapsePhase"):Connect(refresh),
            deck:GetAttributeChangedSignal("BridgeShutterPhase"):Connect(refresh),
        }
        for _, property in ipairs({"Size", "CanCollide", "Transparency", "Anchored"}) do
            connections[#connections + 1] = deck:GetPropertyChangedSignal(property):Connect(refresh)
        end
        observedDecks[deck] = connections
    end
end

local function mask(part, alpha)
    if part.LocalTransparencyModifier ~= alpha then
        part.LocalTransparencyModifier = alpha
    end
end

local function track(part)
    if part:IsA("BasePart") then
        mask(part, 1)
        candidates[part] = true
        refresh()
    end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(track)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(part)
    candidates[part] = nil
    if part:IsA("BasePart") then mask(part, 1) end
    refresh()
end)
for _, part in ipairs(CollectionService:GetTagged(TAG)) do track(part) end

function Paint.sync(arena, cameraPoint)
    lastArena, lastCameraPoint = arena, cameraPoint
    local decor = arena and arena:FindFirstChild("Decor")
    local platforms = arena and arena:FindFirstChild("Platforms")
    local groups = {}
    for part in pairs(candidates) do
        local key, side = part.Name:match("^(.+)_(%-?1)$")
        if decor and part.Parent == decor and key and cameraPoint
            and (part.Position - cameraPoint).Magnitude <= 82
            and part.Anchored and not part.CanCollide
            and not part.CanTouch and not part.CanQuery then
            local pair = groups[key] or {}
            if pair[side] then
                pair.invalid = true
                mask(part, 1)
            else
                pair[side] = part
            end
            groups[key] = pair
        else
            mask(part, 1)
        end
    end
    local nearby = {}
    if next(groups) == nil then
        observeDecks(nearby)
        return
    end

    local warnings, lava = JumpRouteHazards.read(arena)
    for _, pair in pairs(groups) do
        local left, right = pair["-1"], pair["1"]
        local visible = false
        if platforms and not pair.invalid and left and right then
            local sourceId = left:GetAttribute("PerimeterPlatformIndex")
            local targetId = left:GetAttribute("PerimeterGuideTarget")
            if type(sourceId) == "number" and type(targetId) == "number"
                and right:GetAttribute("PerimeterPlatformIndex") == sourceId
                and right:GetAttribute("PerimeterGuideTarget") == targetId then
                local source = platforms:FindFirstChild("Platform" .. sourceId)
                local target = platforms:FindFirstChild("Platform" .. targetId)
                if source and source:IsA("BasePart") then nearby[source] = true end
                if target and target:IsA("BasePart") then nearby[target] = true end
                visible = JumpRouteCueRules.safeLandingTarget(source)
                    and (if source:GetAttribute("BranchStep") == 4
                        then JumpRouteCueRules.skyNetworkLink(source, target)
                        else JumpRouteCueRules.jumpable(source, target))
                    and JumpRouteHazards.deckPathIsSafe(source, target, warnings, lava)
            end
        end
        local alpha = visible and 0 or 1
        if left then mask(left, alpha) end
        if right then mask(right, alpha) end
    end
    observeDecks(nearby)
end

JumpRouteHazards.WarningsChanged:Connect(refresh)

return Paint
