-- Share replicated warnings between the personal guide, mastery hints and deck markings.
local JumpRouteCueRules = if script then require(script.Parent.JumpRouteCueRules)
    else require("./JumpRouteCueRules")

local JumpRouteHazards = {}

local liveWarnings = {}
local function trackWarning(child)
    if child:IsA("BasePart")
        and (child.Name == "MeteorWarning" or child.Name == "BombWarning")
    then
        liveWarnings[child] = true
    end
end
workspace.ChildAdded:Connect(trackWarning)
workspace.ChildRemoved:Connect(function(child)
    liveWarnings[child] = nil
end)
for _, child in ipairs(workspace:GetChildren()) do
    trackWarning(child)
end

function JumpRouteHazards.read(arena)
    local result = {}
    for part in pairs(liveWarnings) do
        if part.Parent == workspace then
            result[#result + 1] = part
        else
            liveWarnings[part] = nil
        end
    end

    local mechanics = arena and arena:FindFirstChild("Mechanics")
    if mechanics then
        for _, folderName in ipairs({"GridSweep", "HarborCargoSweep"}) do
            local folder = mechanics:FindFirstChild(folderName)
            if folder then
                for _, band in ipairs(folder:GetChildren()) do
                    if band:IsA("BasePart")
                        and (band:GetAttribute("GridSweepPhase") == "Warning"
                            or band:GetAttribute("GridSweepPhase") == "Pulse"
                            or band:GetAttribute("HarborSweepPhase") == "Warning"
                            or band:GetAttribute("HarborSweepPhase") == "Pulse") then
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

function JumpRouteHazards.landingPathIsSafe(fromPosition, target, warnings, lava)
    local targetRoot = standingRoot(target)
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
