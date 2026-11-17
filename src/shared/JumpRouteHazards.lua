-- Share replicated warnings between the personal guide, mastery hints and deck markings.
local CollectionService = game:GetService("CollectionService")
local JumpRouteCueRules = if script then require(script.Parent.JumpRouteCueRules)
    else require("./JumpRouteCueRules")

local warningsChanged = Instance.new("BindableEvent")
local JumpRouteHazards = {
    WarningsChanged = warningsChanged.Event,
}

local liveWarnings = {}
local warningUpdateQueued = false
local function queueWarningUpdate()
    if warningUpdateQueued then return end
    warningUpdateQueued = true
    task.defer(function()
        warningUpdateQueued = false
        warningsChanged:Fire()
    end)
end

local function trackWarning(child)
    if child.Parent ~= workspace or liveWarnings[child] or not child:IsA("BasePart")
        or (child.Name ~= "MeteorWarning" and child.Name ~= "BombWarning") then
        return
    end
    -- Streaming can deliver the final hazard size after the Part itself.
    liveWarnings[child] = child:GetAttributeChangedSignal("WarningEndSize"):Connect(queueWarningUpdate)
    queueWarningUpdate()
end
workspace.ChildAdded:Connect(trackWarning)
workspace.ChildRemoved:Connect(function(child)
    local connection = liveWarnings[child]
    if not connection then return end
    connection:Disconnect()
    liveWarnings[child] = nil
    queueWarningUpdate()
    -- The remove notification may run after the same part streams back in.
    trackWarning(child)
end)
for _, child in ipairs(workspace:GetChildren()) do
    trackWarning(child)
end

local sweeps = {
    {folder = "GridSweep", phase = "GridSweepPhase", tag = "ChaosClassicSweepBand"},
    {folder = "HarborCargoSweep", phase = "HarborSweepPhase", tag = "ChaosHarborSweepLane"},
}

local function watchSweep(sweep)
    local connections = {}
    local function track(lane)
        if connections[lane] or not lane:IsA("BasePart")
            or not lane:IsDescendantOf(game) or not lane:HasTag(sweep.tag) then return end
        connections[lane] = lane:GetAttributeChangedSignal(sweep.phase):Connect(queueWarningUpdate)
        queueWarningUpdate()
    end
    CollectionService:GetInstanceAddedSignal(sweep.tag):Connect(track)
    CollectionService:GetInstanceRemovedSignal(sweep.tag):Connect(function(lane)
        local connection = connections[lane]
        if not connection then return end
        connection:Disconnect()
        connections[lane] = nil
        queueWarningUpdate()
        track(lane)
    end)
    for _, lane in ipairs(CollectionService:GetTagged(sweep.tag)) do
        track(lane)
    end
end

for _, sweep in ipairs(sweeps) do
    watchSweep(sweep)
end

function JumpRouteHazards.read(arena)
    local result = {}
    for part in pairs(liveWarnings) do
        if part.Parent == workspace then
            result[#result + 1] = part
        end
    end

    local mechanics = arena and arena:FindFirstChild("Mechanics")
    if mechanics then
        for _, sweep in ipairs(sweeps) do
            local folder = mechanics:FindFirstChild(sweep.folder)
            if folder then
                for _, band in ipairs(folder:GetChildren()) do
                    local phase = band:GetAttribute(sweep.phase)
                    if band:IsA("BasePart") and (phase == "Warning" or phase == "Pulse") then
                        result[#result + 1] = band
                    end
                end
            end
        end
    end
    return result, workspace:FindFirstChild("RoundLava")
end

local function standingRoot(deck)
    return deck.Position + Vector3.yAxis * (deck.Size.Y * 0.5 + 2.5)
end

function JumpRouteHazards.landingPathIsSafe(fromPosition, target, warnings, lava, rampEntry)
    local targetRoot = if rampEntry then rampEntry + Vector3.yAxis * 2.5 else standingRoot(target)
    return not JumpRouteCueRules.lavaAtRoot(targetRoot, lava)
        and JumpRouteCueRules.safeGuidedPath(fromPosition, targetRoot, warnings)
end

function JumpRouteHazards.deckPathIsSafe(from, target, warnings, lava)
    if not lava and #warnings == 0 then return true end
    local fromRoot = standingRoot(from)
    return not JumpRouteCueRules.lavaAtRoot(fromRoot, lava)
        and JumpRouteHazards.landingPathIsSafe(fromRoot, target, warnings, lava)
end

return JumpRouteHazards
