-- Exact, nonphysical source identity and device caps for cinematic
-- skyline structures. Positions and primitive dimensions are unchanged.
-- The existing cinematic builder and real-mesh replacement use SAME rules.
local Ring = require("./CinematicDepthLayoutRules")
local Rules = {}

local VALID = {
    Classic=true, Towers=true, Crossroads=true, Orbital=true, Harbor=true,
}
local CAPS = {
    Low={2,1,0},
    Medium={5,2,0},
    High={11,6,0},
}
local TOUCH_HIGH={7,3,0}

function Rules.bodySize(variant,index)
    if not VALID[variant] or not Ring.angle("Horizon",index) then return nil end
    local width,height,depth
    if variant=="Towers" then
        width=7+((index*3)%6)
        height=44+((index*17)%42)
        depth=width
    elseif variant=="Crossroads" then
        width=18+((index*5)%12)
        height=18+((index*7)%18)
        depth=7+((index*3)%5)
    elseif variant=="Orbital" then
        width=11+((index*2)%5)
        height=12+((index*5)%15)
        depth=width
    else
        width=10+((index*4)%8)
        height=28+((index*13)%32)
        depth=8+((index*3)%6)
    end
    return Vector3.new(width,height,depth)
end

function Rules.offset(baseSize,variant,index)
    local size=Rules.bodySize(variant,index)
    if not size or typeof(baseSize)~="Vector3"
        or baseSize.X<160 or baseSize.Z<160 then return nil end
    local angle=Ring.angle("Horizon",index)
    local radius=variant=="Orbital" and 148
        or (variant=="Towers" and 142 or 136)
    return Vector3.new(math.cos(angle)*radius,size.Y*.5-8,
        math.sin(angle)*radius)
end

function Rules.capacity(tier,pressure,isTouch)
    local cap=CAPS[tier]
    if not cap then return 0 end
    local stress=math.clamp(math.floor(tonumber(pressure) or 0),0,2)
    if tier=="High" and isTouch then return TOUCH_HIGH[stress+1] end
    return cap[stress+1]
end

-- The four documented, server-owned original district sources are the
-- universal fallback. Specialized original artworks take priority in
-- their actual variant when their sanitized templates are available.
local POOLS={
    Classic={"Observatory","Aerial","Turbine","Freight"},
    Towers={"CoolingSpire","HollowStack","Turbine","Aerial"},
    Crossroads={"Freight","Aerial","Turbine","Observatory"},
    Orbital={"Satellite","Containment","Aerial","Observatory"},
    Harbor={"Freight","Turbine","Aerial","Observatory"},
}
local FALLBACK={"Observatory","Freight","Turbine","Aerial"}

function Rules.sources(variant,index)
    local pool=POOLS[variant]
    if not pool or not Ring.angle("Horizon",index) then return {} end
    local preferred=pool[((index-1)%#pool)+1]
    local alternatives={preferred}
    for shift=0,#FALLBACK-1 do
        local key=FALLBACK[((index+shift-1)%#FALLBACK)+1]
        if key~=preferred then alternatives[#alternatives+1]=key end
    end
    return alternatives
end

return Rules
