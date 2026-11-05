-- Tier-independent positions for nonphysical cinematic scenery.
local Rules = {}
local groups = {
    Horizon = {total=11, offset=math.rad(11),
        Low={1,3,5,7,10}, Medium={1,2,3,5,6,7,9,10},
        High={1,2,3,4,5,6,7,8,9,10,11}},
    OrbitalHalo = {total=14, offset=0,
        Low={}, Medium={1,2,4,5,6,8,9,11,12,13},
        High={1,2,3,4,5,6,7,8,9,10,11,12,13,14}},
    Beacon = {total=5, offset=math.rad(22),
        Low={}, Medium={1,3,5}, High={1,2,3,4,5}},
    Traffic = {total=4, offset=0,
        Low={}, Medium={1,3}, High={1,2,3,4}},
}
function Rules.indices(group,tier)
    local info=groups[group]
    if not info then return {} end
    return info[tier] or info.Low
end
function Rules.angle(group,index)
    local info=groups[group]
    if not info or type(index)~="number" or index~=index
        or index~=math.floor(index) or index<1 or index>info.total then
        return nil
    end
    return ((index-1)/info.total)*math.pi*2+info.offset
end
return Rules
