-- Pure, authenticated original sky-traffic source and route contracts.
-- One arena exists at a time; two/four previously authored visual craft.
-- Tweening the driving native's CFrame (not Position) makes genuine
-- noncolliding WeldConstraint children move with it; no extra frame loop.
local Rules={}
local Ring=if script and script.Parent
    then require(script.Parent.CinematicDepthLayoutRules)
    else require("./CinematicDepthLayoutRules")

local SOURCE={
    Classic={id=102850052145878},
    Towers={id=72210530094580},
    Crossroads={id=116186226477876},
    Orbital={id=127850230318627},
    Harbor={id=131294203899636},
}
local CAPS={
    Low={0,0,0},
    Medium={2,1,0},
    High={4,2,0},
}
local MOBILE_HIGH={3,1,0}

function Rules.source(variant)
    return SOURCE[variant]
end

function Rules.capacity(tier,pressure,isTouch)
    local row=CAPS[tier]
    if not row then return 0 end
    local n=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if tier=="High" and isTouch then row=MOBILE_HIGH end
    return row[n+1]
end

function Rules.isNative(part,folder,variant,index)
    if typeof(part)~="Instance" or not part:IsA("Part")
        or typeof(folder)~="Instance" or not folder:IsA("Folder")
        or part.Parent~=folder or not SOURCE[variant]
        or not Ring.angle("Traffic",index)
        or part.Name~="CinemaTraffic"..index
        or not part.Anchored or part.CanCollide
        or part.CanTouch or part.CanQuery
        or part:GetAttribute("CosmeticOnly")~=true
        or part:GetAttribute("OriginalCinematicTrafficIndex")~=index
        or part:GetAttribute("OriginalCinematicTrafficVariant")~=variant
        or (part.Size-Vector3.new(5.6,.26,.46)).Magnitude>.05
    then return false end
    return true
end

function Rules.goal(from,to)
    if typeof(from)~="Vector3" or typeof(to)~="Vector3"
        or (to-from).Magnitude<.1 then return nil end
    -- Existing TweenService path/length unchanged; only move by CFrame
    -- instead of Position to preserve welded detailed model assembly.
    return CFrame.lookAt(to,to+(to-from))
end

return Rules
