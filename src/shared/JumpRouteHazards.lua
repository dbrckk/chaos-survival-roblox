-- Share the replicated warning list between the personal guide and deck markings.
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

function JumpRouteHazards.deckPathIsSafe(from, target, warnings, lava)
    if not lava and #warnings == 0 then return true end
    local fromRoot = from.Position + Vector3.new(0, from.Size.Y * .5 + 2.5, 0)
    local targetRoot = target.Position + Vector3.new(0, target.Size.Y * .5 + 2.5, 0)
    return not JumpRouteCueRules.lavaAtRoot(fromRoot, lava)
        and not JumpRouteCueRules.lavaAtRoot(targetRoot, lava)
        and JumpRouteCueRules.safeGuidedPath(fromRoot, targetRoot, warnings)
end

return JumpRouteHazards
