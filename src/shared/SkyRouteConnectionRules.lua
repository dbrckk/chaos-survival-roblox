-- Physical junctions of the two promenades and the transverse Sky Spine.
-- Shared by route residency and the cosmetic reinforcement at each joint.
local Rules = {}

local function traversable(deck)
    if not deck or not deck:IsA("BasePart") or not deck.Anchored
        or not deck.CanCollide or deck.Transparency >= .75
        or deck:GetAttribute("ChaosPermanentRoute") ~= true
        or not deck.Name:match("^Platform%d+$") then return false end
    local phase = deck:GetAttribute("CollapsePhase")
    local shutter = deck:GetAttribute("BridgeShutterPhase")
    return (phase == nil or phase == "Normal" or phase == "Safe")
        and (shutter == nil or shutter == "Idle")
end

function Rules.spineJunction(spine,promenade)
    if not traversable(spine) or not traversable(promenade) or spine == promenade
        or not spine.Parent or spine.Parent ~= promenade.Parent
        or spine.Parent.Name ~= "Platforms"
        or spine:GetAttribute("SkySpineInterchange") ~= true
        or promenade:GetAttribute("SkySpineInterchange") == true then return false end
    local step = spine:GetAttribute("SkySpineStep")
    local lane = promenade:GetAttribute("PromenadeLane")
    local crossing = promenade:GetAttribute("PromenadeStep")
    if not ((step == 1 and lane == 1) or (step == 10 and lane == 2))
        or (crossing ~= 4 and crossing ~= 5) then return false end
    local a,b = spine.CFrame,promenade.CFrame
    local sa,sb = spine.Size,promenade.Size
    if sa.Z <= sa.X or sb.X <= sb.Z
        or a.UpVector:Dot(Vector3.yAxis) < .999 or b.UpVector:Dot(Vector3.yAxis) < .999
        or math.abs(a.LookVector:Dot(b.RightVector)) > .20
        or math.abs(spine.Position.Y+sa.Y*.5-promenade.Position.Y-sb.Y*.5) > .35 then
        return false
    end
    -- Positive overlap on both decks' horizontal axes. A nearby edge or
    -- a diagonal miss never promotes a physical junction.
    local delta = promenade.Position-spine.Position
    for _,axis in ipairs({a.RightVector,a.LookVector,b.RightVector,b.LookVector}) do
        local half = math.abs(axis:Dot(a.RightVector))*sa.X*.5
            + math.abs(axis:Dot(a.LookVector))*sa.Z*.5
            + math.abs(axis:Dot(b.RightVector))*sb.X*.5
            + math.abs(axis:Dot(b.LookVector))*sb.Z*.5
        if half-math.abs(delta:Dot(axis)) < .20 then return false end
    end
    return true
end

return Rules
